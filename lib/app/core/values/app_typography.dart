import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  // Font sizes outside the standard TextTheme slots
  static const double fontSizeCaption = 10;

  static const TextTheme textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.2,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.3,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 24,
      fontWeight: FontWeight.w600,
      height: 1.3,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.6,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.5,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.4,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 11,
      fontWeight: FontWeight.w500,
      height: 1.3,
    ),
  );
}
