import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum ChallengeCategory { social, creative, physical, mindful, foodie, music }

enum ChallengeDifficulty { easy, medium, hard }

enum ChallengeStatus { available, active, completed, expired }

/// A connection a challenge has been shared with (from `sharedWith` on the
/// GET /api/challenges payload).
class SharedConnection {
  const SharedConnection({
    required this.connectionId,
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.level,
  });

  final String connectionId;
  final String userId;
  final String username;
  final String avatarUrl;
  final int level;

  factory SharedConnection.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    return SharedConnection(
      connectionId: (json['connectionId'] ?? '').toString(),
      userId: (user['id'] ?? user['_id'] ?? '').toString(),
      username: (user['username'] ?? '') as String,
      avatarUrl: (user['avatarUrl'] ?? '') as String,
      level: (user['level'] ?? 1) as int,
    );
  }
}

class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.emoji,
    required this.durationMinutes,
    required this.category,
    required this.difficulty,
    required this.status,
    required this.participants,
    required this.maxParticipants,
    required this.xpReward,
    required this.tags,
    required this.expiresAt,
    this.isTrending = false,
    this.isDaily = false,
    this.isShared = false,
    this.sharedWith = const [],
    this.isCompleted = false,
    this.inProgress = false,
  });

  final String id;
  final String title;
  final String description;
  final String emoji;
  final int durationMinutes;
  final ChallengeCategory category;
  final ChallengeDifficulty difficulty;
  final ChallengeStatus status;
  final int participants;
  final int maxParticipants;
  final int xpReward;
  final List<String> tags;
  final DateTime expiresAt;
  final bool isTrending;
  final bool isDaily;

  /// Whether this challenge has been shared with any connections.
  final bool isShared;

  /// Connections this challenge has been shared with.
  final List<SharedConnection> sharedWith;

  /// Whether the logged in user completed this challenge.
  final bool isCompleted;

  /// Whether this challenge is currently active / in-progress.
  final bool inProgress;

  /// Builds a challenge from the GET /api/challenges payload.
  factory ChallengeModel.fromJson(Map<String, dynamic> json) {
    final xpReward = (json['xpReward'] ?? 0) as int;
    final isComp = (json['isCompleted'] ?? false) as bool;
    final inProg = (json['inProgress'] ?? false) as bool;
    return ChallengeModel(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      title: (json['title'] ?? '') as String,
      description: (json['description'] ?? '') as String,
      emoji: (json['emoji'] ?? '🎯') as String,
      durationMinutes: (json['durationMinutes'] ?? 0) as int,
      category: _categoryFrom(json['category'] as String?),
      difficulty: _difficultyFrom(json['difficulty'] as String?),
      status: inProg
          ? ChallengeStatus.active
          : (isComp ? ChallengeStatus.completed : ChallengeStatus.available),
      participants: 0,
      maxParticipants: 0,
      xpReward: xpReward,
      tags: (json['vibeTags'] as List?)?.cast<String>() ?? const [],
      expiresAt: DateTime.tryParse('${json['updatedAt']}')
              ?.add(const Duration(days: 1)) ??
          DateTime.now().add(const Duration(days: 1)),
      isTrending: xpReward >= 120,
      isShared: (json['isShared'] ?? false) as bool,
      sharedWith: (json['sharedWith'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(SharedConnection.fromJson)
              .toList() ??
          const [],
      isCompleted: isComp,
      inProgress: inProg,
    );
  }

  ChallengeModel copyWith({
    String? id,
    String? title,
    String? description,
    String? emoji,
    int? durationMinutes,
    ChallengeCategory? category,
    ChallengeDifficulty? difficulty,
    ChallengeStatus? status,
    int? participants,
    int? maxParticipants,
    int? xpReward,
    List<String>? tags,
    DateTime? expiresAt,
    bool? isTrending,
    bool? isDaily,
    bool? isShared,
    List<SharedConnection>? sharedWith,
    bool? isCompleted,
    bool? inProgress,
  }) {
    return ChallengeModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      status: status ?? this.status,
      participants: participants ?? this.participants,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      xpReward: xpReward ?? this.xpReward,
      tags: tags ?? this.tags,
      expiresAt: expiresAt ?? this.expiresAt,
      isTrending: isTrending ?? this.isTrending,
      isDaily: isDaily ?? this.isDaily,
      isShared: isShared ?? this.isShared,
      sharedWith: sharedWith ?? this.sharedWith,
      isCompleted: isCompleted ?? this.isCompleted,
      inProgress: inProgress ?? this.inProgress,
    );
  }

  static ChallengeCategory _categoryFrom(String? s) {
    for (final c in ChallengeCategory.values) {
      if (c.name == s) return c;
    }
    return ChallengeCategory.social;
  }

  static ChallengeDifficulty _difficultyFrom(String? s) {
    for (final d in ChallengeDifficulty.values) {
      if (d.name == s) return d;
    }
    return ChallengeDifficulty.easy;
  }

  String get difficultyLabel => switch (difficulty) {
        ChallengeDifficulty.easy => 'Easy',
        ChallengeDifficulty.medium => 'Medium',
        ChallengeDifficulty.hard => 'Hard',
      };

  Color get difficultyColor => switch (difficulty) {
        ChallengeDifficulty.easy => AppColors.green,
        ChallengeDifficulty.medium => AppColors.gold,
        ChallengeDifficulty.hard => AppColors.pink,
      };

  String get categoryLabel => switch (category) {
        ChallengeCategory.social => 'Social',
        ChallengeCategory.creative => 'Creative',
        ChallengeCategory.physical => 'Physical',
        ChallengeCategory.mindful => 'Mindful',
        ChallengeCategory.foodie => 'Foodie',
        ChallengeCategory.music => 'Music',
      };

  LinearGradient get gradient => switch (category) {
        ChallengeCategory.social => AppColors.primaryGradient,
        ChallengeCategory.creative => AppColors.cyanPurpleGradient,
        ChallengeCategory.physical => AppColors.pinkOrangeGradient,
        ChallengeCategory.mindful => AppColors.greenCyanGradient,
        ChallengeCategory.foodie => AppColors.goldGradient,
        ChallengeCategory.music => AppColors.primaryGradient,
      };

  static List<ChallengeModel> get mockList => [
        ChallengeModel(
          id: 'c1',
          title: 'Song Swap',
          description: 'Ask a stranger what song they\'re listening to and share yours. Exchange music tastes!',
          emoji: '🎵',
          durationMinutes: 5,
          category: ChallengeCategory.music,
          difficulty: ChallengeDifficulty.easy,
          status: ChallengeStatus.available,
          participants: 142,
          maxParticipants: 200,
          xpReward: 50,
          tags: ['music', 'icebreaker'],
          expiresAt: DateTime.now().add(const Duration(hours: 8)),
          isDaily: true,
        ),
        ChallengeModel(
          id: 'c2',
          title: 'Wave & Smile',
          description: 'Wave at 3 strangers and hold eye contact with a smile. Count how many wave back!',
          emoji: '👋',
          durationMinutes: 10,
          category: ChallengeCategory.social,
          difficulty: ChallengeDifficulty.easy,
          status: ChallengeStatus.available,
          participants: 89,
          maxParticipants: 150,
          xpReward: 40,
          tags: ['social', 'confidence'],
          expiresAt: DateTime.now().add(const Duration(hours: 12)),
          isTrending: true,
        ),
        ChallengeModel(
          id: 'c3',
          title: 'Lunch Story',
          description: 'Share your lunch story with someone nearby — where\'s it from and why you chose it?',
          emoji: '🍕',
          durationMinutes: 15,
          category: ChallengeCategory.foodie,
          difficulty: ChallengeDifficulty.medium,
          status: ChallengeStatus.available,
          participants: 56,
          maxParticipants: 100,
          xpReward: 75,
          tags: ['food', 'storytelling'],
          expiresAt: DateTime.now().add(const Duration(hours: 6)),
          isTrending: true,
        ),
        ChallengeModel(
          id: 'c4',
          title: 'Sketch Together',
          description: 'Find someone and co-create a quick 2-minute doodle on your phone. No art skills needed!',
          emoji: '🎨',
          durationMinutes: 10,
          category: ChallengeCategory.creative,
          difficulty: ChallengeDifficulty.medium,
          status: ChallengeStatus.available,
          participants: 34,
          maxParticipants: 80,
          xpReward: 80,
          tags: ['art', 'creative', 'co-op'],
          expiresAt: DateTime.now().add(const Duration(hours: 10)),
        ),
        ChallengeModel(
          id: 'c5',
          title: 'Park Sprint',
          description: 'Challenge someone nearby to a 30-second sprint. Winner picks the celebration move!',
          emoji: '⚡',
          durationMinutes: 5,
          category: ChallengeCategory.physical,
          difficulty: ChallengeDifficulty.hard,
          status: ChallengeStatus.available,
          participants: 23,
          maxParticipants: 60,
          xpReward: 100,
          tags: ['sport', 'fun', 'competition'],
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
        ),
        ChallengeModel(
          id: 'c6',
          title: 'Gratitude Drop',
          description: 'Tell someone nearby one thing you\'re grateful for today. Let the good vibes spread.',
          emoji: '🌿',
          durationMinutes: 5,
          category: ChallengeCategory.mindful,
          difficulty: ChallengeDifficulty.easy,
          status: ChallengeStatus.available,
          participants: 201,
          maxParticipants: 300,
          xpReward: 60,
          tags: ['mindful', 'gratitude', 'positivity'],
          expiresAt: DateTime.now().add(const Duration(hours: 20)),
          isTrending: true,
        ),
      ];
}
