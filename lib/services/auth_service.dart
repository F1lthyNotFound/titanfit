import '../config/api_config.dart';
import '../flavor/gym_flavor.dart';
import '../flavor/gym_flavor_service.dart';
import 'api_client.dart';
import 'member_service.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  static AuthService forFlavor(GymFlavor flavor) {
    final base = flavor.apiBase.isNotEmpty ? flavor.apiBase : ApiConfig.defaultApiBase;
    return AuthService(ApiClient(baseUrl: base));
  }

  ApiClient get client => _client;

  Future<AuthResult> login({
    required String username,
    required String password,
    required GymFlavor flavor,
  }) async {
    final res = await _client.postForm('/api/controllers/app.php', {
      'action': 'mobile_login',
      'gym_slug': flavor.gymSlug,
      'username': username.trim(),
      'password': password,
    });

    if (res['success'] == true) {
      final data = res['data'];
      if (data is Map<String, dynamic>) {
        final profile = MemberProfile.fromJson(data);
        final gymId = (data['gym_id'] as num?)?.toInt();
        if (gymId != null && gymId != flavor.gymId) {
          return AuthResult.fail('Wrong username or password');
        }
        await GymFlavorService.instance.setSession(
          loggedIn: true,
          onboardingComplete: profile.onboardingComplete,
        );
        return AuthResult.ok(needsOnboarding: !profile.onboardingComplete);
      }
      await GymFlavorService.instance.setSession(loggedIn: true);
      return AuthResult.ok();
    }

    final msg = (res['message'] ?? '').toString();
    return AuthResult.fail(
      msg.isEmpty || !msg.toLowerCase().contains('wrong')
          ? 'Wrong username or password'
          : msg,
    );
  }

  Future<AuthResult> register({
    required GymFlavor flavor,
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await _client.postForm('/api/controllers/auth.php', {
      'action': 'tenant_register',
      'gym_slug': flavor.gymSlug,
      'username': username.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    if (res['success'] == true) {
      await GymFlavorService.instance.setSession(
        loggedIn: true,
        onboardingComplete: false,
      );
      return AuthResult.ok(needsOnboarding: true);
    }
    return AuthResult.fail((res['message'] ?? 'Registration failed').toString());
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
