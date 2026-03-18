import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/comments_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/like_button.dart';

/// Read-only answer preview card shown in the Profile screen's "Recent Answers" section.
class AnswerPreviewCard extends StatelessWidget {
  const AnswerPreviewCard({
    super.key,
    required this.item,
    this.onLikeToggleSuccess,
  });

  final FeedItem item;
  final VoidCallback? onLikeToggleSuccess;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return InkWell(
      onTap: () => showCommentsSheet(
        context,
        answerId: item.answerId,
        commentCount: item.commentCount,
      ),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Container(
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
                    '"${item.questionContent}"',
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
                item.answerContent,
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
                      LikeButton(
                        answerId: item.answerId,
                        likeCount: item.likeCount,
                        likedBy: item.likedBy,
                        onToggleSuccess: onLikeToggleSuccess,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      _CommentChip(
                        count: item.commentCount,
                        color: cs.onSurfaceVariant,
                      ),
                      const Spacer(),
                      Text(
                        timeago.format(item.createdAt).toUpperCase(),
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentChip extends StatelessWidget {
  const _CommentChip({required this.count, required this.color});

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(LucideIcons.messageCircle, size: 16, color: color),
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
