import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/muscle_status.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/scores_provider.dart';
import '../../library/providers/muscle_group_images_provider.dart';
import 'body_score_overlay.dart';
import 'share_strength_sheet.dart';

// Muted gradient palette for score grids
const _gradientStart = Color(0xFFD4726A); // dusty rose
const _gradientMid1 = Color(0xFFD4956A); // soft peach
const _gradientMid2 = Color(0xFFD4C36A); // warm sand
const _gradientEnd = Color(0xFF6AAD7B); // sage green

/// Card showing overall strength score and muscle group breakdown
class StrengthOverviewCard extends ConsumerStatefulWidget {
  final String userId;
  final Function(String muscleGroup)? onTapMuscleGroup;

  const StrengthOverviewCard({
    super.key,
    required this.userId,
    this.onTapMuscleGroup,
  });

  @override
  ConsumerState<StrengthOverviewCard> createState() =>
      _StrengthOverviewCardState();
}

class _StrengthOverviewCardState extends ConsumerState<StrengthOverviewCard> {
  static const _pinnedMusclesKey = 'strength_pinned_muscles';
  static const _viewModeKey = 'strength_view_mode'; // 0=body, 1=muscle
  static const _muscleOrderKey = 'strength_muscle_order';

  bool _readinessExpanded = false;
  Set<String> _pinnedMuscles = {};
  int _viewMode = 0; // 0 = body diagram, 1 = muscle cards
  List<String>? _customMuscleOrder; // persisted drag order

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoresProvider.notifier).loadStrengthScores(userId: widget.userId);
    });
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pinned = prefs.getStringList(_pinnedMusclesKey)?.toSet() ?? {};
      final viewMode = prefs.getInt(_viewModeKey) ?? 0;
      final order = prefs.getStringList(_muscleOrderKey);
      if (mounted) {
        setState(() {
          _pinnedMuscles = pinned;
          _viewMode = viewMode;
          _customMuscleOrder = order;
        });
      }
    } catch (_) {}
  }

  Future<void> _setViewMode(int mode) async {
    setState(() => _viewMode = mode);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_viewModeKey, mode);
    } catch (_) {}
  }

  Future<void> _togglePinnedMuscle(String muscleGroup) async {
    setState(() {
      if (_pinnedMuscles.contains(muscleGroup)) {
        _pinnedMuscles.remove(muscleGroup);
      } else {
        _pinnedMuscles.add(muscleGroup);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_pinnedMusclesKey, _pinnedMuscles.toList());
    } catch (_) {}
  }

  Future<void> _saveMuscleOrder(List<String> order) async {
    setState(() => _customMuscleOrder = order);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_muscleOrderKey, order);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoresState = ref.watch(scoresProvider);
    final strengthScores = scoresState.strengthScores;
    final isLoading = scoresState.isLoading;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with info + refresh buttons
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.fitness_center, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Strength Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _showScoreInfoSheet(context),
                  icon: const Icon(Icons.info_outline),
                  iconSize: 20,
                  tooltip: 'How scores work',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: () {
                      ref.read(scoresProvider.notifier).recalculateStrengthScores(userId: widget.userId);
                    },
                    icon: const Icon(Icons.refresh),
                    iconSize: 20,
                    tooltip: 'Recalculate',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
          ),

          // Readiness strip
          _buildReadinessStrip(context, colorScheme),

          if (isLoading && strengthScores == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (strengthScores == null)
            _buildEmptyState(colorScheme)
          else
            _buildContent(strengthScores, colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Readiness / Fatigue Strip ─────────────────────────────────────

  Widget _buildReadinessStrip(BuildContext context, ColorScheme colorScheme) {
    final scoresState = ref.watch(scoresProvider);
    final hasCheckedIn = scoresState.hasCheckedInToday;
    final readiness = scoresState.todayReadiness ??
        scoresState.overview?.todayReadiness;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: hasCheckedIn && readiness != null
          ? _buildReadinessContent(readiness, colorScheme)
          : _buildCheckInPrompt(context, colorScheme),
    );
  }

  Widget _buildReadinessContent(ReadinessScore readiness, ColorScheme colorScheme) {
    final score = readiness.readinessScore;
    final levelColor = Color(readiness.levelColor);
    final levelName = readiness.readinessLevel[0].toUpperCase() +
        readiness.readinessLevel.substring(1);

    return Column(
      children: [
        // Top row: label + progress bar + score + level + collapse toggle
        GestureDetector(
          onTap: () => setState(() => _readinessExpanded = !_readinessExpanded),
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(
                'Readiness',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: score / 100,
                    minHeight: 6,
                    backgroundColor: colorScheme.outline.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(levelColor),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$score',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  levelName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: levelColor,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              AnimatedRotation(
                turns: _readinessExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Icon(Icons.keyboard_arrow_down, size: 18, color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // Collapsible detail: Hooper chips + navigate arrow
        AnimatedCrossFade(
          firstChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => context.push('/stats/readiness'),
              behavior: HitTestBehavior.opaque,
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        _buildHooperChip('Sleep', readiness.sleepQuality, colorScheme),
                        const SizedBox(width: 6),
                        _buildHooperChip('Fatigue', readiness.fatigueLevel, colorScheme),
                        const SizedBox(width: 6),
                        _buildHooperChip('Stress', readiness.stressLevel, colorScheme),
                        const SizedBox(width: 6),
                        _buildHooperChip('Sore', readiness.muscleSoreness, colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right, size: 16, color: colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: _readinessExpanded
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

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

  // ─── Empty State ───────────────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.fitness_center_outlined,
            size: 48,
            color: colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No Strength Data Yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete workouts with resistance exercises\nto track your strength progress.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Content ──────────────────────────────────────────────────

  Widget _buildContent(AllStrengthScores scores, ColorScheme colorScheme) {
    final levelColor = _getLevelColor(scores.level);

    return Column(
      children: [
        const SizedBox(height: 12),

        // Compact hero row: ring + level + share + toggle
        _buildCompactHeroRow(scores, levelColor, colorScheme),

        const SizedBox(height: 12),

        // Animated content swap
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          child: _viewMode == 0
              ? _buildBodyView(scores, colorScheme)
              : _buildMuscleListView(scores, colorScheme),
        ),

        const SizedBox(height: 16),
      ],
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

  Widget _buildToggleIcon(IconData icon, int mode, ColorScheme colorScheme) {
    final selected = _viewMode == mode;
    return GestureDetector(
      onTap: () => _setViewMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: selected ? colorScheme.primary.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  // ─── Body Diagram View ──────────────────────────────────────────────

  ReadinessScore? _getReadiness() {
    final scoresState = ref.read(scoresProvider);
    return scoresState.todayReadiness ?? scoresState.overview?.todayReadiness;
  }

  Widget _buildBodyView(AllStrengthScores scores, ColorScheme colorScheme) {
    final readiness = _getReadiness();
    final statuses = computeAllMuscleStatuses(
      muscleScores: scores.muscleScores,
      readiness: readiness,
    );

    return Padding(
      key: const ValueKey('body_view'),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BodyScoreOverlay(
            muscleScores: scores.muscleScores,
            muscleStatuses: statuses,
            isDark: Theme.of(context).brightness == Brightness.dark,
            height: 400,
            onTapMuscle: (muscleGroup) => widget.onTapMuscleGroup?.call(muscleGroup),
          ),
          const SizedBox(height: 8),
          _buildBodyLegend(scores, colorScheme),
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
              'Long press to reorder \u00B7 Tap pin to keep on top',
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
              return ReorderableDragStartListener(
                key: ValueKey(muscle.muscleGroup),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _buildMuscleCard(muscle, colorScheme, status: statuses[muscle.muscleGroup]),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  List<StrengthScoreData> _getOrderedMuscles(AllStrengthScores scores) {
    final muscles = List<StrengthScoreData>.from(scores.sortedMuscleScores);

    // Apply custom order if available
    if (_customMuscleOrder != null && _customMuscleOrder!.isNotEmpty) {
      muscles.sort((a, b) {
        final aIdx = _customMuscleOrder!.indexOf(a.muscleGroup);
        final bIdx = _customMuscleOrder!.indexOf(b.muscleGroup);
        // Muscles not in custom order go to end
        final aPos = aIdx >= 0 ? aIdx : 999;
        final bPos = bIdx >= 0 ? bIdx : 999;
        return aPos.compareTo(bPos);
      });
    }

    // Float pinned muscles to top
    final pinned = muscles.where((m) => _pinnedMuscles.contains(m.muscleGroup)).toList();
    final unpinned = muscles.where((m) => !_pinnedMuscles.contains(m.muscleGroup)).toList();
    return [...pinned, ...unpinned];
  }

  // ─── Muscle Card with Score Grid ───────────────────────────────────

  Widget _buildMuscleCard(StrengthScoreData muscle, ColorScheme colorScheme, {MuscleStatus? status}) {
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
            // Right: pin button
            const SizedBox(width: 6),
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
          ],
        ),
      ),
    );
  }

  Widget _buildMuscleStatusBar(MuscleStatus status, ColorScheme colorScheme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (i) {
            return Container(
              width: 6,
              height: 4,
              margin: EdgeInsets.only(left: i > 0 ? 1.5 : 0),
              decoration: BoxDecoration(
                color: i < status.filledSegments
                    ? status.color
                    : colorScheme.outline.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(1.5),
              ),
            );
          }),
        ),
        const SizedBox(height: 2),
        Text(
          status.label,
          style: TextStyle(
            fontSize: 8,
            color: status.color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildImageFallback(String displayName, int score, bool isDark) {
    final color = _scoreOverlayColor(score);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0] : '?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreGridWithOverlay(int score, bool isDark) {
    return Stack(
      children: [
        _buildScoreGrid(score, isDark),
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '$score',
            style: TextStyle(
              fontSize: 14 + (score / 100 * 14),
              fontWeight: FontWeight.bold,
              color: _scoreOverlayColor(score),
              shadows: [
                Shadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.7)
                      : Colors.white.withValues(alpha: 0.8),
                  blurRadius: 4,
                ),
                Shadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
      ],
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

  // ─── Color Helpers ─────────────────────────────────────────────────

  Color _boxColor(int boxIndex, int filledCount) {
    if (filledCount <= 0) return Colors.transparent;
    final t = boxIndex / filledCount;
    if (t < 0.33) return Color.lerp(_gradientStart, _gradientMid1, t / 0.33)!;
    if (t < 0.66) return Color.lerp(_gradientMid1, _gradientMid2, (t - 0.33) / 0.33)!;
    return Color.lerp(_gradientMid2, _gradientEnd, (t - 0.66) / 0.34)!;
  }

  Color _scoreOverlayColor(int score) {
    if (score >= 80) return const Color(0xFF4A8B5C); // deep sage
    if (score >= 60) return const Color(0xFF6AAD7B); // sage green
    if (score >= 45) return const Color(0xFFD4C36A); // warm sand
    if (score >= 25) return const Color(0xFFD4956A); // soft peach
    return const Color(0xFFD4726A); // dusty rose
  }

  // ─── Score Info Bottom Sheet ────────────────────────────────────────

  void _showScoreInfoSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
        return SafeArea(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'How Strength Scores Work',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Your strength score (0-100) measures how much you can lift relative to your bodyweight, compared to established standards.',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  'Score is calculated from your best set (weight x reps) for each muscle group in the last 90 days. Higher bodyweight ratio = higher score.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  'Levels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                _buildLevelRow('Beginner', '0-24', '< 0.75x bodyweight', const Color(0xFF9E9E9E), colorScheme),
                _buildLevelRow('Novice', '25-49', '0.75-1.25x bodyweight', const Color(0xFFFF9800), colorScheme),
                _buildLevelRow('Intermediate', '50-69', '1.25-1.5x bodyweight', const Color(0xFF4CAF50), colorScheme),
                _buildLevelRow('Advanced', '70-89', '1.5-2x bodyweight', const Color(0xFF2196F3), colorScheme),
                _buildLevelRow('Elite', '90-100', '> 2x bodyweight', const Color(0xFF9C27B0), colorScheme),

                const SizedBox(height: 16),

                Text(
                  'Overall Score (Hero Ring)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'The ring displays a weighted average of all your muscle group scores. 1RM is estimated using the Brzycki/Epley/Lombardi formula average from your best logged set in the last 90 days.',
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your overall fitness score is weighted:\nStrength 40% + Consistency 30% + Nutrition 20% + Readiness 10%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  'Scores update automatically after each workout. Only tracked resistance exercises count \u2014 imported cardio workouts don\'t affect scores.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Training Status section
                Text(
                  'Training Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                ...MuscleStatus.values.map((status) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: status.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: Text(
                          status.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          status.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 20),

                // Volume Guidelines section
                Text(
                  'Volume Guidelines (sets/week)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Table header
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          'Muscle',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Min',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Optimal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          'Max',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                // Table rows
                ...volumeGuidelinesTable.map((row) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(
                          row.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${row.mev}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          row.mavRange,
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(
                        width: 40,
                        child: Text(
                          '${row.mrv}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                )),

                const SizedBox(height: 12),
                Text(
                  'Values are for intermediate lifters and adjust automatically based on your training level. Status also factors in your readiness check-in.',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        );
          },
        );
      },
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

  // ─── Color Helpers ─────────────────────────────────────────────────

  Color _getLevelColor(StrengthLevel level) {
    switch (level) {
      case StrengthLevel.elite:
        return const Color(0xFF9C27B0);
      case StrengthLevel.advanced:
        return const Color(0xFF2196F3);
      case StrengthLevel.intermediate:
        return const Color(0xFF4CAF50);
      case StrengthLevel.novice:
        return const Color(0xFFFF9800);
      case StrengthLevel.beginner:
        return const Color(0xFF9E9E9E);
    }
  }

}
