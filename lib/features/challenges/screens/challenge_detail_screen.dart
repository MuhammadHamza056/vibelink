import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/toast_util.dart';
import '../../../models/challenge_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../../../shared/widgets/review_dialog.dart';
import '../../review/providers/review_provider.dart';
import '../providers/challenge_provider.dart';

class ChallengeDetailScreen extends ConsumerWidget {
  const ChallengeDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(() => ref.read(challengeProvider.notifier).fetchChallengeById(id));
    final challenge = ref.watch(challengeByIdProvider(id));

    if (challenge == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(child: Text('Challenge not found')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero header
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back_rounded,
                    color: Colors.white, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: challenge.gradient,
                ),
                child: Stack(
                  children: [
                    Positioned(
                      bottom: -20,
                      right: -20,
                      child: Text(
                        challenge.emoji,
                        style: const TextStyle(fontSize: 160),
                      ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
                            duration: 3.seconds,
                            begin: const Offset(1, 1),
                            end: const Offset(1.08, 1.08),
                          ),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 20,
                      right: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              if (challenge.isDaily) _Tag(label: '⭐ Daily'),
                              if (challenge.isTrending)
                                _Tag(label: '🔥 Trending'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            challenge.title,
                            style: AppTextStyles.displayMedium
                                .copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Body
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick info row
                _InfoRow(challenge: challenge)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 24),

                // Description
                Text('About this challenge', style: AppTextStyles.titleLarge)
                    .animate(delay: 100.ms)
                    .fadeIn(),
                const SizedBox(height: 10),
                Text(
                  challenge.description,
                  style: AppTextStyles.bodyLarge.copyWith(height: 1.6),
                ).animate(delay: 120.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 24),

                // Tags
                Text('Tags', style: AppTextStyles.titleLarge)
                    .animate(delay: 150.ms)
                    .fadeIn(),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: challenge.tags.map((t) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Text(
                        '#$t',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primaryLight,
                        ),
                      ),
                    );
                  }).toList(),
                ).animate(delay: 180.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 28),

                // Shared with — only when this challenge is shared.
                if (challenge.isShared && challenge.sharedWith.isNotEmpty) ...[
                  Row(
                    children: [
                      Text('Shared with', style: AppTextStyles.titleLarge),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${challenge.sharedWith.length}',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.green),
                        ),
                      ),
                    ],
                  ).animate(delay: 190.ms).fadeIn(),
                  const SizedBox(height: 12),
                  ...challenge.sharedWith.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _SharedConnectionRow(connection: c),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],

                // Reward
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: AppColors.goldGradient,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 32)),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '+${challenge.xpReward} XP',
                            style: AppTextStyles.headlineMedium
                                .copyWith(color: Colors.white),
                          ),
                          Text(
                            'Complete to earn this reward',
                            style: AppTextStyles.bodySmall
                                .copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ],
                  ),
                )
                    .animate(delay: 200.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),
                const SizedBox(height: 32),

                // CTA
                _ChallengeCta(challenge: challenge)
                    .animate(delay: 250.ms)
                    .fadeIn(duration: 500.ms),
                const SizedBox(height: 12),
                OutlineButton(
                  label: 'Save for Later',
                  onTap: () {
                    ToastUtil.info(context, 'Saved to your list');
                    Navigator.of(context).pop();
                  },
                  color: AppColors.textSecondary,
                ).animate(delay: 300.ms).fadeIn(duration: 400.ms),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

final _ctaTickerProvider = StreamProvider.autoDispose<int>(
  (ref) => Stream<int>.periodic(const Duration(seconds: 1), (i) => i),
);

