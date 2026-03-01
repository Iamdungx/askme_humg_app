/// UC-1.3 — HUMG Email Verification Screen
///
/// Two steps on one screen (no PageView):
///   Step 1 — EmailInputStep: user enters @humg.edu.vn email → OTP sent
///   Step 2 — OtpInputStep:  user enters 6-digit code → account verified
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/app/modules/auth/presentation/widgets/email_input_step.dart';
import 'package:askme_humg/app/modules/auth/presentation/widgets/otp_input_step.dart';
import 'package:askme_humg/config/app_routes.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

enum _VerifyStep { email, otp }

class VerifyHumgScreen extends ConsumerStatefulWidget {
  const VerifyHumgScreen({super.key});

  @override
  ConsumerState<VerifyHumgScreen> createState() => _VerifyHumgScreenState();
}

class _VerifyHumgScreenState extends ConsumerState<VerifyHumgScreen> {
  _VerifyStep _step = _VerifyStep.email;
  String _sentEmail = '';

  void _onOtpSent(String email) {
    setState(() {
      _sentEmail = email;
      _step = _VerifyStep.otp;
    });
  }

  void _onVerified() {
    if (!mounted) return;
    context.go(AppRoutes.feed);
  }

  void _onSkip() {
    context.go(AppRoutes.feed);
  }

  void _onResend() {
    final user = ref.read(authStateProvider).asData?.value;
    ref.read(generateOtpProvider.notifier).send(
      email: _sentEmail,
      uid: user?.uid ?? '',
      recipientName: user?.displayName,
    );
  }

  void _onBack() {
    if (_step == _VerifyStep.otp) {
      setState(() => _step = _VerifyStep.email);
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final uid = ref.watch(authStateProvider).asData?.value?.uid ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.verifyHumgTitle),
        leading: BackButton(onPressed: _onBack),
        // Remove elevation / border to keep clean look
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.05, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: _step == _VerifyStep.email
                ? EmailInputStep(
                    key: const ValueKey(_VerifyStep.email),
                    uid: uid,
                    onOtpSent: _onOtpSent,
                    onSkip: _onSkip,
                  )
                : OtpInputStep(
                    key: const ValueKey(_VerifyStep.otp),
                    email: _sentEmail,
                    uid: uid,
                    onVerified: _onVerified,
                    onResend: _onResend,
                  ),
          ),
        ),
      ),
    );
  }
}
