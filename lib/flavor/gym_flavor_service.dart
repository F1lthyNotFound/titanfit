import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import 'gym_flavor.dart';

class GymFlavorService extends ChangeNotifier {
  GymFlavorService._();
  static final GymFlavorService instance = GymFlavorService._();

  static const _keyFlavor = 'titanfit_gym_flavor';
  static const _keyLoggedIn = 'titanfit_logged_in';

  GymFlavor? _flavor;
  bool _loggedIn = false;
  bool _loading = false;

  GymFlavor? get flavor => _flavor;
  bool get hasFlavor => _flavor != null && _flavor!.isValid;
  bool get isLoggedIn => _loggedIn;
  bool get isLoading => _loading;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    final raw = prefs.getString(_keyFlavor);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _flavor = GymFlavor.fromJson(map, map['gym_slug']?.toString() ?? '');
      } catch (_) {
        _flavor = null;
      }
    }
    notifyListeners();
  }

  Future<GymFlavor?> resolveFlavor(String gymSlug) async {
    _loading = true;
    notifyListeners();
    try {
      final slug = gymSlug.trim().toLowerCase();
      if (slug.isEmpty) return null;
      final client = ApiClient(baseUrl: ApiConfig.defaultApiBase);
      final res = await client.get(
        '/api/controllers/app.php',
        query: {'action': 'get_flavor', 'gym': slug},
      );
      if (res['success'] != true) return null;
      final flavor = GymFlavor.fromJson(res, slug);
      if (!flavor.isValid) return null;
      await _persistFlavor(flavor);
      return flavor;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _persistFlavor(GymFlavor flavor) async {
    _flavor = flavor;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFlavor, jsonEncode(flavor.toJson()));
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value) async {
    _loggedIn = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, value);
    notifyListeners();
  }

  Future<void> clearFlavor() async {
    _flavor = null;
    _loggedIn = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFlavor);
    await prefs.remove(_keyLoggedIn);
    notifyListeners();
  }
}