String _formatRemaining(Duration d) {
  final m = d.inMinutes.toString().padLeft(2, '0');
  final s = (d.inSeconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}

class _ChallengeCta extends ConsumerWidget {
  const _ChallengeCta({required this.challenge});
  final ChallengeModel challenge;

  Future<void> _onTap(
      BuildContext context, WidgetRef ref, bool isStarted) async {
    final notifier = ref.read(challengeProvider.notifier);

    if (isStarted) {
      final done = await notifier.completeChallenge(challenge.id);
      if (!context.mounted) return;
      if (done) {
        ToastUtil.success(
            context, '${challenge.emoji} Challenge completed! 🎉');
        Navigator.of(context).pop();

        final completedCount =
            ref.read(challengeProvider).completedChallenges.length;
        final hasReviewed = ref.read(reviewProvider).hasReviewed;
        if (completedCount == 1 && !hasReviewed) {
          showReviewDialog(context);
        }
      } else {
        ToastUtil.error(
          context,
          ref.read(challengeProvider).error ??
              'Could not complete the challenge.',
        );
      }
      return;
    }

    final ok = await notifier.startChallenge(
      challenge.id,
      duration: Duration(minutes: challenge.durationMinutes),
    );
    if (!context.mounted) return;
    if (ok) {
      ToastUtil.success(
        context,
        '${challenge.emoji} Challenge started! Good luck!',
      );
    } else {
      ToastUtil.error(
        context,
        ref.read(challengeProvider).error ?? 'Could not start the challenge.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final id = challenge.id;
    // Rebuild every second while a countdown is running.
    ref.watch(_ctaTickerProvider);
    final isStarted = ref.watch(
      challengeProvider.select((s) => s.isStarted(id)),
    );
    final isStarting = ref.watch(
      challengeProvider.select((s) => s.startingId == id),
    );
    final isCompleting = ref.watch(
      challengeProvider.select((s) => s.completingId == id),
    );
    final completableAt = ref.watch(
      challengeProvider.select((s) => s.completableTimeFor(id)),
    );

    final hasOtherActive = ref.watch(
      challengeProvider.select((s) => s.hasOtherActiveChallenge(id)),
    );

    final remaining = completableAt == null
        ? Duration.zero
        : completableAt.difference(DateTime.now());
    final inProgress = isStarted && remaining > Duration.zero;

    final label = !isStarted
        ? (challenge.isCompleted
            ? 'Play Again 🔁'
            : (hasOtherActive ? 'Another Challenge Active 🔒' : 'Start Challenge 🚀'))
        : inProgress
            ? 'Complete in ${_formatRemaining(remaining)} ⏳'
            : 'Complete Challenge ✅';

    final button = GradientButton(
      label: label,
      gradient: challenge.gradient,
      isLoading: isStarting || isCompleting,
      // Disabled while countdown is active for this challenge.
      onTap: inProgress ? null : () => _onTap(context, ref, isStarted),
      width: double.infinity,
      height: 58,
    );

    // Dim the button while countdown is active or another challenge is active.
    return Opacity(opacity: (inProgress || (hasOtherActive && !isStarted)) ? 0.6 : 1, child: button);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.challenge});
  final dynamic challenge;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _InfoChip(
          icon: Icons.timer_rounded,
          label: AppHelpers.challengeDuration(challenge.durationMinutes),
          color: AppColors.cyan,
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.category_rounded,
          label: challenge.categoryLabel,
          color: AppColors.green,
        ),
        const SizedBox(width: 10),
        _InfoChip(
          icon: Icons.circle,
          label: challenge.difficultyLabel,
          color: challenge.difficultyColor,
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon, required this.label, required this.color});
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      ),
    );
  }
}

/// A single row in the challenge "Shared with" list: avatar, username and level.
class _SharedConnectionRow extends StatelessWidget {
  const _SharedConnectionRow({required this.connection});
  final SharedConnection connection;

  @override
  Widget build(BuildContext context) {
    final name = connection.username;
    Widget avatarFallback() => Center(
          child: name.isEmpty
              ? const Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 20)
              : Text(
                  name[0].toUpperCase(),
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primaryLight),
                ),
        );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: ClipOval(
              child: connection.avatarUrl.isEmpty
                  ? avatarFallback()
                  : CachedNetworkImage(
                      imageUrl: ApiEndpoints.mediaUrl(connection.avatarUrl),
                      fit: BoxFit.cover,
                      placeholder: (_, __) => avatarFallback(),
                      errorWidget: (_, __, ___) => avatarFallback(),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              name.isEmpty ? 'Unknown' : name,
              style: AppTextStyles.titleMedium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'Lv.${connection.level}',
              style: AppTextStyles.labelSmall
                  .copyWith(color: Colors.white, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}
