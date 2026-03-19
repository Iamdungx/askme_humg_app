import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/modules/moderation/presentation/moderation_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ReportReasonSheet extends ConsumerStatefulWidget {
  const ReportReasonSheet({
    super.key,
    required this.targetId,
    required this.targetType,
    required this.content,
    this.parentAnswerId,
  });

  final String targetId;
  final String targetType;

  /// Snapshot of the reported content, stored in Firestore for admin review.
  final String content;

  /// Required when [targetType] == 'comment' so admin resolve can decrement commentCount.
  final String? parentAnswerId;

  @override
  ConsumerState<ReportReasonSheet> createState() => _ReportReasonSheetState();
}

class _ReportReasonSheetState extends ConsumerState<ReportReasonSheet> {
  String? _selectedReason;

  Future<void> _submit() async {
    final reason = _selectedReason;
    if (reason == null) return;

    await ref
        .read(reportProvider.notifier)
        .submit(
          targetId: widget.targetId,
          targetType: widget.targetType,
          reason: reason,
          content: widget.content,
          parentAnswerId: widget.parentAnswerId,
        );

    if (!mounted) return;

    // Capture messenger before popping — context is invalid after pop.
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    Navigator.of(context).pop();

    messenger.showSnackBar(SnackBar(content: Text(l10n.reportSubmitted)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isLoading = ref.watch(reportProvider).isLoading;

    final reasons = [
      ('inappropriate_language', l10n.reportReasonInappropriate),
      ('spam', l10n.reportReasonSpam),
      ('misinformation', l10n.reportReasonMisinformation),
      ('other', l10n.reportReasonOther),
    ];

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with drag handle
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                // Manual drag handle: 40×4dp
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    Icon(LucideIcons.flag, size: 20, color: cs.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      l10n.reportTitle,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.reportSubtitle,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Radio option list
                RadioGroup<String>(
                  groupValue: _selectedReason,
                  onChanged: (v) {
                    if (!isLoading) setState(() => _selectedReason = v);
                  },
                  child: Column(
                    children: reasons.asMap().entries.map((entry) {
                      final isLast = entry.key == reasons.length - 1;
                      final (value, label) = entry.value;
                      return Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(
                              label,
                              style: tt.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            trailing: Radio<String>(
                              value: value,
                              activeColor: cs.primary,
                            ),
                            onTap: isLoading
                                ? null
                                : () => setState(() => _selectedReason = value),
                          ),
                          if (!isLast)
                            Divider(
                              height: 1,
                              color: cs.outline.withValues(alpha: 0.3),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                Divider(height: 1, color: cs.outline.withValues(alpha: 0.3)),
                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          l10n.commonCancel,
                          style: tt.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: (_selectedReason == null || isLoading)
                            ? null
                            : _submit,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: isLoading
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: cs.onPrimary,
                                ),
                              )
                            : Text(l10n.reportSubmit),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: MediaQuery.of(context).padding.bottom + AppSpacing.lg,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
