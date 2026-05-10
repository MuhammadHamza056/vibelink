import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/user_model.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = true,
    this.burnoutRiskLevel = 0.0,
  });

  final UserModel? user;
  final bool isLoading;
  final double burnoutRiskLevel;

  bool get shouldRestToday => burnoutRiskLevel >= 0.7;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    double? burnoutRiskLevel,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      burnoutRiskLevel: burnoutRiskLevel ?? this.burnoutRiskLevel,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    _load();
    return const ProfileState();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 600));
    state = state.copyWith(
      user: UserModel.mock,
      isLoading: false,
      burnoutRiskLevel: 0.25,
    );
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
