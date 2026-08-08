import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/user_model.dart';
import '../../challenges/providers/challenge_provider.dart';
import '../../connections/providers/connections_provider.dart';
import '../../home/providers/home_provider.dart';
import '../../match/providers/match_provider.dart';
import '../../memories/providers/memories_provider.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../profile/providers/profile_provider.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.hasSeenOnboarding = false,
    this.userId,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.message,
    this.error,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final bool hasSeenOnboarding;
  final String? userId;
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;
  final String? message;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasSeenOnboarding,
    String? userId,
    UserModel? user,
    String? accessToken,
    String? refreshToken,
    String? message,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      userId: userId ?? this.userId,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      message: message,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    final tokens = ref.read(bootstrapTokensProvider);
    final seenOnboarding = ref.read(bootstrapOnboardingSeenProvider);
    final accessToken = tokens.accessToken;
    if (accessToken != null && accessToken.isNotEmpty) {
      ref.read(apiClientProvider).setAuthToken(accessToken);
      return AuthState(
        isAuthenticated: true,
        hasSeenOnboarding: true,
        accessToken: accessToken,
        refreshToken: tokens.refreshToken,
      );
    }
    return AuthState(hasSeenOnboarding: seenOnboarding);
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.post(
        ApiEndpoints.register,
        body: {
          'email': email,
          'username': username,
          'password': password,
        },
      );

      debugPrint('📝 Signup response: $res');

      final accessToken = (res['accessToken'] ??
          res['token'] ??
          res['access_token']) as String?;
      final refreshToken =
          (res['refreshToken'] ?? res['refresh_token']) as String?;
      final userJson = res['user'];
      final user = userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null;

      client.setAuthToken(accessToken);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

      _resetUserScopedProviders();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        userId: user?.id,
        message: res['message'] as String?,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.post(
        ApiEndpoints.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      debugPrint('🔐 Login response: $res');

      final accessToken = (res['accessToken'] ??
          res['token'] ??
          res['access_token']) as String?;
      final refreshToken =
          (res['refreshToken'] ?? res['refresh_token']) as String?;
      final userJson = res['user'];
      final user = userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null;

      client.setAuthToken(accessToken);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

      _resetUserScopedProviders();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: user,
        userId: user?.id,
        message: res['message'] as String?,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, error: 'Something went wrong.');
      return false;
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      userId: 'user_001',
    );
  }

  Future<void> signInWithApple() async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 1));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      userId: 'user_001',
    );
  }

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasSeenOnboarding: true);
    await ref.read(tokenStorageProvider).setOnboardingSeen();
  }

  Future<void> signOut() async {
    state = const AuthState(hasSeenOnboarding: true);
    await ref.read(tokenStorageProvider).clear();
    ref.read(apiClientProvider).setAuthToken(null);
    _resetUserScopedProviders();
  }

  void _resetUserScopedProviders() {
    ref.invalidate(homeProvider);
    ref.invalidate(profileProvider);
    ref.invalidate(matchProvider);
    ref.invalidate(challengeProvider);
    ref.invalidate(memoriesProvider);
    ref.invalidate(notificationsProvider);
    ref.invalidate(connectionsProvider);
  }
}

final authProvider =
    NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthFormState {
  const AuthFormState({this.isSignUp = false, this.obscurePassword = true});

  final bool isSignUp;
  final bool obscurePassword;

  AuthFormState copyWith({bool? isSignUp, bool? obscurePassword}) {
    return AuthFormState(
      isSignUp: isSignUp ?? this.isSignUp,
      obscurePassword: obscurePassword ?? this.obscurePassword,
    );
  }
}

class AuthFormNotifier extends AutoDisposeNotifier<AuthFormState> {
  @override
  AuthFormState build() => const AuthFormState();

  void toggleMode() => state = state.copyWith(isSignUp: !state.isSignUp);

  /// Switch to the login view (used after a successful registration).
  void showLogin() => state = state.copyWith(isSignUp: false);

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
}

final authFormProvider =
    AutoDisposeNotifierProvider<AuthFormNotifier, AuthFormState>(
  AuthFormNotifier.new,
);
