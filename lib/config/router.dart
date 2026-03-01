import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/widgets/app_shell.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/feed_screen.dart';
import 'package:askme_humg/app/modules/profile/presentation/screens/profile_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/answer_compose_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/inbox_screen.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';
import 'package:askme_humg/config/app_routes.dart';

part 'router.g.dart';

// ---------------------------------------------------------------------------
// RouterNotifier
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen<AsyncValue<dynamic>>(authStateProvider, (_, next) {
      if (!next.isLoading) notifyListeners();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateProvider);
    final path = state.matchedLocation;

    if (authAsync.isLoading) return null;
    if (path == '/splash') return null;

    final user = authAsync.asData?.value;
    final isLoggedIn = user != null;

    // Unauthenticated → redirect to login for protected routes.
    final isProtected = protectedLocationPrefixes.any(
      (prefix) => path.startsWith(prefix),
    );
    if (!isLoggedIn && isProtected) return '/login';

    // Admin route — requires isAdmin custom claim.
    if (path.startsWith('/admin')) {
      if (!isLoggedIn) return '/login';
      if (user.isAdmin != true) return '/';
    }

    // Authenticated → leave the login screen.
    if (isLoggedIn && path == '/login') return '/';

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
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // ── Outside shell (full-screen, no bottom nav) ──────────────────────
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Deep-link profile for OTHER users — full-screen, no bottom nav.
      GoRoute(
        path: '/u/:userId',
        builder: (context, state) =>
            ProfileScreen(userId: state.pathParameters['userId']!),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const _AdminPlaceholder(),
      ),

      // ── Shell: 3 tabs with persistent bottom NavigationBar ───────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Public Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const FeedScreen(),
              ),
            ],
          ),

          // Tab 1 — Inbox (protected by redirect above)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/inbox',
                builder: (context, state) => const InboxScreen(),
                routes: [
                  GoRoute(
                    path: 'answer/:questionId',
                    builder: (context, state) => AnswerComposeScreen(
                      questionId: state.pathParameters['questionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Tab 2 — Own profile (/me)
          // userId is passed via extra when navigating: context.go('/me', extra: uid)
          // If not logged in, shows sign-in prompt.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/me',
                builder: (context, state) {
                  final userId = state.extra as String?;
                  if (userId == null || userId.isEmpty) {
                    return const _ProfileLoginPrompt();
                  }
                  return ProfileScreen(userId: userId);
                },
              ),
            ],
          ),
        ],
      ),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.error}')),
    ),
  );

  _initDeepLinks(router, ref);

  return router;
}

// ---------------------------------------------------------------------------
// Deep link initializer (UC-2.1)
// ---------------------------------------------------------------------------

void _initDeepLinks(GoRouter router, Ref ref) {
  final appLinks = AppLinks();

  final sub = appLinks.uriLinkStream.listen(
    (uri) {
      logger.i('Deep link warm-start: $uri');
      final path = uri.path;
      if (path.isNotEmpty && path != '/') router.go(path);
    },
    onError: (Object e, StackTrace s) {
      logger.w('Deep link stream error', error: e, stackTrace: s);
    },
  );
  ref.onDispose(sub.cancel);

  appLinks.getInitialLink().then((initialUri) {
    if (initialUri != null) {
      final path = initialUri.path;
      logger.i('Deep link cold-start: $initialUri');
      if (path.isNotEmpty && path != '/') router.go(path);
    }
  }).catchError((Object e, StackTrace s) {
    logger.w('Failed to get initial deep link', error: e, stackTrace: s);
  });
}

// ---------------------------------------------------------------------------
// Local widgets
// ---------------------------------------------------------------------------

class _ProfileLoginPrompt extends StatelessWidget {
  const _ProfileLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 72,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'Sign in to view your profile',
                style: tt.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.go('/login'),
                child: const Text('Sign in'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminPlaceholder extends StatelessWidget {
  const _AdminPlaceholder();

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        // TODO(phase-5): replace with AdminDashboardScreen — UC-5.2
        body: const Center(child: Text('Admin Dashboard')),
      );
}
