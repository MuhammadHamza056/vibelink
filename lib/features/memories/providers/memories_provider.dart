import 'dart:convert';
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

  /// Creates a memory via POST /api/memories, then re-fetches the full list
  /// from GET /api/memories so the grid shows fresh server data. Returns true
  /// on success. When [imageFilePath] is given the request is sent as
  /// multipart/form-data with the picked image attached; otherwise plain JSON.
  Future<bool> createMemory({
    required String title,
    required String caption,
    String? imageFilePath,
    List<String> vibeTags = const [],
  }) async {
    try {
      final client = ref.read(apiClientProvider);

      if (imageFilePath != null && imageFilePath.isNotEmpty) {
        // Multipart can't carry a real array — multer would give the DTO a
        // bare string for one tag and nothing for none. Send it as a single
        // JSON string; the backend parses it back into an array.
        await client.postMultipart(
          ApiEndpoints.memories,
          fields: {
            'title': title,
            'caption': caption,
            'vibeTags': jsonEncode(vibeTags),
          },
          filePath: imageFilePath,
        );
      } else {
        // Plain JSON preserves the array natively.
        await client.post(
          ApiEndpoints.memories,
          body: {
            'title': title,
            'caption': caption,
            'vibeTags': vibeTags,
          },
        );
      }

      // Pull the fresh list from the server instead of trusting the POST body.
      await _load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Could not save your memory.');
      return false;
    }
  }

  void deleteMemory(String id) {
    state = state.copyWith(
      memories: state.memories.where((m) => m.id != id).toList(),
    );
  }
}

final memoriesProvider =
    NotifierProvider<MemoriesNotifier, MemoriesState>(MemoriesNotifier.new);
