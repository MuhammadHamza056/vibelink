import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/user_model.dart';

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

  /// Latest server message (e.g. "Account created successfully").
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
    // Restore a persisted session loaded from secure storage at app start.
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

  /// Registers a new account against POST /api/auth/register.
  ///
  /// Returns `true` on success; on failure sets [AuthState.error] and
  /// returns `false` so the UI can show the message.
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

      // Registration does NOT log the user in — they sign in afterwards on
      // the login screen. So we only surface the server message here.
      state = state.copyWith(
        isLoading: false,
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

  /// Signs in against POST /api/auth/login.
  ///
  /// Returns `true` on success; on failure sets [AuthState.error] and
  /// returns `false` so the UI can show the message.
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

      final accessToken =
          (res['accessToken'] ?? res['token'] ?? res['access_token']) as String?;
      final refreshToken =
          (res['refreshToken'] ?? res['refresh_token']) as String?;
      final userJson = res['user'];
      final user = userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null;

      // Authorize subsequent requests with the issued token and persist the
      // session so it survives an app restart.
      client.setAuthToken(accessToken);
      await ref.read(tokenStorageProvider).saveTokens(
            accessToken: accessToken,
            refreshToken: refreshToken,
          );

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

  /// Marks onboarding complete in state and persists it to secure storage so
  /// it survives restarts and sign-out.
  Future<void> completeOnboarding() async {
    state = state.copyWith(hasSeenOnboarding: true);
    await ref.read(tokenStorageProvider).setOnboardingSeen();
  }

  Future<void> signOut() async {
    await ref.read(tokenStorageProvider).clear();
    ref.read(apiClientProvider).setAuthToken(null);
    // Keep hasSeenOnboarding so logout returns to login, not onboarding.
    state = const AuthState(hasSeenOnboarding: true);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

/// UI-only state for the auth form: which mode (sign up vs. login) is showing
/// and whether the password is obscured. Kept in Riverpod so [AuthScreen]
/// needs no [setState]. Auto-disposes, so the form resets when the screen is
/// left — matching the previous StatefulWidget behaviour.
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
