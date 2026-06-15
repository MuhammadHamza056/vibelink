import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/memory_model.dart';

class MemoriesState {
  const MemoriesState({
    this.memories = const [],
    this.isLoading = true,
    this.error,
  });

  final List<MemoryModel> memories;
  final bool isLoading;
  final String? error;

  MemoriesState copyWith({
    List<MemoryModel>? memories,
    bool? isLoading,
    String? error,
  }) {
    return MemoriesState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MemoriesNotifier extends Notifier<MemoriesState> {
  @override
  MemoriesState build() {
    _load();
    return const MemoriesState();
  }

  /// Fetches the user's memories from GET /api/memories. The payload's `body`
  /// is a JSON array, which we map into [MemoryModel]s.
  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get(ApiEndpoints.memories);
      final body = res['body'];
      final memories = (body as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MemoryModel.fromJson)
              .toList() ??
          const <MemoryModel>[];
      state = state.copyWith(memories: memories, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your memories.',
      );
    }
  }

  /// Re-fetches memories (e.g. pull-to-refresh).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  void addMemory(MemoryModel memory) {
    state = state.copyWith(memories: [memory, ...state.memories]);
  }

  void deleteMemory(String id) {
    state = state.copyWith(
      memories: state.memories.where((m) => m.id != id).toList(),
    );
  }
}

final memoriesProvider =
    NotifierProvider<MemoriesNotifier, MemoriesState>(MemoriesNotifier.new);
