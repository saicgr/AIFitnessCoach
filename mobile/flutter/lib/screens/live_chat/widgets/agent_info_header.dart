import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_colors.dart';
import '../live_chat_screen.dart';

/// Agent info header widget for the app bar
/// Shows agent name, avatar, and online status
class AgentInfoHeader extends StatelessWidget {
  final AgentInfo agent;
  final bool isTyping;

  const AgentInfoHeader({
    super.key,
    required this.agent,
    this.isTyping = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Agent avatar with online indicator
        Stack(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.cyan, AppColors.teal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: agent.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(
                        agent.avatarUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => _buildInitial(),
                      ),
                    )
                  : _buildInitial(),
            ),

            // Online status indicator
            Positioned(
              bottom: 0,
              right: 0,
              child: _OnlineIndicator(isOnline: agent.isOnline),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Agent name and status
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              _StatusText(
                isTyping: isTyping,
                isOnline: agent.isOnline,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInitial() {
    return Center(
      child: Text(
        agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

/// Online status indicator dot
class _OnlineIndicator extends StatelessWidget {
  final bool isOnline;

  const _OnlineIndicator({required this.isOnline});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: isOnline ? AppColors.success : AppColors.textMuted,
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.pureBlack,
          width: 2,
        ),
      ),
    );
  }
}

/// Status text (typing, online, etc.)
class _StatusText extends StatelessWidget {
  final bool isTyping;
  final bool isOnline;

  const _StatusText({
    required this.isTyping,
    required this.isOnline,
  });

  @override
  Widget build(BuildContext context) {
    if (isTyping) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Typing',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(width: 4),
          _TypingDots(),
        ],
      ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 300.ms);
    }

    return Text(
      isOnline ? 'Online' : 'Offline',
      style: TextStyle(
        fontSize: 12,
        color: isOnline ? AppColors.success : AppColors.textMuted,
      ),
    );
  }
}

/// Small typing dots for header
class _TypingDots extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            color: AppColors.cyan,
            shape: BoxShape.circle,
          ),
        )
            .animate(
              onPlay: (controller) => controller.repeat(),
            )
            .fadeIn(delay: Duration(milliseconds: index * 150))
            .then()
            .fadeOut(delay: const Duration(milliseconds: 300));
      }),
    );
  }
}

/// Connected to support badge
class ConnectedBadge extends StatelessWidget {
  const ConnectedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: 12,
            color: AppColors.success,
          ),
          const SizedBox(width: 4),
          Text(
            'Connected to support',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.success,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full agent info card (for display in chat area)
class AgentInfoCard extends StatelessWidget {
  final AgentInfo agent;

  const AgentInfoCard({
    super.key,
    required this.agent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.elevated : AppColorsLight.elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.cyan.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          // Agent avatar
          Container(
            width: 48,
            height: 48,
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
                agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Agent info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      agent.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const ConnectedBadge(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'FitWiz Support Agent',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(
          begin: -0.1,
          end: 0,
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// Minimal agent tag (for inline display)
class AgentTag extends StatelessWidget {
  final String name;
  final bool isOnline;

  const AgentTag({
    super.key,
    required this.name,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cyan.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOnline ? AppColors.success : AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.cyan,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
