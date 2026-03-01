import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/feed/presentation/feed_providers.dart' show toggleLikeProvider;
import 'package:askme_humg/l10n/app_localizations.dart';

class LikeButton extends ConsumerWidget {
  const LikeButton({
    super.key,
    required this.answerId,
    required this.likeCount,
    required this.likedBy,
  });

  final String answerId;
  final int likeCount;
  final List<String> likedBy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final uid = ref.watch(authStateProvider).asData?.value?.uid;
    final isLiked = uid != null && likedBy.contains(uid);
    final isLoading = ref.watch(toggleLikeProvider(answerId)).isLoading;

    void handleTap() {
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.loginRequiredToLike)),
        );
        return;
      }
      ref.read(toggleLikeProvider(answerId).notifier).toggle(
            uid: uid,
            isCurrentlyLiked: isLiked,
          );
    }

    return Semantics(
      label: isLiked
          ? '$likeCount likes, liked'
          : '$likeCount likes',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : handleTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.heart,
                  color: isLiked
                      ? cs.error
                      : cs.onSurface.withValues(alpha: 0.5),
                  size: 20,
                )
                    .animate(target: isLiked ? 1.0 : 0.0)
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      duration: 150.ms,
                    )
                    .then()
                    .scale(
                      begin: const Offset(1.3, 1.3),
                      end: const Offset(1, 1),
                      duration: 100.ms,
                    ),
                const SizedBox(width: 4),
                Text(
                  '$likeCount',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: isLiked
                            ? cs.error
                            : cs.onSurface.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
