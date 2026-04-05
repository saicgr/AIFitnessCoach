part of 'strength_overview_card.dart';

/// UI builder methods extracted from _StrengthOverviewCardState
extension _StrengthOverviewCardStateUI on _StrengthOverviewCardState {

  Widget _buildHooperChip(String label, int value, ColorScheme colorScheme) {
    // 1 = best, 7 = worst → color green→red
    final t = ((value - 1) / 6).clamp(0.0, 1.0);
    final chipColor = Color.lerp(
      const Color(0xFF4CAF50), // green
      const Color(0xFFF44336), // red
      t,
    )!;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: chipColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: chipColor,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCheckInPrompt(BuildContext context, ColorScheme colorScheme) {
    return InkWell(
      onTap: () => context.push('/stats/readiness'),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Icon(Icons.self_improvement, size: 20, color: colorScheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'How are you feeling today?',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Check in',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ─── Compact Hero Row (ring + level + share + toggle) ─────────────────

  Widget _buildCompactHeroRow(AllStrengthScores scores, Color levelColor, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Mini circular progress ring with score
          SizedBox(
            width: 44,
            height: 44,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(
                    value: scores.overallScore / 100,
                    strokeWidth: 5,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text(
                  '${scores.overallScore}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Level name + muscle count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scores.overallLevel.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: levelColor,
                  ),
                ),
                Text(
                  '${scores.muscleScores.length} muscle groups',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          // Share button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              ShareStrengthSheet.show(context, ref, scores);
            },
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.ios_share_rounded,
                size: 20,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // View toggle icons
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleIcon(Icons.accessibility_new, 0, colorScheme),
                const SizedBox(width: 2),
                _buildToggleIcon(Icons.view_list_rounded, 1, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBodyLegend(AllStrengthScores scores, ColorScheme colorScheme) {
    final sampleScore = scores.overallScore;
    final sampleColor = _getLevelColor(scores.level);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          // Row 1: score badge + training status mockup + info button
          Row(
            children: [
              // Mini score badge
              Container(
                width: 22,
                height: 14,
                decoration: BoxDecoration(
                  color: sampleColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    '$sampleScore',
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'Strength Score',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              // Mini 5-bar mockup
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  return Container(
                    width: 4,
                    height: 3,
                    margin: EdgeInsets.only(left: i > 0 ? 1 : 0),
                    decoration: BoxDecoration(
                      color: i < 3
                          ? const Color(0xFF22C55E)
                          : colorScheme.outline.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
              const SizedBox(width: 4),
              Text(
                'Training Status',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(
                width: 24,
                height: 24,
                child: IconButton(
                  onPressed: () => _showScoreInfoSheet(context),
                  icon: const Icon(Icons.info_outline),
                  iconSize: 14,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Row 2: all 5 status labels
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: MuscleStatus.values.map((status) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: status.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    status.label,
                    style: TextStyle(
                      fontSize: 10,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  // ─── Muscle Cards List View (Reorderable) ───────────────────────────

  Widget _buildMuscleListView(AllStrengthScores scores, ColorScheme colorScheme) {
    // Sort muscles by custom order if available, else default sort
    final muscles = _getOrderedMuscles(scores);
    final readiness = _getReadiness();
    final statuses = computeAllMuscleStatuses(
      muscleScores: scores.muscleScores,
      readiness: readiness,
    );

    return Padding(
      key: const ValueKey('muscle_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hint text
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Drag \u2630 to reorder \u00B7 Tap pin to keep on top',
              style: TextStyle(fontSize: 10, color: colorScheme.onSurfaceVariant),
            ),
          ),
          // Reorderable list
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(animation.value);
                  final elevation = 4.0 * t;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.transparent,
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemCount: muscles.length,
            onReorder: (oldIndex, newIndex) {
              if (newIndex > oldIndex) newIndex--;
              final order = muscles.map((m) => m.muscleGroup).toList();
              final item = order.removeAt(oldIndex);
              order.insert(newIndex, item);
              _saveMuscleOrder(order);
            },
            itemBuilder: (context, index) {
              final muscle = muscles[index];
              return Padding(
                key: ValueKey(muscle.muscleGroup),
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildMuscleCard(muscle, colorScheme, index: index, status: statuses[muscle.muscleGroup]),
              );
            },
          ),
        ],
      ),
    );
  }


  // ─── Muscle Card with Score Grid ───────────────────────────────────

  Widget _buildMuscleCard(StrengthScoreData muscle, ColorScheme colorScheme, {required int index, MuscleStatus? status}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = muscle.muscleGroupDisplayName;
    final assetPath = muscleGroupAssets[displayName];
    final score = muscle.strengthScore;
    final isPinned = _pinnedMuscles.contains(muscle.muscleGroup);

    return InkWell(
      onTap: () => widget.onTapMuscleGroup?.call(muscle.muscleGroup),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Left: image + name + status bar
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: assetPath != null
                      ? Image.asset(
                          assetPath,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _buildImageFallback(displayName, score, isDark),
                        )
                      : _buildImageFallback(displayName, score, isDark),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  width: 48,
                  child: Text(
                    displayName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (status != null) ...[
                  const SizedBox(height: 3),
                  _buildMuscleStatusBar(status, colorScheme),
                ],
              ],
            ),
            const SizedBox(width: 10),
            // Center: score grid
            Expanded(
              child: _buildScoreGridWithOverlay(score, isDark),
            ),
            // Right: pin + drag handle
            const SizedBox(width: 4),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => _togglePinnedMuscle(muscle.muscleGroup),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                      size: 16,
                      color: isPinned ? colorScheme.primary : colorScheme.outline.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildScoreGrid(int score, bool isDark) {
    final emptyColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.1);
    const rows = 5;

    return LayoutBuilder(builder: (context, constraints) {
      const boxSize = 8.0;
      const spacing = 2.0;
      final cols = (constraints.maxWidth / (boxSize + spacing)).floor();
      final totalBoxes = rows * cols;
      final filledCount = (score / 100 * totalBoxes).round().clamp(0, totalBoxes);

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(rows, (row) {
          return Row(
            children: List.generate(cols, (col) {
              final index = col * rows + row; // column-first fill
              final filled = index < filledCount;
              return Container(
                width: boxSize,
                height: boxSize,
                margin: const EdgeInsets.all(spacing / 2),
                decoration: BoxDecoration(
                  color: filled
                      ? _boxColor(index, filledCount)
                      : emptyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          );
        }),
      );
    });
  }


  Widget _buildLevelRow(String name, String range, String description, Color color, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(
            width: 48,
            child: Text(
              range,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
