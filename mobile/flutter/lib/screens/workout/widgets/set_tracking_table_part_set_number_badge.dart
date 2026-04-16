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
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        color: isActive
            ? WorkoutDesign.accentBlue.withOpacity(0.2)
            : isCompleted
                ? (isDark ? WorkoutDesign.textMuted.withOpacity(0.15) : Colors.grey.shade200)
                : (isDark ? WorkoutDesign.surface : Colors.grey.shade50),
        shape: BoxShape.circle,
        border: Border.all(
          color: isActive
              ? WorkoutDesign.accentBlue
              : isCompleted
                  ? (isDark ? WorkoutDesign.textMuted.withOpacity(0.3) : Colors.grey.shade400)
                  : (isDark ? WorkoutDesign.border : Colors.grey.shade300),
          width: isActive ? 2 : 1,
        ),
      ),
      child: Center(
        child: Text(
          isWarmup ? 'W' : (number?.toString() ?? ''),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive
                ? WorkoutDesign.accentBlue
                : isCompleted
                    ? (isDark ? WorkoutDesign.textMuted : Colors.grey.shade500)
                    : (isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800),
          ),
        ),
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

  const _AutoTargetCell({
    this.targetWeight,
    this.targetReps,
    this.targetRir,
    this.previousWeight,
    this.previousReps,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          'What is RIR?',
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
                      'Hardest',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDarkTheme ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Easiest',
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
                      'No reps in reserve',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkTheme ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Many reps in reserve',
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
                  'What you see above is an RIR scale',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'RIR stands for Reps in Reserve—a simple way to describe how challenging a set felt.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A lower RIR (0–1) means you pushed to your limit. A higher RIR (like 4–6+) means the set felt easier and you had plenty left in the tank.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You are not required to track RIR, but we strongly recommend it. Understanding your proximity to failure will help the app better accommodate your current strength levels and rates of fatigue.',
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
                  'How your target RIR is calculated',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDarkTheme ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your RIR target is personalized using three factors:',
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
                  title: 'Training Goal + Exercise Type',
                  description: 'Compound lifts (squats, presses) stay more conservative than isolation moves (curls, raises). Hypertrophy pushes closer to failure than strength.',
                  isDark: isDarkTheme,
                ),
                const SizedBox(height: 10),
                _buildRirFactorRow(
                  icon: Icons.fitness_center,
                  color: AppColors.cyan,
                  title: 'Equipment Safety',
                  description: 'Machines & cables are safer to push hard on. Barbells & kettlebells need more reserve due to injury risk.',
                  isDark: isDarkTheme,
                ),
                const SizedBox(height: 10),
                _buildRirFactorRow(
                  icon: Icons.trending_up,
                  color: AppColors.green,
                  title: 'Your Fitness Level',
                  description: 'Beginners get extra buffer for form learning. Advanced lifters can push closer to failure safely.',
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
                          'RIR decreases across sets — the last set pushes hardest while earlier sets build up.',
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

    if (targetWeight != null && targetReps != null) {
      final displayWeight = useKg ? targetWeight! : WeightUtils.fromKgSnapped(targetWeight!, displayInLbs: true);
      targetString = '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} ${useKg ? 'kg' : 'lb'} x $targetReps';
    } else if (previousWeight != null && previousReps != null) {
      final displayWeight = useKg ? previousWeight! : WeightUtils.fromKgSnapped(previousWeight!, displayInLbs: true);
      targetString = '${displayWeight.toStringAsFixed(displayWeight % 1 == 0 ? 0 : 1)} ${useKg ? 'kg' : 'lb'} x $previousReps';
    } else {
      throw StateError(
        'No weight data available for set target. '
        'targetWeight: $targetWeight, targetReps: $targetReps, '
        'previousWeight: $previousWeight, previousReps: $previousReps, '
        'isWarmup: $isWarmup',
      );
    }

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target weight x reps
            Text(
              targetString,
              style: WorkoutDesign.autoTargetStyle.copyWith(
                color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // RIR pill with info icon - only ? icon is tappable
            if (targetRir != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
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
          style: WorkoutDesign.autoTargetStyle.copyWith(
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
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
            // Previous weight x reps
            Text(
              previousString,
              style: WorkoutDesign.autoTargetStyle.copyWith(
                color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade500,
                fontSize: 12,
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

  const _PreviousCellWithRir({
    this.previousWeight,
    this.previousReps,
    this.previousRir,
    this.targetRir,
    required this.useKg,
    this.isWarmup = false,
    this.isDark = true,
    this.onRirTapped,
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
                      const Expanded(
                        child: Center(
                          child: Text(
                            'What is RIR?',
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
                    'RIR stands for Reps in Reserve—a simple way to describe how challenging a set felt.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isDarkTheme ? Colors.grey.shade300 : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'A lower RIR (0–1) means you pushed close to your limit. A higher RIR (like 3–4) means you had more reps in the tank.',
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
                    'How your target RIR is calculated',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDarkTheme ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Your RIR target is personalized using three factors:',
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
                    title: 'Training Goal + Exercise Type',
                    description: 'Compound lifts (squats, presses) stay more conservative than isolation moves (curls, raises). Hypertrophy pushes closer to failure than strength.',
                    isDark: isDarkTheme,
                  ),
                  const SizedBox(height: 10),
                  _AutoTargetCell._buildRirFactorRow(
                    icon: Icons.fitness_center,
                    color: AppColors.cyan,
                    title: 'Equipment Safety',
                    description: 'Machines & cables are safer to push hard on. Barbells & kettlebells need more reserve due to injury risk.',
                    isDark: isDarkTheme,
                  ),
                  const SizedBox(height: 10),
                  _AutoTargetCell._buildRirFactorRow(
                    icon: Icons.trending_up,
                    color: AppColors.green,
                    title: 'Your Fitness Level',
                    description: 'Beginners get extra buffer for form learning. Advanced lifters can push closer to failure safely.',
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
                            'RIR decreases across sets — the last set pushes hardest while earlier sets build up.',
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

    return ClipRect(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previous weight x reps
            Text(
              previousString,
              style: WorkoutDesign.autoTargetStyle.copyWith(
                color: isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
    return SizedBox(
      height: WorkoutDesign.inputFieldHeight,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: WorkoutDesign.inputStyle.copyWith(
          color: isDark ? WorkoutDesign.textPrimary : Colors.grey.shade800,
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor: isDark ? WorkoutDesign.inputField : Colors.grey.shade100,
          hintText: hintText,
          hintStyle: WorkoutDesign.inputStyle.copyWith(
            color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: isDark ? BorderSide.none : BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
            borderSide: const BorderSide(color: WorkoutDesign.accentBlue, width: 2),
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
    return Container(
      height: WorkoutDesign.inputFieldHeight,
      decoration: BoxDecoration(
        color: isDark
            ? WorkoutDesign.inputField.withOpacity(isCompleted ? 0.5 : 0.3)
            : (isCompleted ? Colors.grey.shade200 : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(WorkoutDesign.radiusSmall),
        border: isDark ? null : Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        child: label != null && value.isEmpty
            ? Text(
                label!,
                style: WorkoutDesign.inputStyle.copyWith(
                  color: isDark ? WorkoutDesign.textMuted : Colors.grey.shade400,
                  fontSize: 12,
                ),
              )
            : Text(
                value.isEmpty ? '—' : value,
                style: WorkoutDesign.inputStyle.copyWith(
                  color: isDark
                      ? (isCompleted ? WorkoutDesign.textSecondary : WorkoutDesign.textMuted)
                      : (isCompleted ? Colors.grey.shade700 : Colors.grey.shade500),
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: isCompleted
              ? WorkoutDesign.success
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isCompleted
                ? WorkoutDesign.success
                : isActive
                    ? (isDark ? WorkoutDesign.textSecondary : Colors.grey.shade600)
                    : (isDark ? WorkoutDesign.border : Colors.grey.shade400),
            width: 2,
          ),
        ),
        child: isCompleted
            ? const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
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

