import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/user_model.dart';

class AuthResult {
  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.message,
  });

  final String? accessToken;
  final String? refreshToken;
  final UserModel? user;
  final String? message;
}

class AuthRepository {
  AuthRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
  }) async {
    final res = await _client.post(
      ApiEndpoints.register,
      body: {
        'email': email,
        'username': username,
        'password': password,
      },
    );

    final accessToken = (res['accessToken'] ??
        res['token'] ??
        res['access_token']) as String?;
    final refreshToken =
        (res['refreshToken'] ?? res['refresh_token']) as String?;
    final userJson = res['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : null;

    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      message: res['message'] as String?,
    );
  }

  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final res = await _client.post(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    final accessToken = (res['accessToken'] ??
        res['token'] ??
        res['access_token']) as String?;
    final refreshToken =
        (res['refreshToken'] ?? res['refresh_token']) as String?;
    final userJson = res['user'];
    final user = userJson is Map<String, dynamic>
        ? UserModel.fromJson(userJson)
        : null;

    return AuthResult(
      accessToken: accessToken,
      refreshToken: refreshToken,
      user: user,
      message: res['message'] as String?,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(client: ref.watch(apiClientProvider));
});
