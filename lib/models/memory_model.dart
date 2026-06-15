import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_constants.dart';

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
    this.vibeTags = const [],
  });

  final String id;
  final String challengeTitle;
  final String challengeEmoji;
  final String note;
  final String partnerUsername;
  final DateTime createdAt;
  final int gradientIndex;
  final String? imageUrl;
  final List<String> vibeTags;

  /// Builds a memory from the GET /api/memories payload. The backend has no
  /// emoji or colour, so we derive both deterministically from the id (stable
  /// per memory, varied across the grid). It also has no partner, so the
  /// partner chip is hidden via the 'solo' sentinel.
  factory MemoryModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? json['_id'] ?? '').toString();
    final seed = id.hashCode.abs();
    final emojis = AppConstants.challengeEmojis;
    final img = (json['imageUrl'] ?? '') as String;
    return MemoryModel(
      id: id,
      challengeTitle: (json['title'] ?? '') as String,
      challengeEmoji: emojis[seed % emojis.length],
      note: (json['caption'] ?? '') as String,
      partnerUsername: 'solo',
      createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.now(),
      gradientIndex: seed % _gradients.length,
      imageUrl: img.isEmpty ? null : img,
      vibeTags: (json['vibeTags'] as List?)?.cast<String>() ?? const [],
    );
  }

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
