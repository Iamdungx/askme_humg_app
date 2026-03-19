import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Small verified checkmark badge for HUMG-verified users.
/// Uses LucideIcons.badgeCheck filled with [colorScheme.primary].
/// Use [inline] for name rows (icon only), use default for profile header (icon + label).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14, this.inline = true});

  final double size;
  final bool inline;

  Widget _icon(Color color) =>
      Icon(LucideIcons.badgeCheck, size: size, color: color);

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    if (inline) return _icon(color);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _icon(color),
        const SizedBox(width: 3),
        Text(
          'HUMG',
          style: TextStyle(
            fontSize: size * 0.78,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
