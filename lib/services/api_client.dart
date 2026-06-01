import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Titan Labs mobile API client — always HTTPS, POST-safe redirects, cookie session.
class ApiClient {
  ApiClient({required String baseUrl, this.cookieHeader = ''})
      : baseUrl = _normalizeBaseUrl(baseUrl);

  final String baseUrl;
  String cookieHeader;

  static const int _maxRedirects = 5;
  static const String _mobileApiPath = '/api/controllers/app.php';

  /// Single mobile auth/profile endpoint (avoids auth.php redirect issues).
  static String get mobileApiPath => _mobileApiPath;

  static String _normalizeBaseUrl(String url) {
    var u = url.trim().replaceAll(RegExp(r'/+$'), '');
    if (u.isEmpty) return u;

    // Bare hostname (no scheme) — common in stale flavor cache.
    if (!u.contains('://')) {
      final hostPart = u.split('/').first;
      if (RegExp(r'^[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}').hasMatch(hostPart)) {
        u = 'https://$u';
      }
    }

    final uri = Uri.tryParse(u);
    if (uri == null || uri.host.isEmpty) return u;
    var scheme = uri.scheme;
    if (scheme == 'http' || scheme.isEmpty) {
      scheme = 'https';
    }
    final port = (scheme == 'https' && uri.port == 443) ||
            (scheme == 'http' && uri.port == 80)
        ? null
        : (uri.hasPort ? uri.port : null);
    return Uri(scheme: scheme, host: uri.host, port: port).origin;
  }

  /// Canonical HTTPS API endpoint for mobile auth.
  Uri get mobileApiUri => _uri(ApiClient.mobileApiPath);

  Uri _uri(String path, [Map<String, String>? query]) {
    final root = Uri.parse(baseUrl);
    if (root.host.isEmpty) {
      throw StateError('Invalid API base URL: $baseUrl');
    }
    final p = path.startsWith('/') ? path : '/$path';
    return Uri(
      scheme: 'https',
      host: root.host,
      port: root.hasPort && root.port != 443 ? root.port : null,
      path: p,
      queryParameters: query,
    );
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

  void _captureCookies(http.Response response) {
    final merged = <String, String>{};
    if (cookieHeader.isNotEmpty) {
      for (final pair in cookieHeader.split(';')) {
        final kv = pair.trim().split('=');
        if (kv.length >= 2) merged[kv[0]] = kv.sublist(1).join('=');
      }
    }

    // http package lowercases header keys; some servers emit multiple Set-Cookie lines.
    for (final entry in response.headers.entries) {
      if (entry.key.toLowerCase() != 'set-cookie') continue;
      for (final chunk in _splitSetCookie(entry.value)) {
        final part = chunk.split(';').first.trim();
        final eq = part.indexOf('=');
        if (eq > 0) {
          merged[part.substring(0, eq).trim()] = part.substring(eq + 1);
        }
      }
    }

    if (merged.isEmpty) return;
    cookieHeader = merged.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  List<String> _splitSetCookie(String raw) {
    final out = <String>[];
    var start = 0;
    for (var i = 0; i < raw.length; i++) {
      if (raw[i] == ',' && i + 1 < raw.length) {
        final next = raw[i + 1];
        if (next == ' ' && i + 2 < raw.length) {
          final after = raw[i + 2];
          if (RegExp(r'[A-Za-z]').hasMatch(after)) {
            out.add(raw.substring(start, i).trim());
            start = i + 1;
          }
        }
      }
    }
    out.add(raw.substring(start).trim());
    return out;
  }

  bool _isRedirect(int code) =>
      code == 301 || code == 302 || code == 303 || code == 307 || code == 308;

  Uri? _redirectUri(http.Response res, Uri current) {
    final loc = res.headers['location'] ?? res.headers['Location'];
    if (loc == null || loc.isEmpty) return null;
    return loc.startsWith('http') ? Uri.parse(loc) : current.resolve(loc);
  }

  Future<http.Response> _requestWithRedirects(
    Future<http.Response> Function(Uri uri) send,
    Uri startUri,
  ) async {
    var uri = _uriFromNormalized(startUri);
    http.Response? last;
    for (var i = 0; i <= _maxRedirects; i++) {
      last = await send(uri);
      _captureCookies(last);
      if (!_isRedirect(last.statusCode) || i >= _maxRedirects) {
        return last;
      }
      final next = _redirectUri(last, uri);
      if (next == null) return last;
      uri = _uriFromNormalized(next);
    }
    return last!;
  }

  Uri _uriFromNormalized(Uri uri) {
    final normalized = _normalizeBaseUrl(uri.origin);
    if (normalized.isEmpty) return uri;
    final root = Uri.parse(normalized);
    return Uri(
      scheme: 'https',
      host: root.host,
      port: root.hasPort && root.port != 443 ? root.port : null,
      path: uri.path,
      query: uri.hasQuery ? uri.query : null,
    );
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await _requestWithRedirects(
      (uri) => http.get(uri, headers: _headers),
      _uri(path, query),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> postForm(
    String path,
    Map<String, String> fields,
  ) async {
    final headers = {
      ..._headers,
      'Content-Type': 'application/x-www-form-urlencoded',
    };
    final body = fields.entries
        .map((e) =>
            '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');

    final res = await _requestWithRedirects(
      (uri) => http.post(uri, headers: headers, body: body),
      _uri(path),
    );
    return _decode(res);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    Map<String, List<int>>? files,
    String fileField = 'avatar',
    String fileName = 'avatar.jpg',
  }) async {
    Future<http.Response> send(Uri uri) async {
      final req = http.MultipartRequest('POST', uri);
      req.headers['Accept'] = 'application/json';
      if (cookieHeader.isNotEmpty) {
        req.headers['Cookie'] = cookieHeader;
      }
      req.fields.addAll(fields);
      if (files != null) {
        for (final e in files.entries) {
          req.files.add(http.MultipartFile.fromBytes(
            e.key,
            e.value,
            filename: fileName,
            contentType: MediaType('image', 'jpeg'),
          ));
        }
      }
      final streamed = await req.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _requestWithRedirects(send, _uri(path));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    if (_isRedirect(res.statusCode)) {
      return {
        'success': false,
        'message':
            'Server redirect (${res.statusCode}). Clear app data or reinstall from gym download link.',
      };
    }
    final trimmed = res.body.trim();
    if (trimmed.isEmpty) {
      return {
        'success': false,
        'message': 'Empty response (${res.statusCode})',
      };
    }
    if (trimmed.startsWith('<')) {
      return {
        'success': false,
        'message': 'Server returned HTML (${res.statusCode}), not JSON',
      };
    }
    try {
      final body = jsonDecode(res.body);
      if (body is Map<String, dynamic>) return body;
      return {'success': false, 'message': 'Invalid response'};
    } catch (_) {
      return {
        'success': false,
        'message': 'Network error (${res.statusCode})',
      };
    }
  }
}
