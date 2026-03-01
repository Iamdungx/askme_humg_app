import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  // Font sizes outside the standard TextTheme slots
  static const double fontSizeCaption = 10;

  // TextTheme is a theme definition (consumed by AppTheme._buildTheme),
  // so using raw dark tokens here is correct — colors are overridden by
  // colorScheme.onSurface at runtime via Material 3 text theme merging.
  static TextTheme get textTheme => const TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      color: AppDarkColors.textPrimary,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppDarkColors.textPrimary,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      color: AppDarkColors.textPrimary,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      color: AppDarkColors.textPrimary,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppDarkColors.textPrimary,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppDarkColors.textPrimary,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppDarkColors.textPrimary,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppDarkColors.textPrimary,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppDarkColors.textSecondary,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppDarkColors.textPrimary,
      height: 1.4,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      color: AppDarkColors.textSecondary,
      height: 1.3,
    ),
  );
}
