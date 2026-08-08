import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/toast_util.dart';
import '../../features/review/providers/review_provider.dart';
import 'gradient_button.dart';

/// Shows an App Review Dialog and requests native store review.
Future<void> showReviewDialog(BuildContext context, {bool isDismissible = false}) async {
  final inAppReview = InAppReview.instance;
  if (await inAppReview.isAvailable()) {
    try {
      await inAppReview.requestReview();
    } catch (_) {}
  }

  if (!context.mounted) return;

  return showDialog<void>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (ctx) => _ReviewDialogWidget(isDismissible: isDismissible),
  );
}

class _ReviewDialogWidget extends ConsumerStatefulWidget {
  const _ReviewDialogWidget({this.isDismissible = false});

  final bool isDismissible;

  @override
  ConsumerState<_ReviewDialogWidget> createState() => _ReviewDialogWidgetState();
}

class _ReviewDialogWidgetState extends ConsumerState<_ReviewDialogWidget> {
  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final commentText = _commentController.text.trim();
    final platform = Theme.of(context).platform;
    final deviceInfo = '${platform.name.toUpperCase()} Device';

    final ok = await ref.read(reviewProvider.notifier).submitReview(
          rating: _rating,
          comment: commentText.isEmpty
              ? 'Love the app! Vibe challenges are awesome.'
              : commentText,
          appVersion: '1.0.0',
          deviceInfo: deviceInfo,
        );

    if (!mounted) return;

    if (ok) {
      ToastUtil.success(context, 'Thank you for your review! 🎉');
      Navigator.of(context).pop();
    } else {
      final err = ref.read(reviewProvider).error;
      ToastUtil.error(context, err ?? 'Could not submit review.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSubmitting = ref.watch(reviewProvider.select((s) => s.isSubmitting));

    return PopScope(
      canPop: widget.isDismissible,
      child: AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.isDismissible)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary, size: 20),
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Text('⭐', style: TextStyle(fontSize: 40)),
              ),
              const SizedBox(height: 16),
              Text(
                'First Challenge Completed!',
                style: AppTextStyles.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'How was your experience? Please leave us a rating & review to continue.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // Interactive 5-Star Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  final isFilled = starIndex <= _rating;
                  return IconButton(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(),
                    icon: Icon(
                      isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: isFilled ? AppColors.gold : AppColors.textSecondary,
                      size: 36,
                    ),
                    onPressed: () {
                      setState(() {
                        _rating = starIndex;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 20),
              // Review comment field
              TextField(
                controller: _commentController,
                maxLines: 3,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Share your feedback (e.g. Love the app!)...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cyan),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: GradientButton(
                  label: 'Submit Review ⭐',
                  gradient: AppColors.primaryGradient,
                  isLoading: isSubmitting,
                  onTap: isSubmitting ? null : _submit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
