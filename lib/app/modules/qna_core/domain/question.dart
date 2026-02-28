import 'package:freezed_annotation/freezed_annotation.dart';

part 'question.freezed.dart';

@freezed
abstract class Question with _$Question {
  const factory Question({
    required String questionId,
    required String toUserId,
    required String content,
    required DateTime createdAt,
    required String status,
  }) = _Question;
}
