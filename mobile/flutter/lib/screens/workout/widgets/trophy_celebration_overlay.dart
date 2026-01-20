/// Trophy Celebration Overlay
///
/// Full-screen celebration overlay shown when trophies are earned after workout completion.
/// Features confetti, trophy animation, and summary of achievements.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/animations/celebration_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/haptic_service.dart';

/// Show full-screen trophy celebration overlay
Future<void> showTrophyCelebration({
  required BuildContext context,
  required List<Map<String, dynamic>> newPRs,
  List<Map<String, dynamic>>? newAchievements,
  int? workoutMilestone,
  int? currentStreak,
}) {
  // Trigger epic haptic pattern
  HapticService.multiPrAchievement();

  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.9),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return TrophyCelebrationOverlay(
        newPRs: newPRs,
        newAchievements: newAchievements,
        workoutMilestone: workoutMilestone,
        currentStreak: currentStreak,
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
          ),
          child: child,
        ),
      );
    },
  );
}

class TrophyCelebrationOverlay extends StatefulWidget {
  final List<Map<String, dynamic>> newPRs;
  final List<Map<String, dynamic>>? newAchievements;
  final int? workoutMilestone;
  final int? currentStreak;

  const TrophyCelebrationOverlay({
    super.key,
    required this.newPRs,
    this.newAchievements,
    this.workoutMilestone,
    this.currentStreak,
  });

  @override
  State<TrophyCelebrationOverlay> createState() =>
      _TrophyCelebrationOverlayState();
}

class _TrophyCelebrationOverlayState extends State<TrophyCelebrationOverlay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _showContent = false;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Start content animation after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _showContent = true);
      }
    });

    // Stop confetti after 4 seconds
    Future.delayed(const Duration(milliseconds: 4000), () {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });

    // Auto-dismiss after 5 seconds
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  int get _totalTrophies {
    int count = widget.newPRs.length;
    count += widget.newAchievements?.length ?? 0;
    if (widget.workoutMilestone != null) count++;
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Stack(
          children: [
            // Confetti layer
            if (_showConfetti)
              Positioned.fill(
                child: ConfettiOverlay(
                  particleCount: 200,
                  duration: const Duration(milliseconds: 4000),
                ),
              ),

            // Background gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      AppColors.orange.withValues(alpha: 0.3),
                      AppColors.purple.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Close hint at top
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Tap anywhere to continue',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 1500.ms, duration: 500.ms),

                  const Spacer(),

                  // Trophy icon with glow
                  if (_showContent) _buildTrophyIcon(),

                  const SizedBox(height: 32),

                  // Title
                  if (_showContent)
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppColors.orange, AppColors.purple],
                      ).createShader(bounds),
                      child: const Text(
                        'TROPHIES EARNED!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.3, end: 0)
                        .then()
                        .shimmer(
                          delay: 500.ms,
                          duration: 1500.ms,
                          color: Colors.white.withValues(alpha: 0.3),
                        ),

                  const SizedBox(height: 48),

                  // Trophy summary cards
                  if (_showContent) _buildTrophySummary(),

                  const Spacer(),

                  // Total count badge
                  if (_showContent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.orange.withValues(alpha: 0.3),
                            AppColors.purple.withValues(alpha: 0.3),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: AppColors.orange.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        '$_totalTrophies ${_totalTrophies == 1 ? 'Trophy' : 'Trophies'} Unlocked!',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 800.ms, duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),

                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.orange,
                  AppColors.purple,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.orange.withValues(alpha: 0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
                BoxShadow(
                  color: AppColors.purple.withValues(alpha: 0.4),
                  blurRadius: 60,
                  spreadRadius: 20,
                ),
              ],
            ),
            child: const Icon(
              Icons.emoji_events,
              color: Colors.white,
              size: 80,
            ),
          ),
        );
      },
    )
        .animate()
        .scale(
          begin: const Offset(0, 0),
          end: const Offset(1, 1),
          duration: 600.ms,
          curve: Curves.elasticOut,
        );
  }

  Widget _buildTrophySummary() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          // PRs
          if (widget.newPRs.isNotEmpty)
            _buildTrophyRow(
              icon: Icons.military_tech,
              iconColor: const Color(0xFFFFD700), // Gold
              label: '${widget.newPRs.length} Personal ${widget.newPRs.length == 1 ? 'Record' : 'Records'}',
              subtitle: widget.newPRs.take(2).map((pr) => pr['exercise_name'] ?? 'Exercise').join(', '),
              delay: 300,
            ),

          // Achievements
          if (widget.newAchievements != null && widget.newAchievements!.isNotEmpty)
            _buildTrophyRow(
              icon: Icons.workspace_premium,
              iconColor: AppColors.purple,
              label: '${widget.newAchievements!.length} ${widget.newAchievements!.length == 1 ? 'Achievement' : 'Achievements'}',
              subtitle: widget.newAchievements!.take(2).map((a) => a['name'] ?? 'Achievement').join(', '),
              delay: 450,
            ),

          // Milestone
          if (widget.workoutMilestone != null)
            _buildTrophyRow(
              icon: Icons.flag,
              iconColor: AppColors.orange,
              label: 'Milestone Reached!',
              subtitle: '${widget.workoutMilestone} Workouts Completed',
              delay: 600,
            ),

          // Streak
          if (widget.currentStreak != null && widget.currentStreak! >= 3)
            _buildTrophyRow(
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF6B35),
              label: '${widget.currentStreak} Day Streak!',
              subtitle: 'Keep the momentum going',
              delay: 750,
            ),
        ],
      ),
    );
  }

  Widget _buildTrophyRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required int delay,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
