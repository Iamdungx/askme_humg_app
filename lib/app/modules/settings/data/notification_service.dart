import 'dart:async';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/config/env_reader.dart';

class ForegroundNotificationEvent {
  const ForegroundNotificationEvent({
    required this.title,
    required this.body,
    required this.data,
  });

  final String title;
  final String body;
  final Map<String, dynamic> data;
}

/// OneSignal: dùng khi chưa có Blaze (không chạy Cloud Functions).
/// Gọi [init] trong main sau Firebase. Gọi [login]/[logout] khi user đăng nhập/đăng xuất.
/// Gọi [syncTags] khi user bật/tắt toggle trong Settings (và persist Firestore qua profile datasource).
class NotificationService {
  NotificationService._() : _appId = EnvReader.oneSignalAppId;

  static final NotificationService instance = NotificationService._();

  final String _appId;
  static bool _initialized = false;

  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  final _foregroundController =
      StreamController<ForegroundNotificationEvent>.broadcast();

  Stream<Map<String, dynamic>> get tapStream => _tapController.stream;
  Stream<ForegroundNotificationEvent> get foregroundStream =>
      _foregroundController.stream;

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
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.additionalData;
        if (data == null) return;
        _tapController.add(Map<String, dynamic>.from(data));
      });
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        // Don't rely on OS notification UI while app is foreground.
        event.preventDefault();
        final n = event.notification;
        _foregroundController.add(
          ForegroundNotificationEvent(
            title: n.title ?? '',
            body: n.body ?? '',
            data: Map<String, dynamic>.from(n.additionalData ?? const {}),
          ),
        );
      });
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
