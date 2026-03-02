import 'package:flutter/material.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Wordmark "Askme**HUMG**" dùng chung cho Splash, Login, và bất kỳ màn hình nào cần hiển thị thương hiệu.
///
/// Usage:
/// ```dart
/// const AppBrandWordmark()                          // size mặc định (32)
/// const AppBrandWordmark(fontSize: 24)              // size nhỏ hơn
/// AppBrandWordmark(fontSize: 40, fontWeight: FontWeight.w800)
/// ```
class AppBrandWordmark extends StatelessWidget {
  const AppBrandWordmark({
    super.key,
    this.fontSize = 32,
    this.fontWeight = FontWeight.w700,
    this.letterSpacing = -0.5,
  });

  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    final style = TextStyle(
      fontFamily: 'Inter',
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1,
    );

    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: l10n.appBrandName,
            style: style.copyWith(color: cs.onSurface),
          ),
          TextSpan(
            text: l10n.appBrandSuffix,
            style: style.copyWith(color: cs.primary),
          ),
        ],
      ),
    );
  }
}
