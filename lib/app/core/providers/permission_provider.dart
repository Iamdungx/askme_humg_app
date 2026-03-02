import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';

part 'permission_provider.g.dart';

/// Centralized permission checks — watch this instead of checking authState
/// manually in every widget.
///
/// Usage:
///   final p = ref.watch(permissionProvider);
///   if (p.canAnswer) { ... }
@riverpod
AppPermission permission(Ref ref) {
  final authAsync = ref.watch(authStateProvider);
  final user = authAsync.asData?.value;
  return AppPermission(user);
}

class AppPermission {
  const AppPermission(this._user);
  final AuthUser? _user;

  /// Signed in with any Google account
  bool get isSignedIn => _user != null;

  /// Verified HUMG student — can use Host features
  bool get isHost => _user?.isHumgVerified == true;

  /// Firebase Custom Claim `admin: true` — set by Cloud Functions, read from IdToken.
  bool get isAdmin => _user?.isAdmin == true;

  /// Blocked users cannot interact
  bool get isBlocked => _user?.isBlocked == true;

  // ── Feature-level gates ────────────────────────────────────────────────────

  /// Can submit questions anonymously — anyone (no sign-in required)
  bool get canSubmitQuestion => !isBlocked;

  /// Can view and manage their inbox
  bool get canManageInbox => isHost && !isBlocked;

  /// Can answer and publish to feed
  bool get canAnswer => isHost && !isBlocked;

  /// Can like / comment on feed posts
  bool get canInteractWithFeed => isSignedIn && !isBlocked;

  /// Can generate / share deep link profile card
  bool get canShareProfile => isHost && !isBlocked;

  /// Can report content
  bool get canReport => isSignedIn && !isBlocked;

  /// Can access admin moderation panel
  bool get canModerate => isAdmin;
}
