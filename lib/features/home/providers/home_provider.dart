import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/home_model.dart';
import '../../../models/user_model.dart';

class HomeState {
  const HomeState({
    this.home,
    this.profile,
    this.isLoading = true,
    this.safetyPulseActive = false,
    this.error,
  });

  final HomeModel? home;

  /// Full profile from GET /api/profile, used for richer data not in the home
  /// payload (e.g. the avatar shown in the app bar).
  final UserModel? profile;
  final bool isLoading;
  final bool safetyPulseActive;
  final String? error;

  HomeState copyWith({
    HomeModel? home,
    UserModel? profile,
    bool? isLoading,
    bool? safetyPulseActive,
    String? error,
  }) {
    return HomeState(
      home: home ?? this.home,
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      safetyPulseActive: safetyPulseActive ?? this.safetyPulseActive,
      error: error,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    _load();
    return const HomeState();
  }

  /// Loads the home dashboard from GET /api/home, and the full user from
  /// GET /api/profile (for the avatar). The two are fetched concurrently but
  /// handled independently so a profile failure never blanks the dashboard.
  Future<void> _load() async {
    final client = ref.read(apiClientProvider);
    final results = await Future.wait([
      _fetchHome(client),
      _fetchProfile(client),
    ]);
    final home = results[0] as HomeModel?;
    final profile = results[1] as UserModel?;

    state = state.copyWith(
      home: home,
      profile: profile,
      isLoading: false,
      // Reflect the user's saved burnout-guard preference.
      safetyPulseActive: home?.burnoutEnabled ?? false,
      error: home == null ? 'Could not load your home feed.' : null,
    );
  }

  Future<HomeModel?> _fetchHome(ApiClient client) async {
    try {
      final res = await client.get(ApiEndpoints.home);
      final body = res['body'];
      return body is Map<String, dynamic> ? HomeModel.fromJson(body) : null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> _fetchProfile(ApiClient client) async {
    try {
      final res = await client.get(ApiEndpoints.profile);
      final body = res['body'];
      return body is Map<String, dynamic> ? UserModel.fromJson(body) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  void toggleSafetyPulse() {
    state = state.copyWith(safetyPulseActive: !state.safetyPulseActive);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
