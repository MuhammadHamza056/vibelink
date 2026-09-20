import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/challenge_model.dart';

class ChallengeRepository {
  ChallengeRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<ChallengeModel>> fetchChallenges() async {
    final res = await _client.get(ApiEndpoints.challenges);
    final body = res['body'] ?? res;
    final rawList = body is List
        ? body
        : (body is Map && body['challenges'] is List
            ? body['challenges'] as List
            : const []);
    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ChallengeModel.fromJson)
        .toList();
  }

  Future<List<ChallengeModel>> fetchCompletedChallenges() async {
    final res = await _client.get(ApiEndpoints.challengesCompleted);
    final body = res['body'] ?? res;
    final rawCompleted = body is List
        ? body
        : (body is Map && body['challenges'] is List
            ? body['challenges'] as List
            : const []);
    return rawCompleted
        .whereType<Map<String, dynamic>>()
        .map(ChallengeModel.fromJson)
        .toList();
  }

  Future<ChallengeModel?> fetchChallengeById(String id) async {
    try {
      final res = await _client.get(ApiEndpoints.challengeById(id));
      final data = res['body'] ?? res;
      if (data is Map<String, dynamic>) {
        return ChallengeModel.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  Future<ChallengeModel?> startChallenge(String id) async {
    try {
      final res = await _client.post(ApiEndpoints.challengeStart(id));
      final challengeData =
          res['challenge'] ?? (res['body'] is Map ? res['body']['challenge'] : null);
      if (challengeData is Map<String, dynamic>) {
        return ChallengeModel.fromJson(challengeData);
      }
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already in progress') || msg.contains('already started')) {
        return null;
      }
      rethrow;
    }
    return null;
  }

  Future<ChallengeModel?> completeChallenge(String id) async {
    try {
      final res = await _client.post(ApiEndpoints.challengeComplete(id));
      final challengeData =
          res['challenge'] ?? (res['body'] is Map ? res['body']['challenge'] : null);
      if (challengeData is Map<String, dynamic>) {
        return ChallengeModel.fromJson(challengeData);
      }
    } on ApiException catch (e) {
      final msg = e.message.toLowerCase();
      if (msg.contains('already completed') ||
          msg.contains('not in progress') ||
          msg.contains('not started')) {
        return null;
      }
      rethrow;
    }
    return null;
  }
}

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepository(client: ref.watch(apiClientProvider));
});
