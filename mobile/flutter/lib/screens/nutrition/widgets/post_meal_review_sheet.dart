import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/models/nutrition.dart';
import '../../../data/providers/food_patterns_provider.dart';
import '../../../data/repositories/nutrition_repository.dart';
import '../../../data/services/api_client.dart';
import '../../../widgets/glass_sheet.dart';

import '../../../l10n/generated/app_localizations.dart';
const _kHidePostMealReviewKey = 'hide_post_meal_review';

/// Shows a compact post-meal review sheet after logging a meal.
/// Checks user preference and skips if they chose "Don't show again".
Future<void> showPostMealReviewSheet(
  BuildContext context, {
  required List<String> foodNames,
  required int totalCalories,
  required bool isDark,
  required String userId,
  String? foodLogId,
  Future<void>? saveFuture,
  String? Function()? getSavedLogId,
}) async {
  final prefs = await SharedPreferences.getInstance();
  if (prefs.getBool(_kHidePostMealReviewKey) == true) return;

  if (!context.mounted) return;
  showGlassSheet<void>(
    context: context,
    // Stickier: explicit Skip / Don't-show-again actions only — no tap-outside
    // or swipe-down dismissals. This keeps the sheet on screen long enough for
    // users to actually fill it in (live data showed 1/78 recent logs had mood
    // filled — mostly because the sheet was getting dismissed too easily).
    isDismissible: false,
    enableDrag: false,
    builder: (context) => GlassSheet(
      showHandle: false,
      child: _PostMealReviewSheet(
        foodNames: foodNames,
        totalCalories: totalCalories,
        isDark: isDark,
        userId: userId,
        foodLogId: foodLogId,
        saveFuture: saveFuture,
        getSavedLogId: getSavedLogId,
      ),
    ),
  );
}

class _PostMealReviewSheet extends ConsumerStatefulWidget {
  final List<String> foodNames;
  final int totalCalories;
  final bool isDark;
  final String userId;
  final String? foodLogId;
  final Future<void>? saveFuture;
  final String? Function()? getSavedLogId;

  const _PostMealReviewSheet({
    required this.foodNames,
    required this.totalCalories,
    required this.isDark,
    required this.userId,
    this.foodLogId,
    this.saveFuture,
    this.getSavedLogId,
  });

  @override
  ConsumerState<_PostMealReviewSheet> createState() => _PostMealReviewSheetState();
}

class _PostMealReviewSheetState extends ConsumerState<_PostMealReviewSheet> {
  FoodMood? _moodBefore;
  FoodMood? _moodAfter;
  int _energyLevel = 3;
  bool _showWhyItMatters = false;
  bool _isSaving = false;
  bool _isDismissing = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accentEnum = AccentColorScope.of(context);
    final accent = accentEnum.getColor(isDark);
    final teal = accent;

