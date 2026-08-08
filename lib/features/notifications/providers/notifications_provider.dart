import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';

class NotificationsState {
  const NotificationsState({
    this.notifications = const [],
    this.count = 0,
    this.pendingCount = 0,
    this.isLoading = true,
    this.respondingId,
    this.respondingIsAccept = false,
    this.error,
  });

  final List<NotificationModel> notifications;
  final int count;

  /// Number of notifications still awaiting action (drives the bell badge).
  final int pendingCount;
  final bool isLoading;

  /// Id of the notification whose accept/reject request is in flight (null when
  /// none), and whether that in-flight action is an accept.
  final String? respondingId;
  final bool respondingIsAccept;
  final String? error;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? count,
    int? pendingCount,
    bool? isLoading,
    String? respondingId,
    bool? respondingIsAccept,
    String? error,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      count: count ?? this.count,
      pendingCount: pendingCount ?? this.pendingCount,
      isLoading: isLoading ?? this.isLoading,
      respondingId: respondingId,
      respondingIsAccept: respondingIsAccept ?? this.respondingIsAccept,
      error: error,
    );
  }
}

class NotificationsNotifier extends Notifier<NotificationsState> {
  @override
  NotificationsState build() {
    Future.microtask(() => _load());
    return const NotificationsState();
  }

  /// Fetches the user's notifications from GET /api/notifications. The payload's
  /// `body` holds `count`, `pendingCount` and the `notifications` array.
  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final res =
          await ref.read(apiClientProvider).get(ApiEndpoints.notifications);
      final body = res['body'];
      if (body is! Map<String, dynamic>) {
        throw ApiException('Unexpected notifications response.');
      }
      final list = (body['notifications'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(NotificationModel.fromJson)
              .toList() ??
          const <NotificationModel>[];
      state = state.copyWith(
        notifications: list,
        count: (body['count'] ?? list.length) as int,
        pendingCount: (body['pendingCount'] ?? 0) as int,
        isLoading: false,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your notifications.',
      );
    }
  }

  /// Re-fetches notifications (e.g. pull-to-refresh).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  /// Accepts the connection request via POST /api/notifications/{id}/accept.
  Future<bool> accept(String id) => _respond(id, accept: true);

  /// Rejects the connection request via POST /api/notifications/{id}/reject.
  Future<bool> reject(String id) => _respond(id, accept: false);

  Future<bool> _respond(String id, {required bool accept}) async {
    state = state.copyWith(
      respondingId: id,
      respondingIsAccept: accept,
      error: null,
    );
    try {
      await ref.read(apiClientProvider).post(
            accept
                ? ApiEndpoints.notificationAccept(id)
                : ApiEndpoints.notificationReject(id),
          );
      // Reflect the resolved status locally so the buttons disappear and the
      // pending count (and bell badge) update without a full refetch.
      final updated = [
        for (final n in state.notifications)
          n.id == id ? n.copyWith(status: accept ? 'accepted' : 'rejected') : n,
      ];
      state = state.copyWith(
        notifications: updated,
        pendingCount: updated.where((n) => n.isPending).length,
        respondingId: null,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(respondingId: null, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        respondingId: null,
        error: 'Could not update the request. Please try again.',
      );
      return false;
    }
  }
}

final notificationsProvider =
    NotifierProvider<NotificationsNotifier, NotificationsState>(
  NotificationsNotifier.new,
);
