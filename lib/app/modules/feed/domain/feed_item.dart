import 'package:freezed_annotation/freezed_annotation.dart';

part 'feed_item.freezed.dart';

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
  }) = _FeedItem;
}
