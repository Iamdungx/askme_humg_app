import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: cs.surfaceContainerHigh,
      highlightColor: cs.surfaceContainerHighest,
      child: _buildSkeletonCard(cs),
    );
  }

  Widget _buildSkeletonCard(ColorScheme cs) {
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
          Row(
            children: [
              _box(cs, width: 40, height: 40, radius: 20),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(cs, width: 120, height: 12),
                  const SizedBox(height: 4),
                  _box(cs, width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _box(cs, width: 140, height: 20, radius: AppRadius.full),
          const SizedBox(height: AppSpacing.sm),
          _box(cs, width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(cs, width: 200, height: 12),
          const SizedBox(height: AppSpacing.md),
          _box(cs, width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(cs, width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(cs, width: 160, height: 12),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              _box(cs, width: 48, height: 20),
              const SizedBox(width: AppSpacing.lg),
              _box(cs, width: 48, height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box(
    ColorScheme cs, {
    required double width,
    required double height,
    double radius = AppRadius.sm,
  }) {
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
