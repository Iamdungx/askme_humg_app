import 'package:flutter/material.dart';
import 'package:askme_humg/app/core/values/app_spacing.dart';

/// Compact pill-shaped text input for comment entry.
/// Typically used in a [Row] alongside a send [IconButton].
class AppCommentInput extends StatelessWidget {
  const AppCommentInput({
    super.key,
    required this.controller,
    this.hintText,
    this.errorText,
    this.maxLines = 4,
    this.maxLength,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;
  final String? hintText;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: 1,
      maxLines: maxLines,
      maxLength: maxLength,
      autofocus: autofocus,
      textInputAction: TextInputAction.done,
      onChanged: onChanged,
      onSubmitted: onSubmitted ?? (_) => FocusScope.of(context).unfocus(),
      decoration: InputDecoration(
        hintText: hintText,
        errorText: errorText,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
    );
  }
}
