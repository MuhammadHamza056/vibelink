import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/home_model.dart';
import '../../../models/user_model.dart';

class HomeRepository {
  HomeRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<HomeModel?> fetchHome() async {
    try {
      final res = await _client.get(ApiEndpoints.home);
      final body = res['body'];
      if (body is! Map<String, dynamic>) return null;
      final home = HomeModel.fromJson(body);
      home.suggestedChallenges.shuffle();
      return home;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> fetchProfile() async {
    try {
      final res = await _client.get(ApiEndpoints.profile);
      final body = res['body'];
      return body is Map<String, dynamic> ? UserModel.fromJson(body) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> syncLocation({required double lat, required double lng}) async {
    try {
      await _client.put(
        ApiEndpoints.profileLocation,
        body: {'lat': lat, 'lng': lng},
      );
    } catch (_) {
      // Best-effort location sync swallower
    }
  }

  Future<bool> triggerEmergencySOS({double? lat, double? lng}) async {
    try {
      final res = await _client.post(
        ApiEndpoints.notificationEmergency,
        body: {
          if (lat != null) 'lat': lat,
          if (lng != null) 'lng': lng,
          'message': 'Emergency SOS alert triggered from Safety Pulse!',
        },
      );
      final isSuccess = res['success'] == true ||
          res['statusCode'] == 200 ||
          res['statusCode'] == 201 ||
          (res['body'] is Map && res['body']['success'] == true);
      return isSuccess;
    } on ApiException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(client: ref.watch(apiClientProvider));
});
