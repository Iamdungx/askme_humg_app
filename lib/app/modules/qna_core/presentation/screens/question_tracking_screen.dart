import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/utils/validator.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question_tracking_status.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class QuestionTrackingScreen extends ConsumerStatefulWidget {
  const QuestionTrackingScreen({super.key});

  @override
  ConsumerState<QuestionTrackingScreen> createState() =>
      _QuestionTrackingScreenState();
}

class _QuestionTrackingScreenState
    extends ConsumerState<QuestionTrackingScreen> {
  final _codeController = TextEditingController();
  String? _validationError;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final lookupState = ref.watch(questionTrackingStatusProvider);

    ref.listen<AsyncValue<QuestionTrackingStatus?>>(
      questionTrackingStatusProvider,
      (_, next) {
        if (!context.mounted || !next.hasError) return;
        final error = next.error;
        final message = switch (error) {
          InvalidTrackingCodeFailure() => l10n.trackQuestionErrorInvalidCode,
          TrackingNotFoundFailure() => l10n.trackQuestionErrorNotFound,
          RateLimitFailure() => l10n.trackQuestionErrorTooManyRequests,
          _ => l10n.commonError,
        };
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: cs.error),
        );
      },
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackQuestionTitle),
        leading: context.canPop()
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            l10n.trackQuestionDescription,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _codeController,
            keyboardType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.search,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
              LengthLimitingTextInputFormatter(6),
              _UpperCaseTextFormatter(),
            ],
            decoration: InputDecoration(
              labelText: l10n.trackQuestionInputLabel,
              hintText: l10n.trackQuestionInputHint,
              errorText: _validationError,
              prefixIcon: const Icon(LucideIcons.keyRound),
            ),
            onSubmitted: (_) => _lookup(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: l10n.trackQuestionLookupButton,
            variant: AppButtonVariant.primary,
            isLoading: lookupState.isLoading,
            onPressed: lookupState.isLoading ? null : _lookup,
          ),
          const SizedBox(height: AppSpacing.xl),
          if (lookupState.hasValue && lookupState.asData?.value != null)
            _TrackingResultCard(result: lookupState.asData!.value!),
        ],
      ),
    );
  }

  Future<void> _lookup() async {
    final l10n = AppLocalizations.of(context);
    final code = _codeController.text
        .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')
        .trim()
        .toUpperCase();
    final error = Validators.validateTrackingCode(code);
    if (error != null) {
      setState(() {
        _validationError = switch (error) {
          TrackingCodeValidationError.empty => l10n.trackQuestionErrorEmpty,
          TrackingCodeValidationError.invalidLength =>
            l10n.trackQuestionErrorCodeLength,
          TrackingCodeValidationError.invalidFormat =>
            l10n.trackQuestionErrorCodeFormat,
        };
      });
      return;
    }

    setState(() => _validationError = null);
    await ref
        .read(questionTrackingStatusProvider.notifier)
        .lookup(trackingCode: code);
  }
}

class _TrackingResultCard extends StatelessWidget {
  const _TrackingResultCard({required this.result});

  final QuestionTrackingStatus result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final statusText = switch (result.status) {
      'answered' => l10n.trackQuestionStatusAnswered,
      _ => l10n.trackQuestionStatusUnanswered,
    };
    final statusIcon = result.status == 'answered'
        ? LucideIcons.circleCheck
        : LucideIcons.clock3;

    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        side: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, size: 18, color: cs.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  statusText,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            if (result.createdAt != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.trackQuestionCreatedAt(context.timeAgo(result.createdAt!)),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (result.answeredAt != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                l10n.trackQuestionAnsweredAt(
                  context.timeAgo(result.answeredAt!),
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (result.status == 'answered' && !result.isPublished) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                l10n.trackQuestionAnswerNotPublished,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
            if (result.isPublished && result.answerId != null) ...[
              const SizedBox(height: AppSpacing.md),
              AppButton(
                label: l10n.trackQuestionOpenAnswer,
                variant: AppButtonVariant.secondary,
                leading: Icon(
                  LucideIcons.externalLink,
                  size: 16,
                  color: cs.onSecondary,
                ),
                isFullWidth: false,
                onPressed: () =>
                    context.push('${AppRoutes.answer}/${result.answerId}'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
      composing: TextRange.empty,
    );
  }
}
