import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_typography.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

abstract final class AppTheme {
  // --------------------------------------------------------------------------
  // Dark
  // --------------------------------------------------------------------------

  static ColorScheme get darkColorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppDarkColors.accent,
        onPrimary: AppDarkColors.onAccent,
        primaryContainer: AppDarkColors.primary,
        onPrimaryContainer: AppDarkColors.onAccent,
        secondary: AppDarkColors.accent,
        onSecondary: AppDarkColors.onAccent,
        surface: AppDarkColors.surface,
        onSurface: AppDarkColors.textPrimary,
        surfaceContainerHigh: AppDarkColors.surfaceElevated,
        surfaceContainerHighest: AppDarkColors.surfaceVariant,
        onSurfaceVariant: AppDarkColors.textSecondary,
        error: AppSemanticColors.error,
        onError: AppDarkColors.onAccent,
        outline: AppDarkColors.border,
        outlineVariant: AppDarkColors.divider,
        tertiary: AppSemanticColors.like,
        onTertiary: AppDarkColors.onAccent,
        scrim: AppDarkColors.scrim,
      );

  static ThemeData get dark => _buildTheme(
        colorScheme: darkColorScheme,
        scaffoldBg: AppDarkColors.background,
        cardColor: AppDarkColors.surface,
        cardBorder: AppDarkColors.border,
        inputFill: AppDarkColors.surfaceElevated,
        inputBorder: AppDarkColors.border,
        hintColor: AppDarkColors.inputHint,
        shimmerBase: AppDarkColors.shimmerBase,
        navBarBg: AppDarkColors.surface,
        dividerColor: AppDarkColors.divider,
        bottomSheetBg: AppDarkColors.surfaceElevated,
        snackBarBg: AppDarkColors.surfaceElevated,
        chipBg: AppDarkColors.surfaceElevated,
        chipBorder: AppDarkColors.border,
        switchThumbOff: AppDarkColors.textDisabled,
        switchTrackOff: AppDarkColors.border,
      );

  // --------------------------------------------------------------------------
  // Light
  // --------------------------------------------------------------------------

  static ColorScheme get lightColorScheme => const ColorScheme(
        brightness: Brightness.light,
        primary: AppLightColors.accent,
        onPrimary: AppLightColors.onAccent,
        primaryContainer: AppLightColors.primaryLight,
        onPrimaryContainer: AppLightColors.onAccent,
        secondary: AppLightColors.accent,
        onSecondary: AppLightColors.onAccent,
        surface: AppLightColors.surface,
        onSurface: AppLightColors.textPrimary,
        surfaceContainerHigh: AppLightColors.surfaceElevated,
        surfaceContainerHighest: AppLightColors.surfaceVariant,
        onSurfaceVariant: AppLightColors.textSecondary,
        error: AppSemanticColors.error,
        onError: AppLightColors.onAccent,
        outline: AppLightColors.border,
        outlineVariant: AppLightColors.divider,
        tertiary: AppSemanticColors.like,
        onTertiary: AppLightColors.onAccent,
        scrim: AppLightColors.scrim,
      );

  static ThemeData get light => _buildTheme(
        colorScheme: lightColorScheme,
        scaffoldBg: AppLightColors.background,
        cardColor: AppLightColors.surface,
        cardBorder: AppLightColors.border,
        inputFill: AppLightColors.surfaceElevated,
        inputBorder: AppLightColors.border,
        hintColor: AppLightColors.inputHint,
        shimmerBase: AppLightColors.shimmerBase,
        navBarBg: AppLightColors.surface,
        dividerColor: AppLightColors.divider,
        bottomSheetBg: AppLightColors.surfaceElevated,
        snackBarBg: AppLightColors.surfaceVariant,
        chipBg: AppLightColors.surfaceElevated,
        chipBorder: AppLightColors.border,
        switchThumbOff: AppLightColors.textDisabled,
        switchTrackOff: AppLightColors.border,
      );

  // --------------------------------------------------------------------------
  // Shared builder — single source of truth for component themes
  // --------------------------------------------------------------------------

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required Color cardColor,
    required Color cardBorder,
    required Color inputFill,
    required Color inputBorder,
    required Color hintColor,
    required Color shimmerBase,
    required Color navBarBg,
    required Color dividerColor,
    required Color bottomSheetBg,
    required Color snackBarBg,
    required Color chipBg,
    required Color chipBorder,
    required Color switchThumbOff,
    required Color switchTrackOff,
  }) {
    final accent = colorScheme.primary;
    final textPrimary = colorScheme.onSurface;
    final textSecondary = colorScheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      fontFamily: AppTypography.fontFamily,
      textTheme: AppTypography.textTheme,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: cardBorder, width: 1),
        ),
      ),

      // Filled Button
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(double.infinity, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined Button
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          minimumSize: const Size(double.infinity, 52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          textStyle: const TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Fields
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: hintColor,
          fontSize: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: accent, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppSemanticColors.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),

      // Tab Bar
      tabBarTheme: TabBarThemeData(
        labelColor: accent,
        unselectedLabelColor: textSecondary,
        indicatorColor: accent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Bottom Navigation Bar
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarBg,
        indicatorColor: accent.withValues(alpha: 0.15),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: accent);
          }
          return IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontFamily: AppTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: accent,
            );
          }
          return TextStyle(
            fontFamily: AppTypography.fontFamily,
            fontSize: 12,
            color: textSecondary,
          );
        }),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 0,
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return switchThumbOff;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accent.withValues(alpha: 0.3);
          }
          return switchTrackOff;
        }),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bottomSheetBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        showDragHandle: true,
        dragHandleColor: cardBorder,
      ),

      // Snack Bar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarBg,
        contentTextStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          color: textPrimary,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        labelStyle: TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: textSecondary,
        ),
        side: BorderSide(color: chipBorder),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
      ),
    );
  }
}
