import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

class MemoryModel {
  const MemoryModel({
    required this.id,
    required this.challengeTitle,
    required this.challengeEmoji,
    required this.note,
    required this.partnerUsername,
    required this.createdAt,
    required this.gradientIndex,
    this.imageUrl,
  });

  final String id;
  final String challengeTitle;
  final String challengeEmoji;
  final String note;
  final String partnerUsername;
  final DateTime createdAt;
  final int gradientIndex;
  final String? imageUrl;

  LinearGradient get gradient => _gradients[gradientIndex % _gradients.length];

  static const List<LinearGradient> _gradients = [
    AppColors.primaryGradient,
    AppColors.cyanPurpleGradient,
    AppColors.goldGradient,
    AppColors.greenCyanGradient,
    AppColors.pinkOrangeGradient,
  ];

  static List<MemoryModel> get mockList => [
        MemoryModel(
          id: 'm1',
          challengeTitle: 'Song Swap',
          challengeEmoji: '🎵',
          note: 'They were listening to Arctic Monkeys too! Instant connection 🎶',
          partnerUsername: 'jess.m',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          gradientIndex: 0,
        ),
        MemoryModel(
          id: 'm2',
          challengeTitle: 'Wave & Smile',
          challengeEmoji: '👋',
          note: '8/10 strangers waved back. Today was a good day ☀️',
          partnerUsername: 'solo',
          createdAt: DateTime.now().subtract(const Duration(days: 1)),
          gradientIndex: 1,
        ),
        MemoryModel(
          id: 'm3',
          challengeTitle: 'Lunch Story',
          challengeEmoji: '🍕',
          note: 'Met a chef who travels the world for recipes. Mind blown 🤯',
          partnerUsername: 'marco.v',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
          gradientIndex: 2,
        ),
        MemoryModel(
          id: 'm4',
          challengeTitle: 'Sketch Together',
          challengeEmoji: '🎨',
          note: 'We drew a dragon that somehow looked like a potato. 10/10',
          partnerUsername: 'lily.art',
          createdAt: DateTime.now().subtract(const Duration(days: 3)),
          gradientIndex: 3,
        ),
        MemoryModel(
          id: 'm5',
          challengeTitle: 'Gratitude Drop',
          challengeEmoji: '🌿',
          note: 'Told someone I was grateful for coffee. They bought me one! ☕',
          partnerUsername: 'stranger',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
          gradientIndex: 4,
        ),
        MemoryModel(
          id: 'm6',
          challengeTitle: 'Park Sprint',
          challengeEmoji: '⚡',
          note: 'Lost the sprint but won a new friend. Worth it every time',
          partnerUsername: 'kai.run',
          createdAt: DateTime.now().subtract(const Duration(days: 7)),
          gradientIndex: 0,
        ),
      ];
}
