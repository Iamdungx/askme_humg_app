import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/core/widgets/app_shell.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/feed_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/answer_detail_screen.dart';
import 'package:askme_humg/app/modules/onboarding/presentation/onboarding_providers.dart';
import 'package:askme_humg/app/modules/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:askme_humg/app/modules/profile/presentation/screens/profile_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/answer_compose_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/inbox_screen.dart';
import 'package:askme_humg/app/modules/settings/presentation/edit_profile_screen.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_screen.dart';
import 'package:askme_humg/app/modules/moderation/presentation/screens/admin_dashboard_screen.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/verify_humg_screen.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';

part 'router.g.dart';

// Instant no-animation transition for tab switches — preserves IndexedStack state.
Widget _noTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) => child;

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
    if (path == AppRoutes.splash) return null;

    final onboardingCompleted = _ref.read(onboardingCompletedProvider);
    final isDeepLinkProfile = path.startsWith(AppRoutes.userProfile);
    final isDeepLinkAnswer = path.startsWith(AppRoutes.answer);
    if (!onboardingCompleted &&
        path != AppRoutes.onboarding &&
        !isDeepLinkProfile &&
        !isDeepLinkAnswer) {
      return AppRoutes.onboarding;
    }

    final user = authAsync.asData?.value;
    final isLoggedIn = user != null;

    // Unauthenticated → redirect to login for protected routes.
    final isProtected = protectedLocationPrefixes.any(
      (prefix) => path.startsWith(prefix),
    );
    if (!isLoggedIn && isProtected) return AppRoutes.login;

    // /me and /settings require login but NOT HUMG verification.
    if (!isLoggedIn &&
        (path.startsWith(AppRoutes.me) || path.startsWith(AppRoutes.settings))) {
      return AppRoutes.login;
    }

    // Admin route — requires isAdmin custom claim.
    if (path.startsWith(AppRoutes.admin)) {
      if (!isLoggedIn) return AppRoutes.login;
      if (user.isAdmin != true) return AppRoutes.feed;
    }

    // Authenticated → leave the login screen.
    if (isLoggedIn && path == AppRoutes.login) return AppRoutes.feed;

    // UC-2.1 — Deep-link to own profile → redirect to /me tab (has bottom nav).
    // /user/{userId} is a full-screen route without bottom nav; when the
    // logged-in user scans their own QR code they'd see no back button and no
    // shell navigation, so we bounce them to the /me shell tab instead.
    if (isLoggedIn && state.pathParameters['userId'] == user.uid) {
      return AppRoutes.me;
    }

    // UC-1.3 — Redirect to HUMG verification if not yet verified.
    // Exempt paths/prefixes are defined in app_routes.dart (isHumgVerifyExempt).
    if (isLoggedIn && user.isHumgVerified == false && !isHumgVerifyExempt(path)) {
      return AppRoutes.verifyHumg;
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

  final     router = GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
    onException: (context, state, router) {
      final uri = Uri.tryParse(state.uri.toString());
      if (uri != null) {
        final path = _resolveDeepLinkPath(uri);
        if (path != null) {
          router.go(path);
          return;
        }
      }
      router.go(AppRoutes.feed);
    },
    routes: [
      // ── Outside shell (full-screen, no bottom nav) ──────────────────────
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      // Deep-link profile for OTHER users — full-screen, no bottom nav.
      GoRoute(
        path: '${AppRoutes.userProfile}/:userId',
        builder: (context, state) =>
            ProfileScreen(userId: state.pathParameters['userId']!),
      ),
      // Deep-link answer detail — full-screen, no bottom nav.
      GoRoute(
        path: '${AppRoutes.answer}/:answerId',
        builder: (context, state) =>
            AnswerDetailScreen(answerId: state.pathParameters['answerId']!),
      ),
      // AnswerCompose is full-screen — no bottom nav visible while composing.
      GoRoute(
        path: '${AppRoutes.inbox}/answer/:questionId',
        builder: (context, state) => AnswerComposeScreen(
          questionId: state.pathParameters['questionId']!,
        ),
      ),
      // Edit Profile — full-screen, accessible from Profile tab and Settings tab.
      GoRoute(
        path: AppRoutes.meEdit,
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyHumg,
        builder: (context, state) => const VerifyHumgScreen(),
      ),

      // ── Shell: 4 tabs with persistent bottom NavigationBar ───────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          // Tab 0 — Public Feed
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.feed,
                pageBuilder: (context, state) => const CustomTransitionPage(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: _noTransition,
                  child: FeedScreen(),
                ),
              ),
            ],
          ),

          // Tab 1 — Inbox (protected by redirect above)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.inbox,
                pageBuilder: (context, state) => const CustomTransitionPage(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: _noTransition,
                  child: InboxScreen(),
                ),
              ),
            ],
          ),

          // Tab 2 — Own profile (/me)
          // _MeTab reads authStateProvider directly — survives GoRouter rebuilds.
          // No state.extra needed, so auth refresh never breaks the tab.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.me,
                pageBuilder: (context, state) => const CustomTransitionPage(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: _noTransition,
                  child: _MeTab(),
                ),
              ),
            ],
          ),

          // Tab 3 — Settings (/settings)
          // Visible to all users; account-specific items are hidden when guest.
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) => const CustomTransitionPage(
                  transitionDuration: Duration.zero,
                  reverseTransitionDuration: Duration.zero,
                  transitionsBuilder: _noTransition,
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
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
      final path = _resolveDeepLinkPath(uri);
      if (path != null) router.go(path);
    },
    onError: (Object e, StackTrace s) {
      logger.w('Deep link stream error', error: e, stackTrace: s);
    },
  );
  ref.onDispose(sub.cancel);

  appLinks.getInitialLink().then((initialUri) {
    if (initialUri != null) {
      logger.i('Deep link cold-start: $initialUri');
      final path = _resolveDeepLinkPath(initialUri);
      if (path != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => router.go(path));
      }
    }
  }).catchError((Object e, StackTrace s) {
    logger.w('Failed to get initial deep link', error: e, stackTrace: s);
  });
}

