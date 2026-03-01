import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _version = '${info.version} (${info.buildNumber})');
    } catch (e) {
      logger.w('Failed to load package info', error: e);
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      logger.w('Could not launch $url');
    }
  }

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsSignOut),
        content: Text(l10n.settingsSignOutConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: Text(l10n.settingsSignOut),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(signOutProvider).call();
    if (mounted) context.go('/login');
  }

  void _clearCache() {
    final l10n = AppLocalizations.of(context);
    ref.invalidate(authStateProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.settingsClearCacheSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final user = ref.watch(authStateProvider).asData?.value;
    final isLoggedIn = user != null;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final showRealName = ref.watch(showRealNameProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: ListView(
        children: [
          // ── ACCOUNT (only when logged in) ─────────────────────────────
          if (isLoggedIn) ...[
            _SectionHeader(label: l10n.settingsSectionAccount),
            _SettingsTile(
              icon: LucideIcons.userPen,
              label: l10n.settingsEditProfile,
              trailing: const Icon(LucideIcons.chevronRight, size: 18),
              onTap: () => context.push('/me/edit'),
            ),
            _SettingsTile(
              icon: LucideIcons.badgeCheck,
              label: l10n.settingsHumgVerification,
              trailing: Text(
                user.isHumgVerified == true
                    ? l10n.settingsHumgVerified
                    : l10n.settingsHumgNotVerified,
                style: tt.bodySmall?.copyWith(
                  color: user.isHumgVerified == true
                      ? cs.primary
                      : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              onTap: user.isHumgVerified == true
                  ? null
                  : () => context.push('/verify-humg'),
            ),
            _SettingsTile(
              icon: LucideIcons.eye,
              label: l10n.settingsShowRealName,
              subtitle: l10n.settingsShowRealNameSubtitle,
              trailing: Switch(
                value: showRealName,
                onChanged: (v) {
                  ref.read(showRealNameProvider.notifier).toggle(v);
                  // TODO(v2): persist showRealName to Firestore users doc
                },
              ),
            ),
          ],

          // ── NOTIFICATIONS (logged in only, FCM — v2) ──────────────────
          if (isLoggedIn) ...[
            _SectionHeader(label: l10n.settingsSectionNotifications),
            _SettingsTile(
              icon: LucideIcons.bellRing,
              label: l10n.settingsNotifNewQuestion,
              subtitle: l10n.settingsNotifComingSoon,
              trailing: Switch(
                // TODO(v2): wire to FCM topic subscription + SharedPreferences
                value: false,
                onChanged: null,
              ),
            ),
            _SettingsTile(
              icon: LucideIcons.messageCircle,
              label: l10n.settingsNotifNewComment,
              subtitle: l10n.settingsNotifComingSoon,
              trailing: Switch(
                // TODO(v2): wire to FCM topic subscription + SharedPreferences
                value: false,
                onChanged: null,
              ),
            ),
          ],

          // ── APP ───────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionApp),
          _SettingsTile(
            icon: LucideIcons.languages,
            label: l10n.settingsLanguage,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _localeName(locale.languageCode, l10n),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 18, color: cs.outline),
              ],
            ),
            onTap: () => _showLanguageDialog(context, l10n, locale),
          ),
          _SettingsTile(
            icon: LucideIcons.sunMoon,
            label: l10n.settingsTheme,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _themeLabel(themeMode, l10n),
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(LucideIcons.chevronRight, size: 18, color: cs.outline),
              ],
            ),
            onTap: () => _showThemeDialog(context, l10n, themeMode),
          ),
          _SettingsTile(
            icon: LucideIcons.trash2,
            label: l10n.settingsClearCache,
            onTap: _clearCache,
          ),

          // ── ABOUT ─────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionAbout),
          _SettingsTile(
            icon: LucideIcons.info,
            label: l10n.settingsVersion,
            trailing: Text(
              _version.isEmpty ? '...' : _version,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          _SettingsTile(
            icon: LucideIcons.fileText,
            label: l10n.settingsTermsOfService,
            trailing: Icon(LucideIcons.externalLink, size: 16, color: cs.outline),
            onTap: () => _launchUrl('https://askme.humg.edu.vn/terms'),
          ),
          _SettingsTile(
            icon: LucideIcons.shield,
            label: l10n.settingsPrivacyPolicy,
            trailing: Icon(LucideIcons.externalLink, size: 16, color: cs.outline),
            onTap: () => _launchUrl('https://askme.humg.edu.vn/privacy'),
          ),

          // ── SIGN OUT ──────────────────────────────────────────────────
          if (isLoggedIn) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(LucideIcons.logOut),
                label: Text(l10n.settingsSignOut),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
          Center(
            child: Text(
              'Crafted for Mining & Geology Students',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.3),
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _localeName(String code, AppLocalizations l10n) => switch (code) {
    'vi' => l10n.languageVietnamese,
    'en' => l10n.languageEnglish,
    'ja' => l10n.languageJapanese,
    _ => code,
  };

  String _themeLabel(ThemeMode mode, AppLocalizations l10n) => switch (mode) {
    ThemeMode.light => l10n.settingsThemeLight,
    ThemeMode.dark => l10n.settingsThemeDark,
    ThemeMode.system => l10n.settingsThemeSystem,
  };

  Future<void> _showLanguageDialog(
    BuildContext context,
    AppLocalizations l10n,
    Locale current,
  ) async {
    final options = [
      (const Locale('vi'), l10n.languageVietnamese),
      (const Locale('en'), l10n.languageEnglish),
      (const Locale('ja'), l10n.languageJapanese),
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsLanguage),
        children: options.map((opt) {
          final (locale, name) = opt;
          final isSelected = locale.languageCode == current.languageCode;
          return ListTile(
            title: Text(name),
            leading: Radio<String>(
              value: locale.languageCode,
              groupValue: current.languageCode,
              onChanged: (v) {
                if (v != null) {
                  ref.read(localeProvider.notifier).setLocale(Locale(v));
                }
                Navigator.of(ctx).pop();
              },
            ),
            selected: isSelected,
            onTap: () {
              ref.read(localeProvider.notifier).setLocale(locale);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _showThemeDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeMode current,
  ) async {
    final options = [
      (ThemeMode.system, l10n.settingsThemeSystem),
      (ThemeMode.light, l10n.settingsThemeLight),
      (ThemeMode.dark, l10n.settingsThemeDark),
    ];
    await showDialog<void>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.settingsTheme),
        children: options.map((opt) {
          final (mode, name) = opt;
          final isSelected = mode == current;
          return ListTile(
            title: Text(name),
            leading: Radio<ThemeMode>(
              value: mode,
              groupValue: current,
              onChanged: (v) {
                if (v != null) {
                  ref.read(themeModeProvider.notifier).setMode(v);
                }
                Navigator.of(ctx).pop();
              },
            ),
            selected: isSelected,
            onTap: () {
              ref.read(themeModeProvider.notifier).setMode(mode);
              Navigator.of(ctx).pop();
            },
          );
        }).toList(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local widgets
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: cs.primary, size: 22),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                  ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null || trailing is Switch,
    );
  }
}
