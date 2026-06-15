import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/challenge_model.dart';

enum ChallengeFilter { today, thisWeek, trending }

class ChallengeState {
  const ChallengeState({
    this.challenges = const [],
    this.filter = ChallengeFilter.today,
    this.isLoading = true,
    this.activeChallenge,
    this.error,
    this.activeChallengeIds = const {},
    this.startingId,
    this.completingId,
  });

  final List<ChallengeModel> challenges;
  final ChallengeFilter filter;
  final bool isLoading;
  final ChallengeModel? activeChallenge;
  final String? error;

  /// Ids of challenges the user has started (POST .../start succeeded).
  final Set<String> activeChallengeIds;

  /// Id of the challenge whose start request is currently in flight.
  final String? startingId;

  /// Id of the challenge whose complete request is currently in flight.
  final String? completingId;

  List<ChallengeModel> get filtered => switch (filter) {
        ChallengeFilter.today => challenges,
        ChallengeFilter.thisWeek => challenges.where((c) => c.xpReward >= 60).toList(),
        ChallengeFilter.trending => challenges.where((c) => c.isTrending).toList(),
      };

  bool isStarted(String id) => activeChallengeIds.contains(id);

  ChallengeState copyWith({
    List<ChallengeModel>? challenges,
    ChallengeFilter? filter,
    bool? isLoading,
    ChallengeModel? activeChallenge,
    String? error,
    Set<String>? activeChallengeIds,
    String? startingId,
    String? completingId,
  }) {
    return ChallengeState(
      challenges: challenges ?? this.challenges,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      activeChallenge: activeChallenge ?? this.activeChallenge,
      error: error,
      activeChallengeIds: activeChallengeIds ?? this.activeChallengeIds,
      startingId: startingId,
      completingId: completingId,
    );
  }
}

class ChallengeNotifier extends Notifier<ChallengeState> {
  @override
  ChallengeState build() {
    _load();
    return const ChallengeState();
  }

  /// Fetches challenges from GET /api/challenges. The payload's `body` is a
  /// JSON array, which we map into [ChallengeModel]s.
  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get(ApiEndpoints.challenges);
      final body = res['body'];
      final challenges = (body as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChallengeModel.fromJson)
              .toList() ??
          const <ChallengeModel>[];
      state = state.copyWith(challenges: challenges, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load challenges.',
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

  /// Starts a challenge via POST /api/challenges/{id}/start. On success the id
  /// is recorded in [ChallengeState.activeChallengeIds] so the UI can flip the
  /// CTA to "Complete". Returns `true` on success, `false` otherwise (with the
  /// reason left in [ChallengeState.error]).
  Future<bool> startChallenge(String id) async {
    state = state.copyWith(startingId: id);
    try {
      await ref.read(apiClientProvider).post(ApiEndpoints.challengeStart(id));
      state = state.copyWith(
        activeChallengeIds: {...state.activeChallengeIds, id},
        // startingId omitted → cleared.
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Could not start the challenge.');
      return false;
    }
  }

  /// Completes a started challenge via POST /api/challenges/{id}/complete. On
  /// success the id is removed from [ChallengeState.activeChallengeIds].
  /// Returns `true` on success, `false` otherwise (reason in
  /// [ChallengeState.error]).
  Future<bool> completeChallenge(String id) async {
    state = state.copyWith(completingId: id);
    try {
      await ref.read(apiClientProvider).post(ApiEndpoints.challengeComplete(id));
      state = state.copyWith(
        activeChallengeIds:
            state.activeChallengeIds.where((c) => c != id).toSet(),
        // completingId omitted → cleared.
      );
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
