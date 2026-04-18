import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/pill_app_bar.dart';
import '../../widgets/glass_sheet.dart';
import 'widgets/edit_targets_sheet.dart';
import 'food_library_screen.dart';
import 'weekly_checkin_sheet.dart';

part 'nutrition_settings_screen_ui_1.dart';
part 'nutrition_settings_screen_ui_2.dart';

part 'nutrition_settings_screen_ui.dart';


/// Nutrition settings screen with toggles for calm mode, AI feedback, etc.
class NutritionSettingsScreen extends ConsumerStatefulWidget {
  const NutritionSettingsScreen({super.key});

  @override
  ConsumerState<NutritionSettingsScreen> createState() =>
      _NutritionSettingsScreenState();
}

class _NutritionSettingsScreenState
    extends ConsumerState<NutritionSettingsScreen> {
  bool _isLoading = false;
  bool _hidePostMealReview = false;

  @override
  void initState() {
    super.initState();
    _loadPostMealReviewPref();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = ref.read(authStateProvider).user?.id;
      if (userId == null) return;
      final prefsState = ref.read(nutritionPreferencesProvider);
      if (prefsState.preferences == null) {
        ref.read(nutritionPreferencesProvider.notifier).initialize(userId);
      }
    });
  }

  Future<void> _loadPostMealReviewPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _hidePostMealReview = prefs.getBool('hide_post_meal_review') ?? false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final accentColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    final prefsState = ref.watch(nutritionPreferencesProvider);
    final preferences = prefsState.preferences;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: const PillAppBar(title: 'Nutrition Settings'),
      body: prefsState.isLoading || preferences == null
          ? _buildSkeleton(isDark, elevated, cardBorder)
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── 1. Current Targets (hero) — macro rings + goal pill.
                  //       Edit pencil, Recalculate ↻, Training Day chip all
                  //       live inside the card header.
                  if (userId != null) ...[
                    _buildInfoCard(
                      context,
                      isDark,
                      elevated,
                      cardBorder,
                      textPrimary,
                      textMuted,
                      preferences,
                      prefsState,
                      userId,
                    ),
                    const SizedBox(height: 28),
                  ],

                  // ── 2. Logging — most-touched preference block, kept
                  //       high up so users can flip quick-log / macro
                  //       visibility without scrolling.
                  _buildSectionHeader(
                    context,
                    'Logging',
                    Icons.edit_note_rounded,
                    AppColors.cyan,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Quick Log Mode',
                        subtitle:
                            'Show quick add button for faster meal logging',
                        value: preferences.quickLogModeEnabled,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, quickLogModeEnabled: value),
                        icon: Icons.bolt_rounded,
                        iconColor: AppColors.yellow,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        context,
                        title: 'Show Macros on Log',
                        subtitle:
                            'Display macro breakdown when confirming a logged meal',
                        value: preferences.showMacrosOnLog,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, showMacrosOnLog: value),
                        icon: Icons.pie_chart_rounded,
                        iconColor: AppColors.macroProtein,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 3. Weekly Check-In.
                  _buildSectionHeader(
                    context,
                    'Weekly Check-In',
                    Icons.event_note_rounded,
                    AppColors.cyan,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildWeeklyCheckinCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    textPrimary,
                    textMuted,
                    preferences,
                  ),

                  const SizedBox(height: 24),

                  // ── 4. Weekly Goal (streak toggle). Status (current
                  //       streak, freezes, Use Freeze) lives on the
                  //       Nutrition home now.
                  _buildSectionHeader(
                    context,
                    'Weekly Goal',
                    Icons.calendar_view_week_rounded,
                    AppColors.purple,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildStreakSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    textPrimary,
                    textMuted,
                    userId,
                    prefsState.streak,
                  ),

                  const SizedBox(height: 24),

                  // ── 5. Dynamic Calorie Adjustments.
                  _buildSectionHeader(
                    context,
                    'Dynamic Calorie Adjustments',
                    Icons.trending_up_rounded,
                    AppColors.green,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Training Day Boost',
                        subtitle:
                            'Increase calories on workout days for better performance',
                        value: preferences.adjustCaloriesForTraining,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, adjustCaloriesForTraining: value),
                        icon: Icons.fitness_center_rounded,
                        iconColor: AppColors.green,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        context,
                        title: 'Rest Day Reduction',
                        subtitle:
                            'Slightly reduce calories on rest days',
                        value: preferences.adjustCaloriesForRest,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, adjustCaloriesForRest: value),
                        icon: Icons.nightlight_round,
                        iconColor: AppColors.purple,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        context,
                        title: 'Weekly Check-in Reminders',
                        subtitle: preferences.weeklyCheckinEnabled
                            ? 'Get reminded to review and adjust your targets weekly'
                            : 'Disabled - targets won\'t auto-adjust',
                        value: preferences.weeklyCheckinEnabled,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, weeklyCheckinEnabled: value),
                        icon: Icons.calendar_today_rounded,
                        iconColor: AppColors.cyan,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 6. Calorie Estimate Bias.
                  _buildSectionHeader(
                    context,
                    'Calorie Estimate Bias',
                    Icons.tune_rounded,
                    AppColors.yellow,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildCalorieBiasCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    textPrimary,
                    textMuted,
                    preferences,
                    userId,
                  ),

                  const SizedBox(height: 24),

                  // ── 7. Display.
                  _buildSectionHeader(
                    context,
                    'Display',
                    Icons.view_compact_rounded,
                    AppColors.purple,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Compact Tracker View',
                        subtitle:
                            'Use a condensed layout with meals at the top',
                        value: preferences.compactTrackerViewEnabled,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, compactTrackerViewEnabled: value),
                        icon: Icons.density_small_rounded,
                        iconColor: AppColors.cyan,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 8. AI Assistance.
                  _buildSectionHeader(
                    context,
                    'AI Assistance',
                    Icons.auto_awesome,
                    AppColors.purple,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Disable AI Food Tips',
                        subtitle:
                            'Hide nutrition suggestions after logging meals',
                        value: !preferences.showAiFeedbackAfterLogging,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, showAiFeedbackAfterLogging: !value),
                        icon: Icons.lightbulb_outline_rounded,
                        iconColor: AppColors.purple,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 9. Mental Health & Wellbeing — softer preferences
                  //       settled toward the bottom since they're
                  //       set-and-forget for most users.
                  _buildSectionHeader(
                    context,
                    'Mental Health & Wellbeing',
                    Icons.favorite_rounded,
                    AppColors.pink,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildSettingsCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    children: [
                      _buildSwitchTile(
                        context,
                        title: 'Calm Mode',
                        subtitle:
                            'Hide calorie numbers and focus on food quality instead',
                        value: preferences.calmModeEnabled,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, calmModeEnabled: value),
                        icon: Icons.spa_rounded,
                        iconColor: AppColors.green,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        context,
                        title: 'Weekly View',
                        subtitle:
                            'Show weekly averages instead of daily targets',
                        value: preferences.showWeeklyInsteadOfDaily,
                        onChanged: (value) =>
                            _updatePreference(userId, preferences, showWeeklyInsteadOfDaily: value),
                        icon: Icons.calendar_view_week_rounded,
                        iconColor: AppColors.cyan,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                      _buildDivider(isDark),
                      _buildSwitchTile(
                        context,
                        title: 'Post-Meal Check-in',
                        subtitle:
                            'Ask how you feel after logging a meal (mood, energy)',
                        value: !_hidePostMealReview,
                        onChanged: (value) async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('hide_post_meal_review', !value);
                          setState(() => _hidePostMealReview = !value);
                        },
                        icon: Icons.mood_rounded,
                        iconColor: AppColors.yellow,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── 10. Food Library — navigation to Saved Foods & Recipes.
                  _buildSectionHeader(
                    context,
                    'Food Library',
                    Icons.menu_book_rounded,
                    AppColors.orange,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    isDark,
                    elevated,
                    cardBorder,
                    textPrimary,
                    textMuted,
                    title: 'Saved Foods & Recipes',
                    subtitle: 'Manage your food library for quick logging',
                    icon: Icons.bookmark_rounded,
                    iconColor: AppColors.orange,
                    onTap: () {
                      HapticService.light();
                      Navigator.push(
                        context,
                        AppPageRoute(
                          builder: (context) => const FoodLibraryScreen(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Future<void> _useStreakFreeze(String userId) async {
    HapticService.medium();
    setState(() => _isLoading = true);
    try {
      await ref
          .read(nutritionPreferencesProvider.notifier)
          .useStreakFreeze(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.ac_unit, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Streak freeze used! Your streak is protected.'),
              ],
            ),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Trigger a backend target recalculation (BMR × activity × goal using the
  /// user's current profile) and surface the result as a snackbar. Shared by
  /// the ↻ icon button on the Current Targets header.
  Future<void> _recalculateTargets(String userId) async {
    if (_isLoading) return;
    HapticService.medium();
    setState(() => _isLoading = true);
    try {
      await ref
          .read(nutritionPreferencesProvider.notifier)
          .recalculateTargets(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Targets recalculated from your profile.'),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updatePreference(
    String? userId,
    NutritionPreferences preferences, {
    bool? calmModeEnabled,
    bool? showWeeklyInsteadOfDaily,
    bool? showAiFeedbackAfterLogging,
    bool? adjustCaloriesForTraining,
    bool? adjustCaloriesForRest,
    bool? quickLogModeEnabled,
    bool? compactTrackerViewEnabled,
    bool? showMacrosOnLog,
    bool? weeklyCheckinEnabled,
    int? calorieEstimateBias,
  }) async {
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final updatedPrefs = preferences.copyWith(
        calmModeEnabled: calmModeEnabled,
        showWeeklyInsteadOfDaily: showWeeklyInsteadOfDaily,
        showAiFeedbackAfterLogging: showAiFeedbackAfterLogging,
        adjustCaloriesForTraining: adjustCaloriesForTraining,
        adjustCaloriesForRest: adjustCaloriesForRest,
        quickLogModeEnabled: quickLogModeEnabled,
        compactTrackerViewEnabled: compactTrackerViewEnabled,
        showMacrosOnLog: showMacrosOnLog,
        weeklyCheckinEnabled: weeklyCheckinEnabled,
        calorieEstimateBias: calorieEstimateBias,
      );

      await ref.read(nutritionPreferencesProvider.notifier).savePreferences(
            userId: userId,
            preferences: updatedPrefs,
          );

      debugPrint('✅ [NutritionSettings] Preference updated');
    } catch (e) {
      debugPrint('❌ [NutritionSettings] Error updating preference: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppColors.textMuted,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Show bottom sheet to edit calorie and macro targets
  void _showEditTargetsSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String userId,
  ) {
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: EditTargetsSheet(
          userId: userId,
          onSaved: () {}, // Settings screen doesn't need a refresh callback
        ),
      ),
    );
  }

  // ---------- Calorie Estimate Bias ----------

  static const _biasLabels = <int, String>{
    -2: 'Under More',
    -1: 'Under',
    0: 'No Bias',
    1: 'Over',
    2: 'Over More',
  };

  static const _biasMultipliers = <int, double>{
    -2: 0.85,
    -1: 0.93,
    0: 1.0,
    1: 1.07,
    2: 1.15,
  };

  String _biasLabel(int bias) => _biasLabels[bias] ?? 'No Bias';

  Widget _buildCalorieBiasCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    NutritionPreferences preferences,
    String? userId,
  ) {
    final bias = preferences.calorieEstimateBias;
    final label = _biasLabel(bias);

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showCalorieBiasSheet(
            context,
            isDark,
            textPrimary,
            textMuted,
            elevated,
            preferences,
            userId,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.yellow.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: AppColors.yellow, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Calorie Estimate Bias',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Adjust AI calorie estimates to match your experience',
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right, color: textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _mealPatternLabel(String pattern) {
    switch (pattern) {
      case '3_meals': return '3 Meals';
      case '3_meals_snacks': return '3 Meals + Snacks';
      case '2_meals': return '2 Meals';
      case 'omad': return 'OMAD';
      case 'if_16_8': return 'IF 16:8';
      case 'if_18_6': return 'IF 18:6';
      case 'if_20_4': return 'IF 20:4';
      case '5_6_small_meals': return '5-6 Small Meals';
      case 'religious_fasting': return 'Religious Fast';
      case 'custom': return 'Custom';
      default: return pattern;
    }
  }

  String _formatList(List<String> values, List<MapEntry<String, String>> lookup) {
    const max = 2;
    final names = values.map((v) {
      try { return lookup.firstWhere((e) => e.key == v).value; } catch (_) { return v; }
    }).toList();
    final shown = names.take(max).join(', ');
    return names.length > max ? '$shown +${names.length - max} more' : shown;
  }

  String _getGoalDisplayName(String goal) {
    switch (goal) {
      case 'lose_fat':
        return 'Lose Fat';
      case 'build_muscle':
        return 'Build Muscle';
      case 'maintain':
        return 'Maintain';
      case 'improve_energy':
        return 'Improve Energy';
      case 'eat_healthier':
        return 'Eat Healthier';
      case 'recomposition':
        return 'Body Recomposition';
      default:
        return goal;
    }
  }
}
