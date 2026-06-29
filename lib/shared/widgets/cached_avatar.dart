import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/network/api_endpoints.dart';

/// Circular avatar backed by a cached network image. Falls back to the
/// person's initial (or a person icon) when the url is empty, still loading,
/// or fails to load. Used everywhere a user avatar is shown so images are
/// always cached.
class CachedAvatar extends StatelessWidget {
  const CachedAvatar({
    super.key,
    required this.avatarUrl,
    required this.username,
    this.size = 48,
    this.backgroundColor,
    this.border,
    this.fallback,
  });

  final String avatarUrl;
  final String username;
  final double size;
  final Color? backgroundColor;
  final BoxBorder? border;

  /// Optional custom fallback (e.g. a differently-styled initial). When null a
  /// default initial/icon is used.
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    final name = username.trim();
    final placeholder = fallback ??
        Center(
          child: name.isEmpty
              ? Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: size * 0.45)
              : Text(
                  name[0].toUpperCase(),
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primaryLight,
                    fontSize: size * 0.4,
                  ),
                ),
        );

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? AppColors.cardBg,
        border: border,
      ),
      child: ClipOval(
        child: avatarUrl.isEmpty
            ? placeholder
            : CachedNetworkImage(
                imageUrl: ApiEndpoints.mediaUrl(avatarUrl),
                fit: BoxFit.cover,
                width: size,
                height: size,
                placeholder: (_, __) => placeholder,
                errorWidget: (_, __, ___) => placeholder,
              ),
      ),
    );
  }
}
