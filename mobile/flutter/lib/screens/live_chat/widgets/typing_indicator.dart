import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';

/// Typing indicator widget showing animated dots when agent is typing
class AgentTypingIndicator extends StatelessWidget {
  final String agentName;

  const AgentTypingIndicator({
    super.key,
    required this.agentName,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Agent avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.cyan, AppColors.teal],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Text(
                agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Typing bubble
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.elevated : AppColorsLight.elevated,
              borderRadius: BorderRadius.circular(16).copyWith(
                bottomLeft: const Radius.circular(4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "Agent is typing" text
                Text(
                  '$agentName is typing',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),

                const SizedBox(width: 8),

                // Animated dots
                const _AnimatedDots(),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

/// Animated typing dots
class _AnimatedDots extends StatelessWidget {
  const _AnimatedDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: AppColors.cyan,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .scale(
              begin: const Offset(0.6, 0.6),
              end: const Offset(1.0, 1.0),
              delay: Duration(milliseconds: index * 200),
              duration: const Duration(milliseconds: 400),
            )
            .then()
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(0.6, 0.6),
              duration: const Duration(milliseconds: 400),
            );
      }),
    );
  }
}

/// Compact typing indicator (just dots, no text)
class CompactTypingIndicator extends StatelessWidget {
  const CompactTypingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16).copyWith(
          bottomLeft: const Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (index) {
          return Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                onPlay: (controller) => controller.repeat(),
              )
              .fadeIn(delay: Duration(milliseconds: index * 200))
              .then()
              .fadeOut(delay: const Duration(milliseconds: 400));
        }),
      ),
    );
  }
}

/// User typing indicator (shown to agent - for reference)
class UserTypingIndicator extends StatelessWidget {
  final String userName;

  const UserTypingIndicator({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$userName is typing',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(width: 4),
          const _AnimatedDots(),
        ],
      ),
    ).animate().fadeIn(duration: 150.ms);
  }
}

/// Typing status banner (shown at bottom of chat)
class TypingStatusBanner extends StatelessWidget {
  final String agentName;
  final bool isTyping;

  const TypingStatusBanner({
    super.key,
    required this.agentName,
    required this.isTyping,
  });

  @override
  Widget build(BuildContext context) {
    if (!isTyping) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.cyan.withOpacity(0.1),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.cyan,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                agentName.isNotEmpty ? agentName[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$agentName is typing...',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.cyan,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.2, end: 0);
  }
}
