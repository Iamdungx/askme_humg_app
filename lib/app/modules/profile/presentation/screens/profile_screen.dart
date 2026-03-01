import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/states/empty_state.dart';
import 'package:askme_humg/app/global_widgets/states/error_state.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/profile/domain/user_profile.dart';
import 'package:askme_humg/app/modules/profile/presentation/profile_providers.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/answer_preview_card.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/ask_question_sheet.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/profile_header.dart';
import 'package:askme_humg/app/global_widgets/layout/app_bottom_sheet.dart';
import 'package:askme_humg/app/modules/moderation/presentation/widgets/show_report_sheet.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/share_card_widget.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(userProfileProvider(userId));
    final currentUid = ref.watch(authStateProvider).asData?.value?.uid;
    final isOwner = currentUid != null && currentUid == userId;

    return profileAsync.when(
      loading: () => const _ProfileLoadingScaffold(),
      error: (e, _) {
        // UC-2.2 §3: distinguish "user not found" from generic network error
        final isNotFound =
            e is FirestoreFailure && e.message == 'User not found';
        return _ProfileErrorScaffold(
          isNotFound: isNotFound,
          onRetry: () => ref.invalidate(userProfileProvider(userId)),
        );
      },
      data: (profile) => _ProfileContent(profile: profile, isOwner: isOwner),
    );
  }
}

// ---------------------------------------------------------------------------
// Main content scaffold
// ---------------------------------------------------------------------------

class _ProfileContent extends ConsumerWidget {
  const _ProfileContent({required this.profile, required this.isOwner});

  final UserProfile profile;
  final bool isOwner;

