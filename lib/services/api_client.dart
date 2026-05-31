import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiClient {
  ApiClient({required this.baseUrl, this.cookieHeader = ''});

  final String baseUrl;
  String cookieHeader;

  String get _origin => baseUrl.replaceAll(RegExp(r'/+$'), '');

  Uri _uri(String path, [Map<String, String>? query]) {
    final p = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$_origin$p').replace(queryParameters: query);
  }

  Map<String, String> get _headers => {
        'Accept': 'application/json',
        if (cookieHeader.isNotEmpty) 'Cookie': cookieHeader,
      };

  void _captureCookies(http.Response response) {
    final setCookie = response.headers['set-cookie'];
    if (setCookie == null || setCookie.isEmpty) return;
    final parts = setCookie.split(',').map((s) => s.split(';').first.trim());
    final merged = <String, String>{};
    if (cookieHeader.isNotEmpty) {
      for (final pair in cookieHeader.split(';')) {
        final kv = pair.trim().split('=');
        if (kv.length >= 2) merged[kv[0]] = kv.sublist(1).join('=');
      }
    }
    for (final p in parts) {
      final kv = p.split('=');
      if (kv.length >= 2) merged[kv[0]] = kv.sublist(1).join('=');
    }
    cookieHeader = merged.entries.map((e) => '${e.key}=${e.value}').join('; ');
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? query,
  }) async {
    final res = await http.get(_uri(path, query), headers: _headers);
    _captureCookies(res);
    return _decode(res);
  }

  Future<Map<String, dynamic>> postForm(
    String path,
    Map<String, String> fields,
  ) async {
    final res = await http.post(
      _uri(path),
      headers: {
        ..._headers,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: fields,
    );
    _captureCookies(res);
    return _decode(res);
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    Map<String, String> fields, {
    Map<String, List<int>>? files,
    String fileField = 'avatar',
    String fileName = 'avatar.jpg',
  }) async {
    final req = http.MultipartRequest('POST', _uri(path));
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
    final res = await http.Response.fromStream(streamed);
    _captureCookies(res);
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
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
