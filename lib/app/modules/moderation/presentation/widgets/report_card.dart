import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/layout/app_card.dart';
import 'package:askme_humg/app/global_widgets/layout/left_accent_block.dart';
import 'package:askme_humg/app/modules/moderation/domain/i_moderation_repository.dart';
import 'package:askme_humg/app/modules/moderation/domain/report.dart';
import 'package:askme_humg/app/modules/moderation/presentation/moderation_providers.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ReportCard extends ConsumerWidget {
  const ReportCard({super.key, required this.report});

  final Report report;

  static const double _snapshotMaxHeight = 280;

  String _typeLabel(AppLocalizations l10n, String rawType) {
    return switch (rawType.toLowerCase()) {
      'answer' => l10n.adminReportTargetAnswer,
      'comment' => l10n.adminReportTargetComment,
      'user' => l10n.adminReportTargetUser,
      _ => l10n.adminReportTargetUnknown,
    };
  }

  bool _canOpenTarget(Report r) {
    final t = r.targetType.toLowerCase();
    if (t == 'answer' || t == 'user') return true;
    if (t == 'comment') {
      final pid = r.parentAnswerId;
      return pid != null && pid.isNotEmpty;
    }
    return false;
  }

  void _openReportTarget(BuildContext context) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final l10n = AppLocalizations.of(context);
    final t = report.targetType.toLowerCase();

    void showErr(String msg) =>
        messenger?.showSnackBar(SnackBar(content: Text(msg)));

    if (t == 'answer') {
      context.push('${AppRoutes.answer}/${report.targetId}');
      return;
    }
    if (t == 'comment') {
      final pid = report.parentAnswerId;
      if (pid == null || pid.isEmpty) {
        showErr(l10n.adminReportMissingParentAnswer);
        return;
      }
      context.push('${AppRoutes.answer}/$pid');
      return;
    }
    if (t == 'user') {
      context.push('${AppRoutes.userProfile}/${report.targetId}');
      return;
    }
    showErr(l10n.adminReportOpenError);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final resolveState = ref.watch(resolveReportProvider(report.reportId));
    final isLoading = resolveState.isLoading;
    final canOpen = _canOpenTarget(report);

    Future<void> resolve(ResolveAction action) async {
      final messenger = ScaffoldMessenger.of(context);

      try {
        await ref
            .read(resolveReportProvider(report.reportId).notifier)
            .resolve(
              targetId: report.targetId,
              targetType: report.targetType,
              action: action,
              parentAnswerId: report.parentAnswerId,
            );
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.adminResolved)));
      } catch (_) {
        if (!context.mounted) return;
        messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
      }
    }

    final reasonLabel = _reasonLabel(l10n, report.reason);
    final typeLabel = _typeLabel(l10n, report.targetType);

    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: cs.primary,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  typeLabel,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onPrimary,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  reasonLabel,
                  style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w500),
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

          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: canOpen && !isLoading ? () => _openReportTarget(context) : null,
              borderRadius: BorderRadius.circular(AppRadius.md),
              child: LeftAccentBlock(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxHeight: _snapshotMaxHeight,
                      ),
                      child: Scrollbar(
                        thumbVisibility: report.content.length > 400,
                        child: SingleChildScrollView(
                          child: SelectableText(
                            report.content.isNotEmpty
                                ? report.content
                                : l10n.adminReportSnapshotMissing,
                            style: tt.bodySmall?.copyWith(
                              color: report.content.isNotEmpty
                                  ? cs.onSurface.withValues(alpha: 0.85)
                                  : cs.onSurface.withValues(alpha: 0.45),
                              fontStyle: report.content.isNotEmpty
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (canOpen) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.externalLink,
                            size: 14,
                            color: cs.primary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            l10n.adminViewReportedContent,
                            style: tt.labelMedium?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isLoading
                      ? null
                      : () => resolve(ResolveAction.dismiss),
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
                  onPressed: isLoading
                      ? null
                      : () => resolve(ResolveAction.remove),
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
