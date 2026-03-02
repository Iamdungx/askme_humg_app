import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Decodes a base64 data URI (e.g. `data:image/jpeg;base64,...`) to raw bytes.
/// Returns null if [url] is not a valid data URI or decoding fails.
Uint8List? tryDecodeBase64Avatar(String? url) {
  if (url == null || !url.startsWith('data:image')) return null;
  try {
    final commaIndex = url.indexOf(',');
    if (commaIndex == -1) return null;
    return base64Decode(url.substring(commaIndex + 1));
  } catch (_) {
    return null;
  }
}

/// Returns true if [url] is a base64 data URI image.
bool isBase64DataUri(String? url) =>
    url != null && url.startsWith('data:image');
