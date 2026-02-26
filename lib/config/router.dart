import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/screens/login_screen.dart';
import 'package:askme_humg/app/modules/splash/presentation/screens/splash_screen.dart';

part 'router.g.dart';

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

// ---------------------------------------------------------------------------
// RouterNotifier — bridge giữa Riverpod auth state và GoRouter listenable
// ---------------------------------------------------------------------------

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    // Lắng nghe authStateProvider, notify router khi auth state thay đổi.
    // QUAN TRỌNG: listen() này giữ authStateProvider luôn subscribed —
    // đảm bảo ref.read() trong redirect() nhận được giá trị mới nhất thay vì AsyncLoading.
    // Không được xóa listen này dù không dùng trực tiếp giá trị ở đây.
    _ref.listen<AsyncValue>(authStateProvider, (_, next) {
      // Bỏ qua AsyncLoading để tránh re-evaluate router không cần thiết.
      if (!next.isLoading) notifyListeners();
    });
  }

  final Ref _ref;

  String? redirect(BuildContext context, GoRouterState state) {
    // ref.read hoạt động đúng ở đây vì listen() phía trên giữ stream luôn active.
    final authAsync = _ref.read(authStateProvider);
    final currentPath = state.matchedLocation;

    final isOnSplash = currentPath == '/splash';
    final isOnLogin = currentPath == '/login';

    // Đang loading → giữ nguyên
    if (authAsync.isLoading) return null;

    final isLoggedIn = authAsync.valueOrNull != null;

    // Splash tự điều hướng qua initState
    if (isOnSplash) return null;

    // Chưa login → về login nếu vào protected route
    final protectedRoutes = ['/inbox', '/admin'];
    final isProtected = protectedRoutes.any((r) => currentPath.startsWith(r));
    if (!isLoggedIn && isProtected) return '/login';

    // Đã login → không cần ở login nữa
    if (isLoggedIn && isOnLogin) return '/';

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
    initialLocation: '/splash',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: notifier,
    redirect: notifier.redirect,
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

      // Login — UC-1.1
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (_, __) => const LoginScreen(),
      ),

      // Inbox
      GoRoute(
        path: '/inbox',
        name: 'inbox',
        builder: (_, __) => const _PlaceholderScreen(title: 'Inbox'),
        routes: [
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
        builder: (_, __) =>
            const _PlaceholderScreen(title: 'Admin Dashboard'),
      ),
    ],

    // Error page
    errorBuilder: (_, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.error}'),
      ),
    ),
  );
}
