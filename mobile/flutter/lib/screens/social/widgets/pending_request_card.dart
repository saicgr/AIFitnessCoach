import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Pending Request Card - Compact card for displaying pending friend requests
class PendingRequestCard extends StatelessWidget {
  final Map<String, dynamic> request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onViewProfile;

  const PendingRequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    this.onViewProfile,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final name = request['from_user_name'] as String? ?? 'Unknown';
    final avatarUrl = request['from_user_avatar'] as String?;
    final message = request['message'] as String?;

    return Container(
      width: 180,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: isDark
                ? AppColors.cyan.withValues(alpha: 0.2)
                : AppColorsLight.accent.withValues(alpha: 0.1),
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.cyan : AppColorsLight.accent,
                    ),
                  )
                : null,
          ),
          const SizedBox(height: 8),

          // Name
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Message (if any)
          if (message != null && message.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '"$message"',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],

          const Spacer(),

          // View Profile button
          if (onViewProfile != null) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onViewProfile,
                icon: const Icon(Icons.person_outline_rounded, size: 16),
                label: const Text('View Profile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: BorderSide(color: AppColors.cardBorder.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? AppColors.coral : AppColorsLight.coral,
                    side: BorderSide(
                      color: (isDark ? AppColors.coral : AppColorsLight.coral)
                          .withValues(alpha: 0.3),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  onPressed: onAccept,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.cyan,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Icon(Icons.check_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
