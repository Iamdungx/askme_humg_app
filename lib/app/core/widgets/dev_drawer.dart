import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/modules/auth/domain/auth_user.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/config/languages.dart';

/// Dev-only navigation drawer.
/// Only rendered in [kDebugMode] — wrap call sites with `kDebugMode ? ... : null`.
class DevDrawer extends ConsumerWidget {
  const DevDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    final authAsync = ref.watch(authStateProvider);
    final AuthUser? user = authAsync.asData?.value;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            _Header(user: user),
            const Divider(),
            _NavTile(
              icon: LucideIcons.house,
              label: 'Feed  /  (placeholder)',
              onTap: () => _go(context, '/'),
            ),
            if (user != null) ...[
              _NavTile(
                icon: LucideIcons.inbox,
                label: 'Inbox  /inbox',
                onTap: () => _go(context, '/inbox'),
              ),
              _NavTile(
                icon: LucideIcons.circleUser,
                label: 'My Profile  /u/:uid',
                onTap: () =>
                    _go(context, '/me'),
              ),
              _NavTile(
                icon: LucideIcons.userSearch,
                label: 'Visit Profile by UID…',
                onTap: () => _showVisitProfileDialog(context, user.uid),
              ),
              _NavTile(
                icon: LucideIcons.shieldCheck,
                label: 'Admin  /admin  (placeholder)',
                onTap: () => _go(context, '/admin'),
              ),
            ],
            const Divider(),
            _NavTile(
              icon: LucideIcons.logIn,
              label: 'Login Screen',
              onTap: () => _go(context, '/login'),
            ),
            _NavTile(
              icon: LucideIcons.sparkles,
              label: 'Splash Screen',
              onTap: () => _go(context, '/splash'),
            ),
            if (user != null) ...[
              const Divider(),
              _NavTile(
                icon: LucideIcons.logOut,
                label: 'Sign Out',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(authProvider.notifier).signOut();
                },
              ),
            ],
            const Divider(),
            _DevToolsSection(themeMode: themeMode, locale: locale, ref: ref),
            const Divider(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                '🛠 DEV DRAWER — remove before release',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _go(BuildContext context, String location) {
    Navigator.pop(context);
    context.go(location);
  }

  void _showVisitProfileDialog(BuildContext context, String myUid) {
    final controller = TextEditingController(text: myUid);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Visit Profile by UID'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'User ID',
            hintText: 'Paste any Firebase UID',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final uid = controller.text.trim();
              if (uid.isEmpty) return;
              Navigator.pop(ctx);
              Navigator.pop(context); // close drawer
              context.go('/u/$uid');
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
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
                child: const Icon(LucideIcons.bug, color: Colors.orange),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dev Navigation',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      dense: true,
      leading: Icon(icon, color: effectiveColor, size: 20),
      title: Text(label, style: TextStyle(fontSize: 13, color: effectiveColor)),
      onTap: onTap,
    );
  }
}

class _DevToolsSection extends StatelessWidget {
  const _DevToolsSection({
    required this.themeMode,
    required this.locale,
    required this.ref,
  });

  final ThemeMode themeMode;
  final Locale locale;
  final WidgetRef ref;

  static const _langLabels = {
    'vi': '🇻🇳 VI',
    'en': '🇬🇧 EN',
    'ja': '🇯🇵 JA',
  };

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = themeMode == ThemeMode.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              'DEV TOOLS',
              style: tt.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                letterSpacing: 1.2,
              ),
            ),
          ),
          // Theme toggle
          Row(
            children: [
              Icon(
                isDark ? LucideIcons.moon : LucideIcons.sun,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                isDark ? 'Dark mode' : 'Light mode',
                style: tt.bodySmall?.copyWith(color: cs.onSurface),
              ),
              const Spacer(),
              Switch(
                value: isDark,
                onChanged: (_) => ref.read(themeModeProvider.notifier).toggle(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Language picker
          Row(
            children: [
              Icon(LucideIcons.languages, size: 18, color: cs.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                'Language',
                style: tt.bodySmall?.copyWith(color: cs.onSurface),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: locale.languageCode,
                isDense: true,
                underline: const SizedBox.shrink(),
                items: supportedLanguages
                    .map(
                      (l) => DropdownMenuItem(
                        value: l.languageCode,
                        child: Text(
                          _langLabels[l.languageCode] ?? l.languageCode,
                          style: tt.bodySmall,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(localeProvider.notifier).setLocale(Locale(val));
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
