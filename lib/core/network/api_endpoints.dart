/// Central place for the API base URL and all endpoint paths.
class ApiEndpoints {
  ApiEndpoints._();

  /// Build-time override, e.g. for a physical device on your LAN:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:3000
  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Public ngrok tunnel to the backend. Works across emulator, simulator,
  /// desktop, web and physical devices since it's a public HTTPS URL.
  /// Override via `--dart-define=API_BASE_URL=...` to point elsewhere.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return 'https://3105-221-132-118-98.ngrok-free.app';
  }

  // ---- Auth ----
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // ---- Home ----
  static const String home = '/api/home';

  // ---- Profile ----
  static const String profile = '/api/profile';

  // ---- Memories ----
  static const String memories = '/api/memories';

  // ---- Challenges ----
  static const String challenges = '/api/challenges';
  static String challengeStart(String id) => '/api/challenges/$id/start';
  static String challengeComplete(String id) => '/api/challenges/$id/complete';
}
