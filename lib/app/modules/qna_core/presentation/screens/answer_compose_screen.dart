import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/app/global_widgets/error_state.dart';
import 'package:askme_humg/app/global_widgets/loading_shimmer.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/widgets/answer_publish_toggle.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class AnswerComposeScreen extends ConsumerStatefulWidget {
  const AnswerComposeScreen({super.key, required this.questionId});

  final String questionId;

  @override
  ConsumerState<AnswerComposeScreen> createState() =>
      _AnswerComposeScreenState();
}

class _AnswerComposeScreenState extends ConsumerState<AnswerComposeScreen> {
  static const int _maxChars = 2000;

  final _controller = TextEditingController();
  bool _isPublished = true;
  String? _validationError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final questionAsync = ref.watch(questionByIdProvider(widget.questionId));
    final answerState = ref.watch(answerProvider);

    ref.listen(answerProvider, (_, next) {
      if (!next.isLoading && !next.hasError && next.hasValue) {
        if (!context.mounted) return;
        final msg = _isPublished ? l10n.answerPublishSuccess : l10n.answerSaved;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
        context.pop();
      } else if (next.hasError) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.commonError),
            backgroundColor: cs.error,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.answerComposeTitle),
        centerTitle: true,
      ),
      body: questionAsync.when(
        loading: () => const LoadingShimmer(),
        error: (e, _) => ErrorState(
          message: l10n.commonError,
          onRetry: () =>
              ref.invalidate(questionByIdProvider(widget.questionId)),
        ),
        data: (question) {
          if (question == null) {
            return ErrorState(message: l10n.commonError);
          }
          return _buildContent(context, l10n, cs, question, answerState);
        },
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ColorScheme cs,
    Question question,
    AsyncValue<void> answerState,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _QuestionCard(question: question, l10n: l10n, cs: cs),
          const SizedBox(height: AppSpacing.xl),
          Text(
            l10n.answerComposeTitle,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _controller,
            minLines: 5,
            maxLines: null,
            maxLength: _maxChars,
            onChanged: (_) {
              if (_validationError != null) {
                setState(() => _validationError = null);
              }
            },
            style: TextStyle(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: l10n.answerComposeHint,
              hintStyle: TextStyle(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              errorText: _validationError,
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              contentPadding: const EdgeInsets.all(AppSpacing.lg),
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
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AnswerPublishToggle(
            value: _isPublished,
            onChanged: (v) => setState(() => _isPublished = v),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: _isPublished ? l10n.answerPublishButton : l10n.answerSaveButton,
            variant: AppButtonVariant.primary,
            isLoading: answerState.isLoading,
            onPressed: answerState.isLoading ? null : _submit,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final content = _controller.text.trim();
    final l10n = AppLocalizations.of(context);
    if (content.isEmpty) {
      setState(() => _validationError = l10n.answerErrorEmpty);
      return;
    }
    if (content.length > _maxChars) {
      setState(() => _validationError = l10n.answerErrorTooLong);
      return;
    }

    await ref.read(answerProvider.notifier).submit(
      questionId: widget.questionId,
      content: content,
      isPublished: _isPublished,
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    required this.l10n,
    required this.cs,
  });

  final Question question;
  final AppLocalizations l10n;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: cs.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: cs.surfaceContainer,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('📩', style: TextStyle(fontSize: 12)),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  l10n.inboxQuestionFrom.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            question.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(LucideIcons.clock, size: 12, color: cs.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.answerReceivedTimeAgo(
                  timeago.format(
                    question.createdAt,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
