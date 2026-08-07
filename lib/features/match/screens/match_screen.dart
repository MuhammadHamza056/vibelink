import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/toast_util.dart';
import '../../../shared/widgets/badge_chip.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/match_provider.dart';

class MatchScreen extends ConsumerStatefulWidget {
  const MatchScreen({super.key});

  @override
  ConsumerState<MatchScreen> createState() => _MatchScreenState();
}

class _MatchScreenState extends ConsumerState<MatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _radarController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _radarController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  ShaderMask(
                    shaderCallback: (b) =>
                        AppColors.cyanPurpleGradient.createShader(b),
                    child: Text(
                      '💫 Find Your Vibe',
                      style: AppTextStyles.headlineLarge
                          .copyWith(color: Colors.white),
                    ),
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Anonymous matching based on your energy',
                style: AppTextStyles.bodyMedium,
              ).animate(delay: 100.ms).fadeIn(),
              const SizedBox(height: 40),

              // Radar / Match animation
              _RadarWidget(
                controller: _radarController,
                pulseController: _pulseController,
                status: state.status,
                candidate: state.candidate,
              ),
              const SizedBox(height: 36),

              // Status text
              _StatusSection(state: state),
              const SizedBox(height: 32),

              // Action buttons
              _ActionButtons(state: state, ref: ref, context: context),
              const SizedBox(height: 40),

              // Stats
              _MatchStats(),
            ],
          ),
        ),
      ),
    );
  }
}

class _RadarWidget extends StatelessWidget {
  const _RadarWidget({
    required this.controller,
    required this.pulseController,
    required this.status,
    required this.candidate,
  });

