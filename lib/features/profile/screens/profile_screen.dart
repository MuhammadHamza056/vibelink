import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../shared/widgets/badge_chip.dart';
import '../../../shared/widgets/cached_avatar.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/streak_indicator.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../widgets/burnout_guard.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/profile_stats_row.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

    if (state.isLoading && state.user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    if (state.user == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('😕', style: TextStyle(fontSize: 40)),
                const SizedBox(height: 12),
                Text(
                  state.error ?? 'Could not load your profile.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Retry',
                  onTap: () => ref.read(profileProvider.notifier).refresh(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = state.user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primaryLight,
        backgroundColor: AppColors.cardBg,
        onRefresh: () => ref.read(profileProvider.notifier).refresh(),
        child: CustomScrollView(
          // AlwaysScrollable so pull-to-refresh works even when content fits.
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Profile header
            SliverToBoxAdapter(
              child: Stack(
                children: [
                  // Gradient header bg
                  Container(
                    height: 220,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.4),
                          AppColors.background,
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '👤 Profile',
                                style: AppTextStyles.headlineLarge,
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_rounded,
                                    color: AppColors.textSecondary),
                                tooltip: 'Edit profile',
                                onPressed: () => showEditProfileSheet(
                                  context,
                                  ref,
                                  user,
                                  state.availableTags.isNotEmpty
                                      ? state.availableTags
                                      : AppConstants.vibeTags,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(duration: 400.ms),
                          const SizedBox(height: 16),
                          // Avatar
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient:
                                      AppHelpers.levelGradient(user.level),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary
                                          .withValues(alpha: 0.5),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              CachedAvatar(
                                avatarUrl: user.avatarUrl,
                                username: user.username,
                                size: 90,
                                fallback: Center(
                                  child: Text(
                                    (user.username.isEmpty
                                            ? '?'
                                            : user.username[0])
                                        .toUpperCase(),
                                    style: AppTextStyles.displayMedium.copyWith(
                                      color: AppColors.primaryLight,
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    gradient: AppColors.primaryGradient,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                        color: AppColors.background, width: 2),
                                  ),
                                  child: Text(
                                    'Lv.${user.level}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ).animate(delay: 100.ms).scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                curve: Curves.easeOutBack,
                                duration: 600.ms,
                              ),
                          const SizedBox(height: 12),
                          Text(
                            user.username,
                            style: AppTextStyles.headlineMedium,
                          ).animate(delay: 200.ms).fadeIn(duration: 400.ms),
                          Text(
                            user.levelTitle,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primaryLight,
                            ),
                          ).animate(delay: 250.ms).fadeIn(),
                          if (user.email.isNotEmpty)
                            Text(
                              user.email,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ).animate(delay: 280.ms).fadeIn(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 16),
                  // XP Progress
                  XPProgressBar(
                    level: user.level,
                    progress: user.levelProgress,
                    currentXP: user.xp % 1000,
                    xpToNext: user.xpToNextLevel,
                  ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Streak
                  StreakIndicator(streakDays: user.streakDays)
                      .animate(delay: 350.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 24),

                  // Stats row
                  ProfileStatsRow(user: user)
                      .animate(delay: 400.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 28),

                  // Vibe Tags
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Vibes', style: AppTextStyles.titleLarge),
                      TextButton.icon(
                        onPressed: () => showEditProfileSheet(
                          context,
                          ref,
                          user,
                          state.availableTags.isNotEmpty
                              ? state.availableTags
                              : AppConstants.vibeTags,
                        ),
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ).animate(delay: 450.ms).fadeIn(),
                  const SizedBox(height: 12),
                  if (user.vibeTags.isEmpty)
                    Text(
                      'No vibes yet — tap Edit to pick a few.',
                      style: AppTextStyles.bodySmall,
                    ),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: user.vibeTags
                        .map((tag) => VibeTagChip(label: tag, isSelected: true))
                        .toList(),
                  ).animate(delay: 480.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),

                  // Badges
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Badges', style: AppTextStyles.titleLarge),
                      Text(
                        '${user.badges.length} earned',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.gold,
                        ),
                      ),
                    ],
                  ).animate(delay: 500.ms).fadeIn(),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: user.badges.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => BadgeChip(badge: user.badges[i]),
                    ),
                  ).animate(delay: 530.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 24),

                  // Connections
                  GradientButton(
                    label: 'My Connections',
                    icon: Icons.people_alt_rounded,
                    gradient: AppColors.cyanPurpleGradient,
                    width: double.infinity,
                    onTap: () => context.push(AppConstants.routeConnections),
                  ).animate(delay: 550.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 28),

                  // Burnout guard
                  BurnoutGuard(riskLevel: state.burnoutRiskLevel)
                      .animate(delay: 570.ms)
                      .fadeIn(duration: 500.ms),
                  const SizedBox(height: 28),

                  // Sign out
                  OutlineButton(
                    label: 'Sign Out',
                    onTap: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (!context.mounted) return;
                      context.go(AppConstants.routeAuth);
                    },
                    color: AppColors.error,
                  ).animate(delay: 600.ms).fadeIn(duration: 400.ms),
                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
