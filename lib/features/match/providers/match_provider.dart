import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MatchStatus { searching, found, connected, skipped }

class MatchCandidate {
  const MatchCandidate({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.vibeTags,
    required this.vibeScore,
    required this.distanceMeters,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final List<String> vibeTags;
  final double vibeScore;
  final int distanceMeters;

  String get distanceLabel {
    if (distanceMeters < 1000) return '${distanceMeters}m away';
    return '${(distanceMeters / 1000).toStringAsFixed(1)}km away';
  }

  static MatchCandidate get mock => const MatchCandidate(
        id: 'u2',
        username: 'Anonymous Vibe',
        avatarUrl: 'https://i.pravatar.cc/150?img=25',
        vibeTags: ['Musical', 'Creative', 'Traveler'],
        vibeScore: 0.82,
        distanceMeters: 340,
      );
}

class MatchState {
  const MatchState({
    this.status = MatchStatus.searching,
    this.candidate,
    this.isLoading = false,
    this.searchSeconds = 0,
  });

  final MatchStatus status;
  final MatchCandidate? candidate;
  final bool isLoading;
  final int searchSeconds;

  MatchState copyWith({
    MatchStatus? status,
    MatchCandidate? candidate,
    bool? isLoading,
    int? searchSeconds,
  }) {
    return MatchState(
      status: status ?? this.status,
      candidate: candidate ?? this.candidate,
      isLoading: isLoading ?? this.isLoading,
      searchSeconds: searchSeconds ?? this.searchSeconds,
    );
  }
}

class MatchNotifier extends Notifier<MatchState> {
  @override
  MatchState build() => const MatchState();

  Future<void> startSearch() async {
    state = state.copyWith(status: MatchStatus.searching, isLoading: true);
    await Future.delayed(const Duration(seconds: 3));
    state = state.copyWith(
      status: MatchStatus.found,
      candidate: MatchCandidate.mock,
      isLoading: false,
    );
  }

  void acceptMatch() {
    state = state.copyWith(status: MatchStatus.connected);
  }

  void skipMatch() {
    state = state.copyWith(
      status: MatchStatus.skipped,
      candidate: null,
    );
    Future.delayed(const Duration(seconds: 1), startSearch);
  }

  void reset() {
    state = const MatchState();
  }
}

final matchProvider = NotifierProvider<MatchNotifier, MatchState>(MatchNotifier.new);
