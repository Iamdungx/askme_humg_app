import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_avatar.dart';
import 'package:askme_humg/app/global_widgets/ui/app_button.dart';
import 'package:askme_humg/app/modules/feed/domain/feed_item.dart';
import 'package:askme_humg/app/modules/profile/presentation/widgets/share_card_style.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class ShareAnswerCardWidget extends ConsumerStatefulWidget {
  const ShareAnswerCardWidget({
    super.key,
    required this.item,
    required this.deepLink,
  });

  final FeedItem item;
  final String deepLink;

  @override
  ConsumerState<ShareAnswerCardWidget> createState() =>
      _ShareAnswerCardWidgetState();
}

class _ShareAnswerCardWidgetState extends ConsumerState<ShareAnswerCardWidget> {
  final _cardKey = GlobalKey();
  bool _isSharing = false;

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
      final file = File('${dir.path}/askme_answer_card.png');
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
          LayoutBuilder(
            builder: (_, innerConstraints) => RepaintBoundary(
              key: _cardKey,
              child: SizedBox(
                width: innerConstraints.maxWidth,
                child: _AnswerShareCard(
                  item: widget.item,
                  deepLink: widget.deepLink,
                  style: style,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
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
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(LucideIcons.link2, size: 18),
                  label: Text(l10n.commonCopyLink),
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
    );
  }
}

class _AnswerShareCard extends StatelessWidget {
  const _AnswerShareCard({
    required this.item,
    required this.deepLink,
    required this.style,
  });

  final FeedItem item;
  final String deepLink;
  final ShareCardStyle style;

  String _clamp(String s, {required int max}) {
    final t = s.trim();
    if (t.length <= max) return t;
    return '${t.substring(0, max).trim()}…';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final question = _clamp(
      item.questionContent.isNotEmpty
          ? item.questionContent
          : l10n.feedEmptyQuestion,
      max: 120,
    );
    final answer = _clamp(item.answerContent, max: 420);

    return AspectRatio(
      aspectRatio: 4 / 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              style.assetPath,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => DecoratedBox(
                decoration: BoxDecoration(gradient: style.fallbackGradient),
              ),
            ),
            ColoredBox(color: style.contentOverlay),
            DecoratedBox(
              decoration: BoxDecoration(gradient: style.contentScrim),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                            imageUrl: item.hostAvatar,
                            name: item.hostName,
                            size: 44,
                            showRing: false,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.hostName.isNotEmpty
                                  ? item.hostName
                                  : l10n.feedFallbackHostName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: style.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 3),
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
                                l10n.feedShareAnswerPill,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: style.accentTextColor,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.appTitle,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: style.textPrimary,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(6),
                            child: QrImageView(
                              data: deepLink,
                              version: QrVersions.auto,
                              size: 64,
                              backgroundColor: Colors.white,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF000000),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF000000),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '“$question”',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: style.textPrimary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: style.footerBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: style.pillBorderColor.withValues(alpha: 0.6),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        answer,
                        maxLines: 11,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: style.textPrimary,
                          height: 1.5,
                        ),
                      ),
                    ),
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
              Image.asset(
                style.assetPath,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => DecoratedBox(
                  decoration: BoxDecoration(gradient: style.fallbackGradient),
                ),
              ),
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
