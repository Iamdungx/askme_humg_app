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
import 'package:askme_humg/app/core/values/app_durations.dart';
import 'package:askme_humg/app/core/error/failures.dart';
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
    final page = await ref.watch(getPublicFeedUseCaseProvider).call();

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
      // Run fetch and a minimum display delay concurrently so the shimmer is
      // always visible for at least AppDuration.loadMoreMin — prevents a flash
      // when Firestore responds faster than one animation frame.
      final (page, _) = await (
        ref.read(getPublicFeedUseCaseProvider).call(lastDocId: current.lastDocId),
        Future<void>.delayed(AppDuration.loadMoreMin),
      ).wait;
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
    try {
      final (page, _) = await (
        ref.read(getPublicFeedUseCaseProvider).call(),
        Future<void>.delayed(AppDuration.loadMoreMin),
      ).wait;
      if (!ref.mounted) return;
      state = AsyncData(FeedState(
        items: page.items,
        lastDocId: page.lastDocId,
        hasReachedEnd: !page.hasMore,
      ));
    } catch (e, s) {
      logger.e('FeedNotifier.refresh failed', error: e, stackTrace: s);
      if (!ref.mounted) return;
      state = AsyncError(e, s);
    }
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

  /// Local update — called after posting a comment so the feed card reflects
  /// the latest comment count without requiring a refresh.
  void incrementItemCommentCount(String answerId) {
    final current = state.asData?.value;
    if (current == null) return;

    final updatedItems = current.items.map((item) {
      if (item.answerId != answerId) return item;
      return item.copyWith(commentCount: item.commentCount + 1);
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

  /// Returns a [Failure] if validation fails or the call errors, null on success.
  Future<Failure?> post({
    required String answerId,
    required String content,
    required bool isAnonymous,
  }) async {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return const ValidationFailure('errorCommentEmpty');
    if (trimmed.length > 500) return const ValidationFailure('errorCommentTooLong');

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
      return result.error is Failure
          ? result.error as Failure
          : UnknownFailure(result.error.toString());
    }

    // Keep the feed card in sync (commentCount) without forcing a full refresh.
    ref.read(feedProvider.notifier).incrementItemCommentCount(answerId);
    return null;
  }
}
