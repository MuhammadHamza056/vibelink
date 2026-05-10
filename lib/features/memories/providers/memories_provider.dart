import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/memory_model.dart';

class MemoriesState {
  const MemoriesState({
    this.memories = const [],
    this.isLoading = true,
  });

  final List<MemoryModel> memories;
  final bool isLoading;

  MemoriesState copyWith({
    List<MemoryModel>? memories,
    bool? isLoading,
  }) {
    return MemoriesState(
      memories: memories ?? this.memories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MemoriesNotifier extends Notifier<MemoriesState> {
  @override
  MemoriesState build() {
    _load();
    return const MemoriesState();
  }

  Future<void> _load() async {
    await Future.delayed(const Duration(milliseconds: 700));
    state = state.copyWith(
      memories: MemoryModel.mockList,
      isLoading: false,
    );
  }

  void addMemory(MemoryModel memory) {
    state = state.copyWith(memories: [memory, ...state.memories]);
  }

  void deleteMemory(String id) {
    state = state.copyWith(
      memories: state.memories.where((m) => m.id != id).toList(),
    );
  }
}

final memoriesProvider =
    NotifierProvider<MemoriesNotifier, MemoriesState>(MemoriesNotifier.new);
