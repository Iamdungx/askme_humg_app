import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/utils/validator.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/anonymous_badge.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// UC-3.1 — Anonymous question submission with App Check + Cloud Function.
class AskQuestionSheet extends ConsumerStatefulWidget {
  const AskQuestionSheet({super.key, required this.toUserId});

  final String toUserId;

  @override
  ConsumerState<AskQuestionSheet> createState() => _AskQuestionSheetState();
}

class _AskQuestionSheetState extends ConsumerState<AskQuestionSheet> {
  final _controller = TextEditingController();
  int _charCount = 0;
  String? _validationError;

  static const int _maxChars = 300;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _charCount = _controller.text.length;
        if (_validationError != null) _validationError = null;
      });
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
    final submitState = ref.watch(submitQuestionProvider);

    ref.listen<AsyncValue<void>>(submitQuestionProvider, (_, next) {
      if (!next.isLoading && !next.hasError && next.hasValue) {
        final messenger = ScaffoldMessenger.of(context);
        final successMessage = l10n.questionSubmitSuccess;
        Navigator.of(context).pop();
        messenger.showSnackBar(SnackBar(content: Text(successMessage)));
      } else if (next.hasError) {
        final err = next.error;
        final message = err is RateLimitFailure
            ? l10n.questionSubmitErrorRateLimit
            : err is NetworkFailure
                ? l10n.questionSubmitErrorAppCheck
                : l10n.commonError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: cs.error,
          ),
        );
      }
    });

    final bool isOverLimit = _charCount > _maxChars;
    final bool canSubmit = !submitState.isLoading && !isOverLimit;

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
                errorText: _validationError,
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
                l10n.questionCharCount(_charCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isOverLimit ? cs.error : cs.onSurfaceVariant,
                  fontWeight: isOverLimit ? FontWeight.bold : null,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: l10n.profileAskAnonymously,
          variant: AppButtonVariant.primary,
          leading: submitState.isLoading
              ? null
              : Icon(LucideIcons.lock, size: 18, color: cs.onPrimary),
          isLoading: submitState.isLoading,
          onPressed: canSubmit ? _submit : null,
        ),
        const SizedBox(height: AppSpacing.md),
        Center(child: const AnonymousBadge()),
      ],
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    final l10n = AppLocalizations.of(context);

    final error = Validators.validateQuestion(content);
    if (error != null) {
      setState(() {
        _validationError = switch (error) {
          QuestionValidationError.empty => l10n.questionSubmitErrorEmpty,
          QuestionValidationError.tooLong => l10n.questionSubmitErrorTooLong,
          QuestionValidationError.inappropriate =>
            l10n.questionErrorInappropriate,
        };
      });
      return;
    }

    await ref.read(submitQuestionProvider.notifier).submit(
      toUserId: widget.toUserId,
      content: content,
    );
  }
}
