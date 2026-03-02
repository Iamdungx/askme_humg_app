import 'package:flutter/material.dart';
import 'package:askme_humg/config/languages.dart';

class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({
    super.key,
    required this.currentLocale,
    required this.onChanged,
    this.spacing = 8.0,
    this.runSpacing = 8.0,
    this.padding,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onChanged;
  final double spacing;
  final double runSpacing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final EdgeInsetsGeometry effectivePadding =
        padding ?? const EdgeInsets.symmetric(horizontal: 12.0);
    return Padding(
      padding: effectivePadding,
      child: Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        children: supportedLanguages.map((locale) {
          final bool isSelected =
              locale.languageCode == currentLocale.languageCode;
          return ChoiceChip(
            label: Text(locale.languageCode.toUpperCase()),
            selected: isSelected,
            onSelected: (_) => onChanged(locale),
          );
        }).toList(),
      ),
    );
  }
}
