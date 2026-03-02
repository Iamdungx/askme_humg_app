import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/layout/app_bottom_sheet.dart';
import 'package:askme_humg/app/core/values/app_typography.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/settings/data/cache_service.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/config/app_routes.dart';
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

  Future<void> _signOut() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      builder: (ctx) => _SignOutSheet(l10n: l10n),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(authProvider.notifier).signOut();
    // GoRouter's refreshListenable handles navigation to /login automatically
    // once authStateProvider emits null — no manual context.go needed here.
  }

  Future<void> _clearCache() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(cacheClearerProvider.notifier).clear();
    if (!mounted) return;
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
    final cacheSizeAsync = ref.watch(cacheSizeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        automaticallyImplyLeading: false,
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: ListView(
        children: [
          // ── ACCOUNT (only when logged in) ─────────────────────────────
          if (isLoggedIn) ...[
            _SectionHeader(label: l10n.settingsSectionAccount),
            _SettingsTile(
              icon: LucideIcons.userPen,
              label: l10n.settingsEditProfile,
              trailing: const Icon(LucideIcons.chevronRight, size: AppIconSize.md),
              onTap: () => context.push(AppRoutes.meEdit),
            ),
            _SettingsTile(
              icon: LucideIcons.badgeCheck,
              label: l10n.settingsHumgVerification,
              trailing: user.isHumgVerified == true
                  ? Text(
                      l10n.settingsHumgVerified,
                      style: tt.bodySmall?.copyWith(color: cs.primary),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.settingsHumgNotVerified,
                          style: tt.bodySmall?.copyWith(color: cs.error),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Icon(LucideIcons.circleAlert, size: AppIconSize.md, color: cs.error),
                      ],
                    ),
              onTap: user.isHumgVerified == true
                  ? null
                  : () => context.push(AppRoutes.verifyHumg),
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
                    color: cs.onSurface.withValues(alpha: AppSemanticColors.opacitySubtle),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(LucideIcons.chevronRight, size: AppIconSize.md, color: cs.outline),
              ],
            ),
            onTap: () => _showLanguageDialog(context, l10n, locale),
          ),
          ListTile(
            leading: Icon(LucideIcons.sunMoon, color: cs.primary, size: AppIconSize.lg),
            title: Text(l10n.settingsTheme),
            trailing: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: const Icon(LucideIcons.sun, size: AppIconSize.sm),
                ),
                ButtonSegment(
                  value: ThemeMode.system,
                  icon: const Icon(LucideIcons.monitor, size: AppIconSize.sm),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: const Icon(LucideIcons.moon, size: AppIconSize.sm),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).setMode(s.first),
              style: const ButtonStyle(
                visualDensity: VisualDensity.compact,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
          _SettingsTile(
            icon: LucideIcons.trash2,
            label: l10n.settingsClearCache,
            trailing: Text(
              cacheSizeAsync.when(
                data: CacheService.formatBytes,
                loading: () => CacheService.loadingPlaceholder,
                error: (_, _) => CacheService.errorPlaceholder,
              ),
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
              ),
            ),
            onTap: _clearCache,
          ),

          // ── ABOUT ─────────────────────────────────────────────────────
          _SectionHeader(label: l10n.settingsSectionAbout),
          _SettingsTile(
            icon: LucideIcons.info,
            label: l10n.settingsVersion,
            trailing: Text(
              _version.isEmpty ? CacheService.loadingPlaceholder : _version,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
              ),
            ),
          ),
          _SettingsTile(
            icon: LucideIcons.fileText,
            label: l10n.settingsTermsOfService,
            trailing: Text(
              l10n.settingsNotifComingSoon,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
              ),
            ),
            onTap: null,
          ),
          _SettingsTile(
            icon: LucideIcons.shield,
            label: l10n.settingsPrivacyPolicy,
            trailing: Text(
              l10n.settingsNotifComingSoon,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
              ),
            ),
            onTap: null,
          ),

          // ── SIGN OUT ──────────────────────────────────────────────────
          if (isLoggedIn) ...[
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: OutlinedButton.icon(
                onPressed: _signOut,
                icon: const Icon(LucideIcons.logOut),
                label: Text(l10n.settingsSignOut),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: AppSemanticColors.opacityDisabled)),
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppSpacing.xxl),
          Center(
            child: Text(
              l10n.settingsTagline,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityHint),
                fontSize: AppTypography.fontSizeCaption,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
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
        children: [
          RadioGroup<String>(
            groupValue: current.languageCode,
            onChanged: (v) {
              if (v != null) {
                ref.read(localeProvider.notifier).setLocale(Locale(v));
              }
              Navigator.of(ctx).pop();
            },
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: options.map((opt) {
                final (locale, name) = opt;
                return RadioListTile<String>(
                  secondary: Text(
                    _flagFor(locale.languageCode),
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(name),
                  value: locale.languageCode,
                  selected: locale.languageCode == current.languageCode,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _flagFor(String code) => switch (code) {
    'vi' => '🇻🇳',
    'en' => '🇬🇧',
    'ja' => '🇯🇵',
    _ => '🌐',
  };

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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.smPlus,
      ),
      child: Text(
        label.toUpperCase(),
        style: tt.labelSmall?.copyWith(
          color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
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
      leading: Icon(icon, color: cs.primary, size: AppIconSize.lg),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: AppSemanticColors.opacityDisabled),
                  ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
      enabled: onTap != null ||
          (trailing is Switch && (trailing as Switch).onChanged != null),
    );
  }
}

class _SignOutSheet extends StatelessWidget {
  const _SignOutSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppSemanticColors.error.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              LucideIcons.logOut,
              size: 24,
              color: AppSemanticColors.error,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.settingsSignOut,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: cs.onSurface,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.settingsSignOutConfirm,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.commonCancel),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppSemanticColors.error,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(52),
                    shape: const StadiumBorder(),
                  ),
                  child: Text(l10n.settingsSignOut),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