// ---------------------------------------------------------------------------
// Local widgets
// ---------------------------------------------------------------------------

/// Profile tab widget — reads auth state directly so it survives GoRouter
/// rebuilds (e.g. refreshListenable triggers). Never relies on state.extra.
class _MeTab extends ConsumerWidget {
  const _MeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).asData?.value;
    if (user == null) return const _ProfileLoginPrompt();
    if (user.isAdmin == true) {
      return _AdminMeWrapper(userId: user.uid);
    }
    return ProfileScreen(userId: user.uid);
  }
}

class _AdminMeWrapper extends StatelessWidget {
  const _AdminMeWrapper({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.secondary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.secondary.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.shieldCheck, color: cs.secondary, size: 20),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.adminEntryTitle,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: cs.onSurface,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            l10n.adminEntrySubtitle,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => context.push(AppRoutes.admin),
                      child: Text(l10n.adminEntryButton),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(child: ProfileScreen(userId: userId)),
          ],
        ),
      ),
    );
  }
}

class _ProfileLoginPrompt extends StatelessWidget {
  const _ProfileLoginPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.circleUserRound,
                size: 72,
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityHint),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                l10n.authSubtitle,
                style: tt.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => context.go(AppRoutes.login),
                child: Text(l10n.authSignInWithGoogle),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

// Resolves both https and custom scheme (askme://) deep links to GoRouter paths.
// askme://user/{id} → host="user", pathSegments=["{id}"] → /user/{id}
// https://askme-humg-app.web.app/user/{id} → path="/user/{id}"
String? _resolveDeepLinkPath(Uri uri) {
  logger.d('resolveDeepLinkPath: scheme=${uri.scheme} host=${uri.host} path=${uri.path} segments=${uri.pathSegments}');
  if (uri.scheme == 'askme') {
    // askme://user/{userId} → host="user", pathSegments=["{userId}"]
    final pathSegments = uri.pathSegments;
    if (uri.host == 'user' && pathSegments.isNotEmpty) {
      return '/user/${pathSegments.first}';
    }
    // Fallback: treat host as route segment + pathSegments
    if (uri.host.isNotEmpty) return '/${uri.host}${uri.path}';
    return null;
  }
  // HTTPS scheme — only pass the path portion, never full URI.
  if (uri.scheme == 'https' || uri.scheme == 'http') {
    final path = uri.path;
    if (path.isNotEmpty && path != '/') return path;
    return null;
  }
  return null;
}
