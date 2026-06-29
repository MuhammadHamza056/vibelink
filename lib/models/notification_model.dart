import 'user_model.dart';

/// A single entry from GET /api/notifications. The optional [user] is the
/// person the notification relates to (e.g. who sent a connection request).
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.status,
    required this.title,
    required this.message,
    required this.actionable,
    required this.createdAt,
    this.user,
  });

  final String id;

  /// e.g. "connection_request".
  final String type;

  /// e.g. "pending".
  final String status;
  final String title;
  final String message;

  /// Whether the notification expects the user to act on it.
  final bool actionable;
  final DateTime? createdAt;
  final UserModel? user;

  bool get isPending => status == 'pending';

  NotificationModel copyWith({String? status}) {
    return NotificationModel(
      id: id,
      type: type,
      status: status ?? this.status,
      title: title,
      message: message,
      actionable: actionable,
      createdAt: createdAt,
      user: user,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return NotificationModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      type: (json['type'] ?? '') as String,
      status: (json['status'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      message: (json['message'] ?? '') as String,
      actionable: (json['actionable'] ?? false) as bool,
      createdAt: DateTime.tryParse('${json['createdAt']}'),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : null,
    );
  }
}
