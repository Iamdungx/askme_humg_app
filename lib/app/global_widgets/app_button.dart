import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost, danger, google }

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
      AppButtonVariant.google => _buildGoogle(context),
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

  Widget _buildGoogle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: minimumHeight,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surfaceContainerHigh,
          side: BorderSide(color: cs.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        ),
        child: isLoading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: cs.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _GoogleLogoIcon(),
                  const SizedBox(width: AppSpacing.md),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
      ),
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

// ---------------------------------------------------------------------------
// Google "G" logo — reusable 20dp icon
// ---------------------------------------------------------------------------

class _GoogleLogoIcon extends StatelessWidget {
  const _GoogleLogoIcon();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  const _GoogleLogoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;

    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.938, w * 0.510)
        ..cubicTo(w * 0.938, w * 0.476, w * 0.935, w * 0.443, w * 0.930, w * 0.412)
        ..lineTo(w * 0.500, w * 0.412)
        ..lineTo(w * 0.500, w * 0.588)
        ..lineTo(w * 0.747, w * 0.588)
        ..cubicTo(w * 0.736, w * 0.642, w * 0.704, w * 0.687, w * 0.657, w * 0.715)
        ..lineTo(w * 0.657, w * 0.831)
        ..cubicTo(w * 0.804, w * 0.789, w * 0.938, w * 0.662, w * 0.938, w * 0.510)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.500, w * 0.958)
        ..cubicTo(w * 0.624, w * 0.958, w * 0.728, w * 0.916, w * 0.803, w * 0.843)
        ..lineTo(w * 0.657, w * 0.727)
        ..cubicTo(w * 0.615, w * 0.755, w * 0.561, w * 0.773, w * 0.500, w * 0.773)
        ..cubicTo(w * 0.381, w * 0.773, w * 0.279, w * 0.693, w * 0.243, w * 0.585)
        ..lineTo(w * 0.091, w * 0.585)
        ..lineTo(w * 0.091, w * 0.704)
        ..cubicTo(w * 0.166, w * 0.855, w * 0.321, w * 0.958, w * 0.500, w * 0.958)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.243, w * 0.585)
        ..cubicTo(w * 0.234, w * 0.557, w * 0.229, w * 0.528, w * 0.229, w * 0.500)
        ..cubicTo(w * 0.229, w * 0.472, w * 0.234, w * 0.443, w * 0.243, w * 0.415)
        ..lineTo(w * 0.243, w * 0.296)
        ..lineTo(w * 0.091, w * 0.296)
        ..cubicTo(w * 0.060, w * 0.357, w * 0.042, w * 0.427, w * 0.042, w * 0.500)
        ..cubicTo(w * 0.042, w * 0.573, w * 0.060, w * 0.643, w * 0.091, w * 0.704)
        ..lineTo(w * 0.243, w * 0.585)
        ..close(),
      paint,
    );

    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.500, w * 0.227)
        ..cubicTo(w * 0.568, w * 0.227, w * 0.628, w * 0.250, w * 0.675, w * 0.295)
        ..lineTo(w * 0.806, w * 0.164)
        ..cubicTo(w * 0.728, w * 0.091, w * 0.624, w * 0.042, w * 0.500, w * 0.042)
        ..cubicTo(w * 0.321, w * 0.042, w * 0.166, w * 0.145, w * 0.091, w * 0.296)
        ..lineTo(w * 0.243, w * 0.415)
        ..cubicTo(w * 0.279, w * 0.307, w * 0.381, w * 0.227, w * 0.500, w * 0.227)
        ..close(),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
