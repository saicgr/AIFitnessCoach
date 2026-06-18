part of 'set_tracking_table.dart';


/// Set number badge widget
class _SetNumberBadge extends StatelessWidget {
  final int? number;
  final bool isWarmup;
  final bool isCompleted;
  final bool isActive;
  final bool isDark;

  const _SetNumberBadge({
    this.number,
    this.isWarmup = false,
    this.isCompleted = false,
    this.isActive = false,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Signature set number (.ra-c1): a bare Barlow Condensed numeral — no
    // circular chip. Active = full text color, done = full color, upcoming
    // = faint, matching the hairline-led cockpit table.
    final Color color = isActive
        ? (isDark ? AppColors.textPrimary : Colors.grey.shade900)
        : isCompleted
            ? (isDark ? AppColors.textPrimary : Colors.grey.shade800)
            : (isDark ? AppColors.textMuted : Colors.grey.shade500);
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      alignment: AlignmentDirectional.centerStart,
      child: Text(
        isWarmup ? 'W' : (number?.toString() ?? ''),
        style: ZType.lbl(15, color: color, letterSpacing: 0.5),
      ),
    );
  }
}


/// Auto target cell showing AI recommendation with RIR pill
class _AutoTargetCell extends StatelessWidget {
  final double? targetWeight;
  final String? targetReps;
  final int? targetRir;
  final double? previousWeight;
  final int? previousReps;
  final bool useKg;
  final bool isWarmup;
  final bool isDark;
  /// When set, the cell renders a time-based target ("45s hold" / "5 min").
  final int? targetHoldSeconds;
  final int? targetDurationSeconds;
  /// True for cardio/timed exercises — affects label ("hold" vs duration).
  final bool isTimedExercise;
  /// True when exercise uses no external load — render reps only, never "0 kg".
  final bool isBodyweight;

  // ── Trend pill / Edited chip plumbing ─────────────────────────────────
  final bool progressiveOverloadEnabled;
  final bool isEdited;
  final bool isDeload;
  final bool isFirstSetEver;
  final double? previousSetTargetWeight; // in kg
  final int? previousSetTargetReps;
  final int? previousSetTargetSeconds;
  // ── RIR pills plumbing (parity with set_row.dart) ─────────────────────
  final bool isEasyMode;
  final bool isAmrap;
  final int? actualRir;
  /// Raw set type string ('working' | 'warmup' | 'failure' | 'amrap'). When
  /// it equals 'failure' the target-effort pill reads "Push to failure".
  final String setType;

  const _AutoTargetCell({
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.previousWeight,
    this.previousReps,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
    this.targetHoldSeconds,
    this.targetDurationSeconds,
    this.isTimedExercise = false,
    this.isBodyweight = false,
    this.progressiveOverloadEnabled = true,
    this.isEdited = false,
    this.isDeload = false,
    this.isFirstSetEver = false,
    this.previousSetTargetWeight,
    this.previousSetTargetReps,
    this.previousSetTargetSeconds,
    this.isEasyMode = false,
    this.isAmrap = false,
    this.actualRir,
    this.setType = 'working',
  });

