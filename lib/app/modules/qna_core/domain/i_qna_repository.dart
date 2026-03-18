import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

abstract class IQnaRepository {
  Future<void> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  });

  Stream<List<Question>> getInboxQuestions(String userId);

  Future<Question?> getQuestionById(String questionId);

  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  });

  Stream<Map<String, bool>> getAnswerPublishStates(String userId);

  Future<void> publishSavedAnswer({
    required String questionId,
    required String userId,
  });

  Future<void> deleteQuestion(String questionId);
}
