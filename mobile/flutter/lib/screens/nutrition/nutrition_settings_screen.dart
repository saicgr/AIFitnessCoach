import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/glass_sheet.dart';
import 'food_library_screen.dart';
import 'weekly_checkin_sheet.dart';

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
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Nutrition Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: prefsState.isLoading || preferences == null
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Mental Health & Wellbeing Section
                  _buildSectionHeader(
                    context,
                    'Mental Health & Wellbeing',
                    Icons.favorite_rounded,
                    textPrimary,
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
                        iconColor: textPrimary,
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
                        iconColor: textPrimary,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Streak & Goals Section
                  _buildSectionHeader(
                    context,
                    'Streaks & Weekly Goals',
                    Icons.local_fire_department,
                    textPrimary,
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

                  // AI Assistance Section
                  _buildSectionHeader(
                    context,
                    'AI Assistance',
                    Icons.auto_awesome,
                    textPrimary,
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
                        iconColor: textPrimary,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Logging Section
                  _buildSectionHeader(
                    context,
                    'Logging',
                    Icons.edit_note_rounded,
                    textPrimary,
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
                        iconColor: textPrimary,
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
                        iconColor: textPrimary,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Food Library Section
                  _buildSectionHeader(
                    context,
                    'Food Library',
                    Icons.menu_book_rounded,
                    textPrimary,
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
                    iconColor: textPrimary,
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

                  const SizedBox(height: 24),

                  // Display Section
                  _buildSectionHeader(
                    context,
                    'Display',
                    Icons.view_compact_rounded,
                    textPrimary,
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
                        iconColor: textPrimary,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Dynamic Targets Section
                  _buildSectionHeader(
                    context,
                    'Dynamic Calorie Adjustments',
                    Icons.trending_up_rounded,
                    textPrimary,
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
                        iconColor: textPrimary,
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
                        iconColor: textPrimary,
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
                        iconColor: textPrimary,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Calorie Estimate Bias Section
                  _buildSectionHeader(
                    context,
                    'Calorie Estimate Bias',
                    Icons.tune_rounded,
                    textPrimary,
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

                  // Nutrition Goals Section
                  _buildSectionHeader(
                    context,
                    'Nutrition Goals',
                    Icons.track_changes_rounded,
                    textPrimary,
                    textPrimary,
                  ),
                  const SizedBox(height: 12),
                  _buildNutritionGoalsCard(
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

                  // Weekly Check-In Section
                  _buildSectionHeader(
                    context,
                    'Weekly Check-In',
                    Icons.event_note_rounded,
                    textPrimary,
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

                  // Current Targets Info Card
                  if (userId != null)
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

                  const SizedBox(height: 24),

                  // Recalculate Button
                  if (userId != null)
                    _buildRecalculateButton(
                      context,
                      userId,
                      isDark,
                      textPrimary,
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildStreakSettingsCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    String? userId,
    NutritionStreak? streak,
  ) {
    final accentLight = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Current Streak Info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${streak?.currentStreakDays ?? 0}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current Streak',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Best: ${streak?.longestStreakEver ?? 0} days • Total: ${streak?.totalDaysLogged ?? 0} days logged',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(isDark),
          // Streak Freezes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accentLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.ac_unit, color: accentLight, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Streak Freezes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${streak?.freezesAvailable ?? 2} available this week',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                // Use Freeze Button
                if ((streak?.freezesAvailable ?? 0) > 0 && userId != null)
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => _useStreakFreeze(userId),
                    style: TextButton.styleFrom(
                      backgroundColor: accentLight.withValues(alpha: 0.15),
                      foregroundColor: accentLight,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.ac_unit, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Use Freeze',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          _buildDivider(isDark),
          // Weekly Goal Info (non-editable for now)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_view_week_rounded,
                    color: textPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Weekly Goal',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        streak?.weeklyGoalEnabled == true
                            ? 'Log meals ${streak?.weeklyGoalDays ?? 5} out of 7 days'
                            : 'Track daily streak (consecutive days)',
                        style: TextStyle(fontSize: 12, color: textMuted),
                      ),
                    ],
                  ),
                ),
                // Weekly Goal Status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: (streak?.weeklyGoalEnabled == true &&
                            (streak?.daysLoggedThisWeek ?? 0) >=
                                (streak?.weeklyGoalDays ?? 5))
                        ? textPrimary.withValues(alpha: 0.15)
                        : textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    streak?.weeklyGoalEnabled == true
                        ? '${streak?.daysLoggedThisWeek ?? 0}/${streak?.weeklyGoalDays ?? 5}'
                        : 'Daily',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: (streak?.weeklyGoalEnabled == true &&
                              (streak?.daysLoggedThisWeek ?? 0) >=
                                  (streak?.weeklyGoalDays ?? 5))
                          ? textPrimary
                          : textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon,
    Color iconColor,
    Color textPrimary,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder, {
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color iconColor,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          subtitle,
          style: TextStyle(
            color: textMuted,
            fontSize: 13,
          ),
        ),
      ),
      trailing: Switch.adaptive(
        value: value,
        onChanged: _isLoading
            ? null
            : (newValue) {
                HapticService.light();
                onChanged(newValue);
              },
        activeTrackColor: textPrimary.withValues(alpha: 0.5),
        activeThumbColor: textPrimary,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 56,
      color: isDark ? AppColors.cardBorder : AppColorsLight.cardBorder,
    );
  }

  Widget _buildNavigationCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textMuted,
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
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    NutritionPreferences preferences,
    NutritionPreferencesState prefsState,
    String userId,
  ) {
    final dynamicTargets = prefsState.dynamicTargets;
    final isTrainingDay = prefsState.isTrainingDay;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: textPrimary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Current Targets',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (isTrainingDay) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: textMuted.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Training Day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Edit button
              GestureDetector(
                onTap: () => _showEditTargetsSheet(
                  context,
                  isDark,
                  textPrimary,
                  textMuted,
                  elevated,
                  preferences,
                  userId,
                ),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: textPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTargetRow(
            'Calories',
            '${prefsState.currentCalorieTarget} kcal',
            preferences.targetCalories != prefsState.currentCalorieTarget
                ? '(base: ${preferences.targetCalories})'
                : null,
            textPrimary,
            textMuted,
          ),
          const SizedBox(height: 8),
          _buildTargetRow(
            'Protein',
            '${prefsState.currentProteinTarget}g',
            null,
            textPrimary,
            textMuted,
          ),
          const SizedBox(height: 8),
          _buildTargetRow(
            'Carbs',
            '${prefsState.currentCarbsTarget}g',
            null,
            textPrimary,
            textMuted,
          ),
          const SizedBox(height: 8),
          _buildTargetRow(
            'Fat',
            '${prefsState.currentFatTarget}g',
            null,
            textPrimary,
            textMuted,
          ),
          if (dynamicTargets?.adjustmentReason != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: textPrimary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dynamicTargets!.adjustmentReason,
                      style: TextStyle(
                        fontSize: 13,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetRow(
    String label,
    String value,
    String? note,
    Color textPrimary,
    Color textMuted,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            if (note != null) ...[
              const SizedBox(width: 4),
              Text(
                note,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildRecalculateButton(
    BuildContext context,
    String userId,
    bool isDark,
    Color textPrimary,
  ) {
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _isLoading
              ? null
              : () async {
                  HapticService.medium();
                  setState(() => _isLoading = true);
                  try {
                    await ref
                        .read(nutritionPreferencesProvider.notifier)
                        .recalculateTargets(userId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Targets recalculated!'),
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
                },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textPrimary,
                    ),
                  )
                else
                  Icon(
                    Icons.refresh_rounded,
                    color: textPrimary,
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Recalculating...' : 'Recalculate Targets',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;

    final caloriesController = TextEditingController(
      text: (preferences.targetCalories ?? 2000).toString(),
    );
    final proteinController = TextEditingController(
      text: (preferences.targetProteinG ?? 150).toString(),
    );
    final carbsController = TextEditingController(
      text: (preferences.targetCarbsG ?? 200).toString(),
    );
    final fatController = TextEditingController(
      text: (preferences.targetFatG ?? 65).toString(),
    );

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 8,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Daily Targets',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Manually set your daily nutrition goals',
                style: TextStyle(
                  fontSize: 14,
                  color: textMuted,
                ),
              ),
              const SizedBox(height: 24),
              _buildTargetTextField(
                controller: caloriesController,
                label: 'Calories',
                suffix: 'kcal',
                elevated: elevated,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              _buildTargetTextField(
                controller: proteinController,
                label: 'Protein',
                suffix: 'g',
                elevated: elevated,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              _buildTargetTextField(
                controller: carbsController,
                label: 'Carbs',
                suffix: 'g',
                elevated: elevated,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 12),
              _buildTargetTextField(
                controller: fatController,
                label: 'Fat',
                suffix: 'g',
                elevated: elevated,
                textMuted: textMuted,
                textPrimary: textPrimary,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    HapticService.light();
                    Navigator.pop(context);

                    final calories = int.tryParse(caloriesController.text);
                    final protein = int.tryParse(proteinController.text);
                    final carbs = int.tryParse(carbsController.text);
                    final fat = int.tryParse(fatController.text);

                    if (calories != null || protein != null || carbs != null || fat != null) {
                      await ref.read(nutritionPreferencesProvider.notifier).updateTargets(
                        userId: userId,
                        targetCalories: calories,
                        targetProteinG: protein,
                        targetCarbsG: carbs,
                        targetFatG: fat,
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Targets updated'),
                            backgroundColor: teal,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: teal,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Save Targets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTargetTextField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required Color elevated,
    required Color textMuted,
    required Color textPrimary,
  }) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(color: textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textMuted),
        suffixText: suffix,
        suffixStyle: TextStyle(color: textMuted),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
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
                    color: textPrimary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.tune_rounded, color: textPrimary, size: 24),
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

  void _showCalorieBiasSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String? userId,
  ) {
    if (userId == null) return;

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final teal = isDark ? AppColors.teal : AppColorsLight.teal;
    int currentBias = preferences.calorieEstimateBias;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) {
            final label = _biasLabel(currentBias);
            final multiplier = _biasMultipliers[currentBias] ?? 1.0;
            final exampleCal = (600 * multiplier).round();

            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 8,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Calorie Estimate Bias',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: Icon(Icons.close, color: textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'If AI calorie estimates feel too high or too low for your meals, '
                    'adjust the bias so future estimates better match reality.',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  ),
                  const SizedBox(height: 20),

                  // Current selection card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: currentBias == 0
                                ? textMuted
                                : (currentBias > 0 ? teal : Colors.orange),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${multiplier.toStringAsFixed(2)}x',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Slider
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: teal,
                      inactiveTrackColor: textMuted.withValues(alpha: 0.2),
                      thumbColor: teal,
                      overlayColor: teal.withValues(alpha: 0.15),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: currentBias.toDouble(),
                      min: -2,
                      max: 2,
                      divisions: 4,
                      onChanged: (value) {
                        setSheetState(() {
                          currentBias = value.round();
                        });
                      },
                    ),
                  ),
                  // Slider labels
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Under More',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                        Text('No Bias',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                        Text('Over More',
                            style: TextStyle(fontSize: 11, color: textMuted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Example section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textPrimary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.lightbulb_outline,
                            size: 18, color: textMuted),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Example: A 600 cal meal would be logged as $exampleCal cal',
                            style: TextStyle(fontSize: 13, color: textMuted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        HapticService.light();
                        Navigator.pop(context);
                        _updatePreference(
                          userId,
                          preferences,
                          calorieEstimateBias: currentBias,
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Save',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build the nutrition goals card showing current goals with edit option
  Widget _buildNutritionGoalsCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    NutritionPreferences preferences,
    String? userId,
  ) {
    final green = textPrimary;
    final goals = preferences.nutritionGoals;
    final primaryGoal = preferences.nutritionGoal;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Your Goals',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showEditGoalsSheet(
                        context,
                        isDark,
                        textPrimary,
                        textMuted,
                        elevated,
                        preferences,
                        userId,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, size: 16, color: green),
                            const SizedBox(width: 4),
                            Text(
                              'Edit',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Display goals
                if (goals.isEmpty)
                  Text(
                    'No goals set',
                    style: TextStyle(fontSize: 14, color: textMuted),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: goals.map((goal) {
                      final isPrimary = goal == primaryGoal;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isPrimary
                              ? green.withValues(alpha: 0.15)
                              : textMuted.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: isPrimary
                              ? Border.all(color: green.withValues(alpha: 0.3))
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getGoalDisplayName(goal),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                                color: isPrimary ? green : textPrimary,
                              ),
                            ),
                            if (isPrimary) ...[
                              const SizedBox(width: 4),
                              Icon(Icons.star, size: 14, color: green),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
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

  /// Show bottom sheet to edit nutrition goals
  void _showEditGoalsSheet(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
    Color elevated,
    NutritionPreferences preferences,
    String? userId,
  ) {
    if (userId == null) return;

    final nearBlack = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final green = textPrimary;

    // Available goals
    final allGoals = [
      {'id': 'lose_fat', 'name': 'Lose Fat', 'icon': Icons.local_fire_department},
      {'id': 'build_muscle', 'name': 'Build Muscle', 'icon': Icons.fitness_center},
      {'id': 'maintain', 'name': 'Maintain Weight', 'icon': Icons.balance},
      {'id': 'improve_energy', 'name': 'Improve Energy', 'icon': Icons.bolt},
      {'id': 'eat_healthier', 'name': 'Eat Healthier', 'icon': Icons.eco},
      {'id': 'recomposition', 'name': 'Body Recomposition', 'icon': Icons.swap_vert},
    ];

    // Rate of change options
    final rateOptions = ['slow', 'moderate', 'fast', 'aggressive'];

    // Local state for selections
    List<String> selectedGoals = List.from(preferences.nutritionGoals);
    String selectedRate = preferences.rateOfChange ?? 'moderate';
    bool isSaving = false;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit Nutrition Goals',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your goals (first selected = primary)',
                  style: TextStyle(fontSize: 14, color: textMuted),
                ),
                const SizedBox(height: 16),
                // Goals multi-select
                ...allGoals.map((goal) {
                  final isSelected = selectedGoals.contains(goal['id']);
                  final isPrimary = selectedGoals.isNotEmpty && selectedGoals.first == goal['id'];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () {
                        setSheetState(() {
                          if (isSelected) {
                            selectedGoals.remove(goal['id']);
                          } else {
                            selectedGoals.add(goal['id'] as String);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? green.withValues(alpha: 0.15)
                              : elevated,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? green.withValues(alpha: 0.5)
                                : Colors.transparent,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              goal['icon'] as IconData,
                              color: isSelected ? green : textMuted,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                goal['name'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? green : textPrimary,
                                ),
                              ),
                            ),
                            if (isPrimary)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Primary',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: green,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Icon(
                              isSelected
                                  ? Icons.check_circle
                                  : Icons.circle_outlined,
                              color: isSelected ? green : textMuted,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                // Rate of change
                Text(
                  'Rate of Change',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: rateOptions.map((rate) {
                    final isSelected = selectedRate == rate;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(right: rate != 'aggressive' ? 8 : 0),
                        child: GestureDetector(
                          onTap: () => setSheetState(() => selectedRate = rate),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? green.withValues(alpha: 0.15)
                                  : elevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? green.withValues(alpha: 0.5)
                                    : Colors.transparent,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                rate[0].toUpperCase() + rate.substring(1),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? green : textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: isSaving || selectedGoals.isEmpty
                        ? null
                        : () async {
                            setSheetState(() => isSaving = true);
                            HapticService.light();

                            try {
                              // Call recalculate endpoint with new goals
                              final authState = ref.read(authStateProvider);
                              final user = authState.user;
                              final apiClient = ref.read(apiClientProvider);

                              await apiClient.post(
                                '${ApiConstants.users}/$userId/calculate-nutrition-targets',
                                data: {
                                  'weight_kg': user?.weightKg ?? 70,
                                  'height_cm': user?.heightCm ?? 170,
                                  'age': user?.age ?? 30,
                                  'gender': user?.gender ?? 'male',
                                  'activity_level': user?.activityLevel ?? 'moderately_active',
                                  'weight_direction': selectedGoals.contains('lose_fat') ? 'lose' : (selectedGoals.contains('build_muscle') ? 'gain' : 'maintain'),
                                  'weight_change_rate': selectedRate,
                                  'goal_weight_kg': user?.targetWeightKg,
                                  'nutrition_goals': selectedGoals,
                                  'workout_days_per_week': user?.workoutsPerWeek ?? 3,
                                },
                              );

                              // Refresh preferences
                              await ref.read(nutritionPreferencesProvider.notifier).initialize(userId);

                              Navigator.pop(context);

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Goals updated and targets recalculated!'),
                                    backgroundColor: green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              debugPrint('❌ Error updating goals: $e');
                              setSheetState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: textMuted,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save & Recalculate',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build the weekly check-in card with manual trigger button
  Widget _buildWeeklyCheckinCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    NutritionPreferences preferences,
  ) {
    final blue = textPrimary;
    final isDue = preferences.isWeeklyCheckinDue;
    final lastCheckin = preferences.lastWeeklyCheckinAt;
    final daysSince = preferences.daysSinceLastCheckin;

    String statusText;
    if (lastCheckin == null) {
      statusText = 'Never completed';
    } else if (isDue) {
      statusText = 'Due now ($daysSince days since last)';
    } else {
      statusText = '$daysSince days since last check-in';
    }

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDue
                        ? blue.withValues(alpha: 0.15)
                        : textMuted.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: isDue ? blue : textMuted,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review & Adjust Targets',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 13,
                          color: isDue ? blue : textMuted,
                          fontWeight: isDue ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isDue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: blue.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Due',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: blue,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticService.medium();
                  showWeeklyCheckinSheet(context, ref);
                },
                icon: Icon(Icons.play_arrow_rounded, color: blue),
                label: Text(
                  'Run Weekly Check-In',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: blue,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: blue.withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
