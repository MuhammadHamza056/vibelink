import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthState {
  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.hasSeenOnboarding = false,
    this.userId,
    this.error,
  });

  final bool isAuthenticated;
  final bool isLoading;
  final bool hasSeenOnboarding;
  final String? userId;
  final String? error;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    bool? hasSeenOnboarding,
    String? userId,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      userId: userId ?? this.userId,
      error: error,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthState();

  Future<void> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      userId: 'user_001',
    );
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

  void completeOnboarding() {
    state = state.copyWith(hasSeenOnboarding: true);
  }

  Future<void> signOut() async {
    state = const AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
