import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_item.freezed.dart';

@freezed
abstract class FeedAiTagRef with _$FeedAiTagRef {
  const factory FeedAiTagRef({
    required String id,
    required String slug,
    required String label,
    required String color,
  }) = _FeedAiTagRef;
}

@freezed
abstract class FeedItem with _$FeedItem {
  const factory FeedItem({
    required String answerId,
    required String questionId,
    required String questionContent,
    required String answerContent,
    required String hostUserId,
    required String hostName,
    required String hostAvatar,
    required DateTime createdAt,
    required int likeCount,
    required List<String> likedBy,
    required int commentCount,
    required bool isPublished,
    @Default(false) bool hostIsHumgVerified,
    String? aiCategory,
    @Default(<String>[]) List<String> aiTags,
    @Default(<String>[]) List<String> aiTagIds,
    @Default(<FeedAiTagRef>[]) List<FeedAiTagRef> aiTagRefs,
  }) = _FeedItem;
}
