import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_avatar.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.avatarUrl,
    required this.answerCount,
    required this.totalLikes,
  });

  final String name;
  final String avatarUrl;
  final int answerCount;
  final int totalLikes;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppAvatar(
          imageUrl: avatarUrl,
          name: name,
          size: 80,
          showRing: true,
          ringColor: Theme.of(context).colorScheme.secondary,
          ringWidth: 2,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          name,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          AppLocalizations.of(context).profileHumgStudent,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ProfileStatsRow(answerCount: answerCount, totalLikes: totalLikes),
      ],
    );
  }
}

class _ProfileStatsRow extends StatelessWidget {
  const _ProfileStatsRow({required this.answerCount, required this.totalLikes});

  final int answerCount;
  final int totalLikes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md,
        horizontal: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _StatItem(
                value: answerCount.toString(),
                label: AppLocalizations.of(context).profileStatAnswers,
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: cs.primary.withValues(alpha: 0.3),
            ),
            Expanded(
              child: _StatItem(
                value: totalLikes.toString(),
                label: AppLocalizations.of(context).profileStatLikes,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: cs.onSurfaceVariant,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
