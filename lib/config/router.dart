import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
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

    // asData?.value: returns null on both AsyncLoading and AsyncError,
    // treating error state as logged-out (safe fallback).
    final isLoggedIn = authAsync.asData?.value != null;

    // Unauthenticated → redirect to login for protected locations.
    final isProtected = protectedLocationPrefixes.any(
      (prefix) => path.startsWith(prefix),
    );
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

  final router = GoRouter(
    initialLocation: const SplashRoute().location,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    // All routes are declared in app_routes.dart via @TypedGoRoute.
    // build_runner generates $appRoutes from those annotations.
    routes: $appRoutes,
    errorBuilder: (_, state) =>
        Scaffold(body: Center(child: Text('Page not found: ${state.error}'))),
  );

  // UC-2.1: Deep link handling via app_links.
  // The warm-start subscription is registered synchronously so that:
  //   1. No warm-start links are missed during the cold-start await gap.
  //   2. ref.onDispose is always called even if the provider is disposed early.
  _initDeepLinks(router, ref);

  return router;
}

// ---------------------------------------------------------------------------
// Deep link initializer — cold-start + warm-start (UC-2.1)
// ---------------------------------------------------------------------------

void _initDeepLinks(GoRouter router, Ref ref) {
  final appLinks = AppLinks();

  // Warm-start: subscribe synchronously before any await so that no links
  // are missed and the dispose callback is always registered.
  final sub = appLinks.uriLinkStream.listen(
    (uri) {
      logger.i('Deep link warm-start: $uri');
      router.go(uri.path);
    },
    onError: (Object e, StackTrace s) {
      logger.w('Deep link stream error', error: e, stackTrace: s);
    },
  );
  ref.onDispose(sub.cancel);

  // Cold-start: app opened from scratch via deep link (async, safe to fire-and-forget
  // because warm-start subscription above is already active).
  appLinks.getInitialLink().then((initialUri) {
    if (initialUri != null) {
      logger.i('Deep link cold-start: $initialUri');
      router.go(initialUri.path);
    }
  }).catchError((Object e, StackTrace s) {
    logger.w('Failed to get initial deep link', error: e, stackTrace: s);
  });
}
