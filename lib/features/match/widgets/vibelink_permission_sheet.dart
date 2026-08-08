import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/match_provider.dart';

final permissionLoadingProvider =
    StateProvider.autoDispose<bool>((ref) => false);

class VibelinkPermissionSheet extends ConsumerWidget {
  const VibelinkPermissionSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VibelinkPermissionSheet(),
    );
  }

  /// Opens VibeLink's specific App Settings page on the user's phone.
  Future<void> _onOpenAppSettings(BuildContext context, WidgetRef ref) async {
    ref.read(permissionLoadingProvider.notifier).state = true;
    await ref.read(locationServiceProvider).openAppSettings();
    if (!context.mounted) return;
    Navigator.of(context).pop();
  }

  /// Requests in-app system permission dialog.
  Future<void> _onRequestPermission(BuildContext context, WidgetRef ref) async {
    ref.read(permissionLoadingProvider.notifier).state = true;
    final service = ref.read(locationServiceProvider);
    await service.requestPermission();
    if (!context.mounted) return;
    Navigator.of(context).pop();
    ref.read(matchProvider.notifier).startSearch();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(permissionLoadingProvider);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(color: AppColors.cardBorder, width: 1.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Location badge icon
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: AppColors.cyanPurpleGradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.cyan.withValues(alpha: 0.35),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.location_on_rounded,
                size: 38,
                color: Colors.white,
              ),
            ),
          ).animate().scale(duration: 350.ms, curve: Curves.easeOutBack),
          const SizedBox(height: 20),

          // Title
          Text(
            'Location Access Required 📍',
            style: AppTextStyles.headlineSmall.copyWith(color: Colors.white),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),

          // Subtitle / explanation
          Text(
            'To discover nearby matches and calculate vibe scores, please grant Location permission in VibeLink\'s app settings on your phone.',
            style: AppTextStyles.bodyMedium
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Feature list
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              children: const [
                _FeatureRow(
                  icon: Icons.settings_applications_rounded,
                  iconColor: AppColors.cyan,
                  title: 'App Settings Access',
                  subtitle: 'Opens VibeLink app permissions page directly on phone',
                ),
                SizedBox(height: 12),
                _FeatureRow(
                  icon: Icons.security_rounded,
                  iconColor: AppColors.green,
                  title: 'Privacy Guaranteed',
                  subtitle: 'Location is only used to find local matches nearby',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          Column(
            children: [
              GradientButton(
                label: 'Open App Settings ⚙️',
                gradient: AppColors.cyanPurpleGradient,
                isLoading: isLoading,
                onTap: isLoading ? null : () => _onOpenAppSettings(context, ref),
                width: double.infinity,
              ),
              const SizedBox(height: 10),
              OutlineButton(
                label: 'Request Permission Directly',
                onTap: isLoading ? null : () => _onRequestPermission(context, ref),
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.titleMedium
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
