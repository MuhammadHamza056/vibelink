import 'user_model.dart';

/// A single connection from GET /api/match/connections. [connectionId] is used
/// to leave the connection; [sharedChallengeId] links to a challenge the two
/// users share, when present.
class ConnectionModel {
  const ConnectionModel({
    required this.connectionId,
    required this.user,
    this.sharedChallengeId,
  });

  final String connectionId;
  final UserModel user;
  final String? sharedChallengeId;

  factory ConnectionModel.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'];
    return ConnectionModel(
      connectionId: (json['connectionId'] ?? '').toString(),
      user: userJson is Map<String, dynamic>
          ? UserModel.fromJson(userJson)
          : UserModel.fromJson(const {}),
      sharedChallengeId: (json['sharedChallengeId'] as String?),
    );
  }
}
