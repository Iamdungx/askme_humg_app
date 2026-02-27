import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/config/app_routes.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// RouterNotifier — bridges Riverpod auth state to GoRouter's refreshListenable.
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Keep authStateProvider subscribed so ref.read() in redirect() always
    // returns the latest value instead of AsyncLoading.
    _ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      if (!next.isLoading) notifyListeners();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final path = state.matchedLocation;

    // Still resolving — hold position.
    if (authAsync.isLoading) return null;

    // Splash manages its own navigation; skip redirect entirely.
    if (path == const SplashRoute().location) return null;

    final isLoggedIn = authAsync.valueOrNull != null;

    // Unauthenticated → redirect to login for protected locations.
    final isProtected =
        protectedLocationPrefixes.any((prefix) => path.startsWith(prefix));
    if (!isLoggedIn && isProtected) return const LoginRoute().location;

    // Authenticated → leave the login screen.
    if (isLoggedIn && path == const LoginRoute().location) {
      return const FeedRoute().location;
    }

    return null;
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  final notifier = _RouterNotifier(ref);
  ref.onDispose(notifier.dispose);

  return GoRouter(
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    // All routes are declared in app_routes.dart via @TypedGoRoute.
    // build_runner generates $appRoutes from those annotations.
    routes: $appRoutes,
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
