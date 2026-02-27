import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
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
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Inbox');
}

@immutable
class AnswerComposeRoute extends GoRouteData with $AnswerComposeRoute {
  const AnswerComposeRoute({required this.questionId});

  final String questionId;

  @override
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
      _PlaceholderScreen(title: 'Profile: $userId');
}

@TypedGoRoute<AdminRoute>(path: '/admin')
@immutable
class AdminRoute extends GoRouteData with $AdminRoute {
  const AdminRoute();

  @override
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
    appBar: AppBar(title: Text(title)),
    body: Center(child: Text(title)),
  );
}
