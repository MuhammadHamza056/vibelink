class AppConstants {
  AppConstants._();

  // App
  static const String appName = 'VibeLink';
  static const String appVersion = '1.0.0';

  // Durations
  static const int animFast = 200;
  static const int animMedium = 350;
  static const int animSlow = 600;

  // Spacing
  static const double paddingXS = 4.0;
  static const double paddingS = 8.0;
  static const double paddingM = 16.0;
  static const double paddingL = 24.0;
  static const double paddingXL = 32.0;
  static const double paddingXXL = 48.0;

  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 16.0;
  static const double radiusL = 24.0;
  static const double radiusXL = 32.0;
  static const double radiusFull = 999.0;

  // Bottom nav
  static const double bottomNavHeight = 80.0;

  // Challenge durations
  static const int challengeMinMinutes = 5;
  static const int challengeMaxMinutes = 20;

  // Levels
  static const int xpPerLevel = 1000;
  static const int maxLevel = 50;

  // Streak
  static const int burnoutThresholdDays = 14;

  // Matching
  static const double minVibeMatchScore = 0.6;
  static const int matchRadiusMeters = 5000;

  // Routes
  static const String routeSplash = '/splash';
  static const String routeOnboarding = '/onboarding';
  static const String routeAuth = '/auth';
  static const String routeHome = '/home';
  static const String routeChallenges = '/challenges';
  static const String routeMatch = '/match';
  static const String routeMemories = '/memories';
  static const String routeProfile = '/profile';
  static const String routeChallengeDetail = '/challenge/:id';

  // Vibe Tags
  static const List<String> vibeTags = [
    'Creative', 'Adventurous', 'Chill', 'Foodie',
    'Musical', 'Sporty', 'Bookworm', 'Gamer',
    'Traveler', 'Artsy', 'Techie', 'Nature',
  ];

  // Challenge emojis
  static const List<String> challengeEmojis = [
    '🎵', '👋', '🍕', '🎨', '⚽', '📚',
    '🌿', '🎮', '✈️', '🎤', '🤝', '🌈',
  ];
}
