import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_circular_progress_bar/simple_circular_progress_bar.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/accent_color_provider.dart';
import '../data/models/user_xp.dart';
import '../data/providers/xp_provider.dart';
import '../data/services/haptic_service.dart';
import 'xp_goals_sheet.dart';

/// Animated XP level bar showing:
/// Lvl X ----[animated fill bar]---- Lvl X+1
///              123/250 XP
class XPLevelBar extends ConsumerStatefulWidget {
  final bool showLabels;
  final bool compact;
  final VoidCallback? onTap;

  const XPLevelBar({
    super.key,
    this.showLabels = true,
    this.compact = false,
    this.onTap,
  });

  @override
  ConsumerState<XPLevelBar> createState() => _XPLevelBarState();
}

class _XPLevelBarState extends ConsumerState<XPLevelBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _previousProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _updateAnimation(double newProgress) {
    if (newProgress != _previousProgress) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress,
        end: newProgress,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );
      _animationController.forward(from: 0);
      _previousProgress = newProgress;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;

    // Get dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final xpState = ref.watch(xpProvider);
    final userXp = xpState.userXp;
    final isLoading = xpState.isLoading;

    if (isLoading || userXp == null) {
      return _buildLoadingState(bgColor, textSecondary, accentColor);
    }

    // Trigger animation when progress changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateAnimation(userXp.progressFraction);
    });

    final xpTitle = userXp.xpTitle;
    final levelColor = Color(xpTitle.colorValue);

    return GestureDetector(
      onTap: widget.onTap ?? () {
        HapticService.light();
        showXPGoalsSheet(context, ref);
      },
      child: Container(
        padding: EdgeInsets.all(widget.compact ? 12 : 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Level indicators with progress bar
            Row(
              children: [
                // Current Level Badge
                _buildLevelBadge(
                  userXp.currentLevel,
                  levelColor,
                  isCurrentLevel: true,
                  compact: widget.compact,
                ),

                const SizedBox(width: 12),

                // Animated Progress Bar
                Expanded(
                  child: _buildAnimatedProgressBar(
                    userXp,
                    levelColor,
                    accentColor,
                    textSecondary,
                  ),
                ),

                const SizedBox(width: 12),

                // Next Level Badge
                _buildLevelBadge(
                  userXp.currentLevel + 1,
                  levelColor.withValues(alpha: 0.4),
                  isCurrentLevel: false,
                  compact: widget.compact,
                ),
              ],
            ),

            if (widget.showLabels) ...[
              SizedBox(height: widget.compact ? 8 : 12),
              // XP text and title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // XP Progress text
                  Text(
                    '${userXp.xpInCurrentLevel} / ${userXp.xpToNextLevel} XP',
                    style: TextStyle(
                      fontSize: widget.compact ? 12 : 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  // Title badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: levelColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: levelColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      xpTitle.displayName,
                      style: TextStyle(
                        fontSize: widget.compact ? 10 : 11,
                        fontWeight: FontWeight.w600,
                        color: levelColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge(
    int level,
    Color color, {
    required bool isCurrentLevel,
    required bool compact,
  }) {
    final size = compact ? 36.0 : 44.0;
    final fontSize = compact ? 14.0 : 16.0;
    final labelSize = compact ? 9.0 : 10.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: isCurrentLevel
                ? LinearGradient(
                    colors: [
                      color,
                      color.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isCurrentLevel ? null : color.withValues(alpha: 0.2),
            border: isCurrentLevel
                ? null
                : Border.all(
                    color: color.withValues(alpha: 0.4),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside,
                  ),
            boxShadow: isCurrentLevel
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              level.toString(),
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: isCurrentLevel ? Colors.white : color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          isCurrentLevel ? 'Lvl' : 'Next',
          style: TextStyle(
            fontSize: labelSize,
            color: isCurrentLevel
                ? color
                : color.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedProgressBar(
    UserXP userXp,
    Color levelColor,
    Color accentColor,
    Color textSecondary,
  ) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, _) {
        final progress = _progressAnimation.value.clamp(0.0, 1.0);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress bar
            Stack(
              children: [
                // Background track
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                // Animated fill
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    height: 12,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: LinearGradient(
                        colors: [
                          levelColor,
                          levelColor.withValues(alpha: 0.8),
                          accentColor,
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: levelColor.withValues(alpha: 0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                // Shine effect overlay
                if (progress > 0)
                  Positioned.fill(
                    child: FractionallySizedBox(
                      widthFactor: progress,
                      alignment: Alignment.centerLeft,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.0),
                              Colors.white.withValues(alpha: 0.2),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                            stops: const [0.0, 0.5, 1.0],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            // Percentage indicator
            Text(
              '${userXp.progressPercent}%',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: levelColor,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingState(Color bgColor, Color textSecondary, Color accentColor) {
    return Container(
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          // Loading level badge
          Container(
            width: widget.compact ? 36 : 44,
            height: widget.compact ? 36 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textSecondary.withValues(alpha: 0.2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: textSecondary.withValues(alpha: 0.15),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 10,
                  width: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: textSecondary.withValues(alpha: 0.1),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: widget.compact ? 36 : 44,
            height: widget.compact ? 36 : 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: textSecondary.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact circular XP indicator for headers - space-efficient animated design
class XPLevelBarCompact extends ConsumerWidget {
  final VoidCallback? onTap;

  const XPLevelBarCompact({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    // Use dynamic accent color
    final accentEnum = ref.watch(accentColorProvider);
    final accentColor = accentEnum.getColor(isDark);

    final xpState = ref.watch(xpProvider);
    final userXp = xpState.userXp;

    // Show placeholder/default state when XP data is loading
    final currentLevel = userXp?.currentLevel ?? 1;
    final progressFraction = userXp?.progressFraction ?? 0.0;
    final progressPercent = (progressFraction * 100).round();

    return GestureDetector(
      onTap: onTap ?? () {
        HapticService.light();
        showXPGoalsSheet(context, ref);
      },
      child: SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress bar
            SimpleCircularProgressBar(
              size: 44,
              progressStrokeWidth: 4,
              backStrokeWidth: 3,
              valueNotifier: ValueNotifier(progressFraction * 100),
              progressColors: [
                accentColor.withValues(alpha: 0.7),
                accentColor,
                accentColor.withValues(alpha: 0.9),
              ],
              backColor: textSecondary.withValues(alpha: 0.15),
              mergeMode: true,
              animationDuration: 1,
              startAngle: -90,
            ),
            // Center content - Level number
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accentColor.withValues(alpha: 0.15),
                    accentColor.withValues(alpha: 0.05),
                  ],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentLevel.toString(),
                      style: TextStyle(
                        fontSize: currentLevel >= 100 ? 10 : 13,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        height: 1.0,
                      ),
                    ),
                    Text(
                      '$progressPercent%',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
