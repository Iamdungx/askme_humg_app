import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/modules/qna_core/domain/answer.dart';

part 'answer_model.freezed.dart';
part 'answer_model.g.dart';

@freezed
abstract class AnswerModel with _$AnswerModel {
  const factory AnswerModel({
    required String answerId,
    required String questionId,
    required String userId,
    required String content,
    required DateTime createdAt,
    @Default(0) int likeCount,
    @Default([]) List<String> likedBy,
    @Default(true) bool isPublished,
    @Default(0) int commentCount,
  }) = _AnswerModel;

  factory AnswerModel.fromJson(Map<String, dynamic> json) =>
      _$AnswerModelFromJson(json);

  factory AnswerModel.fromFirestore(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final createdAtTs = data['createdAt'] as Timestamp?;
    if (createdAtTs == null) {
      throw const FirestoreException('answers: missing required field createdAt');
    }
    return AnswerModel(
      answerId: doc.id,
      questionId: data['questionId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      content: data['content'] as String? ?? '',
      createdAt: createdAtTs.toDate(),
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
      likedBy: List<String>.from(data['likedBy'] as List? ?? []),
      isPublished: data['isPublished'] as bool? ?? true,
      commentCount: (data['commentCount'] as num?)?.toInt() ?? 0,
    );
  }
}

extension AnswerModelX on AnswerModel {
  Answer toDomain() => Answer(
    answerId: answerId,
    questionId: questionId,
    userId: userId,
    content: content,
    createdAt: createdAt,
    likeCount: likeCount,
    likedBy: likedBy,
    isPublished: isPublished,
    commentCount: commentCount,
  );
}
