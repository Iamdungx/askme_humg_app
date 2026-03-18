import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_submission_receipt.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_tracking_status.dart';

abstract class IQnaRepository {
  Future<QuestionSubmissionReceipt> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  });

  Future<QuestionTrackingStatus> getQuestionTrackingStatus({
    required String trackingCode,
    String? clientKey,
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
