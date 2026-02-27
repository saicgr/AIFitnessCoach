import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../workout/widgets/share_templates/app_watermark.dart';

/// Aspect ratio options for share cards
enum ShareAspectRatio {
  story, // 9:16
  square, // 1:1
  portrait, // 4:5
}

/// Visual template themes for share cards
enum ShareTemplate {
  darkMinimal,
  gradientBold,
  neonGlow,
  cleanLight,
  glassMorphism,
}

/// Activity Share Card for social feed posts
///
/// Supports 5 visual templates and 3 aspect ratios.
/// Adapts its visuals based on [activityType] and selected [template].
class ActivityShareCard extends StatelessWidget {
  final String userName;
  final String activityType;
  final Map<String, dynamic> activityData;
  final DateTime timestamp;
  final bool showWatermark;
  final ShareTemplate template;
  final ShareAspectRatio aspectRatio;
  final String? editedCaption;

  const ActivityShareCard({
    super.key,
    required this.userName,
    required this.activityType,
    required this.activityData,
    required this.timestamp,
    this.showWatermark = true,
    this.template = ShareTemplate.darkMinimal,
    this.aspectRatio = ShareAspectRatio.story,
    this.editedCaption,
  });

  // Activity type configurations
  static const _typeConfigs = <String, _ActivityTypeConfig>{
    'workout_completed': _ActivityTypeConfig(
      icon: Icons.fitness_center,
      accentColor: Color(0xFFF97316),
      defaultHeadline: 'WORKOUT COMPLETE',
    ),
    'personal_record': _ActivityTypeConfig(
      icon: Icons.emoji_events,
      accentColor: Color(0xFFFFD700),
      defaultHeadline: 'NEW PR!',
    ),
    'achievement_earned': _ActivityTypeConfig(
      icon: Icons.star_rounded,
      accentColor: Color(0xFF22C55E),
      defaultHeadline: 'ACHIEVEMENT UNLOCKED',
    ),
    'streak_milestone': _ActivityTypeConfig(
      icon: Icons.local_fire_department,
      accentColor: Color(0xFFF97316),
      defaultHeadline: 'STREAK',
    ),
    'weight_milestone': _ActivityTypeConfig(
      icon: Icons.monitor_weight,
      accentColor: Color(0xFFA855F7),
      defaultHeadline: 'WEIGHT MILESTONE',
    ),
    'challenge_victory': _ActivityTypeConfig(
      icon: Icons.emoji_events,
      accentColor: Color(0xFFFFD700),
      defaultHeadline: 'VICTORY!',
    ),
    'manual_post': _ActivityTypeConfig(
      icon: Icons.chat_bubble_rounded,
      accentColor: Color(0xFF3B82F6),
      defaultHeadline: '',
    ),
  };

  static const _defaultConfig = _ActivityTypeConfig(
    icon: Icons.flash_on,
    accentColor: Color(0xFFE0E0E0),
    defaultHeadline: 'UPDATE',
  );

  _ActivityTypeConfig get _config =>
      _typeConfigs[activityType] ?? _defaultConfig;

  String get _headline {
    if (editedCaption != null && editedCaption!.isNotEmpty) {
      if (activityType == 'manual_post') return editedCaption!;
    }
    switch (activityType) {
      case 'streak_milestone':
        final days = activityData['streak_days'] ?? 0;
        return '$days-DAY STREAK';
      case 'manual_post':
        final caption = editedCaption ??
            activityData['caption'] as String? ?? '';
        return caption.isNotEmpty ? caption : 'SHARED AN UPDATE';
      default:
        return _config.defaultHeadline;
    }
  }

  /// Smart icon resolution based on activity type + flair context
  IconData get _smartIcon {
    if (activityType == 'manual_post') {
      final flairs =
          (activityData['flairs'] as List<dynamic>?)?.cast<String>() ?? [];
      if (flairs.isNotEmpty) {
        return _getFlairIcon(flairs.first);
      }
      return Icons.chat_bubble_rounded;
    }
    return _config.icon;
  }

  /// Get accent color, potentially modified by template
  Color get _accent {
    if (template == ShareTemplate.cleanLight) {
      // Darken accent for light background
      return HSLColor.fromColor(_config.accentColor)
          .withLightness(0.4)
          .toColor();
    }
    return _config.accentColor;
  }

