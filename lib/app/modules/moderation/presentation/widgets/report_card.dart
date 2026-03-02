import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/layout/app_card.dart';
import 'package:askme_humg/app/global_widgets/layout/left_accent_block.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';
import 'package:askme_humg/app/modules/moderation/presentation/moderation_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report});

  final Report report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final resolveState =
        ref.watch(resolveReportProvider(report.reportId));
    final isLoading = resolveState.isLoading;

    Future<void> resolve(ResolveAction action) async {
      // Capture messenger before async gap.
      final messenger = ScaffoldMessenger.of(context);

      await ref
          .read(resolveReportProvider(report.reportId).notifier)
          .resolve(
            targetId: report.targetId,
            targetType: report.targetType,
            action: action,
            parentAnswerId: report.parentAnswerId,
          );

      if (!context.mounted) return;
      final result = ref.read(resolveReportProvider(report.reportId));
      if (result is AsyncError) {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.commonError)),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text(l10n.adminResolved)),
        );
      }
    }

    final reasonLabel = _reasonLabel(l10n, report.reason);
    final typeLabel = report.targetType.toUpperCase();

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: type badge + reason + timestamp
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  typeLabel,
                  style: tt.labelSmall?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  reasonLabel,
                  style: tt.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                context.timeAgo(report.createdAt),
                style: tt.labelSmall?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Row 2: content preview with left accent border
          LeftAccentBlock(
            width: double.infinity,
            child: Text(
              report.content.isNotEmpty ? report.content : '—',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
                height: 1.5,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Row 3: action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading ? null : () => resolve(ResolveAction.dismiss),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: const StadiumBorder(),
                    side: BorderSide(color: cs.outline),
                    foregroundColor: cs.onSurface.withValues(alpha: 0.7),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onSurface.withValues(alpha: 0.5),
                          ),
                        )
                      : Text(l10n.adminDismiss),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton(
                  onPressed: isLoading ? null : () => resolve(ResolveAction.remove),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                    shape: const StadiumBorder(),
                    backgroundColor: cs.error,
                    foregroundColor: cs.onError,
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.onError,
                          ),
                        )
                      : Text(l10n.adminRemove),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _reasonLabel(AppLocalizations l10n, String reason) {
    return switch (reason) {
      'inappropriate_language' => l10n.reportReasonInappropriate,
      'spam' => l10n.reportReasonSpam,
      'misinformation' => l10n.reportReasonMisinformation,
      _ => l10n.reportReasonOther,
    };
  }
}
