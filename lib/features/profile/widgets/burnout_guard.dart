import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../home/providers/home_provider.dart';

/// Burnout-guard card: a risk meter/message driven by [riskLevel], plus the
/// real guard data from GET /api/home (whether the guard is enabled, days
/// since last active, and the latest nudge) read from [homeProvider].
class BurnoutGuard extends ConsumerWidget {
  const BurnoutGuard({super.key, required this.riskLevel});
  final double riskLevel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final home = ref.watch(homeProvider.select((s) => s.home));

    final isHighRisk = riskLevel >= 0.7;
    final color = isHighRisk ? AppColors.warning : AppColors.green;
    final message = isHighRisk
        ? 'You\'ve been very active! Consider a rest day today 🛌'
        : 'Great balance! Keep your healthy vibe routine going 🌿';

    final nudge = home?.burnoutNudge;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          // Real burnout-guard data from GET /api/home.
          if (home != null) ...[
            const SizedBox(height: 14),
            Divider(color: color.withValues(alpha: 0.2), height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  home.burnoutEnabled
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  size: 16,
                  color: home.burnoutEnabled
                      ? AppColors.green
                      : AppColors.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  home.burnoutEnabled ? 'Guard active' : 'Guard off',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: home.burnoutEnabled
                        ? AppColors.green
                        : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                Text(
                  home.daysSinceActive == 1
                      ? '1 day since active'
                      : '${home.daysSinceActive} days since active',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            if (nudge != null && nudge.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('💡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(nudge, style: AppTextStyles.bodyMedium),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
