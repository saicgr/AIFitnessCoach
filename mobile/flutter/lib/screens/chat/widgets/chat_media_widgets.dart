import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/services/haptic_service.dart';
import '../../../screens/nutrition/menu_analysis_sheet.dart';

/// Overlay shown on top of a video thumbnail while it is uploading or being analyzed.
class MediaUploadOverlay extends StatefulWidget {
  final String phase; // 'uploading' | 'analyzing'
  final double? progress; // 0.0-1.0 for uploading; null for analyzing

  const MediaUploadOverlay({super.key, required this.phase, this.progress});

  @override
  State<MediaUploadOverlay> createState() => _MediaUploadOverlayState();
}

class _MediaUploadOverlayState extends State<MediaUploadOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUploading = widget.phase == 'uploading';
    final label = isUploading
        ? 'Uploading ${widget.progress != null ? '${(widget.progress! * 100).toInt()}%' : ''}'
        : 'Analyzing...';
    final icon = isUploading ? Icons.cloud_upload_outlined : Icons.auto_awesome;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: 100,
                child: isUploading
                    ? LinearProgressIndicator(
                        value: widget.progress,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        borderRadius: BorderRadius.circular(4),
                        minHeight: 3,
                      )
                    : AnimatedBuilder(
                        animation: _shimmer,
                        builder: (_, __) => LinearProgressIndicator(
                          value: null,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                          borderRadius: BorderRadius.circular(4),
                          minHeight: 3,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact summary card for food analysis with 6+ items.
class FoodAnalysisSummaryCard extends StatelessWidget {
  final List<Map<String, dynamic>> foodItems;
  final void Function(List<Map<String, dynamic>>)? onViewAll;

  const FoodAnalysisSummaryCard({
    super.key,
    required this.foodItems,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final isDark = colors.isDark;

    int totalCal = 0;
    int totalProtein = 0;
    for (final item in foodItems) {
      totalCal += (item['calories'] as num? ?? 0).toInt();
      totalProtein += (item['protein_g'] as num? ?? item['protein'] as num? ?? 0).toInt();
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.glassSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.cardBorder : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.restaurant_rounded, size: 16, color: AppColors.green),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${foodItems.length} items found',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '$totalCal cal total',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.coral,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${totalProtein}g protein',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.macroProtein,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                _openMenuSheet(context, isDark);
              },
              icon: const Icon(Icons.visibility_outlined, size: 16),
              label: const Text('View All & Log'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMenuSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MenuAnalysisSheet(
        foodItems: foodItems,
        analysisType: 'plate',
        isDark: isDark,
        onLogItems: (selected) => onViewAll?.call(selected),
      ),
    );
  }
}

/// Button to navigate to a generated workout
/// Compact deep-link rendered inside the coach's chat bubble whenever the
/// Nutrition agent persisted a food_log row. Tapping navigates to the
/// Nutrition tab's Daily view so the user can see the logged meal in
/// context (and edit/delete it from there).
class ViewLoggedMealButton extends StatelessWidget {
  final String? mealType;
  final int? calories;

  const ViewLoggedMealButton({
    super.key,
    this.mealType,
    this.calories,
  });

  String _label() {
    final mt = mealType;
    final cal = calories;
    final mealLabel = mt != null && mt.isNotEmpty
        ? '${mt[0].toUpperCase()}${mt.substring(1)}'
        : 'meal';
    if (cal != null && cal > 0) {
      return 'View logged $mealLabel · $cal cal';
    }
    return 'View logged $mealLabel';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: InkWell(
        onTap: () {
          HapticService.selection();
          // tab=0 = Daily tab in MainShell's nutrition route.
          context.go('/nutrition?tab=0');
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.cyan.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.cyan.withValues(alpha: 0.35),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.restaurant_menu_rounded, size: 16, color: AppColors.cyan),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  _label(),
                  style: TextStyle(
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.cyan),
            ],
          ),
        ),
      ),
    );
  }
}

class GoToWorkoutButton extends StatelessWidget {
  final String workoutId;
  final String? workoutName;

  const GoToWorkoutButton({
    super.key,
    required this.workoutId,
    this.workoutName,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticService.selection();
        context.push('/workout/$workoutId');
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.cyan, AppColors.purple],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fitness_center, size: 18, color: Colors.white),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                workoutName != null ? 'Go to $workoutName' : 'Go to Workout',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
