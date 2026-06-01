import '../flavor/gym_flavor.dart';
import '../flavor/gym_flavor_service.dart';
import 'api_client.dart';
import 'member_service.dart';
import 'session_cookies.dart';

/// Member auth — all calls go through [ApiClient.mobileApiPath] (app.php), not auth.php.
class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  static AuthService forFlavor(GymFlavor flavor) {
    return AuthService(GymFlavorService.instance.apiClientFor(flavor));
  }

  ApiClient get client => _client;

  Future<AuthResult> login({
    required String username,
    required String password,
    required GymFlavor flavor,
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'mobile_login',
      'gym_slug': flavor.gymSlug,
      'username': username.trim(),
      'password': password,
    });

    return _finishAuth(res, flavor);
  }

  Future<AuthResult> register({
    required GymFlavor flavor,
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'mobile_register',
      'gym_slug': flavor.gymSlug,
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    return _finishAuth(res, flavor, defaultNeedsOnboarding: true);
  }

  Future<AuthResult> forgotPassword({
    required GymFlavor flavor,
    required String email,
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'mobile_forgot_password',
      'gym_slug': flavor.gymSlug,
      'email': email.trim().toLowerCase(),
      'return_app': '1',
    });
    if (res['success'] == true) {
      return AuthResult.ok();
    }
    return AuthResult.fail(
      (res['message'] ?? 'Could not send reset email').toString(),
    );
  }

  Future<AuthResult> _finishAuth(
    Map<String, dynamic> res,
    GymFlavor flavor, {
    bool defaultNeedsOnboarding = false,
  }) async {
    if (res['success'] == true) {
      final data = res['data'];
      var needsOnboarding = defaultNeedsOnboarding;
      if (data is Map<String, dynamic>) {
        final profile = MemberProfile.fromJson(data);
        final gymId = (data['gym_id'] as num?)?.toInt();
        if (gymId != null && gymId != flavor.gymId) {
          return AuthResult.fail('Wrong username or password');
        }
        needsOnboarding = !profile.onboardingComplete;
      }
      await _applySessionFromResponse(res);
      await GymFlavorService.instance.setSession(
        loggedIn: true,
        onboardingComplete: !needsOnboarding,
      );
      return AuthResult.ok(needsOnboarding: needsOnboarding);
    }
    return AuthResult.fail((res['message'] ?? 'Request failed').toString());
  }

  /// Cookie jar on mobile often miss Set-Cookie — use session_token from JSON body.
  Future<void> _applySessionFromResponse(Map<String, dynamic> res) async {
    var header = _client.cookieHeader;
    final tok = SessionCookies.tokenFromResponse(res);
    if (tok != null) {
      header = SessionCookies.upsert(header, SessionCookies.sessionName, tok);
      _client.cookieHeader = header;
    }
    if (header.isNotEmpty) {
      await GymFlavorService.instance.saveCookies(header);
    }
  }

  Future<void> logout() async {
    try {
      await _client.postForm('/api/controllers/logout.php', {});
    } catch (_) {}
    await GymFlavorService.instance.clearSession();
  }
}

class AuthResult {
  const AuthResult._({
    required this.ok,
    this.message,
    this.needsOnboarding = false,
  });

  factory AuthResult.ok({bool needsOnboarding = false}) =>
      AuthResult._(ok: true, needsOnboarding: needsOnboarding);

  factory AuthResult.fail(String message) =>
      AuthResult._(ok: false, message: message);

  final bool ok;
  final String? message;
  final bool needsOnboarding;
}
