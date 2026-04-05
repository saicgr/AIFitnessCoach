part of 'set_tracking_overlay.dart';

/// UI builder methods extracted from _SetTrackingOverlayState
extension _SetTrackingOverlayStateUI1 on _SetTrackingOverlayState {

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.5)
            : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
      ),
      child: Row(
          children: [
            // Previous exercise button
            _buildNavButton(
              icon: Icons.chevron_left,
              enabled: widget.viewingExerciseIndex > 0,
              onTap: widget.onPreviousExercise,
              isDark: isDark,
            ),

            const SizedBox(width: 12),

            // Exercise name and position
            Expanded(
              child: Column(
                children: [
                  Text(
                    widget.exercise.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 2),
                  // Wrap in Flexible to prevent overflow
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      Text(
                        '${widget.viewingExerciseIndex + 1} of ${widget.totalExercises}',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (!isViewingCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.viewingExerciseIndex < widget.currentExerciseIndex
                                ? 'DONE'
                                : 'UPCOMING',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Next exercise button
            _buildNavButton(
              icon: Icons.chevron_right,
              enabled: widget.viewingExerciseIndex < widget.totalExercises - 1,
              onTap: widget.onNextExercise,
              isDark: isDark,
            ),

            const SizedBox(width: 8),

            // Open workout plan button
            if (widget.onOpenWorkoutPlan != null)
              _buildWorkoutPlanButton(isDark, textMuted),

            // 3-dot menu button for exercise options
            if (widget.onOpenExerciseOptions != null)
              _buildExerciseOptionsButton(isDark, textMuted),
          ],
        ),
    );
  }


  // _openAnalyticsPage moved to set_tracking_sheets.dart

  Widget _buildQuickStatButton({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required bool isDark,
    required Color textMuted,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildTableHeader(bool isDark, Color textMuted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(
            width: 36,
            child: Text(
              'SET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // LAST column - previous session data
          Expanded(
            flex: 3,
            child: Text(
              'LAST',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // TARGET column - AI recommended
          Expanded(
            flex: 3,
            child: Text(
              'TARGET',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.purple.withOpacity(0.9),
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Weight input column with unit toggle
          Expanded(
            flex: 3,
            child: GestureDetector(
              onTap: () {
                widget.onToggleUnit();
                HapticFeedback.selectionClick();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.electricBlue.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  widget.useKg ? 'KG' : 'LBS',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.electricBlue,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Reps/Time input column - show TIME for timed exercises
          Expanded(
            flex: 2,
            child: Text(
              widget.exercise.isTimedExercise ? 'TIME' : 'REPS',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.electricBlue,
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 36), // Space for checkmark
        ],
      ),
    );
  }


  /// Build set type tags row with + Set button (W/D/F + Add)
  Widget _buildSetTypeTagsWithAddButton(bool isDark, Color textMuted) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Use compact mode on narrow screens
    final isCompact = screenWidth < 340;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 12 : 16,
        vertical: isCompact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.elevated.withOpacity(0.3)
            : Colors.grey.shade100.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          // Set type label - hide on very compact screens
          if (!isCompact) ...[
            Text(
              'Set Type:',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
            const SizedBox(width: 8),
          ],
          // Tag buttons
          _buildSetTypeTag('W', 'Warmup', AppColors.orange, isDark, textMuted, isCompact),
          SizedBox(width: isCompact ? 4 : 6),
          _buildSetTypeTag('D', 'Drop Set', AppColors.purple, isDark, textMuted, isCompact),
          SizedBox(width: isCompact ? 4 : 6),
          _buildSetTypeTag('F', 'Failure', AppColors.error, isDark, textMuted, isCompact),

          SizedBox(width: isCompact ? 4 : 8),

          // Info button (right after set types)
          GestureDetector(
            onTap: () => sheets.showSetTypeInfoSheet(context),
            child: Container(
              width: isCompact ? 24 : 28,
              height: isCompact ? 24 : 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.05),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: isCompact ? 14 : 16,
                color: textMuted,
              ),
            ),
          ),

          const Spacer(),

          // + Set button (at the end)
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onAddSet();
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 8 : 10,
                vertical: isCompact ? 4 : 5,
              ),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.electricBlue.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.add_rounded,
                    size: isCompact ? 14 : 16,
                    color: AppColors.electricBlue,
                  ),
                  SizedBox(width: isCompact ? 2 : 4),
                  Text(
                    'Set',
                    style: TextStyle(
                      fontSize: isCompact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


  /// Build section header (Hevy-style)
  Widget _buildSectionHeader({
    required String title,
    bool isCollapsed = false,
    VoidCallback? onToggle,
    required bool isDark,
    required Color textMuted,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : Colors.black.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: textMuted,
              letterSpacing: 0.3,
            ),
          ),
          if (onToggle != null)
            GestureDetector(
              onTap: onToggle,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.08)
                      : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isCollapsed ? 'Show' : 'Hide',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: isCollapsed ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_up,
                        size: 14,
                        color: AppColors.electricBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  /// Build notes section (Hevy-style)
  Widget _buildNotesSection(bool isDark, Color textMuted) {
    final hasNotes = _notesController.text.isNotEmpty;

    return GestureDetector(
      onTap: () => _showNotesDialog(isDark),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.sticky_note_2_outlined,
              size: 18,
              color: hasNotes ? AppColors.purple : textMuted.withOpacity(0.6),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasNotes ? _notesController.text : 'Tap to add notes...',
                style: TextStyle(
                  fontSize: 13,
                  color: hasNotes
                      ? (isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8))
                      : textMuted.withOpacity(0.6),
                  fontStyle: hasNotes ? FontStyle.normal : FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: textMuted.withOpacity(0.4),
            ),
          ],
        ),
      ),
    );
  }


  /// Build warmup set row
  Widget _buildWarmupRow(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textMuted,
  ) {
    // Calculate warmup weight (50% of target weight for first working set)
    final targetWeight = double.tryParse(widget.weightController.text) ?? widget.exercise.weight ?? 0;
    final warmupWeight = targetWeight * 0.5;
    final warmupReps = 10; // Standard warmup reps

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Warmup row (orange styled - no separate label needed since section header says "Warmup sets")
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.orange.withOpacity(0.06)
                : AppColors.orange.withOpacity(0.04),
            border: Border(
              bottom: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.04),
              ),
            ),
          ),
          child: Row(
            children: [
              // Warmup indicator
              SizedBox(
                width: 36,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withOpacity(0.15),
                  ),
                  child: const Center(
                    child: Text(
                      'W',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                ),
              ),

              // LAST column (empty for warmup)
              Expanded(
                flex: 3,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted.withOpacity(0.5),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // TARGET column - warmup suggestion
              Expanded(
                flex: 3,
                child: Text(
                  warmupWeight > 0 ? '${warmupWeight.toStringAsFixed(0)} × $warmupReps' : '—',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.orange.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Weight column (empty for warmup)
              Expanded(
                flex: 3,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Reps column (empty for warmup)
              Expanded(
                flex: 2,
                child: Text(
                  '—',
                  style: TextStyle(
                    fontSize: 14,
                    color: textMuted.withOpacity(0.4),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

              // Warmup indicator icon
              SizedBox(
                width: 36,
                child: Icon(
                  Icons.whatshot_outlined,
                  size: 16,
                  color: AppColors.orange.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
