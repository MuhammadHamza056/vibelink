import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

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

  /// True while a PATCH /api/profile update is in flight.
  final bool isSaving;
  final double burnoutRiskLevel;

  /// All selectable vibe tags from GET /api/profile/vibe-tags.
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

  /// Fetches the signed-in user from GET /api/profile. The payload is wrapped
  /// in a `body` object, which we unwrap into [UserModel]. The selectable vibe
  /// tags are loaded concurrently and never block the profile itself.
  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated ||
        auth.accessToken == null ||
        auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    final client = ref.read(apiClientProvider);

    // Best-effort: fetch the list of selectable vibe tags alongside the profile.
    _fetchVibeTags(client);

    try {
      final res = await client.get(ApiEndpoints.profile);
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

  /// Loads selectable vibe tags from GET /api/profile/vibe-tags. The response
  /// wraps the list in `body.tags`. Failures are swallowed since the screen
  /// falls back to the built-in [AppConstants.vibeTags] list.
  Future<void> _fetchVibeTags(ApiClient client) async {
    try {
      final res = await client.get(ApiEndpoints.profileVibeTags);
      final body = res['body'];
      final tags = body is Map<String, dynamic>
          ? (body['tags'] as List?)?.cast<String>()
          : null;
      if (tags != null && tags.isNotEmpty) {
        state = state.copyWith(availableTags: tags);
      }
    } catch (_) {
      // Ignore — the screen falls back to a built-in tag list.
    }
  }

  /// Re-fetches the profile (e.g. pull-to-refresh).
  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  /// Persists profile changes via PATCH /api/profile. Only the fields passed in
  /// are sent, so callers can update a single property at a time. The updated
  /// user is read back from the response `body`, falling back to an optimistic
  /// local merge when the server echoes nothing.
  ///
  /// Returns true on success; on failure the state is rolled back to [previous]
  /// and [ProfileState.error] is populated.
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
      // A picked file replaces avatarUrl; don't send both.
      if (avatarUrl != null && avatarFilePath == null) 'avatarUrl': avatarUrl,
      if (vibeTags != null) 'vibeTags': vibeTags,
      if (safetyPulseEnabled != null) 'safetyPulseEnabled': safetyPulseEnabled,
      if (isOnBurnoutGuard != null) 'isOnBurnoutGuard': isOnBurnoutGuard,
      if (hasSeenOnboarding != null) 'hasSeenOnboarding': hasSeenOnboarding,
    };
    if (body.isEmpty && avatarFilePath == null) return true;

    // Optimistically reflect the change while the request is in flight. The
    // avatar isn't reflected optimistically — we wait for the server's hosted
    // URL in the response.
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
      final client = ref.read(apiClientProvider);
      if (avatarFilePath != null) {
        await client.patchMultipart(
          ApiEndpoints.profile,
          fields: body,
          filePath: avatarFilePath,
        );
      } else {
        await client.patch(ApiEndpoints.profile, body: body);
      }
      // Re-fetch the authoritative profile from GET /api/profile so the UI
      // reflects exactly what the server stored (e.g. the hosted avatar URL).
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

  /// Toggles a single vibe tag and persists the new set via PATCH /api/profile.
  Future<bool> toggleVibeTag(String tag) {
    final current = state.user;
    if (current == null) return Future.value(false);
    final tags = List<String>.from(current.vibeTags);
    tags.contains(tag) ? tags.remove(tag) : tags.add(tag);
    return updateProfile(vibeTags: tags);
  }

  /// Replaces the full vibe-tag set and persists it via PATCH /api/profile.
  Future<bool> updateVibeTags(List<String> tags) =>
      updateProfile(vibeTags: tags);

  Future<void> signOut(void Function() onSignOut) async {
    onSignOut();
  }
}

final profileProvider =
    NotifierProvider<ProfileNotifier, ProfileState>(ProfileNotifier.new);

/// Transient state for the Edit Profile sheet: the picked photo and the
/// selected vibe tags. Auto-disposes so it resets each time the sheet is
class EditProfileForm {
  const EditProfileForm({this.pickedImagePath, this.selectedTags = const {}});

  final String? pickedImagePath;
  final Set<String> selectedTags;
}

/// Outcome of an avatar pick, so the UI can decide whether to surface an error.
enum PickPhotoResult { picked, cancelled, failed }

class EditProfileFormNotifier
    extends AutoDisposeFamilyNotifier<EditProfileForm, List<String>> {
  final ImagePicker _picker = ImagePicker();

  /// [initialTags] are the profile's current vibe tags; they seed the
  /// selection without mutating the provider during widget build.
  @override
  EditProfileForm build(List<String> initialTags) {
    return EditProfileForm(selectedTags: {...initialTags});
  }

  /// Picks a photo from [source] (camera/gallery) and stores its path. Returns
  /// the outcome so the caller can show an error toast when it fails.
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

  /// Sets (or clears, when [path] is null) the freshly picked photo.
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
