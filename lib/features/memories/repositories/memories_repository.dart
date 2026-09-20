import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/memory_model.dart';

class MemoriesRepository {
  MemoriesRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<MemoryModel>> fetchMemories() async {
    final res = await _client.get(ApiEndpoints.memories);
    final body = res['body'];
    return (body as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(MemoryModel.fromJson)
            .toList() ??
        const <MemoryModel>[];
  }

  Future<void> createMemory({
    required String title,
    required String caption,
    String? imageFilePath,
    List<String> vibeTags = const [],
  }) async {
    if (imageFilePath != null && imageFilePath.isNotEmpty) {
      await _client.postMultipart(
        ApiEndpoints.memories,
        fields: {
          'title': title,
          'caption': caption,
          'vibeTags': jsonEncode(vibeTags),
        },
        filePath: imageFilePath,
      );
    } else {
      await _client.post(
        ApiEndpoints.memories,
        body: {
          'title': title,
          'caption': caption,
          'vibeTags': vibeTags,
        },
      );
    }
  }

  Future<void> deleteMemory(String id) async {
    await _client.delete(ApiEndpoints.memoryById(id));
  }
}

final memoriesRepositoryProvider = Provider<MemoriesRepository>((ref) {
  return MemoriesRepository(client: ref.watch(apiClientProvider));
});
