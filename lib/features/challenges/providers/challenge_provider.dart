import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/token_storage.dart';
import '../../../models/challenge_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';

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

  /// Ids of challenges the user has started (POST .../start succeeded).
  final Set<String> activeChallengeIds;

  /// For each started challenge, the time at which its timer elapses and it can
  /// be completed. Until then the "Complete" CTA stays disabled.
  final Map<String, DateTime> completableAt;

  /// Id of the challenge whose start request is currently in flight.
  final String? startingId;

  /// Id of the challenge whose complete request is currently in flight.
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

  /// True if any challenge is currently active.
  bool get hasActiveChallenge => activeChallengeIds.isNotEmpty;

  /// True if a challenge OTHER than [id] is currently active.
  bool hasOtherActiveChallenge(String id) =>
      activeChallengeIds.isNotEmpty && !activeChallengeIds.contains(id);

  /// When the [id] challenge becomes completable, or null if it's not started.
  DateTime? completableTimeFor(String id) => completableAt[id];

  /// True once a started challenge's timer has elapsed (or it has no timer).
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

  /// Fetches challenges from GET /api/challenges and GET /api/challenges/completed.
  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final activeMap = await ref.read(tokenStorageProvider).readActiveChallenges();
      final client = ref.read(apiClientProvider);

      List<ChallengeModel> challenges = const [];
      List<ChallengeModel> completedChallenges = const [];

      try {
        final res = await client.get(ApiEndpoints.challenges);
        final body = res['body'] ?? res;
        final rawList = body is List
            ? body
            : (body is Map && body['challenges'] is List
                ? body['challenges'] as List
                : const []);
        challenges = rawList
            .whereType<Map<String, dynamic>>()
            .map(ChallengeModel.fromJson)
            .toList();
      } catch (_) {}

      try {
        final resCompleted = await client.get(ApiEndpoints.challengesCompleted);
        final bodyCompleted = resCompleted['body'] ?? resCompleted;
        final rawCompleted = bodyCompleted is List
            ? bodyCompleted
            : (bodyCompleted is Map && bodyCompleted['challenges'] is List
                ? bodyCompleted['challenges'] as List
                : const []);
        completedChallenges = rawCompleted
            .whereType<Map<String, dynamic>>()
            .map(ChallengeModel.fromJson)
            .toList();
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

  /// Re-fetches challenges (e.g. pull-to-refresh / retry).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  void setFilter(ChallengeFilter filter) {
    state = state.copyWith(filter: filter);
  }

  /// Fetches a single challenge by ID from GET /api/challenges/:id
  Future<ChallengeModel?> fetchChallengeById(String id) async {
    try {
      final res = await ref.read(apiClientProvider).get(ApiEndpoints.challengeById(id));
      final data = res['body'] ?? res;
      if (data is Map<String, dynamic>) {
        final model = ChallengeModel.fromJson(data);
        _updateChallengeInState(model);
        return model;
      }
    } catch (_) {}
    return null;
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

  /// Starts or Re-plays a challenge via POST /api/challenges/{id}/start.
  Future<bool> startChallenge(String id, {Duration duration = Duration.zero}) async {
    if (state.hasOtherActiveChallenge(id)) {
      state = state.copyWith(
        error: 'You already have an active challenge in progress. Complete it first!',
      );
      return false;
    }
    state = state.copyWith(startingId: id);
    try {
      try {
        final res = await ref.read(apiClientProvider).post(ApiEndpoints.challengeStart(id));
        final challengeData = res['challenge'] ?? (res['body'] is Map ? res['body']['challenge'] : null);
        if (challengeData is Map<String, dynamic>) {
          final updated = ChallengeModel.fromJson(challengeData);
          _updateChallengeInState(updated);
        }
      } on ApiException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already in progress') || msg.contains('already started')) {
          // Challenge was already started on server
        } else {
          rethrow;
        }
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

  /// Completes a started challenge via POST /api/challenges/{id}/complete.
  Future<bool> completeChallenge(String id) async {
    state = state.copyWith(completingId: id);
    try {
      try {
        final res = await ref.read(apiClientProvider).post(ApiEndpoints.challengeComplete(id));
        final challengeData = res['challenge'] ?? (res['body'] is Map ? res['body']['challenge'] : null);
        if (challengeData is Map<String, dynamic>) {
          final updated = ChallengeModel.fromJson(challengeData);
          _updateChallengeInState(updated);
        }
      } on ApiException catch (e) {
        final msg = e.message.toLowerCase();
        if (msg.contains('already completed') || msg.contains('not in progress') || msg.contains('not started')) {
          // Already completed on server
        } else {
          rethrow;
        }
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
