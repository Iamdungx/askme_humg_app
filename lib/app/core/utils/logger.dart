import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Global logger instance. Use instead of `print()` everywhere.
///
/// Usage:
///   logger.d('debug message');
///   logger.i('info message');
///   logger.w('warning message');
///   logger.e('error message', error: e, stackTrace: s);
final logger = Logger(
  printer: PrettyPrinter(
    methodCount: 1,
    errorMethodCount: 5,
    lineLength: 80,
    colors: true,
    printEmojis: true,
    dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
  ),
  level: kReleaseMode ? Level.warning : Level.debug,
);
