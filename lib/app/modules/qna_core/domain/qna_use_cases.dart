import 'package:askme_humg/app/modules/qna_core/domain/i_qna_repository.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

class SubmitAnonymousQuestion {
  const SubmitAnonymousQuestion(this._repo);
  final IQnaRepository _repo;

  Future<void> call({required String toUserId, required String content}) =>
      _repo.submitAnonymousQuestion(toUserId: toUserId, content: content);
}

class GetInboxQuestions {
  const GetInboxQuestions(this._repo);
  final IQnaRepository _repo;

  Stream<List<Question>> call(String userId) =>
      _repo.getInboxQuestions(userId);
}

class GetQuestionById {
  const GetQuestionById(this._repo);
  final IQnaRepository _repo;

  Future<Question?> call(String questionId) =>
      _repo.getQuestionById(questionId);
}

class AnswerQuestion {
  const AnswerQuestion(this._repo);
  final IQnaRepository _repo;

  Future<void> call({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) => _repo.answerQuestion(
    questionId: questionId,
    userId: userId,
    content: content,
    isPublished: isPublished,
  );
}

class DeleteQuestion {
  const DeleteQuestion(this._repo);
  final IQnaRepository _repo;

  Future<void> call(String questionId) => _repo.deleteQuestion(questionId);
}
