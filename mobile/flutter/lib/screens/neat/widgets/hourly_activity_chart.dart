import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// A horizontal scrollable bar chart showing hourly step activity.
///
/// Features:
/// - 24 bars for 24 hours
/// - Bar height scaled based on steps in that hour
/// - Red bars for <250 steps, green for 250+
/// - Current hour highlighted with border
/// - Tap bar to see exact count
/// - Summary below: "X Active Hours | Y Sedentary Hours"
class HourlyActivityChart extends StatefulWidget {
  /// Steps for each hour (0-23). Map keys are hour indices.
  final Map<int, int> hourlySteps;

  /// Threshold for active vs sedentary (default 250 steps)
  final int activeThreshold;

  /// Maximum steps to use for scaling (defaults to max in data or 500)
  final int? maxStepsForScale;

  /// The current hour (0-23), will be highlighted
  final int? currentHour;

  /// Whether to use dark theme
  final bool isDark;

  /// Callback when an hour bar is tapped
  final void Function(int hour, int steps)? onHourTap;

  const HourlyActivityChart({
    super.key,
    required this.hourlySteps,
    this.activeThreshold = 250,
    this.maxStepsForScale,
    this.currentHour,
    this.isDark = true,
    this.onHourTap,
  });

  @override
  State<HourlyActivityChart> createState() => _HourlyActivityChartState();
}

class _HourlyActivityChartState extends State<HourlyActivityChart>
    with SingleTickerProviderStateMixin {
  int? _selectedHour;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  int get _maxSteps {
    if (widget.maxStepsForScale != null) {
      return widget.maxStepsForScale!;
    }
    final maxInData = widget.hourlySteps.values.fold<int>(0, (a, b) => a > b ? a : b);
    return maxInData > 0 ? maxInData : 500;
  }

  int get _activeHours {
    return widget.hourlySteps.values
        .where((steps) => steps >= widget.activeThreshold)
        .length;
  }

  int get _sedentaryHours {
    final currentHour = widget.currentHour ?? DateTime.now().hour;
    // Count hours from 0 to current hour that have < threshold steps
    int count = 0;
    for (int hour = 0; hour <= currentHour; hour++) {
      final steps = widget.hourlySteps[hour] ?? 0;
      if (steps < widget.activeThreshold) {
        count++;
      }
    }
    return count;
  }

  void _onBarTap(int hour) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedHour = _selectedHour == hour ? null : hour;
    });
    final steps = widget.hourlySteps[hour] ?? 0;
    widget.onHourTap?.call(hour, steps);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final error = isDark ? AppColors.error : AppColorsLight.error;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final currentHour = widget.currentHour ?? DateTime.now().hour;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bar_chart_rounded,
                    size: 20,
                    color: cyan,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Hourly Activity',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              // Legend
              Row(
                children: [
                  _LegendDot(color: success, label: 'Active'),
                  const SizedBox(width: 12),
                  _LegendDot(color: error, label: 'Sedentary'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Selected hour info
          if (_selectedHour != null) ...[
            _SelectedHourInfo(
              hour: _selectedHour!,
              steps: widget.hourlySteps[_selectedHour!] ?? 0,
              isActive: (widget.hourlySteps[_selectedHour!] ?? 0) >= widget.activeThreshold,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
          ],

          // Chart
          SizedBox(
            height: 140,
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(24, (hour) {
                      final steps = widget.hourlySteps[hour] ?? 0;
                      final isActive = steps >= widget.activeThreshold;
                      final isCurrent = hour == currentHour;
                      final isSelected = hour == _selectedHour;
                      final isFutureHour = hour > currentHour;

                      // Calculate bar height (minimum 8, max 100)
                      final rawHeight = _maxSteps > 0
                          ? (steps / _maxSteps * 100).clamp(8.0, 100.0)
                          : 8.0;
                      final height = rawHeight * _animation.value;

                      return Semantics(
                        label: _formatHourAccessibility(hour, steps, isActive),
                        button: true,
                        selected: isSelected,
                        child: GestureDetector(
                          onTap: () => _onBarTap(hour),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                // Bar
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: 24,
                                  height: height,
                                  decoration: BoxDecoration(
                                    color: isFutureHour
                                        ? glassSurface
                                        : isActive
                                            ? success
                                            : error.withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: isCurrent || isSelected
                                        ? Border.all(
                                            color: isCurrent ? cyan : textPrimary,
                                            width: 2,
                                          )
                                        : null,
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: (isActive ? success : error)
                                                  .withOpacity(0.4),
                                              blurRadius: 8,
                                              spreadRadius: 1,
                                            )
                                          ]
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Hour label
                                Text(
                                  _formatHourLabel(hour),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                                    color: isCurrent ? cyan : textMuted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Summary
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Semantics(
                  label: '$_activeHours active hours',
                  child: _SummaryItem(
                    icon: Icons.directions_walk,
                    iconColor: success,
                    value: '$_activeHours',
                    label: 'Active Hours',
                    isDark: isDark,
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: textMuted.withOpacity(0.3),
                ),
                Semantics(
                  label: '$_sedentaryHours sedentary hours',
                  child: _SummaryItem(
                    icon: Icons.weekend_outlined,
                    iconColor: error,
                    value: '$_sedentaryHours',
                    label: 'Sedentary Hours',
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatHourLabel(int hour) {
    if (hour == 0) return '12a';
    if (hour == 12) return '12p';
    if (hour < 12) return '${hour}a';
    return '${hour - 12}p';
  }

  String _formatHourAccessibility(int hour, int steps, bool isActive) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final status = isActive ? 'active' : 'sedentary';
    return '$displayHour $period: $steps steps, $status';
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

class _SelectedHourInfo extends StatelessWidget {
  final int hour;
  final int steps;
  final bool isActive;
  final bool isDark;

  const _SelectedHourInfo({
    required this.hour,
    required this.steps,
    required this.isActive,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final success = isDark ? AppColors.success : AppColorsLight.success;
    final error = isDark ? AppColors.error : AppColorsLight.error;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final color = isActive ? success : error;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.directions_walk : Icons.weekend_outlined,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Text(
            _formatHour(hour),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textPrimary,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$steps steps',
            style: TextStyle(
              fontSize: 14,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isActive ? 'ACTIVE' : 'SEDENTARY',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatHour(int hour) {
    final period = hour < 12 ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:00 $period';
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool isDark;

  const _SummaryItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
          color: iconColor,
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
