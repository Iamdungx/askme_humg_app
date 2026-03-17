import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/extensions/context_extensions.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/layout/app_bottom_sheet.dart';
import 'package:askme_humg/app/global_widgets/input/app_comment_input.dart';
import 'package:askme_humg/app/global_widgets/states/error_state.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/network/firebase_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/widgets/comment_tile.dart';
import 'package:askme_humg/app/modules/settings/presentation/settings_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// Opens the comments bottom sheet for a given answer.
Future<void> showCommentsSheet(
  BuildContext context, {
  required String answerId,
  required int commentCount,
}) {
  return showAppScrollableSheet<void>(
    context: context,
    builder: (ctx, scrollController) => _CommentsSheetContent(
      answerId: answerId,
      commentCount: commentCount,
      scrollController: scrollController,
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

    return Column(
      children: [
        const SizedBox(height: AppSpacing.sm),

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
        Divider(
          height: 1,
          thickness: 1,
          color: cs.outline.withValues(alpha: 0.3),
        ),

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

    final authUser = ref.read(authStateProvider).asData?.value;
    final uid = authUser?.uid;
    final isVerified = authUser?.isHumgVerified == true;
    if (!context.requireVerified(
      uid: uid,
      isVerified: isVerified,
      loginMessage: l10n.loginRequiredToComment,
      verifyMessage: l10n.verifyRequiredToComment,
    )) { return; }

    setState(() => _error = null);

    final failure = await ref.read(postCommentProvider.notifier).post(
          answerId: widget.answerId,
          content: _controller.text,
          isAnonymous: _isAnonymous,
        );

    if (!mounted) return;

    if (failure is ValidationFailure) {
      final msg = failure.message == 'errorCommentEmpty'
          ? l10n.errorCommentEmpty
          : l10n.errorCommentTooLong;
      setState(() => _error = msg);
      return;
    }
    if (failure != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.commonError),
          backgroundColor: cs.error,
        ),
      );
      return;
    }

    final content = _controller.text;
    _controller.clear();
    setState(() => _error = null);

    await _triggerNotifyNewComment(ref, widget.answerId, content);
  }

  Future<void> _triggerNotifyNewComment(WidgetRef ref, String answerId, String content) async {
    final client = ref.read(notifyWebhookClientProvider);
    if (!client.isAvailable) return;
    final auth = ref.read(firebaseAuthProvider);
    final token = await auth.currentUser?.getIdToken(true);
    if (token == null) return;
    await client.sendNewComment(idToken: token, answerId: answerId, content: content);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isPosting = ref.watch(postCommentProvider).isLoading;

    return Container(
      color: cs.surfaceContainerHigh,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.lg,
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
                child: AppCommentInput(
                  controller: _controller,
                  hintText: l10n.commentInputHint,
                  errorText: _error,
                  maxLength: 500,
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
