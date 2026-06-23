part of 'workout_detail_screen.dart';

/// UI builder methods extracted from _WorkoutDetailScreenState
extension _WorkoutDetailScreenStateUI on _WorkoutDetailScreenState {

  Widget _buildFloatingButtons(BuildContext context, WidgetRef ref, Workout workout) {
    final aiSettings = ref.watch(aiSettingsProvider);
    final coach = CoachPersona.findById(aiSettings.coachPersonaId) ?? CoachPersona.defaultCoach;
    final accentColor = ref.colors(context).accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Coach Button
        CoachAvatar(
          coach: coach,
          size: 48,
          showBorder: true,
          borderWidth: 2,
          showShadow: true,
          enableTapToView: false,
          onTap: () {
            HapticFeedback.mediumImpact();
            // Navigate to full chat screen for proper keyboard handling
            context.push('/chat');
          },
        ),
        const SizedBox(width: 12),
        // Let's Go Button - custom styled to ensure full text visibility
        GestureDetector(
          onTap: () => context.push('/active-workout', extra: workout),
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 28),
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.bolt_rounded,
                  size: 24,
                  color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)
                      .workoutDetailScreenLetSGo
                      .toUpperCase(),
                  style: ZType.lbl(
                    16,
                    color: isDark ? AppColors.pureBlack : AppColorsLight.pureWhite,
                    weight: FontWeight.w800,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  /// Build a labeled badge with "Label: Value" format for clarity
  Widget _buildLabeledBadge({
    required String label,
    required String value,
    required Color color,
    required Color backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${label.toUpperCase()}: ',
            style: ZType.lbl(
              10,
              color: labelColor,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            value.toUpperCase(),
            style: ZType.lbl(
              10,
              color: color,
              weight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }


  // _buildWorkoutSummarySection moved to WorkoutDetailAIInsightsMixin

  // _showAIInsightsPopup, _buildInsightSection, _shortenMuscleName,
  // _buildTargetedMusclesSection, _buildAIReasoningSection moved to WorkoutDetailAIInsightsMixin

  // AI Reasoning, View Parameters, and Params Section methods removed - now in mixin

  /// Build collapsible section header for warmup/stretches
  Widget _buildCollapsibleSectionHeader({
    required String title,
    required IconData icon,
    required Color color,
    required bool isExpanded,
    required VoidCallback onTap,
    required int itemCount,
    String? subtitle,
    bool? toggleValue,
    ValueChanged<bool>? onToggleChanged,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title.toUpperCase(),
                          style: ZType.lbl(
                            12,
                            color: textMuted,
                            letterSpacing: 1.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$itemCount',
                          style: ZType.data(
                            11,
                            color: color,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: ZType.sans(
                        12,
                        color: textMuted.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Toggle switch (if provided)
            if (toggleValue != null && onToggleChanged != null) ...[
              GestureDetector(
                onTap: () {}, // Absorb tap to prevent collapse/expand
                child: Switch.adaptive(
                  value: toggleValue,
                  onChanged: (value) {
                    HapticFeedback.lightImpact();
                    onToggleChanged(value);
                  },
                  activeTrackColor: color,
                ),
              ),
              const SizedBox(width: 4),
            ],
            // Custom trailing widget (if provided)
            if (trailing != null) ...[
              GestureDetector(
                onTap: () {}, // Absorb tap to prevent collapse/expand
                child: trailing,
              ),
              const SizedBox(width: 8),
            ],
            Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


  /// Build warmup/stretch item
  /// Build challenge exercise card for beginners
  Widget _buildChallengeExerciseCard(WorkoutExercise exercise) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final color = Colors.orange;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          // Exercise header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Exercise thumbnail/icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: exercise.gifUrl != null && exercise.gifUrl!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            exercise.gifUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.local_fire_department,
                              color: color,
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.local_fire_department,
                          color: color,
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Exercise info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              AppLocalizations.of(context).workoutDetailScreenChallenge.toUpperCase(),
                              style: ZType.lbl(
                                10,
                                color: color,
                                weight: FontWeight.w800,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          if (exercise.difficulty != null) ...[
                            const SizedBox(width: 8),
                            Text(
                              exercise.difficulty!.toUpperCase(),
                              style: ZType.lbl(
                                10,
                                color: textMuted,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        exercise.name,
                        style: ZType.ser(
                          17,
                          color: textPrimary,
                          weight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.repeat, size: 14, color: textMuted),
                          const SizedBox(width: 4),
                          Text(
                            exercise.setsRepsDisplay,
                            style: ZType.data(
                              12,
                              color: textMuted,
                              weight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (exercise.restSeconds != null) ...[
                            Icon(Icons.timer_outlined, size: 14, color: textMuted),
                            const SizedBox(width: 4),
                            Text(
                              '${exercise.restSeconds}s rest',
                              style: ZType.data(
                                12,
                                color: textMuted,
                                weight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Note about challenge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.black12 : Colors.white24,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context).workoutDetailScreenThisIsAnOptional,
                    style: ZType.ser(
                      13,
                      color: textMuted,
                      style: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildWarmupStretchItem(Map<String, String> item, Color color,
      {int? dragIndex}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface = isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Optimistic entries carry a `just_added: 'true'` flag so we can give
    // them a brief highlight the first time they render. This makes the
    // instant-insert feel intentional rather than ghostly.
    final bool isJustAdded = item['just_added'] == 'true';
    final Color highlightColor = AppColors.cyan;

    final tile = Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isJustAdded
            ? highlightColor.withValues(alpha: 0.12)
            : glassSurface,
        borderRadius: BorderRadius.circular(10),
        border: isJustAdded
            ? Border.all(
                color: highlightColor.withValues(alpha: 0.4),
                width: 1,
              )
            : null,
      ),
      child: Row(
        children: [
          // Drag handle — reorder affordance, mirrors the working-exercise
          // list. Only the handle starts a drag; tapping the row body opens the
          // exercise-detail screen.
          if (dragIndex != null) ...[
            ReorderableDragStartListener(
              index: dragIndex,
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Icon(Icons.drag_indicator, size: 18, color: textMuted),
              ),
            ),
          ],
          // Real exercise illustration (branded écorché) resolved by name +
          // optional library id; falls back to an icon on miss. Replaces the
          // old static dumbbell icon so warmups/stretches show real images.
          ExerciseImage(
            exerciseName: item['name'] ?? '',
            exerciseId: item['exercise_id'],
            width: 36,
            height: 36,
            borderRadius: 8,
            fit: BoxFit.cover,
            iconColor: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              item['name'] ?? '',
              style: ZType.sans(
                15,
                color: textPrimary,
                weight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              item['duration'] ?? '',
              style: ZType.data(
                11,
                color: color,
                weight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );

    if (!isJustAdded) return tile;

    // Subtle fade-up + brief highlight pulse on entry.
    return tile
        .animate()
        .fadeIn(duration: 180.ms)
        .slideY(begin: -0.1, end: 0, duration: 220.ms, curve: Curves.easeOut);
  }

  /// Shimmering placeholder tile shown while warmup/stretch data loads.
  Widget _buildWarmupStretchSkeleton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      height: 60,
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 1200.ms,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        );
  }

  /// Inline error + retry row shown when the warmup/stretch fetch fails. We
  /// surface the failure instead of silently showing a fake default list.
  Widget _buildWarmupStretchError(Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final glassSurface =
        isDark ? AppColors.glassSurface : AppColorsLight.glassSurface;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: glassSurface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: textMuted, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Couldn't load. Tap retry.",
              style: ZType.sans(14, color: textMuted),
            ),
          ),
          TextButton(
            onPressed: _loadWarmupAndStretches,
            child: Text(
              'Retry',
              style: ZType.sans(14, color: color, weight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  /// Subtle empty-state row when the server has no warmup/stretch for this
  /// workout (e.g. an offline/locally-generated workout).
  Widget _buildWarmupStretchEmpty(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Text(label, style: ZType.sans(13, color: textMuted)),
    );
  }

  /// Build the expanded body sliver for a warmup/stretch section, switching
  /// between loading (skeletons) / error (retry) / empty / data states.
  Widget _buildWarmupStretchSliver(
      List<Map<String, String>> items, Color color, String emptyLabel,
      {required String section}) {
    if (items.isEmpty && _isLoadingWarmupStretch) {
      return SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildWarmupStretchSkeleton(),
          childCount: 3,
        ),
      );
    }
    if (items.isEmpty && _warmupStretchError) {
      return SliverToBoxAdapter(child: _buildWarmupStretchError(color));
    }
    if (items.isEmpty) {
      return SliverToBoxAdapter(child: _buildWarmupStretchEmpty(emptyLabel));
    }
    // Reorderable + tappable: each row opens the full exercise-detail screen on
    // tap and reorders via its drag handle (persisted by _reorderWarmupStretch).
    final rawList = section == 'warmup' ? _warmupData : _stretchData;
    return SliverReorderableList(
      itemCount: items.length,
      onReorder: (oldIndex, newIndex) =>
          _reorderWarmupStretch(section, oldIndex, newIndex),
      proxyDecorator: (child, index, animation) =>
          Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final item = items[index];
        final raw = (rawList != null && index < rawList.length)
            ? rawList[index]
            : null;
        return GestureDetector(
          key: ValueKey('${section}_${item['name'] ?? ''}_$index'),
          behavior: HitTestBehavior.opaque,
          onTap: () => _openTimedExerciseDetail(raw, item),
          child: _buildWarmupStretchItem(item, color, dragIndex: index),
        );
      },
    );
  }

}
