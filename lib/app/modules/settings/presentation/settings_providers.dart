import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/modules/profile/presentation/profile_providers.dart';
import 'package:askme_humg/app/modules/settings/data/cache_service.dart';

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
// CacheService DI
// ---------------------------------------------------------------------------

@riverpod
CacheService cacheService(Ref ref) => const CacheService();

// ---------------------------------------------------------------------------
// Cache size — async, auto-loaded on first watch
// ---------------------------------------------------------------------------

@riverpod
Future<int> cacheSize(Ref ref) => ref.watch(cacheServiceProvider).getCacheSize();

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
      await ref.read(updateProfileUseCaseProvider).call(
        userId: userId,
        name: name,
        avatarLocalPath: avatarLocalPath,
      );
      ref.invalidate(userProfileProvider(userId));
    });
  }
}
