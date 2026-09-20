import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/challenge_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../repositories/challenge_repository.dart';

enum ChallengeFilter { today, thisWeek, trending, completed }

class ChallengeState {
  const ChallengeState({
    this.challenges = const [],
    this.completedChallenges = const [],
    this.filter = ChallengeFilter.today,
    this.isLoading = true,
    this.activeChallenge,
    this.error,
    this.activeChallengeIds = const {},
    this.completableAt = const {},
    this.startingId,
    this.completingId,
  });

  final List<ChallengeModel> challenges;
  final List<ChallengeModel> completedChallenges;
  final ChallengeFilter filter;
  final bool isLoading;
  final ChallengeModel? activeChallenge;
  final String? error;

  final Set<String> activeChallengeIds;
  final Map<String, DateTime> completableAt;
  final String? startingId;
  final String? completingId;

  List<ChallengeModel> get filtered => switch (filter) {
        ChallengeFilter.today => challenges,
        ChallengeFilter.thisWeek => challenges.where((c) => c.xpReward >= 60).toList(),
        ChallengeFilter.trending => challenges.where((c) => c.isTrending).toList(),
        ChallengeFilter.completed => completedChallenges.isNotEmpty
            ? completedChallenges
            : challenges.where((c) => c.isCompleted).toList(),
      };

  bool isStarted(String id) => activeChallengeIds.contains(id);

  bool get hasActiveChallenge => activeChallengeIds.isNotEmpty;

  bool hasOtherActiveChallenge(String id) =>
      activeChallengeIds.isNotEmpty && !activeChallengeIds.contains(id);

  DateTime? completableTimeFor(String id) => completableAt[id];

  bool isCompletable(String id) {
    if (!isStarted(id)) return false;
    final at = completableAt[id];
    return at == null || !DateTime.now().isBefore(at);
  }

  ChallengeState copyWith({
    List<ChallengeModel>? challenges,
    List<ChallengeModel>? completedChallenges,
    ChallengeFilter? filter,
    bool? isLoading,
    ChallengeModel? activeChallenge,
    String? error,
    Set<String>? activeChallengeIds,
    Map<String, DateTime>? completableAt,
    String? startingId,
    String? completingId,
  }) {
    return ChallengeState(
      challenges: challenges ?? this.challenges,
      completedChallenges: completedChallenges ?? this.completedChallenges,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      error: error,
      activeChallengeIds: activeChallengeIds ?? this.activeChallengeIds,
      completableAt: completableAt ?? this.completableAt,
      startingId: startingId,
      completingId: completingId,
    );
  }
}

