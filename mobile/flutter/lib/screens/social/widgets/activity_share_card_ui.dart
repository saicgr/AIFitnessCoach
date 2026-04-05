part of 'activity_share_card.dart';

/// Methods extracted from ActivityShareCard
extension _ActivityShareCardExt on ActivityShareCard {

  // ═══════════════════════════════════════════════════════════════
  // TEMPLATE 1: Dark Minimal
  // ═══════════════════════════════════════════════════════════════
  Widget _buildDarkMinimal() {
    final accent = _accent;
    final isCompact = aspectRatio == ShareAspectRatio.square;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A0A14), Color(0xFF0F0F1A), Color(0xFF141420)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Radial glow behind icon
          Positioned(
            top: isCompact ? 10 : 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: isCompact ? 140 : 200,
                height: isCompact ? 140 : 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accent.withValues(alpha: 0.2),
                      accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isCompact ? 16 : 20,
            ),
            child: Column(
              children: [
                SizedBox(height: isCompact ? 8 : 24),
                _buildIconCircle(accent, isCompact ? 60 : 80),
                SizedBox(height: isCompact ? 12 : 20),
                _buildHeadlineText(accent, Colors.white),
                SizedBox(height: isCompact ? 8 : 16),
                if (!isCompact) Expanded(child: _buildContentCard(accent)),
                if (isCompact) _buildContentCard(accent),
                if (!isCompact) const Spacer(),
                _buildFooter(Colors.white),
                if (showWatermark) ...[
                  SizedBox(height: isCompact ? 4 : 8),
                  const AppWatermark(),
                ],
                SizedBox(height: isCompact ? 4 : 8),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════
  // TEMPLATE 3: Neon Glow
  // ═══════════════════════════════════════════════════════════════
  Widget _buildNeonGlow() {
    final accent = _accent;
    final isCompact = aspectRatio == ShareAspectRatio.square;
    final neonColor = accent;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF050510),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: neonColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Stack(
        children: [
          // Top glow
          Positioned(
            top: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      neonColor.withValues(alpha: 0.15),
                      neonColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Bottom glow
          Positioned(
            bottom: -40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 300,
                height: 120,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      neonColor.withValues(alpha: 0.1),
                      neonColor.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isCompact ? 16 : 24,
            ),
            child: Column(
              children: [
                SizedBox(height: isCompact ? 4 : 16),
                // Neon-bordered icon
                Container(
                  width: isCompact ? 60 : 80,
                  height: isCompact ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: neonColor,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonColor.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    _smartIcon,
                    color: neonColor,
                    size: isCompact ? 28 : 36,
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 16),
                // Neon headline
                _buildHeadlineText(neonColor, Colors.white, glow: true),
                SizedBox(height: isCompact ? 8 : 16),
                if (!isCompact)
                  Expanded(
                    child: _buildContentCard(neonColor, neonBorder: true),
                  ),
                if (isCompact) _buildContentCard(neonColor, neonBorder: true),
                if (!isCompact) const Spacer(),
                _buildFooter(Colors.white),
                if (showWatermark) ...[
                  SizedBox(height: isCompact ? 4 : 8),
                  const AppWatermark(),
                ],
                SizedBox(height: isCompact ? 4 : 8),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ═══════════════════════════════════════════════════════════════
  // TEMPLATE 5: Glass Morphism
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGlassMorphism() {
    final accent = _accent;
    final isCompact = aspectRatio == ShareAspectRatio.square;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A1A2E).withValues(alpha: 0.95),
            const Color(0xFF16213E).withValues(alpha: 0.95),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Floating glass circles
          Positioned(
            top: -30,
            right: -30,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.15),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -20,
            left: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    accent.withValues(alpha: 0.1),
                    accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: isCompact ? 16 : 24,
            ),
            child: Column(
              children: [
                SizedBox(height: isCompact ? 4 : 16),
                // Glass icon container
                Container(
                  width: isCompact ? 60 : 80,
                  height: isCompact ? 60 : 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    _smartIcon,
                    color: accent,
                    size: isCompact ? 28 : 36,
                  ),
                ),
                SizedBox(height: isCompact ? 10 : 16),
                _buildHeadlineText(accent, Colors.white),
                SizedBox(height: isCompact ? 8 : 16),
                // Glass content card
                if (!isCompact)
                  Expanded(
                    child: _buildContentCard(
                      accent,
                      glassBg: true,
                    ),
                  ),
                if (isCompact)
                  _buildContentCard(accent, glassBg: true),
                if (!isCompact) const Spacer(),
                _buildFooter(Colors.white),
                if (showWatermark) ...[
                  SizedBox(height: isCompact ? 4 : 8),
                  const AppWatermark(),
                ],
                SizedBox(height: isCompact ? 4 : 8),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildContentCard(
    Color accent, {
    bool lightBg = false,
    bool neonBorder = false,
    bool glassBg = false,
    Color? textColor,
    Color? cardBg,
  }) {
    switch (activityType) {
      case 'workout_completed':
        return _buildWorkoutCard(
          accent,
          lightBg: lightBg,
          neonBorder: neonBorder,
          glassBg: glassBg,
          textColor: textColor,
          cardBg: cardBg,
        );
      case 'personal_record':
        return _buildPRCard(
          accent,
          lightBg: lightBg,
          neonBorder: neonBorder,
          glassBg: glassBg,
          textColor: textColor,
          cardBg: cardBg,
        );
      case 'achievement_earned':
        return _buildAchievementCard(
          accent,
          textColor: textColor,
          cardBg: cardBg,
          glassBg: glassBg,
          neonBorder: neonBorder,
        );
      case 'streak_milestone':
        return _buildStreakCard(
          accent,
          textColor: textColor,
          cardBg: cardBg,
          glassBg: glassBg,
          neonBorder: neonBorder,
        );
      case 'weight_milestone':
        return _buildWeightCard(
          accent,
          textColor: textColor,
          cardBg: cardBg,
          glassBg: glassBg,
          neonBorder: neonBorder,
        );
      case 'challenge_victory':
        return _buildChallengeCard(
          accent,
          lightBg: lightBg,
          textColor: textColor,
          cardBg: cardBg,
          glassBg: glassBg,
          neonBorder: neonBorder,
        );
      case 'manual_post':
        return _buildManualPostCard(
          accent,
          textColor: textColor,
        );
      default:
        return _buildGenericCard(
          accent,
          textColor: textColor,
          cardBg: cardBg,
          glassBg: glassBg,
          neonBorder: neonBorder,
        );
    }
  }


  Widget _buildPRCard(
    Color accent, {
    bool lightBg = false,
    bool neonBorder = false,
    bool glassBg = false,
    Color? textColor,
    Color? cardBg,
  }) {
    final exercise = activityData['exercise_name'] ?? 'Exercise';
    final value = activityData['record_value'] ?? 0;
    final unit = activityData['record_unit'] ?? '';
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        lightBg: lightBg,
        neonBorder: neonBorder,
        glassBg: glassBg,
        cardBg: cardBg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            exercise.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: fgColor.withValues(alpha: 0.7),
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: accent,
                  height: 1,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    unit,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: fgColor.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildChallengeCard(
    Color accent, {
    bool lightBg = false,
    Color? textColor,
    Color? cardBg,
    bool glassBg = false,
    bool neonBorder = false,
  }) {
    final workoutName = activityData['workout_name'] ?? 'a workout';
    final challengerName = activityData['challenger_name'] ?? 'someone';
    final yourDuration = activityData['your_duration'];
    final theirDuration = activityData['their_duration'];
    final yourVolume = activityData['your_volume'];
    final theirVolume = activityData['their_volume'];
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        lightBg: lightBg,
        glassBg: glassBg,
        neonBorder: neonBorder,
        cardBg: cardBg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: TextStyle(
                fontSize: 14,
                color: fgColor.withValues(alpha: 0.7),
              ),
              children: [
                const TextSpan(text: 'beat '),
                TextSpan(
                  text: "$challengerName's",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: fgColor,
                  ),
                ),
                const TextSpan(text: ' '),
                TextSpan(
                  text: workoutName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: accent,
                  ),
                ),
              ],
            ),
          ),
          if (yourDuration != null && theirDuration != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompareColumn('You', '$yourDuration min', accent),
                Icon(Icons.arrow_forward,
                    size: 16, color: fgColor.withValues(alpha: 0.3)),
                _buildCompareColumn('Them', '$theirDuration min',
                    fgColor.withValues(alpha: 0.5)),
              ],
            ),
          ],
          if (yourVolume != null && theirVolume != null) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCompareColumn(
                    '', '${yourVolume.toStringAsFixed(0)} lbs', accent),
                const SizedBox(width: 16),
                _buildCompareColumn('',
                    '${theirVolume.toStringAsFixed(0)} lbs',
                    fgColor.withValues(alpha: 0.5)),
              ],
            ),
          ],
        ],
      ),
    );
  }

}