  /// Format seconds as "45s" or "1:30" for ≥60s, "5 min" for clean minutes.
  static String _formatSeconds(int seconds) {
    if (seconds <= 0) return '';
    if (seconds >= 60 && seconds % 60 == 0) {
      final mins = seconds ~/ 60;
      return '$mins min';
    }
    if (seconds >= 60) {
      final m = seconds ~/ 60;
      final s = seconds % 60;
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '${seconds}s';
  }

  void _showRirExplanation(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with close button
                  Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Icon(
                        Icons.close,
                        size: 24,
                        color: isDarkTheme ? Colors.white : Colors.black,
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).setTrackingTableWhatIsRir,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24), // Balance the close button
                  ],
                ),
                const SizedBox(height: 24),

                // Scale labels
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).setTrackingTableHardest,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).setTrackingTableEasiest,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      AppLocalizations.of(context).setTrackingTableNoRepsInReserve,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      AppLocalizations.of(context).setTrackingTableManyRepsInReserve,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // RIR scale with colored circles
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildRirCircle('0', WorkoutDesign.rirMax, isDarkTheme),
                    _buildRirCircle('1', WorkoutDesign.rir1, isDarkTheme),
                    _buildRirCircle('2', WorkoutDesign.rir2, isDarkTheme),
                    _buildRirCircle('3', WorkoutDesign.rir3, isDarkTheme),
                    _buildRirCircle('4', const Color(0xFF3B82F6), isDarkTheme), // Blue
                    _buildRirCircle('5', const Color(0xFF3B82F6), isDarkTheme),
                    _buildRirCircle('6+', const Color(0xFF3B82F6), isDarkTheme),
                  ],
                ),
                const SizedBox(height: 24),

                // Divider
                Divider(
                  color: isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                const SizedBox(height: 16),

                // Explanation text
                Text(
                  AppLocalizations.of(context).setTrackingTableWhatYouSeeAbove,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).setTrackingTableRirStandsForReps,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).setTrackingTableALowerRir0,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).setTrackingTableYouAreNotRequired,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),

                // ── How your target RIR is calculated ──
                Divider(
                  color: isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
                ),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context).setTrackingTableHowYourTargetRir,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalizations.of(context).setTrackingTableYourRirTargetIs,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRirFactorRow(
                  icon: Icons.track_changes,
                  color: AppColors.orange,
                  title: AppLocalizations.of(context).setTrackingTableTrainingGoalExerciseType,
                  description: AppLocalizations.of(context).setTrackingTableCompoundLiftsSquatsPresse,
                  isDark: isDarkTheme,
                ),
                const SizedBox(height: 10),
                _buildRirFactorRow(
                  icon: Icons.fitness_center,
                  color: AppColors.cyan,
                  title: AppLocalizations.of(context).setTrackingTableEquipmentSafety,
                  description: AppLocalizations.of(context).setTrackingTableMachinesCablesAreSafer,
                  isDark: isDarkTheme,
                ),
                const SizedBox(height: 10),
                _buildRirFactorRow(
                  icon: Icons.trending_up,
                  color: AppColors.green,
                  title: AppLocalizations.of(context).setTrackingTableYourFitnessLevel,
                  description: AppLocalizations.of(context).setTrackingTableBeginnersGetExtraBuffer,
                  isDark: isDarkTheme,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDarkTheme
                        ? AppColors.orange.withOpacity(0.1)
                        : AppColors.orange.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: AppColors.orange,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppLocalizations.of(context).setTrackingTableRirDecreasesAcrossSets,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRirFactorRow({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRirCircle(String label, Color color, bool isDark) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: (color == WorkoutDesign.rir2)
                ? Colors.black87 // Dark text on yellow
                : Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build target string
    String targetString = '';

    // ── Priority 1: Timed/hold target (planks, hollow body, walking, etc.)
    // Per-set hold target beats everything else — e.g. Hollow Body Hold
    // prescribes 30s→45s→45s→45s and that is the true per-set target.
    final holdSecs = targetHoldSeconds;
    final durSecs = targetDurationSeconds;
    if ((holdSecs != null && holdSecs > 0) || (durSecs != null && durSecs > 0)) {
      final secs = (holdSecs != null && holdSecs > 0) ? holdSecs : durSecs!;
      final timeStr = _formatSeconds(secs);
      // "45s hold" for static holds; plain duration for cardio (Walking 5 min).
      final isHoldStyle = holdSecs != null && holdSecs > 0;
      targetString = isWarmup
          ? (isHoldStyle ? 'Warmup · $timeStr hold' : 'Warmup · $timeStr')
          : (isHoldStyle ? '$timeStr hold' : timeStr);
    }
    // ── Priority 2: Weight × reps (standard strength prescription)
    else if (targetWeight != null && targetWeight! > 0 && targetReps != null && !isBodyweight) {
      final displayWeight = useKg ? targetWeight! : WeightUtils.fromKgSnapped(targetWeight!, displayInLbs: true);
      targetString = '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} ${useKg ? 'kg' : 'lb'} x $targetReps';
    }
    // ── Priority 3: Bodyweight reps — never show "0 kg × 10", just reps.
    else if (isBodyweight && targetReps != null) {
      targetString = isWarmup ? 'Warmup · $targetReps reps' : '$targetReps reps';
    }
    // ── Priority 4: Previous session (weighted) — use last session's load.
    else if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : WeightUtils.fromKgSnapped(previousWeight!, displayInLbs: true);
      targetString = '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} ${useKg ? 'kg' : 'lb'} x $previousReps';
    }
    // ── Priority 5: Warmup without any numeric target — hint text.
    else if (isWarmup) {
      targetString = targetReps != null ? 'Warmup × $targetReps' : 'Warmup';
    }
    // ── Priority 6: Reps-only target (AMRAP or first-time weighted exercise)
    else if (targetReps != null) {
      targetString = '× $targetReps';
    }
    // ── No data of any kind — em-dash placeholder.
    else {
      targetString = '—';
    }

    // ── Trend pill + Edited chip (parity with set_row.dart) ──────────────
    // Renders on its own line under the TARGET string. Suppressed entirely
    // when progressive overload is off; renders a "Starter weight" muted hint
    // when this is the first set ever performed for the exercise.
    final String metric = (targetHoldSeconds != null && targetHoldSeconds! > 0) ||
            (targetDurationSeconds != null && targetDurationSeconds! > 0) ||
            isTimedExercise
        ? 'time'
        : (isBodyweight ? 'reps' : 'weight');
    final double targetDisplay = (targetWeight != null && targetWeight! > 0)
        ? (useKg ? targetWeight! : WeightUtils.fromKgSnapped(targetWeight!, displayInLbs: true))
        : 0.0;
    final double? prevDisplay = previousSetTargetWeight != null && previousSetTargetWeight! > 0
        ? (useKg
            ? previousSetTargetWeight!
            : WeightUtils.fromKgSnapped(previousSetTargetWeight!, displayInLbs: true))
        : null;
    // Best-effort numeric reps for trend math: parse the lo end of "8-12".
    final int targetRepsInt = (() {
      final s = targetReps;
      if (s == null || s.isEmpty) return 0;
      return int.tryParse(s.split('-').first.trim()) ?? 0;
    })();
    final trendPill = SetRowVisuals.buildTrendPill(
      progressiveOverloadEnabled: progressiveOverloadEnabled,
      isFirstSetEver: isFirstSetEver,
      isDeload: isDeload,
      metric: metric,
      targetWeightDisplay: targetDisplay,
      targetReps: targetRepsInt,
      durationSeconds: targetDurationSeconds ?? targetHoldSeconds,
      previousSetTargetWeightDisplay: prevDisplay,
      previousSetTargetReps: previousSetTargetReps,
      previousSetTargetSeconds: previousSetTargetSeconds,
      unitLabel: useKg ? 'kg' : 'lb',
    );
    final editedChip = SetRowVisuals.buildEditedChip(isEdited: isEdited);

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target weight x reps — Signature .ra-tg cell: monospaced
            // telemetry numerals, tinted muted/rust so the AI target reads as
            // guidance distinct from the user-logged values.
            Text(
              targetString,
              style: ZType.data(
                11.5,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade700,
                weight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (trendPill != null || editedChip != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (trendPill != null) trendPill,
                    if (trendPill != null && editedChip != null)
                      const SizedBox(width: 4),
                    if (editedChip != null) editedChip,
                  ],
                ),
              ),
            // RIR pill with info icon - only ? icon is tappable.
            // Shown ONLY before the set is logged: once an actualRir exists the
            // logged-RIR chip below replaces it. Rendering BOTH stacked the
            // column past the fixed row height ("OVERFLOWED BY 1.00" + the
            // logged pill overlapping the target pill).
            if (targetRir != null && actualRir == null)
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: WorkoutDesign.getRirColor(targetRir!),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        WorkoutDesign.getRirLabel(targetRir!),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: WorkoutDesign.getRirTextColor(targetRir!),
                        ),
                      ),
                      const SizedBox(width: 2),
                      // Only the ? icon triggers the explanation
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showRirExplanation(context),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.help_outline,
                            size: 12,
                            color: WorkoutDesign.getRirTextColor(targetRir!).withOpacity(0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // ── Outline target / filled logged RIR pills (parity with
            // set_row.dart). The existing colored pill above doubles as the
            // canonical target indicator + ? affordance; these helper pills
            // explicitly call out AMRAP and the user-logged RIR after pick.
            // Suppressed in Easy mode by the helper itself.
            Builder(builder: (context) {
              // Avoid duplicating the existing colored target-RIR pill: the
              // helper renders an outline target-effort pill only when AMRAP
              // or a 'failure' set (so the "Push to failure" override
              // surfaces) or the logged value is set, in which case the
              // filled chip is what we really need.
              final isFailureSet = setType.toLowerCase() == 'failure';
              // surfaces the "· AMRAP" / "Push to failure" override
              final showTargetCopy = isAmrap || isFailureSet;
              final pills = SetRowVisuals.buildRirPills(
                isEasyMode: isEasyMode,
                isAmrap: isAmrap,
                targetRir: showTargetCopy ? targetRir : null,
                actualRir: actualRir,
                setType: setType,
                // Live BuildContext from the Builder — makes the target-effort
                // pill tappable and opens the plain-English explainer sheet.
                context: context,
              );
              if (pills == null) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 2),
                child: pills,
              );
            }),
          ],
        ),
      ),
    );
  }
}


