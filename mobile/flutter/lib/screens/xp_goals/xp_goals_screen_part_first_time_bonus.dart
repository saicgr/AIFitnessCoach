part of 'xp_goals_screen.dart';


class _FirstTimeBonus {
  final String type;
  final String title;
  final int xp;
  final IconData icon;
  final bool isAwarded;

  _FirstTimeBonus({
    required this.type,
    required this.title,
    required this.xp,
    required this.icon,
    required this.isAwarded,
  });
}


class _DailyGoal {
  final String title;
  final int xp;
  final bool isComplete;
  final IconData icon;

  _DailyGoal({
    required this.title,
    required this.xp,
    required this.isComplete,
    required this.icon,
  });
}


/// Level data model
class _LevelInfo {
  final int level;
  final int xpRequired;
  final String title;
  final String levelName;
  final String? reward;
  final String? rewardIcon;
  final bool isMilestone;

  const _LevelInfo({
    required this.level,
    required this.xpRequired,
    required this.title,
    required this.levelName,
    this.reward,
    this.rewardIcon,
    this.isMilestone = false,
  });

  static String getLevelName(int level) {
    const levelNames = <int, String>{
      // Beginner (1-10)
      1: 'First Steps', 2: 'Awakening', 3: 'Foundation', 4: 'Momentum',
      5: 'Rising Star', 6: 'Steadfast', 7: 'Determined', 8: 'Resilient',
      9: 'Breakthrough', 10: 'Iron Will',
      // Novice (11-25)
      11: 'Pathfinder', 12: 'Trailblazer', 13: 'Forged', 14: 'Unyielding',
      15: 'Disciplined', 16: 'Focused', 17: 'Driven', 18: 'Relentless',
      19: 'Unstoppable', 20: 'Silver Strength', 21: 'Tempered', 22: 'Hardened',
      23: 'Unbreakable', 24: 'Tenacious', 25: 'Dedicated',
      // Apprentice (26-50)
      26: 'Competitor', 27: 'Challenger', 28: 'Fierce', 29: 'Powerhouse',
      30: 'Gold Standard', 31: 'Peak Form', 32: 'Dynamo', 33: 'Juggernaut',
      34: 'Titan', 35: 'Colossus', 36: 'Champion', 37: 'Conqueror',
      38: 'Dominator', 39: 'Crusher', 40: 'Diamond Core', 41: 'Invincible',
      42: 'Supreme', 43: 'Almighty', 44: 'Ascendant', 45: 'Mythic Rise',
      46: 'Ascended', 47: 'Paragon', 48: 'Zenith', 49: 'Pinnacle', 50: 'Veteran',
      // Athlete (51-75)
      51: 'Elite Guard', 52: 'Vanguard', 53: 'Sentinel', 54: 'Warden',
      55: 'Gladiator', 56: 'Spartan', 57: 'Berserker', 58: 'Valkyrie',
      59: 'Phoenix', 60: 'Elite Force', 61: 'Apex', 62: 'Sovereign',
      63: 'Overlord', 64: 'Commander', 65: 'General', 66: 'Warlord',
      67: 'Conqueror II', 68: 'Destroyer', 69: 'Annihilator', 70: 'Purple Heart',
      71: 'Harbinger', 72: 'Omega', 73: 'Absolute', 74: 'Supreme II', 75: 'Triumph',
      // Elite (76-100)
      76: 'Grandmaster', 77: 'Sage', 78: 'Oracle', 79: 'Prophet', 80: 'Visionary',
      81: 'Virtuoso', 82: 'Prodigy', 83: 'Genius', 84: 'Mastermind',
      85: 'Legendary Rise', 86: 'Architect', 87: 'Creator', 88: 'Worldbreaker',
      89: 'Godslayer', 90: 'Cosmic', 91: 'Celestial', 92: 'Divine',
      93: 'Eternal', 94: 'Infinite', 95: 'Ultimate', 96: 'Omega II',
      97: 'Alpha', 98: 'Primordial', 99: 'Apex Predator', 100: 'Centurion',
      // Master (101-125)
      101: 'True Master', 102: 'Sage II', 103: 'Warmaster', 104: 'Iron Sage',
      105: 'Stormcaller', 106: 'Flamebringer', 107: 'Thunderlord', 108: 'Frostborn',
      109: 'Earthshaker', 110: 'Windwalker', 111: 'Shadowblade', 112: 'Lightbringer',
      113: 'Starforger', 114: 'Moonstrider', 115: 'Sunkeeper', 116: 'Voidwalker',
      117: 'Runemaster', 118: 'Spellweaver', 119: 'Battlemage', 120: 'Warbringer',
      121: 'Dawnblade', 122: 'Nightfall', 123: 'Stormbringer', 124: 'Ironheart',
      125: 'Grand Master',
      // Champion (126-150)
      126: 'True Champion', 127: 'Siegebreaker', 128: 'Warhammer', 129: 'Soulforge',
      130: 'Titanborn', 131: 'Dragonslayer', 132: 'Leviathan', 133: 'Behemoth',
      134: 'Colossus II', 135: 'Juggernaut II', 136: 'Thundergod', 137: 'Firelord',
      138: 'Icewarden', 139: 'Earthlord', 140: 'Skywarden', 141: 'Abyssal',
      142: 'Celestial II', 143: 'Nebula', 144: 'Supernova', 145: 'Pulsar',
      146: 'Quasar', 147: 'Galaxy', 148: 'Universe', 149: 'Multiverse',
      150: 'Grand Champion',
      // Legend (151-175)
      151: 'Living Legend', 152: 'Mythmaker', 153: 'Storyweaver', 154: 'Fatewriter',
      155: 'Destiny', 156: 'Prophecy', 157: 'Revelation', 158: 'Ascension',
      159: 'Enlightened', 160: 'Awakened', 161: 'Transcended', 162: 'Reborn',
      163: 'Evolved', 164: 'Perfected', 165: 'Exalted', 166: 'Glorified',
      167: 'Sanctified', 168: 'Hallowed', 169: 'Blessed', 170: 'Anointed',
      171: 'Chosen', 172: 'Ordained', 173: 'Destined', 174: 'Fated',
      175: 'Grand Legend',
      // Mythic (176-200)
      176: 'Mythic I', 177: 'Mythic II', 178: 'Mythic III', 179: 'Mythic IV',
      180: 'Mythic V', 181: 'Mythic VI', 182: 'Mythic VII', 183: 'Mythic VIII',
      184: 'Mythic IX', 185: 'Mythic X', 186: 'Mythic XI', 187: 'Mythic XII',
      188: 'Mythic XIII', 189: 'Mythic XIV', 190: 'Mythic XV', 191: 'Mythic XVI',
      192: 'Mythic XVII', 193: 'Mythic XVIII', 194: 'Mythic XIX', 195: 'Mythic XX',
      196: 'Mythic XXI', 197: 'Mythic XXII', 198: 'Mythic XXIII', 199: 'Mythic XXIV',
      200: 'Mythic XXV',
      // Immortal (201-225)
      201: 'Immortal I', 202: 'Immortal II', 203: 'Immortal III', 204: 'Immortal IV',
      205: 'Immortal V', 206: 'Immortal VI', 207: 'Immortal VII', 208: 'Immortal VIII',
      209: 'Immortal IX', 210: 'Immortal X', 211: 'Immortal XI', 212: 'Immortal XII',
      213: 'Immortal XIII', 214: 'Immortal XIV', 215: 'Immortal XV', 216: 'Immortal XVI',
      217: 'Immortal XVII', 218: 'Immortal XVIII', 219: 'Immortal XIX', 220: 'Immortal XX',
      221: 'Immortal XXI', 222: 'Immortal XXII', 223: 'Immortal XXIII', 224: 'Immortal XXIV',
      225: 'Immortal XXV',
      // Transcendent (226-250)
      226: 'Transcendent I', 227: 'Transcendent II', 228: 'Transcendent III',
      229: 'Transcendent IV', 230: 'Transcendent V', 231: 'Transcendent VI',
      232: 'Transcendent VII', 233: 'Transcendent VIII', 234: 'Transcendent IX',
      235: 'Transcendent X', 236: 'Transcendent XI', 237: 'Transcendent XII',
      238: 'Transcendent XIII', 239: 'Transcendent XIV', 240: 'Transcendent XV',
      241: 'Transcendent XVI', 242: 'Transcendent XVII', 243: 'Transcendent XVIII',
      244: 'Transcendent XIX', 245: 'Transcendent XX', 246: 'Transcendent XXI',
      247: 'Transcendent XXII', 248: 'Transcendent XXIII', 249: 'Transcendent XXIV',
      250: 'Transcendent XXV',
    };
    return levelNames[level] ?? 'Level $level';
  }
}


