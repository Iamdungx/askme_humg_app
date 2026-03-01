import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/error_state.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/comment_tile.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Opens the comments bottom sheet for a given answer.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String answerId,
  required int commentCount,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    useSafeArea: true,
    builder: (_) => DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (ctx, scrollController) => _CommentsSheetContent(
        answerId: answerId,
        commentCount: commentCount,
        scrollController: scrollController,
      ),
    ),
  );
}

class _CommentsSheetContent extends ConsumerWidget {
  const _CommentsSheetContent({
    required this.answerId,
    required this.commentCount,
    required this.scrollController,
  });

  final String answerId;
  final int commentCount;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final commentsAsync = ref.watch(commentsProvider(answerId));

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Header — live count from stream, falls back to initial commentCount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                Text(
                  '${l10n.commentTitle} (${commentsAsync.asData?.value.length ?? commentCount})',
                  style: tt.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(LucideIcons.x, color: cs.onSurface.withValues(alpha: 0.6)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Divider(color: cs.outline.withValues(alpha: 0.3)),

          // Comment list
          Expanded(
            child: commentsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(commentsProvider(answerId)),
              ),
              data: (comments) {
                if (comments.isEmpty) {
                  return Center(
                    child: Text(
                      l10n.commentEmpty,
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemCount: comments.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.xl),
                  itemBuilder: (_, i) => CommentTile(comment: comments[i]),
                );
              },
            ),
          ),

          // Input bar
          _CommentInputBar(answerId: answerId),
        ],
      ),
    );
  }
}

class _CommentInputBar extends ConsumerStatefulWidget {
  const _CommentInputBar({required this.answerId});

  final String answerId;

  @override
  ConsumerState<_CommentInputBar> createState() => _CommentInputBarState();
}

class _CommentInputBarState extends ConsumerState<_CommentInputBar> {
  final _controller = TextEditingController();
  bool _isAnonymous = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    final uid = ref.read(authStateProvider).asData?.value?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.loginRequiredToComment)),
      );
      return;
    }

    setState(() => _error = null);

    final errorKey = await ref.read(postCommentProvider.notifier).post(
          answerId: widget.answerId,
          content: _controller.text,
          isAnonymous: _isAnonymous,
        );

    if (!mounted) return;

    if (errorKey == 'errorCommentEmpty') {
      setState(() => _error = l10n.errorCommentEmpty);
      return;
    }
    if (errorKey == 'errorCommentTooLong') {
      setState(() => _error = l10n.errorCommentTooLong);
      return;
    }
    if (errorKey != null) {
      final msg = errorKey == 'commonError' ? l10n.commonError : errorKey;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    _controller.clear();
    setState(() => _error = null);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPosting = ref.watch(postCommentProvider).isLoading;

    return Container(
      color: cs.surfaceContainerLow,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Anonymous toggle row
          Row(
            children: [
              Icon(LucideIcons.lock, size: 18, color: cs.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                l10n.commentAnonymousToggle,
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const Spacer(),
              Switch(
                value: _isAnonymous,
                onChanged: (v) => setState(() => _isAnonymous = v),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Input + send row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  minLines: 1,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: l10n.commentInputHint,
                    errorText: _error,
                    counterText: '',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                icon: isPosting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: cs.primary,
                        ),
                      )
                    : Icon(LucideIcons.sendHorizontal, color: cs.primary),
                onPressed: isPosting ? null : _submit,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
