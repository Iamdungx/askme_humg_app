import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message,
    this.description,
    this.icon,
    this.retryLabel,
    this.onRetry,
  });

  final String? message;
  final String? description;
  final IconData? icon;
  final String? retryLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon ?? LucideIcons.circleAlert, size: 72, color: cs.error),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message ?? l10n.commonError,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
            ),
            if (description != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                description!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: retryLabel ?? l10n.commonRetry,
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                isFullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
