import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/challenge_model.dart';

class ChallengeCard extends StatelessWidget {
  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.onTap,
    this.isLarge = false,
    this.index = 0,
  });

  final ChallengeModel challenge;
  final VoidCallback onTap;
  final bool isLarge;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (isLarge) return _LargeChallengeCard(challenge: challenge, onTap: onTap);
    return _CompactChallengeCard(challenge: challenge, onTap: onTap, index: index);
  }
}

class _LargeChallengeCard extends StatelessWidget {
  const _LargeChallengeCard({required this.challenge, required this.onTap});

  final ChallengeModel challenge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: challenge.gradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: challenge.gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Text(
                challenge.emoji,
                style: const TextStyle(fontSize: 100),
              ).animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(duration: 3.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (challenge.isDaily)
                        _Tag(label: '⭐ Daily', bg: Colors.white.withValues(alpha: 0.2)),
                      if (challenge.isTrending)
                        _Tag(
                          label: '🔥 Trending',
                          bg: Colors.white.withValues(alpha: 0.2),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    challenge.title,
                    style: AppTextStyles.headlineLarge.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    challenge.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _InfoPill(
                        icon: Icons.timer_rounded,
                        label: AppHelpers.challengeDuration(challenge.durationMinutes),
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        icon: Icons.people_rounded,
                        label: '${challenge.participants}',
                      ),
                      const SizedBox(width: 8),
                      _InfoPill(
                        icon: Icons.bolt_rounded,
                        label: '+${challenge.xpReward} XP',
                        color: AppColors.gold,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: challenge.difficultyColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: challenge.difficultyColor.withValues(alpha: 0.5)),
                        ),
                        child: Text(
                          challenge.difficultyLabel,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: challenge.difficultyColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactChallengeCard extends StatelessWidget {
  const _CompactChallengeCard({
    required this.challenge,
    required this.onTap,
    required this.index,
  });

  final ChallengeModel challenge;
  final VoidCallback onTap;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: challenge.gradient,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                      challenge.emoji,
                      style: const TextStyle(fontSize: 36),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        challenge.title,
                        style: AppTextStyles.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.timer_rounded,
                              size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 3),
                          Text(
                            AppHelpers.challengeDuration(challenge.durationMinutes),
                            style: AppTextStyles.bodySmall,
                          ),
                          const Spacer(),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: challenge.difficultyColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            challenge.difficultyLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: challenge.difficultyColor,
                            ),
                          ),
                        ],
                      ),
                      if (challenge.isTrending) ...[
                        const SizedBox(height: 6),
                        Text(
                          '🔥 Trending',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.pink,
                          ),
                        ),
                      ],
                      if (challenge.isShared) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.people_alt_rounded,
                                size: 12, color: AppColors.green),
                            const SizedBox(width: 4),
                            Text(
                              challenge.sharedWith.length == 1
                                  ? 'Shared with 1'
                                  : 'Shared with ${challenge.sharedWith.length}',
                              style: AppTextStyles.labelSmall
                                  .copyWith(color: AppColors.green),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).slideY(begin: 0.15, end: 0);
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, this.color});
  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: c),
          const SizedBox(width: 4),
          Text(label, style: AppTextStyles.labelSmall.copyWith(color: c)),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label, required this.bg});
  final String label;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}
