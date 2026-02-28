import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/widgets/dev_drawer.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/profile/presentation/screens/profile_screen.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';

part 'app_routes.g.dart';

@TypedGoRoute<SplashRoute>(path: '/splash')
@immutable
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SplashScreen();
}

@TypedGoRoute<FeedRoute>(path: '/')
@immutable
class FeedRoute extends GoRouteData with $FeedRoute {
  const FeedRoute();

  @override
  // TODO(phase-4): replace with FeedScreen — UC-4.1 public feed
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Feed');
}

@TypedGoRoute<LoginRoute>(path: '/login')
@immutable
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}

@TypedGoRoute<InboxRoute>(
  path: '/inbox',
  routes: [TypedGoRoute<AnswerComposeRoute>(path: 'answer/:questionId')],
)
@immutable
class InboxRoute extends GoRouteData with $InboxRoute {
  const InboxRoute();

  @override
  // TODO(phase-3): replace with InboxScreen — UC-3.2 manage inbox (2 tabs: unanswered / answered)
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Inbox');
}

@immutable
class AnswerComposeRoute extends GoRouteData with $AnswerComposeRoute {
  const AnswerComposeRoute({required this.questionId});

  final String questionId;

  @override
  // TODO(phase-3): replace with AnswerComposeScreen — UC-3.3 answer & publish (WriteBatch required)
  Widget build(BuildContext context, GoRouterState state) =>
      _PlaceholderScreen(title: 'Answer: $questionId');
}

@TypedGoRoute<ProfileRoute>(path: '/u/:userId')
@immutable
class ProfileRoute extends GoRouteData with $ProfileRoute {
  const ProfileRoute({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      ProfileScreen(userId: userId);
}

@TypedGoRoute<AdminRoute>(path: '/admin')
@immutable
class AdminRoute extends GoRouteData with $AdminRoute {
  const AdminRoute();

  @override
  // TODO(phase-5): replace with AdminDashboardScreen — UC-5.2 admin moderate (requires admin claim)
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Admin Dashboard');
}

/// Prefixes of routes that require authentication.
const protectedLocationPrefixes = ['/inbox', '/admin'];

// Placeholder — remove when feature screens are implemented
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        if (kDebugMode)
          Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(LucideIcons.bug),
              tooltip: 'Dev nav',
              onPressed: () => Scaffold.of(ctx).openDrawer(),
            ),
          ),
      ],
    ),
    drawer: kDebugMode ? const DevDrawer() : null,
    body: Center(child: Text(title)),
  );
}
