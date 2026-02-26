import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = 40,
    this.showRing = true,
    this.ringColor = AppColors.accent,
    this.ringWidth = 2,
  });

  final String? imageUrl;
  final String? name;
  final double size;
  final bool showRing;
  final Color ringColor;
  final double ringWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: showRing
          ? BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: ringColor, width: ringWidth),
            )
          : null,
      child: Padding(
        padding: showRing ? EdgeInsets.all(ringWidth) : EdgeInsets.zero,
        child: ClipOval(child: _buildImage()),
      ),
    );
  }

  Widget _buildImage() {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildFallback(),
        errorWidget: (_, __, ___) => _buildFallback(),
      );
    }
    return _buildFallback();
  }

  Widget _buildFallback() {
    final initial =
        (name != null && name!.isNotEmpty) ? name![0].toUpperCase() : '?';
    return Container(
      color: AppColors.surfaceElevated,
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          color: AppColors.accent,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}