    final foodSummary = widget.foodNames.take(3).join(', ');
    final extraCount = widget.foodNames.length > 3 ? ' +${widget.foodNames.length - 3} more' : '';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              // Success header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context).postMealReviewMealLogged,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                        ),
                        Text(
                          AppLocalizations.of(context)!.postMealReviewSheetKcal(foodSummary, extraCount, widget.totalCalories),
                          style: TextStyle(fontSize: 12, color: textMuted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Skip button
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).onboardingSkip, style: TextStyle(fontSize: 13, color: textMuted)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Quick review prompt
              Text(
                AppLocalizations.of(context).postMealReviewQuickCheckInOptional,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(() => _showWhyItMatters = !_showWhyItMatters),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: teal),
                    const SizedBox(width: 4),
                    Text(
                      _showWhyItMatters ? AppLocalizations.of(context).workoutSheetsMixinHide : AppLocalizations.of(context).postMealReviewWhyTrackThis,
                      style: TextStyle(fontSize: 12, color: teal, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Why it matters (collapsible)
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                child: _showWhyItMatters
                    ? Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: teal.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: teal.withValues(alpha: 0.12)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _whyRow(Icons.psychology, 'Mood patterns', 'Discover which foods boost or drain your energy', textPrimary, textMuted),
                            const SizedBox(height: 6),
                            _whyRow(Icons.track_changes, 'Spot triggers', 'Identify foods that cause bloating or fatigue', textPrimary, textMuted),
                            const SizedBox(height: 6),
                            _whyRow(Icons.auto_graph, 'Smarter coaching', 'Your AI coach uses this to personalize recommendations', textPrimary, textMuted),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              const SizedBox(height: 14),

              // Before eating mood
              Text(
                AppLocalizations.of(context).postMealReviewHowDidYouFeel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildMoodChip(FoodMood.hungry, isDark),
                  _buildMoodChip(FoodMood.tired, isDark),
                  _buildMoodChip(FoodMood.stressed, isDark),
                  _buildMoodChip(FoodMood.neutral, isDark),
                  _buildMoodChip(FoodMood.good, isDark),
                  _buildMoodChip(FoodMood.great, isDark),
                ],
              ),
              const SizedBox(height: 14),

              // After eating mood
              Text(
                AppLocalizations.of(context).postMealReviewHowDoYouFeel,
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildMoodChip(FoodMood.satisfied, isDark, isAfter: true),
                  _buildMoodChip(FoodMood.bloated, isDark, isAfter: true),
                  _buildMoodChip(FoodMood.great, isDark, isAfter: true),
                  _buildMoodChip(FoodMood.neutral, isDark, isAfter: true),
                  _buildMoodChip(FoodMood.tired, isDark, isAfter: true),
                ],
              ),
              const SizedBox(height: 14),

              // Energy level
              Row(
                children: [
                  Text(
                    AppLocalizations.of(context).preWorkoutCheckinEnergyLevel,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textMuted, letterSpacing: 0.3),
                  ),
                  const Spacer(),
                  Text(
                    _energyLabel(_energyLevel),
                    style: TextStyle(fontSize: 12, color: accent, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.battery_1_bar, size: 16, color: textMuted),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 4,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                      ),
                      child: Slider(
                        value: _energyLevel.toDouble(),
                        min: 1,
                        max: 5,
                        divisions: 4,
                        activeColor: accent,
                        inactiveColor: accent.withValues(alpha: 0.15),
                        onChanged: (v) => setState(() => _energyLevel = v.round()),
                      ),
                    ),
                  ),
                  Icon(Icons.battery_full, size: 16, color: accent),
                ],
              ),
              const SizedBox(height: 16),

              // Save button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_moodBefore != null || _moodAfter != null) && !_isSaving
                      ? () => _saveMoodReview(teal)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: accent.withValues(alpha: 0.3),
                    disabledForegroundColor: Colors.white54,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(AppLocalizations.of(context).postMealReviewSaveCheckIn, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 10),
              // Don't show again — also persists server-side so the sheet
              // stays hidden across devices until the user re-enables it from
              // Nutrition > Patterns tab.
              Center(
                child: GestureDetector(
                  onTap: () {
                    if (_isDismissing) return;
                    _isDismissing = true;

                    // Capture references BEFORE pop — once the sheet is
                    // disposed, `ref` and `context` are unsafe to use.
                    final repo = ref.read(nutritionRepositoryProvider);
                    final container = ProviderScope.containerOf(
                      context,
                      listen: false,
                    );
                    final messenger = ScaffoldMessenger.of(context);
                    final userId = widget.userId;

                    // Dismiss immediately so the UI feels snappy.
                    Navigator.pop(context);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context).postMealReviewCheckInDisabledRe,
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );

                    // Persist in the background — the sheet is gone, so do
                    // NOT touch `ref` or `context` here.
                    () async {
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setBool(_kHidePostMealReviewKey, true);
                        await repo.updatePatternsSettings(
                          userId,
                          postMealCheckinDisabled: true,
                        );
                        container
                            .invalidate(patternsSettingsProvider(userId));
                        container
                            .invalidate(foodPatternsMoodProvider(userId));
                      } catch (e) {
                        debugPrint('⚠️ [PostMealReview] Backend toggle failed: $e');
                      }
                    }();
                  },
                  child: Text(
                    AppLocalizations.of(context).postMealReviewDonTShowAgain,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted.withValues(alpha: 0.6),
                      decoration: TextDecoration.underline,
                      decorationColor: textMuted.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
  }

  Future<void> _saveMoodReview(Color teal) async {
    // Resolve foodLogId — may still be in-flight if sheet was shown optimistically
    String? logId = widget.foodLogId;
    if (logId == null && widget.saveFuture != null) {
      setState(() => _isSaving = true);
      try {
        await widget.saveFuture;
      } catch (_) {}
      logId = widget.getSavedLogId?.call();
    }
    if (logId == null) {
      debugPrint('⚠️ [PostMealReview] No foodLogId, skipping backend save');
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '/nutrition/food-logs/$logId/mood',
        data: {
          if (_moodBefore != null) 'mood_before': _moodBefore!.value,
          if (_moodAfter != null) 'mood_after': _moodAfter!.value,
          'energy_level': _energyLevel,
        },
      );
      debugPrint('✅ [PostMealReview] Mood saved for log $logId');
    } catch (e) {
      debugPrint('❌ [PostMealReview] Failed to save mood: $e');
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.mood, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(AppLocalizations.of(context).postMealReviewCheckInSaved),
          ],
        ),
        backgroundColor: teal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMoodChip(FoodMood mood, bool isDark, {bool isAfter = false}) {
    final isSelected = isAfter ? _moodAfter == mood : _moodBefore == mood;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isAfter) {
            _moodAfter = _moodAfter == mood ? null : mood;
          } else {
            _moodBefore = _moodBefore == mood ? null : mood;
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? accent.withValues(alpha: 0.12)
              : elevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? accent.withValues(alpha: 0.4) : cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mood.emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? accent : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _whyRow(IconData icon, String title, String desc, Color textPrimary, Color textMuted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: textPrimary.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textPrimary)),
              Text(desc, style: TextStyle(fontSize: 11, color: textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  String _energyLabel(int level) {
    switch (level) {
      case 1: return 'Very low';
      case 2: return 'Low';
      case 3: return 'Normal';
      case 4: return 'Good';
      case 5: return 'High';
      default: return 'Normal';
    }
  }
}
