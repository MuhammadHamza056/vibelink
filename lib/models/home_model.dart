import '../core/constants/app_constants.dart';
import 'challenge_model.dart';
import 'memory_model.dart';

/// Aggregated payload for the home dashboard (GET /api/home). Bundles the
/// user summary, leveling, stats, suggested challenges, recent memories and
/// the burnout guard so the home screen only makes a single request.
class HomeModel {
  const HomeModel({
    required this.username,
    required this.avatarUrl,
    required this.xp,
    required this.streakDays,
    required this.level,
    required this.levelTitle,
    required this.xpToNextLevel,
    required this.progress,
    required this.challengesCompleted,
    required this.matchesCount,
    required this.memoriesCount,
    required this.badgesCount,
    required this.activeChallengeIds,
    required this.suggestedChallenges,
    required this.recentMemories,
    required this.categories,
    required this.burnoutEnabled,
    required this.daysSinceActive,
    this.burnoutNudge,
    this.safetyPulseEnabled = false,
  });

  // user
  final String username;
  final String avatarUrl;
  final int xp;
  final int streakDays;

  // leveling
  final int level;
  final String levelTitle;
  final int xpToNextLevel;
  final double progress;

  // stats
  final int challengesCompleted;
  final int matchesCount;
  final int memoriesCount;
  final int badgesCount;

  final List<String> activeChallengeIds;
  final List<ChallengeModel> suggestedChallenges;
  final List<MemoryModel> recentMemories;
  final List<String> categories;

  // burnout guard & safety pulse
  final bool burnoutEnabled;
  final int daysSinceActive;
  final String? burnoutNudge;
  final bool safetyPulseEnabled;

  /// The first suggested challenge, featured as the "Challenge of the Day".
  ChallengeModel? get dailyChallenge =>
      suggestedChallenges.isNotEmpty ? suggestedChallenges.first : null;

  /// XP earned within the current level (for the progress bar's "X / Y" label).
  int get currentLevelXp =>
      (AppConstants.xpPerLevel - xpToNextLevel).clamp(0, AppConstants.xpPerLevel);

  factory HomeModel.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? const {};
    final leveling = (json['leveling'] as Map<String, dynamic>?) ?? const {};
    final stats = (json['stats'] as Map<String, dynamic>?) ?? const {};
    final burnout = (json['burnoutGuard'] as Map<String, dynamic>?) ?? const {};

    return HomeModel(
      username: (user['username'] ?? '') as String,
      avatarUrl: (user['avatarUrl'] ?? '') as String,
      xp: (user['xp'] ?? 0) as int,
      streakDays: (user['streakDays'] ?? 0) as int,
      level: (leveling['level'] ?? 1) as int,
      levelTitle: (leveling['title'] ?? '') as String,
      xpToNextLevel: (leveling['xpToNextLevel'] ?? 0) as int,
      progress: ((leveling['progress'] ?? 0) as num).toDouble(),
      challengesCompleted: (stats['challengesCompleted'] ?? 0) as int,
      matchesCount: (stats['matchesCount'] ?? 0) as int,
      memoriesCount: (stats['memoriesCount'] ?? 0) as int,
      badgesCount: (stats['badges'] ?? 0) as int,
      activeChallengeIds:
          (json['activeChallengeIds'] as List?)?.cast<String>() ?? const [],
      suggestedChallenges: (json['suggestedChallenges'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(ChallengeModel.fromJson)
              .toList() ??
          const [],
      recentMemories: (json['recentMemories'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MemoryModel.fromJson)
              .toList() ??
          const [],
      categories: (json['categories'] as List?)?.cast<String>() ?? const [],
      burnoutEnabled: (burnout['enabled'] ?? false) as bool,
      daysSinceActive: (burnout['daysSinceActive'] ?? 0) as int,
      burnoutNudge: burnout['nudge'] as String?,
      safetyPulseEnabled: (user['safetyPulseEnabled'] ?? false) as bool,
    );
  }
}
