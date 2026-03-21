import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/anonymous_badge.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/global_widgets/input/app_text_input.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/app/core/utils/validator.dart';
import 'package:askme_humg/config/app_routes.dart';
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
  String? _lastSubmittedToUserId;
  String? _lastSubmittedContent;

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

    ref.listen(submitQuestionProvider, (_, next) {
      final receipt = next.asData?.value;
      if (!next.isLoading && !next.hasError && receipt != null) {
        if (!context.mounted) return;
        final toUserId = _lastSubmittedToUserId;
        final content = _lastSubmittedContent ?? '';
        if (toUserId != null && content.isNotEmpty) {
          _triggerNotifyNewQuestion(ref, toUserId, content);
        }
        _controller.clear();
        setState(() {
          _charCount = 0;
          _validationError = null;
          _lastSubmittedToUserId = null;
          _lastSubmittedContent = null;
        });
        _showTrackingCodeDialog(receipt.trackingCode);
      } else if (next.hasError) {
        final err = next.error;
        final message = err is RateLimitFailure
            ? l10n.questionSubmitErrorRateLimit
            : err is NetworkFailure
            ? l10n.questionSubmitErrorAppCheck
            : l10n.commonError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: cs.error),
        );
      }
    });

    final bool isOverLimit = _charCount > _maxChars;
    final bool canSubmit =
        !submitState.isLoading && !isOverLimit && _charCount > 0;

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
        AppTextInputWithCounter(
          controller: _controller,
          hintText: l10n.questionSubmitHint,
          errorText: _validationError,
          maxLines: 4,
          maxLength: _maxChars,
          charCount: _charCount,
          counterLabel: l10n.questionCharCount(_charCount),
          focusedBorderColor: cs.secondary,
          onChanged: (_) {},
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

    setState(() {
      _lastSubmittedToUserId = widget.toUserId;
      _lastSubmittedContent = content;
    });
    await ref
        .read(submitQuestionProvider.notifier)
        .submit(toUserId: widget.toUserId, content: content);
  }

  Future<void> _showTrackingCodeDialog(String trackingCode) async {
    final shouldTrackNow = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _TrackingCodeDialog(trackingCode: trackingCode),
    );

    if (!mounted) return;
    if (shouldTrackNow == true) {
      context.push(AppRoutes.trackQuestion);
    }
  }

  Future<void> _triggerNotifyNewQuestion(
    WidgetRef ref,
    String toUserId,
    String content,
  ) async {
    final client = ref.read(notifyWebhookClientProvider);
    if (!client.isAvailable) return;
    final auth = ref.read(firebaseAuthProvider);
    final token = await auth.currentUser?.getIdToken(true);
    if (token == null) return;
    await client.sendNewQuestion(
      idToken: token,
      toUserId: toUserId,
      content: content,
    );
  }
}

class _TrackingCodeDialog extends StatefulWidget {
  const _TrackingCodeDialog({required this.trackingCode});

  final String trackingCode;

  @override
  State<_TrackingCodeDialog> createState() => _TrackingCodeDialogState();
}

class _TrackingCodeDialogState extends State<_TrackingCodeDialog> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.trackingCode));
    if (!mounted) return;
    if (!_copied) {
      setState(() => _copied = true);
      return;
    }
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.questionTrackingCodeCopied)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final trackingCode = widget.trackingCode;

    return PopScope(
      canPop: _copied,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop || !mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.questionTrackingCodeCopyRequiredHint)),
        );
      },
      child: AlertDialog(
        titlePadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        contentPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.md,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.sm,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(LucideIcons.circleCheck, color: cs.primary, size: 22),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    l10n.questionSubmitSuccess,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.questionTrackingCodeDialogTitle,
              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.questionTrackingCodeDescription,
                style: textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: cs.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.keyRound, size: 16, color: cs.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l10n.trackQuestionInputLabel,
                          style: textTheme.labelMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.lg,
                        ),
                        child: Text(
                          trackingCode,
                          textAlign: TextAlign.center,
                          style: textTheme.headlineSmall?.copyWith(
                            letterSpacing: 4,
                            fontWeight: FontWeight.w800,
                            color: cs.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (_copied)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.circleCheck, size: 20, color: cs.primary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        l10n.questionTrackingCodeCopied,
                        style: textTheme.bodyMedium?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _copy,
                      child: Text(l10n.commonCopy),
                    ),
                  ],
                )
              else ...[
                FilledButton.icon(
                  onPressed: _copy,
                  icon: const Icon(LucideIcons.copy, size: 18),
                  label: Text(l10n.questionTrackingCodeCopyPrimary),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  l10n.questionTrackingCodeCopyRequiredHint,
                  style: textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _copied ? () => Navigator.of(context).pop(false) : null,
            child: Text(l10n.commonClose),
          ),
          FilledButton(
            onPressed: _copied ? () => Navigator.of(context).pop(true) : null,
            child: Text(l10n.questionTrackingCodeTrackNow),
          ),
        ],
      ),
    );
  }
}
