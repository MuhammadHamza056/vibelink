import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Backgrounds ─────────────────────────────────────────────────────────────
  static const Color background = Color(0xFF08080F);
  static const Color surface = Color(0xFF111120);
  static const Color cardBg = Color(0xFF181830);
  static const Color cardBorder = Color(0xFF2A2A50);

  // ── Brand ────────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF7B2FBE);
  static const Color primaryLight = Color(0xFF9D4EDD);
  static const Color primaryDark = Color(0xFF5A1D8A);

  // ── Accents ──────────────────────────────────────────────────────────────────
  static const Color cyan = Color(0xFF00D4FF);
  static const Color pink = Color(0xFFFF006E);
  static const Color gold = Color(0xFFFFB700);
  static const Color green = Color(0xFF00F5A0);
  static const Color orange = Color(0xFFFF6B35);

  // ── Text ─────────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFF8888AA);
  static const Color textHint = Color(0xFF444466);

  // ── Status ───────────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF00F5A0);
  static const Color warning = Color(0xFFFFB700);
  static const Color error = Color(0xFFFF3860);

  // ── Gradients ────────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF7B2FBE), Color(0xFFFF006E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cyanPurpleGradient = LinearGradient(
    colors: [Color(0xFF00D4FF), Color(0xFF7B2FBE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFB700), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenCyanGradient = LinearGradient(
    colors: [Color(0xFF00F5A0), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient pinkOrangeGradient = LinearGradient(
    colors: [Color(0xFFFF006E), Color(0xFFFF6B35)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF08080F), Color(0xFF111120)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // ── Glass ────────────────────────────────────────────────────────────────────
  static Color glassWhite = Colors.white.withValues(alpha: 0.06);
  static Color glassBorder = Colors.white.withValues(alpha: 0.10);
}
