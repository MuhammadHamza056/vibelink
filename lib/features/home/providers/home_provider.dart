import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/location_service.dart';
import '../../../models/home_model.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/home_repository.dart';

class HomeState {
  const HomeState({
    this.home,
    this.profile,
    this.isLoading = true,
    this.safetyPulseActive = false,
    this.error,
  });

  final HomeModel? home;
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
  Timer? _locationTimer;

  @override
  HomeState build() {
    ref.onDispose(() {
      _locationTimer?.cancel();
    });
    Future.microtask(() => _load());
    return const HomeState();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final repo = ref.read(homeRepositoryProvider);

    _syncLocation(repo);

    final results = await Future.wait([
      repo.fetchHome(),
      repo.fetchProfile(),
    ]);
    final home = results[0] as HomeModel?;
    final profile = results[1] as UserModel?;

    final isSafetyActive = profile?.safetyPulseEnabled ?? false;

    state = state.copyWith(
      home: home,
      profile: profile,
      isLoading: false,
      safetyPulseActive: isSafetyActive,
      error: home == null ? 'Could not load your home feed.' : null,
    );

    if (isSafetyActive) {
      _startPeriodicLocationSync();
    }
  }

  Future<void> _syncLocation(HomeRepository repo) async {
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (pos == null) return;
      await repo.syncLocation(lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      // Swallowed — non-critical
    }
  }

  void _startPeriodicLocationSync() {
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final repo = ref.read(homeRepositoryProvider);
      _syncLocation(repo);
    });
  }

  void _stopPeriodicLocationSync() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  Future<bool> toggleSafetyPulse() async {
    final nextState = !state.safetyPulseActive;
    state = state.copyWith(safetyPulseActive: nextState);

    final repo = ref.read(homeRepositoryProvider);

    if (nextState) {
      _syncLocation(repo);
      _startPeriodicLocationSync();
    } else {
      _stopPeriodicLocationSync();
    }

    try {
      if (state.profile != null) {
        state = state.copyWith(
          profile: state.profile!.copyWith(safetyPulseEnabled: nextState),
        );
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> triggerEmergencySOS() async {
    final repo = ref.read(homeRepositoryProvider);
    final pos = await ref.read(locationServiceProvider).currentPosition();
    return repo.triggerEmergencySOS(lat: pos?.latitude, lng: pos?.longitude);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
