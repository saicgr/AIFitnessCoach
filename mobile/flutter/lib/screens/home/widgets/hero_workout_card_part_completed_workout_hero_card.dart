part of 'hero_workout_card.dart';


/// Card shown when today's workout is already completed
/// Shows completion status and the next scheduled workout
class CompletedWorkoutHeroCard extends ConsumerWidget {
  final Workout completedWorkout;
  final Workout nextWorkout;
  final int daysUntilNext;

  const CompletedWorkoutHeroCard({
    super.key,
    required this.completedWorkout,
    required this.nextWorkout,
    required this.daysUntilNext,
  });

  String _getNextWorkoutLabel() {
    if (daysUntilNext == 1) return 'Tomorrow';
    if (daysUntilNext == 2) return 'In 2 days';
    return 'In $daysUntilNext days';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimary
        : AppColorsLight.textPrimary;
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: 0.2),
              blurRadius: 24,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Completed workout banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.15),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(19),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 18,
                    color: AppColors.success,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context).heroWorkoutCardTodaySWorkoutComplete,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Next workout content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getNextWorkoutLabel().toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      HapticService.selection();
                      GoRouter.of(context).push('/workout/${nextWorkout.id}');
                    },
                    child: Text(
                      nextWorkout.name ?? AppLocalizations.of(context).navWorkout,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _StatChip(
                        icon: Icons.timer_outlined,
                        label: '${nextWorkout.bestDurationMinutes} min',
                        isDark: isDark,
                      ),
                      const SizedBox(width: 16),
                      _StatChip(
                        icon: Icons.fitness_center,
                        label: '${nextWorkout.exerciseCount} exercises',
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton(
                      onPressed: () {
                        HapticService.medium();
                        GoRouter.of(context).push('/workout/${nextWorkout.id}');
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: accentColor, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 22,
                            color: accentColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            AppLocalizations.of(context).heroWorkoutCardPreview,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Card shown when generating/loading workouts. When [onRetry] is non-null,
/// the card renders a tappable "Tap to retry" CTA underneath the message
/// (used after generation polling caps out — plan §4 retry sentinel).
class GeneratingHeroCard extends ConsumerStatefulWidget {
  final String? message;
  final String? subtitle;
  final VoidCallback? onRetry;

  const GeneratingHeroCard({
    super.key,
    this.message,
    this.subtitle,
    this.onRetry,
  });

  @override
  ConsumerState<GeneratingHeroCard> createState() => _GeneratingHeroCardState();
}


class _GeneratingHeroCardState extends ConsumerState<GeneratingHeroCard>
    with TickerProviderStateMixin {
  // A polished, multi-layer loading motif (richer than a single shimmer):
  //   • _pulseController  — breathing glow halo behind the icon
  //   • _sweepController  — a rotating "comet" highlight around the ring
  //   • _shimmerController — the moving sheen on the progress bar
  // plus a timer that rotates the status line through real generation stages.
  late final AnimationController _pulseController;
  late final AnimationController _sweepController;
  late final AnimationController _shimmerController;
  Timer? _stageTimer;
  int _stageIndex = 0;

  // Shown only when the caller didn't pass a custom subtitle — cycles so the
  // wait reads as active work rather than a frozen "please wait".
  static const List<String> _stages = [
    'Reviewing your plan…',
    'Picking your exercises…',
    'Balancing your volume…',
    'Adding warm-ups…',
    'Finishing touches…',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _stageTimer = Timer.periodic(const Duration(milliseconds: 1700), (_) {
      if (!mounted) return;
      setState(() => _stageIndex = (_stageIndex + 1) % _stages.length);
    });
  }

  @override
  void dispose() {
    _stageTimer?.cancel();
    _pulseController.dispose();
    _sweepController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.pureBlack : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);

    final statusLine = widget.subtitle ?? _stages[_stageIndex];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Stack(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 180),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.alphaBlend(
                      accentColor.withValues(alpha: isDark ? 0.10 : 0.06),
                      cardBg),
                  cardBg,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RepaintBoundary(
                  child: _buildMotif(accentColor, cardBg),
                ),
                const SizedBox(height: 22),
                Text(
                  widget.message ??
                      AppLocalizations.of(context)
                          .heroWorkoutCardLoadingYourWorkout,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                // Rotating stage copy — fades/slides between stages.
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(anim),
                      child: child,
                    ),
                  ),
                  child: Text(
                    statusLine,
                    key: ValueKey(statusLine),
                    style: TextStyle(fontSize: 14, color: textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (widget.onRetry != null) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label:
                        Text(AppLocalizations.of(context).upNextCardTapToRetry),
                    style: FilledButton.styleFrom(
                      backgroundColor: accentColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                RepaintBoundary(child: _buildProgressBar(accentColor)),
              ],
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(
              width: 4,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Animated hero motif: a breathing glow halo, a rotating comet ring, a faint
  /// static track, and the dumbbell at center.
  Widget _buildMotif(Color accentColor, Color cardBg) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Breathing glow halo.
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, _) {
              final t = _pulseController.value; // 0..1
              return Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.20 + 0.22 * t),
                      blurRadius: 14 + 14 * t,
                      spreadRadius: 1 + 4 * t,
                    ),
                  ],
                ),
              );
            },
          ),
          // Faint full track ring.
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: accentColor.withValues(alpha: 0.16),
                width: 4,
              ),
            ),
          ),
          // Rotating comet highlight (sweep gradient disk masked to a ring).
          RotationTransition(
            turns: _sweepController,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                    accentColor.withValues(alpha: 0.0),
                    accentColor.withValues(alpha: 0.0),
                    accentColor,
                    accentColor.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.55, 0.88, 1.0],
                ),
              ),
            ),
          ),
          // Inner mask carves the disk into a 4px ring.
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(shape: BoxShape.circle, color: cardBg),
          ),
          // Gently pulsing dumbbell.
          ScaleTransition(
            scale: Tween<double>(begin: 0.9, end: 1.06).animate(
              CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
            ),
            child: Icon(
              Icons.fitness_center_rounded,
              color: accentColor,
              size: 26,
            ),
          ),
        ],
      ),
    );
  }

  /// A wider, rounded progress track with a bright moving sheen.
  Widget _buildProgressBar(Color accentColor) {
    const barWidth = 150.0;
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          height: 5,
          width: barWidth,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: accentColor.withValues(alpha: 0.16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: Stack(
              children: [
                Positioned(
                  left: _shimmerController.value * (barWidth + 60) - 60,
                  child: Container(
                    width: 60,
                    height: 5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accentColor.withValues(alpha: 0.0),
                          accentColor,
                          accentColor.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

