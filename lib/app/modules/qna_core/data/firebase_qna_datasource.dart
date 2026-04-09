import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_installations/firebase_installations.dart';
import 'package:askme_humg/app/core/error/exceptions.dart';
import 'package:askme_humg/app/core/utils/answer_hot_score.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_submission_receipt.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_tracking_status.dart';
import 'package:askme_humg/app/modules/qna_core/data/question_model.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/services/api_client.dart';
import 'package:askme_humg/config/env_reader.dart';

class FirebaseQnaDatasource {
  FirebaseQnaDatasource({
    required FirebaseFirestore firestore,
    required ApiClient apiClient,
  }) : _firestore = firestore,
       _apiClient = apiClient;

  final FirebaseFirestore _firestore;
  final ApiClient _apiClient;

  static const _defaultFunctionsBaseUrl = 'https://askme-humg.vercel.app/api';

  String get _functionsBaseUrl {
    final apiBase = EnvReader.apiBaseUrl.trim();
    if (apiBase.isNotEmpty && !apiBase.contains('example.com')) {
      return apiBase.endsWith('/')
          ? apiBase.substring(0, apiBase.length - 1)
          : apiBase;
    }
    final notifyBase = EnvReader.notifyWebhookUrl.trim();
    if (notifyBase.isNotEmpty &&
        !notifyBase.contains('your-deployment.vercel.app')) {
      return notifyBase.endsWith('/')
          ? notifyBase.substring(0, notifyBase.length - 1)
          : notifyBase;
    }
    return _defaultFunctionsBaseUrl;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  Future<void> classifyPublishedAnswer({
    required String answerId,
    String? idToken,
  }) async {
    try {
      final resolvedToken = (idToken != null && idToken.trim().isNotEmpty)
          ? idToken.trim()
          : await FirebaseAuth.instance.currentUser?.getIdToken();
      if (resolvedToken == null || resolvedToken.isEmpty) {
        logger.w('classifyPublishedAnswer skipped: missing id token');
        return;
      }
      await _apiClient.post<Map<String, dynamic>>(
        '$_functionsBaseUrl/classifyAnswer',
        data: {'answerId': answerId},
        options: Options(headers: {'Authorization': 'Bearer $resolvedToken'}),
      );
    } on DioException catch (e, s) {
      // Classification is non-blocking and must not break publish UX.
      logger.w(
        'classifyPublishedAnswer failed (non-blocking)',
        error: e,
        stackTrace: s,
      );
    } catch (e, s) {
      logger.w(
        'classifyPublishedAnswer unexpected error (non-blocking)',
        error: e,
        stackTrace: s,
      );
    }
  }

  Never _throwFromDioException(DioException e) {
    final data = e.response?.data;
    final errorCode = data is Map<String, dynamic>
        ? data['error'] as String?
        : null;
    final statusCode = e.response?.statusCode;

    if (statusCode == 429 || errorCode == 'rate_limit_exceeded') {
      throw const RateLimitException();
    }
    if (statusCode == 429 || errorCode == 'too_many_requests') {
      throw const RateLimitException();
    }
    if (statusCode == 401) {
      throw const AppCheckException();
    }
    if (errorCode == 'invalid_code') {
      throw const InvalidTrackingCodeException();
    }
    if (errorCode == 'not_found') {
      throw const TrackingNotFoundException();
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw const NetworkException('Network request failed');
    }
    throw NetworkException(e.message ?? 'Request failed');
  }

  /// UC-3.1: Anonymous question submit via Cloud Function.
  Future<QuestionSubmissionReceipt> submitAnonymousQuestion({
    required String toUserId,
    required String content,
  }) async {
    try {
      String? appCheckToken;
      try {
        appCheckToken = await FirebaseAppCheck.instance.getToken();
      } on FirebaseException catch (e) {
        logger.w('AppCheck token unavailable, continue without header', error: e);
        appCheckToken = null;
      }
      final fid = await FirebaseInstallations.id;
      final response = await _apiClient.post<Map<String, dynamic>>(
        '$_functionsBaseUrl/submitQuestion',
        data: {'toUserId': toUserId, 'content': content, 'fid': fid},
        options: Options(
          headers: {
            if (appCheckToken != null && appCheckToken.isNotEmpty)
              'X-Firebase-AppCheck': appCheckToken,
          },
        ),
      );

      final data = response.data;
      final questionId = data?['questionId'] as String?;
      final trackingCode = data?['trackingCode'] as String?;
      if (questionId == null ||
          questionId.isEmpty ||
          trackingCode == null ||
          trackingCode.isEmpty) {
        throw const NetworkException('Invalid submitQuestion response');
      }
      return QuestionSubmissionReceipt(
        questionId: questionId,
        trackingCode: trackingCode,
      );
    } on FirebaseException catch (e, s) {
      logger.e(
        'submitAnonymousQuestion firebase failed',
        error: e,
        stackTrace: s,
      );
      throw const NetworkException(
        'Failed to prepare anonymous question request',
      );
    } on DioException catch (e, s) {
      logger.e('submitAnonymousQuestion failed', error: e, stackTrace: s);
      _throwFromDioException(e);
    } catch (e, s) {
      logger.e(
        'submitAnonymousQuestion unexpected error',
        error: e,
        stackTrace: s,
      );
      if (e is AppException) rethrow;
      throw NetworkException(e.toString());
    }
  }

  Future<QuestionTrackingStatus> getQuestionTrackingStatus({
    required String trackingCode,
    String? clientKey,
  }) async {
    try {
      final resolvedClientKey =
          (clientKey != null && clientKey.trim().isNotEmpty)
          ? clientKey.trim()
          : (await FirebaseInstallations.id ?? '');
      final response = await _apiClient.post<Map<String, dynamic>>(
        '$_functionsBaseUrl/getQuestionTrackingStatus',
        data: {'trackingCode': trackingCode, 'clientKey': resolvedClientKey},
      );

      final data = response.data;
      if (data == null) {
        throw const NetworkException('Invalid tracking status response');
      }
      return QuestionTrackingStatus(
        status: (data['status'] as String?) ?? 'unanswered',
        createdAt: _parseDateTime(data['createdAt']),
        answeredAt: _parseDateTime(data['answeredAt']),
        isPublished: data['isPublished'] as bool? ?? false,
        answerId: data['answerId'] as String?,
      );
    } on DioException catch (e, s) {
      logger.e('getQuestionTrackingStatus failed', error: e, stackTrace: s);
      _throwFromDioException(e);
    } catch (e, s) {
      logger.e(
        'getQuestionTrackingStatus unexpected error',
        error: e,
        stackTrace: s,
      );
      if (e is AppException) rethrow;
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

  /// UC-3.3: WriteBatch — answers.create + questions.update in one atomic commit.
  ///
  /// Denormalizes questionContent, hostName, hostAvatar into the answers doc
  /// so UC-4.1 feed queries read 1 doc instead of 3 (SRS NFR-02 performance).
  Future<String> answerQuestion({
    required String questionId,
    required String userId,
    required String content,
    required bool isPublished,
  }) async {
    try {
      // Fetch question content and host user info before the batch (denormalization).
      final questionSnap = await _firestore
          .collection('questions')
          .doc(questionId)
          .get();
      if (!questionSnap.exists) {
        throw FirestoreException(
          'answerQuestion: question $questionId not found',
        );
      }
      final questionContent =
          (questionSnap.data()?['content'] as String?) ?? '';

      final userSnap = await _firestore.collection('users').doc(userId).get();
      final userData = userSnap.data();
      final hostName = (userData?['name'] as String?) ?? '';
      final hostAvatar = (userData?['avatar'] as String?) ?? '';
      final hostIsHumgVerified =
          (userData?['isHumgVerified'] as bool?) ?? false;

      final batch = _firestore.batch();

      final answerRef = _firestore.collection('answers').doc();
      final createdAtForScore = DateTime.now();
      batch.set(answerRef, {
        'questionId': questionId,
        'userId': userId,
        'content': content,
        'isPublished': isPublished,
        'likedBy': [],
        'likeCount': 0,
        'commentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'hotScore': computeAnswerHotScore(
          likeCount: 0,
          commentCount: 0,
          createdAt: createdAtForScore,
        ),
        // Denormalized fields for UC-4.1 feed display (SRS NFR-02)
        'questionContent': questionContent,
        'hostName': hostName,
        'hostAvatar': hostAvatar,
        'hostIsHumgVerified': hostIsHumgVerified,
      });

      final questionRef = _firestore.collection('questions').doc(questionId);
      batch.update(questionRef, {'status': 'answered'});

      await batch.commit();
      if (isPublished) {
        unawaited(classifyPublishedAnswer(answerId: answerRef.id));
      }
      return answerRef.id;
    } on FirebaseException catch (e, s) {
      logger.e('answerQuestion WriteBatch failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore write failed');
    }
  }

  /// Tracks published/private state of answers keyed by questionId for a host.
  Stream<Map<String, bool>> getAnswerPublishStates(String userId) {
    return _firestore
        .collection('answers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snap) {
          final states = <String, bool>{};
          for (final doc in snap.docs) {
            final data = doc.data();
            final questionId = data['questionId'] as String?;
            if (questionId == null || questionId.isEmpty) continue;
            states[questionId] = data['isPublished'] as bool? ?? false;
          }
          return states;
        });
  }

  /// Publishes a previously saved private answer for a question.
  Future<String> publishSavedAnswer({
    required String questionId,
    required String userId,
  }) async {
    try {
      final snap = await _firestore
          .collection('answers')
          .where('questionId', isEqualTo: questionId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        throw FirestoreException(
          'publishSavedAnswer: answer for question $questionId not found',
        );
      }

      final answerDoc = snap.docs.first;
      final answerData = answerDoc.data();
      final isPublished = answerData['isPublished'] as bool? ?? false;
      if (isPublished) return answerDoc.id;

      final createdAtTs = answerData['createdAt'] as Timestamp?;
      final lc = answerData['likeCount'] as int? ?? 0;
      final cc = answerData['commentCount'] as int? ?? 0;
      final hotUpdate = <String, dynamic>{'isPublished': true};
      if (createdAtTs != null) {
        hotUpdate['hotScore'] = computeAnswerHotScore(
          likeCount: lc,
          commentCount: cc,
          createdAt: createdAtTs.toDate(),
        );
      }
      await answerDoc.reference.update(hotUpdate);
      unawaited(classifyPublishedAnswer(answerId: answerDoc.id));
      return answerDoc.id;
    } on FirebaseException catch (e, s) {
      logger.e('publishSavedAnswer failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore update failed');
    }
  }

  Future<void> deleteQuestion(String questionId) async {
    try {
      final questionRef = _firestore.collection('questions').doc(questionId);
      final relatedAnswers = await _firestore
          .collection('answers')
          .where('questionId', isEqualTo: questionId)
          .get();

      final batch = _firestore.batch();
      batch.delete(questionRef);
      for (final answerDoc in relatedAnswers.docs) {
        // Hide linked answers from Feed immediately when a host deletes
        // an answered question in Inbox.
        batch.update(answerDoc.reference, {'isPublished': false});
      }
      await batch.commit();
    } on FirebaseException catch (e, s) {
      logger.e('deleteQuestion failed', error: e, stackTrace: s);
      throw FirestoreException(e.message ?? 'Firestore delete failed');
    }
  }
}
