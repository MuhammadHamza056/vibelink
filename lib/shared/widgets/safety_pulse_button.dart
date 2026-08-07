import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class SafetyPulseButton extends StatefulWidget {
  const SafetyPulseButton({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.onLongPress,
  });

  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback? onLongPress;

  @override
  State<SafetyPulseButton> createState() => _SafetyPulseButtonState();
}

class _SafetyPulseButtonState extends State<SafetyPulseButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isActive ? AppColors.green : AppColors.error;

    return GestureDetector(
      onTap: widget.onToggle,
      onLongPress: widget.onLongPress,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.isActive)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (_, __) => Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.4),
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(
                      alpha: 0.15 * (1 - _pulseController.value),
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: widget.isActive
                    ? [AppColors.green, AppColors.cyan]
                    : [AppColors.error, AppColors.pink],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.shield_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}

class SafetyPulseBanner extends StatelessWidget {
  const SafetyPulseBanner({
    super.key,
    required this.isActive,
    required this.onToggle,
    this.onLongPressSOS,
  });

  final bool isActive;
  final VoidCallback onToggle;
  final VoidCallback? onLongPressSOS;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      onLongPress: onLongPressSOS,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isActive
                ? [AppColors.green.withValues(alpha: 0.2), AppColors.cyan.withValues(alpha: 0.1)]
                : [AppColors.error.withValues(alpha: 0.15), AppColors.pink.withValues(alpha: 0.08)],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? AppColors.green.withValues(alpha: 0.4)
                : AppColors.error.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            SafetyPulseButton(
              isActive: isActive,
              onToggle: onToggle,
              onLongPress: onLongPressSOS,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isActive ? 'Safety Pulse: ON' : 'Safety Pulse: OFF',
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isActive ? AppColors.green : AppColors.error,
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.error.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Hold for SOS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.error,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? 'Trusted contacts notified • Hold shield 2s for Emergency SOS'
                        : 'Tap to activate peace of mind mode',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

