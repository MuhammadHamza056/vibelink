import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/app_helpers.dart';
import '../../models/memory_model.dart';

class MemoryBubbleCard extends StatelessWidget {
  const MemoryBubbleCard({
    super.key,
    required this.memory,
    this.index = 0,
  });

  final MemoryModel memory;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: memory.gradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: memory.gradient.colors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: 8,
            right: 8,
            child: Text(
              memory.challengeEmoji,
              style: const TextStyle(fontSize: 28),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Text(
                  memory.challengeTitle,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  memory.note,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      AppHelpers.timeAgo(memory.createdAt),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                    if (memory.partnerUsername != 'solo') ...[
                      const SizedBox(width: 8),
                      const Icon(Icons.person_rounded,
                          size: 11, color: Colors.white70),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          memory.partnerUsername,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white70,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn(duration: 500.ms).scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1, 1),
          curve: Curves.easeOutBack,
        );
  }
}
