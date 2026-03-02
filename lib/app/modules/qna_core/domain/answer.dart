import 'package:freezed_annotation/freezed_annotation.dart';

part 'answer.freezed.dart';

@freezed
abstract class Answer with _$Answer {
  const factory Answer({
    required String answerId,
    required String questionId,
    required String userId,
    required String content,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default([]) List<String> likedBy,
    @Default(true) bool isPublished,
    @Default(0) int commentCount,
  }) = _Answer;
}
