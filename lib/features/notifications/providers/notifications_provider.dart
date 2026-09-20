import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/notification_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/notifications_repository.dart';

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
  final int pendingCount;
  final bool isLoading;
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

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      final result = await repo.fetchNotifications();
      state = state.copyWith(
        notifications: result.notifications,
        count: result.count,
        pendingCount: result.pendingCount,
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

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  Future<bool> accept(String id) => _respond(id, accept: true);

  Future<bool> reject(String id) => _respond(id, accept: false);

  Future<bool> _respond(String id, {required bool accept}) async {
    state = state.copyWith(
      respondingId: id,
      respondingIsAccept: accept,
      error: null,
    );
    try {
      final repo = ref.read(notificationsRepositoryProvider);
      await repo.respondToNotification(id, accept: accept);

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
