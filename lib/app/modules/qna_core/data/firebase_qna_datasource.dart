import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/qna_core/data/question_model.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

class FirebaseQnaDatasource {
  FirebaseQnaDatasource({
    required FirebaseFirestore firestore,
    required Dio dio,
  }) : _firestore = firestore,
       _dio = dio;

  final FirebaseFirestore _firestore;
  final Dio _dio;

  /// UC-3.1: Requires App Check token before calling Cloud Function
  Future<void> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  }) async {
    try {
      final appCheckToken = await FirebaseAppCheck.instance.getToken(false);
      if (appCheckToken == null) {
        throw const NetworkException('App Check token unavailable');
      }

      await _dio.post<void>(
        '/submitQuestion',
        data: {'toUserId': toUserId, 'content': content},
        options: Options(
          headers: {'X-Firebase-AppCheck': appCheckToken},
        ),
      );
    } on DioException catch (e, s) {
      logger.e('submitAnonymousQuestion Dio error', error: e, stackTrace: s);
      if (e.response?.statusCode == 429) throw const RateLimitException();
      throw NetworkException(
        e.response?.data?.toString() ?? e.message ?? 'Network error',
      );
    } on NetworkException {
      rethrow;
    } on RateLimitException {
      rethrow;
    } catch (e, s) {
      logger.e('submitAnonymousQuestion unexpected error', error: e, stackTrace: s);
      throw NetworkException(e.toString());
    }
  }

  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc = await _firestore
          .collection('questions')
          .doc(questionId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      final data = doc.data()!;
      return QuestionModel(
        questionId: doc.id,
        toUserId: data['toUserId'] as String? ?? '',
        content: data['content'] as String? ?? '',
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        status: data['status'] as String? ?? 'unanswered',
      ).toDomain();
    } on FirebaseException catch (e, s) {
      logger.e('getQuestionById failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore read failed');
    }
  }

  /// UC-3.2: Real-time stream — composite index required on Firestore
  Stream<List<Question>> getInboxQuestions(String userId) {
    return _firestore
        .collection('questions')
        .where('toUserId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => QuestionModel.fromFirestore(d).toDomain())
              .toList(),
        );
  }

  /// UC-3.3: WriteBatch — answers.create + questions.update in one atomic commit
  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) async {
    try {
      final batch = _firestore.batch();

      final answerRef = _firestore.collection('answers').doc();
      batch.set(answerRef, {
        'questionId': questionId,
        'userId': userId,
        'content': content,
        'isPublished': isPublished,
        'likedBy': [],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });

      final questionRef = _firestore.collection('questions').doc(questionId);
      batch.update(questionRef, {'status': 'answered'});

      await batch.commit();
    } on FirebaseException catch (e, s) {
      logger.e('answerQuestion WriteBatch failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore write failed');
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      await _firestore.collection('questions').doc(questionId).delete();
    } on FirebaseException catch (e, s) {
      logger.e('deleteQuestion failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore delete failed');
    }
  }
}
