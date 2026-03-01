import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_durations.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Persistent shell scaffold wrapping the 4 bottom-nav tabs:
///   0 → Feed      (/)
///   1 → Inbox     (/inbox)
///   2 → Profile   (/me)
///   3 → Settings  (/settings)
///
/// Full-screen routes (Login, AnswerCompose, /u/:userId, Admin, Splash,
/// /me/edit, /verify-humg) are declared outside the StatefulShellRoute
/// and render without this shell.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _visible = true;

  void _switchTab(int index) {
    if (index == widget.navigationShell.currentIndex) {
      widget.navigationShell.goBranch(index, initialLocation: true);
      return;
    }
    // Fade out → switch → fade in
    setState(() => _visible = false);
    Future.delayed(AppDuration.fast, () {
      if (!mounted) return;
      widget.navigationShell.goBranch(index);
      setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final isLoggedIn = ref.watch(authStateProvider).asData?.value != null;
    final navigationShell = widget.navigationShell;

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
      body: AnimatedOpacity(
        opacity: _visible ? 1.0 : 0.0,
        duration: AppDuration.fast,
        curve: Curves.easeInOut,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _switchTab,
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
          NavigationDestination(
            icon: const Icon(LucideIcons.settings),
            selectedIcon: Icon(LucideIcons.settings, color: cs.secondary),
            label: l10n.navSettings,
          ),
        ],
      ),
    );
  }
}
