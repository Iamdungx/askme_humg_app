import 'package:flutter/material.dart';

class FontSizes {
  const FontSizes._();

  static const double xs = 12.0;
  static const double sm = 14.0;
  static const double md = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

class AppTextStyles {
  const AppTextStyles._();

  static TextStyle get bodySm => const TextStyle(fontSize: FontSizes.sm);
  static TextStyle get bodyMd => const TextStyle(fontSize: FontSizes.md);
  static TextStyle get bodyLg => const TextStyle(fontSize: FontSizes.lg);

  static TextStyle get headingSm =>
      const TextStyle(fontSize: FontSizes.lg, fontWeight: FontWeight.w600);

  static TextStyle get headingMd =>
      const TextStyle(fontSize: FontSizes.xl, fontWeight: FontWeight.w600);

  static TextStyle get headingLg =>
      const TextStyle(fontSize: FontSizes.xxl, fontWeight: FontWeight.w700);
}

class AppTextTheme {
  const AppTextTheme._();

  static TextTheme applyTo(TextTheme base) {
    return base.copyWith(
      bodySmall: (base.bodySmall ?? const TextStyle()).merge(
        AppTextStyles.bodySm,
      ),
      bodyMedium: (base.bodyMedium ?? const TextStyle()).merge(
        AppTextStyles.bodyMd,
      ),
      bodyLarge: (base.bodyLarge ?? const TextStyle()).merge(
        AppTextStyles.bodyLg,
      ),
      titleMedium: (base.titleMedium ?? const TextStyle()).merge(
        AppTextStyles.headingSm,
      ),
      titleLarge: (base.titleLarge ?? const TextStyle()).merge(
        AppTextStyles.headingMd,
      ),
      displaySmall: (base.displaySmall ?? const TextStyle()).merge(
        AppTextStyles.headingSm,
      ),
      displayMedium: (base.displayMedium ?? const TextStyle()).merge(
        AppTextStyles.headingMd,
      ),
      displayLarge: (base.displayLarge ?? const TextStyle()).merge(
        AppTextStyles.headingLg,
      ),
    );
  }
}
