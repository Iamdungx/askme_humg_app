import 'package:flutter/material.dart';
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
      AppButtonVariant.primary => _buildFilled(context),
      AppButtonVariant.secondary => _buildOutlined(context),
      AppButtonVariant.ghost => _buildGhost(context),
      AppButtonVariant.danger => _buildDanger(context),
    };
  }

  Widget _buildFilled(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cs.primary,
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(cs.onPrimary),
    );
  }

  Widget _buildOutlined(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: cs.primary),
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(cs.primary),
    );
  }

  Widget _buildGhost(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return TextButton(
      onPressed: isLoading ? null : onPressed,
      style: TextButton.styleFrom(
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(cs.onSurfaceVariant),
    );
  }

  Widget _buildDanger(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: cs.error,
        minimumSize: Size(isFullWidth ? double.infinity : 0, minimumHeight),
      ),
      child: _buildChild(cs.onError),
    );
  }

  Widget _buildChild(Color color) {
    if (isLoading) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
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
