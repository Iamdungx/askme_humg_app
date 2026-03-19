import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/feed/data/comment_model.dart';
import 'package:askme_humg/app/modules/feed/data/feed_item_model.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_topic.dart';

class FirebaseFeedDatasource {
  FirebaseFeedDatasource({required FirebaseFirestore firestore})
    : _firestore = firestore;

  final FirebaseFirestore _firestore;
  static const Duration _topicFilterIndexCooldown = Duration(seconds: 45);
  static const Duration _topicFilterFallbackLogThrottle = Duration(seconds: 30);
  DateTime? _topicFilterIndexCooldownUntil;
  DateTime? _lastTopicFilterFallbackLogAt;

  static const Set<String> _mainCategorySlugs = <String>{
    'hoc_tap',
    'doi_song',
    'tuyen_dung',
    'su_kien',
    'khac',
  };
  static const Map<String, String> _mainTopicColorBySlug = {
    'hoc_tap': '#1A7AAF',
    'doi_song': '#2D9BD8',
    'tuyen_dung': '#F59E0B',
    'su_kien': '#22C55E',
    'khac': '#475569',
  };

  /// UC-4.1: Query published answers, cursor-based pagination.
  /// Requires composite index: answers(isPublished ASC, createdAt DESC).
  /// [lastDocId] is the Firestore doc ID of the last seen item (opaque cursor).
  Future<({List<FeedItemModel> items, String? lastDocId})> getPublicFeed({
    String? lastDocId,
    String? topicTagId,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('answers')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true);

      final normalizedTopicId = topicTagId?.trim();
      final hasTopicFilter =
          normalizedTopicId != null && normalizedTopicId.isNotEmpty;
      final now = DateTime.now();
      if (hasTopicFilter &&
          _topicFilterIndexCooldownUntil != null &&
          now.isBefore(_topicFilterIndexCooldownUntil!)) {
        _logTopicFallbackOnce(
          'getPublicFeed topic filter fallback: index cooldown active',
        );
        final fallbackSnap = await _runUnfilteredFeedQuery(
          lastDocId: lastDocId,
        );
        final fallbackItems = fallbackSnap.docs
            .map(FeedItemModel.fromFirestore)
            .toList();
        final fallbackLastDocId = fallbackSnap.docs.isNotEmpty
            ? fallbackSnap.docs.last.id
            : null;
        return (items: fallbackItems, lastDocId: fallbackLastDocId);
      }

      if (normalizedTopicId != null && normalizedTopicId.isNotEmpty) {
        if (_mainCategorySlugs.contains(normalizedTopicId)) {
          query = query.where('aiCategory', isEqualTo: normalizedTopicId);
        } else {
          query = query.where('aiTagIds', arrayContains: normalizedTopicId);
        }
      }
      query = query.limit(20);

      if (lastDocId != null) {
        final lastSnap = await _firestore
            .collection('answers')
            .doc(lastDocId)
            .get();
        if (lastSnap.exists) {
          query = query.startAfterDocument(lastSnap);
        }
      }

      QuerySnapshot<Map<String, dynamic>> snap;
      try {
        snap = await query.get();
      } on FirebaseException catch (e) {
        final indexNotReady =
            e.code == 'failed-precondition' &&
            (e.message?.toLowerCase().contains('requires an index') == true ||
                e.message?.toLowerCase().contains(
                      'index is currently building',
                    ) ==
                    true);
        if (!indexNotReady || !hasTopicFilter) {
          rethrow;
        }
        // While Firestore is still building composite indexes, fallback to
        // unfiltered feed so users can continue browsing instead of hard error.
        _topicFilterIndexCooldownUntil = DateTime.now().add(
          _topicFilterIndexCooldown,
        );
        _logTopicFallbackOnce(
          'getPublicFeed topic filter fallback: index not ready',
        );
        snap = await _runUnfilteredFeedQuery(lastDocId: lastDocId);
      }
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

  Query<Map<String, dynamic>> _baseUnfilteredFeedQuery() {
    return _firestore
        .collection('answers')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(20);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _runUnfilteredFeedQuery({
    String? lastDocId,
  }) async {
    Query<Map<String, dynamic>> query = _baseUnfilteredFeedQuery();
    if (lastDocId != null) {
      final lastSnap = await _firestore
          .collection('answers')
          .doc(lastDocId)
          .get();
      if (lastSnap.exists) {
        query = query.startAfterDocument(lastSnap);
      }
    }
    return query.get();
  }

  void _logTopicFallbackOnce(String message) {
    final now = DateTime.now();
    if (_lastTopicFilterFallbackLogAt != null &&
        now.difference(_lastTopicFilterFallbackLogAt!) <
            _topicFilterFallbackLogThrottle) {
      return;
    }
    _lastTopicFilterFallbackLogAt = now;
    logger.w(message);
  }

  Future<List<FeedTopic>> getAiTopics() async {
    try {
      final snap = await _firestore
          .collection('app_config')
          .doc('ai_classification')
          .get();
      final data = snap.data() ?? const <String, dynamic>{};
      final rawCategories = data['categories'];
      final categorySlugs = <String>[];
      if (rawCategories is List) {
        for (final raw in rawCategories) {
          if (raw is! String) continue;
          final slug = raw.trim();
          if (slug.isEmpty || categorySlugs.contains(slug)) continue;
          categorySlugs.add(slug);
        }
      }

      if (categorySlugs.isEmpty) {
        final rawTags = data['tags'];
        if (rawTags is List) {
          for (final raw in rawTags) {
            if (raw is! Map) continue;
            final category = raw['category'] is String
                ? (raw['category'] as String).trim()
                : '';
            if (category.isEmpty || categorySlugs.contains(category)) continue;
            categorySlugs.add(category);
          }
        }
      }

      final topics = <FeedTopic>[];
      for (final slug in categorySlugs) {
        topics.add(
          FeedTopic(
            id: slug,
            slug: slug,
            // UI is responsible for localizing this display label by slug.
            label: slug,
            color: _mainTopicColorBySlug[slug] ?? '#475569',
            category: slug,
          ),
        );
      }
      return topics;
    } on FirebaseException catch (e, s) {
      if (e.code == 'permission-denied') {
        // Keep feed usable when app_config read is blocked by rules.
        logger.w('getAiTopics permission denied, fallback to empty topics');
        return const <FeedTopic>[];
      }
      logger.e('getAiTopics failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e('getAiTopics unexpected error', error: e, stackTrace: s);
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
        aiCategory: data['aiCategory'] as String?,
        aiTags: List<String>.from(data['aiTags'] as List? ?? []),
        aiTagIds: List<String>.from(data['aiTagIds'] as List? ?? []),
        aiTagRefs: _parseAiTagRefs(data['aiTagRefs'] as List?),
      );
    } on FirebaseException catch (e, s) {
      logger.e('getPublishedAnswerById failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    } catch (e, s) {
      logger.e(
        'getPublishedAnswerById unexpected error',
        error: e,
        stackTrace: s,
      );
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
      final answerRef = _firestore.collection('answers').doc(answerId);
      await _firestore.runTransaction((tx) async {
        final snap = await tx.get(answerRef);
        if (!snap.exists) {
          throw const FirestoreException('Answer not found');
        }

        final data = snap.data();
        final currentLikedBy = List<String>.from(
          data?['likedBy'] as List? ?? [],
        );
        final isLikedOnServer = currentLikedBy.contains(userId);
        if (isLikedOnServer != isCurrentlyLiked) {
          logger.w(
            'toggleLike client/server mismatch for $answerId: '
            'client=$isCurrentlyLiked server=$isLikedOnServer',
          );
        }

        tx.update(answerRef, {
          'likedBy': isLikedOnServer
              ? FieldValue.arrayRemove([userId])
              : FieldValue.arrayUnion([userId]),
          'likeCount': FieldValue.increment(isLikedOnServer ? -1 : 1),
        });
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
        .map((snap) => snap.docs.map(CommentModel.fromFirestore).toList());
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
        final userSnap = await _firestore.collection('users').doc(userId).get();
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
      batch.update(answerRef, {'commentCount': FieldValue.increment(1)});

      await batch.commit();
      logger.d('postComment WriteBatch committed for answer $answerId');
    } on FirebaseException catch (e, s) {
      logger.e('postComment WriteBatch failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore batch failed');
    }
  }
}

List<FeedAiTagRef> _parseAiTagRefs(List? rawList) {
  if (rawList == null) return const <FeedAiTagRef>[];
  final results = <FeedAiTagRef>[];
  for (final raw in rawList) {
    if (raw is! Map) continue;
    final id = raw['id'] is String ? raw['id'] as String : '';
    final slug = raw['slug'] is String ? raw['slug'] as String : '';
    final label = raw['label'] is String ? raw['label'] as String : '';
    final color = raw['color'] is String ? raw['color'] as String : '';
    if (id.isEmpty || slug.isEmpty) continue;
    results.add(
      FeedAiTagRef(
        id: id,
        slug: slug,
        label: label.isNotEmpty ? label : slug,
        color: color,
      ),
    );
  }
  return results;
}
