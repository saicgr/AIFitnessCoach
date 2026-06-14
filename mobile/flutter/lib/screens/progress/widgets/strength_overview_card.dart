import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../data/models/muscle_status.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/gym_progress_filter_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../library/providers/muscle_group_images_provider.dart';
import 'body_score_overlay.dart';
import 'gym_progress_filter.dart';
import 'share_strength_sheet.dart';
import '../../../widgets/glass_sheet.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../widgets/design_system/zealova.dart';

import '../../../l10n/generated/app_localizations.dart';
part 'strength_overview_card_ui.dart';


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

  static const _gymSurfaceKey = 'strength_overview';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Select just the slices read here — avoids rebuilds on unrelated
    // scores mutations (readiness, PRs, nutrition).
    final (combinedStrengthScores, combinedLoading) = ref.watch(
      scoresProvider.select((s) => (s.strengthScores, s.isLoading)),
    );

    // When a specific gym is selected, read the gym-filtered strength score so
    // the score stops bouncing on gym switch. "All gyms"/unresolved falls back
    // to the combined scoresProvider exactly as before.
    final gymSelection = ref.watch(gymProgressFilterProvider(_gymSurfaceKey));
    final gymScoped = !gymSelection.isAllGyms && gymSelection.gymProfileId != null;
    final gymScoresAsync = gymScoped
        ? ref.watch(gymStrengthScoresProvider(GymStrengthScoresArgs(
            userId: widget.userId,
            gymProfileId: gymSelection.gymProfileId,
          )))
        : null;

    final AllStrengthScores? strengthScores =
        gymScoped ? gymScoresAsync?.valueOrNull : combinedStrengthScores;
    final bool isLoading = gymScoped
        ? (gymScoresAsync?.isLoading ?? false)
        : combinedLoading;

    final tc = ThemeColors.of(context);

    return ZealovaCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — Barlow section kicker + info / refresh affordances.
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
            child: Row(
              children: [
                Expanded(
                  child: ZealovaSectionKicker(
                    AppLocalizations.of(context).strengthOverviewCardStrengthScore,
                  ),
                ),
                IconButton(
                  onPressed: () => _showScoreInfoSheet(context),
                  icon: const Icon(Icons.info_outline),
                  iconSize: 20,
                  color: tc.textMuted,
                  tooltip: AppLocalizations.of(context).strengthOverviewCardHowScoresWork,
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
                    color: tc.textMuted,
                    tooltip: AppLocalizations.of(context).strengthOverviewCardRecalculate,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                  ),
              ],
            ),
          ),

          // Compact gym selector — hides itself when ≤1 gym. Selecting a gym
          // re-reads the strength score scoped to that gym.
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: GymProgressFilter(surfaceKey: _gymSurfaceKey),
          ),

          if (isLoading && strengthScores == null)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (strengthScores == null)
            _buildEmptyState(colorScheme, gymScoped: gymScoped)
          else
            _buildContent(strengthScores, colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }

  // ─── Empty State ───────────────────────────────────────────────────

  Widget _buildEmptyState(ColorScheme colorScheme, {bool gymScoped = false}) {
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
            gymScoped
                ? 'Not enough data at this gym'
                : AppLocalizations.of(context).strengthOverviewCardNoStrengthDataYet,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            gymScoped
                ? 'Log a few weighted sets at this gym, or switch to "All gyms".'
                : AppLocalizations.of(context).strengthOverviewCardCompleteWorkoutsWithResista,
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
    final tc = ThemeColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Hero Anton numeral + Barlow delta line + share/toggle row.
        _buildHeroNumeralRow(scores, levelColor, colorScheme),

        const SizedBox(height: 14),

        // PUSH / PULL / LEGS style sub-scores on hairline bars (.pg-hb).
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildSubScoreBars(scores, tc),
        ),

        const SizedBox(height: 14),

        // Animated content swap (body diagram / muscle list)
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

  // ─── Color Helpers ─────────────────────────────────────────────────

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

    showGlassSheet<void>(
      context: context,
      builder: (context) {
        return GlassSheet(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  AppLocalizations.of(context).strengthOverviewCardHowStrengthScoresWork,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context).strengthOverviewCardYourStrengthScore0,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  AppLocalizations.of(context).strengthOverviewCardScoreIsCalculatedFrom,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context).strengthOverviewCardLevels,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                _buildLevelRow('Beginner', '0-24', 'Building your base', const Color(0xFF9E9E9E), colorScheme),
                _buildLevelRow('Novice', '25-49', 'Solid foundation', const Color(0xFFFF9800), colorScheme),
                _buildLevelRow('Intermediate', '50-69', 'Trained and consistent', const Color(0xFF4CAF50), colorScheme),
                _buildLevelRow('Advanced', '70-89', 'Strong and well-developed', const Color(0xFF2196F3), colorScheme),
                _buildLevelRow('Elite', '90-100', 'Top-tier strength', const Color(0xFF9C27B0), colorScheme),

                const SizedBox(height: 16),

                // FEATURE 4: composite-score breakdown. Replaces the old single
                // bodyweight-ratio explainer — the score now blends four signals.
                Text(
                  'What goes into your score',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                _buildFactorRow(
                  'Strength', '60%',
                  'How much you lift relative to your bodyweight, machine-aware, with a bodyweight model for unweighted moves.',
                  colorScheme,
                ),
                _buildFactorRow(
                  'Volume', '25%',
                  'Your weekly working sets per muscle vs. evidence-based MEV/MAV/MRV landmarks.',
                  colorScheme,
                ),
                _buildFactorRow(
                  'Consistency', '15%',
                  'How often and how recently you have trained the muscle over the last 28 days.',
                  colorScheme,
                ),
                _buildFactorRow(
                  'Bodyweight context', '+/-5',
                  'A small nudge when strength rises while your bodyweight moves (recomposition).',
                  colorScheme,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Calibrating',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB07800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Shown as an approximate range (like ~62) for the first couple of weeks while we gather enough sessions to lock in a reliable number.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context).strengthOverviewCardOverallScoreHeroRing,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).strengthOverviewCardTheRingDisplaysA,
                  style: TextStyle(
                    fontSize: 13,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).strengthOverviewCardYourOverallFitnessScore,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  AppLocalizations.of(context).strengthOverviewCardScoresUpdateAutomaticallyAf,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 20),

                // Training Status section
                Text(
                  AppLocalizations.of(context).strengthOverviewCardTrainingStatus,
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
                  AppLocalizations.of(context).strengthOverviewCardVolumeGuidelinesSetsWeek,
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
                          AppLocalizations.of(context).strengthOverviewCardMuscle,
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
                          AppLocalizations.of(context).syncedWorkoutDetailMin,
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
                          AppLocalizations.of(context).strengthOverviewCardOptimal,
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
                          AppLocalizations.of(context).strengthOverviewCardMax,
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
                  AppLocalizations.of(context).strengthOverviewCardValuesAreForIntermediate,
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
