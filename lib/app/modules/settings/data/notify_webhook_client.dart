import 'package:dio/dio.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/config/env_reader.dart';

/// Gọi webhook để gửi thông báo qua OneSignal (khi chưa có Blaze).
/// Webhook verify idToken, đọc preference từ Firestore, gọi OneSignal API.
class NotifyWebhookClient {
  NotifyWebhookClient() : _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
    headers: {'Content-Type': 'application/json'},
  ));

  final Dio _dio;

  String get _baseUrl => EnvReader.notifyWebhookUrl;

  bool get isAvailable => _baseUrl.isNotEmpty;

  /// Gửi thông báo "câu hỏi mới" tới [toUserId]. Gọi sau khi tạo question thành công.
  Future<void> sendNewQuestion({
    required String idToken,
    required String toUserId,
    required String content,
  }) async {
    if (!isAvailable) return;
    try {
      await _dio.post(
        '$_baseUrl/notify',
        data: {
          'idToken': idToken,
          'type': 'new_question',
          'toUserId': toUserId,
          'content': content,
        },
      );
    } on DioException catch (e, s) {
      logger.w(
        'NotifyWebhook sendNewQuestion failed',
        error: {
          'url': e.requestOptions.uri.toString(),
          'status': e.response?.statusCode,
          'data': e.response?.data,
        },
        stackTrace: s,
      );
    } catch (e, s) {
      logger.w(
        'NotifyWebhook sendNewQuestion failed',
        error: e,
        stackTrace: s,
      );
    }
  }

  /// Gửi thông báo "bình luận mới" tới chủ answer. Gọi sau khi post comment thành công.
  /// Webhook sẽ đọc answers/{answerId}.userId để biết gửi tới ai.
  Future<void> sendNewComment({
    required String idToken,
    required String answerId,
    required String content,
  }) async {
    if (!isAvailable) return;
    try {
      await _dio.post(
        '$_baseUrl/notify',
        data: {
          'idToken': idToken,
          'type': 'new_comment',
          'answerId': answerId,
          'content': content,
        },
      );
    } on DioException catch (e, s) {
      logger.w(
        'NotifyWebhook sendNewComment failed',
        error: {
          'url': e.requestOptions.uri.toString(),
          'status': e.response?.statusCode,
          'data': e.response?.data,
        },
        stackTrace: s,
      );
    } catch (e, s) {
      logger.w(
        'NotifyWebhook sendNewComment failed',
        error: e,
        stackTrace: s,
      );
    }
  }
}
