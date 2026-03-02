import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// USAGE GUIDE
// ---------------------------------------------------------------------------
// In widgets, ALWAYS prefer Theme.of(context).colorScheme.* — it auto-adapts
// to the current ThemeMode (dark / light) without any manual checks.
//
//   ✅ Theme.of(context).colorScheme.surface
//   ✅ Theme.of(context).colorScheme.onSurface
//   ❌ AppColors.dark.surface   ← only use in theme definitions
//
// Raw token classes below are ONLY consumed by AppTheme (app_theme.dart).
// ---------------------------------------------------------------------------

/// Dark mode raw tokens — consumed by [AppTheme.dark] only.
abstract final class AppDarkColors {
  static const Color background = Color(0xFF0A0D1A);
  static const Color surface = Color(0xFF0D1B3E);
  static const Color surfaceElevated = Color(0xFF162347);
  static const Color surfaceVariant = Color(0xFF11224D);

  static const Color primary = Color(0xFF1A3A8C);
  static const Color primaryLight = Color(0xFF2A4FA8);
  static const Color primaryDark = Color(0xFF102570);

  static const Color accent = Color(0xFF2D9BD8);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentLight = Color(0xFF4DB8F0);
  static const Color accentDark = Color(0xFF1A7AAF);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF7FA8C9);
  static const Color textDisabled = Color(0xFF3D5A7A);
  static const Color inputHint = Color(0xFF5E7E9E);

  static const Color border = Color(0xFF1E3A6E);
  static const Color divider = Color(0xFF152850);

  static const Color scrim = Color(0xB3000000);
  static const Color cardOverlay = Color(0x1AFFFFFF);

  static const Color shimmerBase = Color(0xFF162347);
  static const Color shimmerHighlight = Color(0xFF213363);

  static const Color badgeBackground = Color(0xFFEF4444);
  static const Color badgeText = Color(0xFFFFFFFF);

  static const Color anonymousBadge = Color(0xFF162347);
  static const Color anonymousBadgeText = Color(0xFF7FA8C9);

  static const Color tabInactiveBackground = Color(0xFF0D1B3E);
  static const Color successBackground = Color(0xFF064E3B);
}

/// Light mode raw tokens — consumed by [AppTheme.light] only.
abstract final class AppLightColors {
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color surfaceVariant = Color(0xFFE2E8F0);

  static const Color primary = Color(0xFF1A3A8C);
  static const Color primaryLight = Color(0xFF2A4FA8);
  static const Color primaryDark = Color(0xFF102570);

  static const Color accent = Color(0xFF1A7AAF);
  static const Color onAccent = Color(0xFFFFFFFF);
  static const Color accentLight = Color(0xFF2D9BD8);
  static const Color accentDark = Color(0xFF0F5A85);

  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color textDisabled = Color(0xFFAFC0D0);
  static const Color inputHint = Color(0xFF94A3B8);

  static const Color border = Color(0xFFCBD5E1);
  static const Color divider = Color(0xFFE2E8F0);

  static const Color scrim = Color(0x80000000);
  static const Color cardOverlay = Color(0x0A000000);

  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);

  static const Color badgeBackground = Color(0xFFEF4444);
  static const Color badgeText = Color(0xFFFFFFFF);

  static const Color anonymousBadge = Color(0xFFE2E8F0);
  static const Color anonymousBadgeText = Color(0xFF475569);

  static const Color tabInactiveBackground = Color(0xFFFFFFFF);
  static const Color successBackground = Color(0xFFDCFCE7);
}

/// Semantic colors shared across both themes.
/// These never change between dark / light mode.
abstract final class AppSemanticColors {
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color like = Color(0xFFEF4444);
  static const Color transparent = Colors.transparent;

  // Opacity tokens — use with Color.withValues(alpha: AppSemanticColors.opacity*)
  static const double opacityDisabled = 0.5;
  static const double opacitySubtle = 0.6;
  static const double opacityHint = 0.3;
}

// ---------------------------------------------------------------------------
// Convenience re-exports so existing call-sites using AppColors.* still work
// during migration. Prefer Theme.of(context).colorScheme in widget code.
// ---------------------------------------------------------------------------
@Deprecated(
  'Use Theme.of(context).colorScheme in widget code. '
  'Use AppDarkColors / AppLightColors in theme definitions.',
)
abstract final class AppColors {
  // Dark surfaces
  static const Color background = AppDarkColors.background;
  static const Color surface = AppDarkColors.surface;
  static const Color surfaceElevated = AppDarkColors.surfaceElevated;
  static const Color surfaceVariant = AppDarkColors.surfaceVariant;

  // Brand
  static const Color primary = AppDarkColors.primary;
  static const Color primaryLight = AppDarkColors.primaryLight;
  static const Color primaryDark = AppDarkColors.primaryDark;
  static const Color accent = AppDarkColors.accent;
  static const Color onAccent = AppDarkColors.onAccent;
  static const Color accentLight = AppDarkColors.accentLight;
  static const Color accentDark = AppDarkColors.accentDark;

  // Text
  static const Color textPrimary = AppDarkColors.textPrimary;
  static const Color textSecondary = AppDarkColors.textSecondary;
  static const Color textDisabled = AppDarkColors.textDisabled;
  static const Color inputHint = AppDarkColors.inputHint;

  // Border / divider
  static const Color border = AppDarkColors.border;
  static const Color divider = AppDarkColors.divider;

  // Overlay
  static const Color scrim = AppDarkColors.scrim;
  static const Color cardOverlay = AppDarkColors.cardOverlay;

  // Shimmer
  static const Color shimmerBase = AppDarkColors.shimmerBase;
  static const Color shimmerHighlight = AppDarkColors.shimmerHighlight;

  // Badge
  static const Color badgeBackground = AppDarkColors.badgeBackground;
  static const Color badgeText = AppDarkColors.badgeText;

  // Anonymous
  static const Color anonymousBadge = AppDarkColors.anonymousBadge;
  static const Color anonymousBadgeText = AppDarkColors.anonymousBadgeText;

  // Tab
  static const Color tabInactiveBackground =
      AppDarkColors.tabInactiveBackground;

  // Semantic
  static const Color success = AppSemanticColors.success;
  static const Color successBackground = AppDarkColors.successBackground;
  static const Color warning = AppSemanticColors.warning;
  static const Color error = AppSemanticColors.error;
  static const Color like = AppSemanticColors.like;
  static const Color transparent = AppSemanticColors.transparent;
}
