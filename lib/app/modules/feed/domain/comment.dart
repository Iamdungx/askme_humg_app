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
    /// Denormalized from users collection — empty string for anonymous comments.
    @Default('') String authorName,
    /// Denormalized from users collection — empty string for anonymous comments.
    @Default('') String authorAvatar,
  }) = _Comment;
}
