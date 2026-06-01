/// Mobile session cookie helpers — PHP returns session_token in JSON when Set-Cookie is lost.
class SessionCookies {
  SessionCookies._();

  static const sessionName = 'titan_session';

  static String? tokenFromResponse(Map<String, dynamic> res) {
    final top = (res['session_token'] ?? '').toString().trim();
    if (top.isNotEmpty) return top;
    final data = res['data'];
    if (data is Map<String, dynamic>) {
      final nested = (data['session_token'] ?? '').toString().trim();
      if (nested.isNotEmpty) return nested;
    }
    return null;
  }

  static String upsert(String header, String name, String value) {
    final merged = <String, String>{};
    if (header.isNotEmpty) {
      for (final pair in header.split(';')) {
        final kv = pair.trim().split('=');
        if (kv.length >= 2) merged[kv[0].trim()] = kv.sublist(1).join('=');
      }
    }
    merged[name] = value;
    return merged.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  static void applyToClient(String cookieHeader, void Function(String) setHeader) {
    if (cookieHeader.isNotEmpty) setHeader(cookieHeader);
  }
}
