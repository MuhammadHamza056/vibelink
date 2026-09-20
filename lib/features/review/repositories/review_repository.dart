import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/review_model.dart';

class ReviewRepository {
  ReviewRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<List<ReviewModel>> fetchMyReviews() async {
    final res = await _client.get(ApiEndpoints.reviewsMine);
    final data = res['body'] ?? res;
    final rawList = data is List
        ? data
        : (data is Map && data['reviews'] is List
            ? data['reviews'] as List
            : const []);

    return rawList
        .whereType<Map<String, dynamic>>()
        .map(ReviewModel.fromJson)
        .toList();
  }

  Future<ReviewModel> submitReview({
    required int rating,
    required String comment,
    String appVersion = '1.0.0',
    String deviceInfo = '',
  }) async {
    final res = await _client.post(
      ApiEndpoints.reviews,
      body: {
        'rating': rating,
        'comment': comment,
        'appVersion': appVersion,
        'deviceInfo': deviceInfo,
      },
    );

    final data = res['body'] ?? res;
    if (data is Map<String, dynamic>) {
      return ReviewModel.fromJson(data);
    }
    return ReviewModel(rating: rating, comment: comment, id: '');
  }
}

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(client: ref.watch(apiClientProvider));
});
