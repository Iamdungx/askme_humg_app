import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// Read-only answer preview card shown in the Profile screen's "Recent Answers" section.
// TODO(phase-4): add answerId field + onTap callback → navigate to full answer / comments sheet (UC-4.3)
class AnswerPreviewCard extends StatelessWidget {
  const AnswerPreviewCard({
    super.key,
    required this.question,
    required this.answer,
    required this.likeCount,
    required this.commentCount,
    this.timestamp,
  });

  final String question;
  final String answer;
  final int likeCount;
  final int commentCount;
  final String? timestamp;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleQuestionMark,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  '"$question"',
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.8),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg + AppSpacing.md),
            child: Text(
              answer,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.only(left: AppSpacing.lg + AppSpacing.md),
            child: Column(
              children: [
                Divider(
                  height: 1,
                  thickness: 1,
                  color: cs.primary.withValues(alpha: 0.1),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    // TODO(phase-4): like button → UC-4.2 (arrayUnion/arrayRemove + FieldValue.increment)
                    _ActionChip(
                      icon: LucideIcons.heart,
                      count: likeCount,
                      color: cs.onSurfaceVariant,
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    // TODO(phase-4): comment button → open DraggableScrollableSheet (UC-4.3)
                    _ActionChip(
                      icon: LucideIcons.messageCircle,
                      count: commentCount,
                      color: cs.onSurfaceVariant,
                    ),
                    if (timestamp != null) ...[
                      const Spacer(),
                      Text(
                        timestamp!.toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.count,
    required this.color,
  });

  final IconData icon;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          count.toString(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