/// All Levels Sheet
class _AllLevelsSheet extends StatelessWidget {
  final int currentLevel;
  final Color accentColor;

  const _AllLevelsSheet({
    required this.currentLevel,
    required this.accentColor,
  });

  /// XP required per level, matching backend _XP_TABLE (Migration 227)
  static const _xpTable = [
    // Levels 1-10 (Beginner): Quick early wins
    25, 30, 40, 50, 65, 80, 100, 120, 150, 180,
    // Levels 11-25 (Novice)
    200, 220, 240, 260, 280, 300, 320, 340, 360, 380, 400, 420, 440, 460, 500,
    // Levels 26-50 (Apprentice)
    550, 600, 650, 700, 750, 800, 850, 900, 950, 1000, 1050, 1100, 1150, 1200, 1250, 1300, 1350, 1400, 1450, 1500, 1550, 1600, 1650, 1700, 1800,
    // Levels 51-75 (Athlete)
    1900, 2000, 2100, 2200, 2300, 2400, 2500, 2600, 2700, 2800, 2900, 3000, 3100, 3200, 3300, 3400, 3500, 3600, 3700, 3800, 3900, 4000, 4100, 4200, 4500,
    // Levels 76-100 (Elite)
    4800, 5000, 5200, 5400, 5600, 5800, 6000, 6200, 6400, 6600, 6800, 7000, 7200, 7400, 7600, 7800, 8000, 8200, 8400, 8600, 8800, 9000, 9200, 9400, 10000,
    // Levels 101-125 (Master)
    10500, 11000, 11500, 12000, 12500, 13000, 13500, 14000, 14500, 15000, 15500, 16000, 16500, 17000, 17500, 18000, 18500, 19000, 19500, 20000, 20500, 21000, 21500, 22000, 23000,
    // Levels 126-150 (Champion)
    24000, 25000, 26000, 27000, 28000, 29000, 30000, 31000, 32000, 33000, 34000, 35000, 36000, 37000, 38000, 39000, 40000, 41000, 42000, 43000, 44000, 45000, 46000, 47000, 50000,
    // Levels 151-175 (Legend)
    52000, 54000, 56000, 58000, 60000, 62000, 64000, 66000, 68000, 70000, 72000, 74000, 76000, 78000, 80000, 82000, 84000, 86000, 88000, 90000, 92000, 94000, 96000, 98000, 100000,
  ];

