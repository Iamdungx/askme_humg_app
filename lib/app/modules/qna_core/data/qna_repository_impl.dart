import 'package:askme_humg/app/modules/qna_core/data/firebase_qna_datasource.dart';
import 'package:askme_humg/app/modules/qna_core/domain/i_qna_repository.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

class QnaRepositoryImpl implements IQnaRepository {
  QnaRepositoryImpl(this._datasource);
  final FirebaseQnaDatasource _datasource;

  @override
  Future<void> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  }) => _datasource.submitAnonymousQuestion(
    toUserId: toUserId,
    content: content,
  );

  @override
  Stream<List<Question>> getInboxQuestions(String userId) =>
      _datasource.getInboxQuestions(userId);

  @override
  Future<Question?> getQuestionById(String questionId) =>
      _datasource.getQuestionById(questionId);

  @override
  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) => _datasource.answerQuestion(
    questionId: questionId,
    userId: userId,
    content: content,
    isPublished: isPublished,
  );

  @override
  Future<void> deleteQuestion(String questionId) =>
      _datasource.deleteQuestion(questionId);
}
