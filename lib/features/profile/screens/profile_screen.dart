import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../shared/widgets/badge_chip.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/streak_indicator.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileProvider);

    if (state.isLoading || state.user == null) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primaryLight),
        ),
      );
    }

    final user = state.user!;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
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
                              icon: const Icon(Icons.settings_rounded,
                                  color: AppColors.textSecondary),
                              onPressed: () {},
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
                                gradient: AppHelpers.levelGradient(user.level),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                    blurRadius: 24,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.cardBg,
                              ),
                              child: ClipOval(
                                child: Image.network(
                                  user.avatarUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      user.username[0].toUpperCase(),
                                      style: AppTextStyles.displayMedium
                                          .copyWith(color: AppColors.primaryLight),
                                    ),
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
                    .animate(delay: 350.ms).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // Stats row
                _StatsRow(user: user)
                    .animate(delay: 400.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 28),

                // Vibe Tags
                Text('My Vibes', style: AppTextStyles.titleLarge)
                    .animate(delay: 450.ms).fadeIn(),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: AppConstants.vibeTags.map((tag) {
                    final isSelected = user.vibeTags.contains(tag);
                    return VibeTagChip(
                      label: tag,
                      isSelected: isSelected,
                    );
                  }).toList(),
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
                const SizedBox(height: 28),

                // Burnout guard
                _BurnoutGuard(riskLevel: state.burnoutRiskLevel)
                    .animate(delay: 570.ms).fadeIn(duration: 500.ms),
                const SizedBox(height: 28),

                // Sign out
                OutlineButton(
                  label: 'Sign Out',
                  onTap: () {
                    ref.read(authProvider.notifier).signOut();
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
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.user});
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatBox(
          label: 'Challenges',
          value: '${user.challengesCompleted}',
          emoji: '⚡',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Matches',
          value: '${user.matchesCount}',
          emoji: '💫',
        ),
        const SizedBox(width: 12),
        _StatBox(
          label: 'Memories',
          value: '${user.memoriesCount}',
          emoji: '💭',
        ),
      ],
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox(
      {required this.label, required this.value, required this.emoji});
  final String label;
  final String value;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: AppTextStyles.headlineMedium),
            Text(label, style: AppTextStyles.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _BurnoutGuard extends StatelessWidget {
  const _BurnoutGuard({required this.riskLevel});
  final double riskLevel;

  @override
  Widget build(BuildContext context) {
    final isHighRisk = riskLevel >= 0.7;
    final color = isHighRisk ? AppColors.warning : AppColors.green;
    final message = isHighRisk
        ? 'You\'ve been very active! Consider a rest day today 🛌'
        : 'Great balance! Keep your healthy vibe routine going 🌿';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(isHighRisk ? '⚠️' : '🛡️',
              style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Burnout Guard',
                  style: AppTextStyles.titleMedium.copyWith(color: color),
                ),
                const SizedBox(height: 4),
                Text(message, style: AppTextStyles.bodySmall),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: riskLevel,
                    minHeight: 6,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
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
