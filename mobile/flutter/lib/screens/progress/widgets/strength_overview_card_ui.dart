part of 'strength_overview_card.dart';

/// FEATURE 4: de-emphasized copy shown when a muscle score ticks DOWN. A score dip is
/// usually a fresh-data or recovery artefact, not a real loss, so we frame it neutrally
/// (>= 4 variants; the surface picks one deterministically per muscle so it doesn't
/// flicker between rebuilds).
const List<String> _dropCopyVariants = <String>[
  'Settling in',
  'Recalibrating',
  'Easing back',
  'Finding its level',
  'Catching its breath',
];

/// UI builder methods extracted from _StrengthOverviewCardState
extension _StrengthOverviewCardStateUI on _StrengthOverviewCardState {

  /// FEATURE 4: build the score-delta / calibrating badge for a muscle tile.
  /// - establishing  -> amber "Calibrating" chip (no caret; the number is approximate)
  /// - gain (>0)     -> green up-caret with +N
  /// - drop (<0)     -> NEUTRAL grey down-caret + de-emphasized copy (variant pool)
  /// - flat / null   -> nothing
  Widget? _buildScoreDeltaBadge(StrengthScoreData muscle, ColorScheme colorScheme) {
    if (muscle.isEstablishing) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: const Color(0xFFFFB300).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(5),
        ),
        child: const Text(
          'Calibrating',
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Color(0xFFB07800),
          ),
        ),
      );
    }

    final change = muscle.scoreChange;
    if (change == null || change == 0) return null;

    if (change > 0) {
      // Gains keep the existing green up-caret with +N.
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.arrow_drop_up, size: 16, color: Color(0xFF4CAF50)),
          Text(
            '+$change',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF4CAF50),
            ),
          ),
        ],
      );
    }

    // Drop: neutral grey caret + soft copy (no red, no minus shaming).
    final neutral = colorScheme.onSurfaceVariant.withValues(alpha: 0.7);
    final copy = _dropCopyVariants[muscle.muscleGroup.hashCode.abs() % _dropCopyVariants.length];
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.arrow_drop_down, size: 16, color: neutral),
        Flexible(
          child: Text(
            copy,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w500,
              color: neutral,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Hero numeral row (Anton score + Barlow delta + share + toggle) ────
  //
  // STATS HUB FRAME 1: the strength score reads as a hero Anton numeral with a
  // small Barlow delta line beside it ("LEVEL · N muscle groups") — not boxed
  // in a ring card.
  Widget _buildHeroNumeralRow(AllStrengthScores scores, Color levelColor, ColorScheme colorScheme) {
    final tc = ThemeColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hero Anton numeral.
          Text(
            '${scores.overallScore}',
            style: ZType.disp(62, color: tc.textPrimary, height: 0.86),
          ),
          const SizedBox(width: 13),
          // Barlow delta line: level (semantic tint) + muscle-group count.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scores.overallLevel.toUpperCase(),
                  style: ZType.lbl(13,
                      color: levelColor,
                      weight: FontWeight.w800,
                      letterSpacing: 1.4),
                ),
                const SizedBox(height: 2),
                Text(
                  AppLocalizations.of(context)
                      .strengthOverviewCardUiMuscleGroups(scores.muscleScores.length),
                  style: ZType.lbl(10.5,
                      color: tc.textMuted,
                      weight: FontWeight.w600,
                      letterSpacing: 0.8),
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
                color: tc.textMuted,
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

  // ─── Sub-score hairline bars (.pg-hb) ──────────────────────────────────
  //
  // Top muscle groups rendered as the v2 .pg-hb row: Barlow uppercase label
  // (left, fixed width) · 4px hairline track with fill · Anton numeral (right).
  // No boxed tiles. The single peak muscle's fill carries the accent.
  Widget _buildSubScoreBars(AllStrengthScores scores, ThemeColors tc) {
    final top = scores.sortedMuscleScores.take(3).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    final peakScore = top.first.strengthScore;

    return Column(
      children: List.generate(top.length, (i) {
        final m = top[i];
        final isPeak = m.strengthScore == peakScore;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(
                  m.muscleGroupDisplayName.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(10,
                      color: tc.textMuted, letterSpacing: 1.8),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: SizedBox(
                    height: 4,
                    child: LinearProgressIndicator(
                      value: (m.strengthScore / 100).clamp(0.0, 1.0),
                      backgroundColor: tc.cardBorder,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isPeak ? tc.accent : tc.textMuted,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              SizedBox(
                width: 30,
                child: Text(
                  '${m.strengthScore}',
                  textAlign: TextAlign.right,
                  style: ZType.disp(15, color: tc.textPrimary),
                ),
              ),
            ],
          ),
        );
      }),
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
                AppLocalizations.of(context).strengthOverviewCardStrengthScore,
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
                    margin: EdgeInsetsDirectional.only(start: i > 0 ? 1 : 0),
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
                AppLocalizations.of(context).strengthOverviewCardTrainingStatus,
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
              AppLocalizations.of(context).strengthOverviewCardDragU2630ToReorder,
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
              final isLast = index == muscles.length - 1;
              return Column(
                key: ValueKey(muscle.muscleGroup),
                children: [
                  _buildMuscleCard(muscle, colorScheme,
                      index: index, status: statuses[muscle.muscleGroup]),
                  if (!isLast) const ZealovaRule(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }


  // ─── Muscle hairline row (.pg-hb derived) ──────────────────────────────
  //
  // STATS HUB: each muscle is a hairline row — thumbnail · Barlow name (+ status
  // bar / calibrating badge) · 4px hairline score track · Anton numeral · pin +
  // drag. No boxed surfaceContainerLow tile; the hairline divider between rows
  // is drawn by the list builder.
  Widget _buildMuscleCard(StrengthScoreData muscle, ColorScheme colorScheme, {required int index, MuscleStatus? status}) {
    final tc = ThemeColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayName = muscle.muscleGroupDisplayName;
    final assetPath = muscleGroupAssets[displayName];
    final score = muscle.strengthScore;
    final isPinned = _pinnedMuscles.contains(muscle.muscleGroup);
    final scoreColor = _scoreOverlayColor(score);
    final numeralLabel = muscle.hasRange ? muscle.rangeLabel : '$score';

    return InkWell(
      onTap: () => widget.onTapMuscleGroup?.call(muscle.muscleGroup),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: assetPath != null
                  ? Image.asset(
                      assetPath,
                      width: 38,
                      height: 38,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildImageFallback(displayName, score, isDark),
                    )
                  : _buildImageFallback(displayName, score, isDark),
            ),
            const SizedBox(width: 11),
            // Name + status bar + delta badge + hairline score track
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: ZType.lbl(12,
                              color: tc.textPrimary,
                              weight: FontWeight.w800,
                              letterSpacing: 1),
                        ),
                      ),
                      if (status != null) ...[
                        const SizedBox(width: 8),
                        _buildMuscleStatusBar(status, colorScheme),
                      ],
                    ],
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: SizedBox(
                      height: 4,
                      child: LinearProgressIndicator(
                        value: (score / 100).clamp(0.0, 1.0),
                        backgroundColor: tc.cardBorder,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(scoreColor),
                      ),
                    ),
                  ),
                  // FEATURE 4: score-delta / calibrating badge.
                  Builder(builder: (_) {
                    final badge = _buildScoreDeltaBadge(muscle, colorScheme);
                    if (badge == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: badge,
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(width: 10),
            // Anton score numeral
            SizedBox(
              width: 34,
              child: Text(
                numeralLabel,
                textAlign: TextAlign.right,
                style: ZType.disp(18, color: tc.textPrimary),
              ),
            ),
            // Right: pin + drag handle
            const SizedBox(width: 6),
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
                      color: isPinned ? tc.accent : tc.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                ReorderableDragStartListener(
                  index: index,
                  child: Icon(
                    Icons.drag_handle,
                    size: 20,
                    color: tc.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
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

  /// FEATURE 4: a "What goes into your score" factor row (label + weight + blurb).
  Widget _buildFactorRow(
    String name,
    String weight,
    String description,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
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
            width: 44,
            child: Text(
              weight,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.primary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
