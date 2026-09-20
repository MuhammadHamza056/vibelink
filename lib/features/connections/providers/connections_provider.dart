import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/connection_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/connections_repository.dart';

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
    Future.microtask(() => _load());
    return const ConnectionsState();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final repo = ref.read(connectionsRepositoryProvider);
      final result = await repo.fetchConnections();
      state = state.copyWith(
        connections: result.connections,
        count: result.count,
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

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  Future<bool> leave(String connectionId) async {
    state = state.copyWith(leavingId: connectionId, error: null);
    try {
      final repo = ref.read(connectionsRepositoryProvider);
      await repo.leaveConnection(connectionId);
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
