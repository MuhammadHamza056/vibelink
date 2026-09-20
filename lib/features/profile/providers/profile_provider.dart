import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/profile_repository.dart';

class ProfileState {
  const ProfileState({
    this.user,
    this.isLoading = true,
    this.isSaving = false,
    this.burnoutRiskLevel = 0.0,
    this.availableTags = const [],
    this.error,
  });

  final UserModel? user;
  final bool isLoading;
  final bool isSaving;
  final double burnoutRiskLevel;
  final List<String> availableTags;
  final String? error;

  bool get shouldRestToday => burnoutRiskLevel >= 0.7;

  ProfileState copyWith({
    UserModel? user,
    bool? isLoading,
    bool? isSaving,
    double? burnoutRiskLevel,
    List<String>? availableTags,
    String? error,
  }) {
    return ProfileState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      burnoutRiskLevel: burnoutRiskLevel ?? this.burnoutRiskLevel,
      availableTags: availableTags ?? this.availableTags,
      error: error,
    );
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() {
    Future.microtask(() => _load());
    return const ProfileState();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated ||
        auth.accessToken == null ||
        auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final repo = ref.read(profileRepositoryProvider);

    _fetchVibeTags(repo);

    try {
      final user = await repo.fetchProfile();
      state = state.copyWith(
        user: user,
        isLoading: false,
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

  Future<void> _fetchVibeTags(ProfileRepository repo) async {
    try {
      final tags = await repo.fetchVibeTags();
      if (tags.isNotEmpty) {
        state = state.copyWith(availableTags: tags);
      }
    } catch (_) {}
  }

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  Future<bool> updateProfile({
    String? username,
    String? avatarUrl,
    List<String>? vibeTags,
    bool? safetyPulseEnabled,
    bool? isOnBurnoutGuard,
    bool? hasSeenOnboarding,
    String? avatarFilePath,
  }) async {
    final current = state.user;
    if (current == null) return false;

    final body = <String, dynamic>{
      if (username != null) 'username': username,
      if (avatarUrl != null && avatarFilePath == null) 'avatarUrl': avatarUrl,
      if (vibeTags != null) 'vibeTags': vibeTags,
      if (safetyPulseEnabled != null) 'safetyPulseEnabled': safetyPulseEnabled,
      if (isOnBurnoutGuard != null) 'isOnBurnoutGuard': isOnBurnoutGuard,
      if (hasSeenOnboarding != null) 'hasSeenOnboarding': hasSeenOnboarding,
    };
    if (body.isEmpty && avatarFilePath == null) return true;

    final previous = state;
    final optimistic = current.copyWith(
      username: username,
      avatarUrl: avatarFilePath == null ? avatarUrl : null,
      vibeTags: vibeTags,
      safetyPulseEnabled: safetyPulseEnabled,
      isOnBurnoutGuard: isOnBurnoutGuard,
      hasSeenOnboarding: hasSeenOnboarding,
    );
    state = state.copyWith(user: optimistic, isSaving: true, error: null);

    try {
      final repo = ref.read(profileRepositoryProvider);
      await repo.updateProfile(body: body, avatarFilePath: avatarFilePath);

      await _load();
      state = state.copyWith(isSaving: false);
      return true;
    } on ApiException catch (e) {
      state = previous.copyWith(isSaving: false, error: e.message);
      return false;
    } catch (_) {
      state = previous.copyWith(
        isSaving: false,
        error: 'Could not update your profile.',
      );
      return false;
    }
  }

  Future<bool> toggleVibeTag(String tag) {
    final current = state.user;
    if (current == null) return Future.value(false);
    final tags = List<String>.from(current.vibeTags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    return updateProfile(vibeTags: tags);
  }

  Future<bool> updateVibeTags(List<String> tags) =>
      updateProfile(vibeTags: tags);

  Future<void> signOut(void Function() onSignOut) async {
    onSignOut();
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

class EditProfileForm {
  const EditProfileForm({this.pickedImagePath, this.selectedTags = const {}});

  final String? pickedImagePath;
  final Set<String> selectedTags;
}

enum PickPhotoResult { picked, cancelled, failed }

class EditProfileFormNotifier
    extends AutoDisposeFamilyNotifier<EditProfileForm, List<String>> {
  final ImagePicker _picker = ImagePicker();

  @override
  EditProfileForm build(List<String> initialTags) {
    return EditProfileForm(selectedTags: {...initialTags});
  }

  Future<PickPhotoResult> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (file == null) return PickPhotoResult.cancelled;
      setImage(file.path);
      return PickPhotoResult.picked;
    } catch (_) {
      return PickPhotoResult.failed;
    }
  }

  void setImage(String? path) {
    state = EditProfileForm(
      pickedImagePath: path,
      selectedTags: state.selectedTags,
    );
  }

  void toggleTag(String tag) {
    final next = {...state.selectedTags};
    next.contains(tag) ? next.remove(tag) : next.add(tag);
    state = EditProfileForm(
      pickedImagePath: state.pickedImagePath,
      selectedTags: next,
    );
  }
}

final editProfileFormProvider = AutoDisposeNotifierProvider.family<
    EditProfileFormNotifier, EditProfileForm, List<String>>(
  EditProfileFormNotifier.new,
);
