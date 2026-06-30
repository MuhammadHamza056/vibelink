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
    return 'https://vibelinkbackend.vercel.app';
    // return 'https://8125-103-177-241-226.ngrok-free.app';
  }

  /// Resolves a possibly-relative media path returned by the API (e.g.
  /// "/uploads/avatars/x.jpg") into an absolute URL against [baseUrl].
  /// Absolute URLs and empty strings are returned unchanged.
  static String mediaUrl(String path) {
    if (path.isEmpty) return path;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    return '$base${path.startsWith('/') ? '' : '/'}$path';
  }

  // ---- Auth ----
  static const String register = '/api/auth/register';
  static const String login = '/api/auth/login';

  // ---- Home ----
  static const String home = '/api/home';

  // ---- Profile ----
  static const String profile = '/api/profile';
  static const String profileLocation = '/api/profile/location';
  static const String profileVibeTags = '/api/profile/vibe-tags';

  // ---- Match ----
  static const String matchNearby = '/api/match/nearby';
  static const String matchConnect = '/api/match/connect';
  static const String matchConnections = '/api/match/connections';
  static String matchConnectionLeave(String connectionId) =>
      '/api/match/connections/$connectionId';

  // ---- Notifications ----
  static const String notifications = '/api/notifications';
  static String notificationAccept(String id) =>
      '/api/notifications/$id/accept';
  static String notificationReject(String id) =>
      '/api/notifications/$id/reject';

  // ---- Memories ----
  static const String memories = '/api/memories';

  // ---- Challenges ----
  static const String challenges = '/api/challenges';
  static String challengeStart(String id) => '/api/challenges/$id/start';
  static String challengeComplete(String id) => '/api/challenges/$id/complete';
}
