import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/anonymous_badge.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// UC-3.1 placeholder — submit logic implemented in a later phase.
class AskQuestionSheet extends StatefulWidget {
  const AskQuestionSheet({super.key, required this.toUserId});

  final String toUserId;

  @override
  State<AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends State<AskQuestionSheet> {
  final _controller = TextEditingController();
  int _charCount = 0;

  static const int _maxChars = 300;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() => _charCount = _controller.text.length);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.profileAskSomething,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          children: [
            TextField(
              controller: _controller,
              maxLines: 4,
              maxLength: _maxChars,
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => const SizedBox.shrink(),
              style: TextStyle(color: cs.onSurface),
              decoration: InputDecoration(
                hintText: l10n.questionSubmitHint,
                hintStyle: TextStyle(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: cs.surfaceContainerHigh,
                contentPadding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: cs.outline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: cs.outline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(color: cs.secondary, width: 1.5),
                ),
              ),
            ),
            Positioned(
              bottom: AppSpacing.sm,
              right: AppSpacing.lg,
              child: Text(
                '$_charCount/$_maxChars',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: _charCount >= _maxChars
                      ? cs.error
                      : cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.profileAskAnonymously,
          variant: AppButtonVariant.primary,
          leading: Icon(LucideIcons.lock, size: 18, color: cs.onPrimary),
          // TODO(phase-3): implement UC-3.1 — validate input (1–300 chars),
          //   call Cloud Function with App Check token, show success/rate-limit feedback
          onPressed: () {},
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: const AnonymousBadge()),
      ],
    );
  }
}
