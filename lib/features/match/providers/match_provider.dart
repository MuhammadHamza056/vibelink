import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/location_service.dart';
import '../repositories/match_repository.dart';

enum MatchStatus { searching, found, connected, skipped }

class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.level,
    required this.vibeTags,
    required this.sharedTags,
    required this.vibeScore,
    this.safetyPulseEnabled = false,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final int level;
  final List<String> vibeTags;
  final List<String> sharedTags;
  final double vibeScore;
  final bool safetyPulseEnabled;

  factory MatchCandidate.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return MatchCandidate(
      id: (user['id'] ?? user['_id'] ?? '').toString(),
      username: (user['username'] ?? 'Anonymous') as String,
      avatarUrl: (user['avatarUrl'] ?? '') as String,
      level: (user['level'] ?? 1) as int,
      vibeTags: (user['vibeTags'] as List?)?.cast<String>() ?? const [],
      sharedTags: (json['sharedTags'] as List?)?.cast<String>() ?? const [],
      vibeScore: ((json['vibeScore'] ?? 0) as num).toDouble(),
      safetyPulseEnabled: (user['safetyPulseEnabled'] ?? false) as bool,
    );
  }

  static MatchCandidate get mock => const MatchCandidate(
        id: 'u2',
        username: 'Anonymous Vibe',
        avatarUrl: 'https://i.pravatar.cc/150?img=25',
        level: 5,
        vibeTags: ['Musical', 'Creative', 'Traveler'],
        sharedTags: ['Creative'],
        vibeScore: 0.82,
        safetyPulseEnabled: true,
      );
}

class MatchState {
  const MatchState({
    this.status = MatchStatus.searching,
    this.candidates = const [],
    this.currentIndex = 0,
    this.isLoading = false,
    this.isConnecting = false,
    this.error,
  });

  final MatchStatus status;
  final List<MatchCandidate> candidates;
  final int currentIndex;
  final bool isLoading;
  final bool isConnecting;
  final String? error;

  MatchCandidate? get candidate =>
      currentIndex >= 0 && currentIndex < candidates.length
          ? candidates[currentIndex]
          : null;

  MatchState copyWith({
    MatchStatus? status,
    List<MatchCandidate>? candidates,
    int? currentIndex,
    bool? isLoading,
    bool? isConnecting,
    String? error,
  }) {
    return MatchState(
      status: status ?? this.status,
      candidates: candidates ?? this.candidates,
      currentIndex: currentIndex ?? this.currentIndex,
      isLoading: isLoading ?? this.isLoading,
      isConnecting: isConnecting ?? this.isConnecting,
      error: error,
    );
  }
}

class MatchNotifier extends Notifier<MatchState> {
  @override
  MatchState build() => const MatchState();

  static const int _radius = 5000;
  static const int _limit = 50;

  Future<void> startSearch() async {
    state = state.copyWith(
      status: MatchStatus.searching,
      isLoading: true,
      error: null,
    );
    try {
      final pos = await ref.read(locationServiceProvider).currentPosition();
      if (pos == null) {
        state = state.copyWith(
          status: MatchStatus.searching,
          isLoading: false,
          error: 'Location permission is required to find nearby matches. Please grant location access.',
        );
        return;
      }

      final repo = ref.read(matchRepositoryProvider);
      await repo.updateLocation(lat: pos.latitude, lng: pos.longitude);

      final candidates = await repo.fetchNearbyMatches(
        radius: _radius,
        limit: _limit,
      );

      if (candidates.isEmpty) {
        state = state.copyWith(
          status: MatchStatus.searching,
          candidates: const [],
          currentIndex: 0,
          isLoading: false,
          error: 'No vibes nearby right now. Try again later.',
        );
        return;
      }

      state = state.copyWith(
        status: MatchStatus.found,
        candidates: candidates,
        currentIndex: 0,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        status: MatchStatus.searching,
        isLoading: false,
        error: e.message,
      );
    } catch (_) {
      state = state.copyWith(
        status: MatchStatus.searching,
        isLoading: false,
        error: 'Could not find matches. Check your connection.',
      );
    }
  }

  Future<bool> acceptMatch() async {
    final candidate = state.candidate;
    if (candidate == null) return false;

    state = state.copyWith(isConnecting: true, error: null);
    try {
      final repo = ref.read(matchRepositoryProvider);
      await repo.connectMatch(candidate.id);
      state = state.copyWith(
        status: MatchStatus.connected,
        isConnecting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isConnecting: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isConnecting: false,
        error: 'Could not connect. Please try again.',
      );
      return false;
    }
  }

  void skipMatch() {
    final next = state.currentIndex + 1;
    if (next < state.candidates.length) {
      state = state.copyWith(status: MatchStatus.found, currentIndex: next);
    } else {
      state = state.copyWith(status: MatchStatus.skipped);
      Future.delayed(const Duration(seconds: 1), startSearch);
    }
  }

  void reset() {
    state = const MatchState();
  }
}

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(MatchNotifier.new);
