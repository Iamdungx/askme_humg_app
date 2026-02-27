import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.showRing = true,
    this.ringColor,
    this.ringWidth = 2,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final bool showRing;

  /// Defaults to colorScheme.primary when null.
  final Color? ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    final effectiveRingColor =
        ringColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: effectiveRingColor, width: ringWidth),
            )
          : null,
      child: Padding(
        padding: showRing ? EdgeInsets.all(ringWidth) : EdgeInsets.zero,
        child: ClipOval(child: _buildImage(context)),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => _buildFallback(context),
        errorWidget: (_, _, _) => _buildFallback(context),
      );
    }
    return _buildFallback(context);
  }

  Widget _buildFallback(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final initial = (name != null && name!.isNotEmpty)
        ? name![0].toUpperCase()
        : '?';
    return Container(
      color: cs.surfaceContainerHigh,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: cs.primary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
