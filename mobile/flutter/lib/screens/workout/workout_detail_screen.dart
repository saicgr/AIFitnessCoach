import 'dart:async';
import 'dart:math' show max;
import 'dart:ui' show ImageFilter;
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../widgets/app_dialog.dart';
import '../../widgets/exercise_image.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/program_badge.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/animations/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/services/posthog_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../widgets/design_system/zealova.dart';
import '../../core/providers/user_provider.dart';
import '../../core/providers/warmup_duration_provider.dart';
import '../../core/utils/difficulty_utils.dart';
import '../../core/utils/equipment_display.dart';
import '../../data/models/workout.dart';
import '../../data/models/exercise.dart';
import '../../data/models/workout_generation_params.dart';
import '../../data/models/coach_persona.dart';
import '../ai_settings/ai_settings_screen.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/models/sauna_log.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/sauna_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../data/services/api_client.dart' show apiClientProvider;
import '../../core/constants/api_constants.dart';
import '../../data/models/workout_studio_models.dart';
import '../../data/providers/workout_studio_providers.dart';
import 'customization_studio_sheet.dart';
import 'widgets/save_to_library_sheet.dart';
import 'widgets/summary_floating_pill.dart';
import '../../data/services/image_url_cache.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'widgets/sauna_dialog.dart';
import '../home/widgets/components/training_program_selector.dart';
import 'widgets/exercise_swap_sheet.dart';
import 'widgets/exercise_add_sheet.dart';
import 'widgets/expanded_exercise_card.dart';
import 'widgets/superset_indicator.dart';
import 'widgets/superset_reorder_sheet.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/branding.dart';
import '../../data/services/share_service.dart';
import '../../widgets/fasting_training_warning.dart';
import '../../widgets/coach_avatar.dart';
import '../../widgets/fading_chip_row.dart';
import '../../models/equipment_item.dart';
import '../../core/providers/environment_equipment_provider.dart';
import 'widgets/edit_workout_equipment_sheet.dart';
import '../../core/providers/avoided_provider.dart';
import '../../core/providers/pending_workout_mutations_provider.dart';
import '../../data/providers/today_workout_provider.dart';
import 'widgets/workout_detail_helpers.dart';
import 'widgets/workout_detail_ai_insights.dart';
import 'schedule_date_utils.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/theme/accent_color_provider.dart';
part 'workout_detail_screen_ui.dart';

part 'workout_detail_screen_ui_1.dart';
part 'workout_detail_screen_ui_2.dart';
part 'workout_detail_screen_warmup.dart';


/// Merge optimistic pending entries into the main-section exercise list.
///
/// Dedupes by name so that when the silent refresh brings the canonical
/// server row in, the optimistic copy drops cleanly. Preserves the order:
/// real rows first, optimistic extras appended at the end where the user
/// expects newly-added exercises to land.
List<WorkoutExercise> _mergeOptimisticMainExercises(
  List<WorkoutExercise> base,
  List<Map<String, dynamic>> pending,
) {
  if (pending.isEmpty) return base;
  final baseNames = base
      .map((e) => (e.nameValue ?? '').toLowerCase())
      .where((n) => n.isNotEmpty)
      .toSet();
  final extras = <WorkoutExercise>[];
  for (final raw in pending) {
    final name = raw['name']?.toString().toLowerCase();
    if (name == null || baseNames.contains(name)) continue;
    try {
      extras.add(WorkoutExercise.fromJson(Map<String, dynamic>.from(raw)));
    } catch (_) {
      // If the optimistic payload is malformed, skip silently — the real
      // row will arrive via the silent refresh shortly.
    }
  }
  if (extras.isEmpty) return base;
  return [...base, ...extras];
}


class WorkoutDetailScreen extends ConsumerStatefulWidget {
  final String workoutId;
  /// Optional pre-loaded workout to display immediately while refreshing.
  final Workout? initialWorkout;
  /// When true, hides the coach avatar + "Let's Go" FAB (used inside summary).
  final bool isSummaryMode;

  const WorkoutDetailScreen({super.key, required this.workoutId, this.initialWorkout, this.isSummaryMode = false});

