import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gal/gal.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/share_card_style.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Public shell widget (bottom sheet content)
// ---------------------------------------------------------------------------

class ShareCardWidget extends ConsumerStatefulWidget {
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
  ConsumerState<ShareCardWidget> createState() => _ShareCardWidgetState();
}

class _ShareCardWidgetState extends ConsumerState<ShareCardWidget> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;
  bool _isSaving = false;

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: widget.deepLink));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context).profileLinkCopied)),
    );
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

  Future<File?> _captureCardFile() async {
    final boundary =
        _cardKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final image = await boundary.toImage(pixelRatio: 3.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;
    final bytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/askme_profile_card.png');
    await file.writeAsBytes(bytes);
    return file;
  }

  Future<void> _saveImage(BuildContext context) async {
    if (_isSharing || _isSaving) return;
    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context);
    try {
      if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.editProfilePickerUnavailable)),
        );
        return;
      }
      final file = await _captureCardFile();
      if (file == null || !context.mounted) return;
      await Gal.putImage(file.path);
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.shareCardImageSaved)));
    } on GalException catch (e) {
      if (!context.mounted) return;
      final message = e.type == GalExceptionType.accessDenied
          ? l10n.editProfilePickerPermissionDenied
          : l10n.commonError;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } on MissingPluginException {
      if (!context.mounted) return;
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.editProfilePickerUnavailable)),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final style = ref.watch(shareCardStyleProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Card preview
          LayoutBuilder(
            builder: (_, innerConstraints) => RepaintBoundary(
              key: _cardKey,
              child: SizedBox(
                width: innerConstraints.maxWidth,
                child: _ShareCard(
                  displayName: widget.displayName,
                  avatarUrl: widget.avatarUrl,
                  deepLink: widget.deepLink,
                  style: style,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Inline style picker — thumbnails scrollable horizontally
          SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: ShareCardStyle.values
                  .map(
                    (s) => _StyleChip(
                      style: s,
                      isSelected: style == s,
                      onTap: () =>
                          ref.read(shareCardStyleProvider.notifier).setStyle(s),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.download, size: 18),
                  label: Text(l10n.commonSave),
                  onPressed: () => _saveImage(context),
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
                  isLoading: _isSharing || _isSaving,
                  onPressed: () => _shareImage(context),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                tooltip: l10n.commonCopyLink,
                onPressed: () => _copyLink(context),
                icon: const Icon(LucideIcons.link2, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The visual card captured as PNG
// ---------------------------------------------------------------------------

class _ShareCard extends StatelessWidget {
  const _ShareCard({
    required this.displayName,
    required this.avatarUrl,
    required this.deepLink,
    required this.style,
  });

  final String displayName;
  final String avatarUrl;
  final String deepLink;
  final ShareCardStyle style;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background PNG asset ──────────────────────────────────────
            Image.asset(
              style.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: BoxDecoration(gradient: style.fallbackGradient),
              ),
            ),

            // ── Content overlay for readability ──────────────────────────
            ColoredBox(color: style.contentOverlay),

            // ── Gradient scrim (vignette) for extra text legibility ───────
            DecoratedBox(
              decoration: BoxDecoration(gradient: style.contentScrim),
            ),

            // ── Full card content: top info + centered QR ────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // ── Top: avatar + name + tagline ─────────────────────────
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: style.avatarRingGradient,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: style.avatarGapColor,
                      ),
                      child: AppAvatar(
                        imageUrl: avatarUrl,
                        name: displayName,
                        size: 64,
                        showRing: false,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: style.textPrimary,
                      letterSpacing: -0.3,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // App pill badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: style.pillBgColor,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: style.pillBorderColor,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      '${l10n.appBrandName} ${l10n.appBrandSuffix}',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: style.accentTextColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Text(
                    l10n.profileShareCardTagline,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: style.textPrimary,
                      height: 1.4,
                      letterSpacing: -0.1,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // ── Center: big QR code ───────────────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(10),
                    child: QrImageView(
                      data: deepLink,
                      version: QrVersions.auto,
                      size: 140,
                      backgroundColor: cs.surface,
                      eyeStyle: QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: cs.onSurface,
                      ),
                      dataModuleStyle: QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: cs.onSurface,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // ── Bottom: brand ─────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.messageCircle,
                        size: 13,
                        color: style.accentTextColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.appBrandName} ${l10n.appBrandSuffix}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: style.textPrimary,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Individual style chip in the picker
class _StyleChip extends StatelessWidget {
  const _StyleChip({
    required this.style,
    required this.isSelected,
    required this.onTap,
  });

  final ShareCardStyle style;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 10),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? cs.primary : Colors.transparent,
            width: 2.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cs.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background asset preview
              Image.asset(
                style.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(gradient: style.fallbackGradient),
                ),
              ),

              // Label
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.35),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    style.label(context),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              // Checkmark when selected
              if (isSelected)
                const Positioned(
                  top: 6,
                  right: 6,
                  child: CircleAvatar(
                    radius: 8,
                    backgroundColor: Colors.white,
                    child: Icon(
                      LucideIcons.check,
                      size: 10,
                      color: Colors.black87,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
