import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_brand_wordmark.dart';
import 'package:askme_humg/app/global_widgets/empty_state.dart';
import 'package:askme_humg/app/global_widgets/error_state.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/comments_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/feed_item_card.dart';
import 'package:askme_humg/app/global_widgets/loading_shimmer.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends ConsumerState<FeedScreen> {
  bool _isLoadingMoreGuard = false;

  Future<void> _triggerLoadMore() async {
    if (_isLoadingMoreGuard) return;
    _isLoadingMoreGuard = true;
    await ref.read(feedProvider.notifier).loadMore();
    _isLoadingMoreGuard = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final feedAsync = ref.watch(feedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandWordmark(),
        centerTitle: false,
        actions: [
          // TODO(phase-5): Search screen
          IconButton(
            icon: Icon(LucideIcons.search, color: cs.onSurface.withValues(alpha: 0.7)),
            onPressed: () {},
          ),
          // TODO(phase-5): Notification screen
          IconButton(
            icon: Icon(LucideIcons.bell, color: cs.onSurface.withValues(alpha: 0.7)),
            onPressed: () {},
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: feedAsync.when(
        loading: () => const ShimmerList(),
        error: (e, _) => ErrorState(
          message: l10n.feedErrorLoad,
          onRetry: () => ref.read(feedProvider.notifier).refresh(),
        ),
        data: (feedState) {
          if (feedState.items.isEmpty) {
            return EmptyState(
              icon: LucideIcons.messageCircle,
              message: l10n.feedEmpty,
              actionLabel: l10n.commonRetry,
              onAction: () => ref.read(feedProvider.notifier).refresh(),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(feedProvider.notifier).refresh(),
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (notification is ScrollUpdateNotification &&
                    notification.metrics.extentAfter < 400) {
                  _triggerLoadMore();
                }
                return false;
              },
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  top: AppSpacing.sm,
                  bottom: AppSpacing.xxl,
                ),
                itemCount: feedState.items.length + 1,
                itemBuilder: (context, index) {
                  if (index == feedState.items.length) {
                    return _FeedListFooter(
                      isLoadingMore: feedState.isLoadingMore,
                      hasReachedEnd: feedState.hasReachedEnd,
                      l10n: l10n,
                      tt: tt,
                      cs: cs,
                    );
                  }
                  final item = feedState.items[index];
                  return FeedItemCard(
                    item: item,
                    onCommentTap: () => showCommentsSheet(
                      context,
                      answerId: item.answerId,
                      commentCount: item.commentCount,
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeedListFooter extends StatelessWidget {
  const _FeedListFooter({
    required this.isLoadingMore,
    required this.hasReachedEnd,
    required this.l10n,
    required this.tt,
    required this.cs,
  });

  final bool isLoadingMore;
  final bool hasReachedEnd;
  final AppLocalizations l10n;
  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    if (isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    if (hasReachedEnd) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
          child: Text(
            l10n.feedReachedEnd,
            style: tt.labelMedium?.copyWith(
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
