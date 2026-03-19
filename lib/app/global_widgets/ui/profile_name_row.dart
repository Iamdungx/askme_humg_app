import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/verified_badge.dart';

/// Displays a user name with an optional [VerifiedBadge] inline.
///
/// Used in [ProfileHeader] and [_HeroSection] (EditProfileScreen) to keep
/// the name + badge layout consistent across screens.
class ProfileNameRow extends StatelessWidget {
  const ProfileNameRow({
    super.key,
    required this.name,
    required this.isHumgVerified,
  });

  final String name;
  final bool isHumgVerified;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isHumgVerified) ...[
          const SizedBox(width: AppSpacing.xs),
          const VerifiedBadge(size: 20, inline: true),
        ],
      ],
    );
  }
}