  Size _getCardSize() {
    switch (aspectRatio) {
      case ShareAspectRatio.story:
        return const Size(320, 568); // 9:16
      case ShareAspectRatio.square:
        return const Size(320, 320); // 1:1
      case ShareAspectRatio.portrait:
        return const Size(320, 400); // 4:5
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = _getCardSize();

    return SizedBox(
      width: size.width,
      height: size.height,
      child: _buildTemplate(),
    );
  }

  Widget _buildTemplate() {
    switch (template) {
      case ShareTemplate.darkMinimal:
        return _buildDarkMinimal();
      case ShareTemplate.gradientBold:
        return _buildGradientBold();
      case ShareTemplate.neonGlow:
        return _buildNeonGlow();
      case ShareTemplate.cleanLight:
        return _buildCleanLight();
      case ShareTemplate.glassMorphism:
        return _buildGlassMorphism();
    }
  }

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
  // TEMPLATE 2: Gradient Bold
  // ═══════════════════════════════════════════════════════════════
  Widget _buildGradientBold() {
    final isCompact = aspectRatio == ShareAspectRatio.square;

    // Pick gradient based on activity type
    final gradientColors = _getGradientBoldColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isCompact ? 16 : 24,
        ),
        child: Column(
          children: [
            SizedBox(height: isCompact ? 4 : 16),
            // Large icon with white circle
            Container(
              width: isCompact ? 56 : 72,
              height: isCompact ? 56 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Icon(
                _smartIcon,
                color: Colors.white,
                size: isCompact ? 28 : 36,
              ),
            ),
            SizedBox(height: isCompact ? 10 : 16),
            _buildHeadlineText(Colors.white, Colors.white, bold: true),
            SizedBox(height: isCompact ? 8 : 16),
            if (!isCompact)
              Expanded(child: _buildContentCard(Colors.white, lightBg: true)),
            if (isCompact) _buildContentCard(Colors.white, lightBg: true),
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
    );
  }

  List<Color> _getGradientBoldColors() {
    switch (activityType) {
      case 'workout_completed':
        return const [Color(0xFFF97316), Color(0xFFEA580C), Color(0xFFC2410C)];
      case 'personal_record':
      case 'challenge_victory':
        return const [Color(0xFFEAB308), Color(0xFFCA8A04), Color(0xFFA16207)];
      case 'achievement_earned':
        return const [Color(0xFF22C55E), Color(0xFF16A34A), Color(0xFF15803D)];
      case 'streak_milestone':
        return const [Color(0xFFEF4444), Color(0xFFDC2626), Color(0xFFB91C1C)];
      case 'weight_milestone':
        return const [Color(0xFFA855F7), Color(0xFF9333EA), Color(0xFF7E22CE)];
      case 'manual_post':
        return const [Color(0xFF3B82F6), Color(0xFF2563EB), Color(0xFF1D4ED8)];
      default:
        return const [Color(0xFF6366F1), Color(0xFF4F46E5), Color(0xFF4338CA)];
    }
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
  // TEMPLATE 4: Clean Light
  // ═══════════════════════════════════════════════════════════════
  Widget _buildCleanLight() {
    final accent = _accent;
    final isCompact = aspectRatio == ShareAspectRatio.square;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 24,
          vertical: isCompact ? 16 : 24,
        ),
        child: Column(
          children: [
            SizedBox(height: isCompact ? 4 : 16),
            // Simple colored circle icon
            Container(
              width: isCompact ? 56 : 72,
              height: isCompact ? 56 : 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accent.withValues(alpha: 0.12),
              ),
              child: Icon(
                _smartIcon,
                color: accent,
                size: isCompact ? 28 : 36,
              ),
            ),
            SizedBox(height: isCompact ? 10 : 16),
            _buildHeadlineText(
              accent,
              const Color(0xFF1A1A2E),
            ),
            SizedBox(height: isCompact ? 8 : 16),
            if (!isCompact)
              Expanded(
                child: _buildContentCard(
                  accent,
                  textColor: const Color(0xFF1A1A2E),
                  cardBg: Colors.white,
                ),
              ),
            if (isCompact)
              _buildContentCard(
                accent,
                textColor: const Color(0xFF1A1A2E),
                cardBg: Colors.white,
              ),
            if (!isCompact) const Spacer(),
            _buildFooter(const Color(0xFF1A1A2E)),
            if (showWatermark) ...[
              SizedBox(height: isCompact ? 4 : 8),
              const AppWatermark(
                backgroundColor: Color(0xFFE8E8E8),
              ),
            ],
            SizedBox(height: isCompact ? 4 : 8),
          ],
        ),
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

  // ═══════════════════════════════════════════════════════════════
  // SHARED BUILDING BLOCKS
  // ═══════════════════════════════════════════════════════════════

  Widget _buildIconCircle(Color accent, double size) {
    // For achievement_earned, show emoji instead of icon
    if (activityType == 'achievement_earned') {
      final emoji = activityData['achievement_icon'] as String? ?? '';
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [accent, accent.withValues(alpha: 0.7)],
          ),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Center(
          child: emoji.isNotEmpty
              ? Text(emoji, style: TextStyle(fontSize: size * 0.45))
              : Icon(_config.icon, color: Colors.white, size: size * 0.5),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.7)],
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.4),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Icon(_smartIcon, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildHeadlineText(
    Color accentColor,
    Color textColor, {
    bool bold = false,
    bool glow = false,
  }) {
    final isManualPost = activityType == 'manual_post';
    final isCompact = aspectRatio == ShareAspectRatio.square;

    if (isManualPost) {
      return Text(
        _headline,
        style: TextStyle(
          fontSize: isCompact ? 20 : 24,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 1.3,
          shadows: glow
              ? [
                  Shadow(
                    color: accentColor.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ]
              : null,
        ),
        textAlign: TextAlign.center,
        maxLines: isCompact ? 3 : 5,
        overflow: TextOverflow.ellipsis,
      );
    }

    return Text(
      _headline,
      style: TextStyle(
        fontSize: isCompact ? 18 : 22,
        fontWeight: bold ? FontWeight.w900 : FontWeight.bold,
        color: accentColor,
        letterSpacing: 2,
        shadows: glow
            ? [
                Shadow(
                  color: accentColor.withValues(alpha: 0.5),
                  blurRadius: 12,
                ),
              ]
            : null,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildFooter(Color textColor) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '@$userName',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          DateFormat('MMM d, yyyy').format(timestamp),
          style: TextStyle(
            fontSize: 12,
            color: textColor.withValues(alpha: 0.5),
          ),
        ),
      ],
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

  BoxDecoration _cardDecoration(
    Color accent, {
    bool lightBg = false,
    bool neonBorder = false,
    bool glassBg = false,
    Color? cardBg,
  }) {
    Color bg;
    if (cardBg != null) {
      bg = cardBg;
    } else if (glassBg) {
      bg = Colors.white.withValues(alpha: 0.08);
    } else if (lightBg) {
      bg = Colors.white.withValues(alpha: 0.15);
    } else {
      bg = Colors.white.withValues(alpha: 0.08);
    }

    return BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: neonBorder
            ? accent.withValues(alpha: 0.6)
            : accent.withValues(alpha: 0.3),
        width: neonBorder ? 1.5 : 1,
      ),
      boxShadow: neonBorder
          ? [
              BoxShadow(
                color: accent.withValues(alpha: 0.2),
                blurRadius: 8,
              ),
            ]
          : null,
    );
  }

  Widget _buildWorkoutCard(
    Color accent, {
    bool lightBg = false,
    bool neonBorder = false,
    bool glassBg = false,
    Color? textColor,
    Color? cardBg,
  }) {
    final workoutName = activityData['workout_name'] ?? 'Workout';
    final duration = activityData['duration_minutes'] ?? 0;
    final exercises = activityData['exercises_count'] ?? 0;
    final totalVolume = activityData['total_volume'];
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
            workoutName,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: fgColor,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatColumn('$duration', 'min', accent, textColor: fgColor),
              _buildStatDivider(fgColor),
              _buildStatColumn('$exercises', 'exercises', accent,
                  textColor: fgColor),
              if (totalVolume != null) ...[
                _buildStatDivider(fgColor),
                _buildStatColumn(
                  '${totalVolume.toStringAsFixed(0)}',
                  'lbs',
                  accent,
                  textColor: fgColor,
                ),
              ],
            ],
          ),
        ],
      ),
    );
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

  Widget _buildAchievementCard(
    Color accent, {
    Color? textColor,
    Color? cardBg,
    bool glassBg = false,
    bool neonBorder = false,
  }) {
    final name = activityData['achievement_name'] ?? 'Achievement';
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        glassBg: glassBg,
        neonBorder: neonBorder,
        cardBg: cardBg,
      ),
      child: Text(
        name,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: fgColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildStreakCard(
    Color accent, {
    Color? textColor,
    Color? cardBg,
    bool glassBg = false,
    bool neonBorder = false,
  }) {
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        glassBg: glassBg,
        neonBorder: neonBorder,
        cardBg: cardBg,
      ),
      child: Text(
        'Consistency is key',
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: fgColor.withValues(alpha: 0.8),
          fontStyle: FontStyle.italic,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildWeightCard(
    Color accent, {
    Color? textColor,
    Color? cardBg,
    bool glassBg = false,
    bool neonBorder = false,
  }) {
    final weightChange = activityData['weight_change'] ?? 0;
    final direction =
        (weightChange is num && weightChange < 0) ? 'lost' : 'gained';
    final absValue =
        (weightChange is num) ? weightChange.abs() : weightChange;
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        glassBg: glassBg,
        neonBorder: neonBorder,
        cardBg: cardBg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$direction ',
            style: TextStyle(
              fontSize: 18,
              color: fgColor.withValues(alpha: 0.7),
            ),
          ),
          Text(
            '$absValue lbs',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
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

  Widget _buildManualPostCard(Color accent, {Color? textColor}) {
    final flairs =
        (activityData['flairs'] as List<dynamic>?)?.cast<String>() ?? [];

    if (flairs.isEmpty) return const SizedBox.shrink();

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: flairs.map((flair) {
        final color = _getFlairColor(flair);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getFlairIcon(flair), size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                _getFlairLabel(flair),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGenericCard(
    Color accent, {
    Color? textColor,
    Color? cardBg,
    bool glassBg = false,
    bool neonBorder = false,
  }) {
    final caption = editedCaption ??
        activityData['caption'] as String?;
    final fgColor = textColor ?? Colors.white;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(
        accent,
        glassBg: glassBg,
        neonBorder: neonBorder,
        cardBg: cardBg,
      ),
      child: Text(
        caption ?? 'Shared an update',
        style: TextStyle(
          fontSize: 16,
          color: fgColor,
        ),
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  // --- Helpers ---

  Widget _buildStatColumn(String value, String label, Color accent,
      {Color? textColor}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: (textColor ?? Colors.white).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(Color textColor) {
    return Container(
      width: 1,
      height: 32,
      color: textColor.withValues(alpha: 0.1),
    );
  }

  Widget _buildCompareColumn(String label, String value, Color color) {
    return Column(
      children: [
        if (label.isNotEmpty)
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Flair helpers (mirrored from activity_card.dart)
  Color _getFlairColor(String flair) {
    switch (flair) {
      case 'fitness':
        return const Color(0xFF06B6D4);
      case 'progress':
        return const Color(0xFF22C55E);
      case 'milestone':
        return const Color(0xFFF97316);
      case 'nutrition':
        return const Color(0xFFA855F7);
      case 'motivation':
        return const Color(0xFFEAB308);
      case 'question':
        return const Color(0xFF3B82F6);
      default:
        return const Color(0xFF06B6D4);
    }
  }

  IconData _getFlairIcon(String flair) {
    switch (flair) {
      case 'fitness':
        return Icons.fitness_center_rounded;
      case 'progress':
        return Icons.trending_up_rounded;
      case 'milestone':
        return Icons.emoji_events_rounded;
      case 'nutrition':
        return Icons.restaurant_rounded;
      case 'motivation':
        return Icons.bolt_rounded;
      case 'question':
        return Icons.help_outline_rounded;
      default:
        return Icons.tag_rounded;
    }
  }

  String _getFlairLabel(String flair) {
    switch (flair) {
      case 'fitness':
        return 'Fitness';
      case 'progress':
        return 'Progress';
      case 'milestone':
        return 'Milestone';
      case 'nutrition':
        return 'Nutrition';
      case 'motivation':
        return 'Motivation';
      case 'question':
        return 'Question';
      default:
        return flair.isNotEmpty
            ? flair[0].toUpperCase() + flair.substring(1)
            : flair;
    }
  }
}

/// Internal config for activity type visuals
class _ActivityTypeConfig {
  final IconData icon;
  final Color accentColor;
  final String defaultHeadline;

  const _ActivityTypeConfig({
    required this.icon,
    required this.accentColor,
    required this.defaultHeadline,
  });
}