  static int _getXpForLevel(int level) {
    if (level >= 250) return 0;
    if (level <= 175) return _xpTable[level - 1];
    return 100000; // Levels 176-250 flat
  }

  static String _getTitleForLevel(int level) {
    if (level <= 10) return 'Beginner';
    if (level <= 25) return 'Novice';
    if (level <= 50) return 'Apprentice';
    if (level <= 75) return 'Athlete';
    if (level <= 100) return 'Elite';
    if (level <= 125) return 'Master';
    if (level <= 150) return 'Champion';
    if (level <= 175) return 'Legend';
    if (level <= 200) return 'Mythic';
    if (level <= 225) return 'Immortal';
    return 'Transcendent';
  }

  /// Milestone rewards matching backend xp_endpoints.py
  static const _milestoneRewards = <int, String>{
    5: 'Streak Shield x1',
    10: '2x XP Token',
    15: 'Fitness Crate x2',
    20: 'Streak Shield x2',
    25: '2x XP Token x2',
    30: 'Premium Crate',
    40: 'Streak Shield x3',
    50: '2x XP Token x3 + Premium Crate',
    60: 'Fitness Crate x5',
    75: 'Premium Crate x2',
    100: 'Elite Badge + Premium Crate x3',
    125: 'Master Badge + Master Crate',
    150: 'Champion Badge + Champion Crate x2',
    175: 'Legend Badge + Legend Crate x3',
    200: 'Mythic Badge + Mythic Crate x5',
    225: 'Immortal Badge + Immortal Crate x7',
    250: 'Transcendent Badge + Legendary Crate x10',
  };

