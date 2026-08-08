import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../models/challenge_model.dart';
import '../providers/challenge_provider.dart';

import '../../../shared/widgets/review_dialog.dart';

final completedSearchQueryProvider =
    StateProvider.autoDispose<String>((ref) => '');

class CompletedChallengesSheet extends ConsumerWidget {
  const CompletedChallengesSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const CompletedChallengesSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeProvider);
    final completedList = state.completedChallenges;
    final searchQuery = ref.watch(completedSearchQueryProvider);

    final filteredList = completedList.where((c) {
      if (searchQuery.isEmpty) return true;
      final q = searchQuery.toLowerCase();
      return c.title.toLowerCase().contains(q) ||
          c.description.toLowerCase().contains(q) ||
          c.tags.any((t) => t.toLowerCase().contains(q));
    }).toList();

    final totalXpEarned =
        completedList.fold<int>(0, (sum, c) => sum + c.xpReward);

    final size = MediaQuery.of(context).size;

    return Container(
      height: size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Header title, review & close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppColors.primaryGradient.createShader(bounds),
                  child: Text(
                    '🏆 Completed Challenges',
                    style: AppTextStyles.headlineSmall
                        .copyWith(color: Colors.white),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => showReviewDialog(context, isDismissible: true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 16, color: AppColors.gold),
                        const SizedBox(width: 4),
                        Text(
                          'Rate App',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.gold, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Stats Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.2),
                    AppColors.pink.withValues(alpha: 0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  _StatTile(
                    icon: Icons.check_circle_rounded,
                    iconColor: AppColors.green,
                    value: '${completedList.length}',
                    label: 'Completed',
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  _StatTile(
                    icon: Icons.bolt_rounded,
                    iconColor: AppColors.gold,
                    value: '+$totalXpEarned',
                    label: 'XP Earned',
                  ),
                  Container(
                    height: 36,
                    width: 1,
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                  _StatTile(
                    icon: Icons.emoji_events_rounded,
                    iconColor: AppColors.cyan,
                    value: completedList.isEmpty
                        ? 'Bronze'
                        : (completedList.length >= 10 ? 'Gold' : 'Silver'),
                    label: 'Rank Tier',
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0),
          ),
          const SizedBox(height: 12),

          // Leave App Review Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => showReviewDialog(context, isDismissible: true),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 22)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Enjoying VibeLink?',
                            style: AppTextStyles.titleMedium
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            'Leave an App Review to share your feedback!',
                            style: AppTextStyles.labelSmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Review',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Search bar
          if (completedList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (val) =>
                    ref.read(completedSearchQueryProvider.notifier).state = val,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'Search completed challenges...',
                  hintStyle: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textHint),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              size: 18, color: AppColors.textSecondary),
                          onPressed: () {
                            ref
                                .read(completedSearchQueryProvider.notifier)
                                .state = '';
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.cardBg,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primaryLight),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),

          // Challenge list / empty view
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            completedList.isEmpty ? '🎯' : '🔍',
                            style: const TextStyle(fontSize: 54),
                          ).animate().scale(duration: 400.ms),
                          const SizedBox(height: 16),
                          Text(
                            completedList.isEmpty
                                ? 'No Completed Challenges Yet'
                                : 'No Matching Challenges',
                            style: AppTextStyles.titleLarge
                                .copyWith(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            completedList.isEmpty
                                ? 'Complete challenges to earn XP, level up, and showcase your achievements here!'
                                : 'Try searching with a different term',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 8),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      return _CompletedChallengeCard(
                        challenge: item,
                        index: index,
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push('/challenge/${item.id}');
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 5),
              Text(
                value,
                style: AppTextStyles.titleMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CompletedChallengeCard extends StatelessWidget {
  const _CompletedChallengeCard({
    required this.challenge,
    required this.index,
    required this.onTap,
  });

  final ChallengeModel challenge;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: AppColors.green.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.green.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: challenge.gradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  challenge.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          challenge.title,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.green.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              size: 12,
                              color: AppColors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Done',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    challenge.description,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppHelpers.challengeDuration(challenge.durationMinutes),
                        style: AppTextStyles.labelSmall
                            .copyWith(color: AppColors.textHint),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.bolt_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '+${challenge.xpReward} XP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.gold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: (200 + index * 50).ms).slideX(begin: 0.05, end: 0),
    );
  }
}
