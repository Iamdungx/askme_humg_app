import 'package:freezed_annotation/freezed_annotation.dart';

part 'comment.freezed.dart';

@freezed
abstract class Comment with _$Comment {
  const factory Comment({
    required String commentId,
    required String answerId,
    String? userId,
    required String content,
    required bool isAnonymous,
    required DateTime createdAt,
    @Default('') String authorName,
    @Default('') String authorAvatar,
    @Default(false) bool authorIsHumgVerified,
  }) = _Comment;
}
