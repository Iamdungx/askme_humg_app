import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Persistent shell scaffold wrapping the 3 bottom-nav tabs:
///   0 → Feed      (/)
///   1 → Inbox     (/inbox)
///   2 → Profile   (/me)
///
/// Full-screen routes (Login, AnswerCompose, /u/:userId, Admin, Splash) are
/// declared outside the StatefulShellRoute and render without this shell.
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final user = ref.watch(authStateProvider).asData?.value;
    final isLoggedIn = user != null;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTabSelected(context, ref, index),
        indicatorColor: cs.secondary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house),
            selectedIcon: Icon(LucideIcons.house, color: cs.secondary),
            label: l10n.navFeed,
          ),
          NavigationDestination(
            icon: const Icon(LucideIcons.mailbox),
            selectedIcon: Icon(LucideIcons.mailbox, color: cs.secondary),
            label: l10n.navInbox,
          ),
          NavigationDestination(
            icon: Icon(
              isLoggedIn ? LucideIcons.circleUserRound : LucideIcons.logIn,
            ),
            selectedIcon: Icon(
              isLoggedIn ? LucideIcons.circleUserRound : LucideIcons.logIn,
              color: cs.secondary,
            ),
            label: l10n.navProfile,
          ),
        ],
      ),
    );
  }

  void _onTabSelected(BuildContext context, WidgetRef ref, int index) {
    if (index == navigationShell.currentIndex) {
      // Tapping active tab re-navigates to its initial location (scroll to top).
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }

    if (index == 2) {
      // Profile tab: pass userId as extra so GoRoute builder receives it.
      final user = ref.read(authStateProvider).asData?.value;
      context.go('/me', extra: user?.uid ?? '');
      return;
    }

    navigationShell.goBranch(index);
  }
}
