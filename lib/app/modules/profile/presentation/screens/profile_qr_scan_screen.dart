import 'dart:math' show min;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:askme_humg/app/core/utils/logger.dart';
import 'package:askme_humg/app/core/utils/mobile_scanner_support.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/utils/profile_deep_link_parser.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

/// In-app QR scanner for UC-2.1 profile deep links (opened from own profile tab).
class ProfileQrScanScreen extends StatefulWidget {
  const ProfileQrScanScreen({super.key});

  @override
  State<ProfileQrScanScreen> createState() => _ProfileQrScanScreenState();
}

class _ProfileQrScanScreenState extends State<ProfileQrScanScreen> {
  MobileScannerController? _controller;
  bool _handled = false;
  DateTime? _lastInvalidSnack;
  bool _importingImage = false;

  @override
  void initState() {
    super.initState();
    if (isMobileScannerPlatformSupported) {
      _controller = MobileScannerController();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  /// Same geometry as [UI_UX_SPECS] / profile_scan_qr.html — square ~65%, max 320.
  static Rect _scanWindowRect(Size size) {
    final shortest = min(size.width, size.height);
    final side = min(shortest * 0.65, 320.0);
    final left = (size.width - side) / 2;
    final top = (size.height - side) / 2;
    return Rect.fromLTWH(left, top, side, side);
  }

  String? _payloadFromBarcode(Barcode barcode) {
    final raw = barcode.rawValue;
    if (raw != null && raw.isNotEmpty) return raw;
    final url = barcode.url?.url;
    if (url != null && url.isNotEmpty) return url;
    return null;
  }

  void _showInvalidThrottled() {
    final now = DateTime.now();
    if (_lastInvalidSnack != null &&
        now.difference(_lastInvalidSnack!) < const Duration(seconds: 2)) {
      return;
    }
    _lastInvalidSnack = now;
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.profileScanQrInvalid)));
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    for (final barcode in barcodes) {
      final payload = _payloadFromBarcode(barcode);
      if (payload == null) continue;
      final path = parseProfileDeepLinkToPath(payload);
      if (path != null) {
        _handled = true;
        _controller?.stop();
        if (!mounted) return;
        context.go(path);
        return;
      }
      _showInvalidThrottled();
      return;
    }
  }

  Future<void> _pickImageFromGallery() async {
    final controller = _controller;
    if (controller == null || _handled || _importingImage) return;

    setState(() => _importingImage = true);
    try {
      final picker = ImagePicker();
      final file = await picker.pickImage(source: ImageSource.gallery);
      if (file == null || !mounted) return;

      final capture = await controller.analyzeImage(file.path);
      if (!mounted) return;
      if (capture == null || capture.barcodes.isEmpty) {
        _showInvalidThrottled();
        return;
      }
      _onDetect(capture);
    } on MobileScannerBarcodeException catch (e, st) {
      logger.w('QR analyze image: $e', stackTrace: st);
      _showInvalidThrottled();
    } catch (e, st) {
      logger.e('pick/analyze QR image failed', error: e, stackTrace: st);
      if (mounted) _showInvalidThrottled();
    } finally {
      if (mounted) setState(() => _importingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (!isMobileScannerPlatformSupported) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.profileScanQrTitle),
          leading: IconButton(
            icon: Icon(LucideIcons.arrowLeft, color: cs.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Center(
            child: Text(
              l10n.profileScanQrUnsupportedPlatform,
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final controller = _controller!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profileScanQrTitle),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scanWindow = kIsWeb
                    ? null
                    : _scanWindowRect(constraints.biggest);

                return MobileScanner(
                  controller: controller,
                  fit: BoxFit.cover,
                  scanWindow: scanWindow,
                  onDetect: _onDetect,
                  overlayBuilder: (context, constraints) {
                    final size = constraints.biggest;
                    final sw = kIsWeb ? null : _scanWindowRect(size);

                    if (sw == null) {
                      return const SizedBox.shrink();
                    }

                    return IgnorePointer(
                      child: CustomPaint(
                        size: size,
                        painter: _QrCornerBracketsPainter(
                          scanRect: sw,
                          color: cs.primary,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Text(
                        error.errorDetails?.message ?? error.errorCode.name,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          _QrScanBottomBar(
            controller: controller,
            importingImage: _importingImage,
            onImportImage: _pickImageFromGallery,
          ),
        ],
      ),
    );
  }
}

/// Bottom bar: [torch] · [flat QR orb] · [gallery] — no wide outline pill.
class _QrScanBottomBar extends StatelessWidget {
  const _QrScanBottomBar({
    required this.controller,
    required this.importingImage,
    required this.onImportImage,
  });

  final MobileScannerController controller;
  final bool importingImage;
  final VoidCallback onImportImage;

  static const double _sideSlot = 52;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return ColoredBox(
      color: cs.surface,
      child: SafeArea(
        top: false,
        minimum: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _sideSlot,
                child: _TorchBarIconButton(controller: controller),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -8),
                  child: const _ScanCenterOrb(),
                ),
              ),
              SizedBox(
                width: _sideSlot,
                child: _GalleryBarIconButton(
                  importingImage: importingImage,
                  onImportImage: onImportImage,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TorchBarIconButton extends StatelessWidget {
  const _TorchBarIconButton({required this.controller});

  final MobileScannerController controller;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return ValueListenableBuilder<MobileScannerState>(
      valueListenable: controller,
      builder: (context, state, _) {
        final torch = state.torchState;
        final hasTorch = torch != TorchState.unavailable;
        final on = torch == TorchState.on;

        return Tooltip(
          message: l10n.profileScanQrFlashTooltip,
          child: IconButton(
            onPressed: hasTorch
                ? () async {
                    await controller.toggleTorch();
                  }
                : null,
            style: IconButton.styleFrom(
              foregroundColor: hasTorch
                  ? (on ? cs.primary : cs.onSurfaceVariant)
                  : cs.onSurfaceVariant.withValues(
                      alpha: AppSemanticColors.opacityDisabled,
                    ),
            ),
            icon: Icon(
              on ? LucideIcons.flashlight : LucideIcons.flashlightOff,
              size: AppIconSize.xl,
            ),
          ),
        );
      },
    );
  }
}

/// Decorative center orb (non-interactive) — flat fill, no shadow/glow.
class _ScanCenterOrb extends StatelessWidget {
  const _ScanCenterOrb();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IgnorePointer(
      child: ExcludeSemantics(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(shape: BoxShape.circle, color: cs.primary),
          alignment: Alignment.center,
          child: Icon(LucideIcons.qrCode, size: 30, color: cs.onPrimary),
        ),
      ),
    );
  }
}

class _GalleryBarIconButton extends StatelessWidget {
  const _GalleryBarIconButton({
    required this.importingImage,
    required this.onImportImage,
  });

  final bool importingImage;
  final VoidCallback onImportImage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;

    return Tooltip(
      message: l10n.profileScanQrImportImage,
      child: IconButton(
        onPressed: importingImage ? null : onImportImage,
        style: IconButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
        icon: importingImage
            ? SizedBox(
                width: AppIconSize.xl,
                height: AppIconSize.xl,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: cs.primary,
                ),
              )
            : Icon(LucideIcons.images, size: AppIconSize.xl),
      ),
    );
  }
}

/// L-shaped corners only — no dimmed overlay outside the guide rect.
class _QrCornerBracketsPainter extends CustomPainter {
  _QrCornerBracketsPainter({required this.scanRect, required this.color});

  final Rect scanRect;
  final Color color;

  static const double _bracketLength = 40;
  static const double _strokeWidth = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square
      ..strokeJoin = StrokeJoin.miter;

    final r = scanRect;
    const len = _bracketLength;

    canvas.drawLine(Offset(r.left, r.top + len), Offset(r.left, r.top), paint);
    canvas.drawLine(Offset(r.left, r.top), Offset(r.left + len, r.top), paint);

    canvas.drawLine(
      Offset(r.right - len, r.top),
      Offset(r.right, r.top),
      paint,
    );
    canvas.drawLine(
      Offset(r.right, r.top),
      Offset(r.right, r.top + len),
      paint,
    );

    canvas.drawLine(
      Offset(r.left, r.bottom - len),
      Offset(r.left, r.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(r.left, r.bottom),
      Offset(r.left + len, r.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(r.right - len, r.bottom),
      Offset(r.right, r.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(r.right, r.bottom),
      Offset(r.right, r.bottom - len),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _QrCornerBracketsPainter oldDelegate) {
    return oldDelegate.scanRect != scanRect || oldDelegate.color != color;
  }
}
