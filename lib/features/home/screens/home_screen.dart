import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../models/challenge_model.dart';
import '../../../models/home_model.dart';
import '../../../models/user_model.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../../../shared/widgets/safety_pulse_button.dart';
import '../../../shared/widgets/streak_indicator.dart';
import '../../../shared/widgets/vibe_card.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../providers/home_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeProvider);
    final home = state.home;

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
                  _AppBar(profile: state.profile),
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
                                    home?.username ?? '',
                                    style: AppTextStyles.headlineLarge,
                                  ),
                                ],
                              ),
                            ),
                            if (home != null)
                              StreakIndicator(
                                streakDays: home.streakDays,
                                compact: true,
                              ),
                          ],
                        ).animate().fadeIn(duration: 400.ms),
                        const SizedBox(height: 20),

                        // Safety Pulse
                        SafetyPulseBanner(
                          isActive: state.safetyPulseActive,
                          onToggle: () => ref
                              .read(homeProvider.notifier)
                              .toggleSafetyPulse(),
                        ),
                        const SizedBox(height: 24),

                        // Daily Challenge
                        if (home?.dailyChallenge != null) ...[
                          Text(
                            '⭐ Challenge of the Day',
                            style: AppTextStyles.titleLarge,
                          ).animate(delay: 100.ms).fadeIn(),
                          const SizedBox(height: 12),
                          ChallengeCard(
                            challenge: home!.dailyChallenge!,
                            isLarge: true,
                            onTap: () => context.push(
                              '/challenge/${home.dailyChallenge!.id}',
                            ),
                          )
                              .animate(delay: 150.ms)
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.1, end: 0),
                          const SizedBox(height: 28),
                        ],

                        // Suggested challenges
                        if (home != null && home.suggestedChallenges.length > 1)
                          _SuggestedChallenges(challenges: home.suggestedChallenges),

                        // Quick stats
                        Text(
                          'Your Stats',
                          style: AppTextStyles.titleLarge,
                        ).animate(delay: 300.ms).fadeIn(),
                        const SizedBox(height: 12),
                        if (home != null) _StatsGrid(home: home),

                        const SizedBox(height: 28),

                        // XP Progress
                        if (home != null)
                          XPProgressBar(
                            level: home.level,
                            progress: home.progress,
                            currentXP: home.currentLevelXp,
                            xpToNext: home.xpToNextLevel,
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
  const _AppBar({this.profile});
  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      floating: true,
      expandedHeight: 0,
      toolbarHeight: 64,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
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
                  const _NotificationBell(),
                  const SizedBox(width: 4),
                  // Avatar from GET /api/profile; tapping opens the profile tab.
                  GestureDetector(
                    onTap: () => context.go(AppConstants.routeProfile),
                    child: _ProfileAvatar(profile: profile),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bell icon for the home app bar. Shows a dot when there are pending
/// notifications and opens the notifications page on tap.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(
      notificationsProvider.select((s) => s.pendingCount),
    );
    return IconButton(
      onPressed: () => context.push(AppConstants.routeNotifications),
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_rounded,
              color: AppColors.textSecondary),
          if (pending > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 1.5),
                ),
                constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
              ),
            ),
        ],
      ),
    );
  }
}

/// Small circular avatar for the home app bar, fed by GET /api/profile.
/// Falls back to the username's initial (or a person icon) when no image
/// is available or the network image fails to load.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({this.profile});
  final UserModel? profile;

  @override
  Widget build(BuildContext context) {
    final username = profile?.username ?? '';
    final avatarUrl = profile?.avatarUrl ?? '';

    Widget fallback() => Center(
          child: username.isEmpty
              ? const Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 20)
              : Text(
                  username[0].toUpperCase(),
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primaryLight),
                ),
        );

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.cardBg,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipOval(
        child: avatarUrl.isEmpty
            ? fallback()
            : CachedNetworkImage(
                imageUrl: ApiEndpoints.mediaUrl(avatarUrl),
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.home});
  final HomeModel home;

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
          value: '${home.challengesCompleted}',
          icon: Icons.bolt_rounded,
          gradient: AppColors.primaryGradient,
        ),
        VibeStatCard(
          label: 'Matches',
          value: '${home.matchesCount}',
          icon: Icons.people_rounded,
          gradient: AppColors.cyanPurpleGradient,
        ),
        VibeStatCard(
          label: 'Memories',
          value: '${home.memoriesCount}',
          icon: Icons.bubble_chart_rounded,
          gradient: AppColors.goldGradient,
        ),
      ],
    ).animate(delay: 350.ms).fadeIn(duration: 500.ms);
  }
}

class _SuggestedChallenges extends StatelessWidget {
  const _SuggestedChallenges({required this.challenges});
  final List<ChallengeModel> challenges;

  @override
  Widget build(BuildContext context) {
    // Skip the first one — it's already featured as the Challenge of the Day.
    final items = challenges.skip(1).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Suggested for You',
          style: AppTextStyles.titleLarge,
        ).animate(delay: 200.ms).fadeIn(),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => SizedBox(
              width: 150,
              child: ChallengeCard(
                challenge: items[i],
                index: i,
                onTap: () => context.push('/challenge/${items[i].id}'),
              ),
            ),
          ),
        ).animate(delay: 250.ms).fadeIn(duration: 500.ms),
        const SizedBox(height: 28),
      ],
    );
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
  const _ShimmerBox(
      {required this.width, required this.height, required this.radius});
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
