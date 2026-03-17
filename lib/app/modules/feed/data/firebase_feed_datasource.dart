import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/feed/data/comment_model.dart';
import 'package:askme_humg/app/modules/feed/data/feed_item_model.dart';

class FirebaseFeedDatasource {
  FirebaseFeedDatasource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// UC-4.1: Query published answers, cursor-based pagination.
  /// Requires composite index: answers(isPublished ASC, createdAt DESC).
  /// [lastDocId] is the Firestore doc ID of the last seen item (opaque cursor).
  Future<({List<FeedItemModel> items, String? lastDocId})> getPublicFeed({
    String? lastDocId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('answers')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(20);

      if (lastDocId != null) {
        final lastSnap =
            await _firestore.collection('answers').doc(lastDocId).get();
        if (lastSnap.exists) {
          query = query.startAfterDocument(lastSnap);
        }
      }

      final snap = await query.get();
      final items = snap.docs.map(FeedItemModel.fromFirestore).toList();
      final newLastDocId = snap.docs.isNotEmpty ? snap.docs.last.id : null;

      return (items: items, lastDocId: newLastDocId);
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('getPublicFeed failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e('getPublicFeed unexpected error', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
    }
  }

  /// Fetch a single published answer by id for deep-link viewing.
  Future<FeedItemModel?> getPublishedAnswerById(String answerId) async {
    try {
      final doc = await _firestore.collection('answers').doc(answerId).get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      if ((data['isPublished'] as bool?) != true) return null;
      final createdAtTs = data['createdAt'] as Timestamp?;
      if (createdAtTs == null) {
        throw FirestoreException('createdAt is null for answer ${doc.id}');
      }
      return FeedItemModel(
        answerId: doc.id,
        questionId: data['questionId'] as String? ?? '',
        questionContent: data['questionContent'] as String? ?? '',
        answerContent: data['content'] as String? ?? '',
        hostUserId: data['userId'] as String? ?? '',
        hostName: data['hostName'] as String? ?? '',
        hostAvatar: data['hostAvatar'] as String? ?? '',
        createdAt: createdAtTs.toDate(),
        likeCount: data['likeCount'] as int? ?? 0,
        likedBy: List<String>.from(data['likedBy'] as List? ?? []),
        commentCount: data['commentCount'] as int? ?? 0,
        isPublished: data['isPublished'] as bool? ?? false,
        hostIsHumgVerified: data['hostIsHumgVerified'] as bool? ?? false,
      );
    } on FirebaseException catch (e, s) {
      logger.e('getPublishedAnswerById failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e('getPublishedAnswerById unexpected error', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
    }
  }

  /// UC-4.2: Single update() — NOT batch (spec requirement).
  Future<void> toggleLike({
    required String answerId,
    required String userId,
    required bool isCurrentlyLiked,
  }) async {
    try {
      await _firestore.collection('answers').doc(answerId).update({
        'likedBy': isCurrentlyLiked
            ? FieldValue.arrayRemove([userId])
            : FieldValue.arrayUnion([userId]),
        'likeCount': FieldValue.increment(isCurrentlyLiked ? -1 : 1),
      });
    } on FirebaseException catch (e, s) {
      logger.e('toggleLike failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore update failed');
    }
  }

  /// UC-4.3: Real-time stream of comments for an answer.
  /// Requires composite index: comments(answerId ASC, createdAt ASC).
  /// Limited to 100 most recent comments to avoid unbounded streams.
  Stream<List<CommentModel>> getComments(String answerId) {
    return _firestore
        .collection('comments')
        .where('answerId', isEqualTo: answerId)
        .orderBy('createdAt')
        .limit(100)
        .snapshots()
        .map(
          (snap) => snap.docs.map(CommentModel.fromFirestore).toList(),
        );
  }

  /// Returns the most recent [limit] published answers by a specific user.
  Future<List<FeedItemModel>> getUserAnswers({
    required String userId,
    int limit = 3,
  }) async {
    try {
      final snap = await _firestore
          .collection('answers')
          .where('userId', isEqualTo: userId)
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snap.docs.map(FeedItemModel.fromFirestore).toList();
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('getUserAnswers failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e('getUserAnswers unexpected error', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
    }
  }

  /// UC-4.3: WriteBatch — MANDATORY: comments add + answers.commentCount increment.
  ///
  /// Fetches authorName/authorAvatar from `users/{userId}` (Firestore source of
  /// truth) so denormalized data reflects the latest profile, not stale Auth data.
  /// Guard: [userId] must be non-null when [isAnonymous] is false.
  Future<void> postComment({
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
  }) async {
    if (!isAnonymous && userId == null) {
      throw const FirestoreException(
        'postComment: userId must not be null for non-anonymous comment',
      );
    }

    try {
      // Fetch latest author info from Firestore for named comments.
      String authorName = '';
      String authorAvatar = '';
      bool authorIsHumgVerified = false;
      if (!isAnonymous && userId != null) {
        final userSnap =
            await _firestore.collection('users').doc(userId).get();
        final data = userSnap.data();
        authorName = (data?['name'] as String?) ?? '';
        authorAvatar = (data?['avatar'] as String?) ?? '';
        authorIsHumgVerified = (data?['isHumgVerified'] as bool?) ?? false;
      }

      final batch = _firestore.batch();

      final commentRef = _firestore.collection('comments').doc();
      batch.set(commentRef, {
        'answerId': answerId,
        'userId': isAnonymous ? null : userId,
        'content': content,
        'isAnonymous': isAnonymous,
        'createdAt': FieldValue.serverTimestamp(),
        // Denormalized for display — empty strings for anonymous comments.
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'authorIsHumgVerified': authorIsHumgVerified,
      });

      final answerRef = _firestore.collection('answers').doc(answerId);
      batch.update(answerRef, {
        'commentCount': FieldValue.increment(1),
      });

      await batch.commit();
      logger.d('postComment WriteBatch committed for answer $answerId');
    } on FirebaseException catch (e, s) {
      logger.e('postComment WriteBatch failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore batch failed');
    }
  }
}
