import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../services/api_client.dart';
import 'gym_flavor.dart';
import 'gym_slug_reader.dart';

class GymFlavorService extends ChangeNotifier {
  GymFlavorService._();
  static final GymFlavorService instance = GymFlavorService._();

  static const _keyFlavor = 'titanfit_gym_flavor';
  static const _keyLoggedIn = 'titanfit_logged_in';
  static const _keyOnboardingDone = 'titanfit_onboarding_complete';
  static const _keyCookies = 'titanfit_session_cookies';

  GymFlavor? _flavor;
  ApiClient? _client;
  String _cookieHeader = '';
  bool _loggedIn = false;
  bool _onboardingComplete = false;
  bool _loading = false;
  String? _bootstrapError;

  GymFlavor? get flavor => _flavor;
  bool get hasFlavor => _flavor != null && _flavor!.isValid;
  bool get isLoggedIn => _loggedIn;
  bool get onboardingComplete => _onboardingComplete;
  bool get isLoading => _loading;
  String? get bootstrapError => _bootstrapError;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool(_keyOnboardingDone) ?? false;
    _loggedIn = prefs.getBool(_keyLoggedIn) ?? false;
    _cookieHeader = prefs.getString(_keyCookies) ?? '';
    final raw = prefs.getString(_keyFlavor);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        final rawBase = (map['api_base'] ?? '').toString();
        final flavor = GymFlavor.fromJson(map, map['gym_slug']?.toString() ?? '');
        _flavor = flavor;
        if (rawBase.startsWith('http://') || rawBase != flavor.apiBase) {
          await _persistFlavor(flavor);
        }
      } catch (_) {
        _flavor = null;
      }
    }
    notifyListeners();
    if (_flavor != null) {
      unawaited(refreshFlavorFromServer());
    }
  }

  /// Re-fetch flavor from API so stale http api_base cannot survive cache.
  Future<void> refreshFlavorFromServer() async {
    final slug = _flavor?.gymSlug;
    if (slug == null || slug.isEmpty) return;
    try {
      final client = ApiClient(baseUrl: ApiConfig.defaultApiBase);
      final res = await client.get(
        ApiClient.mobileApiPath,
        query: {'action': 'get_flavor', 'gym': slug},
      );
      if (res['success'] != true) return;
      final fresh = GymFlavor.fromJson(res, slug);
      if (!fresh.isValid) return;
      await _persistFlavor(fresh);
    } catch (_) {
      // Offline — keep cached flavor (already HTTPS-normalized).
    }
  }

  /// Resolve gym from install bundle or deep link — never prompts for a gym code.
  Future<bool> bootstrapFlavor({Uri? initialUri}) async {
    _bootstrapError = null;
    _loading = true;
    notifyListeners();
    try {
      if (hasFlavor) {
        await refreshFlavorFromServer();
        return true;
      }
      var slug = await GymSlugReader.bundledSlug();
      slug ??= GymSlugReader.slugFromUri(initialUri);
      slug ??= await GymSlugReader.bundledSlugFromPlatform();
      if (slug == null || slug.isEmpty) {
        _bootstrapError =
            'Install TitanFit from your gym\'s landing page download link, then open the app from that page.';
        return false;
      }
      final flavor = await resolveFlavor(slug);
      if (flavor == null) {
        _bootstrapError = 'Gym not found. Re-download from your gym\'s official page.';
        return false;
      }
      return true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<GymFlavor?> resolveFlavor(String gymSlug) async {
    _loading = true;
    notifyListeners();
    try {
      final slug = gymSlug.trim().toLowerCase();
      if (slug.isEmpty) return null;
      final client = ApiClient(baseUrl: ApiConfig.defaultApiBase);
      final res = await client.get(
        ApiClient.mobileApiPath,
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

  Future<void> setSession({
    required bool loggedIn,
    bool? onboardingComplete,
  }) async {
    _loggedIn = loggedIn;
    if (onboardingComplete != null) {
      _onboardingComplete = onboardingComplete;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLoggedIn, loggedIn);
    if (onboardingComplete != null) {
      await prefs.setBool(_keyOnboardingDone, onboardingComplete);
    }
    notifyListeners();
  }

  Future<void> setLoggedIn(bool value) async {
    await setSession(loggedIn: value);
  }

  Future<void> setOnboardingComplete(bool value) async {
    _onboardingComplete = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, value);
    notifyListeners();
  }

  String get cookieHeader => _cookieHeader;

  Future<void> saveCookies(String header) async {
    _cookieHeader = header;
    _client?.cookieHeader = header;
    final prefs = await SharedPreferences.getInstance();
    if (header.isEmpty) {
      await prefs.remove(_keyCookies);
    } else {
      await prefs.setString(_keyCookies, header);
    }
  }

  /// Shared client — keeps session cookies in sync across auth + profile calls.
  ApiClient apiClientFor(GymFlavor flavor) {
    final base = flavor.apiBase.isNotEmpty ? flavor.apiBase : ApiConfig.defaultApiBase;
    if (_client == null || _client!.baseUrl != base) {
      _client = ApiClient(baseUrl: base, cookieHeader: _cookieHeader);
    } else {
      _client!.cookieHeader = _cookieHeader;
    }
    return _client!;
  }

  Future<void> clearAuthSession() async {
    _loggedIn = false;
    _onboardingComplete = false;
    _cookieHeader = '';
    _client?.cookieHeader = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyOnboardingDone);
    await prefs.remove(_keyCookies);
    notifyListeners();
  }

  Future<void> clearFlavor() async {
    _flavor = null;
    _loggedIn = false;
    _onboardingComplete = false;
    _cookieHeader = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFlavor);
    await prefs.remove(_keyLoggedIn);
    await prefs.remove(_keyOnboardingDone);
    await prefs.remove(_keyCookies);
    notifyListeners();
  }

  Future<void> clearSession() async => clearFlavor();
}
