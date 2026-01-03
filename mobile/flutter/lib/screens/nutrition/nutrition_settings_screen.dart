import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/nutrition_preferences.dart';
import '../../data/providers/nutrition_preferences_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/haptic_service.dart';
import 'food_library_screen.dart';

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
    final green = const Color(0xFF34C759);

    final prefsState = ref.watch(nutritionPreferencesProvider);
    final preferences = prefsState.preferences;
    final authState = ref.watch(authStateProvider);
    final userId = authState.user?.id;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
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
          ? Center(child: CircularProgressIndicator(color: green))
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
                    const Color(0xFFFF2D55), // Pink
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
                        iconColor: const Color(0xFF5856D6), // Purple
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
                        iconColor: const Color(0xFF007AFF), // Blue
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
                    const Color(0xFFFF9500), // Orange
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
                    const Color(0xFF5856D6), // Purple
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
                        iconColor: const Color(0xFFFF9500), // Orange
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
                    const Color(0xFF34C759), // Green
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
                        iconColor: const Color(0xFFFF9500), // Orange
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
                        iconColor: const Color(0xFF007AFF), // Blue
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
                    const Color(0xFF8B5CF6), // Purple
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
                    iconColor: const Color(0xFF8B5CF6),
                    onTap: () {
                      HapticService.light();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
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
                    const Color(0xFF00C7BE), // Teal
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
                        iconColor: const Color(0xFF5856D6), // Purple
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
                    const Color(0xFF00C7BE), // Teal
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
                        iconColor: const Color(0xFFFF3B30), // Red
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
                        iconColor: const Color(0xFF5856D6), // Purple
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      ),
                    ],
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
    final orange = const Color(0xFFFF9500);
    final teal = const Color(0xFF4ECDC4);

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
                    color: orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${streak?.currentStreakDays ?? 0}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: orange,
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
                    color: teal.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.ac_unit, color: teal, size: 20),
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
                      backgroundColor: teal.withValues(alpha: 0.15),
                      foregroundColor: teal,
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
                    color: const Color(0xFF007AFF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_view_week_rounded,
                    color: const Color(0xFF007AFF),
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
                        ? const Color(0xFF34C759).withValues(alpha: 0.15)
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
                          ? const Color(0xFF34C759)
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
            backgroundColor: const Color(0xFF4ECDC4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFFFF3B30),
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
        activeColor: const Color(0xFF34C759),
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
                color: const Color(0xFF007AFF),
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
                    color: const Color(0xFFFF3B30).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: const Color(0xFFFF3B30),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Training Day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFF3B30),
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
                    color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: const Color(0xFF007AFF),
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
                color: const Color(0xFF007AFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    size: 16,
                    color: const Color(0xFF007AFF),
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
                          backgroundColor: const Color(0xFF34C759),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: const Color(0xFFFF3B30),
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
                      color: const Color(0xFF007AFF),
                    ),
                  )
                else
                  Icon(
                    Icons.refresh_rounded,
                    color: const Color(0xFF007AFF),
                    size: 20,
                  ),
                const SizedBox(width: 8),
                Text(
                  _isLoading ? 'Recalculating...' : 'Recalculate Targets',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF007AFF),
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
            backgroundColor: const Color(0xFFFF3B30),
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: nearBlack,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
}
