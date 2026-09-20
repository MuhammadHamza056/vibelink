import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/notification_model.dart';

class NotificationsFetchResult {
  const NotificationsFetchResult({
    required this.notifications,
    required this.count,
    required this.pendingCount,
  });

  final List<NotificationModel> notifications;
  final int count;
  final int pendingCount;
}

class NotificationsRepository {
  NotificationsRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<NotificationsFetchResult> fetchNotifications() async {
    final res = await _client.get(ApiEndpoints.notifications);
    final body = res['body'];
    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected notifications response.');
    }
    final list = (body['notifications'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .map(NotificationModel.fromJson)
            .toList() ??
        const <NotificationModel>[];
    return NotificationsFetchResult(
      notifications: list,
      count: (body['count'] ?? list.length) as int,
      pendingCount: (body['pendingCount'] ?? 0) as int,
    );
  }

  Future<void> respondToNotification(String id, {required bool accept}) async {
    await _client.post(
      accept
          ? ApiEndpoints.notificationAccept(id)
          : ApiEndpoints.notificationReject(id),
    );
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>((ref) {
  return NotificationsRepository(client: ref.watch(apiClientProvider));
});
