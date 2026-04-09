import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/modules/onboarding/domain/onboarding.dart';
import 'package:askme_humg/app/modules/onboarding/presentation/onboarding_providers.dart';

class OnboardingHintBanner extends ConsumerWidget {
  const OnboardingHintBanner({
    super.key,
    required this.hint,
    required this.title,
    required this.message,
    required this.icon,
  });

  final OnboardingHint hint;
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seen = ref.watch(hintSeenProvider(hint));
    if (seen) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Material(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: cs.primary, size: 20),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.x,
                size: 18,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              onPressed: () =>
                  ref.read(hintSeenProvider(hint).notifier).markSeen(),
            ),
          ],
        ),
      ),
    );
  }
}
