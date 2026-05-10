import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/toast_util.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/challenge_provider.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenge = ref.watch(challengeByIdProvider(id));

    if (challenge == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Challenge not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: challenge.gradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -20,
                      right: -20,
                      child: Text(
                        challenge.emoji,
                        style: const TextStyle(fontSize: 160),
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .scale(
                            duration: 3.seconds,
                            begin: const Offset(1, 1),
                            end: const Offset(1.08, 1.08),
                          ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (challenge.isDaily)
                                _Tag(label: '⭐ Daily'),
                              if (challenge.isTrending)
                                _Tag(label: '🔥 Trending'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge.title,
                            style: AppTextStyles.displayMedium
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick info row
                _InfoRow(challenge: challenge)
                    .animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // Description
                Text('About this challenge',
                    style: AppTextStyles.titleLarge)
                    .animate(delay: 100.ms).fadeIn(),
                const SizedBox(height: 10),
                Text(
                  challenge.description,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                // Tags
                Text('Tags', style: AppTextStyles.titleLarge)
                    .animate(delay: 150.ms).fadeIn(),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: challenge.tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        '#$t',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 28),

                // Reward
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+${challenge.xpReward} XP',
                            style: AppTextStyles.headlineMedium
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            'Complete to earn this reward',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: 200.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),

                // CTA
                GradientButton(
                  label: 'Start Challenge 🚀',
                  gradient: challenge.gradient,
                  onTap: () {
                    ref
                        .read(challengeProvider.notifier)
                        .startChallenge(challenge);
                    ToastUtil.success(
                      context,
                      '${challenge.emoji} Challenge started! Good luck!',
                    );
                    Navigator.of(context).pop();
                  },
                  width: double.infinity,
                  height: 58,
                ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 12),
                OutlineButton(
                  label: 'Save for Later',
                  onTap: () {
                    ToastUtil.info(context, 'Saved to your list');
                    Navigator.of(context).pop();
                  },
                  color: AppColors.textSecondary,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.challenge});
  final dynamic challenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.timer_rounded,
          label: AppHelpers.challengeDuration(challenge.durationMinutes),
          color: AppColors.cyan,
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.people_rounded,
          label: '${challenge.participants} joined',
          color: AppColors.green,
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.circle,
          label: challenge.difficultyLabel,
          color: challenge.difficultyColor,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}
