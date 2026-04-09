import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/states/empty_state.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/feed_item_card.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class AnswerDetailScreen extends ConsumerWidget {
  const AnswerDetailScreen({super.key, required this.answerId});

  final String answerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final async = ref.watch(publishedAnswerByIdProvider(answerId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.feed),
        ),
        title: Text(l10n.feedTitle),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: EmptyState(
            icon: LucideIcons.triangleAlert,
            message: l10n.commonError,
            actionLabel: l10n.commonRetry,
            onAction: () =>
                ref.invalidate(publishedAnswerByIdProvider(answerId)),
          ),
        ),
        data: (item) {
          if (item == null) {
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: EmptyState(
                icon: LucideIcons.fileX,
                message: l10n.feedAnswerNotFound,
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            children: [
              FeedItemCard(item: item),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }
}
