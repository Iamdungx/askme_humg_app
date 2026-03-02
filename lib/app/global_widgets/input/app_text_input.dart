import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// Multi-line filled text input with 3-state border and optional character
/// counter overlay. Used for question submission and answer composition.
class AppTextInput extends StatelessWidget {
  const AppTextInput({
    super.key,
    required this.controller,
    this.hintText,
    this.errorText,
    this.maxLines = 4,
    this.minLines,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.textInputAction = TextInputAction.done,
    this.keyboardType,
    this.focusedBorderColor,
    this.autofocus = false,
    this.prefixIcon,
    this.suffixText,
    this.autocorrect = true,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputAction textInputAction;
  final TextInputType? keyboardType;

  /// Defaults to `colorScheme.primary` if not provided.
  final Color? focusedBorderColor;
  final bool autofocus;

  /// Optional leading icon inside the field.
  final Widget? prefixIcon;

  /// Optional fixed text shown at the trailing end (e.g. "@humg.edu.vn").
  final String? suffixText;

  final bool autocorrect;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final focusColor = focusedBorderColor ?? cs.primary;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: minLines,
      maxLength: maxLength,
      autofocus: autofocus,
      textInputAction: textInputAction,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onChanged: onChanged,
      onSubmitted: onSubmitted ?? (_) => FocusScope.of(context).unfocus(),
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          const SizedBox.shrink(),
      style: tt.bodyLarge?.copyWith(color: cs.onSurface),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: tt.bodyLarge?.copyWith(
          color: cs.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        errorText: errorText,
        prefixIcon: prefixIcon,
        suffixText: suffixText,
        suffixStyle: tt.bodyLarge?.copyWith(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: cs.surfaceContainerHigh,
        contentPadding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          maxLength != null ? AppSpacing.xxl : AppSpacing.lg,
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
          borderSide: BorderSide(color: focusColor, width: 1.5),
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
    );
  }
}

/// [AppTextInput] wrapped in a [Stack] with a character counter overlay
/// positioned at the bottom-right corner.
class AppTextInputWithCounter extends StatelessWidget {
  const AppTextInputWithCounter({
    super.key,
    required this.controller,
    required this.charCount,
    required this.maxLength,
    this.hintText,
    this.errorText,
    this.maxLines = 4,
    this.minLines,
    this.onChanged,
    this.textInputAction = TextInputAction.done,
    this.focusedBorderColor,
    this.counterLabel,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final int charCount;
  final int maxLength;
  final String? hintText;
  final String? errorText;
  final int? maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;
  final Color? focusedBorderColor;

  /// Text shown as counter. Defaults to "$charCount / $maxLength".
  final String? counterLabel;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isOverLimit = charCount > maxLength;
    final label = counterLabel ?? '$charCount / $maxLength';

    return Stack(
      children: [
        AppTextInput(
          controller: controller,
          hintText: hintText,
          errorText: errorText,
          maxLines: maxLines,
          minLines: minLines,
          maxLength: maxLength,
          onChanged: onChanged,
          textInputAction: textInputAction,
          focusedBorderColor: focusedBorderColor,
          autofocus: autofocus,
        ),
        Positioned(
          bottom: AppSpacing.sm,
          right: AppSpacing.lg,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: isOverLimit ? cs.error : cs.onSurfaceVariant,
              fontWeight: isOverLimit ? FontWeight.bold : null,
            ),
          ),
        ),
      ],
    );
  }
}
