// Route path constants — used by _RouterNotifier and navigation callsites.
// The actual GoRoute tree is declared in router.dart (StatefulShellRoute).

/// Routes that require authentication. GoRouter checks `startsWith`.
const protectedLocationPrefixes = ['/inbox', '/admin'];

/// Named path constants for all app routes.
abstract final class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const feed = '/';
  static const inbox = '/inbox';
  static const me = '/me';
  static const meEdit = '/me/edit';
  static const settings = '/settings';
  static const verifyHumg = '/verify-humg';
  static const admin = '/admin';
  static const userProfile = '/user';
}

/// External URLs opened via url_launcher.
abstract final class AppUrls {
  static const String terms = 'https://askme.humg.edu.vn/terms';
  static const String privacy = 'https://askme.humg.edu.vn/privacy';
}
