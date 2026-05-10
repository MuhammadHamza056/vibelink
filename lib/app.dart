import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/auth/screens/onboarding_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/challenges/screens/challenge_detail_screen.dart';
import 'features/challenges/screens/challenges_screen.dart';
import 'features/home/screens/home_screen.dart';
import 'features/match/screens/match_screen.dart';
import 'features/memories/screens/memories_screen.dart';
import 'features/profile/screens/profile_screen.dart';
import 'features/shell/shell_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppConstants.routeSplash,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isAuth = authState.isAuthenticated;
      final isOnSplash = loc == AppConstants.routeSplash;
      final isOnOnboarding = loc == AppConstants.routeOnboarding;
      final isOnAuth = loc == AppConstants.routeAuth;

      if (isOnSplash) return null;
      if (!isAuth && !isOnOnboarding && !isOnAuth) return AppConstants.routeAuth;
      if (isAuth && (isOnAuth || isOnOnboarding)) return AppConstants.routeHome;
      return null;
    },
    routes: [
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
      // Full-screen challenge detail (outside shell so no bottom nav)
      GoRoute(
        path: '/challenge/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) =>
            ChallengeDetailScreen(id: state.pathParameters['id']!),
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
    ],
  );
});

class VibeLinkApp extends ConsumerWidget {
  const VibeLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: router,
    );
  }
}
