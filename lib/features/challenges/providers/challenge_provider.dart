import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/challenge_model.dart';

enum ChallengeFilter { today, thisWeek, trending }

class ChallengeState {
  const ChallengeState({
    this.challenges = const [],
    this.filter = ChallengeFilter.today,
    this.isLoading = true,
    this.activeChallenge,
  });

  final List<ChallengeModel> challenges;
  final ChallengeFilter filter;
  final bool isLoading;
  final ChallengeModel? activeChallenge;

  List<ChallengeModel> get filtered => switch (filter) {
        ChallengeFilter.today => challenges,
        ChallengeFilter.thisWeek => challenges.where((c) => c.xpReward >= 60).toList(),
        ChallengeFilter.trending => challenges.where((c) => c.isTrending).toList(),
      };

  ChallengeState copyWith({
    List<ChallengeModel>? challenges,
    ChallengeFilter? filter,
    bool? isLoading,
    ChallengeModel? activeChallenge,
  }) {
    return ChallengeState(
      challenges: challenges ?? this.challenges,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      activeChallenge: activeChallenge ?? this.activeChallenge,
    );
  }
}

class ChallengeNotifier extends Notifier<ChallengeState> {
  @override
  ChallengeState build() {
    _load();
    return const ChallengeState();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      challenges: ChallengeModel.mockList,
      isLoading: false,
    );
  }

  void setFilter(ChallengeFilter filter) {
    state = state.copyWith(filter: filter);
  }

  void startChallenge(ChallengeModel challenge) {
    state = state.copyWith(activeChallenge: challenge);
  }

  void completeChallenge() {
    state = ChallengeState(
      challenges: state.challenges,
      filter: state.filter,
    );
  }
}

final challengeProvider =
    NotifierProvider<ChallengeNotifier, ChallengeState>(ChallengeNotifier.new);

final challengeByIdProvider = Provider.family<ChallengeModel?, String>((ref, id) {
  final challenges = ref.watch(challengeProvider).challenges;
  try {
    return challenges.firstWhere((c) => c.id == id);
  } catch (_) {
    return null;
  }
});
