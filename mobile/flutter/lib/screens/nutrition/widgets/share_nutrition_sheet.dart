import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_colors.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/providers/nutrition_preferences_provider.dart';
import '../../../data/services/share_service.dart';
import '../../../utils/image_capture_utils.dart';
import 'share_templates/daily_summary_template.dart';
import 'share_templates/macros_breakdown_template.dart';
import 'share_templates/meals_log_template.dart';
import 'share_templates/health_score_template.dart';

/// Share Nutrition Bottom Sheet
///
/// Shows a carousel of 4 shareable nutrition templates:
/// 1. Daily Summary - Calorie ring + macro progress bars
/// 2. Macros Breakdown - Donut chart + per-macro calories
/// 3. Meals Log - What was eaten across all meals
/// 4. Health Score - Average AI health score + best meal
class ShareNutritionSheet extends ConsumerStatefulWidget {
  final DailyNutritionSummary? summary;
  final NutritionTargets? targets;

  const ShareNutritionSheet({
    super.key,
    this.summary,
    this.targets,
  });

  /// Show the share nutrition bottom sheet
  static Future<void> show(BuildContext context, WidgetRef ref, {
    DailyNutritionSummary? summary,
    NutritionTargets? targets,
  }) async {
    await showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => ShareNutritionSheet(
        summary: summary,
        targets: targets,
      ),
    );
  }

  @override
  ConsumerState<ShareNutritionSheet> createState() => _ShareNutritionSheetState();
}

