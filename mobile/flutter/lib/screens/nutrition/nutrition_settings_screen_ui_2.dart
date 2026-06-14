part of 'nutrition_settings_screen.dart';

/// UI builder methods extracted from _NutritionSettingsScreenState
extension _NutritionSettingsScreenStateUI2 on _NutritionSettingsScreenState {

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
        color: ThemeColors.of(context).surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.insights_rounded,
                    color: isDue ? blue : textMuted,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context).nutritionSettingsScreenReviewAdjustTargets,
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
                      color: ThemeColors.of(context).surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text(
                      AppLocalizations.of(context).nutritionSettingsScreenDue.toUpperCase(),
                      style: ZType.lbl(10, color: textPrimary, letterSpacing: 1),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ZealovaButton(
              label: AppLocalizations.of(context).nutritionSettingsScreenRunWeeklyCheckIn,
              variant: ZealovaButtonVariant.ghost,
              trailingIcon: Icons.play_arrow_rounded,
              height: 48,
              onTap: () {
                HapticService.medium();
                showWeeklyCheckinSheet(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildSkeleton(bool isDark, Color elevated, Color cardBorder) {
    final shimmer = isDark
        ? Colors.white.withValues(alpha: 0.06)
        : Colors.black.withValues(alpha: 0.06);
    final shimmerDark = isDark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.10);

    Widget block(double w, double h, {double radius = 8}) => Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: shimmer,
            borderRadius: BorderRadius.circular(radius),
          ),
        );

    Widget row() => Container(
          margin: const EdgeInsets.only(bottom: 1),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: elevated,
            border: Border(bottom: BorderSide(color: cardBorder)),
          ),
          child: Row(
            children: [
              block(32, 32, radius: 10),
              const SizedBox(width: 14),
              Expanded(child: block(120, 14)),
              block(60, 12),
              const SizedBox(width: 8),
              block(16, 16, radius: 4),
            ],
          ),
        );

    Widget section(String label, int count) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: block(80, 11),
            ),
            Container(
              decoration: BoxDecoration(
                color: elevated,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: cardBorder),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(children: List.generate(count, (_) => row())),
            ),
          ],
        );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Macro targets card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: elevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: shimmerDark),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block(100, 14),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    block(60, 36, radius: 10),
                    block(60, 36, radius: 10),
                    block(60, 36, radius: 10),
                    block(60, 36, radius: 10),
                  ],
                ),
              ],
            ),
          ),
          section('', 3),
          section('', 2),
          section('', 3),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

}
