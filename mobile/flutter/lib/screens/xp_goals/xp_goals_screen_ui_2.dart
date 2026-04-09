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
    final awardedBonuses = ref.watch(awardedBonusesProvider);

    final dividerColor = isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade300;

    // First-time bonuses list
    final bonuses = [
      _FirstTimeBonus(
        type: 'first_workout',
        title: 'Complete First Workout',
        xp: 150,
        icon: Icons.fitness_center,
        isAwarded: awardedBonuses.contains('first_workout'),
      ),
      _FirstTimeBonus(
        type: 'first_meal_log',
        title: 'Log First Meal',
        xp: 50,
        icon: Icons.restaurant,
        isAwarded: awardedBonuses.contains('first_breakfast') ||
            awardedBonuses.contains('first_lunch') ||
            awardedBonuses.contains('first_dinner') ||
            awardedBonuses.contains('first_snack'),
      ),
      _FirstTimeBonus(
        type: 'first_weight_log',
        title: 'Log First Weight',
        xp: 50,
        icon: Icons.monitor_weight_outlined,
        isAwarded: awardedBonuses.contains('first_weight_log'),
      ),
      _FirstTimeBonus(
        type: 'first_protein_goal',
        title: 'Hit First Protein Goal',
        xp: 100,
        icon: Icons.egg_alt,
        isAwarded: awardedBonuses.contains('first_protein_goal'),
      ),
      _FirstTimeBonus(
        type: 'first_chat',
        title: 'Chat with AI Coach',
        xp: 15,
        icon: Icons.chat_bubble_outline,
        isAwarded: awardedBonuses.contains('first_chat'),
      ),
      _FirstTimeBonus(
        type: 'first_pr',
        title: 'Set First Personal Record',
        xp: 100,
        icon: Icons.emoji_events,
        isAwarded: awardedBonuses.contains('first_pr'),
      ),
    ];

    final earnedCount = bonuses.where((b) => b.isAwarded).length;
    final totalXPEarned = bonuses.where((b) => b.isAwarded).fold(0, (sum, b) => sum + b.xp);
    final totalXPAvailable = bonuses.fold(0, (sum, b) => sum + b.xp);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Summary row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: isDark ? 0.08 : 0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn(
                  '$earnedCount/${bonuses.length}',
                  'Bonuses',
                  isDark ? textColor : Colors.black87,
                  isDark ? textMuted : Colors.black54,
                ),
                Container(
                  width: 1,
                  height: 28,
                  color: isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade400,
                ),
                _buildStatColumn(
                  '+$totalXPEarned',
                  'of $totalXPAvailable XP',
                  isDark ? textColor : Colors.black87,
                  isDark ? textMuted : Colors.black54,
                ),
              ],
            ),
          ),

          // Bonuses list
          ...bonuses.map((bonus) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: dividerColor),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: bonus.isAwarded
                            ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12)
                            : (isDark ? textMuted.withValues(alpha: 0.1) : Colors.grey.shade200),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        bonus.isAwarded ? Icons.check : bonus.icon,
                        size: 15,
                        color: bonus.isAwarded ? Colors.amber : (isDark ? textMuted : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        bonus.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: bonus.isAwarded ? textMuted : textColor,
                          decoration: bonus.isAwarded ? TextDecoration.lineThrough : null,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: bonus.isAwarded
                            ? Colors.amber.withValues(alpha: isDark ? 0.15 : 0.12)
                            : Colors.amber.withValues(alpha: isDark ? 0.1 : 0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!bonus.isAwarded)
                            const Icon(Icons.star, size: 11, color: Colors.amber),
                          if (!bonus.isAwarded) const SizedBox(width: 3),
                          Text(
                            '+${bonus.xp} XP',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: bonus.isAwarded ? Colors.amber.shade700 : Colors.amber.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

}
