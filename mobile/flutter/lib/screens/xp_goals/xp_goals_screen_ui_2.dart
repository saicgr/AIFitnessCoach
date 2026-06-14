part of 'xp_goals_screen.dart';

/// UI builder methods extracted from _XPGoalsScreenState
extension _XPGoalsScreenStateUI2 on _XPGoalsScreenState {

  Widget _buildFirstTimeBonusesCard(
    BuildContext context,
    WidgetRef ref,
    Color textColor,
    Color textMuted,
    Color cardBg,
    Color borderColor,
    Color accentColor,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surface : AppColorsLight.surface;
    final awardedBonuses = ref.watch(awardedBonusesProvider);

    // First-time bonuses list
    final bonuses = [
      _FirstTimeBonus(
        type: 'first_workout',
        title: AppLocalizations.of(context).xpGoalsScreenCompleteFirstWorkout,
        xp: 150,
        icon: Icons.fitness_center,
        isAwarded: awardedBonuses.contains('first_workout'),
      ),
      _FirstTimeBonus(
        type: 'first_meal_log',
        title: AppLocalizations.of(context).xpGoalsScreenLogFirstMeal,
        xp: 50,
        icon: Icons.restaurant,
        isAwarded: awardedBonuses.contains('first_breakfast') ||
            awardedBonuses.contains('first_lunch') ||
            awardedBonuses.contains('first_dinner') ||
            awardedBonuses.contains('first_snack'),
      ),
      _FirstTimeBonus(
        type: 'first_weight_log',
        title: AppLocalizations.of(context).xpGoalsScreenLogFirstWeight,
        xp: 50,
        icon: Icons.monitor_weight_outlined,
        isAwarded: awardedBonuses.contains('first_weight_log'),
      ),
      _FirstTimeBonus(
        type: 'first_protein_goal',
        title: AppLocalizations.of(context).xpGoalsScreenHitFirstProteinGoal,
        xp: 100,
        icon: Icons.egg_alt,
        isAwarded: awardedBonuses.contains('first_protein_goal'),
      ),
      _FirstTimeBonus(
        type: 'first_chat',
        title: AppLocalizations.of(context).xpGoalsScreenChatWithAiCoach,
        xp: 15,
        icon: Icons.chat_bubble_outline,
        isAwarded: awardedBonuses.contains('first_chat'),
      ),
      _FirstTimeBonus(
        type: 'first_pr',
        title: AppLocalizations.of(context).xpGoalsScreenSetFirstPersonalRecord,
        xp: 100,
        icon: Icons.emoji_events,
        isAwarded: awardedBonuses.contains('first_pr'),
      ),
    ];

    final earnedCount = bonuses.where((b) => b.isAwarded).length;
    final totalXPEarned = bonuses.where((b) => b.isAwarded).fold(0, (sum, b) => sum + b.xp);
    final totalXPAvailable = bonuses.fold(0, (sum, b) => sum + b.xp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary meta line — Anton hero counts + Barlow labels on a hairline
        Container(
          padding: const EdgeInsets.only(bottom: 12),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.hairline)),
          ),
          child: Row(
            children: [
              _buildXpStatColumn(
                '$earnedCount/${bonuses.length}',
                'Bonuses',
                textColor,
                textMuted,
              ),
              const SizedBox(width: 28),
              _buildXpStatColumn(
                '+$totalXPEarned',
                'of $totalXPAvailable XP',
                textColor,
                textMuted,
                heroColor: AppColors.gamGold,
              ),
            ],
          ),
        ),

        // Bonuses list — hairline rows; gold open / green awarded
        ...bonuses.map((bonus) => Container(
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.hairline),
                ),
              ),
              child: Row(
                children: [
                  // Status circle — green filled when awarded, gold hairline when open
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: bonus.isAwarded ? AppColors.green : surface,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: bonus.isAwarded ? AppColors.green : AppColors.gamGold,
                        width: 1.5,
                      ),
                    ),
                    child: bonus.isAwarded
                        ? const Icon(Icons.check, size: 12, color: Colors.black)
                        : Icon(bonus.icon, size: 11, color: AppColors.gamGold),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      bonus.title,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: bonus.isAwarded ? textMuted : textColor,
                        decoration: bonus.isAwarded ? TextDecoration.lineThrough : null,
                      ),
                    ),
                  ),
                  Text(
                    '+${bonus.xp}',
                    style: ZType.lbl(11,
                        color: bonus.isAwarded ? AppColors.green : AppColors.gamGold,
                        weight: FontWeight.w800,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            )),
      ],
    );
  }

}
