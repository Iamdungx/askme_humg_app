import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

class LoadingShimmer extends StatelessWidget {
  const LoadingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.shimmerBase,
      highlightColor: AppColors.shimmerHighlight,
      child: _buildSkeletonCard(),
    );
  }

  Widget _buildSkeletonCard() {
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar + name row
          Row(
            children: [
              _box(width: 40, height: 40, radius: 20),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _box(width: 120, height: 12),
                  const SizedBox(height: 4),
                  _box(width: 80, height: 10),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Question chip
          _box(width: 140, height: 20, radius: AppRadius.full),
          const SizedBox(height: AppSpacing.sm),
          // Question text
          _box(width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(width: 200, height: 12),
          const SizedBox(height: AppSpacing.md),
          // Answer text
          _box(width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(width: double.infinity, height: 12),
          const SizedBox(height: 4),
          _box(width: 160, height: 12),
          const SizedBox(height: AppSpacing.md),
          // Actions row
          Row(
            children: [
              _box(width: 48, height: 20),
              const SizedBox(width: AppSpacing.lg),
              _box(width: 48, height: 20),
            ],
          ),
        ],
      ),
    );
  }

  Widget _box({
    required double width,
    required double height,
    double radius = AppRadius.sm,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
