import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Row of three profile stat boxes (challenges, matches, memories).
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key, required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Challenges',
          value: '${user.challengesCompleted}',
          emoji: '⚡',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Matches',
          value: '${user.matchesCount}',
          emoji: '💫',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Memories',
          value: '${user.memoriesCount}',
          emoji: '💭',
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.emoji});
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.headlineMedium),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}
