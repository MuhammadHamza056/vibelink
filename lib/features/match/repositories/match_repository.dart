import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../providers/match_provider.dart';

class MatchRepository {
  MatchRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<void> updateLocation({required double lat, required double lng}) async {
    try {
      await _client.put(
        ApiEndpoints.profileLocation,
        body: {'lat': lat, 'lng': lng},
      );
    } catch (_) {}
  }

  Future<List<MatchCandidate>> fetchNearbyMatches({
    int radius = 5000,
    int limit = 50,
  }) async {
    final res = await _client.get(
      ApiEndpoints.matchNearby,
      query: {'radius': radius, 'limit': limit},
    );
    final body = res['body'];
    final rawMatches =
        body is Map<String, dynamic> ? body['matches'] as List? : null;
    return (rawMatches ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MatchCandidate.fromJson)
        .toList();
  }

  Future<void> connectMatch(String userId) async {
    await _client.post(
      ApiEndpoints.matchConnect,
      body: {'userId': userId},
    );
  }
}

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository(client: ref.watch(apiClientProvider));
});