  void _showShareCard(BuildContext context, String deepLink) {
    showAppBottomSheet<void>(
      context: context,
      builder: (_) => ShareCardWidget(
        userId: profile.userId,
        displayName: profile.name,
        avatarUrl: profile.avatar,
        deepLink: deepLink,
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
                targetId: profile.userId,
                targetType: 'user',
                content: profile.name,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final deepLink = ref
        .read(generateDeepLinkUseCaseProvider)
        .call(profile.userId);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        automaticallyImplyLeading: false,
        leading: isOwner
            ? null
            : IconButton(
                icon: Icon(LucideIcons.arrowLeft, color: cs.onSurface),
                onPressed: () =>
                    context.canPop() ? context.pop() : context.go(AppRoutes.feed),
              ),
        title: Text(
          l10n.profileTitle,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        actions: [
          if (isOwner) ...[
            IconButton(
              icon: Icon(LucideIcons.userPen, color: cs.onSurface),
              tooltip: 'Edit Profile',
              onPressed: () => context.push('/me/edit'),
            ),
            IconButton(
              icon: Icon(LucideIcons.share2, color: cs.onSurface),
              onPressed: () => _showShareCard(context, deepLink),
            ),
          ] else
            IconButton(
              icon: Icon(LucideIcons.ellipsisVertical, color: cs.onSurface),
              onPressed: () => _showMoreMenu(context, l10n, ref),
            ),
        ],
      ),
      body: profile.isBlocked
          ? _BlockedUserView(message: l10n.profileBlockedUser)
          : _ProfileBody(
              profile: profile,
              isOwner: isOwner,
              deepLink: deepLink,
              l10n: l10n,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile body — main scrollable content
// ---------------------------------------------------------------------------

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({
    required this.profile,
    required this.isOwner,
    required this.deepLink,
    required this.l10n,
  });

  final UserProfile profile;
  final bool isOwner;
  final String deepLink;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        // Profile header: avatar + name + stats
          Center(
            child: ProfileHeader(
              name: profile.name,
              avatarUrl: profile.avatar,
              answerCount: profile.answerCount,
              totalLikes: profile.totalLikes,
              isHumgVerified: profile.isHumgVerified,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),

        // isOwner: share link card + inbox shortcut (UC-2.2 §2)
        // isOther: ask question input
        if (isOwner)
          _OwnerActionSection(deepLink: deepLink, l10n: l10n)
        else
          AskQuestionSheet(toUserId: profile.userId),

        const SizedBox(height: AppSpacing.xl),

        // Recent Answers section
        _RecentAnswersSection(
          userId: profile.userId,
          answerCount: profile.answerCount,
          l10n: l10n,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Owner section: share link banner + Inbox shortcut (UC-2.2 §2)
// ---------------------------------------------------------------------------

class _OwnerActionSection extends StatelessWidget {
  const _OwnerActionSection({required this.deepLink, required this.l10n});

  final String deepLink;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        // Share link banner
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: cs.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: cs.secondary.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.link2, color: cs.secondary, size: 20),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.profileYourLink,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      deepLink,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        // UC-2.2 §2: Inbox shortcut for owner
        OutlinedButton.icon(
          icon: Icon(LucideIcons.inbox, size: 18),
          label: Text(l10n.profileGoToInbox),
          onPressed: () => context.go('/inbox'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
            side: BorderSide(color: cs.outline),
            foregroundColor: cs.onSurface,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Answers section — real data from Firestore (UC-4.1)
// ---------------------------------------------------------------------------

class _RecentAnswersSection extends ConsumerWidget {
  const _RecentAnswersSection({
    required this.userId,
    required this.answerCount,
    required this.l10n,
  });

  final String userId;
  final int answerCount;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final answersAsync = ref.watch(userAnswersProvider(userId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n.profileRecentAnswers,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: cs.onSurface,
              ),
            ),
            // TODO(future): Navigate to full published answers list screen
            if (answerCount > 0)
              TextButton(
                onPressed: () {},
                child: Text(
                  l10n.profileViewAll,
                  style: TextStyle(color: cs.primary),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (answerCount == 0)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: EmptyState(
              icon: LucideIcons.messageCircleOff,
              message: l10n.profileEmptyAnswers,
            ),
          )
        else
          answersAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
              child: ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(userAnswersProvider(userId)),
              ),
            ),
            data: (answers) {
              if (answers.isEmpty) {
                // answerCount > 0 but no published answers yet
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: EmptyState(
                    icon: LucideIcons.messageCircleOff,
                    message: l10n.profileNoPublishedAnswers,
                  ),
                );
              }
              return Column(
                children: [
                  for (int i = 0; i < answers.length; i++) ...[
                    if (i > 0) const SizedBox(height: AppSpacing.md),
                    AnswerPreviewCard(item: answers[i]),
                  ],
                ],
              );
            },
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Blocked user view
// ---------------------------------------------------------------------------

class _BlockedUserView extends StatelessWidget {
  const _BlockedUserView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.userX,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Loading & error scaffolds
// ---------------------------------------------------------------------------

class _ProfileLoadingScaffold extends StatelessWidget {
  const _ProfileLoadingScaffold();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cs.onSurface),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.feed),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xl,
        ),
        child: _ProfileShimmer(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile-specific shimmer — mirrors the actual profile layout
// ---------------------------------------------------------------------------

class _ProfileShimmer extends StatelessWidget {
  const _ProfileShimmer();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerHighest,
      child: Column(
        children: [
          // Avatar circle
          Center(child: _box(cs, width: 80, height: 80, radius: 40)),
          const SizedBox(height: AppSpacing.md),
          // Name
          Center(child: _box(cs, width: 160, height: 20)),
          const SizedBox(height: AppSpacing.sm),
          // Subtitle
          Center(child: _box(cs, width: 100, height: 14)),
          const SizedBox(height: AppSpacing.lg),
          // Stats row
          Center(child: _box(cs, width: 280, height: 56, radius: AppRadius.lg)),
          const SizedBox(height: AppSpacing.xl),
          // Input area
          _box(cs, width: double.infinity, height: 120, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.md),
          // Button
          _box(cs, width: double.infinity, height: 52, radius: AppRadius.full),
          const SizedBox(height: AppSpacing.xl),
          // Section title
          _box(cs, width: 140, height: 18),
          const SizedBox(height: AppSpacing.md),
          // Answer card 1
          _box(cs, width: double.infinity, height: 110, radius: AppRadius.lg),
          const SizedBox(height: AppSpacing.md),
          // Answer card 2
          _box(cs, width: double.infinity, height: 110, radius: AppRadius.lg),
        ],
      ),
    );
  }

  Widget _box(
    ColorScheme cs, {
    required double width,
    required double height,
    double radius = AppRadius.sm,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _ProfileErrorScaffold extends StatelessWidget {
  const _ProfileErrorScaffold({
    required this.isNotFound,
    required this.onRetry,
  });

  /// UC-2.2 §3: true = user document doesn't exist, false = network/generic error
  final bool isNotFound;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cs.onSurface),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.feed),
        ),
      ),
      body: ErrorState(
        icon: isNotFound ? LucideIcons.userX : null,
        message: isNotFound ? l10n.profileUserNotFound : l10n.commonError,
        // Don't offer retry for "not found" — it won't change
        onRetry: isNotFound ? null : onRetry,
        retryLabel: l10n.commonRetry,
      ),
    );
  }
}
