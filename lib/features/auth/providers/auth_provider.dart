import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/user_model.dart';
import '../repositories/auth_repository.dart';
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
    this.isInitialized = false,
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
  final bool isInitialized;
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
    bool? isInitialized,
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
      isInitialized: isInitialized ?? this.isInitialized,
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
    _bootstrap();
    return const AuthState(isLoading: true, isInitialized: false);
  }

  Future<void> _bootstrap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isFirstRun = prefs.getBool('app_has_run_before') != true;
      final tokenStorage = ref.read(tokenStorageProvider);

      if (isFirstRun) {
        await tokenStorage.clearAll();
        await prefs.setBool('app_has_run_before', true);
      }

      final accessToken = await tokenStorage.readAccessToken();
      final refreshToken = await tokenStorage.readRefreshToken();
      final seenOnboarding = await tokenStorage.readOnboardingSeen();

      if (accessToken != null && accessToken.isNotEmpty) {
        ref.read(apiClientProvider).setAuthToken(accessToken);
        state = AuthState(
          isInitialized: true,
          isAuthenticated: true,
          hasSeenOnboarding: true,
          accessToken: accessToken,
          refreshToken: refreshToken,
          isLoading: false,
        );
      } else {
        state = AuthState(
          isInitialized: true,
          isAuthenticated: false,
          hasSeenOnboarding: seenOnboarding,
          isLoading: false,
        );
      }
    } catch (_) {
      state = const AuthState(
        isInitialized: true,
        isAuthenticated: false,
        hasSeenOnboarding: false,
        isLoading: false,
      );
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null, message: null);
    try {
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.register(
        email: email,
        username: username,
        password: password,
      );

      debugPrint('📝 Signup response: ${result.user?.username}');

      ref.read(apiClientProvider).setAuthToken(result.accessToken);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
          );

      _resetUserScopedProviders();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
        userId: result.user?.id,
        message: result.message,
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
      final repo = ref.read(authRepositoryProvider);
      final result = await repo.signInWithEmail(
        email: email,
        password: password,
      );

      debugPrint('🔐 Login response: ${result.user?.username}');

      ref.read(apiClientProvider).setAuthToken(result.accessToken);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: result.accessToken,
            refreshToken: result.refreshToken,
          );

      _resetUserScopedProviders();
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        user: result.user,
        userId: result.user?.id,
        message: result.message,
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

  Future<void> completeOnboarding() async {
    state = state.copyWith(hasSeenOnboarding: true);
    await ref.read(tokenStorageProvider).setOnboardingSeen();
  }

  Future<void> signOut() async {
    state = const AuthState(isInitialized: true, hasSeenOnboarding: true);
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

  void showLogin() => state = state.copyWith(isSignUp: false);

  void toggleObscure() =>
      state = state.copyWith(obscurePassword: !state.obscurePassword);
}

final authFormProvider =
    AutoDisposeNotifierProvider<AuthFormNotifier, AuthFormState>(
  AuthFormNotifier.new,
);
