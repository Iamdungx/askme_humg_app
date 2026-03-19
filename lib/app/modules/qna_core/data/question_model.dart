import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

part 'question_model.freezed.dart';
part 'question_model.g.dart';

@freezed
abstract class QuestionModel with _$QuestionModel {
  const factory QuestionModel({
    required String questionId,
    required String toUserId,
    required String content,
    required DateTime createdAt,
    required String status,
  }) = _QuestionModel;

  factory QuestionModel.fromJson(Map<String, dynamic> json) =>
      _$QuestionModelFromJson(json);

  factory QuestionModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtTs = data['createdAt'] as Timestamp?;
    if (createdAtTs == null) {
      throw const FirestoreException(
        'questions: missing required field createdAt',
      );
    }
    return QuestionModel(
      questionId: doc.id,
      toUserId: data['toUserId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: createdAtTs.toDate(),
      status: data['status'] as String? ?? 'unanswered',
    );
  }
}

extension QuestionModelX on QuestionModel {
  Question toDomain() => Question(
    questionId: questionId,
    toUserId: toUserId,
    content: content,
    createdAt: createdAt,
    status: status,
  );
}
