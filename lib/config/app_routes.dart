import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';

part 'app_routes.g.dart';

// ---------------------------------------------------------------------------
// Route tree — single source of truth for all paths and parameters.
//
// Build-runner generates:
//   • SplashRoute().go(context)  → navigates to /splash
//   • FeedRoute().go(context)    → navigates to /
//   • ProfileRoute(userId: id).go(context) → navigates to /u/:userId
//   etc.
//
// After editing, run:  melos run gen:assets
// ---------------------------------------------------------------------------

@TypedGoRoute<SplashRoute>(path: '/splash')
@immutable
class SplashRoute extends GoRouteData {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const SplashScreen();
}

@TypedGoRoute<FeedRoute>(path: '/')
@immutable
class FeedRoute extends GoRouteData {
  const FeedRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Feed');
}

@TypedGoRoute<LoginRoute>(path: '/login')
@immutable
class LoginRoute extends GoRouteData {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const LoginScreen();
}

@TypedGoRoute<InboxRoute>(
  path: '/inbox',
  routes: [
    TypedGoRoute<AnswerComposeRoute>(path: 'answer/:questionId'),
  ],
)
@immutable
class InboxRoute extends GoRouteData {
  const InboxRoute();

  /// Protected: requires authentication.
  static const requiresAuth = true;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Inbox');
}

@immutable
class AnswerComposeRoute extends GoRouteData {
  const AnswerComposeRoute({required this.questionId});

  final String questionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      _PlaceholderScreen(title: 'Answer: $questionId');
}

@TypedGoRoute<ProfileRoute>(path: '/u/:userId')
@immutable
class ProfileRoute extends GoRouteData {
  const ProfileRoute({required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      _PlaceholderScreen(title: 'Profile: $userId');
}

@TypedGoRoute<AdminRoute>(path: '/admin')
@immutable
class AdminRoute extends GoRouteData {
  const AdminRoute();

  /// Protected: requires authentication.
  static const requiresAuth = true;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const _PlaceholderScreen(title: 'Admin Dashboard');
}

// ---------------------------------------------------------------------------
// Centralised list of routes that require a logged-in user.
// Add a route class here instead of sprinkling strings in redirect().
// ---------------------------------------------------------------------------

/// Prefixes of routes that require authentication.
/// Keep in sync with the @TypedGoRoute path above each class.
const protectedLocationPrefixes = [
  '/inbox',
  '/admin',
];

// ---------------------------------------------------------------------------
// Placeholder — remove when feature screens are implemented
// ---------------------------------------------------------------------------

class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(title)),
        body: Center(child: Text(title)),
      );
}
