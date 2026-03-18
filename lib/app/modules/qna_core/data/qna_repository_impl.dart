import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/modules/qna_core/data/firebase_qna_datasource.dart';
import 'package:askme_humg/app/modules/qna_core/domain/i_qna_repository.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_submission_receipt.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_tracking_status.dart';

class QnaRepositoryImpl implements IQnaRepository {
  QnaRepositoryImpl(this._datasource);
  final FirebaseQnaDatasource _datasource;

  @override
  Future<QuestionSubmissionReceipt> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  }) async {
    try {
      return await _datasource.submitAnonymousQuestion(
        toUserId: toUserId,
        content: content,
      );
    } on RateLimitException {
      throw const RateLimitFailure();
    } on AppCheckException catch (e) {
      throw NetworkFailure(e.message);
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<QuestionTrackingStatus> getQuestionTrackingStatus({
    required String trackingCode,
    String? clientKey,
  }) async {
    try {
      return await _datasource.getQuestionTrackingStatus(
        trackingCode: trackingCode,
        clientKey: clientKey,
      );
    } on InvalidTrackingCodeException {
      throw const InvalidTrackingCodeFailure();
    } on TrackingNotFoundException {
      throw const TrackingNotFoundFailure();
    } on RateLimitException {
      throw const RateLimitFailure();
    } on NetworkException catch (e) {
      throw NetworkFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Stream<List<Question>> getInboxQuestions(String userId) =>
      _datasource.getInboxQuestions(userId).handleError((Object e) {
        if (e is FirestoreException) throw FirestoreFailure(e.message);
        if (e is AppException) throw UnknownFailure(e.message);
        throw UnknownFailure(e.toString());
      });

  @override
  Future<Question?> getQuestionById(String questionId) async {
    try {
      return await _datasource.getQuestionById(questionId);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) async {
    try {
      await _datasource.answerQuestion(
        questionId: questionId,
        userId: userId,
        content: content,
        isPublished: isPublished,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Stream<Map<String, bool>> getAnswerPublishStates(String userId) =>
      _datasource.getAnswerPublishStates(userId).handleError((Object e) {
        if (e is FirestoreException) throw FirestoreFailure(e.message);
        if (e is AppException) throw UnknownFailure(e.message);
        throw UnknownFailure(e.toString());
      });

  @override
  Future<void> publishSavedAnswer({
    required String questionId,
    required String userId,
  }) async {
    try {
      await _datasource.publishSavedAnswer(
        questionId: questionId,
        userId: userId,
      );
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }

  @override
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _datasource.deleteQuestion(questionId);
    } on FirestoreException catch (e) {
      throw FirestoreFailure(e.message);
    } on AppException catch (e) {
      throw UnknownFailure(e.message);
    } catch (e) {
      throw UnknownFailure(e.toString());
    }
  }
}
