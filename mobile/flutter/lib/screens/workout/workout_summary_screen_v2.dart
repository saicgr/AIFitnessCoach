import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/api_constants.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/services/haptic_service.dart';
import '../../data/models/workout.dart';
import '../../data/repositories/workout_repository.dart';
import '../../shareables/adapters/workout_adapter.dart';
import '../../shareables/shareable_sheet.dart';
import '../../widgets/design_system/zealova.dart';
import '../../widgets/glass_back_button.dart';
import '../../widgets/lottie_animations.dart';
import 'workout_detail_screen.dart';
import 'workout_summary_general.dart';
import 'widgets/save_to_library_sheet.dart';
import 'widgets/summary_floating_pill.dart';

import '../../l10n/generated/app_localizations.dart';
/// Pill selector state for [WorkoutSummaryScreenV2]. Kept as an enum (rather
/// than a raw int) so callers — including the `?tab=` query param on
/// `/workout-summary/:id` — can deep-link to a specific pane without knowing
/// the pill's underlying index. Declaration order matches the pill layout
/// (Plan, Summary) so the built-in `Enum.index` IS the pill index.
///
/// The legacy 3-pane layout (Detail/Summary/Advanced) was merged into 2 panes
/// — "Plan" (the former Detail) and one rich "Summary" scroll that folds in the
/// worthwhile Advanced analytics. `fromQuery` keeps the old `?tab=` deep links
/// working: `detail`→plan, and `summary`/`general`/`advanced`→summary.
enum WorkoutSummaryTab {
  plan,
  summary;

  /// Parse the `?tab=` query param. Unknown / missing values resolve to
  /// [plan] so the existing "open the workout detail" entry points keep
  /// their behaviour.
  static WorkoutSummaryTab fromQuery(String? raw) {
    switch ((raw ?? '').toLowerCase()) {
      case 'summary':
      case 'general':
      case 'advanced': // merged into Summary — keep old deep links alive
        return WorkoutSummaryTab.summary;
      case 'plan':
      case 'detail':
      default:
        return WorkoutSummaryTab.plan;
    }
  }
}

class WorkoutSummaryScreenV2 extends ConsumerStatefulWidget {
  final String workoutId;
  final WorkoutSummaryTab initialTab;

  const WorkoutSummaryScreenV2({
    super.key,
    required this.workoutId,
    this.initialTab = WorkoutSummaryTab.plan,
  });

  @override
  ConsumerState<WorkoutSummaryScreenV2> createState() =>
      _WorkoutSummaryScreenV2State();
}

