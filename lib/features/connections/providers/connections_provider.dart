import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/connection_model.dart';
import '../../auth/providers/auth_provider.dart';

class ConnectionsState {
  const ConnectionsState({
    this.connections = const [],
    this.count = 0,
    this.isLoading = true,
    this.leavingId,
    this.error,
  });

  final List<ConnectionModel> connections;
  final int count;
  final bool isLoading;

  /// connectionId whose leave (DELETE) request is currently in flight.
  final String? leavingId;
  final String? error;

  ConnectionsState copyWith({
    List<ConnectionModel>? connections,
    int? count,
    bool? isLoading,
    String? leavingId,
    String? error,
  }) {
    return ConnectionsState(
      connections: connections ?? this.connections,
      count: count ?? this.count,
      isLoading: isLoading ?? this.isLoading,
      leavingId: leavingId,
      error: error,
    );
  }
}

class ConnectionsNotifier extends Notifier<ConnectionsState> {
  @override
  ConnectionsState build() {
    _load();
    return const ConnectionsState();
  }

  /// Fetches the user's connections from GET /api/match/connections. The
  /// payload's `body` holds `count` and the `connections` array.
  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final res =
          await ref.read(apiClientProvider).get(ApiEndpoints.matchConnections);
      final body = res['body'];
      if (body is! Map<String, dynamic>) {
        throw ApiException('Unexpected connections response.');
      }
      final list = (body['connections'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ConnectionModel.fromJson)
              .toList() ??
          const <ConnectionModel>[];
      state = state.copyWith(
        connections: list,
        count: (body['count'] ?? list.length) as int,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your connections.',
      );
    }
  }

  /// Re-fetches connections (e.g. pull-to-refresh).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  /// Leaves a connection via DELETE /api/match/connections/{connectionId}. On
  /// success the connection is removed from the list. Returns true on success.
  Future<bool> leave(String connectionId) async {
    state = state.copyWith(leavingId: connectionId, error: null);
    try {
      await ref.read(apiClientProvider).delete(
            ApiEndpoints.matchConnectionLeave(connectionId),
          );
      final remaining = state.connections
          .where((c) => c.connectionId != connectionId)
          .toList();
      state = state.copyWith(
        connections: remaining,
        count: remaining.length,
        leavingId: null,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(leavingId: null, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        leavingId: null,
        error: 'Could not leave the connection.',
      );
      return false;
    }
  }
}

final connectionsProvider =
    NotifierProvider<ConnectionsNotifier, ConnectionsState>(
  ConnectionsNotifier.new,
);
