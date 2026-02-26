import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

class AnonymousBadge extends StatelessWidget {
  const AnonymousBadge({
    super.key,
    this.label = 'Your identity is hidden',
    this.compact = false,
  });

  final String label;

  /// compact = true → chỉ hiện icon (dùng trong comment tile thay avatar)
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) return _buildCompact();
    return _buildFull();
  }

  Widget _buildFull() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.anonymousBadge,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border, width: 1),
      ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 12,
                color: AppColors.anonymousBadgeText,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.anonymousBadgeText,
                ),
              ),
            ],
          ),
    );
  }

  Widget _buildCompact() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.anonymousBadge,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: const Icon(
        Icons.lock_outline,
        size: 16,
        color: AppColors.anonymousBadgeText,
      ),
    );
  }
}
