// Route path constants — used by _RouterNotifier and navigation callsites.
// The actual GoRoute tree is declared in router.dart (StatefulShellRoute).

/// Routes that require authentication. GoRouter checks `startsWith`.
const protectedLocationPrefixes = [
  '/inbox',
  '/me/edit',
  '/admin',
  '/scan-profile-qr',
];

/// Paths that are exempt from the HUMG-verification redirect (UC-1.3).
/// Exact-match paths — checked with Set.contains for O(1) lookup.
const humgVerifyExemptPaths = <String>{
  AppRoutes.verifyHumg,
  AppRoutes.login,
  AppRoutes.splash,
  AppRoutes.feed,
  AppRoutes.onboarding,
  AppRoutes.scanProfileQr,
};

/// Path prefixes that are exempt from the HUMG-verification redirect (UC-1.3).
/// Checked with String.startsWith.
const humgVerifyExemptPrefixes = <String>[
  AppRoutes.me,
  AppRoutes.settings,
  AppRoutes.answer,
];

/// Returns true when [path] does not require HUMG verification to access.
bool isHumgVerifyExempt(String path) =>
    humgVerifyExemptPaths.contains(path) ||
    humgVerifyExemptPrefixes.any(path.startsWith);

/// Named path constants for all app routes.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const onboarding = '/onboarding';
  static const feed = '/';
  static const answer = '/answer';
  static const inbox = '/inbox';
  static const me = '/me';
  static const meEdit = '/me/edit';
  static const settings = '/settings';
  static const verifyHumg = '/verify-humg';
  static const admin = '/admin';
  static const userProfile = '/user';
  static const trackQuestion = '/track-question';
  static const scanProfileQr = '/scan-profile-qr';
}

/// External URLs opened via url_launcher.
abstract final class AppUrls {
  static const String terms = 'https://askme-humg-app.web.app/terms';
  static const String privacy = 'https://askme-humg-app.web.app/privacy';
}
