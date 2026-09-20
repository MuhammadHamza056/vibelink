import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/connection_model.dart';

class ConnectionsFetchResult {
  const ConnectionsFetchResult({
    required this.connections,
    required this.count,
  });

  final List<ConnectionModel> connections;
  final int count;
}

class ConnectionsRepository {
  ConnectionsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<ConnectionsFetchResult> fetchConnections() async {
    final res = await _client.get(ApiEndpoints.matchConnections);
    final body = res['body'];
    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected connections response.');
    }
    final list = (body['connections'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(ConnectionModel.fromJson)
            .toList() ??
        const <ConnectionModel>[];
    return ConnectionsFetchResult(
      connections: list,
      count: (body['count'] ?? list.length) as int,
    );
  }

  Future<void> leaveConnection(String connectionId) async {
    await _client.delete(ApiEndpoints.matchConnectionLeave(connectionId));
  }
}

final connectionsRepositoryProvider = Provider<ConnectionsRepository>((ref) {
  return ConnectionsRepository(client: ref.watch(apiClientProvider));
});
