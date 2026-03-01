import 'package:flutter/material.dart';
import 'package:askme_humg/generated/assets.gen.dart';

/// Small verified checkmark badge for HUMG-verified users.
/// Uses [colorScheme.primary] for the badge circle colour.
/// Use [inline] for name rows (icon only), use default for profile header (icon + label).
class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 14, this.inline = true});

  final double size;
  final bool inline;

  Widget _icon(Color color) => Assets.svgsVerified.svg(
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );

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
