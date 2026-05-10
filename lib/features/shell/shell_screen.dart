import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/bottom_nav_bar.dart';

class ShellScreen extends StatelessWidget {
  const ShellScreen({super.key, required this.child});

  final Widget child;

  static const _routes = [
    AppConstants.routeHome,
    AppConstants.routeChallenges,
    AppConstants.routeMatch,
    AppConstants.routeMemories,
    AppConstants.routeProfile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    final idx = _routes.indexOf(location);
    return idx < 0 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      extendBody: true,
      body: child,
      bottomNavigationBar: VibeLinkBottomNav(
        currentIndex: currentIndex,
        onTap: (i) => context.go(_routes[i]),
      ),
    );
  }
}
