import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// A container with a left-side colored border accent.
/// Used to display quoted answer content and report content previews.
class LeftAccentBlock extends StatelessWidget {
  const LeftAccentBlock({
    super.key,
    required this.child,
    this.accentColor,
    this.padding,
    this.width,
  });

  final Widget child;

  /// Defaults to [ColorScheme.primary].
  final Color? accentColor;
  final EdgeInsetsGeometry? padding;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: width,
      padding: padding ?? const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.sm),
          bottomRight: Radius.circular(AppRadius.sm),
        ),
        border: Border(
          left: BorderSide(color: accentColor ?? cs.primary, width: 3),
        ),
      ),
      child: child,
    );
  }
}