  final AnimationController controller;
  final AnimationController pulseController;
  final MatchStatus status;
  final MatchCandidate? candidate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: 240,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer pulse rings
          ...List.generate(3, (i) {
            return AnimatedBuilder(
              animation: controller,
              builder: (_, __) {
                final offset = i / 3;
                final progress = (controller.value + offset) % 1.0;
                return Transform.scale(
                  scale: 0.4 + (progress * 0.6),
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primaryLight
                            .withValues(alpha: (1 - progress) * 0.4),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            );
          }),
          // Center orb
          AnimatedBuilder(
            animation: pulseController,
            builder: (_, __) => Container(
              width: 100 + (pulseController.value * 8),
              height: 100 + (pulseController.value * 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: status == MatchStatus.found ||
                        status == MatchStatus.connected
                    ? AppColors.greenCyanGradient
                    : AppColors.primaryGradient,
                boxShadow: [
                  BoxShadow(
                    color: (status == MatchStatus.found
                            ? AppColors.green
                            : AppColors.primary)
                        .withValues(alpha: 0.45),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: status == MatchStatus.found ||
                        status == MatchStatus.connected
                    ? const Text('✨', style: TextStyle(fontSize: 40))
                    : const Icon(Icons.radar_rounded,
                        color: Colors.white, size: 44),
              ),
            ),
          ),
          // Candidate dot (when found)
          if (status == MatchStatus.found && candidate != null)
            Positioned(
              top: 30,
              right: 30,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.goldGradient,
                  border: Border.all(color: AppColors.background, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('👤', style: TextStyle(fontSize: 22)),
                ),
              ).animate().scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    curve: Curves.easeOutBack,
                    duration: 600.ms,
                  ),
            ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  const _StatusSection({required this.state});
  final MatchState state;

  @override
  Widget build(BuildContext context) {
    return switch (state.status) {
      MatchStatus.searching => Column(
          children: [
            Text(
              state.error != null ? 'No match yet' : 'Scanning nearby vibes...',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error ?? 'Finding someone compatible with your energy',
              style: AppTextStyles.bodyMedium.copyWith(
                color: state.error != null ? AppColors.warning : null,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn(duration: 400.ms),
      MatchStatus.found => Column(
          children: [
            Text(
              'Vibe Match Found! 🎉',
              style: AppTextStyles.headlineSmall.copyWith(
                color: AppColors.green,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  state.candidate?.username ?? 'Anonymous',
                  style: AppTextStyles.headlineMedium,
                ),
                if (state.candidate?.safetyPulseEnabled == true) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.green.withValues(alpha: 0.5)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_rounded, color: AppColors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Safety Verified',
                          style: TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            if (state.candidate != null)
              Text(
                'Level ${state.candidate!.level}'
                '${state.candidate!.sharedTags.isNotEmpty ? ' · ${state.candidate!.sharedTags.length} shared vibes' : ''}',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.cyan),
              ),
            const SizedBox(height: 16),
            // Vibe score bar
            if (state.candidate != null) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Vibe Match: ', style: AppTextStyles.bodyMedium),
                  Text(
                    '${(state.candidate!.vibeScore * 100).toInt()}%',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppHelpers.vibeMatchColor(state.candidate!.vibeScore),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: state.candidate!.vibeScore,
                    minHeight: 8,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppHelpers.vibeMatchColor(state.candidate!.vibeScore),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                // Shared tags are highlighted (selected); the rest are muted.
                children: state.candidate!.vibeTags
                    .map((t) => VibeTagChip(
                          label: t,
                          isSelected: state.candidate!.sharedTags.contains(t),
                        ))
                    .toList(),
              ),
            ],
          ],
        ).animate().fadeIn(duration: 500.ms).scale(
              begin: const Offset(0.95, 0.95),
              end: const Offset(1, 1),
              curve: Curves.easeOutBack,
            ),
      MatchStatus.connected => Column(
          children: [
            Text('Connected! 🤝', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.green)),
            const SizedBox(height: 8),
            Text('You\'re now vibing with ${state.candidate?.username}',
                style: AppTextStyles.bodyMedium, textAlign: TextAlign.center),
          ],
        ).animate().fadeIn(),
      MatchStatus.skipped => Column(
          children: [
            Text('Looking again...', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text('Finding another match nearby',
                style: AppTextStyles.bodyMedium),
          ],
        ).animate().fadeIn(),
    };
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.state,
    required this.ref,
    required this.context,
  });

  final MatchState state;
  final WidgetRef ref;
  final BuildContext context;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(matchProvider.notifier);
    return switch (state.status) {
      MatchStatus.searching => SizedBox(
          width: double.infinity,
          child: GradientButton(
            label: 'Start Matching',
            gradient: AppColors.cyanPurpleGradient,
            icon: Icons.radar_rounded,
            isLoading: state.isLoading,
            onTap: notifier.startSearch,
          ),
        ),
      MatchStatus.found => Row(
          children: [
            Expanded(
              child: OutlineButton(
                label: 'Skip',
                onTap: () {
                  notifier.skipMatch();
                  ToastUtil.info(context, 'Looking for another match...');
                },
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: GradientButton(
                label: 'Connect ✨',
                gradient: AppColors.greenCyanGradient,
                isLoading: state.isConnecting,
                onTap: state.isConnecting
                    ? null
                    : () async {
                        final ok = await notifier.acceptMatch();
                        if (!context.mounted) return;
                        if (ok) {
                          ToastUtil.success(
                              context, 'Vibe connection made! 🎉');
                        } else {
                          ToastUtil.error(
                            context,
                            ref.read(matchProvider).error ??
                                'Could not connect.',
                          );
                        }
                      },
              ),
            ),
          ],
        ),
      MatchStatus.connected => GradientButton(
          label: 'Find Another Match',
          gradient: AppColors.primaryGradient,
          onTap: () {
            notifier.reset();
            notifier.startSearch();
          },
          width: double.infinity,
        ),
      MatchStatus.skipped => GradientButton(
          label: 'Searching...',
          gradient: AppColors.cyanPurpleGradient,
          isLoading: true,
          onTap: null,
          width: double.infinity,
        ),
    };
  }
}

class _MatchStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How matching works', style: AppTextStyles.titleLarge),
        const SizedBox(height: 16),
        ...[
          ('🔮', 'Anonymous', 'Your identity stays hidden until you connect'),
          ('🎯', 'Vibe-based', 'Matched by energy, interests and location'),
          ('🛡️', 'Safe first', 'Safety Pulse keeps trusted people in the loop'),
        ].map((e) {
          final (emoji, title, desc) = e;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppTextStyles.titleMedium),
                      Text(desc, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    ).animate(delay: 200.ms).fadeIn(duration: 500.ms);
  }
}
