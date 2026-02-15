/// PR Full Celebration Screen
///
/// Full-screen celebration overlay for epic PRs (10%+ improvement).
/// Shows confetti, animations, and share option.
library;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/animations/celebration_animations.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/pr_detection_service.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';
import 'share_templates/pr_share_card.dart';

/// Show full screen PR celebration
Future<void> showPRFullCelebration({
  required BuildContext context,
  required DetectedPR pr,
  required String workoutName,
  List<Map<String, dynamic>>? progressData,
}) {
  // Trigger epic haptic pattern
  HapticService.multiPrAchievement();

  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withOpacity(0.9),
    transitionDuration: const Duration(milliseconds: 400),
    pageBuilder: (context, animation, secondaryAnimation) {
      return PRFullCelebrationScreen(
        pr: pr,
        workoutName: workoutName,
        progressData: progressData,
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

class PRFullCelebrationScreen extends StatefulWidget {
  final DetectedPR pr;
  final String workoutName;
  final List<Map<String, dynamic>>? progressData;

  const PRFullCelebrationScreen({
    super.key,
    required this.pr,
    required this.workoutName,
    this.progressData,
  });

  @override
  State<PRFullCelebrationScreen> createState() => _PRFullCelebrationScreenState();
}

class _PRFullCelebrationScreenState extends State<PRFullCelebrationScreen>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  bool _showContent = false;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    // Start animations after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        _scaleController.forward();
        setState(() => _showContent = true);
      }
    });

    // Stop confetti after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() => _showConfetti = false);
      }
    });
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Confetti layer
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlay(
                particleCount: 150,
                duration: const Duration(milliseconds: 3000),
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
                    const Color(0xFFFFD700).withOpacity(0.2),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Trophy with glow
                if (_showContent)
                  _buildTrophyIcon()
                      .animate()
                      .scale(
                        begin: const Offset(0, 0),
                        end: const Offset(1, 1),
                        duration: 500.ms,
                        curve: Curves.elasticOut,
                      ),

                const SizedBox(height: 32),

                // Title
                if (_showContent)
                  Text(
                    'NEW PERSONAL RECORD!',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFD700),
                      letterSpacing: 2,
                    ),
                    textAlign: TextAlign.center,
                  )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.3, end: 0),

                const SizedBox(height: 48),

                // PR details card
                if (_showContent)
                  _buildPRCard()
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0),

                const Spacer(),

                // Action buttons
                if (_showContent)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // Share button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showShareSheet,
                            icon: const Icon(Icons.share),
                            label: const Text('Share Your Achievement'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 600.ms, duration: 400.ms)
                            .slideY(begin: 0.2, end: 0),

                        const SizedBox(height: 12),

                        // Continue button
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Continue Workout',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                        )
                            .animate()
                            .fadeIn(delay: 700.ms, duration: 400.ms),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyIcon() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        final scale = 1.0 + (_pulseController.value * 0.05);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFD700),
                  Color(0xFFFFA500),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  blurRadius: 40,
                  spreadRadius: 10,
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
    );
  }

  Widget _buildPRCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Exercise name
          Text(
            widget.pr.exerciseName.toUpperCase(),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Main value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.pr.formattedValue.split(' ').first,
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFD700),
                  height: 1,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  widget.pr.formattedValue.split(' ').last,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Reps
          Text(
            '${widget.pr.reps} reps',
            style: const TextStyle(
              fontSize: 18,
              color: Colors.white70,
            ),
          ),

          if (widget.pr.previousValue != null) ...[
            const SizedBox(height: 16),

            // Improvement badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.trending_up,
                    color: AppColors.success,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.pr.formattedImprovement,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(+${widget.pr.improvementPercent.toStringAsFixed(1)}%)',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.success.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showShareSheet() {
    HapticService.selection();
    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: PRShareSheet(
          pr: widget.pr,
          workoutName: widget.workoutName,
          progressData: widget.progressData,
        ),
      ),
    );
  }
}

/// Multiple PRs celebration screen
class MultiPRCelebrationScreen extends StatefulWidget {
  final List<DetectedPR> prs;
  final String workoutName;

  const MultiPRCelebrationScreen({
    super.key,
    required this.prs,
    required this.workoutName,
  });

  @override
  State<MultiPRCelebrationScreen> createState() => _MultiPRCelebrationScreenState();
}

class _MultiPRCelebrationScreenState extends State<MultiPRCelebrationScreen> {
  int _currentPRIndex = 0;
  bool _showConfetti = true;

  @override
  void initState() {
    super.initState();
    HapticService.multiPrAchievement();

    // Stop confetti after 3 seconds
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _showConfetti = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPR = widget.prs[_currentPRIndex];

    return Material(
      color: Colors.black.withOpacity(0.95),
      child: Stack(
        children: [
          // Confetti
          if (_showConfetti)
            Positioned.fill(
              child: ConfettiOverlay(
                particleCount: 200,
                duration: const Duration(milliseconds: 3000),
              ),
            ),

          // Gradient background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFFFF6B6B).withOpacity(0.2),
                    const Color(0xFFFFD93D).withOpacity(0.1),
                    Colors.black.withOpacity(0.95),
                  ],
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white54,
                        size: 28,
                      ),
                    ),
                  ),
                ),

                const Spacer(),

                // Fire icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFFF6B6B),
                        Color(0xFFFFD93D),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD93D).withOpacity(0.5),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 60,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.1, 1.1),
                      duration: 500.ms,
                    ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'YOU\'RE ON FIRE!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFD93D),
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  '${widget.prs.length} Personal Records!',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                  ),
                ),

                const SizedBox(height: 32),

                // PR carousel indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(widget.prs.length, (index) {
                    final isActive = index == _currentPRIndex;
                    return GestureDetector(
                      onTap: () => setState(() => _currentPRIndex = index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 32 : 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFFD93D)
                              : Colors.white.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // PR card
                _buildPRCard(currentPR),

                const Spacer(),

                // Continue button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD93D),
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPRCard(DetectedPR pr) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD93D).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // PR type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD93D).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              pr.type.displayName.toUpperCase(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFD93D),
                letterSpacing: 1,
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Exercise name
          Text(
            pr.exerciseName,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Value
          Text(
            pr.formattedValue,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFD93D),
            ),
          ),

          if (pr.previousValue != null) ...[
            const SizedBox(height: 8),
            Text(
              pr.formattedImprovement,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    )
        .animate(
          key: ValueKey(_currentPRIndex),
        )
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.1, end: 0);
  }
}
