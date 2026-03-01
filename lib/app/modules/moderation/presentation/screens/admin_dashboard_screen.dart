import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/states/empty_state.dart';
import 'package:askme_humg/app/global_widgets/states/error_state.dart';
import 'package:askme_humg/app/global_widgets/states/loading_shimmer.dart';
import 'package:askme_humg/app/modules/moderation/presentation/moderation_providers.dart';
import 'package:askme_humg/app/modules/moderation/presentation/widgets/report_card.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final reportsAsync = ref.watch(pendingReportsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.adminDashboardTitle),
        centerTitle: false,
      ),
      body: reportsAsync.when(
        loading: () => const ShimmerList(count: 3),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(pendingReportsProvider),
        ),
        data: (reports) {
          if (reports.isEmpty) {
            return EmptyState(
              icon: LucideIcons.circleCheck,
              message: l10n.adminNoPendingReports,
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  l10n.adminPendingCount(reports.length),
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              ...reports.map((report) => ReportCard(report: report)),
            ],
          );
        },
      ),
    );
  }
}
