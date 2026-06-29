import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

/// Glassy social-auth button (Google/Apple) used on the auth screen. Shows an
/// [icon] when provided, otherwise the [emoji] glyph, alongside [label].
class SocialAuthButton extends StatelessWidget {
  const SocialAuthButton({
    super.key,
    required this.label,
    required this.emoji,
    required this.onTap,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final String emoji;
  final IconData? icon;
  final VoidCallback onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null)
                  Icon(icon, color: AppColors.textPrimary, size: 22)
                else
                  Text(emoji,
                      style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                const SizedBox(width: 12),
                Text(label, style: AppTextStyles.titleMedium),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
