import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// Generic shimmer skeleton that mirrors the [FeedItemCard] layout.
/// Used by [FeedLoadingShimmer] and any other loading placeholder.
class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerHighest,
      child: _SkeletonCard(cs: cs),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar · name/timestamp · anonymous badge · more ──
          Row(
            children: [
              _Circle(cs: cs, size: 40),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Rect(cs: cs, width: 130, height: 12),
                    const SizedBox(height: AppSpacing.xs),
                    _Rect(cs: cs, width: 80, height: 10),
                  ],
                ),
              ),
              // Anonymous badge pill
              _Rect(cs: cs, width: 64, height: 20, radius: AppRadius.full),
              const SizedBox(width: AppSpacing.sm),
              // More (⋯) icon placeholder
              _Circle(cs: cs, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // ── Question block (italic text, 2 lines) ─────────────────────
          _Rect(cs: cs, width: double.infinity, height: 12),
          const SizedBox(height: AppSpacing.xs),
          _Rect(cs: cs, width: 220, height: 12),
          const SizedBox(height: AppSpacing.sm),

          // ── Answer block: left border accent + content lines ──────────
          _AnswerBlock(cs: cs),
          const SizedBox(height: AppSpacing.md),

          // ── Divider ───────────────────────────────────────────────────
          _Rect(cs: cs, width: double.infinity, height: 1),
          const SizedBox(height: AppSpacing.md),

          // ── Action row: like · comment · spacer · share ───────────────
          Row(
            children: [
              _Rect(cs: cs, width: 52, height: 20),
              const SizedBox(width: AppSpacing.xl),
              _Rect(cs: cs, width: 52, height: 20),
              const Spacer(),
              _Circle(cs: cs, size: 20),
            ],
          ),
        ],
      ),
    );
  }
}

/// Answer block with a 3dp left-border accent, mirroring [FeedItemCard]'s answer section.
class _AnswerBlock extends StatelessWidget {
  const _AnswerBlock({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(AppRadius.sm),
          bottomRight: Radius.circular(AppRadius.sm),
        ),
        border: Border(left: BorderSide(color: cs.primary, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Rect(cs: cs, width: double.infinity, height: 11),
          const SizedBox(height: AppSpacing.xs),
          _Rect(cs: cs, width: double.infinity, height: 11),
          const SizedBox(height: AppSpacing.xs),
          _Rect(cs: cs, width: 180, height: 11),
        ],
      ),
    );
  }
}

class _Rect extends StatelessWidget {
  const _Rect({
    required this.cs,
    required this.width,
    required this.height,
    this.radius = AppRadius.sm,
  });

  final ColorScheme cs;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.cs, required this.size});

  final ColorScheme cs;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        shape: BoxShape.circle,
      ),
    );
  }
}
