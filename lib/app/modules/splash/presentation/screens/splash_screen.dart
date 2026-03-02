import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/generated/assets.gen.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/ui/app_brand_wordmark.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _minSplashDuration = Duration(milliseconds: 2800);
  static const _authTimeout = Duration(seconds: 10);

  // Both conditions must be true before navigating
  bool _minDelayDone = false;
  bool _authResolved = false;
  bool _navigated = false;

  ProviderSubscription<AsyncValue<dynamic>>? _authSub;

  @override
  void initState() {
    super.initState();
    Future.delayed(_minSplashDuration, () {
      if (!mounted) return;
      _minDelayDone = true;
      _maybeNavigate();
    });

    _authSub = ref.listenManual<AsyncValue<dynamic>>(authStateProvider, (
      _,
      next,
    ) {
      if (next.isLoading) return;
      _authResolved = true;
      _maybeNavigate();
    }, fireImmediately: true);

    Future.delayed(_authTimeout, () {
      if (!mounted || _navigated) return;
      _authResolved = true;
      _maybeNavigate();
    });
  }

  void _maybeNavigate() {
    if (!_minDelayDone || !_authResolved || _navigated) return;
    _navigated = true;
    _authSub?.close();
    final isLoggedIn = ref.read(authStateProvider).asData?.value != null;
    if (isLoggedIn) {
      context.go('/');
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _authSub?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Assets.imagesAppIcon
                .image(width: 180, height: 180)
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: AppSpacing.xl),

            const AppBrandWordmark()
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms)
                .slideY(
                  begin: 0.3,
                  end: 0,
                  delay: 400.ms,
                  duration: 500.ms,
                  curve: Curves.easeOut,
                ),

            const SizedBox(height: AppSpacing.sm),

            Text(
              l10n.splashTagline,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: cs.onSurfaceVariant,
                letterSpacing: 0.2,
              ),
            ).animate().fadeIn(delay: 700.ms, duration: 500.ms),

            const SizedBox(height: 64),

            _PulsingDots(
              color: cs.primary,
            ).animate().fadeIn(delay: 1000.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  const _PulsingDots({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(
              delay: Duration(milliseconds: i * 180),
              duration: 300.ms,
            )
            .then()
            .fadeOut(duration: 300.ms)
            .then(delay: Duration(milliseconds: (2 - i) * 180));
      }),
    );
  }
}