  @override
  ConsumerState<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends ConsumerState<WorkoutDetailScreen>
    with WorkoutDetailAIInsightsMixin {
  Workout? _workout;
  bool _isLoading = true;
  String? _error;
  // Surfaced inline (banner) when a refresh fails but we still have a
  // cached workout to show. Lets the user keep working without being
  // popped off the screen. See _loadWorkout 404 path.
  String? _refreshError;
  String? _workoutSummary;
  bool _isLoadingSummary = true;  // Start as true to show loading immediately
  bool _isWarmupExpanded = false;  // For warmup section — collapsed by default (user pref)
  bool _isStretchesExpanded = false;  // For stretches section
  bool _isChallengeExpanded = false;  // For challenge exercise section
  bool _isEquipmentExpanded = false;  // For equipment section
  String? _trainingSplit;  // Training program type from user preferences
  WorkoutGenerationParams? _generationParams;  // AI reasoning and parameters
  bool _isLoadingParams = false;  // Loading state for generation params
  bool _isAIReasoningExpanded = false;  // For AI reasoning section
  bool _isMoreInfoExpanded = false;  // For More Info section (extra details)
  bool? _useKgOverride;  // Local override for kg/lbs toggle
  int? _pendingSupersetIndex;  // Index of exercise waiting to be paired via menu

  // Equipment edit revert state
  List<WorkoutExercise>? _originalExercises;  // Snapshot before equipment changes
  bool _hasEquipmentModifications = false;  // Track if equipment was modified

  // Warmup/stretch exercises loaded from API
  List<Map<String, dynamic>>? _warmupData;
  List<Map<String, dynamic>>? _stretchData;
  // Loading / error state for the warmup+stretch fetch. Drives skeletons and a
  // retry affordance so we never fall back to a misleading hardcoded list when
  // the real per-workout data hasn't loaded yet (see _loadWarmupAndStretches).
  bool _isLoadingWarmupStretch = false;
  bool _warmupStretchError = false;

  // Auto-save state for exercise modifications
  Timer? _autoSaveTimer;
  bool _isSaving = false;
  bool _isFavorite = false;

  // Google-Health-parity action state.
  // _thumbs: 1 = up, -1 = down, 0 = none. Local-optimistic; synced via
  // workoutStudioServiceProvider.sendThumbs().
  int _thumbs = 0;
  // Reflects a locally-applied "Mark as done" so the UI updates instantly
  // even before _loadWorkout() brings the canonical completed row back.
  bool _markedDoneLocal = false;
  // Guards against double-firing async actions while one is in flight.
  bool _actionInFlight = false;

  // Sauna post-workout logging
  SaunaLog? _saunaLog;
  bool _isLoadingSauna = false;
  bool _secondaryLoadsStarted = false;

  @override
  void initState() {
    super.initState();
    // If we have an initial workout, show it immediately (no loading spinner)
    if (widget.initialWorkout != null) {
      _workout = widget.initialWorkout;
      _isFavorite = widget.initialWorkout!.isFavorite ?? false;
      _isLoading = false;
      // Fire secondary loads immediately since workout data is already available
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startSecondaryLoads();
      });
    }
    _loadWorkout();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    // Use dynamic accent color from provider
    final accentColor = ref.colors(context).accent;
    // Use paddingOf to only rebuild on padding changes, not all MediaQuery changes
    final safePadding = MediaQuery.paddingOf(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: accentColor),
        ),
      );
    }

    if (_error != null || _workout == null) {
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),  // accent-allowlist: error/destructive — must stay red
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context).workoutDetailFailedToLoadWorkout,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: textMuted,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _loadWorkout,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: Text(AppLocalizations.of(context).workoutStateCardsTryAgain),
                    ),
                  ],
                ),
              ),
            ),
            // Floating pill back button — matches success-state styling
            Positioned(
              top: safePadding.top + 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  HapticService.light();
                  if (context.canPop()) context.pop();
                },
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1C1C1E) : elevatedColor,
                    borderRadius: BorderRadius.circular(22),
                    border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? Colors.white : AppColorsLight.textPrimary,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final workout = _workout!;

    // Watch the pending-mutations provider so optimistic entries added from
    // elsewhere (e.g. tapping a staple chip) appear immediately, and so we
    // know when the API reconciliation has cleared them — that's our cue to
    // pull the canonical data in from the server.
    final pendingState = ref.watch(pendingWorkoutMutationsProvider);
    final pendingMain =
        pendingState.addsFor(workoutId: workout.id ?? '', section: 'main');
    // When pending mutations just cleared (server confirmed the write),
    // reload the workout + warmup/stretch data so the detail screen shows
    // the canonical row. Guarded with a small microtask so we don't call
    // setState during build.
    ref.listen<PendingWorkoutMutationsState>(pendingWorkoutMutationsProvider,
        (prev, next) {
      final wid = _workout?.id;
      if (wid == null) return;
      bool hadBefore(String section) =>
          (prev?.addsFor(workoutId: wid, section: section).isNotEmpty) ?? false;
      bool hasNow(String section) =>
          next.addsFor(workoutId: wid, section: section).isNotEmpty;
      final clearedMain = hadBefore('main') && !hasNow('main');
      final clearedWarmup = hadBefore('warmup') && !hasNow('warmup');
      final clearedStretches =
          hadBefore('stretches') && !hasNow('stretches');
      if (clearedMain) {
        // Pull the server's fresh main exercises.
        Future.microtask(_loadWorkout);
      }
      if (clearedWarmup || clearedStretches) {
        // Force the warmup/stretch helpers to re-fetch (they're lazy-loaded
        // so wiping the cache here makes the next build re-query).
        if (mounted) {
          setState(() {
            if (clearedWarmup) _warmupData = null;
            if (clearedStretches) _stretchData = null;
          });
          Future.microtask(_loadWarmupAndStretches);
        }
      }
    });

    // Merge optimistic main-section entries (in addition to the helpers
    // for warmup/stretches) so the main list reflects the just-tapped
    // staple within one frame.
    final exercises = pendingMain.isEmpty
        ? workout.exercises
        : _mergeOptimisticMainExercises(workout.exercises, pendingMain);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Spacer for top bar
              SliverToBoxAdapter(
                child: SizedBox(height: safePadding.top + 60),
              ),

              // HERO MASTHEAD — Signature v2: Anton display name over a Barlow
              // Condensed muted subtitle (muscle groups · training program).
              // The whole-brief masthead that leads the pre-start frame.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // SCHEDULED-DAY EYEBROW. E2E #31: this screen carried no
                      // date at all, so a successful reschedule left it
                      // pixel-identical and the user could not tell whether
                      // anything had happened. The day the session is on is
                      // now stated above its name, resolved through the single
                      // local-day chokepoint (`scheduledLocalDay`) so it can
                      // never disagree with the strip/carousel that sent the
                      // user here.
                      Builder(builder: (_) {
                        final day = scheduledLocalDay(workout.scheduledDate);
                        final label = scheduledDayLabel(day);
                        if (label == null) return const SizedBox.shrink();
                        final isToday = label == 'TODAY';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.event_rounded,
                                size: 13,
                                color: isToday ? accentColor : textMuted,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                label,
                                style: ZType.lbl(
                                  11,
                                  color: isToday ? accentColor : textMuted,
                                  letterSpacing: 1.6,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      // E2E #123 gave this a 3rd line so long curated names
                      // ("Active Recovery & Mobility Day") stopped ellipsizing
                      // to "Active Rec…". That fixed truncation but bought it
                      // with height: "UPPER BODY STRENGTH FOUNDATION" set three
                      // 32pt lines and ate roughly a fifth of the screen before
                      // any content (E2E #165).
                      //
                      // Neither cap is the answer — the SIZE is what should
                      // give. _MastheadTitle keeps 32pt when the name fits two
                      // lines and steps down only as far as it must, so short
                      // names look exactly as before, long ones stay fully
                      // readable, and nothing truncates.
                      WorkoutMastheadTitle(
                        text: (workout.name ??
                                AppLocalizations.of(context).navWorkout)
                            .toUpperCase(),
                        color: isDark
                            ? AppColors.textPrimary
                            : AppColorsLight.textPrimary,
                      ),
                      if (_workoutMastheadSubtitle(workout) != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          _workoutMastheadSubtitle(workout)!,
                          style: ZType.lbl(
                            11,
                            color: textMuted,
                            letterSpacing: 1.4,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
                  .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
              ),

              // Inline refresh-error banner: rendered only when a background
              // reload failed but we still have a cached workout. Lets the
              // user keep their in-progress session instead of being popped.
              if (_refreshError != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: Colors.amber.withValues(alpha: 0.15),  // accent-allowlist: warning severity
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          setState(() => _refreshError = null);
                          _loadWorkout();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  size: 18, color: Colors.amber),  // accent-allowlist: warning severity
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _refreshError!,
                                  style: ZType.ser(
                                    13,
                                    color: ThemeColors.of(context).textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                AppLocalizations.of(context).buttonRetry.toUpperCase(),
                                style: ZType.lbl(
                                  12,
                                  color: accentColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 4),
                              IconButton(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minHeight: 28, minWidth: 28),
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () =>
                                    setState(() => _refreshError = null),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Type badges row - single line horizontal scroll.
              // E2E #123 (row 148's fix for this surface): a bare
              // `SingleChildScrollView(horizontal) → Row` with no fade/peek
              // sliced the rightmost chip (DIFFICULTY) at the screen edge —
              // it read as a layout bug, not "scroll me". FadingChipRow adds
              // the fade + trailing gutter and owns inter-chip spacing.
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
                  child: FadingChipRow(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      // Program provenance badge — which program this workout
                      // belongs to (AI vs a curated/branded program like
                      // HYROX), color-matched to the merged schedule.
                      Builder(builder: (_) {
                        final attr = workoutProgramAttribution(workout);
                        return _buildLabeledBadge(
                          label: 'Program',
                          value: attr.isAi ? 'AI' : attr.name,
                          color: attr.color,
                          backgroundColor: attr.color.withValues(alpha: 0.15),
                        );
                      }),
                      // Workout Type Badge - now with semantic color
                      _buildLabeledBadge(
                        label: AppLocalizations.of(context).workoutDetailType,
                        value: (workout.type ?? 'strength').capitalize(),
                        color: AppColors.getWorkoutTypeColor(workout.type ?? 'strength'),
                        backgroundColor: AppColors.getWorkoutTypeColor(workout.type ?? 'strength').withValues(alpha: 0.15),
                      ),
                      // Difficulty Badge - special animated version for Hell
                      if ((workout.difficulty ?? 'medium').toLowerCase() == 'hell')
                        const AnimatedHellBadge()
                      else
                        _buildLabeledBadge(
                          label: AppLocalizations.of(context).workoutSummaryGeneralDifficulty,
                          value: DifficultyUtils.getDisplayName(workout.difficulty ?? 'medium', context),
                          color: DifficultyUtils.getColor(workout.difficulty ?? 'medium'),
                          backgroundColor: DifficultyUtils.getColor(workout.difficulty ?? 'medium').withValues(alpha: 0.15),
                        ),
                      // Training Program Badge (only show if we have a valid program name)
                      if (_trainingSplit != null && _getTrainingProgramName(_trainingSplit!) != null)
                        _buildLabeledBadge(
                          // Labeled "Split" (not "Program") — this chip's value
                          // is the training split (e.g. "Full Body"), which read
                          // as confusing next to the TYPE chip when both showed.
                          // Literal string keeps it off the localized "Program"
                          // key without an .arb change.
                          label: 'Split',
                          value: _getTrainingProgramName(_trainingSplit!)!,
                          color: accentColor,
                          backgroundColor: accentColor.withValues(alpha: 0.15),
                        ),
                    ],
                  ),
                ),
              ),

              // ─────────────────────────────────────────────────────────────
              // PARITY ACTION ROW — Adjust workout + thumbs feedback.
              // Mirrors Google Health's at-a-glance "tune this / rate this"
              // controls; the destructive/secondary actions (Mark as done,
              // Shuffle, Save) live in the app bar + overflow.
              // ─────────────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _adjustWorkout(workout),
                          icon: const Icon(Icons.tune_rounded, size: 18),
                          label: const Text('Adjust workout'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: accentColor,
                            side: BorderSide(
                                color: accentColor.withValues(alpha: 0.5)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      _ThumbButton(
                        icon: _thumbs == 1
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        active: _thumbs == 1,
                        activeColor: accentColor,
                        onTap: () => _onThumbs(workout, 1),
                      ),
                      const SizedBox(width: 8),
                      _ThumbButton(
                        icon: _thumbs == -1
                            ? Icons.thumb_down_rounded
                            : Icons.thumb_down_outlined,
                        active: _thumbs == -1,
                        activeColor: Colors.redAccent,  // accent-allowlist: error/destructive — must stay red
                        onTap: () => _onThumbs(workout, -1),
                      ),
                    ],
                  ),
                ),
              ),

              // Fasting Training Warning (if applicable)
              SliverToBoxAdapter(
                child: FastingTrainingWarning(
                  workoutIntensity: workout.difficulty,
                  workoutType: workout.type,
                  durationMinutes: workout.durationMinutes,
                ),
              ),

              // Stats Row — Signature telemetry ledger: Anton numerals on a
              // hairline strip (no boxed cards). Calorie stat keeps its orange
              // animated flame (semantic energy color).
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const ZealovaRule(),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: ZealovaStatTile(
                            value: '${workout.bestDurationMinutes}',
                            unit: 'min',
                            label: 'duration',
                            valueSize: 26,
                          ),
                        ),
                        Container(width: 1, height: 32, color: ThemeColors.of(context).cardBorder),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ZealovaStatTile(
                            value: '${exercises.length}',
                            label: 'exercises',
                            valueSize: 26,
                          ),
                        ),
                        Container(width: 1, height: 32, color: ThemeColors.of(context).cardBorder),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedFireIcon(size: 18, color: context.accentColor),
                              const SizedBox(width: 6),
                              Expanded(
                                child: ZealovaStatTile(
                                  value: '${workout.estimatedCalories}',
                                  unit: 'cal',
                                  label: 'energy',
                                  valueSize: 26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const ZealovaRule(),
                ],
              ),
            ).animate()
              .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
              .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
          ),

          // ─────────────────────────────────────────────────────────────────
          // EQUIPMENT SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          // User feedback (live review): equipment shouldn't occupy a full
          // card — but knowing whether today's session fits the gym you're
          // standing in is a pre-workout glance, so it can't disappear behind
          // a menu either. Collapsed to one line (icon + count + names,
          // truncated); EDIT moved into the ⋮ overflow menu since editing is
          // deliberate and rare while the glance is frequent.
          if (workout.equipmentNeeded.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: _buildEquipmentCompactRow(workout),
              ),
            ),

            // Equipment items (shown when expanded)
            if (_isEquipmentExpanded)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: workout.equipmentNeeded.map((equipment) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: ThemeColors.of(context).surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: ThemeColors.of(context).cardBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 13,
                              color: ThemeColors.of(context).success,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              localizeEquipment(equipment, context).toUpperCase(),
                              style: ZType.lbl(
                                11,
                                color: ThemeColors.of(context).textSecondary,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ).animate()
                .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.fastOut)
                .slideY(begin: 0.05, end: 0, duration: AppAnimations.quick, curve: AppAnimations.decelerate),
              ),
          ],

          // ─────────────────────────────────────────────────────────────────
          // AI INSIGHTS — a SINGLE always-visible tappable card (no chevron, no
          // expand/collapse). Sits between Equipment and Warm Up (user request).
          // Shows the AI-generated pre-workout briefing — personalized to the
          // user's lift history, PR/1RM opportunities, injuries and targets —
          // as a one-line teaser; tapping opens the full modal. Gated on summary
          // presence/loading so it never renders as an empty shell.
          // ─────────────────────────────────────────────────────────────────
          if (_workoutSummary != null || _isLoadingSummary)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: buildWorkoutSummarySection(
                  workoutSummary: _workoutSummary,
                  isLoadingSummary: _isLoadingSummary,
                  onTapInsights: () => _workoutSummary != null
                      ? showAIInsightsPopup(
                          summaryJson: _workoutSummary!,
                          workoutId: widget.workoutId,
                          onSummaryUpdated: (newSummary) =>
                              setState(() => _workoutSummary = newSummary),
                        )
                      : null,
                ),
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // POST-WORKOUT SECTION (Sauna - only for completed workouts)
          // ─────────────────────────────────────────────────────────────────
          if (workout.isCompleted == true && !_isLoadingSauna)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _saunaLog != null
                    ? ZealovaCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(
                          children: [
                            const Icon(Icons.hot_tub_rounded, size: 20, color: Color(0xFFE65100)),  // accent-allowlist: deliberate deep-orange heat theme for sauna, matches sauna_dialog.dart
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${_saunaLog!.durationMinutes} MIN SAUNA',
                                    style: ZType.lbl(
                                      12,
                                      color: ThemeColors.of(context).textPrimary,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                  if (_saunaLog!.estimatedCalories != null)
                                    Text(
                                      '~${_saunaLog!.estimatedCalories} cal burned',
                                      style: ZType.data(
                                        11,
                                        color: ThemeColors.of(context).textMuted,
                                        weight: FontWeight.w400,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _deleteSaunaLog,
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
                              ),
                            ),
                          ],
                        ),
                      )
                    : TextButton.icon(
                        onPressed: _addSaunaToWorkout,
                        icon: const Icon(Icons.hot_tub_rounded, size: 18),
                        label: Text(AppLocalizations.of(context).workoutDetailAddSaunaTime),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),  // accent-allowlist: deliberate deep-orange heat theme for sauna, matches sauna_dialog.dart
                        ),
                      ),
              ),
            ),

          // ─────────────────────────────────────────────────────────────────
          // WARMUP SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: AppLocalizations.of(context).workoutDetailWarmUp,
                icon: Icons.whatshot,
                color: context.accentColor,
                isExpanded: _isWarmupExpanded,
                onTap: () {
                  setState(() => _isWarmupExpanded = !_isWarmupExpanded);
                  // Lazy-load warmup/stretch data on first expand
                  if (_isWarmupExpanded && _warmupData == null) {
                    _loadWarmupAndStretches();
                  }
                },
                itemCount: _getWarmupExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).warmupEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setWarmupEnabled(value);
                },
              ),
            ),
          ),

          // Warmup items (shown when expanded) — loading/error/empty/data states
          if (_isWarmupExpanded)
            _buildWarmupStretchSliver(
              _getWarmupExercises(),
              context.accentColor,
              'No warm-up for this workout.',
              section: 'warmup',
            ),

          // ─────────────────────────────────────────────────────────────────
          // EXERCISES SECTION header — uses the same card shell as Equipment /
          // Warm Up / Cool Down / More Info so all five sections share one
          // visual language (rounded card, colored icon chip, count badge,
          // muted uppercase title). Trailing slot carries the kg/lbs toggle
          // and the + add button as compact icon affordances.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: AppLocalizations.of(context).workoutSummaryGeneralExercises,
                icon: Icons.fitness_center,
                // Neutral so the single solid-accent budget stays on LET'S GO.
                color: textMuted,
                isExpanded: true,
                onTap: () {/* always expanded */},
                itemCount: exercises.length,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        HapticService.light();
                        _toggleUnit();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.swap_horiz, color: accentColor, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              (_useKgOverride ?? ref.watch(useKgForWorkoutProvider))
                                  ? 'KG'
                                  : 'LBS',
                              style: ZType.lbl(
                                12,
                                color: accentColor,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () async {
                        await _flushPendingAutoSave();
                        if (!context.mounted) return;
                        final currentExerciseNames = exercises.map((e) => e.name).toList();
                        final updatedWorkout = await showExerciseAddSheet(
                          context,
                          ref,
                          workoutId: widget.workoutId,
                          workoutType: _workout?.type ?? 'strength',
                          currentExerciseNames: currentExerciseNames,
                        );
                        if (updatedWorkout != null && context.mounted) {
                          setState(() => _workout = updatedWorkout);
                          ref.read(todayWorkoutProvider.notifier).invalidateAndRefresh();
                          ref.read(workoutsProvider.notifier).silentRefresh();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Icon(Icons.add, color: accentColor, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Exercise List with superset grouping, drag-to-superset, and reordering
          SliverReorderableList(
            itemCount: groupExercisesForDisplay(exercises).length,
            onReorder: _reorderExercises,
            proxyDecorator: (child, index, animation) {
              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) {
                  final elevation = Tween<double>(begin: 0, end: 8).animate(
                    CurvedAnimation(parent: animation, curve: Curves.easeOut),
                  ).value;
                  return Material(
                    elevation: elevation,
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.transparent,
                    shadowColor: accentColor.withValues(alpha: 0.3),
                    child: child,
                  );
                },
                child: child,
              );
            },
            itemBuilder: (context, index) {
              final displayItems = groupExercisesForDisplay(exercises);
              if (index >= displayItems.length) return const SizedBox.shrink();
              final item = displayItems[index];

              // ─── SUPERSET GROUPED CARD (supports 2+ exercises) ───
              if (item.isSuperset) {
                // Build list of exercise widgets for the superset
                // Pass onSupersetDrop AND reorderIndex to enable DragTarget for adding more exercises
                final supersetExercises = item.supersetIndices!
                    .map((idx) => _buildExerciseCard(
                          exercises[idx],
                          idx,
                          accentColor,
                          reorderIndex: idx,  // Required for DragTarget to be created
                          onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, idx),
                          supersetPairingIndex: _pendingSupersetIndex,
                        ))
                    .toList();

                return AnimationConfiguration.staggeredList(
                  key: ValueKey('superset-${item.groupNumber}'),
                  position: index,
                  duration: AppAnimations.listItem,
                  child: SlideAnimation(
                    verticalOffset: 20,
                    curve: AppAnimations.fastOut,
                    child: FadeInAnimation(
                      curve: AppAnimations.fastOut,
                      child: SupersetGroupCard(
                        groupNumber: item.groupNumber!,
                        isActive: false,
                        reorderIndex: index,
                        exercises: supersetExercises,
                        onBreakSuperset: () => _breakSuperset(item.groupNumber!),
                        onSwapOrder: item.exerciseCount == 2
                            ? () => _swapSupersetOrder(item.groupNumber!)
                            : null,
                        onReorderExercises: item.exerciseCount >= 3
                            ? () => _showReorderSheet(item.groupNumber!, item.supersetIndices!)
                            : null,
                      ),
                    ),
                  ),
                );
              }

              // ─── SINGLE EXERCISE ───
              // Drag strip handles both reordering (short drag) and superset creation (long-press drag)
              final exerciseIndex = item.singleIndex!;
              final exercise = exercises[exerciseIndex];
              final isPendingPair = _pendingSupersetIndex == exerciseIndex;

              return AnimationConfiguration.staggeredList(
                key: ValueKey('exercise-$exerciseIndex-${exercise.id ?? exercise.name}'),
                position: index,
                duration: AppAnimations.listItem,
                child: SlideAnimation(
                  verticalOffset: 20,
                  curve: AppAnimations.fastOut,
                  child: FadeInAnimation(
                    curve: AppAnimations.fastOut,
                    child: _buildExerciseCard(
                        exercise,
                        exerciseIndex,
                        accentColor,
                        reorderIndex: index,
                        isPendingPair: isPendingPair,
                        onSupersetDrop: (draggedIndex) => _createSuperset(draggedIndex, exerciseIndex),
                        supersetPairingIndex: _pendingSupersetIndex,
                        sectionHeader: sectionHeaderForIndex(exercises, exerciseIndex),
                      ),
                  ),
                ),
              );
            },
          ),

          // ─────────────────────────────────────────────────────────────────
          // CHALLENGE SECTION (Collapsible) - For beginners and intermediate
          // ─────────────────────────────────────────────────────────────────
          if (workout.hasChallenge)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildCollapsibleSectionHeader(
                  title: AppLocalizations.of(context).workoutDetailWantAChallenge,
                  icon: Icons.local_fire_department,
                  color: Colors.orange,  // accent-allowlist: warning severity
                  isExpanded: _isChallengeExpanded,
                  onTap: () => setState(() => _isChallengeExpanded = !_isChallengeExpanded),
                  itemCount: 1,
                  subtitle: workout.challengeExercise?.progressionFrom != null
                      ? 'Progression from ${workout.challengeExercise!.progressionFrom}'
                      : 'Try this advanced exercise',
                ),
              ),
            ),

          // Challenge exercise item (shown when expanded)
          if (workout.hasChallenge && _isChallengeExpanded)
            SliverToBoxAdapter(
              child: _buildChallengeExerciseCard(workout.challengeExercise!),
            ),

          // ─────────────────────────────────────────────────────────────────
          // STRETCHES SECTION (Collapsible)
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: AppLocalizations.of(context).workoutDetailCoolDownStretches,
                icon: Icons.self_improvement,
                color: context.accentColor,
                isExpanded: _isStretchesExpanded,
                onTap: () {
                  setState(() => _isStretchesExpanded = !_isStretchesExpanded);
                  // Lazy-load warmup/stretch data on first expand
                  if (_isStretchesExpanded && _stretchData == null) {
                    _loadWarmupAndStretches();
                  }
                },
                itemCount: _getStretchExercises().length,
                toggleValue: ref.watch(warmupDurationProvider).stretchEnabled,
                onToggleChanged: (value) {
                  ref.read(warmupDurationProvider.notifier).setStretchEnabled(value);
                },
              ),
            ),
          ),

          // Stretches items (shown when expanded) — loading/error/empty/data states
          if (_isStretchesExpanded)
            _buildWarmupStretchSliver(
              _getStretchExercises(),
              AppColors.green,  // accent-allowlist: success/positive state — same value as AppColors.success, must stay green regardless of accent
              'No stretches for this workout.',
              section: 'stretches',
            ),

          // ─────────────────────────────────────────────────────────────────
          // MORE INFO SECTION (Collapsible) - AI Insights moved here
          // ─────────────────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child: _buildCollapsibleSectionHeader(
                title: AppLocalizations.of(context).workoutDetailMoreInfo,
                icon: Icons.lightbulb_outline,
                color: accentColor,
                isExpanded: _isMoreInfoExpanded,
                onTap: () => setState(() => _isMoreInfoExpanded = !_isMoreInfoExpanded),
                itemCount: 2,  // Muscles, AI Reasoning (Summary promoted to AI Insights section above)
                subtitle: 'Targeted muscles & design reasoning',
              ),
            ),
          ),

          // More Info content (shown when expanded)
          if (_isMoreInfoExpanded) ...[
            // (AI workout summary promoted to its own "AI Insights" section
            // between Equipment and Warm Up — no longer rendered here.)

            // Targeted Muscles Section
            SliverToBoxAdapter(
              child: buildTargetedMusclesSection(workout.primaryMuscles),
            ),

            // AI Reasoning Section (expandable)
            if (_generationParams != null || _isLoadingParams)
              SliverToBoxAdapter(
                child: buildAIReasoningSection(
                  generationParams: _generationParams,
                  isLoadingParams: _isLoadingParams,
                  isExpanded: _isAIReasoningExpanded,
                  onToggle: () => setState(() => _isAIReasoningExpanded = !_isAIReasoningExpanded),
                  onViewParameters: () {
                    if (_generationParams != null) showViewParametersModal(_generationParams!);
                  },
                ),
              ),
          ],

          // Skill progressions entry (Dr-Yaad audit #11) — weaves the
          // progression-chain engine + hold-time history into the daily
          // workout flow, not just the Progress tab.
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/workout/exercise-progressions');
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(isDark ? 0.10 : 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: accentColor.withOpacity(0.30), width: 0.8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.trending_up_rounded,
                            size: 20, color: accentColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Skill progressions',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimary
                                      : AppColorsLight.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Track holds & advance to harder variants',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark
                                      ? AppColors.textMuted
                                      : AppColorsLight.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right_rounded,
                            size: 20,
                            color: isDark
                                ? AppColors.textMuted
                                : AppColorsLight.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // E2E #51 — the LET'S GO cluster is no longer a floating FAB painted
          // OVER this list (which collided with whatever exercise row happened
          // to be at the bottom of the viewport); it is docked in
          // `bottomNavigationBar`, so the Scaffold already insets this scroll
          // view by its full height and no row can ever sit under it.
          // Only a small breathing gap is needed here now. Summary mode still
          // floats its Detail/Summary/Advanced pill over the list, so it keeps
          // reserving that pill's clearance.
          SliverToBoxAdapter(
            child: SizedBox(
              height: widget.isSummaryMode
                  ? max(140.0, SummaryFloatingPill.clearanceOf(context))
                  : 16,
            ),
          ),
        ],
      ),
      // Header scrim — the floating top bar below has no backdrop of its
      // own, so scrolled content (and the status bar clock/notch) showed
      // straight through it once the list moved past the initial spacer.
      // Painted before the bar so it sits behind it in the Stack, and
      // absorbs any tap that misses a real button instead of falling
      // through to the card underneath (same pattern as
      // `SummaryHeaderScrim` in workout_summary_screen_v2.dart).
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: safePadding.top + 8 + 44 + 12,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {},
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  backgroundColor,
                  backgroundColor,
                  backgroundColor.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.62, 1.0],
              ),
            ),
          ),
        ),
      ),
      // Floating top bar - positioned below status bar
      Positioned(
        top: safePadding.top + 8,
        left: 16,
        right: 16,
        child: Row(
          children: [
            // Back button - floating pill. Guard pop: if this screen was
            // reached via a stack-replacing `go` (nothing to pop), fall back to
            // the workouts tab instead of throwing "There is nothing to pop".
            GestureDetector(
              onTap: () =>
                  context.canPop() ? context.pop() : context.go('/workouts'),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Workout name in center
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          workout.name ?? AppLocalizations.of(context).navWorkout,
                          style: ZType.ser(
                            16,
                            color: ThemeColors.of(context).textPrimary,
                            weight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_isSaving) ...[
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.5,
                            color: isDark ? Colors.white54 : AppColorsLight.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Favorite button - floating pill
            GestureDetector(
              onTap: _toggleFavorite,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    key: ValueKey(_isFavorite),
                    color: _isFavorite ? Colors.redAccent : (isDark ? Colors.white : AppColorsLight.textPrimary),  // accent-allowlist: error/destructive — must stay red
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Save to library button - floating pill (Google-Health parity)
            GestureDetector(
              onTap: () => _saveToLibrary(workout),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.bookmark_add_outlined,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Menu button - floating pill (Mark as done + Shuffle + more)
            GestureDetector(
              onTap: () => _showParityOverflowMenu(workout),
              child: Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1C1C1E) : AppColorsLight.elevated,
                  borderRadius: BorderRadius.circular(22),
                  border: isDark ? null : Border.all(color: cardBorder.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: isDark ? Colors.white : AppColorsLight.textPrimary,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
      ],
      ),

      // E2E #51 — DOCKED, not floating. As a `floatingActionButton` this
      // cluster painted on top of the scrolling exercise list and overlapped
      // whichever row was under it. Docking it keeps the identical pill
      // visuals (same avatar + accent LET'S GO pill, right-aligned) while
      // making the Scaffold reserve real space for it, so content is scrolled
      // ABOVE it instead of underneath. Hidden in summary mode, as before.
      bottomNavigationBar: widget.isSummaryMode
          ? null
          : _buildStartBar(context, ref, workout),
    );
  }

  // Warmup and stretch methods extracted to workout_detail_screen_warmup.dart
}

// Helper widgets and classes are extracted to:
// - widgets/workout_detail_helpers.dart (StatCard, AnimatedFireIcon, AnimatedHellBadge, ExerciseDisplayItem, equipment helpers)
// - widgets/workout_detail_ai_insights.dart (AI insights mixin)

/// Compact pill thumb button used in the parity action row. Fills with the
/// supplied [activeColor] when [active]; otherwise renders a muted outline.
class _ThumbButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final Color activeColor;
  final VoidCallback onTap;

  const _ThumbButton({
    required this.icon,
    required this.active,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedFg = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final baseColor = active
        ? activeColor.withValues(alpha: 0.15)
        : (isDark ? AppColors.elevated : AppColorsLight.elevated);
    final borderColor = active
        ? activeColor.withValues(alpha: 0.5)
        : mutedFg.withValues(alpha: 0.25);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        width: 44,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Icon(
          icon,
          size: 20,
          color: active ? activeColor : mutedFg,
        ),
      ),
    );
  }
}

/// The workout-detail masthead title.
///
/// Sizes itself to fit **two** lines rather than spilling onto a third.
/// Measures with a real `TextPainter` at the width it is actually given, so it
/// is correct for any name length, any locale, and any text-scale setting —
/// none of which are knowable at build time. Steps down 32 → 22pt and stops at
/// the first size that fits; a name too long even at 22 keeps `maxLines: 2`
/// with an ellipsis, which is strictly better than the 3-line spill it
/// replaces. Short names are untouched: they fit at 32 and the loop exits on
/// the first try.
class WorkoutMastheadTitle extends StatelessWidget {
  final String text;
  final Color color;

  const WorkoutMastheadTitle({super.key, required this.text, required this.color});

  static const List<double> _ladder = [32, 29, 26, 24, 22];

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        double chosen = _ladder.last;
        for (final size in _ladder) {
          final style = ZType.sans(
            size,
            color: color,
            weight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 0.98,
          );
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            maxLines: 2,
            textDirection: Directionality.of(context),
            textScaler: scaler,
          )..layout(maxWidth: maxWidth);
          if (!painter.didExceedMaxLines) {
            chosen = size;
            break;
          }
        }
        return Text(
          text,
          style: ZType.sans(
            chosen,
            color: color,
            weight: FontWeight.w800,
            letterSpacing: -0.5,
            height: 0.98,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        );
      },
    );
  }
}
