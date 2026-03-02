import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/qna_core/data/question_model.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';

class FirebaseQnaDatasource {
  FirebaseQnaDatasource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  // UC-3.1: Direct Firestore write (temporary — Blaze plan required to restore
  // Cloud Function with App Check verification + per-device rate limiting).
  // TODO(blaze): Replace with Cloud Function call once Blaze plan is enabled.
  //   Cloud Function: functions/src/index.ts → submitQuestion
  //   Flow: App Check token → POST /submitQuestion → rate limit check → Firestore write
  Future<void> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  }) async {
    try {
      await _firestore.collection('questions').add({
        'toUserId': toUserId,
        'content': content,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'unanswered',
      });
    } on FirebaseException catch (e, s) {
      logger.e('submitAnonymousQuestion failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore write failed');
    } catch (e, s) {
      logger.e('submitAnonymousQuestion unexpected error', error: e, stackTrace: s);
      throw FirestoreException(e.toString());
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

  /// UC-3.3: WriteBatch — answers.create + questions.update in one atomic commit.
  ///
  /// Denormalizes questionContent, hostName, hostAvatar into the answers doc
  /// so UC-4.1 feed queries read 1 doc instead of 3 (SRS NFR-02 performance).
  Future<void> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) async {
    try {
      // Fetch question content and host user info before the batch (denormalization).
      final questionSnap =
          await _firestore.collection('questions').doc(questionId).get();
      if (!questionSnap.exists) {
        throw FirestoreException(
          'answerQuestion: question $questionId not found',
        );
      }
      final questionContent =
          (questionSnap.data()?['content'] as String?) ?? '';

      final userSnap =
          await _firestore.collection('users').doc(userId).get();
      final userData = userSnap.data();
      final hostName = (userData?['name'] as String?) ?? '';
      final hostAvatar = (userData?['avatar'] as String?) ?? '';
      final hostIsHumgVerified = (userData?['isHumgVerified'] as bool?) ?? false;

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
        // Denormalized fields for UC-4.1 feed display (SRS NFR-02)
        'questionContent': questionContent,
        'hostName': hostName,
        'hostAvatar': hostAvatar,
        'hostIsHumgVerified': hostIsHumgVerified,
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
