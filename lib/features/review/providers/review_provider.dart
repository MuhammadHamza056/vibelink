import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../models/review_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../repositories/review_repository.dart';

class ReviewState {
  const ReviewState({
    this.reviews = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.hasReviewed = false,
    this.error,
  });

  final List<ReviewModel> reviews;
  final bool isLoading;
  final bool isSubmitting;
  final bool hasReviewed;
  final String? error;

  ReviewState copyWith({
    List<ReviewModel>? reviews,
    bool? isLoading,
    bool? isSubmitting,
    bool? hasReviewed,
    String? error,
  }) {
    return ReviewState(
      reviews: reviews ?? this.reviews,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasReviewed: hasReviewed ?? this.hasReviewed,
      error: error,
    );
  }
}

class ReviewNotifier extends Notifier<ReviewState> {
  @override
  ReviewState build() {
    Future.microtask(() => checkMyReviews());
    return const ReviewState();
  }

  Future<void> checkMyReviews() async {
    final auth = ref.read(authProvider);
    if (!auth.isAuthenticated || auth.accessToken == null || auth.accessToken!.isEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      final reviews = await repo.fetchMyReviews();

      state = state.copyWith(
        reviews: reviews,
        hasReviewed: reviews.isNotEmpty,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> submitReview({
    required int rating,
    required String comment,
    String appVersion = '1.0.0',
    String deviceInfo = '',
  }) async {
    state = state.copyWith(isSubmitting: true, error: null);
    try {
      final repo = ref.read(reviewRepositoryProvider);
      final review = await repo.submitReview(
        rating: rating,
        comment: comment,
        appVersion: appVersion,
        deviceInfo: deviceInfo,
      );

      final updated = [review, ...state.reviews];

      state = state.copyWith(
        reviews: updated,
        hasReviewed: true,
        isSubmitting: false,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isSubmitting: false,
        error: 'Could not submit review. Please try again.',
      );
      return false;
    }
  }
}

final reviewProvider =
    NotifierProvider<ReviewNotifier, ReviewState>(ReviewNotifier.new);
