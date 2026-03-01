import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
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
    final isLoggedIn =
        ref.watch(authStateProvider).asData?.value != null;

    // Unanswered count for Inbox badge — 0 when logged out or provider not ready.
    // asData is null when loading/error; parentheses make ?? 0 precedence explicit.
    final unansweredCount = isLoggedIn
        ? (ref
              .watch(inboxProvider)
              .asData
              ?.value
              .where((q) => q.status == 'unanswered')
              .length ??
            0)
        : 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => _onTabSelected(context, index),
        indicatorColor: cs.secondary.withValues(alpha: 0.15),
        destinations: [
          NavigationDestination(
            icon: const Icon(LucideIcons.house),
            selectedIcon: Icon(LucideIcons.house, color: cs.secondary),
            label: l10n.navFeed,
          ),
          NavigationDestination(
            icon: Badge(
              label: Text('$unansweredCount'),
              isLabelVisible: unansweredCount > 0,
              child: const Icon(LucideIcons.mailbox),
            ),
            selectedIcon: Badge(
              label: Text('$unansweredCount'),
              isLabelVisible: unansweredCount > 0,
              child: Icon(LucideIcons.mailbox, color: cs.secondary),
            ),
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

  void _onTabSelected(BuildContext context, int index) {
    if (index == navigationShell.currentIndex) {
      // Tapping active tab scrolls back to top (re-navigate to initial location).
      navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    // Profile tab (/me): _MeTab reads authStateProvider itself — no extra needed.
    navigationShell.goBranch(index);
  }
}
