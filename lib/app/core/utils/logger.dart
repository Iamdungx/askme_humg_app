import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:askme_humg/config/env_reader.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  const AppLogger._();

  static bool get _enabled => EnvReader.isDebug || EnvReader.isStg;

  // ANSI colors (may not render in some IDE logcats)
  static const _reset = '\x1B[0m';
  static const _grey = '\x1B[90m';
  static const _blue = '\x1B[34m';
  static const _yellow = '\x1B[33m';
  static const _red = '\x1B[31m';

  static void _print(
    LogLevel level,
    Object? message, {
    String? tag,
    StackTrace? stackTrace,
  }) {
    if (!_enabled) return;
    final String prefix = switch (level) {
      LogLevel.debug => '$_grey[DEBUG]$_reset',
      LogLevel.info => '$_blue[INFO ]$_reset',
      LogLevel.warn => '$_yellow[WARN ]$_reset',
      LogLevel.error => '$_red[ERROR]$_reset',
    };
    final String tagStr = tag == null ? '' : '[$tag]';
    final String msg = message?.toString() ?? '';
    debugPrint('$prefix$tagStr $msg');
    if (stackTrace != null && level == LogLevel.error) {
      debugPrint(stackTrace.toString());
    }
  }

  static void d(Object? message, {String? tag}) =>
      _print(LogLevel.debug, message, tag: tag);
  static void i(Object? message, {String? tag}) =>
      _print(LogLevel.info, message, tag: tag);
  static void w(Object? message, {String? tag}) =>
      _print(LogLevel.warn, message, tag: tag);
  static void e(Object? message, {String? tag, StackTrace? stackTrace}) =>
      _print(LogLevel.error, message, tag: tag, stackTrace: stackTrace);

  static void json(Object? data, {String? tag}) {
    if (!_enabled) return;
    try {
      final encoder = const JsonEncoder.withIndent('  ');
      final formatted = encoder.convert(data);
      d(formatted, tag: tag ?? 'JSON');
    } catch (_) {
      d(data, tag: tag ?? 'JSON');
    }
  }
}
