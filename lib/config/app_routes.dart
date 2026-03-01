import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/widgets/dev_drawer.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/feed_screen.dart';
import 'package:askme_humg/app/modules/profile/presentation/screens/profile_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/answer_compose_screen.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/screens/inbox_screen.dart';
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
  Widget build(BuildContext context, GoRouterState state) =>
      const FeedScreen();
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
  Widget build(BuildContext context, GoRouterState state) =>
      const InboxScreen();
}

@immutable
class AnswerComposeRoute extends GoRouteData with $AnswerComposeRoute {
  const AnswerComposeRoute({required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AnswerComposeScreen(questionId: questionId);
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
