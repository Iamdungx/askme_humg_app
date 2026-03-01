import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/data/feed_repository_impl.dart';
import 'package:askme_humg/app/modules/feed/data/firebase_feed_datasource.dart';
import 'package:askme_humg/app/modules/feed/domain/comment.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_use_cases.dart';
import 'package:askme_humg/app/modules/feed/domain/i_feed_repository.dart';

part 'feed_providers.freezed.dart';
part 'feed_providers.g.dart';

// ---------------------------------------------------------------------------
// Pagination state — uses String? cursor instead of DocumentSnapshot
// ---------------------------------------------------------------------------

@freezed
abstract class FeedState with _$FeedState {
  const factory FeedState({
    @Default([]) List<FeedItem> items,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasReachedEnd,
    String? lastDocId,
  }) = _FeedState;
}

// ---------------------------------------------------------------------------
// Infrastructure providers
// ---------------------------------------------------------------------------

@riverpod
FirebaseFeedDatasource feedDatasource(Ref ref) =>
    FirebaseFeedDatasource(firestore: ref.watch(firestoreProvider));

@riverpod
IFeedRepository feedRepository(Ref ref) =>
    FeedRepositoryImpl(ref.watch(feedDatasourceProvider));

// ---------------------------------------------------------------------------
// Use case providers
// ---------------------------------------------------------------------------

@riverpod
GetPublicFeed getPublicFeedUseCase(Ref ref) =>
    GetPublicFeed(ref.watch(feedRepositoryProvider));

@riverpod
ToggleLike toggleLikeUseCase(Ref ref) =>
    ToggleLike(ref.watch(feedRepositoryProvider));

@riverpod
GetComments getCommentsUseCase(Ref ref) =>
    GetComments(ref.watch(feedRepositoryProvider));

@riverpod
PostComment postCommentUseCase(Ref ref) =>
    PostComment(ref.watch(feedRepositoryProvider));

@riverpod
GetUserAnswers getUserAnswersUseCase(Ref ref) =>
    GetUserAnswers(ref.watch(feedRepositoryProvider));

// ---------------------------------------------------------------------------
// User answers — for Profile screen "Recent Answers" section
// ---------------------------------------------------------------------------

@riverpod
Future<List<FeedItem>> userAnswers(Ref ref, String userId) =>
    ref.watch(getUserAnswersUseCaseProvider).call(userId: userId);

// ---------------------------------------------------------------------------
// Feed notifier — UC-4.1 cursor pagination
// ---------------------------------------------------------------------------

@riverpod
class FeedNotifier extends _$FeedNotifier {
  @override
  Future<FeedState> build() async {
    final page = await ref.read(getPublicFeedUseCaseProvider).call();
    return FeedState(
      items: page.items,
      lastDocId: page.lastDocId,
      hasReachedEnd: !page.hasMore,
    );
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final page = await ref.read(getPublicFeedUseCaseProvider).call(
            lastDocId: current.lastDocId,
          );
      if (!ref.mounted) return;

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...page.items],
          lastDocId: page.lastDocId,
          isLoadingMore: false,
          hasReachedEnd: !page.hasMore,
        ),
      );
    } catch (e, s) {
      logger.e('FeedNotifier.loadMore failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(isLoadingMore: false));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final page =
          await ref.read(getPublicFeedUseCaseProvider).call(lastDocId: null);
      return FeedState(
        items: page.items,
        lastDocId: page.lastDocId,
        hasReachedEnd: !page.hasMore,
      );
    });
  }

  /// Optimistic update — called by [ToggleLikeNotifier] before the network call.
  void updateItemLike({
    required String answerId,
    required String uid,
    required bool isCurrentlyLiked,
  }) {
    final current = state.asData?.value;
    if (current == null) return;

    final updatedItems = current.items.map((item) {
      if (item.answerId != answerId) return item;
      final newLikedBy = isCurrentlyLiked
          ? (List<String>.from(item.likedBy)..remove(uid))
          : (List<String>.from(item.likedBy)..add(uid));
      return item.copyWith(
        likedBy: newLikedBy,
        likeCount: item.likeCount + (isCurrentlyLiked ? -1 : 1),
      );
    }).toList();

    state = AsyncData(current.copyWith(items: updatedItems));
  }

  /// Revert an optimistic like update on failure.
  void revertItemLike({
    required String answerId,
    required String uid,
    required bool wasLiked,
  }) {
    updateItemLike(answerId: answerId, uid: uid, isCurrentlyLiked: !wasLiked);
  }
}

// ---------------------------------------------------------------------------
// Toggle like notifier — UC-4.2 optimistic UI, parameterized by answerId
// to avoid race conditions when liking multiple items concurrently.
// ---------------------------------------------------------------------------

@riverpod
class ToggleLikeNotifier extends _$ToggleLikeNotifier {
  @override
  FutureOr<void> build(String answerId) {}

  Future<void> toggle({
    required String uid,
    required bool isCurrentlyLiked,
  }) async {
    if (state.isLoading) return;

    ref.read(feedProvider.notifier).updateItemLike(
          answerId: answerId,
          uid: uid,
          isCurrentlyLiked: isCurrentlyLiked,
        );

    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(toggleLikeUseCaseProvider).call(
            answerId: answerId,
            userId: uid,
            isCurrentlyLiked: isCurrentlyLiked,
          ),
    );

    if (state is AsyncError) {
      logger.w('toggleLike failed for $answerId, reverting optimistic update');
      ref.read(feedProvider.notifier).revertItemLike(
            answerId: answerId,
            uid: uid,
            wasLiked: isCurrentlyLiked,
          );
    }
  }
}

// ---------------------------------------------------------------------------
// Comments stream — UC-4.3
// ---------------------------------------------------------------------------

@riverpod
Stream<List<Comment>> comments(Ref ref, String answerId) =>
    ref.watch(getCommentsUseCaseProvider).call(answerId);

// ---------------------------------------------------------------------------
// Post comment notifier — UC-4.3
// ---------------------------------------------------------------------------

@riverpod
class PostCommentNotifier extends _$PostCommentNotifier {
  @override
  FutureOr<void> build() {}

  /// Returns a l10n error key string if validation fails, null on success.
  Future<String?> post({
    required String answerId,
    required String content,
    required bool isAnonymous,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return 'errorCommentEmpty';
    if (trimmed.length > 500) return 'errorCommentTooLong';

    final uid = ref.read(authStateProvider).asData?.value?.uid;

    state = const AsyncLoading();
    final result = await AsyncValue.guard(
      () => ref.read(postCommentUseCaseProvider).call(
            answerId: answerId,
            userId: isAnonymous ? null : uid,
            content: trimmed,
            isAnonymous: isAnonymous,
          ),
    );
    state = result;

    if (result is AsyncError<void>) {
      logger.e(
        'postComment failed',
        error: result.error,
        stackTrace: result.stackTrace,
      );
      return 'commonError';
    }
    return null;
  }
}
