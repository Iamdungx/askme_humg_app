import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/generated/assets.gen.dart';

class AnonymousBadge extends StatelessWidget {
  const AnonymousBadge({
    super.key,
    this.label = 'Your identity is hidden',
    this.compact = false,
    this.size = 36,
  });

  final String label;
  final bool compact;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact(context);
    return _buildFull(context);
  }

  Widget _buildFull(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.lock, size: 12, color: cs.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        shape: BoxShape.circle,
        border: Border.all(color: cs.outline, width: 1),
      ),
      child: ClipOval(
        child: Padding(
          padding: EdgeInsets.all(size * 0.1),
          child: Assets.svgsAnonymous.svg(
            fit: BoxFit.contain,
            colorFilter: ColorFilter.mode(
              cs.onSurfaceVariant,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}
