import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/core/values/app_assets.dart';
import 'package:askme_humg/app/core/values/app_colors.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to feed after animations complete
    Future.delayed(const Duration(milliseconds: 2800), () {
      if (mounted) context.go('/');
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // HUMG Logo
            Image.asset(
              AppAssets.appIcon,
              width: 96,
              height: 96,
              fit: BoxFit.contain,
            )
                .animate()
                .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 600.ms,
                  curve: Curves.easeOutBack,
                ),

            const SizedBox(height: AppSpacing.xl),

            // App name — "Askme" + "HUMG" (accent)
            RichText(
              text: const TextSpan(
                children: [
                  TextSpan(
                    text: 'Askme',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'HUMG',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            )
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

            // Tagline
            Text(
              l10n.splashTagline,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary,
                letterSpacing: 0.2,
              ),
            )
                .animate()
                .fadeIn(delay: 700.ms, duration: 500.ms),

            const SizedBox(height: 64),

            // Loading dot indicator
            _PulsingDots()
                .animate()
                .fadeIn(delay: 1000.ms, duration: 400.ms),
          ],
        ),
      ),
    );
  }
}

class _PulsingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: AppColors.accent,
            shape: BoxShape.circle,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: Duration(milliseconds: i * 180), duration: 300.ms)
            .then()
            .fadeOut(duration: 300.ms)
            .then(delay: Duration(milliseconds: (2 - i) * 180));
      }),
    );
  }
}
