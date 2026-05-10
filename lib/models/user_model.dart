class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.avatarUrl,
    required this.level,
    required this.xp,
    required this.streakDays,
    required this.vibeTags,
    required this.badges,
    required this.challengesCompleted,
    required this.matchesCount,
    required this.memoriesCount,
    required this.isOnBurnoutGuard,
    required this.lastActiveDate,
  });

  final String id;
  final String username;
  final String avatarUrl;
  final int level;
  final int xp;
  final int streakDays;
  final List<String> vibeTags;
  final List<BadgeModel> badges;
  final int challengesCompleted;
  final int matchesCount;
  final int memoriesCount;
  final bool isOnBurnoutGuard;
  final DateTime lastActiveDate;

  int get xpToNextLevel => 1000 - (xp % 1000);
  double get levelProgress => (xp % 1000) / 1000;

  String get levelTitle {
    if (level < 5) return 'Spark';
    if (level < 10) return 'Connector';
    if (level < 20) return 'Vibe Weaver';
    if (level < 35) return 'Social Legend';
    return 'VibeLink Master';
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? avatarUrl,
    int? level,
    int? xp,
    int? streakDays,
    List<String>? vibeTags,
    List<BadgeModel>? badges,
    int? challengesCompleted,
    int? matchesCount,
    int? memoriesCount,
    bool? isOnBurnoutGuard,
    DateTime? lastActiveDate,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      level: level ?? this.level,
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      vibeTags: vibeTags ?? this.vibeTags,
      badges: badges ?? this.badges,
      challengesCompleted: challengesCompleted ?? this.challengesCompleted,
      matchesCount: matchesCount ?? this.matchesCount,
      memoriesCount: memoriesCount ?? this.memoriesCount,
      isOnBurnoutGuard: isOnBurnoutGuard ?? this.isOnBurnoutGuard,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }

  static UserModel get mock => UserModel(
        id: 'user_001',
        username: 'Alex Chen',
        avatarUrl: 'https://i.pravatar.cc/150?img=12',
        level: 12,
        xp: 847,
        streakDays: 7,
        vibeTags: ['Creative', 'Musical', 'Artsy'],
        badges: BadgeModel.mockList,
        challengesCompleted: 24,
        matchesCount: 11,
        memoriesCount: 18,
        isOnBurnoutGuard: false,
        lastActiveDate: DateTime.now(),
      );
}

class BadgeModel {
  const BadgeModel({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.earnedAt,
  });

  final String id;
  final String name;
  final String emoji;
  final String description;
  final DateTime earnedAt;

  static List<BadgeModel> get mockList => [
        BadgeModel(
          id: 'b1',
          name: 'First Vibe',
          emoji: '⚡',
          description: 'Completed your first challenge',
          earnedAt: DateTime.now().subtract(const Duration(days: 30)),
        ),
        BadgeModel(
          id: 'b2',
          name: 'Streak Master',
          emoji: '🔥',
          description: '7-day streak achieved',
          earnedAt: DateTime.now().subtract(const Duration(days: 7)),
        ),
        BadgeModel(
          id: 'b3',
          name: 'Social Butterfly',
          emoji: '🦋',
          description: 'Made 10 connections',
          earnedAt: DateTime.now().subtract(const Duration(days: 14)),
        ),
        BadgeModel(
          id: 'b4',
          name: 'Memory Keeper',
          emoji: '💭',
          description: 'Created 5 memory bubbles',
          earnedAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        BadgeModel(
          id: 'b5',
          name: 'Vibe Master',
          emoji: '🌈',
          description: 'Reached level 10',
          earnedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        BadgeModel(
          id: 'b6',
          name: 'Explorer',
          emoji: '🗺️',
          description: 'Tried 5 different challenge types',
          earnedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
      ];
}
