import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/toast_util.dart';
import '../../../models/connection_model.dart';
import '../../../shared/widgets/badge_chip.dart';
import '../../../shared/widgets/gradient_button.dart';
import '../providers/connections_provider.dart';

class ConnectionsScreen extends ConsumerWidget {
  const ConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionsProvider);

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
        title: Text('Connections', style: AppTextStyles.headlineSmall),
        actions: [
          if (state.count > 0)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${state.count}',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.primaryLight),
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
  final ConnectionsState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading && state.connections.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primaryLight),
      );
    }

    if (state.error != null && state.connections.isEmpty) {
      return _CenteredMessage(
        emoji: '😕',
        message: state.error!,
        onRetry: () => ref.read(connectionsProvider.notifier).refresh(),
      );
    }

    if (state.connections.isEmpty) {
      return const _CenteredMessage(
        emoji: '🤝',
        message: 'No connections yet.\nMatch with someone to start vibing.',
      );
    }

    return RefreshIndicator(
      color: AppColors.primaryLight,
      backgroundColor: AppColors.cardBg,
      onRefresh: () => ref.read(connectionsProvider.notifier).refresh(),
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: state.connections.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _ConnectionCard(
          connection: state.connections[i],
        ).animate(delay: (i * 60).ms).fadeIn(duration: 350.ms).slideY(
              begin: 0.1,
              end: 0,
            ),
      ),
    );
  }
}

class _ConnectionCard extends ConsumerWidget {
  const _ConnectionCard({required this.connection});
  final ConnectionModel connection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = connection.user;
    final leaving = ref.watch(
      connectionsProvider
          .select((s) => s.leavingId == connection.connectionId),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(username: user.username, avatarUrl: user.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username.isEmpty ? 'Unknown' : user.username,
                      style: AppTextStyles.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Level ${user.level}'
                      '${connection.sharedChallengeId != null ? ' · Shared challenge' : ''}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: AppColors.cyan),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user.vibeTags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.vibeTags
                  .map((t) => VibeTagChip(label: t, isSelected: true))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlineButton(
              label: 'Leave Connection',
              height: 44,
              color: AppColors.error,
              icon: Icons.link_off_rounded,
              onTap: leaving
                  ? null
                  : () => _confirmLeave(context, ref, connection),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave(
    BuildContext context,
    WidgetRef ref,
    ConnectionModel connection,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Leave connection?', style: AppTextStyles.titleLarge),
        content: Text(
          'You\'ll no longer be connected with '
          '${connection.user.username.isEmpty ? 'this person' : connection.user.username}.',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel',
                style: AppTextStyles.titleMedium
                    .copyWith(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Leave',
                style:
                    AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final ok =
        await ref.read(connectionsProvider.notifier).leave(connection.connectionId);
    if (!context.mounted) return;
    if (ok) {
      ToastUtil.success(context, 'Connection removed');
    } else {
      ToastUtil.error(
        context,
        ref.read(connectionsProvider).error ?? 'Could not leave.',
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
                  color: AppColors.textSecondary, size: 24)
              : Text(
                  username[0].toUpperCase(),
                  style: AppTextStyles.titleLarge
                      .copyWith(color: AppColors.primaryLight),
                ),
        );

    return Container(
      width: 52,
      height: 52,
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
