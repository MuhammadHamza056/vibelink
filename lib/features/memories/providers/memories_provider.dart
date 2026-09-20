import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/network/api_client.dart';
import '../../../models/memory_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/memories_repository.dart';

class MemoriesState {
  const MemoriesState({
    this.memories = const [],
    this.isLoading = true,
    this.error,
  });

  final List<MemoryModel> memories;
  final bool isLoading;
  final String? error;

  MemoriesState copyWith({
    List<MemoryModel>? memories,
    bool? isLoading,
    String? error,
  }) {
    return MemoriesState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MemoriesNotifier extends Notifier<MemoriesState> {
  @override
  MemoriesState build() {
    Future.microtask(() => _load());
    return const MemoriesState();
  }

  Future<void> _load() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      state = state.copyWith(isLoading: false);
      return;
    }
    try {
      final repo = ref.read(memoriesRepositoryProvider);
      final memories = await repo.fetchMemories();
      state = state.copyWith(memories: memories, isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'Could not load your memories.',
      );
    }
  }

  Future<void> refresh() {
    state = state.copyWith(isLoading: true, error: null);
    return _load();
  }

  void addMemory(MemoryModel memory) {
    state = state.copyWith(memories: [memory, ...state.memories]);
  }

  Future<bool> createMemory({
    required String title,
    required String caption,
    String? imageFilePath,
    List<String> vibeTags = const [],
  }) async {
    try {
      final repo = ref.read(memoriesRepositoryProvider);
      await repo.createMemory(
        title: title,
        caption: caption,
        imageFilePath: imageFilePath,
        vibeTags: vibeTags,
      );

      await _load();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Could not save your memory.');
      return false;
    }
  }

  Future<bool> deleteMemory(String id) async {
    final previous = state.memories;
    state = state.copyWith(
      memories: state.memories.where((m) => m.id != id).toList(),
      error: null,
    );
    try {
      final repo = ref.read(memoriesRepositoryProvider);
      await repo.deleteMemory(id);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(memories: previous, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        memories: previous,
        error: 'Could not delete the memory. Please try again.',
      );
      return false;
    }
  }
}

final memoriesProvider =
    NotifierProvider<MemoriesNotifier, MemoriesState>(MemoriesNotifier.new);

class AddMemoryFormState {
  const AddMemoryFormState({
    this.pickedImagePath,
    this.selectedTags = const {},
    this.isSubmitting = false,
  });

  final String? pickedImagePath;
  final Set<String> selectedTags;
  final bool isSubmitting;

  AddMemoryFormState copyWith({
    String? pickedImagePath,
    Set<String>? selectedTags,
    bool? isSubmitting,
    bool clearImage = false,
  }) {
    return AddMemoryFormState(
      pickedImagePath: clearImage ? null : (pickedImagePath ?? this.pickedImagePath),
      selectedTags: selectedTags ?? this.selectedTags,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class AddMemoryFormNotifier extends AutoDisposeNotifier<AddMemoryFormState> {
  final ImagePicker _picker = ImagePicker();

  @override
  AddMemoryFormState build() => const AddMemoryFormState();

  Future<void> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1280,
        imageQuality: 85,
      );
      if (file == null) return;
      state = state.copyWith(pickedImagePath: file.path);
    } catch (_) {}
  }

  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  void toggleTag(String tag) {
    final next = {...state.selectedTags};
    next.contains(tag) ? next.remove(tag) : next.add(tag);
    state = state.copyWith(selectedTags: next);
  }

  void setSubmitting(bool value) {
    state = state.copyWith(isSubmitting: value);
  }
}

final addMemoryFormProvider =
    AutoDisposeNotifierProvider<AddMemoryFormNotifier, AddMemoryFormState>(
  AddMemoryFormNotifier.new,
);
