import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/app_helpers.dart';
import '../../../core/utils/toast_util.dart';
import '../../../models/notification_model.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/notifications_provider.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Notifications', style: AppTextStyles.headlineSmall),
        actions: [
          if (state.pendingCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${state.pendingCount} pending',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primaryLight),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _Body(state: state),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.state});
  final NotificationsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (state.error != null && state.notifications.isEmpty) {
      return _CenteredMessage(
        emoji: '😕',
        message: state.error!,
        onRetry: () => ref.read(notificationsProvider.notifier).refresh(),
      );
    }

    if (state.notifications.isEmpty) {
      return const _CenteredMessage(
        emoji: '🔔',
        message: 'You\'re all caught up — no notifications yet.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      backgroundColor: AppColors.cardBg,
      onRefresh: () => ref.read(notificationsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: state.notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _NotificationCard(
          notification: state.notifications[i],
        ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms).slideY(
              begin: 0.1,
              end: 0,
            ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});
  final NotificationModel notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = notification.user;
    final responding = ref.watch(
      notificationsProvider.select((s) => s.respondingId == notification.id),
    );
    final respondingIsAccept = ref.watch(
      notificationsProvider.select((s) => s.respondingIsAccept),
    );
    // Buttons only make sense for an actionable request still awaiting a reply.
    final showActions = notification.actionable && notification.isPending;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: notification.isPending
              ? AppColors.primary.withValues(alpha: 0.4)
              : AppColors.cardBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Avatar(username: user?.username ?? '', avatarUrl: user?.avatarUrl ?? ''),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                    if (notification.isPending)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Pending',
                          style: AppTextStyles.labelSmall
                              .copyWith(color: AppColors.warning, fontSize: 10),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(notification.message, style: AppTextStyles.bodyMedium),
                if (user != null && user.vibeTags.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: user.vibeTags
                        .take(4)
                        .map((t) => _MiniTag(label: t))
                        .toList(),
                  ),
                ],
                if (notification.createdAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    AppHelpers.timeAgo(notification.createdAt!),
                    style: AppTextStyles.bodySmall
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
                if (showActions) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlineButton(
                          label: 'Reject',
                          height: 44,
                          color: AppColors.error,
                          onTap: responding
                              ? null
                              : () => _respond(context, ref, accept: false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GradientButton(
                          label: 'Accept',
                          height: 44,
                          gradient: AppColors.greenCyanGradient,
                          isLoading: responding && respondingIsAccept,
                          onTap: responding
                              ? null
                              : () => _respond(context, ref, accept: true),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respond(
    BuildContext context,
    WidgetRef ref, {
    required bool accept,
  }) async {
    final notifier = ref.read(notificationsProvider.notifier);
    final ok =
        await (accept ? notifier.accept(notification.id) : notifier.reject(notification.id));
    if (!context.mounted) return;
    if (ok) {
      ToastUtil.success(
        context,
        accept ? 'Connection accepted 🎉' : 'Request rejected',
      );
    } else {
      ToastUtil.error(
        context,
        ref.read(notificationsProvider).error ?? 'Something went wrong.',
      );
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.username, required this.avatarUrl});
  final String username;
  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    Widget fallback() => Center(
          child: username.isEmpty
              ? const Icon(Icons.person_rounded,
                  color: AppColors.textSecondary, size: 22)
              : Text(
                  username[0].toUpperCase(),
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.primaryLight),
                ),
        );

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.background,
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: ClipOval(
        child: avatarUrl.isEmpty
            ? fallback()
            : CachedNetworkImage(
                imageUrl: ApiEndpoints.mediaUrl(avatarUrl),
                fit: BoxFit.cover,
                placeholder: (_, __) => fallback(),
                errorWidget: (_, __, ___) => fallback(),
              ),
      ),
    );
  }
}

class _MiniTag extends StatelessWidget {
  const _MiniTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall
            .copyWith(color: AppColors.textSecondary, fontSize: 11),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.emoji,
    required this.message,
    this.onRetry,
  });

  final String emoji;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 44)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              GradientButton(label: 'Retry', onTap: onRetry),
            ],
          ],
        ),
      ),
    );
  }
}
