import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    this.onReply,
    this.onDelete,
    this.showReply = true,
  });

  final Question question;
  final VoidCallback? onReply;
  final Future<void> Function()? onDelete;
  final bool showReply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Dismissible(
      key: Key(question.questionId),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      background: onDelete != null
          ? Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: cs.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Icon(LucideIcons.trash2, color: cs.error),
            )
          : null,
      confirmDismiss: onDelete != null
          ? (_) async {
              final confirmed = await _confirmDelete(context, l10n);
              if (!confirmed) return false;
              try {
                await onDelete!();
                return true;
              } catch (_) {
                return false;
              }
            }
          : null,
      onDismissed: null,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(
            color: cs.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    LucideIcons.clock,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    context.timeAgo(question.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                question.content,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  if (showReply && onReply != null) ...[
                    Expanded(
                      child: _ReplyButton(
                        onPressed: onReply!,
                        l10n: l10n,
                        cs: cs,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                  ],
                  if (onDelete != null)
                    AppButton(
                      label: l10n.commonDelete,
                      variant: AppButtonVariant.danger,
                      leading: Icon(
                        LucideIcons.trash2,
                        size: 16,
                        color: cs.onError,
                      ),
                      isFullWidth: false,
                      minimumHeight: 40,
                      onPressed: () async {
                        final confirmed = await _confirmDelete(context, l10n);
                        if (confirmed) await onDelete!();
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(
    BuildContext context,
    AppLocalizations l10n,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.inboxDeleteQuestion),
        content: Text(l10n.inboxDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              l10n.commonDelete,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

class _ReplyButton extends StatelessWidget {
  const _ReplyButton({
    required this.onPressed,
    required this.l10n,
    required this.cs,
  });

  final VoidCallback onPressed;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(LucideIcons.reply, size: 16, color: cs.primary),
      label: Text(
        l10n.inboxReplyButton,
        style: TextStyle(color: cs.primary, fontWeight: FontWeight.bold),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.primary.withValues(alpha: 0.4)),
        backgroundColor: cs.primary.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
    );
  }
}

