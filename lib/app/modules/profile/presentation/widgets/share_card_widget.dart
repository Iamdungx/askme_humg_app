import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ShareCardWidget extends StatefulWidget {
  const ShareCardWidget({
    super.key,
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.deepLink,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final String deepLink;

  @override
  State<ShareCardWidget> createState() => _ShareCardWidgetState();
}

class _ShareCardWidgetState extends State<ShareCardWidget> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.deepLink));
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileLinkCopied)));
  }

  Future<void> _shareImage(BuildContext context) async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final boundary =
          _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final bytes = byteData.buffer.asUint8List();
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/askme_profile_card.png');
      await file.writeAsBytes(bytes);

      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(files: [XFile(file.path)], text: widget.deepLink),
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: AppSpacing.lg),

          // Title
          Text(
            l10n.profileShareCardTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Shareable card (captured via RepaintBoundary)
          RepaintBoundary(
            key: _cardKey,
            child: _ShareCard(
              displayName: widget.displayName,
              avatarUrl: widget.avatarUrl,
              deepLink: widget.deepLink,
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: Icon(LucideIcons.link2, size: 18),
                  label: Text(l10n.profileShareLink),
                  onPressed: () => _copyLink(context),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    side: BorderSide(color: cs.outline),
                    foregroundColor: cs.onSurface,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppButton(
                  label: l10n.commonShare,
                  variant: AppButtonVariant.primary,
                  leading: Icon(
                    LucideIcons.share2,
                    size: 18,
                    color: cs.onPrimary,
                  ),
                  isLoading: _isSharing,
                  onPressed: () => _shareImage(context),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
    );
  }
}

// ---------------------------------------------------------------------------
// The visual card that gets captured as PNG
// ---------------------------------------------------------------------------

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.displayName,
    required this.avatarUrl,
    required this.deepLink,
  });

  final String displayName;
  final String avatarUrl;
  final String deepLink;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        children: [
          AppAvatar(
            imageUrl: avatarUrl,
            name: displayName,
            size: 80,
            showRing: true,
            ringColor: cs.secondary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            displayName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppLocalizations.of(context).profileShareCardTitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.xl),
          QrImageView(
            data: deepLink,
            version: QrVersions.auto,
            size: 120,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            deepLink,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
