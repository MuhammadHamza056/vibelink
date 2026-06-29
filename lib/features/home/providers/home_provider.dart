import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/services/location_service.dart';
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

    // Best-effort: push the device location to the backend. Fire-and-forget so
    // it never blocks or breaks the dashboard load.
    _syncLocation(client);

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

  /// Reads the current device location and PUTs it to /api/profile/location.
  /// Failures (permission denied, services off, offline) are swallowed since
  /// location is non-critical to the home dashboard.
  Future<void> _syncLocation(ApiClient client) async {
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (pos == null) return;
      await client.put(
        ApiEndpoints.profileLocation,
        body: {'lat': pos.latitude, 'lng': pos.longitude},
      );
    } catch (_) {
      // Ignore — location sync is best-effort.
    }
  }

  Future<HomeModel?> _fetchHome(ApiClient client) async {
    try {
      final res = await client.get(ApiEndpoints.home);
      final body = res['body'];
      if (body is! Map<String, dynamic>) return null;
      final home = HomeModel.fromJson(body);
      // Randomize which challenge is featured as the "Challenge of the Day".
      // Shuffling once on load keeps it stable across rebuilds, while a
      // pull-to-refresh picks a fresh one. dailyChallenge reads .first and the
      // "Suggested for You" row skips that same first item, so they stay in sync.
      home.suggestedChallenges.shuffle();
      return home;
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
