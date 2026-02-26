import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.leading,
    this.isLoading = false,
    this.isFullWidth = true,
    this.minimumHeight = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final Widget? leading;
  final bool isLoading;
  final bool isFullWidth;
  final double minimumHeight;

  @override
  Widget build(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary => _buildFilled(),
      AppButtonVariant.secondary => _buildOutlined(),
      AppButtonVariant.ghost => _buildGhost(),
      AppButtonVariant.danger => _buildDanger(),
    };
  }

  Widget _buildFilled() {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(AppColors.textPrimary),
    );
  }

  Widget _buildOutlined() {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: const BorderSide(color: AppColors.accent),
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(AppColors.accent),
    );
  }

  Widget _buildGhost() {
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(AppColors.textSecondary),
    );
  }

  Widget _buildDanger() {
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.error,
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(AppColors.textPrimary),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: color,
        ),
      );
    }
    if (leading != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading!,
          const SizedBox(width: AppSpacing.sm),
          Text(label),
        ],
      );
    }
    return Text(label);
  }
}
