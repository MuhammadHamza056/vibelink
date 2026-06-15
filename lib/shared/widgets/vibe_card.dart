import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class VibeStatCard extends StatelessWidget {
  const VibeStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              // Scale the value down rather than overflow the fixed grid cell,
              // which keeps the card intact under larger text scales too.
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTextStyles.headlineMedium.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class NearbyVibersRow extends StatelessWidget {
  const NearbyVibersRow({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    const avatarCount = 5;
    return Row(
      children: [
        SizedBox(
          width: avatarCount * 28.0 + 8,
          height: 36,
          child: Stack(
            children: List.generate(avatarCount, (i) {
              return Positioned(
                left: i * 24.0,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: _gradientForIndex(i),
                    border: Border.all(color: AppColors.background, width: 2),
                  ),
                  child: Center(
                    child: Text(
                      _emojiForIndex(i),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(width: 12),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '+$count ',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: 'people vibing nearby',
                style: AppTextStyles.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }

  LinearGradient _gradientForIndex(int i) {
    const gradients = [
      AppColors.primaryGradient,
      AppColors.cyanPurpleGradient,
      AppColors.goldGradient,
      AppColors.greenCyanGradient,
      AppColors.pinkOrangeGradient,
    ];
    return gradients[i % gradients.length];
  }

  String _emojiForIndex(int i) {
    const emojis = ['😎', '🎵', '🎨', '⚡', '🌿'];
    return emojis[i % emojis.length];
  }
}
