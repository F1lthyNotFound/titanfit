import 'dart:convert';

import 'package:flutter/services.dart';

/// Gym slug baked into APK at download time or via --dart-define=GYM_SLUG=.
class GymSlugReader {
  GymSlugReader._();

  static const String fromDefine = String.fromEnvironment('GYM_SLUG', defaultValue: '');

  static Future<String?> bundledSlug() async {
    final defined = fromDefine.trim().toLowerCase();
    if (defined.isNotEmpty) return defined;
    try {
      final raw = await rootBundle.loadString('assets/gym_slug.json');
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final g = (map['gym'] ?? '').toString().trim().toLowerCase();
      if (g.isNotEmpty) return g;
    } catch (_) {
      // Asset missing until flavored build
    }
    return null;
  }

  /// Cold-start deep link from Android intent (titanfit://gym/{slug}).
  static Future<String?> bundledSlugFromPlatform() async {
    try {
      final uriStr = await const MethodChannel('titanfit/link')
          .invokeMethod<String>('getInitialUri');
      return slugFromUri(uriStr != null ? Uri.tryParse(uriStr) : null);
    } catch (_) {
      return null;
    }
  }

  /// titanfit://gym/{slug} or titanfit://gym?gym={slug}
  static String? slugFromUri(Uri? uri) {
    if (uri == null) return null;
    if (uri.scheme != 'titanfit' || uri.host != 'gym') return null;
    final path = uri.path.replaceFirst(RegExp(r'^/'), '').trim().toLowerCase();
    if (path.isNotEmpty) return path;
    final q = uri.queryParameters['gym']?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) return q;
    return null;
  }
}
