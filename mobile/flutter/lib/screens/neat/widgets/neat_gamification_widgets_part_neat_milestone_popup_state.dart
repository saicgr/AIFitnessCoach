part of 'neat_gamification_widgets.dart';


class _NeatMilestonePopupState extends State<NeatMilestonePopup>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _confettiController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  final List<_ConfettiParticle> _particles = [];
  final math.Random _random = math.Random();

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
        swayPhase: _random.nextDouble() * 2 * math.pi,
      ));
    }
  }

  void _updateParticles() {
    setState(() {
      for (var particle in _particles) {
        particle.y += particle.velocity * 0.02;
        particle.x +=
            math.sin(particle.swayPhase + _confettiController.value * 10) *
                particle.swayAmplitude;
        particle.rotation += particle.rotationSpeed;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = widget.newLevel?.color ?? AppColors.cyan;
    final emoji = widget.achievementEmoji ?? widget.newLevel?.emoji ?? '\u{1F389}';

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
                  if (widget.newLevel != null)
                    Text(
                      AppLocalizations.of(context)!.neatGamificationWidgetsLevelUp,
                      style: ZType.lbl(16, color: AppColors.yellow, letterSpacing: 4),
                    )
                  else
                    Text(
                      AppLocalizations.of(context)!.neatGamificationWidgetsAchievementUnlocked,
                      style: ZType.lbl(16, color: accentColor, letterSpacing: 4),
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
                                color: accentColor.withOpacity(0.4),
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
                                accentColor.withOpacity(0.3),
                                accentColor.withOpacity(0.1),
                              ],
                            ),
                            border: Border.all(
                              color: accentColor,
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 64),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Title
                  Text(
                    widget.title,
                    style: ZType.disp(30, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      widget.description,
                      textAlign: TextAlign.center,
                      style: ZType.ser(16, color: Colors.white.withOpacity(0.8)),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // XP earned badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.yellow),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          '\u{2B50}', // Star
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '+${widget.xpEarned} XP',
                          style: ZType.data(16, color: AppColors.yellow),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Buttons
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      children: [
                        if (widget.onShare != null) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ShareButton(
                                icon: Icons.share,
                                label: AppLocalizations.of(context)!.commonShare,
                                onTap: widget.onShare!,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticService.light();
                              widget.onDismiss();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              AppLocalizations.of(context)!.buttonContinue,
                              style: ZType.lbl(16, color: Colors.white,
                                  weight: FontWeight.w800, letterSpacing: 1.5),
                            ),
                          ),
                        ),
                      ],
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
}


/// Compact NEAT Stats Card - shows key NEAT metrics in a compact format.
///
/// Useful for home screen or dashboard display.
class CompactNeatStatsCard extends StatelessWidget {
  final int todaySteps;
  final int stepGoal;
  final int neatScore;
  final int activeHours;
  final int targetActiveHours;
  final VoidCallback? onTap;

  const CompactNeatStatsCard({
    super.key,
    required this.todaySteps,
    required this.stepGoal,
    required this.neatScore,
    required this.activeHours,
    this.targetActiveHours = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final tc = ThemeColors.of(context);
    final stepProgress = (todaySteps / stepGoal).clamp(0.0, 1.0);
    final activeProgress = (activeHours / targetActiveHours).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        if (onTap != null) {
          HapticService.light();
          onTap!();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tc.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            // Steps progress
            Expanded(
              child: _CompactStatItem(
                icon: '\u{1F6B6}', // Walking person
                label: l10n.neatGamificationWidgetsSteps,
                value: '$todaySteps',
                subValue: l10n.neatGamificationWidgetsStepGoal(stepGoal),
                progress: stepProgress,
                progressColor: AppColors.cyan,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: tc.cardBorder,
            ),
            // Active hours
            Expanded(
              child: _CompactStatItem(
                icon: '\u{23F0}', // Alarm clock
                label: l10n.neatGamificationWidgetsActive,
                value: '$activeHours',
                subValue: l10n.neatGamificationWidgetsTargetActiveHours(targetActiveHours),
                progress: activeProgress,
                progressColor: AppColors.teal,
              ),
            ),
            Container(
              height: 40,
              width: 1,
              color: tc.cardBorder,
            ),
            // NEAT score
            Expanded(
              child: _CompactStatItem(
                icon: '\u{26A1}', // Lightning
                label: l10n.neatGamificationWidgetsNeat,
                value: '$neatScore',
                subValue: l10n.neatGamificationWidgetsScore,
                progress: (neatScore / 100).clamp(0.0, 1.0),
                progressColor: AppColors.orange,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms);
  }
}

