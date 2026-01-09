import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/services/haptic_service.dart';

/// Weight Trend Tile - Shows weekly weight change with trend arrow
/// Green arrow down = losing weight (good for fat loss)
/// Red arrow up = gaining weight
class WeightTrendCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const WeightTrendCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final nutritionState = ref.watch(nutritionPreferencesProvider);
    final weightTrend = nutritionState.weightTrend;
    final weightHistory = nutritionState.weightHistory;
    final isLoading = nutritionState.isLoading;

    // Get latest weight
    final latestWeight = weightHistory.isNotEmpty ? weightHistory.first : null;
    final changeKg = weightTrend?.changeKg ?? 0.0;
    final direction = weightTrend?.direction ?? 'maintaining';
    final isLosing = direction == 'losing';
    final isGaining = direction == 'gaining';

    // Colors based on direction (for fat loss: losing is good)
    final trendColor = isLosing
        ? AppColors.success
        : isGaining
            ? AppColors.error
            : AppColors.orange;

    // Format change for display
    final changeLbs = (changeKg.abs() * 2.20462);
    final changeText = changeLbs >= 0.1
        ? '${changeLbs.toStringAsFixed(1)} lbs'
        : 'No change';

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        trendColor: trendColor,
        cardBorder: cardBorder,
        isLosing: isLosing,
        isGaining: isGaining,
        changeText: changeText,
        isLoading: isLoading,
        hasData: weightHistory.isNotEmpty,
      );
    }

    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/progress');
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.orange, width: 4),
            top: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            right: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            bottom: BorderSide(color: trendColor.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.15),
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
        child: isLoading
            ? _buildLoadingState(textMuted)
            : weightHistory.isEmpty
                ? _buildEmptyState(textMuted, trendColor)
                : _buildContentState(
                    textColor: textColor,
                    textMuted: textMuted,
                    trendColor: trendColor,
                    latestWeight: latestWeight,
                    isLosing: isLosing,
                    isGaining: isGaining,
                    changeText: changeText,
                    direction: direction,
                    changeLbs: changeLbs,
                  ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color trendColor,
    required Color cardBorder,
    required bool isLosing,
    required bool isGaining,
    required String changeText,
    required bool isLoading,
    required bool hasData,
  }) {
    return InkWell(
      onTap: () {
        HapticService.light();
        context.push('/progress');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: AppColors.orange, width: 4),
            top: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            right: BorderSide(color: trendColor.withValues(alpha: 0.3)),
            bottom: BorderSide(color: trendColor.withValues(alpha: 0.3)),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.orange.withOpacity(0.15),
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
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isLosing
                  ? Icons.trending_down
                  : isGaining
                      ? Icons.trending_up
                      : Icons.trending_flat,
              color: trendColor,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              isLoading
                  ? '...'
                  : hasData
                      ? changeText
                      : 'No data',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: trendColor,
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
          'Loading weight...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted, Color trendColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.scale, color: trendColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Weight Trend',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Log your weight to see trends',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: trendColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Tap to log weight',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: trendColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContentState({
    required Color textColor,
    required Color textMuted,
    required Color trendColor,
    required dynamic latestWeight,
    required bool isLosing,
    required bool isGaining,
    required String changeText,
    required String direction,
    required double changeLbs,
  }) {
    // Format the message based on direction
    String getMessage() {
      if (isLosing) {
        return 'Down $changeText this week!';
      } else if (isGaining) {
        return 'Up $changeText this week';
      } else {
        return 'Weight stable this week';
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              isLosing
                  ? Icons.trending_down
                  : isGaining
                      ? Icons.trending_up
                      : Icons.trending_flat,
              color: trendColor,
              size: 24,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Large change number with animation
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: changeLbs),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutCubic,
                    builder: (context, animatedValue, _) {
                      final displayText = animatedValue >= 0.1
                          ? '${animatedValue.toStringAsFixed(1)} lbs'
                          : 'No change';
                      return Text(
                        displayText,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                          height: 1.0,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 2),
                  // Small label
                  Text(
                    getMessage().replaceAll(changeText, '').trim(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
        if (size == TileSize.full) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              if (latestWeight != null) ...[
                Flexible(
                  child: Text(
                    'Current: ${latestWeight.weightLbs.toStringAsFixed(1)} lbs',
                    style: TextStyle(
                      fontSize: 14,
                      color: textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trendColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  direction == 'losing'
                      ? 'On track'
                      : direction == 'gaining'
                          ? 'Review goals'
                          : 'Maintaining',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: trendColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
