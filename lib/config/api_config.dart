/// API base URL for Titan Labs backend.
/// Override at runtime via flavor cache if needed.
class ApiConfig {
  /// Production default — change for local dev (e.g. http://10.0.2.2:8080).
  static const String defaultApiBase = String.fromEnvironment(
    'TITAN_API_BASE',
    defaultValue: 'https://titanlabs.up.railway.app',
  );

  /// GitHub Releases APK (flavor query param appended per gym on landing page).
  static const String releaseApkBase =
      'https://github.com/F1lthyNotFound/titanfit/releases/latest/download/titanfit-release.apk';
}
