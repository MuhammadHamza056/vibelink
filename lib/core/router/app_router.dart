import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/challenges/screens/challenge_detail_screen.dart';
import '../../features/challenges/screens/challenges_screen.dart';
import '../../features/connections/screens/connections_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/match/screens/match_screen.dart';
import '../../features/memories/screens/memories_screen.dart';
import '../../features/notifications/screens/notifications_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../constants/app_constants.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) => _redirect(state, authState),
    routes: _routes,
  );
});


String? _redirect(GoRouterState state, AuthState authState) {
  final loc = state.matchedLocation;

  final token = authState.accessToken;
  final isAuth = authState.isAuthenticated && token != null && token.isNotEmpty;
  final seenOnboarding = authState.hasSeenOnboarding;
  final isOnSplash = loc == AppConstants.routeSplash;
  final isOnOnboarding = loc == AppConstants.routeOnboarding;
  final isOnAuth = loc == AppConstants.routeAuth;

  // Let the splash screen play and decide the first destination.
  if (isOnSplash) return null;

  // Signed in: never sit on the auth/onboarding screens.
  if (isAuth) {
    if (isOnAuth || isOnOnboarding) return AppConstants.routeHome;
    return null;
  }

  // Signed out and onboarding not done yet → force onboarding.
  if (!seenOnboarding) {
    return isOnOnboarding ? null : AppConstants.routeOnboarding;
  }

  // Signed out but onboarding already seen → send to login, and don't allow
  // going back to the onboarding screen.
  if (!isOnAuth) return AppConstants.routeAuth;
  return null;
}

final List<RouteBase> _routes = [
  GoRoute(
    path: AppConstants.routeSplash,
    builder: (_, __) => const SplashScreen(),
  ),
  GoRoute(
    path: AppConstants.routeOnboarding,
    builder: (_, __) => const OnboardingScreen(),
  ),
  GoRoute(
    path: AppConstants.routeAuth,
    builder: (_, __) => const AuthScreen(),
  ),

  GoRoute(
    path: AppConstants.routeChallengeDetail,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (_, state) =>
        ChallengeDetailScreen(id: state.pathParameters['id']!),
  ),
  GoRoute(
    path: AppConstants.routeNotifications,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (_, __) => const NotificationsScreen(),
  ),
  GoRoute(
    path: AppConstants.routeConnections,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (_, __) => const ConnectionsScreen(),
  ),
  ShellRoute(
    navigatorKey: _shellNavigatorKey,
    builder: (_, __, child) => ShellScreen(child: child),
    routes: [
      GoRoute(
        path: AppConstants.routeHome,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppConstants.routeChallenges,
        builder: (_, __) => const ChallengesScreen(),
      ),
      GoRoute(
        path: AppConstants.routeMatch,
        builder: (_, __) => const MatchScreen(),
      ),
      GoRoute(
        path: AppConstants.routeMemories,
        builder: (_, __) => const MemoriesScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (_, __) => const ProfileScreen(),
      ),
    ],
  ),
];
