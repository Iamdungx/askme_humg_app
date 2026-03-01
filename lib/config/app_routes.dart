// Route path constants — used by _RouterNotifier and navigation callsites.
// The actual GoRoute tree is declared in router.dart (StatefulShellRoute).

/// Routes that require authentication. GoRouter checks `startsWith`.
const protectedLocationPrefixes = ['/inbox', '/admin'];