class _ShareNutritionSheetState extends ConsumerState<ShareNutritionSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSharing = false;
  bool _isSaving = false;
  bool _showWatermark = true;

  final List<GlobalKey> _captureKeys = List.generate(4, (_) => GlobalKey());

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _templateNames => ['Summary', 'Macros', 'Meals', 'Score'];

  String get _dateLabel {
    final date = widget.summary?.date;
    if (date == null) return DateFormat('MMMM d, yyyy').format(DateTime.now());
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return DateFormat('MMMM d, yyyy').format(parsed);
  }

  Future<Uint8List?> _captureCurrentTemplate() async {
    return await ImageCaptureUtils.captureWidgetWithSize(
      _captureKeys[_currentPage],
      width: ImageCaptureUtils.instagramStoriesSize.width,
      height: ImageCaptureUtils.instagramStoriesSize.height,
      pixelRatio: 1.0,
    );
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final result = await ShareService.shareToInstagramStories(bytes);

      if (result.success) {
        // Also save to gallery
        await ShareService.saveToGallery(bytes);
        if (mounted) {
          Navigator.pop(context);
          _showSuccess('Opening Instagram...');
        }
      } else if (result.error != null) {
        _showError('Could not open Instagram');
      }
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareGeneric() async {
    if (_isSharing) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSharing = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      await ShareService.shareGeneric(
        bytes,
        caption: 'Check out my nutrition today!',
      );
    } catch (e) {
      _showError('Failed to share');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSaving = true);

    try {
      final bytes = await _captureCurrentTemplate();
      if (bytes == null) {
        _showError('Failed to capture image');
        return;
      }

      final saveResult = await ShareService.saveToGallery(bytes);
      if (!saveResult.success) {
        _showError(saveResult.error ?? 'Failed to save image');
        return;
      }

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Saved to device!');
      }
    } catch (e) {
      _showError('Failed to save: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
    );
  }

  List<Color> _getGradientForTemplate(int index) {
    switch (index) {
      case 0: return const [Color(0xFF0A1628), Color(0xFF132238), Color(0xFF0A1628)];
      case 1: return const [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)];
      case 2: return const [Color(0xFF1C1917), Color(0xFF292524), Color(0xFF1C1917)];
      case 3: return const [Color(0xFF0F2027), Color(0xFF0D3320), Color(0xFF0F2027)];
      default: return const [Color(0xFF1A2634), Color(0xFF0F1922), Color(0xFF0A0F14)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = widget.summary;
    final prefsState = ref.watch(nutritionPreferencesProvider);

    return GlassSheet(
      maxHeightFraction: 0.85,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
                const Text(
                  'Share Nutrition',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Watermark toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.branding_watermark_rounded,
                  size: 18,
                  color: _showWatermark
                      ? (isDark ? AppColors.accent : AppColorsLight.accent)
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Show Watermark',
                  style: TextStyle(fontSize: 14, color: _showWatermark ? null : Colors.grey),
                ),
                const SizedBox(width: 8),
                Switch.adaptive(
                  value: _showWatermark,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    setState(() => _showWatermark = value);
                  },
                  activeTrackColor: isDark ? AppColors.accent : AppColorsLight.accent,
                  activeThumbColor: isDark ? AppColors.accentContrast : AppColorsLight.accentContrast,
                ),
              ],
            ),
          ),

          // Template carousel
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                HapticFeedback.selectionClick();
                setState(() => _currentPage = index);
              },
              children: [
                // Daily Summary
                Center(
                  child: CapturableWidget(
                    captureKey: _captureKeys[0],
                    child: InstagramStoryWrapper(
                      backgroundGradient: _getGradientForTemplate(0),
                      child: NutritionDailySummaryTemplate(
                        totalCalories: summary?.totalCalories ?? 0,
                        calorieTarget: prefsState.currentCalorieTarget,
                        proteinG: summary?.totalProteinG ?? 0,
                        carbsG: summary?.totalCarbsG ?? 0,
                        fatG: summary?.totalFatG ?? 0,
                        proteinTarget: prefsState.currentProteinTarget.toDouble(),
                        carbsTarget: prefsState.currentCarbsTarget.toDouble(),
                        fatTarget: prefsState.currentFatTarget.toDouble(),
                        mealCount: summary?.mealCount ?? 0,
                        dateLabel: _dateLabel,
                        showWatermark: _showWatermark,
                      ),
                    ),
                  ),
                ),

                // Macros Breakdown
                Center(
                  child: CapturableWidget(
                    captureKey: _captureKeys[1],
                    child: InstagramStoryWrapper(
                      backgroundGradient: _getGradientForTemplate(1),
                      child: NutritionMacrosBreakdownTemplate(
                        totalCalories: summary?.totalCalories ?? 0,
                        proteinG: summary?.totalProteinG ?? 0,
                        carbsG: summary?.totalCarbsG ?? 0,
                        fatG: summary?.totalFatG ?? 0,
                        fiberG: summary?.totalFiberG,
                        dateLabel: _dateLabel,
                        showWatermark: _showWatermark,
                      ),
                    ),
                  ),
                ),

                // Meals Log
                Center(
                  child: CapturableWidget(
                    captureKey: _captureKeys[2],
                    child: InstagramStoryWrapper(
                      backgroundGradient: _getGradientForTemplate(2),
                      child: NutritionMealsLogTemplate(
                        meals: summary?.meals ?? [],
                        totalCalories: summary?.totalCalories ?? 0,
                        dateLabel: _dateLabel,
                        showWatermark: _showWatermark,
                      ),
                    ),
                  ),
                ),

                // Health Score
                Center(
                  child: CapturableWidget(
                    captureKey: _captureKeys[3],
                    child: InstagramStoryWrapper(
                      backgroundGradient: _getGradientForTemplate(3),
                      child: NutritionHealthScoreTemplate(
                        meals: summary?.meals ?? [],
                        totalCalories: summary?.totalCalories ?? 0,
                        calorieTarget: prefsState.currentCalorieTarget,
                        dateLabel: _dateLabel,
                        showWatermark: _showWatermark,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Page indicators
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_templateNames.length, (index) {
                final isActive = _currentPage == index;
                final accent = isDark ? AppColors.accent : AppColorsLight.accent;
                final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;
                return GestureDetector(
                  onTap: () => _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: EdgeInsets.symmetric(horizontal: isActive ? 12 : 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isActive ? accent : isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _templateNames[index],
                      style: TextStyle(
                        color: isActive ? accentContrast : isDark ? Colors.white70 : Colors.black54,
                        fontSize: 12,
                        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          const SizedBox(height: 16),

          // Action buttons
          Padding(
            padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.of(context).padding.bottom + 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildShareButton(
                      onPressed: _shareToInstagram,
                      icon: Icons.camera_alt_rounded,
                      label: 'Instagram',
                      isPrimary: true,
                      isLoading: _isSharing,
                    )),
                    const SizedBox(width: 12),
                    Expanded(child: _buildShareButton(
                      onPressed: _shareGeneric,
                      icon: Icons.share_rounded,
                      label: 'Share',
                      isPrimary: false,
                      isLoading: _isSharing,
                    )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildShareButton(
                      onPressed: _saveToGallery,
                      icon: Icons.save_alt_rounded,
                      label: 'Save Only',
                      isPrimary: false,
                      isLoading: _isSaving,
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShareButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.accent : AppColorsLight.accent;
    final accentContrast = isDark ? AppColors.accentContrast : AppColorsLight.accentContrast;

    return SizedBox(
      height: 48,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: isPrimary ? accentContrast : accent))
            : Icon(icon, size: 18),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? accent : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
          foregroundColor: isPrimary ? accentContrast : (isDark ? Colors.white : Colors.black87),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
      ),
    );
  }
}
