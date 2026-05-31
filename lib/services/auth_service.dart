import '../config/api_config.dart';
import '../flavor/gym_flavor.dart';
import '../flavor/gym_flavor_service.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._client);

  final ApiClient _client;

  static AuthService forFlavor(GymFlavor flavor) {
    final base = flavor.apiBase.isNotEmpty ? flavor.apiBase : ApiConfig.defaultApiBase;
    return AuthService(ApiClient(baseUrl: base));
  }

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
      final gymId = data is Map ? (data['gym_id'] as num?)?.toInt() : null;
      if (gymId != null && gymId != flavor.gymId) {
        return AuthResult.fail('Wrong username or password');
      }
      await GymFlavorService.instance.setLoggedIn(true);
      return AuthResult.ok();
    }

    final msg = (res['message'] ?? '').toString();
    if (msg.toLowerCase().contains('invalid') ||
        msg.toLowerCase().contains('wrong') ||
        msg.toLowerCase().contains('not registered')) {
      return AuthResult.fail('Wrong username or password');
    }
    return AuthResult.fail(msg.isEmpty ? 'Wrong username or password' : msg);
  }

  Future<AuthResult> register({
    required GymFlavor flavor,
    required String fullName,
    required String email,
    required String password,
  }) async {
    final res = await _client.postForm('/api/controllers/auth.php', {
      'action': 'tenant_register',
      'gym_slug': flavor.gymSlug,
      'full_name': fullName.trim(),
      'email': email.trim().toLowerCase(),
      'password': password,
    });

    if (res['success'] == true) {
      await GymFlavorService.instance.setLoggedIn(true);
      return AuthResult.ok();
    }
    return AuthResult.fail((res['message'] ?? 'Registration failed').toString());
  }

  Future<void> logout() async {
    try {
      await _client.postForm('/api/controllers/logout.php', {});
    } catch (_) {}
    await GymFlavorService.instance.setLoggedIn(false);
  }
}

class AuthResult {
  const AuthResult._({required this.ok, this.message});

  factory AuthResult.ok() => const AuthResult._(ok: true);
  factory AuthResult.fail(String message) =>
      AuthResult._(ok: false, message: message);

  final bool ok;
  final String? message;
}
