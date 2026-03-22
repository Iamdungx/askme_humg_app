import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/answer_hot_score.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/feed/data/comment_model.dart';
import 'package:askme_humg/app/modules/feed/data/feed_item_model.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_sort_mode.dart';
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
  /// Indexes: `answers(isPublished, createdAt)` or `answers(isPublished, hotScore)`,
  /// plus topic variants with `aiCategory` / `aiTagIds`.
  /// [lastDocId] is the Firestore doc ID of the last seen item (opaque cursor).
  Future<({List<FeedItemModel> items, String? lastDocId})> getPublicFeed({
    String? lastDocId,
    String? topicTagId,
    FeedSortMode sortMode = FeedSortMode.trending,
  }) async {
    try {
      final normalizedTopicId = topicTagId?.trim();
      final hasTopicFilter =
          normalizedTopicId != null && normalizedTopicId.isNotEmpty;
      Query<Map<String, dynamic>> query = _feedQuery(
        sortMode: sortMode,
        topicTagId: normalizedTopicId,
      );
      final now = DateTime.now();
      if (hasTopicFilter &&
          _topicFilterIndexCooldownUntil != null &&
          now.isBefore(_topicFilterIndexCooldownUntil!)) {
        _logTopicFallbackOnce(
          'getPublicFeed topic filter fallback: index cooldown active',
        );
        final fallbackSnap = await _unfilteredFeedSnapshotWithSortFallback(
          lastDocId: lastDocId,
          sortMode: sortMode,
        );
        final fallbackItems = fallbackSnap.docs
            .map(FeedItemModel.fromFirestore)
            .toList();
        final fallbackLastDocId = fallbackSnap.docs.isNotEmpty
            ? fallbackSnap.docs.last.id
            : null;
        return (items: fallbackItems, lastDocId: fallbackLastDocId);
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
        if (!_isFirestoreIndexNotReady(e)) {
          rethrow;
        }
        // Topic filter: drop filter; trending without index: fall back to newest.
        if (!hasTopicFilter && sortMode != FeedSortMode.trending) {
          rethrow;
        }
        snap = await _snapAfterIndexFailure(
          lastDocId: lastDocId,
          sortMode: sortMode,
          hasTopicFilter: hasTopicFilter,
        );
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

  String _orderFieldForSort(FeedSortMode sortMode) =>
      sortMode == FeedSortMode.trending ? 'hotScore' : 'createdAt';

  /// Equality filters must come before [orderBy] (Firestore constraint).
  Query<Map<String, dynamic>> _feedQuery({
    required FeedSortMode sortMode,
    String? topicTagId,
  }) {
    final orderField = _orderFieldForSort(sortMode);
    Query<Map<String, dynamic>> q = _firestore
        .collection('answers')
        .where('isPublished', isEqualTo: true);

    final normalized = topicTagId?.trim();
    if (normalized != null && normalized.isNotEmpty) {
      if (_mainCategorySlugs.contains(normalized)) {
        q = q.where('aiCategory', isEqualTo: normalized);
      } else {
        q = q.where('aiTagIds', arrayContains: normalized);
      }
    }

    return q.orderBy(orderField, descending: true);
  }

  Query<Map<String, dynamic>> _baseUnfilteredFeedQuery({
    required FeedSortMode sortMode,
  }) {
    return _feedQuery(sortMode: sortMode, topicTagId: null).limit(20);
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _runUnfilteredFeedQuery({
    String? lastDocId,
    required FeedSortMode sortMode,
  }) async {
    Query<Map<String, dynamic>> query = _baseUnfilteredFeedQuery(
      sortMode: sortMode,
    );
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

  static bool _isFirestoreIndexNotReady(FirebaseException e) {
    return e.code == 'failed-precondition' &&
        (e.message?.toLowerCase().contains('requires an index') == true ||
            e.message?.toLowerCase().contains('index is currently building') ==
                true);
  }

  /// Unfiltered feed; if [sortMode] query fails (e.g. `hotScore` index building),
  /// retry with [FeedSortMode.newest].
  Future<QuerySnapshot<Map<String, dynamic>>>
  _unfilteredFeedSnapshotWithSortFallback({
    String? lastDocId,
    required FeedSortMode sortMode,
  }) async {
    try {
      return await _runUnfilteredFeedQuery(
        lastDocId: lastDocId,
        sortMode: sortMode,
      );
    } on FirebaseException catch (e) {
      if (!_isFirestoreIndexNotReady(e) || sortMode != FeedSortMode.trending) {
        rethrow;
      }
      _logTopicFallbackOnce(
        'getPublicFeed trending index fallback: using newest (cooldown path)',
      );
      return _runUnfilteredFeedQuery(
        lastDocId: lastDocId,
        sortMode: FeedSortMode.newest,
      );
    }
  }

  Future<QuerySnapshot<Map<String, dynamic>>> _snapAfterIndexFailure({
    String? lastDocId,
    required FeedSortMode sortMode,
    required bool hasTopicFilter,
  }) async {
    if (hasTopicFilter) {
      _topicFilterIndexCooldownUntil = DateTime.now().add(
        _topicFilterIndexCooldown,
      );
      _logTopicFallbackOnce(
        'getPublicFeed topic filter fallback: index not ready',
      );
      try {
        return await _runUnfilteredFeedQuery(
          lastDocId: lastDocId,
          sortMode: sortMode,
        );
      } on FirebaseException catch (e2) {
        if (!_isFirestoreIndexNotReady(e2) ||
            sortMode != FeedSortMode.trending) {
          rethrow;
        }
        _logTopicFallbackOnce(
          'getPublicFeed trending index fallback: using newest',
        );
        return _runUnfilteredFeedQuery(
          lastDocId: lastDocId,
          sortMode: FeedSortMode.newest,
        );
      }
    }
    _logTopicFallbackOnce('getPublicFeed trending index fallback: using newest');
    return _runUnfilteredFeedQuery(
      lastDocId: lastDocId,
      sortMode: FeedSortMode.newest,
    );
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

  /// UC-4.2: Transaction with single [update] — keeps `likeCount` == `likedBy.length`
  /// and refreshes `hotScore` when `createdAt` is present.
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

        final commentCount = (data?['commentCount'] as int?) ?? 0;
        final createdAtTs = data?['createdAt'] as Timestamp?;
        final newLikedBy = List<String>.from(currentLikedBy);
        if (isLikedOnServer) {
          newLikedBy.remove(userId);
        } else {
          if (!newLikedBy.contains(userId)) newLikedBy.add(userId);
        }
        final newLikeCount = newLikedBy.length;
        final update = <String, dynamic>{
          'likedBy': newLikedBy,
          'likeCount': newLikeCount,
        };
        if (createdAtTs != null) {
          update['hotScore'] = computeAnswerHotScore(
            likeCount: newLikeCount,
            commentCount: commentCount,
            createdAt: createdAtTs.toDate(),
          );
        }
        tx.update(answerRef, update);
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

  /// UC-4.3: Comment doc + answer `commentCount` / `hotScore` in one transaction
  /// so concurrent comments cannot lose increments.
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

      final commentRef = _firestore.collection('comments').doc();
      final answerRef = _firestore.collection('answers').doc(answerId);

      await _firestore.runTransaction((tx) async {
        final answerSnap = await tx.get(answerRef);
        if (!answerSnap.exists || answerSnap.data() == null) {
          throw const FirestoreException('Answer not found');
        }
        final ad = answerSnap.data()!;
        final prevCc = ad['commentCount'] as int? ?? 0;
        final lc = ad['likeCount'] as int? ?? 0;
        final createdAtTs = ad['createdAt'] as Timestamp?;
        final newCc = prevCc + 1;

        tx.set(commentRef, {
          'answerId': answerId,
          'userId': isAnonymous ? null : userId,
          'content': content,
          'isAnonymous': isAnonymous,
          'createdAt': FieldValue.serverTimestamp(),
          'authorName': authorName,
          'authorAvatar': authorAvatar,
          'authorIsHumgVerified': authorIsHumgVerified,
        });

        final commentUpdate = <String, dynamic>{'commentCount': newCc};
        if (createdAtTs != null) {
          commentUpdate['hotScore'] = computeAnswerHotScore(
            likeCount: lc,
            commentCount: newCc,
            createdAt: createdAtTs.toDate(),
          );
        }
        tx.update(answerRef, commentUpdate);
      });
      logger.d('postComment transaction committed for answer $answerId');
    } on FirestoreException {
      rethrow;
    } on FirebaseException catch (e, s) {
      logger.e('postComment transaction failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore transaction failed');
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
