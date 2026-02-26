import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';

// Placeholder screens — sẽ được thay bằng màn hình thật sau khi implement từng feature
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(child: Text(title)),
    );
  }
}

final appRouter = GoRouter(
  initialLocation: '/splash',
  debugLogDiagnostics: true,
  routes: [
    // Splash
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (_, __) => const SplashScreen(),
    ),

    // Feed (Home)
    GoRoute(
      path: '/',
      name: 'feed',
      builder: (_, __) => const _PlaceholderScreen(title: 'Feed'),
    ),

    // Login
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (_, __) => const _PlaceholderScreen(title: 'Login'),
    ),

    // Inbox
    GoRoute(
      path: '/inbox',
      name: 'inbox',
      builder: (_, __) => const _PlaceholderScreen(title: 'Inbox'),
      routes: [
        // Answer Compose
        GoRoute(
          path: 'answer/:questionId',
          name: 'answer-compose',
          builder: (_, state) => _PlaceholderScreen(
            title: 'Answer: ${state.pathParameters['questionId']}',
          ),
        ),
      ],
    ),

    // Profile (deep link: askme.humg.edu.vn/u/{userId})
    GoRoute(
      path: '/u/:userId',
      name: 'profile',
      builder: (_, state) => _PlaceholderScreen(
        title: 'Profile: ${state.pathParameters['userId']}',
      ),
    ),

    // Admin
    GoRoute(
      path: '/admin',
      name: 'admin',
      builder: (_, __) => const _PlaceholderScreen(title: 'Admin Dashboard'),
    ),
  ],

  // Error page
  errorBuilder: (_, state) => Scaffold(
    body: Center(
      child: Text('Page not found: ${state.error}'),
    ),
  ),
);
