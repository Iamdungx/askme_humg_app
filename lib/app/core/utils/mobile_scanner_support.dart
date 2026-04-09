import 'package:flutter/foundation.dart';

/// Whether [mobile_scanner] has a native/web implementation on this platform.
/// (Linux/Windows are unsupported — see package README.)
///
/// **MissingPluginException on Android/iOS** after adding the dependency usually
/// means the app was hot-reloaded; do a full stop, `flutter clean`, then rebuild.
bool get isMobileScannerPlatformSupported {
  if (kIsWeb) return true;
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;
}
