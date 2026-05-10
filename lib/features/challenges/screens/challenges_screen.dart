import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../shared/widgets/challenge_card.dart';
import '../providers/challenge_provider.dart';

class ChallengesScreen extends ConsumerWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(challengeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (b) =>
                              AppColors.primaryGradient.createShader(b),
                          child: Text(
                            '⚡ Challenges',
                            style: AppTextStyles.headlineLarge
                                .copyWith(color: Colors.white),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.cardBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.map_rounded,
                                  size: 16, color: AppColors.cyan),
                              const SizedBox(width: 6),
                              Text('Nearby',
                                  style: AppTextStyles.labelSmall
                                      .copyWith(color: AppColors.cyan)),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 400.ms),
                    const SizedBox(height: 20),
                    // Filter tabs
                    _FilterTabs(
                      selected: state.filter,
                      onSelect: (f) =>
                          ref.read(challengeProvider.notifier).setFilter(f),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            // Grid
            if (state.isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primaryLight),
                ),
              )
            else if (state.filtered.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('😴', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 16),
                      Text('No challenges here yet',
                          style: AppTextStyles.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Try a different filter',
                          style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) {
                      final challenge = state.filtered[i];
                      return ChallengeCard(
                        challenge: challenge,
                        index: i,
                        onTap: () =>
                            context.push('/challenge/${challenge.id}'),
                      );
                    },
                    childCount: state.filtered.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.selected, required this.onSelect});

  final ChallengeFilter selected;
  final ValueChanged<ChallengeFilter> onSelect;

  static const _filters = [
    (ChallengeFilter.today, 'Today'),
    (ChallengeFilter.thisWeek, 'This Week'),
    (ChallengeFilter.trending, '🔥 Trending'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((entry) {
          final (filter, label) = entry;
          final isSelected = selected == filter;
          return GestureDetector(
            onTap: () => onSelect(filter),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : AppColors.cardBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : AppColors.cardBorder,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color:
                      isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
