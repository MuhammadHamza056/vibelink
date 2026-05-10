import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';

class AppHelpers {
  AppHelpers._();

  static String formatDate(DateTime date) =>
      DateFormat('MMM d, yyyy').format(date);

  static String formatTime(DateTime date) => DateFormat('h:mm a').format(date);

  static String timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return formatDate(date);
  }

  static String formatXP(int xp) {
    if (xp >= 1000) return '${(xp / 1000).toStringAsFixed(1)}k';
    return xp.toString();
  }

  static String challengeDuration(int minutes) {
    if (minutes < 60) return '${minutes}min';
    return '${(minutes / 60).toStringAsFixed(0)}h';
  }

  static Color vibeMatchColor(double score) {
    if (score >= 0.8) return AppColors.green;
    if (score >= 0.6) return AppColors.cyan;
    if (score >= 0.4) return AppColors.gold;
    return AppColors.pink;
  }

  static String vibeMatchLabel(double score) {
    if (score >= 0.8) return 'Perfect Match';
    if (score >= 0.6) return 'Great Match';
    if (score >= 0.4) return 'Good Match';
    return 'Low Match';
  }

  static String levelTitle(int level) {
    if (level < 5) return 'Spark';
    if (level < 10) return 'Connector';
    if (level < 20) return 'Vibe Weaver';
    if (level < 35) return 'Social Legend';
    return 'VibeLink Master';
  }

  static Gradient levelGradient(int level) {
    if (level < 5) return AppColors.cyanPurpleGradient;
    if (level < 10) return AppColors.primaryGradient;
    if (level < 20) return AppColors.goldGradient;
    return AppColors.greenCyanGradient;
  }

  static String greetingByTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Hey night owl';
  }

  static void unfocus(BuildContext context) =>
      FocusScope.of(context).unfocus();
}