class _WorkoutSummaryScreenV2State
    extends ConsumerState<WorkoutSummaryScreenV2> {
  late int _selectedView = widget.initialTab.index; // 0 = Plan, 1 = Summary
  WorkoutSummaryResponse? _summaryData;
  Map<String, dynamic>? _metadata;
  Workout? _parsedWorkout;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchData();

    ref.read(posthogServiceProvider).capture(
      eventName: 'workout_summary_v2_viewed',
      properties: {'workout_id': widget.workoutId},
    );
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repo = ref.read(workoutRepositoryProvider);

      // Hard ceiling so a wedged request / slow parse can never leave the
      // screen on its loading spinner forever (the "summary takes super long to
      // load" half of the report). On timeout this throws TimeoutException,
      // which the catch below turns into the existing retry error state.
      final results = await Future.wait([
        repo.getWorkoutCompletionSummary(widget.workoutId),
        repo.getWorkoutLogByWorkoutId(widget.workoutId),
      ]).timeout(ApiConstants.receiveTimeout);

      if (!mounted) return;

      // Parse metadata — the endpoint flattens metadata fields to top level
      final rawLog = results[1] as Map<String, dynamic>?;

      // Parse workout object from summary data for the Detail tab
      Workout? parsed;
      final summaryResult = results[0] as WorkoutSummaryResponse?;
      if (summaryResult != null) {
        try {
          parsed = Workout.fromJson(summaryResult.workout);
        } catch (e) {
          debugPrint('Failed to parse workout from summary: $e');
        }
      }

      setState(() {
        _summaryData = summaryResult;
        _metadata = rawLog;
        _parsedWorkout = parsed;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching workout summary v2 data: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load workout summary. Please try again.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider);
    final accentColor = accent.getColor(isDark);

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      body: _buildBody(isDark, accentColor),
    );
  }

  Widget _buildBody(bool isDark, Color accentColor) {
    if (_isLoading) {
      return _buildLoadingState(isDark);
    }

    if (_error != null) {
      return _buildErrorState(isDark, accentColor);
    }

    final topPadding = MediaQuery.of(context).padding.top;

    // Plan tab renders the full WorkoutDetailScreen (its own Scaffold + back
    // button + favorite/save/overflow actions). Summary tab renders inside
    // this screen's Scaffold with its own header action cluster.
    if (_selectedView == 0) {
      return Stack(
        children: [
          WorkoutDetailScreen(
            key: const ValueKey('detail'),
            workoutId: widget.workoutId,
            initialWorkout: _parsedWorkout,
            isSummaryMode: true,
          ),

          // Floating pill at bottom
          SummaryFloatingPill(
            selectedIndex: _selectedView,
            onChanged: (i) => setState(() => _selectedView = i),
          ),
        ],
      );
    }

    return Stack(
      children: [
        // Force Stack to fill the screen so the pill anchors to the real bottom
        const SizedBox.expand(),

        // The single rich Summary scroll. Positioned.fill so its
        // SingleChildScrollView gets the full Stack width.
        Positioned.fill(
          child: WorkoutSummaryGeneral(
            key: const ValueKey('summary'),
            data: _summaryData,
            metadata: _metadata,
            topPadding: topPadding,
          ),
        ),

        // Floating back button (Plan tab has its own).
        PositionedDirectional(
          top: topPadding + 8,
          start: 16,
          child: const GlassBackButton(),
        ),

        // Header action cluster — Share / Favorite / Save / Redo.
        PositionedDirectional(
          top: topPadding + 8,
          end: 12,
          child: _SummaryHeaderActions(
            workoutId: widget.workoutId,
            workout: _parsedWorkout,
            summary: _summaryData,
            metadata: _metadata,
          ),
        ),

        // Floating pill at bottom
        SummaryFloatingPill(
          selectedIndex: _selectedView,
          onChanged: (i) => setState(() => _selectedView = i),
        ),
      ],
    );
  }

  Widget _buildLoadingState(bool isDark) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const LottieLoading(size: 80),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).workoutSummaryScreenLoadingSummary,
            style: ZType.lbl(
              12,
              color: tc.textMuted,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark, Color accentColor) {
    final tc = ThemeColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.cardBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.error_outline,
                size: 26,
                color: tc.textMuted,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              AppLocalizations.of(context).workoutSummaryScreenFailedToLoadSummary
                  .toUpperCase(),
              textAlign: TextAlign.center,
              style: ZType.disp(24, color: tc.textPrimary),
            ),
            const SizedBox(height: 10),
            Text(
              _error ?? AppLocalizations.of(context).workoutSummaryScreenPleaseCheckYourConnection,
              textAlign: TextAlign.center,
              style: ZType.ser(15, color: tc.textSecondary),
            ),
            const SizedBox(height: 28),
            ZealovaButton(
              label: AppLocalizations.of(context).buttonRetry,
              onTap: _fetchData,
              trailingIcon: Icons.refresh,
              expand: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HEADER ACTIONS — Share / Favorite / Save / Redo
//
// The completed-workout Summary header previously had only a back button, so
// the user "could not share / favorite / save / redo after finishing". This
// cluster wires the actions that already exist elsewhere (Share from the legacy
// summary screen, Favorite + Save from the workout detail screen) plus a new
// Redo that re-runs the same plan.
// ═══════════════════════════════════════════════════════════════════════════

class _SummaryHeaderActions extends ConsumerStatefulWidget {
  final String workoutId;
  final Workout? workout;
  final WorkoutSummaryResponse? summary;
  final Map<String, dynamic>? metadata;

  const _SummaryHeaderActions({
    required this.workoutId,
    required this.workout,
    required this.summary,
    required this.metadata,
  });

  @override
  ConsumerState<_SummaryHeaderActions> createState() =>
      _SummaryHeaderActionsState();
}

class _SummaryHeaderActionsState extends ConsumerState<_SummaryHeaderActions> {
  late bool _isFavorite = widget.workout?.isFavorite ?? false;

  Future<void> _share() async {
    final workout = widget.workout;
    final summary = widget.summary;
    if (workout == null || summary == null) {
      _toast(AppLocalizations.of(context).workoutSummaryNoWorkoutDataTo);
      return;
    }
    HapticService.selection();
    final shareable = WorkoutAdapter.fromCompletion(
      ref: ref,
      workoutName: workout.name ?? 'Workout',
      durationSeconds: (workout.durationMinutes ?? 0) * 60,
      plannedExercises: workout.exercises,
      loggedSets: summary.setLogs,
      setsJsonRaw: widget.metadata?['sets_json'],
      calories: workout.estimatedCalories,
    );
    if (!mounted) return;
    if (shareable == null) {
      _toast(AppLocalizations.of(context).workoutSummaryNoWorkoutDataTo);
      return;
    }
    await ShareableSheet.show(context, data: shareable);
  }

  Future<void> _toggleFavorite() async {
    HapticService.selection();
    final next = !_isFavorite;
    setState(() => _isFavorite = next); // optimistic
    try {
      await ref
          .read(workoutRepositoryProvider)
          .toggleWorkoutFavorite(widget.workoutId);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isFavorite = !next); // rollback
      _toast('Could not update favorite');
    }
  }

  Future<void> _save() async {
    final name = widget.workout?.name ?? 'Workout';
    HapticService.selection();
    try {
      final saved = await showSaveToLibrarySheet(
        context,
        workoutId: widget.workoutId,
        defaultName: 'Copy of $name',
      );
      if (!mounted) return;
      if (saved) _toast('Saved to your library');
    } catch (e) {
      if (mounted) _toast('Could not save: $e');
    }
  }

  void _redo() {
    final workout = widget.workout;
    if (workout == null) return;
    HapticService.medium();
    context.push('/active-workout', extra: workout.cloneForRedo());
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _GlassActionButton(
          icon: Icons.ios_share_rounded,
          tooltip: 'Share',
          isDark: isDark,
          onTap: _share,
        ),
        const SizedBox(width: 8),
        _GlassActionButton(
          icon: _isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          tooltip: 'Favorite',
          isDark: isDark,
          color: _isFavorite ? const Color(0xFFFF4D6D) : null,
          onTap: _toggleFavorite,
        ),
        const SizedBox(width: 8),
        _GlassActionButton(
          icon: Icons.bookmark_add_outlined,
          tooltip: 'Save to library',
          isDark: isDark,
          onTap: _save,
        ),
        const SizedBox(width: 8),
        _GlassActionButton(
          icon: Icons.replay_rounded,
          tooltip: 'Redo workout',
          isDark: isDark,
          color: accent,
          onTap: _redo,
        ),
      ],
    );
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool isDark;
  final Color? color;
  final VoidCallback onTap;

  const _GlassActionButton({
    required this.icon,
    required this.tooltip,
    required this.isDark,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark
        ? AppColors.elevated.withValues(alpha: 0.8)
        : Colors.white.withValues(alpha: 0.85);
    final border = isDark
        ? AppColors.cardBorder.withValues(alpha: 0.6)
        : Colors.black.withValues(alpha: 0.08);
    final fg = color ?? (isDark ? AppColors.textPrimary : Colors.black87);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
              border: Border.all(color: border),
            ),
            child: Icon(icon, size: 19, color: fg),
          ),
        ),
      ),
    );
  }
}
