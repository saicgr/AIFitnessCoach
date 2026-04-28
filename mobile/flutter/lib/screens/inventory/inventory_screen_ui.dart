part of 'inventory_screen.dart';

/// UI builder methods extracted from _InventoryScreenState
extension _InventoryScreenStateUI on _InventoryScreenState {

  Widget _buildTrustLevelCard(
    int trustLevel,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color cardBorder,
    Color accentColor,
    bool has2xXPActive,
  ) {
    // Resolve base trust-level display first.
    final (name, baseColor, icon, baseMultiplier) = switch (trustLevel) {
      0 => ('New User', Colors.grey, Icons.person_outline, '0.5x'),
      1 => ('Verified', const Color(0xFF3B82F6), Icons.verified, '1.0x'),
      2 => ('Trusted', const Color(0xFF22C55E), Icons.star, '1.2x'),
      _ => ('Verified', const Color(0xFF3B82F6), Icons.verified, '1.0x'),
    };
    // When the 2x XP boost is active, override the displayed multiplier with
    // a golden, attention-grabbing "2.0x" so users see the active boost
    // reflected here too. Trust-level name/icon stays the same since trust
    // level itself didn't change — only the effective XP multiplier did.
    const goldColor = Color(0xFFFFC107);
    final color = has2xXPActive ? goldColor : baseColor;
    final multiplier = has2xXPActive ? '2.0x' : baseMultiplier;

    return GestureDetector(
      onTap: _showTrustLevelInfo,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.2),
              color.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trust Level',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.5)),
              ),
              child: Column(
                children: [
                  Text(
                    multiplier,
                    style: TextStyle(
                      color: color,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'XP',
                    style: TextStyle(
                      color: color.withValues(alpha: 0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.info_outline,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildDailyCratesSection(
    bool isDark,
    Color textColor,
    Color textMuted,
    Color elevatedColor,
    Color cardBorder,
  ) {
    final dailyCrates = ref.watch(dailyCratesProvider);
    final claimed = dailyCrates?.claimed ?? false;
    final dailyAvailable = dailyCrates?.dailyCrateAvailable ?? true;
    final streakAvailable = dailyCrates?.streakCrateAvailable ?? false;
    final activityAvailable = dailyCrates?.activityCrateAvailable ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Crates',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          claimed ? 'Come back tomorrow for more!' : 'Pick 1 of 3 crates daily',
          style: TextStyle(
            color: textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),

        // Daily Crate
        _DailyCrateCard(
          emoji: '📦',
          name: 'Daily Crate',
          description: '25-75 XP',
          color: const Color(0xFF78909C),
          isAvailable: dailyAvailable && !claimed,
          isLocked: false,
          lockedReason: claimed ? 'Claimed today' : null,
          onTap: claimed ? null : () => _showDailyCrateSheet(context),
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 12),

        // Streak Crate
        _DailyCrateCard(
          emoji: '🔥',
          name: 'Streak Crate',
          description: '75-150 XP + items',
          color: const Color(0xFFFF7043),
          isAvailable: streakAvailable && !claimed,
          isLocked: !streakAvailable,
          lockedReason: !streakAvailable ? 'Requires 7+ day streak' : (claimed ? 'Claimed today' : null),
          onTap: (streakAvailable && !claimed) ? () => _showDailyCrateSheet(context) : null,
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
        const SizedBox(height: 12),

        // Activity Crate
        _DailyCrateCard(
          emoji: '⭐',
          name: 'Activity Crate',
          description: '150-250 XP + guaranteed item',
          color: const Color(0xFFFFB300),
          isAvailable: activityAvailable && !claimed,
          isLocked: !activityAvailable,
          lockedReason: !activityAvailable ? 'Complete all daily goals' : (claimed ? 'Claimed today' : null),
          onTap: (activityAvailable && !claimed) ? () => _showDailyCrateSheet(context) : null,
          isDark: isDark,
          elevatedColor: elevatedColor,
          textColor: textColor,
          textMuted: textMuted,
          cardBorder: cardBorder,
        ),
      ],
    );
  }

}
