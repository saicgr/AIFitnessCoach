import 'dart:math';
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/milestone.dart';
import '../../../data/services/haptic_service.dart';

/// Full-screen celebration dialog for newly achieved milestones.
/// Shows confetti animation and allows sharing to social platforms.
class MilestoneCelebrationDialog extends StatefulWidget {
  final UserMilestone milestone;
  final VoidCallback onCelebrated;
  final Function(String platform) onShare;

  const MilestoneCelebrationDialog({
    super.key,
    required this.milestone,
    required this.onCelebrated,
    required this.onShare,
  });

  @override
  State<MilestoneCelebrationDialog> createState() =>
      _MilestoneCelebrationDialogState();
}

class _MilestoneCelebrationDialogState extends State<MilestoneCelebrationDialog>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<_ConfettiParticle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Badge scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeIn,
    );

    // Confetti animation
    _confettiController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..addListener(() {
        _updateParticles();
      });

    // Start animations
    _scaleController.forward();
    _generateConfetti();
    _confettiController.forward();

    // Haptic feedback
    HapticService.success();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _generateConfetti() {
    _particles.clear();
    final colors = [
      AppColors.purple,
      AppColors.cyan,
      AppColors.orange,
      AppColors.yellow,
      AppColors.coral,
      AppColors.green,
    ];

    for (int i = 0; i < 100; i++) {
      _particles.add(_ConfettiParticle(
        x: _random.nextDouble(),
        y: -0.1 - _random.nextDouble() * 0.3,
        size: 4 + _random.nextDouble() * 8,
        color: colors[_random.nextInt(colors.length)],
        velocity: 0.3 + _random.nextDouble() * 0.4,
        rotation: _random.nextDouble() * 360,
        rotationSpeed: _random.nextDouble() * 5 - 2.5,
        swayAmplitude: 0.02 + _random.nextDouble() * 0.04,
        swayPhase: _random.nextDouble() * 2 * pi,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.y += particle.velocity * 0.02;
        particle.x += sin(particle.swayPhase + _confettiController.value * 10) *
            particle.swayAmplitude;
        particle.rotation += particle.rotationSpeed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final milestone = widget.milestone.milestone!;
    final tier = milestone.tier;
    final tierColor = Color(tier.colorValue);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Dark overlay
          Container(
            color: Colors.black.withOpacity(0.85),
          ),

          // Confetti
          CustomPaint(
            painter: _ConfettiPainter(_particles),
            size: Size.infinite,
          ),

          // Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Celebration text
                  Text(
                    'MILESTONE ACHIEVED!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.yellow,
                      letterSpacing: 4,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Badge with glow
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Glow effect
                        Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: tierColor.withOpacity(0.4),
                                blurRadius: 60,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                        // Badge
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                tierColor.withOpacity(0.3),
                                tierColor.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: tierColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getIconEmoji(milestone.icon ?? 'trophy'),
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Milestone name
                  Text(
                    milestone.name,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Description
                  if (milestone.description != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        milestone.description!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Tier and points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: tierColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: tierColor),
                        ),
                        child: Text(
                          tier.displayName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: tierColor,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.yellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.yellow),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.stars,
                              size: 16,
                              color: AppColors.yellow,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '+${milestone.points} PTS',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.yellow,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Share buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        Text(
                          'Share your achievement',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _ShareButton(
                              icon: Icons.copy,
                              label: 'Copy',
                              onTap: () {
                                HapticService.light();
                                widget.onShare('copy');
                              },
                            ),
                            const SizedBox(width: 16),
                            _ShareButton(
                              icon: Icons.share,
                              label: 'Share',
                              onTap: () {
                                HapticService.light();
                                widget.onShare('share');
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          HapticService.light();
                          widget.onCelebrated();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: tierColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
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

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getIconEmoji(String iconName) {
    final iconMap = {
      'trophy': '\u{1F3C6}',
      'fire': '\u{1F525}',
      'muscle': '\u{1F4AA}',
      'star': '\u{2B50}',
      'flame': '\u{1F525}',
      'crown': '\u{1F451}',
      'diamond': '\u{1F48E}',
      'calendar': '\u{1F4C5}',
      'medal': '\u{1F3C5}',
      'target': '\u{1F3AF}',
      'clock': '\u{23F0}',
      'hourglass': '\u{23F3}',
      'dumbbell': '\u{1F3CB}',
      'scale': '\u{2696}',
    };
    return iconMap[iconName] ?? '\u{1F3C6}';
  }
}

/// Share button widget
class _ShareButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ShareButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Confetti particle data
class _ConfettiParticle {
  double x;
  double y;
  final double size;
  final Color color;
  final double velocity;
  double rotation;
  final double rotationSpeed;
  final double swayAmplitude;
  final double swayPhase;

  _ConfettiParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.velocity,
    required this.rotation,
    required this.rotationSpeed,
    required this.swayAmplitude,
    required this.swayPhase,
  });
}

/// Custom painter for confetti animation
class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;

  _ConfettiPainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      if (particle.y > 1.2) continue;

      final paint = Paint()
        ..color = particle.color
        ..style = PaintingStyle.fill;

      canvas.save();
      canvas.translate(
        particle.x * size.width,
        particle.y * size.height,
      );
      canvas.rotate(particle.rotation * pi / 180);

      // Draw rectangle confetti
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset.zero,
          width: particle.size,
          height: particle.size * 0.6,
        ),
        paint,
      );

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