/// Previous session cell showing weight x reps + RIR from last workout
class _PreviousCell extends StatelessWidget {
  final double? previousWeight;
  final int? previousReps;
  final int? previousRir;
  final bool useKg;
  final bool isDark;

  const _PreviousCell({
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    required this.useKg,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    // If no previous data, show dash
    if (previousWeight == null && previousReps == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Text(
          '—',
          style: ZType.data(
            11.5,
            color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            weight: FontWeight.w400,
          ),
        ),
      );
    }

    // Build previous string
    String previousString = '';
    if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : WeightUtils.fromKgSnapped(previousWeight!, displayInLbs: true);
      previousString = '${displayWeight.toStringAsFixed(0)} x $previousReps';
    } else if (previousReps != null) {
      previousString = '$previousReps reps';
    }

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous weight x reps — monospaced telemetry, muted.
            Text(
              previousString,
              style: ZType.data(
                11.5,
                color: isDark ? AppColors.textMuted : Colors.grey.shade500,
                weight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // RIR pill (if available)
            if (previousRir != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: WorkoutDesign.getRirColor(previousRir!).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'RIR $previousRir',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? WorkoutDesign.getRirColor(previousRir!)
                          : WorkoutDesign.getRirColor(previousRir!).withOpacity(0.8),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


/// Previous cell with RIR badge - combines previous data with target RIR
/// Used when Target column is removed
class _PreviousCellWithRir extends StatelessWidget {
  final double? previousWeight;
  final int? previousReps;
  final int? previousRir;
  final int? targetRir;
  final bool useKg;
  final bool isWarmup;
  final bool isDark;
  /// Callback when RIR badge text is tapped (for editing)
  final VoidCallback? onRirTapped;

  /// "Same as last time" — tapping the previous weight×reps copies it into the
  /// active set. Null disables the affordance (e.g. completed rows, or rows
  /// with no history). When non-null AND there's previous data, a small replay
  /// glyph is shown to signal tap-to-copy.
  final VoidCallback? onCopyPrevious;

  const _PreviousCellWithRir({
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    this.targetRir,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
    this.onRirTapped,
    this.onCopyPrevious,
  });

  void _showRirExplanation(BuildContext context) {
    final isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    showGlassSheet(
      context: context,
      builder: (context) => GlassSheet(
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: isDarkTheme ? Colors.white : Colors.black,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            AppLocalizations.of(context).setTrackingTableWhatIsRir,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context).setTrackingTableRirStandsForReps,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).setTrackingTableALowerRir02,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── How your target RIR is calculated ──
                  Divider(
                    color: isDarkTheme ? Colors.grey.shade800 : Colors.grey.shade200,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context).setTrackingTableHowYourTargetRir,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppLocalizations.of(context).setTrackingTableYourRirTargetIs,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _AutoTargetCell._buildRirFactorRow(
                    icon: Icons.track_changes,
                    color: AppColors.orange,
                    title: AppLocalizations.of(context).setTrackingTableTrainingGoalExerciseType,
                    description: AppLocalizations.of(context).setTrackingTableCompoundLiftsSquatsPresse,
                    isDark: isDarkTheme,
                  ),
                  const SizedBox(height: 10),
                  _AutoTargetCell._buildRirFactorRow(
                    icon: Icons.fitness_center,
                    color: AppColors.cyan,
                    title: AppLocalizations.of(context).setTrackingTableEquipmentSafety,
                    description: AppLocalizations.of(context).setTrackingTableMachinesCablesAreSafer,
                    isDark: isDarkTheme,
                  ),
                  const SizedBox(height: 10),
                  _AutoTargetCell._buildRirFactorRow(
                    icon: Icons.trending_up,
                    color: AppColors.green,
                    title: AppLocalizations.of(context).setTrackingTableYourFitnessLevel,
                    description: AppLocalizations.of(context).setTrackingTableBeginnersGetExtraBuffer,
                    isDark: isDarkTheme,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkTheme
                          ? AppColors.orange.withOpacity(0.1)
                          : AppColors.orange.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.orange.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: AppColors.orange,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).setTrackingTableRirDecreasesAcrossSets,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Build previous string
    String previousString = '—';
    if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : WeightUtils.fromKgSnapped(previousWeight!, displayInLbs: true);
      previousString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'} x $previousReps';
    } else if (previousReps != null) {
      previousString = '$previousReps reps';
    } else if (previousWeight != null) {
      final displayWeight = useKg ? previousWeight! : WeightUtils.fromKgSnapped(previousWeight!, displayInLbs: true);
      previousString = '${displayWeight.toStringAsFixed(0)} ${useKg ? 'kg' : 'lb'}';
    }

    // Determine which RIR to show (target takes priority for current set guidance)
    final displayRir = targetRir ?? previousRir;

    final bool hasPrevious = previousWeight != null || previousReps != null;
    final bool copyable = onCopyPrevious != null && hasPrevious;

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous weight x reps — monospaced telemetry, muted. When the
            // active set can adopt it ("same as last time"), the whole cell is
            // tap-to-copy with a small replay glyph hint.
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: copyable
                  ? () {
                      HapticFeedback.selectionClick();
                      onCopyPrevious!();
                    }
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      previousString,
                      style: ZType.data(
                        11.5,
                        color:
                            isDark ? AppColors.textSecondary : Colors.grey.shade600,
                        weight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (copyable) ...[
                    const SizedBox(width: 3),
                    Icon(
                      Icons.replay_rounded,
                      size: 11,
                      color: ThemeColors.of(context).accent.withOpacity(0.85),
                    ),
                  ],
                ],
              ),
            ),

            // RIR pill with ? icon (if available and not warmup)
            // RIR text is tappable to edit, ? icon shows explanation
            if (displayRir != null && !isWarmup)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Container(
                  padding: const EdgeInsets.only(left: 5, top: 1, bottom: 1),
                  decoration: BoxDecoration(
                    color: WorkoutDesign.getRirColor(displayRir).withOpacity(isDark ? 0.25 : 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // RIR text - tappable to edit
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: onRirTapped != null
                            ? () {
                                HapticFeedback.lightImpact();
                                onRirTapped!();
                              }
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 2),
                          child: Text(
                            'RIR $displayRir',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                          color: isDark
                              ? WorkoutDesign.getRirColor(displayRir)
                              : WorkoutDesign.getRirColor(displayRir).withOpacity(0.9),
                        ),
                      ),
                    ),
                  ),
                      // ? icon triggers the explanation - larger tap area
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _showRirExplanation(context),
                        child: Padding(
                          padding: const EdgeInsets.all(3),
                          child: Icon(
                            Icons.help_outline,
                            size: 12,
                            color: isDark
                                ? WorkoutDesign.getRirColor(displayRir).withOpacity(0.7)
                                : WorkoutDesign.getRirColor(displayRir).withOpacity(0.6),
                          ),
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


/// Input field for weight/reps (theme-aware)
class _DarkInputField extends StatelessWidget {
  final TextEditingController controller;
  final void Function(String)? onSubmitted;
  final bool isDark;
  final String? hintText;

  const _DarkInputField({
    required this.controller,
    this.onSubmitted,
    this.isDark = true,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    final accent = ThemeColors.of(context).accent;
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        // Signature telemetry numerals (Space Mono) for the editable value.
        style: ZType.data(
          16,
          color: isDark ? AppColors.textPrimary : Colors.grey.shade900,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark
              ? AppColors.elevated.withValues(alpha: 0.6)
              : Colors.grey.shade100,
          hintText: hintText,
          hintStyle: ZType.data(
            16,
            color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            weight: FontWeight.w400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: BorderSide(
              color: isDark ? AppColors.hairlineStrong : Colors.grey.shade300,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: BorderSide(
              color: isDark ? AppColors.hairlineStrong : Colors.grey.shade300,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: BorderSide(color: accent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          isDense: true,
        ),
        onSubmitted: onSubmitted,
      ),
    );
  }
}


/// Cell showing completed value (not editable inline)
class _CompletedValueCell extends StatelessWidget {
  final String value;
  final bool isCompleted;
  final bool isDark;
  final String? label; // Optional label like "L" or "R" for L/R mode

  const _CompletedValueCell({
    required this.value,
    required this.isCompleted,
    this.isDark = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Signature done-cell (.ra-c4/.ra-c5): bare monospaced numeral, no boxed
    // fill — done rows read at full text color, the rest stay muted.
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: Center(
        child: label != null && value.isEmpty
            ? Text(
                label!,
                style: ZType.lbl(
                  11,
                  color: isDark ? AppColors.textMuted : Colors.grey.shade400,
                  letterSpacing: 1,
                ),
              )
            : Text(
                value.isEmpty ? '—' : value,
                style: ZType.data(
                  15,
                  color: isDark
                      ? (isCompleted ? AppColors.textPrimary : AppColors.textMuted)
                      : (isCompleted ? Colors.grey.shade800 : Colors.grey.shade500),
                  weight: FontWeight.w400,
                ),
              ),
      ),
    );
  }
}


/// Completion checkbox widget
class _CompletionCheckbox extends StatelessWidget {
  final bool isCompleted;
  final bool isActive;
  final VoidCallback onTap;
  final bool isDark;

  const _CompletionCheckbox({
    required this.isCompleted,
    required this.isActive,
    required this.onTap,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Signature done-check uses the green status color (.ck #5BE49B).
    const doneGreen = Color(0xFF5BE49B);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted ? doneGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCompleted
                ? doneGreen
                : isActive
                    ? (isDark ? AppColors.textSecondary : Colors.grey.shade600)
                    : (isDark ? AppColors.hairlineStrong : Colors.grey.shade400),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 16,
                color: Color(0xFF0A0A0A),
              )
            : null,
      ),
    );
  }
}


/// Small colored RIR badge shown on completed set rows
class _RirBadge extends StatelessWidget {
  final int rir;
  final bool isDark;

  const _RirBadge({
    required this.rir,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = WorkoutDesign.getRirColor(rir);
    final textColor = WorkoutDesign.getRirTextColor(rir);

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$rir',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}


/// Inert em-dash cell used when a column is not applicable for this exercise
/// (e.g. the weight column for bodyweight/timed exercises). Keeps the grid
/// aligned without offering an input nobody can use.
class _DashCell extends StatelessWidget {
  const _DashCell();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: Center(
        child: Text(
          '—',
          style: ZType.data(
            15,
            color: isDark ? AppColors.textMuted : Colors.grey.shade400,
            weight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}


/// Read-only time-target readout for timed exercises (planks, walking,
/// hollow body holds). Shows the per-set target (e.g. "45s") while pending
/// and the logged duration once the set is completed.
///
/// The actual time capture happens in the TimedExerciseTimer sheet driven by
/// the active-set flow — this widget is purely for the table row.
class _TimedTargetCell extends StatelessWidget {
  final int? targetHoldSeconds;
  final int? targetDurationSeconds;
  final int? actualDurationSeconds;
  final bool isActive;
  final bool isCompleted;
  final bool isDark;

  const _TimedTargetCell({
    this.targetHoldSeconds,
    this.targetDurationSeconds,
    this.actualDurationSeconds,
    this.isActive = false,
    this.isCompleted = false,
    this.isDark = true,
  });

  static String _fmt(int s) {
    if (s <= 0) return '—';
    if (s >= 60 && s % 60 == 0) return '${s ~/ 60}m';
    if (s >= 60) return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
    return '${s}s';
  }

  @override
  Widget build(BuildContext context) {
    // Completed — show the actual duration the user logged.
    if (isCompleted && actualDurationSeconds != null && actualDurationSeconds! > 0) {
      return _CompletedValueCell(
        value: _fmt(actualDurationSeconds!),
        isCompleted: true,
        isDark: isDark,
      );
    }
    // Active set — show the target prominently. Hairline-led: no boxed fill,
    // just the reserved accent on the icon + monospaced time readout.
    final accent = ThemeColors.of(context).accent;
    final target = (targetHoldSeconds != null && targetHoldSeconds! > 0)
        ? targetHoldSeconds!
        : (targetDurationSeconds ?? 0);
    final label = _fmt(target);
    final Color valueColor = isActive
        ? accent
        : (isDark ? AppColors.textSecondary : Colors.grey.shade700);
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: 12,
              color: isActive
                  ? accent
                  : (isDark ? AppColors.textMuted : Colors.grey.shade500),
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: ZType.data(13, color: valueColor, weight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }
}


/// RIR quick-select bar shown below the active set row
class _RirQuickSelectBar extends StatelessWidget {
  final int? selectedRir;
  final ValueChanged<int> onRirSelected;
  final bool isDark;

  const _RirQuickSelectBar({
    super.key,
    this.selectedRir,
    required this.onRirSelected,
    this.isDark = true,
  });

  static const _rirOptions = [0, 1, 2, 3, 4, 5];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'RIR',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
            ),
          ),
          const SizedBox(width: 8),
          ..._rirOptions.map((rir) {
            final isSelected = selectedRir == rir;
            final color = WorkoutDesign.getRirColor(rir);
            final label = rir == 5 ? '5+' : '$rir';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  onRirSelected(rir);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 36,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isSelected ? color : color.withOpacity(isDark ? 0.15 : 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected ? color : color.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected
                            ? WorkoutDesign.getRirTextColor(rir)
                            : color,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

