import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Card widget for displaying a challenge
class ChallengeCard extends StatelessWidget {
  final Map<String, dynamic> challenge;
  final bool isReceived; // true if received, false if sent
  final VoidCallback? onAccept;
  final VoidCallback? onDecline;
  final VoidCallback? onViewDetails;

  const ChallengeCard({
    super.key,
    required this.challenge,
    required this.isReceived,
    this.onAccept,
    this.onDecline,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final status = challenge['status'] as String;
    final workoutName = challenge['workout_name'] as String;
    final workoutData = challenge['workout_data'] as Map<String, dynamic>;
    final createdAt = DateTime.parse(challenge['created_at'] as String);
    final challengeMessage = challenge['challenge_message'] as String?;

    // User info (from or to depending on isReceived)
    final userName = isReceived
        ? (challenge['from_user_name'] as String? ?? 'Unknown User')
        : (challenge['to_user_name'] as String? ?? 'Unknown User');
    final userAvatar = isReceived
        ? challenge['from_user_avatar'] as String?
        : challenge['to_user_avatar'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with user info and status
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: AppColors.cyan.withValues(alpha: 0.2),
                    backgroundImage: userAvatar != null ? NetworkImage(userAvatar) : null,
                    child: userAvatar == null
                        ? Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.cyan,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          timeago.format(createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status),
                ],
              ),

              const SizedBox(height: 12),

              // Challenge title
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: AppColors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isReceived
                          ? 'Challenged you to beat'
                          : 'You challenged to beat',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                workoutName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),

              // Stats to beat
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (workoutData['duration_minutes'] != null)
                    _buildStat('⏱️', '${workoutData['duration_minutes']} min'),
                  if (workoutData['total_volume'] != null)
                    _buildStat('💪', '${workoutData['total_volume']} lbs'),
                  if (workoutData['exercises_count'] != null)
                    _buildStat('🏋️', '${workoutData['exercises_count']} exercises'),
                ],
              ),

              // Challenge message (trash talk)
              if (challengeMessage != null && challengeMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challengeMessage,
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Action buttons for pending challenges
              if (status == 'pending' && isReceived) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onDecline?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: const Text('Decline'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onAccept?.call();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text(
                          'Accept Challenge',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Show result if completed
              if (status == 'completed' && challenge['did_beat'] != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: challenge['did_beat'] == true
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: challenge['did_beat'] == true
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        challenge['did_beat'] == true
                            ? Icons.emoji_events
                            : Icons.fitness_center,
                        color: challenge['did_beat'] == true ? Colors.green : AppColors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challenge['did_beat'] == true
                              ? isReceived
                                  ? '🎉 You beat the challenge!'
                                  : '💪 They beat your challenge!'
                              : isReceived
                                  ? '👊 Good attempt! Keep training!'
                                  : '🏆 You kept your record!'
                          ,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: challenge['did_beat'] == true ? Colors.green : AppColors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildStat(String emoji, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.orange;
      case 'accepted':
        return AppColors.cyan;
      case 'completed':
        return Colors.green;
      case 'declined':
        return Colors.red;
      case 'expired':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'PENDING';
      case 'accepted':
        return 'ACCEPTED';
      case 'completed':
        return 'COMPLETED';
      case 'declined':
        return 'DECLINED';
      case 'expired':
        return 'EXPIRED';
      default:
        return status.toUpperCase();
    }
  }
}
