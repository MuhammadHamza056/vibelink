import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the auth tokens in the platform secure store (Keychain on iOS,
/// EncryptedSharedPreferences on Android) so the session survives restarts.
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const String _kAccess = 'access_token';
  static const String _kRefresh = 'refresh_token';
  static const String _kOnboarding = 'has_seen_onboarding';
  static const String _kActiveChallenges = 'active_challenges';

  Future<void> saveTokens({
    String? accessToken,
    String? refreshToken,
  }) async {
    if (accessToken != null && accessToken.isNotEmpty) {
      await _storage.write(key: _kAccess, value: accessToken);
    } else {
      await _storage.delete(key: _kAccess);
    }
    if (refreshToken != null && refreshToken.isNotEmpty) {
      await _storage.write(key: _kRefresh, value: refreshToken);
    } else {
      await _storage.delete(key: _kRefresh);
    }
  }

  Future<String?> readAccessToken() => _storage.read(key: _kAccess);

  Future<String?> readRefreshToken() => _storage.read(key: _kRefresh);

  /// Marks the onboarding flow as completed. Persisted separately from the
  /// tokens so it survives sign-out (a returning user goes to login, never
  /// back through onboarding).
  Future<void> setOnboardingSeen() =>
      _storage.write(key: _kOnboarding, value: 'true');

  Future<bool> readOnboardingSeen() async =>
      (await _storage.read(key: _kOnboarding)) == 'true';

  /// Saves active challenge completion times map (challengeId -> DateTime ISO string).
  Future<void> saveActiveChallenges(Map<String, DateTime> completableAt) async {
    try {
      final map =
          completableAt.map((id, dt) => MapEntry(id, dt.toIso8601String()));
      await _storage.write(key: _kActiveChallenges, value: jsonEncode(map));
    } catch (_) {}
  }

  /// Reads active challenge completion times map.
  Future<Map<String, DateTime>> readActiveChallenges() async {
    try {
      final str = await _storage.read(key: _kActiveChallenges);
      if (str == null || str.isEmpty) return {};
      final decoded = jsonDecode(str) as Map<String, dynamic>;
      return decoded.map((id, val) {
        return MapEntry(id, DateTime.parse(val.toString()));
      });
    } catch (_) {
      return {};
    }
  }

  /// Clears the auth tokens only. Intentionally leaves the onboarding flag in
  /// place so logout returns the user to login, not onboarding.
  Future<void> clear() async {
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
    await _storage.delete(key: _kActiveChallenges);
  }

  /// Completely purges all stored items from secure storage. Used on fresh app
  /// installs to clean up leftover iOS Keychain entries from prior installations.
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

/// Tokens read from secure storage at app start. Overridden in `main()` once
/// the persisted values have been loaded; defaults to empty so a cold start
/// without an override behaves as "logged out".
final bootstrapTokensProvider =
    Provider<({String? accessToken, String? refreshToken})>(
  (ref) => (accessToken: null, refreshToken: null),
);

/// Whether onboarding has been completed, read from secure storage at app
/// start. Overridden in `main()`; defaults to `false` (show onboarding).
final bootstrapOnboardingSeenProvider = Provider<bool>((ref) => false);
