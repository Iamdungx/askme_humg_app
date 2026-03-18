import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/ui/verified_badge.dart';
import 'package:askme_humg/app/global_widgets/layout/app_bottom_sheet.dart';
import 'package:askme_humg/app/global_widgets/layout/app_card.dart';
import 'package:askme_humg/app/global_widgets/layout/left_accent_block.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/like_button.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/share_answer_card_widget.dart';
import 'package:askme_humg/app/modules/moderation/presentation/widgets/show_report_sheet.dart';
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
    final authUser = ref.watch(authStateProvider).asData?.value;
    final uid = authUser?.uid;
    final isVerified = authUser?.isHumgVerified == true;

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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            item.hostName.isNotEmpty
                                ? item.hostName
                                : l10n.feedFallbackHostName,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (item.hostIsHumgVerified) ...[
                          const SizedBox(width: 4),
                          const VerifiedBadge(size: 14),
                        ],
                      ],
                    ),
                    Text(
                      context.timeAgo(item.createdAt),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              // Questions are always anonymous per spec (UC-3.1)
              Icon(
                LucideIcons.lock,
                size: 14,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(width: AppSpacing.xs),
              IconButton(
                icon: Icon(
                  LucideIcons.ellipsis,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () => _showMoreMenu(context, l10n, ref),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Question block with anonymous sender label
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.lock,
                size: 11,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
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
          LeftAccentBlock(
            child: Text(
              item.answerContent,
              style: tt.bodyMedium?.copyWith(color: cs.onSurface, height: 1.5),
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
                onTap: onCommentTap != null
                    ? () {
                        if (!context.requireVerified(
                          uid: uid,
                          isVerified: isVerified,
                          loginMessage: l10n.loginRequiredToComment,
                          verifyMessage: l10n.verifyRequiredToComment,
                        )) { return; }
                        onCommentTap!();
                      }
                    : null,
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  LucideIcons.share2,
                  size: 20,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
                onPressed: () => _onShare(context, l10n, ref),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMoreMenu(BuildContext context, AppLocalizations l10n, WidgetRef ref) {
    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (!context.requireAuth(uid, l10n.loginRequiredToReport)) return;

    showAppBottomSheet<void>(
      context: context,
      builder: (_) => AppBottomSheetBody(
        children: [
          ListTile(
            leading: const Icon(LucideIcons.flag),
            title: Text(l10n.reportTitle),
            onTap: () {
              Navigator.pop(context);
              showReportSheet(
                context,
                targetId: item.answerId,
                targetType: 'answer',
                content: item.answerContent,
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _onShare(
    BuildContext context,
    AppLocalizations l10n,
    WidgetRef ref,
  ) async {
    final deepLink =
        ref.read(generateAnswerDeepLinkUseCaseProvider).call(item.answerId);
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => ShareAnswerCardWidget(item: item, deepLink: deepLink),
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
    final tt = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.messageCircle,
                size: 20,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$commentCount',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
