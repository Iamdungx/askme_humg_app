import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:askme_humg/app/core/utils/logger.dart';

/// Handles reading and clearing the OS temporary directory used as app cache.
class CacheService {
  const CacheService();

  static const String loadingPlaceholder = '...';
  static const String errorPlaceholder = '-- MB';

  /// Returns the total size (bytes) of all files in the temp directory.
  Future<int> getCacheSize() async {
    try {
      final dir = await getTemporaryDirectory();
      return _measureDir(dir);
    } catch (e, s) {
      logger.w(
        'CacheService: failed to measure cache',
        error: e,
        stackTrace: s,
      );
      return 0;
    }
  }

  /// Deletes every file and sub-directory inside the temp directory.
  /// Returns the number of bytes freed.
  Future<int> clearCache() async {
    try {
      final dir = await getTemporaryDirectory();
      final freed = _measureDir(dir);
      for (final entity in dir.listSync()) {
        try {
          if (entity is File) {
            entity.deleteSync();
          } else if (entity is Directory) {
            entity.deleteSync(recursive: true);
          }
        } catch (e, s) {
          logger.w(
            'CacheService: could not delete ${entity.path}',
            error: e,
            stackTrace: s,
          );
        }
      }
      return freed;
    } catch (e, s) {
      logger.e('CacheService: clearCache failed', error: e, stackTrace: s);
      return 0;
    }
  }

  /// Formats a byte count into a human-readable string: "12.4 MB", "512 KB", "800 B".
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  int _measureDir(Directory dir) {
    int total = 0;
    try {
      for (final entity in dir.listSync(recursive: true)) {
        if (entity is File) total += entity.lengthSync();
      }
    } catch (_) {}
    return total;
  }
}
