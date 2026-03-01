import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/anonymous_badge.dart';
import 'package:askme_humg/app/global_widgets/app_avatar.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/domain/comment.dart';
import 'package:askme_humg/app/modules/moderation/presentation/widgets/report_reason_sheet.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class CommentTile extends ConsumerWidget {
  const CommentTile({super.key, required this.comment});

  final Comment comment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    final currentUid = ref.watch(authStateProvider).asData?.value?.uid;
    final isLoggedIn = currentUid != null;
    final isOwnComment = currentUid != null && comment.userId == currentUid;
    final showReportButton = isLoggedIn && !isOwnComment;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (comment.isAnonymous)
          const AnonymousBadge(compact: true)
        else
          AppAvatar(
            imageUrl: comment.authorAvatar.isNotEmpty
                ? comment.authorAvatar
                : null,
            name: comment.authorName.isNotEmpty ? comment.authorName : null,
            size: 36,
            showRing: false,
          ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          comment.isAnonymous
                              ? l10n.commentAnonymous
                              : (comment.authorName.isNotEmpty
                                  ? comment.authorName
                                  : l10n.commentAnonymous),
                          style: comment.isAnonymous
                              ? tt.labelMedium?.copyWith(
                                  color: cs.onSurface.withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                )
                              : tt.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          timeago.format(
                            comment.createdAt,
                            locale: Localizations.localeOf(context).languageCode,
                          ),
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showReportButton)
                    IconButton(
                      icon: Icon(
                        LucideIcons.ellipsis,
                        size: 16,
                        color: cs.onSurface.withValues(alpha: 0.4),
                      ),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      onPressed: () => showModalBottomSheet<void>(
                        context: context,
                        useSafeArea: true,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => ReportReasonSheet(
                          targetId: comment.commentId,
                          targetType: 'comment',
                          content: comment.content,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                comment.content,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
