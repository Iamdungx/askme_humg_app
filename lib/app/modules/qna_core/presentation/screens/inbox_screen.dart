import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/empty_state.dart';
import 'package:askme_humg/app/global_widgets/error_state.dart';
import 'package:askme_humg/app/global_widgets/loading_shimmer.dart';
import 'package:askme_humg/app/modules/qna_core/domain/question.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/qna_providers.dart';
import 'package:askme_humg/app/modules/qna_core/presentation/widgets/question_card.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class InboxScreen extends ConsumerStatefulWidget {
  const InboxScreen({super.key});

  @override
  ConsumerState<InboxScreen> createState() => _InboxScreenState();
}

class _InboxScreenState extends ConsumerState<InboxScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final inboxAsync = ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inboxTitle),
        bottom: inboxAsync.when(
          loading: () => _buildTabBar(context, l10n, 0, 0),
          error: (e, s) => _buildTabBar(context, l10n, 0, 0),
          data: (questions) {
            final unansweredCount =
                questions.where((q) => q.status == 'unanswered').length;
            return _buildTabBar(context, l10n, unansweredCount, 0);
          },
        ),
      ),
      body: inboxAsync.when(
        loading: () => const LoadingShimmer(),
        error: (error, _) => ErrorState(
          message: error.toString(),
          onRetry: () => ref.invalidate(inboxProvider),
        ),
        data: (questions) {
          final unanswered =
              questions.where((q) => q.status == 'unanswered').toList();
          final answered =
              questions.where((q) => q.status == 'answered').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _QuestionList(
                questions: unanswered,
                showReply: true,
                emptyMessage: l10n.inboxEmptyUnanswered,
                onReply: (q) => AnswerComposeRoute(questionId: q.questionId).push(context),
                onDelete: (q) => _deleteQuestion(q),
              ),
              _QuestionList(
                questions: answered,
                showReply: false,
                emptyMessage: l10n.inboxEmptyAnswered,
                emptyIcon: LucideIcons.circleCheck,
                onDelete: (q) => _deleteQuestion(q),
              ),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildTabBar(
    BuildContext context,
    AppLocalizations l10n,
    int unansweredCount,
    int answeredCount,
  ) {
    final cs = Theme.of(context).colorScheme;
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.inboxTabUnanswered),
                if (unansweredCount > 0) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: cs.error,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      '$unansweredCount',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cs.onError,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Tab(text: l10n.inboxTabAnswered),
        ],
      ),
    );
  }

  Future<void> _deleteQuestion(Question question) async {
    await ref
        .read(deleteQuestionProvider.notifier)
        .delete(question.questionId);

    if (!mounted) return;
    final state = ref.read(deleteQuestionProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.error.toString()),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}

class _QuestionList extends StatelessWidget {
  const _QuestionList({
    required this.questions,
    required this.showReply,
    required this.emptyMessage,
    this.emptyIcon,
    this.onReply,
    this.onDelete,
  });

  final List<Question> questions;
  final bool showReply;
  final String emptyMessage;
  final IconData? emptyIcon;
  final void Function(Question)? onReply;
  final void Function(Question)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return EmptyState(
        message: emptyMessage,
        icon: emptyIcon ?? LucideIcons.inbox,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: questions.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final question = questions[index];
        return QuestionCard(
          question: question,
          showReply: showReply,
          onReply: onReply != null ? () => onReply!(question) : null,
          onDelete: onDelete != null ? () => onDelete!(question) : null,
        );
      },
    );
  }
}
