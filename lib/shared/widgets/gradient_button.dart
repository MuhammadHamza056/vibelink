import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Whether a given [GradientButton] is currently pressed. Keyed per button
/// instance (by a unique token from its state) so each button animates
/// independently, and auto-disposes when the button leaves the tree.
final _buttonPressedProvider =
    AutoDisposeStateProvider.family<bool, Object>((ref, _) => false);

class GradientButton extends ConsumerStatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onTap,
    this.gradient = AppColors.primaryGradient,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final LinearGradient gradient;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  ConsumerState<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends ConsumerState<GradientButton> {
  // Unique identity for this button's entry in [_buttonPressedProvider].
  final Object _token = Object();

  @override
  Widget build(BuildContext context) {
    // While loading we swallow taps so the action can't be fired twice.
    final disabled = widget.isLoading || widget.onTap == null;
    final pressed = ref.watch(_buttonPressedProvider(_token));
    void setPressed(bool value) =>
        ref.read(_buttonPressedProvider(_token).notifier).state = value;

    return GestureDetector(
      onTapDown: disabled ? null : (_) => setPressed(true),
      onTapUp: disabled
          ? null
          : (_) {
              setPressed(false);
              widget.onTap?.call();
            },
      onTapCancel: disabled ? null : () => setPressed(false),
      child: AnimatedScale(
        scale: pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.onTap == null
                ? const LinearGradient(colors: [Color(0xFF333355), Color(0xFF333355)])
                : widget.gradient,
            borderRadius: BorderRadius.circular(widget.borderRadius),
            boxShadow: widget.onTap == null
                ? null
                : [
                    BoxShadow(
                      color: widget.gradient.colors.first.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

class OutlineButton extends StatelessWidget {
  const OutlineButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.color = AppColors.primary,
    this.height = 56,
    this.borderRadius = 16,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