class ChallengeNotifier extends Notifier<ChallengeState> {
  @override
  ChallengeState build() {
    Future.microtask(() => _load());
    return const ChallengeState();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final activeMap = await ref.read(tokenStorageProvider).readActiveChallenges();
      final repo = ref.read(challengeRepositoryProvider);

      List<ChallengeModel> challenges = const [];
      List<ChallengeModel> completedChallenges = const [];

      try {
        challenges = await repo.fetchChallenges();
      } catch (_) {}

      try {
        completedChallenges = await repo.fetchCompletedChallenges();
      } catch (_) {}

      final serverActiveIds = <String>{};
      for (final c in challenges) {
        if (c.inProgress) {
          serverActiveIds.add(c.id);
        }
      }

      final mergedActiveIds = {...activeMap.keys, ...serverActiveIds};

      state = state.copyWith(
        challenges: challenges,
        completedChallenges: completedChallenges,
        isLoading: false,
        activeChallengeIds: mergedActiveIds,
        completableAt: activeMap,
      );
    } on ApiException catch (e) {
      final activeMap = await ref.read(tokenStorageProvider).readActiveChallenges();
      state = state.copyWith(
        isLoading: false,
        error: e.message,
        activeChallengeIds: activeMap.keys.toSet(),
        completableAt: activeMap,
      );
    } catch (_) {
      final activeMap = await ref.read(tokenStorageProvider).readActiveChallenges();
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load challenges.',
        activeChallengeIds: activeMap.keys.toSet(),
        completableAt: activeMap,
      );
    }
  }

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  void setFilter(ChallengeFilter filter) {
    state = state.copyWith(filter: filter);
  }

  Future<ChallengeModel?> fetchChallengeById(String id) async {
    final repo = ref.read(challengeRepositoryProvider);
    final model = await repo.fetchChallengeById(id);
    if (model != null) {
      _updateChallengeInState(model);
    }
    return model;
  }

  void _updateChallengeInState(ChallengeModel model) {
    final updatedList = state.challenges.map((c) => c.id == model.id ? model : c).toList();
    if (!updatedList.any((c) => c.id == model.id)) {
      updatedList.add(model);
    }

    final updatedCompleted = [...state.completedChallenges];
    if (model.isCompleted && !updatedCompleted.any((c) => c.id == model.id)) {
      updatedCompleted.add(model);
    }

    state = state.copyWith(
      challenges: updatedList,
      completedChallenges: updatedCompleted,
    );
  }

  Future<bool> startChallenge(String id, {Duration duration = Duration.zero}) async {
    if (state.hasOtherActiveChallenge(id)) {
      state = state.copyWith(
        error: 'You already have an active challenge in progress. Complete it first!',
      );
      return false;
    }
    state = state.copyWith(startingId: id);
    try {
      final repo = ref.read(challengeRepositoryProvider);
      final updatedModel = await repo.startChallenge(id);
      if (updatedModel != null) {
        _updateChallengeInState(updatedModel);
      }

      final updatedCompletableAt = {
        ...state.completableAt,
        id: DateTime.now().add(duration),
      };
      final updatedIds = {...state.activeChallengeIds, id};

      final updatedChallenges = state.challenges.map((c) {
        if (c.id == id) {
          return c.copyWith(inProgress: true, status: ChallengeStatus.active);
        }
        return c;
      }).toList();

      state = state.copyWith(
        challenges: updatedChallenges,
        activeChallengeIds: updatedIds,
        completableAt: updatedCompletableAt,
      );
      await ref.read(tokenStorageProvider).saveActiveChallenges(updatedCompletableAt);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Could not start the challenge.');
      return false;
    }
  }

  Future<bool> completeChallenge(String id) async {
    state = state.copyWith(completingId: id);
    try {
      final repo = ref.read(challengeRepositoryProvider);
      final updatedModel = await repo.completeChallenge(id);
      if (updatedModel != null) {
        _updateChallengeInState(updatedModel);
      }

      final updatedIds = state.activeChallengeIds.where((c) => c != id).toSet();
      final updatedCompletableAt = {...state.completableAt}..remove(id);

      final updatedChallenges = state.challenges.map((c) {
        if (c.id == id) {
          return c.copyWith(
            isCompleted: true,
            inProgress: false,
            status: ChallengeStatus.completed,
          );
        }
        return c;
      }).toList();

      final target = state.challenges.firstWhere((c) => c.id == id, orElse: () => ChallengeModel(
        id: id, title: '', description: '', emoji: '', durationMinutes: 0, category: ChallengeCategory.social, difficulty: ChallengeDifficulty.easy, status: ChallengeStatus.completed, participants: 0, maxParticipants: 0, xpReward: 0, tags: const [], expiresAt: DateTime.now(), isCompleted: true,
      ));
      final updatedCompleted = [...state.completedChallenges];
      if (!updatedCompleted.any((c) => c.id == id)) {
        updatedCompleted.add(target.copyWith(isCompleted: true, inProgress: false, status: ChallengeStatus.completed));
      }

      state = state.copyWith(
        challenges: updatedChallenges,
        completedChallenges: updatedCompleted,
        activeChallengeIds: updatedIds,
        completableAt: updatedCompletableAt,
      );
      await ref.read(tokenStorageProvider).saveActiveChallenges(updatedCompletableAt);
      ref.read(homeProvider.notifier).refresh();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Could not complete the challenge.');
      return false;
    }
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
