import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_brand_wordmark.dart';
import 'package:askme_humg/app/global_widgets/states/empty_state.dart';
import 'package:askme_humg/app/global_widgets/states/error_state.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/screens/comments_screen.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/feed_item_card.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_topic.dart';
import 'package:askme_humg/app/global_widgets/states/loading_shimmer.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';
import 'package:askme_humg/app/modules/onboarding/presentation/widgets/onboarding_hint_banner.dart';
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
    final brightness = Theme.of(context).brightness;
    final feedAsync = ref.watch(feedProvider);
    final topicsAsync = ref.watch(aiTopicsProvider);
    final selectedTopicTagId = ref.watch(selectedFeedTopicTagIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const AppBrandWordmark(),
        centerTitle: false,
        actions: [
          // TODO(future): Search screen
          IconButton(
            icon: Icon(
              LucideIcons.search,
              color: cs.onSurface.withValues(alpha: 0.7),
            ),
            onPressed: () {},
          ),
          // TODO(future): Notification screen
          // IconButton(
          //   icon: Icon(
          //     LucideIcons.bell,
          //     color: cs.onSurface.withValues(alpha: 0.7),
          //   ),
          //   onPressed: () {},
          // ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ),
      body: Column(
        children: [
          OnboardingHintBanner(
            hint: OnboardingHint.feed,
            title: l10n.onboardingHintFeedTitle,
            message: l10n.onboardingHintFeedBody,
            icon: LucideIcons.sparkles,
          ),
          SizedBox(
            height: 46,
            child: topicsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) => const SizedBox.shrink(),
              data: (topics) {
                if (topics.isEmpty) return const SizedBox.shrink();
                return ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.sm),
                      child: Builder(
                        builder: (context) {
                          final isAllSelected = selectedTopicTagId == null;
                          return ChoiceChip(
                            label: Text(l10n.feedTopicAll),
                            selected: isAllSelected,
                            showCheckmark: true,
                            checkmarkColor: cs.onSurface,
                            labelStyle: tt.labelMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: isAllSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                            ),
                            backgroundColor: cs.surfaceContainerHighest,
                            selectedColor: cs.surfaceContainer,
                            side: BorderSide(
                              color: isAllSelected
                                  ? cs.outline.withValues(alpha: 0.65)
                                  : cs.outlineVariant.withValues(alpha: 0.6),
                            ),
                            onSelected: (_) => ref
                                .read(feedProvider.notifier)
                                .selectTopic(null),
                          );
                        },
                      ),
                    ),
                    for (final topic in topics)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: Builder(
                          builder: (context) {
                            final isSelected = selectedTopicTagId == topic.id;
                            final topicColor = _colorFromHex(
                              topic.color,
                              cs.primary,
                            );
                            final selectedBackground = Color.alphaBlend(
                              topicColor.withValues(
                                alpha: brightness == Brightness.dark
                                    ? 0.3
                                    : 0.16,
                              ),
                              cs.surfaceContainerHighest,
                            );
                            return ChoiceChip(
                              label: Text(_topicLabel(l10n, topic)),
                              selected: isSelected,
                              showCheckmark: true,
                              checkmarkColor: cs.onSurface,
                              labelStyle: tt.labelMedium?.copyWith(
                                color: isSelected
                                    ? cs.onSurface
                                    : cs.onSurfaceVariant,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                              backgroundColor: cs.surfaceContainerHighest,
                              selectedColor: selectedBackground,
                              side: BorderSide(
                                color: isSelected
                                    ? topicColor.withValues(
                                        alpha: brightness == Brightness.dark
                                            ? 0.55
                                            : 0.35,
                                      )
                                    : cs.outlineVariant.withValues(alpha: 0.6),
                              ),
                              onSelected: (_) => ref
                                  .read(feedProvider.notifier)
                                  .selectTopic(topic.id),
                            );
                          },
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          Expanded(
            child: feedAsync.when(
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
                  child: Stack(
                    children: [
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        opacity: feedState.isRefreshing ? 0.72 : 1,
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
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          switchInCurve: Curves.easeOut,
                          switchOutCurve: Curves.easeIn,
                          child: feedState.isRefreshing
                              ? const LinearProgressIndicator(minHeight: 2)
                              : const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _topicLabel(AppLocalizations l10n, FeedTopic topic) {
  final slug = topic.slug.trim().toLowerCase();
  switch (slug) {
    case 'hoc_tap':
      return l10n.feedTopicStudy;
    case 'doi_song':
      return l10n.feedTopicLife;
    case 'tuyen_dung':
      return l10n.feedTopicMajor;
    case 'su_kien':
      return l10n.feedTopicStudent;
    case 'khac':
      return l10n.feedTopicOther;
    default:
      return topic.label;
  }
}

Color _colorFromHex(String rawHex, Color fallback) {
  final normalized = rawHex.trim().toUpperCase();
  final hex = normalized.startsWith('#') ? normalized.substring(1) : normalized;
  if (hex.length != 6) return fallback;
  final value = int.tryParse(hex, radix: 16);
  if (value == null) return fallback;
  return Color(0xFF000000 | value);
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
