import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/health_service.dart';
import '../../../widgets/health_connect_sheet.dart';

class DailyActivityCard extends ConsumerStatefulWidget {
  const DailyActivityCard({super.key});

  @override
  ConsumerState<DailyActivityCard> createState() => _DailyActivityCardState();
}

class _DailyActivityCardState extends ConsumerState<DailyActivityCard> {
  @override
  void initState() {
    super.initState();
    // Load activity when widget is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dailyActivityProvider.notifier).loadTodayActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(healthSyncProvider);
    final activityState = ref.watch(dailyActivityProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // If not connected to Health Connect, show connect prompt
    if (!syncState.isConnected) {
      return _NotConnectedCard(
        isDark: isDark,
        elevated: elevated,
        textPrimary: textPrimary,
        textSecondary: textSecondary,
        textMuted: textMuted,
        cardBorder: cardBorder,
        onConnect: () => showHealthConnectSheet(context, ref),
      );
    }

    final activity = activityState.today;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.directions_run,
                    color: AppColors.orange,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s Activity',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        Platform.isAndroid ? 'From Health Connect' : 'From Apple Health',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (activityState.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.orange,
                    ),
                  )
                else
                  IconButton(
                    icon: Icon(Icons.refresh, size: 20, color: textMuted),
                    onPressed: () => ref.read(dailyActivityProvider.notifier).refresh(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Activity stats row
            Row(
              children: [
                // Steps
                Expanded(
                  child: _ActivityStatItem(
                    icon: Icons.directions_walk,
                    value: _formatNumber(activity?.steps ?? 0),
                    label: 'Steps',
                    color: AppColors.cyan,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: cardBorder,
                ),

                // Calories
                Expanded(
                  child: _ActivityStatItem(
                    icon: Icons.local_fire_department,
                    value: _formatNumber(activity?.caloriesBurned.toInt() ?? 0),
                    label: 'Calories',
                    color: AppColors.orange,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),

                // Divider
                Container(
                  width: 1,
                  height: 40,
                  color: cardBorder,
                ),

                // Distance
                Expanded(
                  child: _ActivityStatItem(
                    icon: Icons.straighten,
                    value: _formatDistance(activity?.distanceKm ?? 0),
                    label: 'Distance',
                    color: AppColors.success,
                    textPrimary: textPrimary,
                    textMuted: textMuted,
                  ),
                ),

                // Heart rate (if available)
                if (activity?.restingHeartRate != null) ...[
                  Container(
                    width: 1,
                    height: 40,
                    color: cardBorder,
                  ),
                  Expanded(
                    child: _ActivityStatItem(
                      icon: Icons.favorite,
                      value: '${activity!.restingHeartRate}',
                      label: 'Resting HR',
                      color: AppColors.error,
                      textPrimary: textPrimary,
                      textMuted: textMuted,
                    ),
                  ),
                ],
              ],
            ),

            // Steps progress bar
            if (activity != null && activity.steps > 0) ...[
              const SizedBox(height: 16),
              _StepsProgressBar(
                steps: activity.steps,
                goal: 10000, // Default 10k step goal
                textMuted: textMuted,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }

  String _formatDistance(double km) {
    if (km < 1) {
      return '${(km * 1000).toInt()}m';
    }
    return '${km.toStringAsFixed(1)}km';
  }
}

class _ActivityStatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final Color textPrimary;
  final Color textMuted;

  const _ActivityStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textMuted,
          ),
        ),
      ],
    );
  }
}

class _StepsProgressBar extends StatelessWidget {
  final int steps;
  final int goal;
  final Color textMuted;

  const _StepsProgressBar({
    required this.steps,
    required this.goal,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (steps / goal).clamp(0.0, 1.0);
    final percentage = (progress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Daily Goal',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
            Text(
              '$percentage% • ${_formatSteps(steps)} / ${_formatSteps(goal)}',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: textMuted.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation(
              progress >= 1.0 ? AppColors.success : AppColors.cyan,
            ),
          ),
        ),
      ],
    );
  }

  String _formatSteps(int steps) {
    if (steps >= 1000) {
      return '${(steps / 1000).toStringAsFixed(1)}k';
    }
    return steps.toString();
  }
}

class _NotConnectedCard extends StatelessWidget {
  final bool isDark;
  final Color elevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color cardBorder;
  final VoidCallback onConnect;

  const _NotConnectedCard({
    required this.isDark,
    required this.elevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.cardBorder,
    required this.onConnect,
  });

  @override
  Widget build(BuildContext context) {
    final healthName = Platform.isAndroid ? 'Health Connect' : 'Apple Health';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onConnect,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Platform.isAndroid ? Icons.watch : Icons.favorite,
                  color: AppColors.orange,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Track Your Activity',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Connect $healthName to see steps, calories & more',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
