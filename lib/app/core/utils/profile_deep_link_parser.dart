/// Parses UC-2.1 profile deep-link payloads (HTTPS or [askme] scheme) into a
/// GoRouter path `/user/{userId}`. Returns null if [raw] is not a profile link.
String? parseProfileDeepLinkToPath(String raw) {
  final uri = Uri.tryParse(raw.trim());
  if (uri == null) return null;

  if (uri.scheme == 'askme') {
    if (uri.host == 'user' && uri.pathSegments.isNotEmpty) {
      final id = uri.pathSegments.first;
      if (id.isEmpty) return null;
      return '/user/$id';
    }
    return null;
  }

  if (uri.scheme == 'https' || uri.scheme == 'http') {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length >= 2 && segments[0] == 'user') {
      return '/user/${segments[1]}';
    }
    return null;
  }

  return null;
}
