import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/user_model.dart';

class ProfileRepository {
  ProfileRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<UserModel> fetchProfile() async {
    final res = await _client.get(ApiEndpoints.profile);
    final body = res['body'];
    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected profile response.');
    }
    return UserModel.fromJson(body);
  }

  Future<List<String>> fetchVibeTags() async {
    try {
      final res = await _client.get(ApiEndpoints.profileVibeTags);
      final body = res['body'];
      final tags = body is Map<String, dynamic>
          ? (body['tags'] as List?)?.cast<String>()
          : null;
      return tags ?? const [];
    } catch (_) {
      return const [];
    }
  }

  Future<void> updateProfile({
    required Map<String, dynamic> body,
    String? avatarFilePath,
  }) async {
    if (avatarFilePath != null) {
      await _client.patchMultipart(
        ApiEndpoints.profile,
        fields: body,
        filePath: avatarFilePath,
      );
    } else {
      await _client.patch(ApiEndpoints.profile, body: body);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(client: ref.watch(apiClientProvider));
});
