import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/config/env_reader.dart';

/// OneSignal: dùng khi chưa có Blaze (không chạy Cloud Functions).
/// Gọi [init] trong main sau Firebase. Gọi [login]/[logout] khi user đăng nhập/đăng xuất.
/// Gọi [syncTags] khi user bật/tắt toggle trong Settings (và persist Firestore qua profile datasource).
class NotificationService {
  NotificationService() : _appId = EnvReader.oneSignalAppId;

  final String _appId;
  bool _initialized = false;

  bool get isAvailable => _appId.isNotEmpty;

  /// Khởi tạo OneSignal (chỉ khi có App ID). Gọi 1 lần sau Firebase init.
  Future<void> init() async {
    if (_appId.isEmpty) {
      logger.d('OneSignal: ONESIGNAL_APP_ID empty, skip init');
      return;
    }
    if (_initialized) return;
    try {
      OneSignal.initialize(_appId);
      await OneSignal.Notifications.requestPermission(true);
      _initialized = true;
      logger.d('OneSignal initialized');
    } catch (e, s) {
      logger.e('OneSignal init failed', error: e, stackTrace: s);
    }
  }

  /// Đăng nhập user (external id = Firebase uid). Gọi sau khi auth thành công.
  Future<void> login(String externalId) async {
    if (!_initialized || _appId.isEmpty) return;
    try {
      OneSignal.login(externalId);
      logger.d('OneSignal login: $externalId');
    } catch (e, s) {
      logger.e('OneSignal login failed', error: e, stackTrace: s);
    }
  }

  /// Đăng xuất (khi user sign out).
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      OneSignal.logout();
      logger.d('OneSignal logout');
    } catch (e, s) {
      logger.e('OneSignal logout failed', error: e, stackTrace: s);
    }
  }

  /// Cập nhật tag theo preference (webhook có thể filter theo tag nếu cần).
  Future<void> syncTags({
    required bool notifNewQuestion,
    required bool notifNewComment,
  }) async {
    if (!_initialized) return;
    try {
      OneSignal.User.addTagWithKey('notif_new_question', notifNewQuestion ? 'true' : 'false');
      OneSignal.User.addTagWithKey('notif_new_comment', notifNewComment ? 'true' : 'false');
      logger.d('OneSignal tags: question=$notifNewQuestion comment=$notifNewComment');
    } catch (e, s) {
      logger.e('OneSignal syncTags failed', error: e, stackTrace: s);
    }
  }
}
