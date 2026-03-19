import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class OtpInputStep extends ConsumerStatefulWidget {
  const OtpInputStep({
    super.key,
    required this.email,
    required this.uid,
    required this.onVerified,
    required this.onResend,
  });

  final String email;
  final String uid;
  final VoidCallback onVerified;
  final VoidCallback onResend;

  @override
  ConsumerState<OtpInputStep> createState() => _OtpInputStepState();
}

class _OtpInputStepState extends ConsumerState<OtpInputStep> {
  static const _otpLength = 6;
  static const _countdownSeconds = 60;

  final _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final _focusNodes = List.generate(_otpLength, (_) => FocusNode());

  String? _error;
  int _countdown = _countdownSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNodes[0].requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _countdown = _countdownSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        if (_countdown > 0) {
          _countdown--;
        } else {
          t.cancel();
        }
      });
    });
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  bool get _isComplete => _currentOtp.length == _otpLength;

  void _onDigitChanged(int index, String value) {
    if (_error != null) setState(() => _error = null);

    if (value.length == 1 && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    // Auto-submit when last digit entered
    if (index == _otpLength - 1 && value.length == 1) {
      setState(() {});
    } else {
      setState(() {});
    }
  }

  Future<void> _confirm(AppLocalizations l10n) async {
    final otp = _currentOtp;
    if (otp.length < _otpLength) return;

    await ref
        .read(verifyOtpProvider.notifier)
        .verify(otp: otp, uid: widget.uid);

    if (!mounted) return;
    final state = ref.read(verifyOtpProvider);
    state.whenOrNull(
      data: (_) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.verifyHumgSuccess)));
        widget.onVerified();
      },
      error: (err, _) {
        final msg = switch (err) {
          OtpExpiredFailure() => l10n.otpErrorExpired,
          OtpInvalidFailure() => l10n.otpErrorInvalid,
          OtpMaxAttemptsFailure() => l10n.otpErrorMaxAttempts,
          _ => l10n.otpErrorNetwork,
        };
        setState(() => _error = msg);
        // Clear boxes on error
        for (final c in _controllers) {
          c.clear();
        }
        _focusNodes[0].requestFocus();
      },
    );
  }

  void _handleResend() {
    for (final c in _controllers) {
      c.clear();
    }
    setState(() => _error = null);
    _focusNodes[0].requestFocus();
    _startCountdown();
    widget.onResend();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = ref.watch(verifyOtpProvider).isLoading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: AppSpacing.xxl),

          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.keyRound,
                size: 36,
                color: cs.onSecondaryContainer,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            l10n.verifyHumgOtpTitle,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Subtitle with email
          Text(
            l10n.verifyHumgOtpSubtitle(widget.email),
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // 6-digit OTP boxes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_otpLength, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _OtpDigitBox(
                  controller: _controllers[i],
                  focusNode: _focusNodes[i],
                  hasError: _error != null,
                  onChanged: (v) => _onDigitChanged(i, v),
                  onBackspace: () {
                    if (_controllers[i].text.isEmpty && i > 0) {
                      _controllers[i - 1].clear();
                      _focusNodes[i - 1].requestFocus();
                    }
                  },
                ),
              );
            }),
          ),

          // Error text
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.circleAlert, size: 14, color: cs.error),
                const SizedBox(width: 4),
                Text(_error!, style: tt.bodySmall?.copyWith(color: cs.error)),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xl),

          // Confirm button
          FilledButton(
            onPressed: (isLoading || !_isComplete)
                ? null
                : () => _confirm(l10n),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.verifyHumgConfirm),
          ),

          const SizedBox(height: AppSpacing.md),

          // Resend button with countdown
          Center(
            child: _countdown > 0
                ? Text(
                    l10n.verifyHumgResendIn(_countdown),
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  )
                : TextButton(
                    onPressed: _handleResend,
                    child: Text(l10n.verifyHumgResend),
                  ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single OTP digit box
// ---------------------------------------------------------------------------

class _OtpDigitBox extends StatelessWidget {
  const _OtpDigitBox({
    required this.controller,
    required this.focusNode,
    required this.hasError,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool hasError;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              controller.text.isEmpty) {
            onBackspace();
          }
        },
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: onChanged,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: hasError ? cs.error : cs.outline,
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(
                color: hasError ? cs.error : cs.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: cs.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              borderSide: BorderSide(color: cs.error, width: 2),
            ),
            filled: true,
            fillColor: hasError
                ? cs.errorContainer.withValues(alpha: 0.15)
                : cs.surfaceContainerHighest.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}