  static const _milestoneIcons = <int, String>{
    5: '🛡️', 10: '⚡', 15: '📦', 20: '🛡️', 25: '⚡',
    30: '🎁', 40: '🛡️', 50: '🎁', 60: '📦', 75: '🎁',
    100: '🎖️', 125: '🎖️', 150: '🎖️', 175: '🎖️',
    200: '🎖️', 225: '🎖️', 250: '🏆',
  };

  static List<_LevelInfo> getAllLevels() {
    final levels = <_LevelInfo>[];

    for (int level = 2; level <= 250; level++) {
      final xpRequired = _getXpForLevel(level);
      final title = _getTitleForLevel(level);
      final reward = _milestoneRewards[level];
      final rewardIcon = _milestoneIcons[level];
      final isMilestone = _milestoneRewards.containsKey(level);

      levels.add(_LevelInfo(
        level: level,
        xpRequired: xpRequired,
        title: title,
        levelName: _LevelInfo.getLevelName(level),
        reward: reward,
        rewardIcon: rewardIcon,
        isMilestone: isMilestone,
      ));
    }

    return levels;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textColorStrong = isDark ? textColor : Colors.black.withValues(alpha: 0.85);
    final textMutedStrong = isDark ? textMuted : Colors.black.withValues(alpha: 0.55);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.15);

