import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/providers/calibration_provider.dart';
import '../widgets/widgets.dart';

/// The calibration section for strength testing settings.
///
/// Allows users to:
/// - Start a new calibration workout to assess their strength
/// - View their last calibration results
/// - See their strength baselines
/// - Recalibrate after 30 days
class CalibrationSection extends ConsumerStatefulWidget {
  const CalibrationSection({super.key});

  @override
  ConsumerState<CalibrationSection> createState() => _CalibrationSectionState();
}

class _CalibrationSectionState extends ConsumerState<CalibrationSection> {
  @override
  void initState() {
    super.initState();
    // Load calibration status on mount
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationStatusProvider.notifier).refreshStatus();
    });
  }

  /// Help items explaining calibration features
  static const List<Map<String, dynamic>> _calibrationHelpItems = [
    {
      'icon': Icons.science,
      'title': 'Strength Calibration',
      'description':
          'A quick workout to assess your current strength levels. The AI uses this data to personalize your workouts with appropriate weights and rep ranges.',
      'color': AppColors.cyan,
    },
    {
      'icon': Icons.analytics,
      'title': 'AI Analysis',
      'description':
          'After completing the calibration, our AI analyzes your performance and may suggest adjusting your fitness level for better workout personalization.',
      'color': AppColors.purple,
    },
    {
      'icon': Icons.fitness_center,
      'title': 'Strength Baselines',
      'description':
          'Your calibration establishes baseline weights for key exercises. The AI uses these to calculate starting weights for similar movements.',
      'color': AppColors.orange,
    },
    {
      'icon': Icons.refresh,
      'title': 'Recalibration',
      'description':
          'As you get stronger, you can recalibrate every 30 days to update your baselines and ensure workouts remain challenging.',
      'color': AppColors.success,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;

    final calibrationStatus = ref.watch(calibrationStatusProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'CALIBRATION',
          subtitle: 'Strength assessment & baselines',
          helpTitle: 'About Calibration',
          helpItems: _calibrationHelpItems,
        ),
        const SizedBox(height: 12),
        Material(
          color: elevated,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              // Calibration status tile
              _buildCalibrationStatusTile(
                context,
                isDark,
                textPrimary,
                textMuted,
                elevated,
                calibrationStatus,
              ),

              Divider(height: 1, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),

              // Start/Recalibrate tile
              _buildCalibrationActionTile(
                context,
                isDark,
                textPrimary,
                textMuted,
                calibrationStatus,
              ),

              // View results tile (only if completed)
              if (calibrationStatus.status?.isCompleted == true) ...[
                Divider(height: 1, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
                _buildViewResultsTile(
                  context,
                  isDark,
                  textPrimary,
                  textMuted,
                  calibrationStatus,
                ),
              ],

              // View baselines tile
              Divider(height: 1, color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder),
              _buildViewBaselinesTile(
                context,
                isDark,
                textPrimary,
                textMuted,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCalibrationStatusTile(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    CalibrationStatusState calibrationStatus,
  ) {
    final status = calibrationStatus.status;
    final isLoading = calibrationStatus.isLoading;

    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (isLoading) {
      statusText = 'Loading...';
      statusColor = textMuted;
      statusIcon = Icons.hourglass_empty;
    } else if (status == null) {
      statusText = 'Not checked';
      statusColor = textMuted;
      statusIcon = Icons.help_outline;
    } else if (status.isCompleted) {
      statusText = 'Completed';
      statusColor = AppColors.success;
      statusIcon = Icons.check_circle;
    } else if (status.isSkipped) {
      statusText = 'Skipped';
      statusColor = AppColors.orange;
      statusIcon = Icons.skip_next;
    } else {
      statusText = 'Pending';
      statusColor = AppColors.cyan;
      statusIcon = Icons.pending;
    }

    return SettingTile(
      icon: Icons.science,
      iconColor: AppColors.cyan,
      title: 'Calibration Status',
      subtitle: statusText,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Icon(statusIcon, color: statusColor, size: 20),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
      onTap: () {
        // Refresh status
        ref.read(calibrationStatusProvider.notifier).refreshStatus();
      },
    );
  }

  Widget _buildCalibrationActionTile(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    CalibrationStatusState calibrationStatus,
  ) {
    final status = calibrationStatus.status;
    final canRecalibrate = status?.recalibrationRecommended ?? true;
    final isCompleted = status?.isCompleted ?? false;

    String title;
    String subtitle;
    IconData icon;
    Color iconColor;
    bool enabled = true;

    if (!isCompleted) {
      title = 'Start Calibration';
      subtitle = 'Take a ~20 min test to assess your strength';
      icon = Icons.play_circle;
      iconColor = AppColors.success;
    } else if (canRecalibrate) {
      title = 'Recalibrate';
      subtitle = 'Update your strength baselines';
      icon = Icons.refresh;
      iconColor = AppColors.cyan;
    } else {
      title = 'Recalibrate';
      subtitle = 'Available after 30 days from last calibration';
      icon = Icons.lock_clock;
      iconColor = textMuted;
      enabled = false;
    }

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: SettingTile(
        icon: icon,
        iconColor: iconColor,
        title: title,
        subtitle: subtitle,
        trailing: Icon(
          Icons.chevron_right,
          color: enabled ? textMuted : textMuted.withValues(alpha: 0.5),
        ),
        onTap: enabled
            ? () {
                // Navigate to calibration intro screen
                context.push('/calibration/intro');
              }
            : null,
      ),
    );
  }

  Widget _buildViewResultsTile(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    CalibrationStatusState calibrationStatus,
  ) {
    final calibrationId = calibrationStatus.status?.calibrationId;

    return SettingTile(
      icon: Icons.analytics,
      iconColor: AppColors.purple,
      title: 'View Last Results',
      subtitle: 'See your calibration analysis and recommendations',
      trailing: Icon(Icons.chevron_right, color: textMuted),
      onTap: () {
        if (calibrationId != null) {
          context.push('/calibration/results', extra: {
            'calibrationId': calibrationId,
          });
        }
      },
    );
  }

  Widget _buildViewBaselinesTile(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return SettingTile(
      icon: Icons.fitness_center,
      iconColor: AppColors.orange,
      title: 'Strength Baselines',
      subtitle: 'View your established strength levels',
      trailing: Icon(Icons.chevron_right, color: textMuted),
      onTap: () {
        // Load and show baselines
        ref.read(strengthBaselinesProvider.notifier).loadBaselines();
        _showBaselinesSheet(context, isDark, textPrimary, textMuted);
      },
    );
  }

  void _showBaselinesSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final background = isDark ? AppColors.background : AppColorsLight.background;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center, color: AppColors.orange, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Strength Baselines',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final baselinesState = ref.watch(strengthBaselinesProvider);

                    if (baselinesState.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (baselinesState.error != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, color: AppColors.error, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load baselines',
                              style: TextStyle(color: textMuted),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () {
                                ref.read(strengthBaselinesProvider.notifier).loadBaselines();
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }

                    final baselines = baselinesState.baselines;

                    if (baselines.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, color: textMuted, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              'No baselines yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Complete a calibration workout to establish\nyour strength baselines.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textMuted),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: baselines.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final baseline = baselines[index];
                        return Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: elevated,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.fitness_center,
                                    color: AppColors.orange,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      baseline.exerciseName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      baseline.muscleGroup,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${baseline.baselineWeight.toStringAsFixed(0)} lbs',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.cyan,
                                    ),
                                  ),
                                  if (baseline.estimatedOneRepMax > 0)
                                    Text(
                                      'Est. 1RM: ${baseline.estimatedOneRepMax.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textMuted,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
