import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/services/health_service.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/api_client.dart';

/// Daily Stats Tile - Shows steps and calorie deficit
/// Steps from HealthKit/Google Fit
/// Deficit = target - consumed + exercise burned
class DailyStatsCard extends ConsumerStatefulWidget {
  final TileSize size;
  final bool isDark;

  const DailyStatsCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  ConsumerState<DailyStatsCard> createState() => _DailyStatsCardState();
}

class _DailyStatsCardState extends ConsumerState<DailyStatsCard> {
  bool _hasTriggeredLoad = false;

  @override
  void initState() {
    super.initState();
    _loadTargetsIfNeeded();
  }

  Future<void> _loadTargetsIfNeeded() async {
    if (_hasTriggeredLoad) return;
    _hasTriggeredLoad = true;

    final apiClient = ref.read(apiClientProvider);
    final userId = await apiClient.getUserId();
    if (userId != null && mounted) {
      await ref.read(nutritionProvider.notifier).loadTargets(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final size = widget.size;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    // Get activity data (steps)
    final activityState = ref.watch(dailyActivityProvider);
    final steps = activityState.today?.steps ?? 0;
    final caloriesBurned = activityState.today?.caloriesBurned ?? 0;

    // Get nutrition data (for deficit calculation)
    final nutritionState = ref.watch(nutritionProvider);
    final caloriesConsumed = nutritionState.todaySummary?.totalCalories ?? 0;
    final calorieTarget = nutritionState.targets?.dailyCalorieTarget ?? 2000;

    // Calculate deficit: target - consumed + exercise burned
    // Positive = in deficit (good for fat loss), Negative = over calories
    final deficit = calorieTarget - caloriesConsumed + caloriesBurned.round();
    final isInDeficit = deficit > 0;

    // Format values
    final stepsFormatted = _formatNumber(steps);
    final deficitFormatted = deficit.abs().toString();

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        stepsFormatted: stepsFormatted,
        deficitFormatted: deficitFormatted,
        isInDeficit: isInDeficit,
        isLoading: activityState.isLoading,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevatedColor,
              border: Border(
                left: BorderSide(color: AppColors.magenta, width: 4),
                top: BorderSide(color: cardBorder),
                right: BorderSide(color: cardBorder),
                bottom: BorderSide(color: cardBorder),
              ),
            ),
            child: activityState.isLoading
                ? _buildLoadingState(textMuted)
                : _buildContentState(
                    textColor: textColor,
                    textMuted: textMuted,
                    steps: steps,
                    stepsFormatted: stepsFormatted,
                    deficit: deficit,
                    deficitFormatted: deficitFormatted,
                    isInDeficit: isInDeficit,
                    caloriesBurned: caloriesBurned,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required String stepsFormatted,
    required String deficitFormatted,
    required bool isInDeficit,
    required bool isLoading,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/stats');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.magenta, width: 4),
            top: BorderSide(color: cardBorder),
            right: BorderSide(color: cardBorder),
            bottom: BorderSide(color: cardBorder),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withOpacity(0.15),
              blurRadius: 16,
              offset: const Offset(0, 6),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDark ? 0.2 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.directions_walk,
              color: AppColors.cyan,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isLoading ? '...' : stepsFormatted,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              isInDeficit ? Icons.trending_down : Icons.trending_up,
              color: isInDeficit ? AppColors.success : AppColors.error,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              isLoading
                  ? '...'
                  : '${isInDeficit ? "-" : "+"}$deficitFormatted',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isInDeficit ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading stats...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildContentState({
    required Color textColor,
    required Color textMuted,
    required int steps,
    required String stepsFormatted,
    required int deficit,
    required String deficitFormatted,
    required bool isInDeficit,
    required double caloriesBurned,
  }) {
    // Steps goal progress (default 10,000 steps)
    const stepsGoal = 10000;
    final stepsProgress = (steps / stepsGoal).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(Icons.insights, color: AppColors.cyan, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Daily Stats',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Stats row
        Row(
          children: [
            // Steps
            Expanded(
              child: _StatItem(
                icon: Icons.directions_walk,
                iconColor: AppColors.cyan,
                value: stepsFormatted,
                label: 'steps',
                textColor: textColor,
                textMuted: textMuted,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: textMuted.withValues(alpha: 0.2),
            ),
            // Calorie deficit/surplus
            Expanded(
              child: _StatItem(
                icon: isInDeficit ? Icons.trending_down : Icons.trending_up,
                iconColor: isInDeficit ? AppColors.success : AppColors.error,
                value: '${isInDeficit ? "-" : "+"}$deficitFormatted',
                label: isInDeficit ? 'deficit' : 'surplus',
                textColor: isInDeficit ? AppColors.success : AppColors.error,
                textMuted: textMuted,
              ),
            ),
          ],
        ),

        // Full size additional info
        if (widget.size == TileSize.full) ...[
          const SizedBox(height: 16),

          // Steps progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'Steps Goal',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '$steps / $stepsGoal',
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(3),
                  color: textMuted.withValues(alpha: 0.2),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: stepsProgress,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      color: stepsProgress >= 1.0 ? AppColors.success : AppColors.cyan,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Exercise calories burned
          Row(
            children: [
              Icon(Icons.local_fire_department, size: 16, color: AppColors.orange),
              const SizedBox(width: 6),
              Text(
                '${caloriesBurned.round()} cal burned from exercise',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}

/// Individual stat item widget
class _StatItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final Color textColor;
  final Color textMuted;

  const _StatItem({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    // Parse the value to get the numeric part for animation
    final numericValue = _extractNumericValue(value);

    return Column(
      children: [
        // Large metric number with animation - use FittedBox to prevent overflow
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: numericValue),
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, _) {
            final displayValue = _formatAnimatedValue(animatedValue, value);
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                displayValue,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.0,
                ),
                maxLines: 1,
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        // Small label with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
      ],
    );
  }

  double _extractNumericValue(String value) {
    // Extract numeric value from strings like "5.2k", "150", "-300", etc.
    final numStr = value.replaceAll(RegExp(r'[^0-9.\-\+]'), '');
    final parsed = double.tryParse(numStr) ?? 0.0;

    // Handle k notation (e.g., "5.2k" = 5200)
    if (value.contains('k')) {
      return parsed * 1000;
    }
    return parsed;
  }

  String _formatAnimatedValue(double animatedValue, String originalValue) {
    // Preserve original formatting (k notation, +/- signs)
    if (originalValue.contains('k')) {
      return '${(animatedValue / 1000).toStringAsFixed(1)}k';
    }

    // Preserve sign for deficit/surplus
    final hasSign = originalValue.startsWith('+') || originalValue.startsWith('-');
    final sign = animatedValue >= 0 ? (hasSign ? '+' : '') : '-';
    final absValue = animatedValue.abs().round();

    return '$sign$absValue';
  }
}
