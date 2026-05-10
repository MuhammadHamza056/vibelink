import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';
import '../../../models/challenge_model.dart';

class HomeState {
  const HomeState({
    this.user,
    this.dailyChallenge,
    this.nearbyCount = 0,
    this.isLoading = true,
    this.safetyPulseActive = false,
  });

  final UserModel? user;
  final ChallengeModel? dailyChallenge;
  final int nearbyCount;
  final bool isLoading;
  final bool safetyPulseActive;

  HomeState copyWith({
    UserModel? user,
    ChallengeModel? dailyChallenge,
    int? nearbyCount,
    bool? isLoading,
    bool? safetyPulseActive,
  }) {
    return HomeState(
      user: user ?? this.user,
      dailyChallenge: dailyChallenge ?? this.dailyChallenge,
      nearbyCount: nearbyCount ?? this.nearbyCount,
      isLoading: isLoading ?? this.isLoading,
      safetyPulseActive: safetyPulseActive ?? this.safetyPulseActive,
    );
  }
}

class HomeNotifier extends Notifier<HomeState> {
  @override
  HomeState build() {
    _load();
    return const HomeState();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 800));
    state = state.copyWith(
      user: UserModel.mock,
      dailyChallenge: ChallengeModel.mockList.first,
      nearbyCount: 23,
      isLoading: false,
    );
  }

  Future<void> refresh() => _load();

  void toggleSafetyPulse() {
    state = state.copyWith(safetyPulseActive: !state.safetyPulseActive);
  }
}

final homeProvider = NotifierProvider<HomeNotifier, HomeState>(HomeNotifier.new);
