import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/scores.dart';
import '../../../../data/providers/recovery_provider.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';

/// Compact readiness indicator card for home screen
/// Shows today's readiness score or prompts for check-in
class HomeReadinessCard extends ConsumerStatefulWidget {
  const HomeReadinessCard({super.key});

  @override
  ConsumerState<HomeReadinessCard> createState() => _HomeReadinessCardState();
}

class _HomeReadinessCardState extends ConsumerState<HomeReadinessCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReadiness();
    });
  }

  void _loadReadiness() {
    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;
    if (userId != null) {
      ref.read(scoresProvider.notifier).loadScoresOverview(userId: userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scoresState = ref.watch(scoresProvider);
    final hasCheckedIn = scoresState.hasCheckedInToday;
    final todayReadiness = scoresState.todayReadiness;

    // Don't show if still loading initial data
    if (scoresState.isLoading && scoresState.overview == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: hasCheckedIn && todayReadiness != null
          ? _buildCheckedInCard(context, todayReadiness, isDark)
          : _buildCheckInPromptCard(context, isDark),
    );
  }

  Widget _buildCheckedInCard(
    BuildContext context,
    ReadinessScore readiness,
    bool isDark,
  ) {
    final levelColor = Color(readiness.levelColor);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final sleep = ref.watch(sleepProvider).valueOrNull;
    final recovery = ref.watch(recoveryProvider).valueOrNull;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/stats');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: levelColor.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Readiness score circle
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: levelColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: levelColor.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    '${readiness.readinessScore}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Today's Readiness",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: levelColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            readiness.readinessLevel.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: levelColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    if (readiness.aiWorkoutRecommendation != null)
                      Text(
                        readiness.aiWorkoutRecommendation!,
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (sleep != null || recovery?.restingHR != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (sleep != null)
                            _buildBadge(
                              icon: Icons.bedtime_outlined,
                              text: _formatSleepDuration(sleep.totalMinutes),
                              color: _sleepQualityColor(sleep.quality),
                            ),
                          if (sleep != null && recovery?.restingHR != null)
                            const SizedBox(width: 8),
                          if (recovery?.restingHR != null)
                            _buildBadge(
                              icon: Icons.favorite_outline,
                              text: '${recovery!.restingHR} bpm',
                              color: _restingHRColor(recovery.score),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                Icons.check_circle,
                color: levelColor,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInPromptCard(BuildContext context, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentColor = AppColors.cyan;

    final recovery = ref.watch(recoveryProvider).valueOrNull;
    final sleep = ref.watch(sleepProvider).valueOrNull;
    final hasObjectiveData = recovery != null;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticService.light();
          context.push('/stats');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withOpacity(0.3),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accentColor.withOpacity(0.05),
                Colors.transparent,
              ],
            ),
          ),
          child: Row(
            children: [
              // Sun icon
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.wb_sunny_outlined,
                  color: accentColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'How are you feeling?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasObjectiveData
                          ? 'Estimated: ${recovery.label}'
                          : 'Check in to optimize your workout',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                    if (hasObjectiveData &&
                        (sleep != null || recovery.restingHR != null)) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          if (sleep != null)
                            _buildBadge(
                              icon: Icons.bedtime_outlined,
                              text: _formatSleepDuration(sleep.totalMinutes),
                              color: _sleepQualityColor(sleep.quality),
                            ),
                          if (sleep != null && recovery.restingHR != null)
                            const SizedBox(width: 8),
                          if (recovery.restingHR != null)
                            _buildBadge(
                              icon: Icons.favorite_outline,
                              text: '${recovery.restingHR} bpm',
                              color: _restingHRColor(recovery.score),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Check In',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatSleepDuration(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours}h ${minutes}m';
  }

  Color _sleepQualityColor(String quality) {
    switch (quality) {
      case 'excellent':
      case 'good':
        return const Color(0xFF4CAF50);
      case 'fair':
        return const Color(0xFFFF9800);
      default:
        return const Color(0xFFF44336);
    }
  }

  Color _restingHRColor(int recoveryScore) {
    if (recoveryScore >= 60) return const Color(0xFF4CAF50);
    if (recoveryScore >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}
