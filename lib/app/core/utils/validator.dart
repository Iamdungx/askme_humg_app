typedef FieldError = String?;
typedef FieldValidator<T> = FieldError Function(T? value);

class Validators {
  const Validators._();

  static FieldValidator<String> nonEmpty({
    String message = 'This field is required',
  }) {
    return (value) {
      if (value == null || value.trim().isEmpty) return message;
      return null;
    };
  }

  static FieldValidator<String> minLength(int length, {String? message}) {
    return (value) {
      if (value == null || value.length < length) {
        return message ?? 'Minimum $length characters';
      }
      return null;
    };
  }

  static FieldValidator<String> maxLength(int length, {String? message}) {
    return (value) {
      if ((value ?? '').length > length) {
        return message ?? 'Maximum $length characters';
      }
      return null;
    };
  }

  static final RegExp _emailRegex = RegExp(r'^\S+@\S+\.\S+$');
  static FieldValidator<String> email({String message = 'Invalid email'}) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return null; // allow empty; chain with nonEmpty to enforce
      if (!_emailRegex.hasMatch(v)) return message;
      return null;
    };
  }

  // Very loose international phone check; customize per region if needed
  static final RegExp _phoneRegex = RegExp(r'^[0-9+().\-\s]{7,}$');
  static FieldValidator<String> phone({
    String message = 'Invalid phone number',
  }) {
    return (value) {
      final v = value?.trim() ?? '';
      if (v.isEmpty) return null; // allow empty
      if (!_phoneRegex.hasMatch(v)) return message;
      return null;
    };
  }

  static FieldValidator<String> match(
    String other, {
    String message = 'Values do not match',
  }) {
    return (value) => value == other ? null : message;
  }

  static FieldValidator<T> custom<T>(
    bool Function(T? value) test, {
    String message = 'Invalid value',
  }) {
    return (value) => test(value) ? null : message;
  }

  static FieldValidator<T> combine<T>(List<FieldValidator<T>> validators) {
    return (value) {
      for (final v in validators) {
        final err = v(value);
        if (err != null) return err;
      }
      return null;
    };
  }

  /// UC-3.1 — Validates question content before submitting.
  /// Returns null if valid, [QuestionValidationError] code if invalid.
  /// Caller is responsible for mapping the code to a localized string.
  static QuestionValidationError? validateQuestion(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) return QuestionValidationError.empty;
    if (content.length > 300) return QuestionValidationError.tooLong;
    if (_containsProfanity(trimmed)) return QuestionValidationError.inappropriate;
    return null;
  }

  static bool _containsProfanity(String text) {
    const blocked = [
      'fuck',
      'shit',
      'bitch',
      'asshole',
      'dick',
      'pussy',
      'cunt',
    ];
    final lower = text.toLowerCase();
    return blocked.any((word) => lower.contains(word));
  }
}

enum QuestionValidationError { empty, tooLong, inappropriate }
