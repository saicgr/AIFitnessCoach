import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Signature-v2 onPrimary ink — text/icon color on the solid orange accent.
const Color _onAccent = Color(0xFF160B03);

/// Card widget for displaying a challenge — signature-v2 styling.
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
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;

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
        border: Border.all(color: cardBorder),
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
                    backgroundColor: orange.withValues(alpha: 0.15),
                    backgroundImage:
                        userAvatar != null ? NetworkImage(userAvatar) : null,
                    child: userAvatar == null
                        ? Text(
                            userName[0].toUpperCase(),
                            style: ZType.disp(16, color: orange),
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
                          style: ZType.sans(15,
                              color: textPrimary, weight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          timeago.format(createdAt),
                          style: ZType.lbl(10.5,
                              color: textMuted, letterSpacing: 1.0),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(status, isDark),
                ],
              ),

              const SizedBox(height: 14),

              // Challenge label kicker
              Text(
                (isReceived
                        ? AppLocalizations.of(context)
                            .challengeCardChallengedYouToBeat
                        : AppLocalizations.of(context)
                            .challengeCardYouChallengedToBeat)
                    .toUpperCase(),
                style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1.6),
              ),
              const SizedBox(height: 6),
              Text(
                workoutName,
                style: ZType.disp(20, color: orange, letterSpacing: 0.5),
              ),

              // Stats to beat
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (workoutData['duration_minutes'] != null)
                    _buildStat('⏱️', '${workoutData['duration_minutes']} MIN',
                        textMuted),
                  if (workoutData['total_volume'] != null)
                    _buildStat(
                        '💪', '${workoutData['total_volume']} LBS', textMuted),
                  if (workoutData['exercises_count'] != null)
                    _buildStat('🏋️',
                        '${workoutData['exercises_count']} EXERCISES', textMuted),
                ],
              ),

              // Challenge message (trash talk)
              if (challengeMessage != null && challengeMessage.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          challengeMessage,
                          style: ZType.ser(13.5, color: textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Expiry countdown for pending challenges
              if (status == 'pending' && challenge['expires_at'] != null) ...[
                const SizedBox(height: 12),
                _buildExpiryCountdown(
                    context, DateTime.parse(challenge['expires_at'] as String)),
              ],

              // Action buttons for pending challenges
              if (status == 'pending' && isReceived) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          onDecline?.call();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.5)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          AppLocalizations.of(context)
                              .challengeCardDecline
                              .toUpperCase(),
                          style: ZType.lbl(12.5,
                              color: AppColors.error, letterSpacing: 1.2),
                        ),
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
                          backgroundColor: orange,
                          foregroundColor: _onAccent,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.check,
                            size: 18, color: _onAccent),
                        label: Text(
                          AppLocalizations.of(context)
                              .challengeCardAcceptChallenge
                              .toUpperCase(),
                          style: ZType.lbl(13,
                              color: _onAccent, letterSpacing: 1.2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Show result if completed
              if (status == 'completed' && challenge['did_beat'] != null) ...[
                const SizedBox(height: 12),
                _buildResultBanner(orange),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultBanner(Color orange) {
    final didBeat = challenge['did_beat'] == true;
    final accent = didBeat ? Colors.green : orange;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(
            didBeat ? Icons.emoji_events : Icons.fitness_center,
            color: accent,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              didBeat
                  ? isReceived
                      ? '🎉 You beat the challenge!'
                      : '💪 They beat your challenge!'
                  : isReceived
                      ? '👊 Good attempt! Keep training!'
                      : '🏆 You kept your record!',
              style: ZType.sans(13,
                  color: accent, weight: FontWeight.w700, height: 1.2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final color = _getStatusColor(status, isDark);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: ZType.lbl(10.5, color: color, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildStat(String emoji, String value, Color textMuted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 5),
        Text(
          value,
          style: ZType.data(12, color: textMuted),
        ),
      ],
    );
  }

  Color _getStatusColor(String status, bool isDark) {
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    switch (status) {
      case 'pending':
        return orange;
      case 'accepted':
        return isDark ? AppColors.cyan : AppColorsLight.cyan;
      case 'completed':
        return Colors.green;
      case 'declined':
        return AppColors.error;
      case 'expired':
        return muted;
      default:
        return muted;
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

  Widget _buildExpiryCountdown(BuildContext context, DateTime expiresAt) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orange = isDark ? AppColors.orange : AppColorsLight.orange;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final now = DateTime.now();
    final remaining = expiresAt.difference(now);

    if (remaining.isNegative) {
      return Row(
        children: [
          const Icon(Icons.timer_off, size: 14, color: AppColors.error),
          const SizedBox(width: 5),
          Text(
            AppLocalizations.of(context).challengeCardExpired.toUpperCase(),
            style: ZType.lbl(11, color: AppColors.error, letterSpacing: 1.2),
          ),
        ],
      );
    }

    final days = remaining.inDays;
    final hours = remaining.inHours % 24;
    final minutes = remaining.inMinutes % 60;

    // Color based on urgency
    Color countdownColor;
    if (remaining.inHours < 24) {
      countdownColor = AppColors.error;
    } else if (remaining.inHours < 48) {
      countdownColor = orange;
    } else {
      countdownColor = muted;
    }

    String timeText;
    if (days > 0) {
      timeText = '${days}D ${hours}H REMAINING';
    } else if (hours > 0) {
      timeText = '${hours}H ${minutes}M REMAINING';
    } else {
      timeText = '${minutes}M REMAINING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: countdownColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: countdownColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: countdownColor),
          const SizedBox(width: 5),
          Text(
            timeText,
            style: ZType.data(11, color: countdownColor),
          ),
        ],
      ),
    );
  }
}
