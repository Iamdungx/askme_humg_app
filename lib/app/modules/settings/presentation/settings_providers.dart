import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/modules/profile/presentation/profile_providers.dart';
import 'package:askme_humg/app/modules/settings/data/cache_service.dart';
import 'package:askme_humg/app/modules/settings/data/notification_service.dart';
import 'package:askme_humg/app/modules/settings/data/notify_webhook_client.dart';

part 'settings_providers.g.dart';

// ---------------------------------------------------------------------------
// ShowRealName — in-memory toggle (persisted to Firestore in v2)
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
class ShowRealNameNotifier extends _$ShowRealNameNotifier {
  @override
  bool build() => false;

  /// Initialize from user profile data (called when SettingsScreen loads).
  void init(bool value) => state = value;

  void toggle(bool value) => state = value;
}

// ---------------------------------------------------------------------------
// Notification preferences — two separate toggles, persisted + FCM topics
// ---------------------------------------------------------------------------

const _kNotifNewQuestionKey = 'notif_new_question';
const _kNotifNewCommentKey = 'notif_new_comment';

@Riverpod(keepAlive: true)
class NotifNewQuestionNotifier extends _$NotifNewQuestionNotifier {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_kNotifNewQuestionKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kNotifNewQuestionKey, value);
  }
}

@Riverpod(keepAlive: true)
class NotifNewCommentNotifier extends _$NotifNewCommentNotifier {
  @override
  bool build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return prefs.getBool(_kNotifNewCommentKey) ?? false;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_kNotifNewCommentKey, value);
  }
}

// ---------------------------------------------------------------------------
// Persist notification prefs (Firestore) + sync local + OneSignal
// ---------------------------------------------------------------------------

@riverpod
class NotificationPrefsUpdater extends _$NotificationPrefsUpdater {
  @override
  FutureOr<void> build() {}

  Future<void> setPrefs({
    required String userId,
    required bool notifNewQuestion,
    required bool notifNewComment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // 1) Persist to backend first (source of truth for next login + webhook).
      await ref
          .read(profileRepositoryProvider)
          .updateNotificationPrefs(
            userId: userId,
            notifNewQuestion: notifNewQuestion,
            notifNewComment: notifNewComment,
          );

      // 2) Update local prefs only after backend success.
      await ref.read(notifNewQuestionProvider.notifier).set(notifNewQuestion);
      await ref.read(notifNewCommentProvider.notifier).set(notifNewComment);

      // 3) Sync OneSignal tags (best-effort; does not throw).
      final svc = ref.read(notificationServiceProvider);
      if (svc.isAvailable) {
        await svc.syncTags(
          notifNewQuestion: notifNewQuestion,
          notifNewComment: notifNewComment,
        );
      }
    });
  }
}

// ---------------------------------------------------------------------------
// NotificationService — FCM topic subscribe/unsubscribe
// ---------------------------------------------------------------------------

@riverpod
NotificationService notificationService(Ref ref) =>
    NotificationService.instance;

@riverpod
NotifyWebhookClient notifyWebhookClient(Ref ref) => NotifyWebhookClient();

@Riverpod(keepAlive: true)
Future<void> notificationBootstrap(Ref ref) async {
  await ref.read(notificationServiceProvider).init();
}

@riverpod
Stream<Map<String, dynamic>> notificationTaps(Ref ref) =>
    ref.watch(notificationServiceProvider).tapStream;

@riverpod
Stream<ForegroundNotificationEvent> notificationForegrounds(Ref ref) =>
    ref.watch(notificationServiceProvider).foregroundStream;

// ---------------------------------------------------------------------------
// CacheService DI
// ---------------------------------------------------------------------------

@riverpod
CacheService cacheService(Ref ref) => const CacheService();

// ---------------------------------------------------------------------------
// Cache size — async, auto-loaded on first watch
// ---------------------------------------------------------------------------

@riverpod
Future<int> cacheSize(Ref ref) =>
    ref.watch(cacheServiceProvider).getCacheSize();

// ---------------------------------------------------------------------------
// CacheClearer — AsyncNotifier that clears cache and refreshes cacheSize
// ---------------------------------------------------------------------------

@riverpod
class CacheClearer extends _$CacheClearer {
  @override
  FutureOr<void> build() {}

  Future<void> clear() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(cacheServiceProvider).clearCache();
      ref.invalidate(cacheSizeProvider);
    });
  }
}

// ---------------------------------------------------------------------------
// EditProfileNotifier — BACKLOG-02: save display name and/or new avatar
// ---------------------------------------------------------------------------

@riverpod
class EditProfileNotifier extends _$EditProfileNotifier {
  @override
  FutureOr<void> build() {}

  /// Call with [userId] of the authenticated user.
  /// Pass [name] to update display name, [avatarLocalPath] to upload a new avatar.
  /// After success, invalidates [userProfileProvider] so Profile tab + Feed refresh.
  Future<void> save({
    required String userId,
    String? name,
    String? avatarLocalPath,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(updateProfileUseCaseProvider)
          .call(userId: userId, name: name, avatarLocalPath: avatarLocalPath);
      ref.invalidate(userProfileProvider(userId));
    });
  }
}
