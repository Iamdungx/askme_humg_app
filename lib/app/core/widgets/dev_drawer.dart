import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/config/app_routes.dart';

/// Dev-only navigation drawer.
/// Only rendered in [kDebugMode] — wrap call sites with `kDebugMode ? ... : null`.
class DevDrawer extends ConsumerWidget {
  const DevDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final authAsync = ref.watch(authStateProvider);
    final AuthUser? user = authAsync.asData?.value;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Header(user: user),
            const Divider(),
            _NavTile(
              icon: Icons.home_outlined,
              label: 'Feed  /  (placeholder)',
              onTap: () => _go(context, const FeedRoute().location),
            ),
            if (user != null) ...[
              _NavTile(
                icon: Icons.inbox_outlined,
                label: 'Inbox  /inbox  (placeholder)',
                onTap: () => _go(context, const InboxRoute().location),
              ),
              _NavTile(
                icon: Icons.person_outline,
                label: 'My Profile  /u/:uid',
                onTap: () => _go(context, ProfileRoute(userId: user.uid).location),
              ),
              _NavTile(
                icon: Icons.admin_panel_settings_outlined,
                label: 'Admin  /admin  (placeholder)',
                onTap: () => _go(context, const AdminRoute().location),
              ),
            ],
            const Divider(),
            _NavTile(
              icon: Icons.login_outlined,
              label: 'Login Screen',
              onTap: () => _go(context, const LoginRoute().location),
            ),
            _NavTile(
              icon: Icons.auto_awesome_outlined,
              label: 'Splash Screen',
              onTap: () => _go(context, const SplashRoute().location),
            ),
            if (user != null) ...[
              const Divider(),
              _NavTile(
                icon: Icons.logout,
                label: 'Sign Out',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '🛠 DEV DRAWER — remove before release',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.orange,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String location) {
    Navigator.pop(context); // close drawer first
    context.go(location);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.user});
  final AuthUser? user;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.bug_report, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dev Navigation',
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    () {
                      final u = user;
                      if (u == null) return 'Not logged in (guest)';
                      return 'Logged in: ${u.email}';
                    }(),
                    style: Theme.of(context).textTheme.labelSmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: effectiveColor, size: 20),
      title: Text(
        label,
        style: TextStyle(fontSize: 13, color: effectiveColor),
      ),
      onTap: onTap,
    );
  }
}
