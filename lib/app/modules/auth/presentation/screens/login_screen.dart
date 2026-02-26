import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/core/values/app_assets.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/global_widgets/app_button.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final isLoading = authState.isLoading;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    // Show error snackbar on failure
    ref.listen(authNotifierProvider, (_, next) {
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            _buildErrorSnackBar(context, err.toString(), cs),
          );
        },
      );
    });

    return Scaffold(
      backgroundColor: cs.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(flex: 2),
              // Brand header
              _BrandHeader(tt: tt, cs: cs)
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: -0.15, end: 0, curve: Curves.easeOut),
              const Spacer(flex: 2),
              // Auth actions
              _AuthActions(
                isLoading: isLoading,
                signInLabel: isLoading
                    ? l10n.commonLoading
                    : l10n.authSignInWithGoogle,
                guestLabel: l10n.authContinueAsGuest,
                onGoogleSignIn: () =>
                    ref.read(authNotifierProvider.notifier).signIn(),
                onContinueAsGuest: () => context.go('/'),
              )
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 200.ms)
                  .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
              const SizedBox(height: AppSpacing.xl),
              // Security notice
              _SecurityNotice(cs: cs)
                  .animate()
                  .fadeIn(duration: 600.ms, delay: 350.ms),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  SnackBar _buildErrorSnackBar(
    BuildContext context,
    String message,
    ColorScheme cs,
  ) {
    return SnackBar(
      backgroundColor: cs.error,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      content: Row(
        children: [
          Icon(Icons.error_rounded, color: cs.onError, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: cs.onError,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      action: SnackBarAction(
        label: '✕',
        textColor: cs.onError,
        onPressed: () =>
            ScaffoldMessenger.of(context).hideCurrentSnackBar(),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Brand Header — logo + wordmark + tagline
// ---------------------------------------------------------------------------

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.tt, required this.cs});

  final TextTheme tt;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: cs.secondary.withValues(alpha: 0.4),
              width: 2,
            ),
            color: cs.surfaceContainerHigh,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            AppAssets.appIcon,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(
                'A',
                style: tt.displaySmall?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl),

        // Wordmark: Askme HUMG
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Askme',
                style: tt.headlineMedium?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
              TextSpan(
                text: 'HUMG',
                style: tt.headlineMedium?.copyWith(
                  color: cs.secondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Tagline
        Builder(
          builder: (ctx) => Text(
            AppLocalizations.of(ctx).authSubtitle,
            textAlign: TextAlign.center,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Auth Actions — sign-in button + guest link
// ---------------------------------------------------------------------------

class _AuthActions extends StatelessWidget {
  const _AuthActions({
    required this.isLoading,
    required this.signInLabel,
    required this.guestLabel,
    required this.onGoogleSignIn,
    required this.onContinueAsGuest,
  });

  final bool isLoading;
  final String signInLabel;
  final String guestLabel;
  final VoidCallback onGoogleSignIn;
  final VoidCallback onContinueAsGuest;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      children: [
        // Google Sign-In
        AppButton(
          label: signInLabel,
          onPressed: onGoogleSignIn,
          variant: AppButtonVariant.google,
          isLoading: isLoading,
          minimumHeight: 56,
        ),

        const SizedBox(height: AppSpacing.xl),

        // Guest access
        Semantics(
          button: true,
          label: guestLabel,
          child: GestureDetector(
            onTap: isLoading ? null : onContinueAsGuest,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    guestLabel,
                    style: tt.bodyMedium?.copyWith(
                      color: isLoading
                          ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                          : cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: isLoading
                        ? cs.onSurfaceVariant.withValues(alpha: 0.4)
                        : cs.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Security Notice — footer
// ---------------------------------------------------------------------------

class _SecurityNotice extends StatelessWidget {
  const _SecurityNotice({required this.cs});

  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          children: [
            TextSpan(
              text: '🔒 ',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            TextSpan(
              text: l10n.authDomainNotice,
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
