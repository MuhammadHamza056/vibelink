import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../../../shared/widgets/safety_pulse_button.dart';
import '../../../shared/widgets/streak_indicator.dart';
import '../../../shared/widgets/vibe_card.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background gradient orbs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 200,
            left: -80,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.cyan.withValues(alpha: 0.08),
              ),
            ),
          ),
          if (state.isLoading)
            _HomeShimmer()
          else
            RefreshIndicator(
              color: AppColors.primaryLight,
              backgroundColor: AppColors.cardBg,
              onRefresh: () => ref.read(homeProvider.notifier).refresh(),
              child: CustomScrollView(
                slivers: [
                  _AppBar(user: state.user),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Greeting + streak
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppHelpers.greetingByTime(),
                                    style: AppTextStyles.bodyMedium,
                                  ),
                                  Text(
                                    state.user?.username ?? '',
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (state.user != null)
                              StreakIndicator(
                                streakDays: state.user!.streakDays,
                                compact: true,
                              ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 20),

                        // Safety Pulse
                        SafetyPulseBanner(
                          isActive: state.safetyPulseActive,
                          onToggle: () =>
                              ref.read(homeProvider.notifier).toggleSafetyPulse(),
                        ),
                        const SizedBox(height: 24),

                        // Daily Challenge
                        Text(
                          '⭐ Challenge of the Day',
                          style: AppTextStyles.titleLarge,
                        ).animate(delay: 100.ms).fadeIn(),
                        const SizedBox(height: 12),
                        if (state.dailyChallenge != null)
                          ChallengeCard(
                            challenge: state.dailyChallenge!,
                            isLarge: true,
                            onTap: () => context.push(
                              '/challenge/${state.dailyChallenge!.id}',
                            ),
                          ).animate(delay: 150.ms).fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0),
                        const SizedBox(height: 28),

                        // Nearby vibers
                        Text(
                          'Nearby Vibers',
                          style: AppTextStyles.titleLarge,
                        ).animate(delay: 200.ms).fadeIn(),
                        const SizedBox(height: 12),
                        NearbyVibersRow(count: state.nearbyCount)
                            .animate(delay: 250.ms)
                            .fadeIn(duration: 500.ms),
                        const SizedBox(height: 28),

                        // Quick stats
                        Text(
                          'Your Stats',
                          style: AppTextStyles.titleLarge,
                        ).animate(delay: 300.ms).fadeIn(),
                        const SizedBox(height: 12),
                        if (state.user != null)
                          _StatsGrid(user: state.user!),

                        const SizedBox(height: 28),

                        // XP Progress
                        if (state.user != null)
                          XPProgressBar(
                            level: state.user!.level,
                            progress: state.user!.levelProgress,
                            currentXP: state.user!.xp % 1000,
                            xpToNext: state.user!.xpToNextLevel,
                          ).animate(delay: 400.ms).fadeIn(duration: 500.ms),

                        const SizedBox(height: 100),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      expandedHeight: 0,
      toolbarHeight: 64,
      flexibleSpace: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bolt_rounded,
                      color: Colors.white, size: 18),
                ),
                const SizedBox(width: 8),
                ShaderMask(
                  shaderCallback: (b) =>
                      AppColors.primaryGradient.createShader(b),
                  child: Text(
                    AppConstants.appName,
                    style: AppTextStyles.headlineSmall.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.settings_rounded,
                      color: AppColors.textSecondary),
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 0.88,
      children: [
        VibeStatCard(
          label: 'Challenges',
          value: '${user.challengesCompleted}',
          icon: Icons.bolt_rounded,
          gradient: AppColors.primaryGradient,
        ),
        VibeStatCard(
          label: 'Matches',
          value: '${user.matchesCount}',
          icon: Icons.people_rounded,
          gradient: AppColors.cyanPurpleGradient,
        ),
        VibeStatCard(
          label: 'Memories',
          value: '${user.memoriesCount}',
          icon: Icons.bubble_chart_rounded,
          gradient: AppColors.goldGradient,
        ),
      ],
    ).animate(delay: 350.ms).fadeIn(duration: 500.ms);
  }
}

class _HomeShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cardBg,
      highlightColor: AppColors.cardBorder,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 80),
            _ShimmerBox(width: 200, height: 28, radius: 8),
            const SizedBox(height: 20),
            _ShimmerBox(width: double.infinity, height: 80, radius: 16),
            const SizedBox(height: 20),
            _ShimmerBox(width: double.infinity, height: 200, radius: 20),
            const SizedBox(height: 20),
            _ShimmerBox(width: 160, height: 22, radius: 8),
            const SizedBox(height: 12),
            _ShimmerBox(width: double.infinity, height: 60, radius: 16),
          ],
        ),
      ),
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.width, required this.height, required this.radius});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
