import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/user_model.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = true,
    this.burnoutRiskLevel = 0.0,
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final double burnoutRiskLevel;
  final String? error;

  bool get shouldRestToday => burnoutRiskLevel >= 0.7;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    double? burnoutRiskLevel,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      burnoutRiskLevel: burnoutRiskLevel ?? this.burnoutRiskLevel,
      error: error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _load();
    return const ProfileState();
  }

  /// Fetches the signed-in user from GET /api/profile. The payload is wrapped
  /// in a `body` object, which we unwrap into [UserModel].
  Future<void> _load() async {
    try {
      final res = await ref.read(apiClientProvider).get(ApiEndpoints.profile);
      final body = res['body'];
      if (body is! Map<String, dynamic>) {
        throw ApiException('Unexpected profile response.');
      }
      final user = UserModel.fromJson(body);
      state = state.copyWith(
        user: user,
        isLoading: false,
        // Burnout risk scales with the active streak until the guard threshold.
        burnoutRiskLevel: user.isOnBurnoutGuard ? 0.85 : 0.25,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your profile.',
      );
    }
  }

  /// Re-fetches the profile (e.g. pull-to-refresh).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  Future<void> updateVibeTags(List<String> tags) async {
    if (state.user == null) return;
    state = state.copyWith(
      user: state.user!.copyWith(vibeTags: tags),
    );
  }

  Future<void> signOut(void Function() onSignOut) async {
    onSignOut();
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);
