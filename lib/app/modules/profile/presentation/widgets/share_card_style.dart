import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:askme_humg/app/core/providers/theme_provider.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/generated/assets.gen.dart';

part 'share_card_style.g.dart';

// ---------------------------------------------------------------------------
// Share card style definitions — each maps to a PNG background asset
// ---------------------------------------------------------------------------

enum ShareCardStyle {
  abstract,     // Light blue, illustrated faces — light text scheme
  candy,        // Yellow/green/red bold — dark text scheme
  darkCarbon,   // Dark navy illustrated — light text scheme
  darkSpace,    // Dark green astronaut — light text scheme
  deepForest1,  // Brown warm bokeh — light text scheme
  deepForest2,  // Dark teal forest — light text scheme
  sunshine,     // Orange warm illustrated — dark text scheme
}

extension ShareCardStyleX on ShareCardStyle {
  String get key => name;

  String get assetPath {
    switch (this) {
      case ShareCardStyle.abstract:    return Assets.imagesSharesAbstractBg.path;
      case ShareCardStyle.candy:       return Assets.imagesSharesCandyBg.path;
      case ShareCardStyle.darkCarbon:  return Assets.imagesSharesDarkcarbonBg.path;
      case ShareCardStyle.darkSpace:   return Assets.imagesSharesDarkspaceBg.path;
      case ShareCardStyle.deepForest1: return Assets.imagesSharesDeepforest1Bg.path;
      case ShareCardStyle.deepForest2: return Assets.imagesSharesDeepforest2Bg.path;
      case ShareCardStyle.sunshine:    return Assets.imagesSharesSunshineBg.path;
    }
  }

  String label(BuildContext context) {
    switch (this) {
      case ShareCardStyle.abstract:    return 'Abstract';
      case ShareCardStyle.candy:       return 'Candy';
      case ShareCardStyle.darkCarbon:  return 'Carbon';
      case ShareCardStyle.darkSpace:   return 'Space';
      case ShareCardStyle.deepForest1: return 'Forest';
      case ShareCardStyle.deepForest2: return 'Deep Forest';
      case ShareCardStyle.sunshine:    return 'Sunshine';
    }
  }

  // Whether the background is predominantly light (needs dark text)
  bool get isLightBackground {
    switch (this) {
      case ShareCardStyle.abstract:    return true;
      case ShareCardStyle.candy:       return true;
      case ShareCardStyle.darkCarbon:  return false;
      case ShareCardStyle.darkSpace:   return false;
      case ShareCardStyle.deepForest1: return false;
      case ShareCardStyle.deepForest2: return false;
      case ShareCardStyle.sunshine:    return true;
    }
  }

  // Base overlay — consistent blur across all styles so text is always readable
  Color get contentOverlay =>
      isLightBackground ? const Color(0x66FFFFFF) : const Color(0x88000000);

  // Gradient scrim: stronger at top & bottom edges, lighter in center
  // so the background art is still visible but text always has contrast
  Gradient get contentScrim {
    if (isLightBackground) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0x44FFFFFF),
          Color(0x00FFFFFF),
          Color(0x00FFFFFF),
          Color(0x44FFFFFF),
        ],
        stops: [0.0, 0.25, 0.75, 1.0],
      );
    }
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0x66000000),
        Color(0x00000000),
        Color(0x00000000),
        Color(0x66000000),
      ],
      stops: [0.0, 0.25, 0.75, 1.0],
    );
  }

  Color get textPrimary {
    if (isLightBackground) return const Color(0xFF0F172A); // near black
    return const Color(0xFFFFFFFF); // pure white for max contrast
  }

  Color get textSecondary {
    if (isLightBackground) return const Color(0xFF1E293B); // slate-800, darker
    return const Color(0xFFE2E8F0); // near white, much more readable
  }

  Color get accentColor {
    switch (this) {
      case ShareCardStyle.abstract:    return const Color(0xFF1A3A8C);
      case ShareCardStyle.candy:       return const Color(0xFF065F46);
      case ShareCardStyle.darkCarbon:  return AppDarkColors.accent;
      case ShareCardStyle.darkSpace:   return const Color(0xFF4ADE80);
      case ShareCardStyle.deepForest1: return const Color(0xFFFBBF24);
      case ShareCardStyle.deepForest2: return AppDarkColors.accentLight;
      case ShareCardStyle.sunshine:    return const Color(0xFF92400E);
    }
  }

  Color get pillBgColor     => accentColor.withValues(alpha: 0.25);
  Color get pillBorderColor => accentColor.withValues(alpha: 0.7);
  // For dark backgrounds, use pure white for pill text so it always pops
  Color get accentTextColor =>
      isLightBackground ? accentColor : const Color(0xFFFFFFFF);

  Color get avatarGapColor {
    switch (this) {
      case ShareCardStyle.abstract:    return const Color(0xFFBAE6FD);
      case ShareCardStyle.candy:       return const Color(0xFFF0FDF4);
      case ShareCardStyle.darkCarbon:  return const Color(0xFF1E293B);
      case ShareCardStyle.darkSpace:   return const Color(0xFF052E16);
      case ShareCardStyle.deepForest1: return const Color(0xFF292524);
      case ShareCardStyle.deepForest2: return const Color(0xFF134E4A);
      case ShareCardStyle.sunshine:    return const Color(0xFF7C2D12);
    }
  }

  LinearGradient get avatarRingGradient {
    switch (this) {
      case ShareCardStyle.abstract:
        return const LinearGradient(
          colors: [Color(0xFF38BDF8), Color(0xFF1A3A8C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.candy:
        return const LinearGradient(
          colors: [Color(0xFF34D399), Color(0xFFFBBF24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.darkCarbon:
        return LinearGradient(
          colors: [AppDarkColors.accent, AppDarkColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.darkSpace:
        return const LinearGradient(
          colors: [Color(0xFF4ADE80), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.deepForest1:
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFF92400E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.deepForest2:
        return LinearGradient(
          colors: [AppDarkColors.accentLight, AppDarkColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case ShareCardStyle.sunshine:
        return const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFEA580C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color get footerBg {
    if (isLightBackground) return const Color(0x88FFFFFF);
    return const Color(0xAA000000);
  }

  // Fallback gradient in case asset fails to load
  Gradient get fallbackGradient {
    if (isLightBackground) {
      return const LinearGradient(
        colors: [Color(0xFFBAE6FD), Color(0xFFEFF6FF)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
    }
    return const LinearGradient(
      colors: [AppDarkColors.primaryDark, AppDarkColors.surface],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }
}

// ---------------------------------------------------------------------------
// Provider — persists chosen style in SharedPreferences
// ---------------------------------------------------------------------------

const _kShareCardStyleKey = 'share_card_style';

@riverpod
class ShareCardStyleNotifier extends _$ShareCardStyleNotifier {
  @override
  ShareCardStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final stored = prefs.getString(_kShareCardStyleKey);
    return ShareCardStyle.values.firstWhere(
      (s) => s.key == stored,
      orElse: () => ShareCardStyle.deepForest2,
    );
  }

  Future<void> setStyle(ShareCardStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_kShareCardStyleKey, style.key);
  }
}
