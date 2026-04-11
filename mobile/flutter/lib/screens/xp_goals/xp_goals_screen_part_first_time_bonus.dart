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

  /// Build from backend response map
  factory _LevelInfo.fromJson(Map<String, dynamic> json) {
    final reward = json['milestone_reward'] as String?;
    return _LevelInfo(
      level: json['level'] as int,
      xpRequired: json['xp_required'] as int? ?? 0,
      title: json['title'] as String? ?? 'Beginner',
      levelName: json['name'] as String? ?? 'Level ${json['level']}',
      reward: reward,
      rewardIcon: json['milestone_icon'] as String?,
      isMilestone: reward != null,
    );
  }
}


/// All Levels Sheet — fetches level data from backend
class _AllLevelsSheet extends ConsumerWidget {
  final int currentLevel;
  final Color accentColor;

  const _AllLevelsSheet({
    required this.currentLevel,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textColorStrong = isDark ? textColor : Colors.black.withValues(alpha: 0.85);
    final textMutedStrong = isDark ? textMuted : Colors.black.withValues(alpha: 0.55);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.15);

    final allLevelsAsync = ref.watch(allLevelsProvider);

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
                            Text('Level $currentLevel • 249 levels total', style: TextStyle(fontSize: 12, color: textMutedStrong)),
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
                  child: allLevelsAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: textMutedStrong),
                            const SizedBox(height: 12),
                            Text(
                              'Failed to load levels',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColorStrong),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Check your connection and try again',
                              style: TextStyle(fontSize: 13, color: textMutedStrong),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            TextButton.icon(
                              onPressed: () => ref.invalidate(allLevelsProvider),
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (rawLevels) {
                      // Skip level 1 (starts at level 2) to match previous behavior
                      final levels = rawLevels
                          .where((l) => (l['level'] as int) >= 2)
                          .map((l) => _LevelInfo.fromJson(l))
                          .toList();

                      if (levels.isEmpty) {
                        return Center(
                          child: Text('No levels available', style: TextStyle(color: textMutedStrong)),
                        );
                      }

                      return ListView.builder(
                        controller: dragScrollController,
                        padding: EdgeInsets.fromLTRB(16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
                        itemCount: levels.length,
                        itemBuilder: (context, index) {
                          final level = levels[index];
                          return _buildLevelRow(level, level.level == currentLevel, level.level < currentLevel, textColorStrong, textMutedStrong, cardBg, borderColor, accentColor, isDark);
                        },
                      );
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

