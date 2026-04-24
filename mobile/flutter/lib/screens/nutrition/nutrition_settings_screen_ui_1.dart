part of 'nutrition_settings_screen.dart';

/// UI builder methods extracted from _NutritionSettingsScreenState
extension _NutritionSettingsScreenStateUI1 on _NutritionSettingsScreenState {

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
    // Streak stats + Use Freeze action were moved to the Nutrition home
    // (Daily tab) as a top-of-screen engagement card. This settings card
    // now holds ONLY the Weekly Goal toggle so users can flip between
    // "daily streak" and "X days per week" modes.
    final goalColor = AppColors.purple;

    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          // Weekly Goal row (only content remaining in this card).
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: goalColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.calendar_view_week_rounded,
                    color: goalColor,
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
      trailing: Switch(
        value: value,
        onChanged: _isLoading
            ? null
            : (newValue) {
                HapticService.light();
                onChanged(newValue);
              },
        // Use the section's accent so each toggle visually ties to its row
        // icon (green for Training Day Boost, purple for Rest Day Reduction,
        // cyan for Weekly Check-in, etc.) instead of the flat white/gray
        // default that read as "disabled".
        activeThumbColor: iconColor,
        activeTrackColor: iconColor.withValues(alpha: 0.5),
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
    // Tie the card's chrome to the user's accent so it feels like a true
    // hero card rather than a neutral block — matches the calories ring
    // colour below it.
    final accent = AccentColorScope.of(context).getColor(isDark);
    // Training Day pill uses green (matches the 'Dynamic Cals' section).
    final trainingColor = AppColors.green;

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
                Icons.insights_rounded,
                color: accent,
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
                    color: trainingColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fitness_center,
                        size: 14,
                        color: trainingColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Training Day',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: trainingColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              // Recalculate targets ↻ button. Lives next to Edit because
              // both are "targets chrome" — Edit = manual tweak, Recalc =
              // rebuild from profile (weight/age/activity/goal).
              _TargetsHeaderIconButton(
                icon: _isLoading
                    ? null
                    : Icons.refresh_rounded,
                tint: accent,
                onTap: _isLoading ? null : () => _recalculateTargets(userId),
                showSpinner: _isLoading,
                tooltip: 'Recalculate from profile',
              ),
              const SizedBox(width: 8),
              // Edit button
              _TargetsHeaderIconButton(
                icon: Icons.edit_outlined,
                tint: accent,
                onTap: () => _showEditTargetsSheet(
                  context,
                  isDark,
                  textPrimary,
                  textMuted,
                  elevated,
                  preferences,
                  userId,
                ),
                tooltip: 'Edit targets',
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Four macro rings: Calories (accent) · Protein · Carbs · Fat.
          // Replaces the old vertical text table so the block reads as a
          // glance-able KPI strip instead of a wall of numbers.
          _MacroRingsRow(
            isDark: isDark,
            caloriesTarget: prefsState.currentCalorieTarget,
            proteinTarget: prefsState.currentProteinTarget,
            carbsTarget: prefsState.currentCarbsTarget,
            fatTarget: prefsState.currentFatTarget,
            baseCaloriesNote:
                preferences.targetCalories != prefsState.currentCalorieTarget
                    ? 'base ${preferences.targetCalories}'
                    : null,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 14),
          // Goal pill (merged-in from the old "Nutrition Goals" section).
          // Tap to open the same edit sheet. We always render it so users
          // have a one-tap entry into their goal — no more separate card.
          _GoalPill(
            primaryGoal: preferences.nutritionGoal,
            allGoals: preferences.nutritionGoals,
            onEdit: () => _showEditGoalsSheet(
              context,
              isDark,
              textPrimary,
              textMuted,
              elevated,
              preferences,
              userId,
            ),
            isDark: isDark,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          // Dynamic-adjustment reason — only when the backend actually
          // returned one, and only if it isn't the 'base_targets' sentinel
          // (that's a no-op string meaning "targets unchanged today").
          if (dynamicTargets?.adjustmentReason != null &&
              dynamicTargets!.adjustmentReason!.trim().isNotEmpty &&
              dynamicTargets.adjustmentReason != 'base_targets') ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.yellow.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.yellow.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.auto_awesome_rounded,
                    size: 14,
                    color: AppColors.yellow,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      dynamicTargets.adjustmentReason!,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                        fontWeight: FontWeight.w600,
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


  // _buildTargetRow was replaced by the _MacroRingsRow widget below — the
  // four rows of "label: value" were swapped for four colored macro rings.
  // Left here only as a no-op anchor in case a Git blame reviewer looks for
  // where the old method lived; safe to delete once the redesign lands.

  /// Build the food preferences card (meal pattern, allergens, cooking, budget)
  Widget _buildFoodPreferencesCard(
    BuildContext context,
    bool isDark,
    Color elevated,
    Color cardBorder,
    Color textPrimary,
    Color textMuted,
    NutritionPreferences preferences,
    String? userId,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            child: Row(
              children: [
                Text(
                  'Your Preferences',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textPrimary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showEditFoodPrefsSheet(context, isDark, textPrimary, textMuted, elevated, preferences, userId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: textPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.edit_outlined, size: 16, color: textPrimary),
                        const SizedBox(width: 4),
                        Text('Edit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textPrimary)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildPrefRow(Icons.access_time_outlined, AppColors.cyan, 'Meal Pattern', _mealPatternLabel(preferences.mealPattern), textPrimary, textMuted),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
          _buildPrefRow(Icons.soup_kitchen_outlined, AppColors.info, 'Cooking', '${CookingSkill.fromString(preferences.cookingSkill).displayName} · ${preferences.cookingTimeMinutes} min', textPrimary, textMuted),
          Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
          _buildPrefRow(Icons.account_balance_wallet_outlined, AppColors.green, 'Budget', BudgetLevel.fromString(preferences.budgetLevel).displayName, textPrimary, textMuted),
          if (preferences.allergies.isNotEmpty) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildPrefRow(Icons.warning_amber_outlined, AppColors.orange, 'Allergens', _formatList(preferences.allergies, FoodAllergen.values.map((e) => MapEntry(e.value, e.displayName)).toList()), textPrimary, textMuted),
          ],
          if (preferences.dietaryRestrictions.isNotEmpty) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildPrefRow(Icons.no_meals_outlined, AppColors.purple, 'Restrictions', _formatList(preferences.dietaryRestrictions, DietaryRestriction.values.map((e) => MapEntry(e.value, e.displayName)).toList()), textPrimary, textMuted),
          ],
          if (preferences.dislikedFoods.isNotEmpty) ...[
            Divider(height: 1, color: cardBorder, indent: 48, endIndent: 16),
            _buildPrefRow(Icons.thumb_down_outlined, AppColors.orange, 'Disliked', preferences.dislikedFoods.take(3).join(', ') + (preferences.dislikedFoods.length > 3 ? ' +${preferences.dislikedFoods.length - 3} more' : ''), textPrimary, textMuted),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }


  Widget _buildPrefRow(IconData icon, Color iconColor, String label, String value, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: textMuted)),
          const Spacer(),
          Flexible(
            child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary), textAlign: TextAlign.end),
          ),
        ],
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

}

// ────────────────────────────────────────────────────────────────────────────
// Macro ring visual — four small ring-bordered circles, one per macro.
// Colour palette follows `feedback_accent_colors` (memory):
//   P / C / F use the canonical macro colours (purple / cyan / orange);
//   Calories uses the user's AccentColorScope accent so the ring feels tied
//   to the rest of the app without repeating any P/C/F hue.
// ────────────────────────────────────────────────────────────────────────────

class _MacroRingsRow extends ConsumerWidget {
  final bool isDark;
  final int caloriesTarget;
  final int proteinTarget;
  final int carbsTarget;
  final int fatTarget;
  final String? baseCaloriesNote;
  final Color textPrimary;
  final Color textMuted;

  const _MacroRingsRow({
    required this.isDark,
    required this.caloriesTarget,
    required this.proteinTarget,
    required this.carbsTarget,
    required this.fatTarget,
    required this.textPrimary,
    required this.textMuted,
    this.baseCaloriesNote,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AccentColorScope.of(context).getColor(isDark);
    final protein =
        isDark ? AppColors.macroProtein : AppColorsLight.macroProtein;
    final carbs = isDark ? AppColors.macroCarbs : AppColorsLight.macroCarbs;
    final fat = isDark ? AppColors.macroFat : AppColorsLight.macroFat;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _MacroRing(
            isDark: isDark,
            color: accent,
            value: '$caloriesTarget',
            unit: 'kcal',
            label: 'Calories',
            footnote: baseCaloriesNote,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroRing(
            isDark: isDark,
            color: protein,
            value: '$proteinTarget',
            unit: 'g',
            label: 'Protein',
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroRing(
            isDark: isDark,
            color: carbs,
            value: '$carbsTarget',
            unit: 'g',
            label: 'Carbs',
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MacroRing(
            isDark: isDark,
            color: fat,
            value: '$fatTarget',
            unit: 'g',
            label: 'Fat',
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ),
      ],
    );
  }
}

class _MacroRing extends StatelessWidget {
  final bool isDark;
  final Color color;
  final String value;
  final String unit;
  final String label;
  final String? footnote;
  final Color textPrimary;
  final Color textMuted;

  const _MacroRing({
    required this.isDark,
    required this.color,
    required this.value,
    required this.unit,
    required this.label,
    required this.textPrimary,
    required this.textMuted,
    this.footnote,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: CustomPaint(
            painter: _MacroRingPainter(color: color, isDark: isDark),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                        height: 1.0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    unit,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textMuted,
            letterSpacing: 0.5,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (footnote != null) ...[
          const SizedBox(height: 2),
          Text(
            footnote!,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: textMuted.withValues(alpha: 0.8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Footer pill merged into the Current Targets card. Renders the user's
/// primary nutrition goal as a tappable chip, with any secondary goals
/// shown as smaller adjacent chips. Tapping anywhere on the row opens the
/// existing edit-goals sheet (handled by the caller).
class _GoalPill extends StatelessWidget {
  final String primaryGoal;
  final List<String> allGoals;
  final VoidCallback onEdit;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;

  const _GoalPill({
    required this.primaryGoal,
    required this.allGoals,
    required this.onEdit,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
  });

  /// Map a goal `value` (e.g. 'lose_fat') to a nice display string.
  static String _displayName(String value) {
    return NutritionGoal.fromString(value).displayName;
  }

  IconData _iconFor(String value) {
    switch (value) {
      case 'lose_fat':
        return Icons.local_fire_department_rounded;
      case 'build_muscle':
        return Icons.fitness_center_rounded;
      case 'maintain':
        return Icons.balance_rounded;
      case 'improve_energy':
        return Icons.bolt_rounded;
      case 'eat_healthier':
        return Icons.eco_rounded;
      case 'recomposition':
        return Icons.swap_vert_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Color _colorFor(String value, bool isDark) {
    // Match each goal to a semantic accent so users can scan the pill.
    switch (value) {
      case 'lose_fat':
        return AppColors.orange;
      case 'build_muscle':
        return AppColors.purple;
      case 'maintain':
        return AppColors.green;
      case 'improve_energy':
        return AppColors.yellow;
      case 'eat_healthier':
        return AppColors.green;
      case 'recomposition':
        return AppColors.cyan;
      default:
        return isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = _colorFor(primaryGoal, isDark);
    final secondary = allGoals.where((g) => g != primaryGoal).toList();

    return InkWell(
      onTap: onEdit,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            Icon(Icons.flag_rounded, size: 13, color: textMuted),
            const SizedBox(width: 6),
            Text(
              'GOAL',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 10),
            // Primary goal chip.
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_iconFor(primaryGoal), size: 13, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    _displayName(primaryGoal),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
            // Secondary goals collapsed into a "+N" badge when there are
            // extras, so the pill row never wraps beyond a single line.
            if (secondary.isNotEmpty) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: textMuted.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '+${secondary.length}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: textMuted,
                  ),
                ),
              ),
            ],
            const Spacer(),
            Icon(Icons.chevron_right_rounded, size: 18, color: textMuted),
          ],
        ),
      ),
    );
  }
}

/// Small tinted icon button used inside the Current Targets card header.
/// Renders either an [icon] or a small spinner (when [showSpinner] is true).
/// Disabled state (null [onTap]) dims the icon so the user can see the
/// button is temporarily unavailable during async work.
class _TargetsHeaderIconButton extends StatelessWidget {
  final IconData? icon;
  final Color tint;
  final VoidCallback? onTap;
  final bool showSpinner;
  final String? tooltip;

  const _TargetsHeaderIconButton({
    required this.icon,
    required this.tint,
    required this.onTap,
    this.showSpinner = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null && !showSpinner;
    final effectiveTint = disabled ? tint.withValues(alpha: 0.35) : tint;
    final bg = tint.withValues(alpha: disabled ? 0.06 : 0.15);

    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: showSpinner
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: tint,
                ),
              )
            : Icon(icon, size: 18, color: effectiveTint),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: button) : button;
  }
}

class _MacroRingPainter extends CustomPainter {
  final Color color;
  final bool isDark;

  _MacroRingPainter({required this.color, required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.shortestSide * 0.10;
    final radius = (size.shortestSide - stroke) / 2;

    // Soft fill behind the ring so the center number sits on a subtle halo.
    final fill = Paint()
      ..style = PaintingStyle.fill
      ..color = color.withValues(alpha: isDark ? 0.10 : 0.08);
    canvas.drawCircle(center, radius, fill);

    // Outer ring.
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = color.withValues(alpha: isDark ? 0.75 : 0.85);
    canvas.drawCircle(center, radius, ringPaint);
  }

  @override
  bool shouldRepaint(covariant _MacroRingPainter old) =>
      old.color != color || old.isDark != isDark;
}

