import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/anonymous_badge.dart';
import 'package:askme_humg/app/global_widgets/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/app_bottom_sheet.dart';
import 'package:askme_humg/app/global_widgets/app_card.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/like_button.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class FeedItemCard extends ConsumerWidget {
  const FeedItemCard({super.key, required this.item, this.onCommentTap});

  final FeedItem item;
  final VoidCallback? onCommentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AppCard(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              AppAvatar(
                imageUrl: item.hostAvatar.isNotEmpty ? item.hostAvatar : null,
                name: item.hostName.isNotEmpty
                    ? item.hostName
                    : l10n.feedFallbackHostName,
                size: 40,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.hostName.isNotEmpty
                          ? item.hostName
                          : l10n.feedFallbackHostName,
                      style: tt.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timeago.format(
                        item.createdAt,
                        locale: Localizations.localeOf(context).languageCode,
                      ),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Questions are always anonymous per spec (UC-3.1)
              const AnonymousBadge(compact: true),
              IconButton(
                icon: Icon(
                  LucideIcons.ellipsis,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () => _showMoreMenu(context, l10n),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Question block with anonymous sender label
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AnonymousBadge(compact: true),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.feedAnonymousAsked,
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            item.questionContent.isNotEmpty
                ? '"${item.questionContent}"'
                : l10n.feedEmptyQuestion,
            style: tt.bodyMedium?.copyWith(
              fontStyle: FontStyle.italic,
              color: cs.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Answer block with left border accent
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHigh,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(AppRadius.sm),
                bottomRight: Radius.circular(AppRadius.sm),
              ),
              border: Border(
                left: BorderSide(color: cs.primary, width: 3),
              ),
            ),
            child: Text(
              item.answerContent,
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.9),
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Divider(color: cs.outline.withValues(alpha: 0.3)),

          // Action row
          Row(
            children: [
              LikeButton(
                answerId: item.answerId,
                likeCount: item.likeCount,
                likedBy: item.likedBy,
              ),
              const SizedBox(width: AppSpacing.xl),
              _CommentButton(
                commentCount: item.commentCount,
                onTap: onCommentTap,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  LucideIcons.share2,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () => _onShare(context, l10n),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, AppLocalizations l10n) {
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => AppBottomSheetBody(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.flag),
            title: Text(l10n.reportTitle),
            // TODO(phase-5): Open report bottom sheet → UC-5.1
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _onShare(BuildContext context, AppLocalizations l10n) {
    // TODO(phase-5): Implement share via share_plus package (deep link UC-2.1)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.commonShare)),
    );
  }
}

class _CommentButton extends StatelessWidget {
  const _CommentButton({required this.commentCount, this.onTap});

  final int commentCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.messageCircle,
            size: 20,
            color: cs.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 4),
          Text(
            '$commentCount',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}