    final levels = getAllLevels();

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, dragScrollController) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                top: BorderSide(
                  color: isDark ? Colors.white.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: textMuted.withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                  child: Row(
                    children: [
                      Icon(Icons.stairs, color: accentColor, size: 24),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('All Levels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColorStrong)),
                            Text('Level $currentLevel • ${levels.length} levels total', style: TextStyle(fontSize: 12, color: textMutedStrong)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.close, color: textMutedStrong, size: 22)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      _buildLegendItem('🎁', 'Milestone', textMutedStrong),
                      const SizedBox(width: 16),
                      _buildLegendItem('⚡', 'XP Bonus', textMutedStrong),
                      const SizedBox(width: 16),
                      _buildLegendItem('🛡️', 'Consumable', textMutedStrong),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: dragScrollController,
                    padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                    itemCount: levels.length,
                    itemBuilder: (context, index) {
                      final level = levels[index];
                      return _buildLevelRow(level, level.level == currentLevel, level.level < currentLevel, textColorStrong, textMutedStrong, cardBg, borderColor, accentColor, isDark);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String icon, String label, Color textMuted) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 12)),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: textMuted)),
      ],
    );
  }

  Widget _buildLevelRow(_LevelInfo level, bool isCurrentLevel, bool isCompleted, Color textColor, Color textMuted, Color cardBg, Color borderColor, Color accentColor, bool isDark) {
    final titleColor = _getTitleColor(level.title);

    Color getRewardColor() {
      if (level.reward == null) return Colors.grey;
      if (level.reward!.contains('Crate') || level.reward!.contains('crate')) {
        if (level.reward!.contains('Diamond')) return const Color(0xFF00BCD4);
        if (level.reward!.contains('Legendary')) return const Color(0xFFFF9800);
        if (level.reward!.contains('Fitness')) return const Color(0xFF4CAF50);
        return const Color(0xFF9C27B0);
      }
      if (level.reward!.contains('Frame')) return const Color(0xFFFF8F00);
      if (level.reward!.contains('Badge')) return titleColor;
      if (level.reward!.contains('Theme')) return const Color(0xFF9C27B0);
      if (level.reward!.contains('T-Shirt') || level.reward!.contains('Hoodie') || level.reward!.contains('Shaker')) return const Color(0xFFE91E63);
      if (level.reward!.contains('XP')) return const Color(0xFFFF8F00);
      if (level.reward!.contains('Shield')) return const Color(0xFF2196F3);
      if (level.reward!.contains('Token')) return const Color(0xFF9C27B0);
      return accentColor;
    }

    final rewardColor = getRewardColor();
    final isBigMilestone = const {10, 25, 50, 75, 100, 125, 150, 175, 200, 225, 250}.contains(level.level);

    final cardBackground = isCurrentLevel
        ? (isDark ? const Color(0xFF1A3A5C) : const Color(0xFFE3F2FD))
        : isCompleted
            ? (isDark ? const Color(0xFF1B4332) : const Color(0xFFE8F5E9))
            : isBigMilestone
                ? (isDark ? const Color(0xFF3E2723) : const Color(0xFFFFF8E1))
                : isDark ? cardBg : Colors.grey.shade100;
    final strongBorder = isCurrentLevel
        ? accentColor.withValues(alpha: isDark ? 0.7 : 0.8)
        : isCompleted
            ? AppColors.green.withValues(alpha: isDark ? 0.5 : 0.6)
            : isBigMilestone
                ? rewardColor.withValues(alpha: isDark ? 0.6 : 0.7)
                : isDark ? borderColor : Colors.grey.shade300;
    final badgeColor = isCompleted || isCurrentLevel ? null : isBigMilestone ? null : (isDark ? textMuted.withValues(alpha: 0.2) : Colors.grey.shade300);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(isBigMilestone ? 14 : 12),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: strongBorder, width: isCurrentLevel ? 2.5 : isBigMilestone ? 2 : 1.5),
        boxShadow: isBigMilestone ? [BoxShadow(color: rewardColor.withValues(alpha: isDark ? 0.2 : 0.15), blurRadius: 8, offset: const Offset(0, 2))]
            : isDark ? null : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4, offset: const Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isBigMilestone ? 50 : 44, height: isBigMilestone ? 50 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isCompleted || isCurrentLevel || isBigMilestone
                      ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
                          colors: isCurrentLevel ? [accentColor, accentColor.withValues(alpha: 0.7)]
                              : isCompleted ? [titleColor, titleColor.withValues(alpha: 0.7)]
                              : [rewardColor, rewardColor.withValues(alpha: 0.7)])
                      : null,
                  color: badgeColor,
                  boxShadow: isBigMilestone ? [BoxShadow(color: rewardColor.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                ),
                child: Center(
                  child: isCompleted && !isCurrentLevel
                      ? const Icon(Icons.check, color: Colors.white, size: 22)
                      : Text(level.level.toString(), style: TextStyle(fontSize: level.level >= 100 ? 14 : isBigMilestone ? 18 : 15, fontWeight: FontWeight.bold, color: isCurrentLevel || isCompleted || isBigMilestone ? Colors.white : (isDark ? textMuted : Colors.grey.shade600))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(level.levelName, style: TextStyle(fontSize: isBigMilestone ? 15 : 14, fontWeight: FontWeight.w600, color: isDark ? textColor : Colors.black87), overflow: TextOverflow.ellipsis)),
                        if (isCurrentLevel) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: accentColor, borderRadius: BorderRadius.circular(4)), child: const Text('YOU', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white)))],
                        if (isBigMilestone && !isCurrentLevel) ...[const SizedBox(width: 6), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(gradient: LinearGradient(colors: [Colors.amber.shade600, Colors.orange.shade600]), borderRadius: BorderRadius.circular(4)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.star, size: 10, color: Colors.white), const SizedBox(width: 2), Text(level.level == 250 ? 'LEGENDARY' : 'MILESTONE', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.white))]))],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1), decoration: BoxDecoration(color: titleColor.withValues(alpha: isDark ? 0.2 : 0.15), borderRadius: BorderRadius.circular(4)), child: Text(level.title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: titleColor))),
                        const SizedBox(width: 8),
                        Text('${_formatNumber(level.xpRequired)} XP', style: TextStyle(fontSize: 11, color: isDark ? textMuted : Colors.black54)),
                      ],
                    ),
                  ],
                ),
              ),
              if (level.reward != null && !isBigMilestone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(color: rewardColor.withValues(alpha: isDark ? 0.2 : 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: rewardColor.withValues(alpha: isDark ? 0.4 : 0.35))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [if (level.rewardIcon != null) Text(level.rewardIcon!, style: const TextStyle(fontSize: 14))]),
                ),
            ],
          ),
          if (level.reward != null && isBigMilestone) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? rewardColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: rewardColor.withValues(alpha: isDark ? 0.4 : 0.5), width: 1.5),
                boxShadow: isDark ? null : [BoxShadow(color: rewardColor.withValues(alpha: 0.1), blurRadius: 4, offset: const Offset(0, 2))],
              ),
              child: Row(
                children: [
                  Container(width: 40, height: 40, decoration: BoxDecoration(color: rewardColor.withValues(alpha: isDark ? 0.25 : 0.15), borderRadius: BorderRadius.circular(10), border: Border.all(color: rewardColor.withValues(alpha: 0.3))), child: Center(child: Text(level.rewardIcon ?? '🎁', style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('REWARD', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: rewardColor, letterSpacing: 1)), const SizedBox(height: 2), Text(level.reward!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? textColor : Colors.black87))])),
                  if (!isCompleted) Icon(Icons.lock_outline, size: 18, color: isDark ? textMuted.withValues(alpha: 0.5) : Colors.grey.shade500),
                  if (isCompleted) const Icon(Icons.check_circle, size: 18, color: AppColors.green),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getTitleColor(String title) {
    switch (title) {
      case 'Beginner': return const Color(0xFF9E9E9E);
      case 'Novice': return const Color(0xFF8BC34A);
      case 'Apprentice': return const Color(0xFF4CAF50);
      case 'Athlete': return const Color(0xFF2196F3);
      case 'Elite': return const Color(0xFF9C27B0);
      case 'Master': return const Color(0xFFFF9800);
      case 'Champion': return const Color(0xFFFF5722);
      case 'Legend': return const Color(0xFFFFD700);
      case 'Mythic': return const Color(0xFFE040FB);
      case 'Immortal': return const Color(0xFF00E5FF);
      case 'Transcendent': return const Color(0xFFFF1744);
      default: return const Color(0xFF9E9E9E);
    }
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(number % 1000 == 0 ? 0 : 1)}K';
    }
    return number.toString();
  }
}


/// Delegate for pinning the tab bar at the top when scrolled
class _StickyTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyTabBarDelegate({required this.child});

  // SegmentedTabBar height: padding(8+8) + containerPadding(4+4) + buttonPadding(12+12) + text(~16) = ~64
  // Adding a bit extra to prevent clipping
  @override
  double get minExtent => 68;
  @override
  double get maxExtent => 68;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyTabBarDelegate oldDelegate) {
    return child != oldDelegate.child;
  }
}

