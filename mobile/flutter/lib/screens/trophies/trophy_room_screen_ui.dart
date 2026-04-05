part of 'trophy_room_screen.dart';

/// UI builder methods extracted from _TrophyRoomScreenState
extension _TrophyRoomScreenStateUI on _TrophyRoomScreenState {

  Widget _buildHeader(
    UserXP? userXp,
    TrophyRoomSummary? summary,
    bool isDark,
    Color textColor,
    Color textMuted,
    Color accentColor,
    Color elevatedColor,
    Color cardBorder,
  ) {
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final currentLevel = userXp?.currentLevel ?? 1;
    final progressFraction = userXp?.progressFraction ?? 0.0;
    final xpTitle = userXp?.xpTitle ?? XPTitle.novice;
    final titleColor = Color(xpTitle.colorValue);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            isDark ? AppColors.elevated : AppColorsLight.elevated,
            isDark ? AppColors.background : AppColorsLight.background,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                size: 28,
                color: accentColor,
              ),
              const SizedBox(width: 12),
              Text(
                'Trophy Room',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // XP Progress Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: glassSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder),
            ),
            child: Row(
              children: [
                // Circular progress with level
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SimpleCircularProgressBar(
                      size: 64,
                      progressStrokeWidth: 5,
                      backStrokeWidth: 4,
                      valueNotifier: ValueNotifier(progressFraction * 100),
                      progressColors: [
                        accentColor.withValues(alpha: 0.7),
                        accentColor,
                        accentColor.withValues(alpha: 0.9),
                      ],
                      backColor: textMuted.withValues(alpha: 0.15),
                      mergeMode: true,
                      animationDuration: 1,
                      startAngle: -90,
                    ),
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            titleColor,
                            titleColor.withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: titleColor.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          currentLevel.toString(),
                          style: TextStyle(
                            fontSize: currentLevel >= 100 ? 14 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(width: 16),

                // Level info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Level ${userXp?.currentLevel ?? 1}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: titleColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: titleColor.withValues(alpha: 0.4),
                              ),
                            ),
                            child: Text(
                              xpTitle.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: titleColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progressFraction,
                          minHeight: 8,
                          backgroundColor: textMuted.withValues(alpha: 0.15),
                          valueColor: AlwaysStoppedAnimation(accentColor),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${userXp?.xpInCurrentLevel ?? 0} / ${userXp?.xpToNextLevel ?? 50} XP',
                        style: TextStyle(
                          fontSize: 11,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
