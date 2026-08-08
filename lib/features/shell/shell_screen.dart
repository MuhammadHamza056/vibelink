import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/app_text_styles.dart';
import '../../shared/widgets/bottom_nav_bar.dart';
import '../../shared/widgets/gradient_button.dart';

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

  Future<void> _handlePop(BuildContext context) async {
    final currentIndex = _currentIndex(context);

    if (currentIndex != 0) {
      // If on Profile or any non-home tab -> Navigate to Home tab
      context.go(AppConstants.routeHome);
    } else {
      // If on Home tab -> Prompt exit confirmation dialog
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Exit VibeLink? 👋', style: AppTextStyles.headlineSmall),
          content: Text(
            'Are you sure you want to exit the app?',
            style: AppTextStyles.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
            ),
            GradientButton(
              label: 'Exit',
              gradient: AppColors.primaryGradient,
              height: 40,
              onTap: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );

      if (shouldExit == true) {
        SystemNavigator.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handlePop(context);
      },
      child: Scaffold(
        extendBody: true,
        body: child,
        bottomNavigationBar: VibeLinkBottomNav(
          currentIndex: currentIndex,
          onTap: (i) => context.go(_routes[i]),
        ),
      ),
    );
  }
}
