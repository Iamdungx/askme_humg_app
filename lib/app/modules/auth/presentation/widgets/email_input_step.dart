import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:askme_humg/app/core/error/failures.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';
import 'package:askme_humg/app/modules/auth/presentation/auth_providers.dart';
import 'package:askme_humg/l10n/app_localizations.dart';

class EmailInputStep extends ConsumerStatefulWidget {
  const EmailInputStep({
    super.key,
    required this.uid,
    required this.onOtpSent,
    required this.onSkip,
  });

  final String uid;
  final void Function(String email) onOtpSent;
  final VoidCallback onSkip;

  @override
  ConsumerState<EmailInputStep> createState() => _EmailInputStepState();
}

class _EmailInputStepState extends ConsumerState<EmailInputStep> {
  final _controller = TextEditingController();
  String? _inlineError;
  String _selectedDomain = '@student.humg.edu.vn';

  static const _domains = ['@student.humg.edu.vn', '@teacher.humg.edu.vn', '@humg.edu.vn'];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static final _mssvRegex = RegExp(r'^\d+$');

  String get _fullEmail => '${_controller.text.trim()}$_selectedDomain';

  bool _validate(String mssv, AppLocalizations l10n) {
    if (mssv.isEmpty || !_mssvRegex.hasMatch(mssv)) {
      setState(() => _inlineError = l10n.otpErrorInvalidMssv);
      return false;
    }
    setState(() => _inlineError = null);
    return true;
  }

  Future<void> _send(AppLocalizations l10n) async {
    final mssv = _controller.text.trim();
    if (!_validate(mssv, l10n)) return;
    final email = _fullEmail;

    final recipientName = ref.read(authStateProvider).asData?.value?.displayName;

    await ref
        .read(generateOtpProvider.notifier)
        .send(email: email, uid: widget.uid, recipientName: recipientName);

    if (!mounted) return;
    final state = ref.read(generateOtpProvider);
    state.whenOrNull(
      data: (_) => widget.onOtpSent(email),
      error: (err, _) {
        final msg = switch (err) {
          OtpSendFailure() => l10n.otpErrorNetwork,
          FirestoreFailure() => l10n.otpErrorNetwork,
          _ => l10n.otpErrorNetwork,
        };
        setState(() => _inlineError = msg);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isLoading = ref.watch(generateOtpProvider).isLoading;

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
                color: cs.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.mail,
                size: 36,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Title
          Text(
            l10n.verifyHumgTitle,
            style: tt.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.sm),

          // Subtitle
          Text(
            l10n.verifyHumgSubtitle,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.xxl),

          // MSSV + domain trong một field duy nhất
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.done,
            autocorrect: false,
            onSubmitted: (_) => _send(l10n),
            onChanged: (_) {
              if (_inlineError != null) setState(() => _inlineError = null);
            },
            style: tt.bodyLarge?.copyWith(color: cs.onSurface),
            decoration: InputDecoration(
              hintText: 'mssv',
              hintStyle: tt.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: 0.5),
              ),
              errorText: _inlineError,
              prefixIcon: const Icon(LucideIcons.hash, size: 20),
              // Domain toggle button bên phải
              suffixIcon: GestureDetector(
                onTap: () => setState(() {
                  _selectedDomain = _selectedDomain == _domains[0]
                      ? _domains[1]
                      : _domains[0];
                }),
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 6, 8, 6),
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: cs.secondaryContainer,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _selectedDomain,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSecondaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        LucideIcons.chevronsUpDown,
                        size: 12,
                        color: cs.onSecondaryContainer,
                      ),
                    ],
                  ),
                ),
              ),
              filled: true,
              fillColor: cs.surfaceContainerHigh,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: cs.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: cs.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: cs.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: cs.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                borderSide: BorderSide(color: cs.error, width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.xl),

          // Send OTP button
          FilledButton(
            onPressed: isLoading ? null : () => _send(l10n),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.verifyHumgSendOtp),
          ),

          const SizedBox(height: AppSpacing.md),

          // Skip button
          TextButton(
            onPressed: widget.onSkip,
            child: Text(
              l10n.verifyHumgSkip,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
