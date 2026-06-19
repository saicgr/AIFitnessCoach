import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_colors.dart';
import '../../data/models/workout.dart';
import '../../data/models/workout_screen_summary.dart';
import '../../core/constants/synced_workout_kinds.dart';
import '../../data/providers/synced_workouts_provider.dart';
import '../../data/repositories/workout_repository.dart';
import '../../widgets/synced/kind_avatar.dart';
import '../../widgets/synced/metric_chip.dart';
import '../profile/synced_workout_detail_screen.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/main_shell.dart';
import '../../widgets/tooltips/tooltips.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/pill_swipe_navigation.dart';
// WorkoutTuneMenu (calendar display options) still lives in the planner
// section file and is hosted in the masthead action cluster.
import 'widgets/workout_planner_section.dart' show WorkoutTuneMenu;
import 'widgets/around_your_workout_section.dart';
import 'widgets/workout_stats/workout_stats_section.dart';
import 'widgets/workouts_signature_body.dart';
import '../home/widgets/week_calendar_strip.dart';
import '../home/widgets/gym_profile_switcher.dart';
import 'package:fitwiz/core/constants/branding.dart';

import '../../l10n/generated/app_localizations.dart';
/// Workouts screen - central hub for all workout-related content
/// Accessible from the floating nav bar (replaces Profile)
class WorkoutsScreen extends ConsumerStatefulWidget {
  /// Optional parameter to scroll to a specific section
  final String? scrollTo;

  const WorkoutsScreen({super.key, this.scrollTo});

  @override
  ConsumerState<WorkoutsScreen> createState() => _WorkoutsScreenState();
}

class _WorkoutsScreenState extends ConsumerState<WorkoutsScreen>
    with PillSwipeNavigationMixin {
  // PillSwipeNavigationMixin: Workouts is index 1
  @override
  int get currentPillIndex => 1;

  // Spotlight target keys for `workouts_v1` now live in
  // `widgets/tooltips/tooltip_anchors.dart`. Local aliases kept so the
  // KeyedSubtree wraps below stay readable.
  GlobalKey get _quickActionsKey => TooltipAnchors.workoutsQuickActions;
  GlobalKey get _exercisePreferencesKey => TooltipAnchors.workoutsExercisePrefs;
  // `workoutsToday` (tour step 1) is now anchored inside WorkoutPlannerSection,
  // scoped to the workout card rather than the whole date-strip + carousel
  // block — see workout_planner_section.dart.

  // Scroll controller + planner anchor key. The floating launcher bar's
  // "Plan" item jumps the scroll view back to the planner section; the
  // remaining items navigate / open sheets instead of scrolling.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _planSectionKey = GlobalKey();

  // Weekly-progress memoization was removed in the Signature v2 body rebuild —
  // the THIS WEEK strip now lives self-contained in `WorkoutsSignatureBody`,
  // which reads `workoutsProvider` / the active gym profile directly.

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Hairline "+ BUILD A WORKOUT" affordance — the spec's "+" add/build
  /// affordance. Routes to the custom workout builder (preserves the old
  /// `/workout/build` route the floating bar's Builder + the CUSTOM chip used).
  Widget _buildAddWorkoutAffordance(BuildContext context, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticService.light();
            context.push('/workout/build');
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 18, color: accentColor),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context).workoutsCustom.toUpperCase(),
                  style: ZType.lbl(12.5,
                      color: ThemeColors.of(context).textPrimary,
                      letterSpacing: 1.8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Get dynamic accent color from provider
    final accentColor = ref.colors(context).accent;

    // Watch workouts state (for weekly progress, upcoming list)
    final workoutsState = ref.watch(workoutsProvider);
    // Watch lightweight screen summary (for weekly progress + previous sessions)
    final screenSummary = ref.watch(workoutScreenSummaryProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: wrapWithSwipeDetector(
        child: Stack(
          children: [
            // Scrollable content
            CustomScrollView(
              controller: _scrollController,
              slivers: [
                // Top padding for the floating masthead. The masthead is now a
                // compact 2-line block (gym-switcher row + date sub-line) since
                // the big split-name title moved onto the carousel — so this
                // reserve dropped from 118 to ~78 (2 top + ~40 gym/pill row +
                // 2 + ~16 date + 10 bottom) to kill the dead gap that opened up
                // above the date strip.
                SliverToBoxAdapter(
                  child: SizedBox(
                      height: MediaQuery.of(context).padding.top + 78),
                ),

                // Content - render unconditionally using valueOrNull to avoid blocking on load
                _buildContent(
                  context,
                  isDark,
                  textPrimary,
                  textSecondary,
                  accentColor,
                  workoutsState.valueOrNull ?? [],
                  screenSummary,
                ),
              ],
            ),

            // Floating header with back, title, and action icons
            _buildFloatingHeader(
              context,
              isDark,
              textPrimary,
              textSecondary,
              accentColor,
            ),

            // Floating options bar removed in the Signature v2 body rebuild —
            // its Plan / Manage Gym / Library / Programs actions now live as
            // inline LIBRARY/BUILDER/PROGRAMS links in the PROGRAM block and
            // the gym switcher in the masthead. Routes preserved.

            // First-run spotlight tour. Anchors + copy live in
            // `widgets/tooltips/tours/workouts_tour.dart`.
            WorkoutsTour.overlay(),
          ],
        ),
      ),
    );
  }

  /// Signature masthead — flat (pureBlack) band, no gradient / no glass. An
  /// Anton "WORKOUTS" title with the "Zealova" eyebrow + action cluster above
  /// it, and the gym switcher restyled as a hairline pill below. Replaces the
  /// old blurred gradient header + glassmorphic action circles.
  Widget _buildFloatingHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;
    // Flat scaffold-colored band that is solid across the status bar + title
    // row and fades to transparent below, so content scrolling up meets the
    // masthead without a seam — but no LinearGradient/blur glass.
    final scaffoldBg =
        isDark ? AppColors.background : AppColorsLight.background;
    final tc = ThemeColors.of(context);

    // Contextual masthead (replaces the redundant static "WORKOUTS" wordmark —
    // the nav tab already names this room). Mirrors Home's editorial date
    // masthead: today's split name big, with the date below; on a rest/no-plan
    // day it falls back to the date itself so the masthead is never empty.
    const _mhWeekdays = [
      'MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY',
    ];
    const _mhMonths = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    final mhNow = DateTime.now();
    final mhWeekday = _mhWeekdays[mhNow.weekday - 1];
    final mhMonthDay = '${_mhMonths[mhNow.month - 1]} ${mhNow.day}';

    return PositionedDirectional(
      top: 0,
      start: 0,
      end: 0,
      child: RepaintBoundary(
        child: Container(
          padding: EdgeInsetsDirectional.only(
              top: topPadding + 2, start: 20, end: 16, bottom: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                scaffoldBg,
                scaffoldBg,
                scaffoldBg.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.72, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Masthead row: the GYM leads (big name + dropdown) with the
              // action pills on the right. The big split-name title was removed
              // here — the workout carousel below now carries today's split
              // name, so leading the masthead with it too was a duplicate. The
              // date drops to the muted sub-line below.
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Expanded(
                    child: GymProfileSwitcher(large: true),
                  ),
                  const SizedBox(width: 8),
                  _HairlineActionPill(
                    icon: Icons.bar_chart_rounded,
                    tint: accentColor,
                    onTap: () {
                      HapticService.light();
                      context.push('/stats');
                    },
                  ),
                  const SizedBox(width: 8),
                  _HairlineActionPill(
                    icon: Icons.show_chart_rounded,
                    tint: accentColor,
                    onTap: () {
                      HapticService.light();
                      context.push('/trends/custom');
                    },
                  ),
                  const SizedBox(width: 8),
                  // Calendar display options (week start / show synced). The
                  // inner PopupMenuButton owns the tap, so no onTap here.
                  _HairlineActionPill(
                    child: WorkoutTuneMenu(tint: accentColor),
                  ),
                  const SizedBox(width: 8),
                  _HairlineActionPill(
                    icon: Icons.settings_outlined,
                    tint: accentColor,
                    onTap: () {
                      HapticService.light();
                      context.push('/settings/workout-settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 2),
              // Sub-line — the date, always muted under the gym lead.
              Text(
                '$mhWeekday  ·  $mhMonthDay',
                style: ZType.lbl(12.5, color: tc.textMuted, letterSpacing: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    List<Workout> workouts,
    AsyncValue<WorkoutScreenSummary?> screenSummary,
  ) {
    // The THIS WEEK strip + weekly figures now live self-contained inside
    // `WorkoutsSignatureBody` (reads workoutsProvider / gym profile directly),
    // so the old `_computeWeeklyProgress` walk that fed `WeeklyProgressCard`
    // is no longer needed here.

    // Build the children list eagerly (cheap — these are widget *constructors*,
    // not built subtrees), then hand it to a lazy SliverChildBuilderDelegate so
    // the heavy below-fold widgets (WorkoutStatsSection et al.) only build as
    // they scroll into view, instead of all on the first frame.
    //
    // Signature v2 body — replaces the old photo planner card / gradient
    // library grid / floating options bar with a single hairline-led scroll:
    // TODAY block → THIS WEEK strip → PROGRAM links → EXERCISE PREFERENCES →
    // HISTORY. The `_planSectionKey` (floating-bar "Plan" jump target — bar
    // removed) and the `workoutsToday` tour anchor now wrap the TODAY block.
    final children = <Widget>[
        // NOTE: the `workoutsToday` tour anchor is NOT wrapped here — it now
        // lives inside WorkoutPlannerSection (scoped to the carousel card), so
        // wrapping the whole body with the same GlobalKey would crash with a
        // duplicate-GlobalKey error.
        KeyedSubtree(
          key: _planSectionKey,
          child: WorkoutsSignatureBody(
            exercisePreferencesKey: _exercisePreferencesKey,
          ),
        ),

        // "Around your workout" — post-workout cards (Training effect, mood /
        // journal prompts, Tomorrow tweak, …). Self-hides entirely until
        // today's workout is completed, so it adds nothing on non-workout days.
        const SizedBox(height: 8),
        const AroundYourWorkoutSection(),

        const SizedBox(height: 24),

        // Training stats — full analytics section (AI insight, scalar strip,
        // trend chart, muscle balance, fueling split, strength, timing,
        // activity heatmap, recent PRs, custom trends).
        const WorkoutStatsSection(),
        const SizedBox(height: 24),

        // Synced Workouts (Health Connect / Apple Health) — same rich
        // visual system as the Profile tab.
        _buildSyncedWorkoutsSection(context, isDark, textSecondary),

        // Quick-actions anchor preserved for the first-run tour — a hairline
        // "+ BUILD A WORKOUT" affordance (replaces the old chip row + the
        // floating bar's Builder entry).
        KeyedSubtree(
          key: _quickActionsKey,
          child: _buildAddWorkoutAffordance(context, accentColor),
        ),
        const SizedBox(height: 20),

        // JIT Generation: workouts auto-generate after each completion.
        _buildJitInfoSection(isDark, textSecondary),

        // Bottom padding — clears MainShell's bottom nav bar.
        const SizedBox(height: 140),
    ];

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => children[index],
        childCount: children.length,
      ),
    );
  }

  // ignore: unused_element
  Widget _buildQuickActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Material(
      color: elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    Color textColor, {
    String? actionText,
    VoidCallback? onAction,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title.toUpperCase(),
            style: ZType.lbl(11, color: textColor, letterSpacing: 2.0),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText.toUpperCase(),
                style: ZType.lbl(11,
                    color: AppColors.textMuted, letterSpacing: 1.5),
              ),
            ),
        ],
      ),
    );
  }

  /// Build JIT info section - explains that workouts are auto-generated
  Widget _buildJitInfoSection(bool isDark, Color textSecondary) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(
            Icons.auto_awesome,
            size: 16,
            color: textSecondary.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppLocalizations.of(context).workoutsYourNextWorkoutIs,
              style: TextStyle(
                fontSize: 12,
                color: textSecondary.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build previous sessions section - shows last 3 completed workouts
  /// Synced Workouts section — horizontally scrollable row of kind-tinted
  /// cards, matching the Profile-tab treatment. Hidden when the user has no
  /// Health Connect / Apple Health imports yet.
  Widget _buildSyncedWorkoutsSection(
    BuildContext context,
    bool isDark,
    Color textSecondary,
  ) {
    final synced = ref.watch(syncedWorkoutsProvider);
    if (synced.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'SYNCED WORKOUTS',
          textSecondary,
          actionText: 'See all',
          onAction: () {
            HapticService.light();
            context.push('/profile/synced-workouts');
          },
        ),
        const SizedBox(height: 8),
        // Adaptive height — scales with OS text size + clamps so the
        // "Apple Health" footer label can't clip on iPhone SE or at 1.3x
        // Dynamic Type. Matches the Profile-tab strip fix.
        Builder(builder: (ctx) {
          final textScale = MediaQuery.textScalerOf(ctx).scale(1.0);
          final height = (156 * textScale).clamp(156.0, 210.0);
          return SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: synced.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => _WorkoutsTabSyncedCard(
                workout: synced[index],
                height: height,
              ),
            ),
          );
        }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPreviousSessions(
    BuildContext context,
    List<Workout> workouts,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    // Get completed workouts, sorted by completion/scheduled date (most recent first).
    // Exclude Health Connect imports — they render in their own section above.
    final completedWorkouts = workouts
        .where((w) =>
            w.isCompleted == true &&
            w.generationMethod != 'health_connect_import')
        .toList()
      ..sort((a, b) {
        final dateA = DateTime.tryParse(a.scheduledDate ?? '') ?? DateTime(1900);
        final dateB = DateTime.tryParse(b.scheduledDate ?? '') ?? DateTime(1900);
        return dateB.compareTo(dateA); // Most recent first
      });

    if (completedWorkouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 32, color: textSecondary),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context).workoutsNoCompletedWorkoutsYet,
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  AppLocalizations.of(context).workoutsCompleteYourFirstWorkout,
                  style: TextStyle(
                    color: textSecondary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Show last 3 completed workouts
    final recentWorkouts = completedWorkouts.take(3).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: recentWorkouts.map((workout) {
          return _PreviousSessionCard(
            workout: workout,
            isDark: isDark,
            onTap: () {
              HapticService.light();
              context.push('/workout-summary/${workout.id}');
            },
          );
        }).toList(),
      ),
    );
  }

}

/// Card widget for displaying a previous workout session
class _PreviousSessionCard extends StatelessWidget {
  final Workout workout;
  final bool isDark;
  final VoidCallback onTap;

  const _PreviousSessionCard({
    required this.workout,
    required this.isDark,
    required this.onTap,
  });

  bool _isQuickWorkout() {
    final method = workout.generationMethod?.toLowerCase() ?? '';
    if (method == 'quick_rule_based' || method == 'ai_quick_workout') {
      return true;
    }
    // Heuristic: short duration + few exercises = quick workout
    final duration = workout.durationMinutes ?? workout.durationMinutesMax ?? 0;
    return duration > 0 && duration <= 15 && workout.exerciseCount <= 5;
  }

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final textPrimary = tc.textPrimary;
    final textMuted = tc.textMuted;
    final accent = tc.accent;

    // Format the date for the hairline date pill.
    String dateText = '';
    bool isToday = false;
    if (workout.scheduledDate != null) {
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final workoutDate = DateTime(date.year, date.month, date.day);
        final difference = today.difference(workoutDate).inDays;

        if (difference == 0) {
          dateText = 'Today';
          isToday = true;
        } else if (difference == 1) {
          dateText = 'Yesterday';
        } else if (difference < 7) {
          dateText = '$difference days ago';
        } else {
          dateText = '${date.day}/${date.month}/${date.year}';
        }
      }
    }

    final typeLabel = (workout.type?.toUpperCase() ??
        AppLocalizations.of(context).workoutsStrength);

    // Signature rh-card row: surface2 fill, hairline border, Anton title,
    // Barlow uppercase subtitle line, an orange date pill (accent only for
    // TODAY), and a monospace duration readout.
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date pill — accent for today, hairline otherwise.
                  if (dateText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isToday
                            ? accent.withValues(alpha: 0.16)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: isToday ? accent : AppColors.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        dateText.toUpperCase(),
                        style: ZType.lbl(9.5,
                            color: isToday ? accent : textMuted,
                            letterSpacing: 1.2),
                      ),
                    ),
                  if (dateText.isNotEmpty) const SizedBox(height: 8),
                  // Anton title.
                  Text(
                    (workout.name ?? AppLocalizations.of(context).navWorkout)
                        .toUpperCase(),
                    style: ZType.disp(19, color: textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  // Barlow uppercase subtitle: type · QUICK · duration.
                  Row(
                    children: [
                      Text(
                        typeLabel,
                        style: ZType.lbl(11,
                            color: textMuted, letterSpacing: 1.5),
                      ),
                      if (_isQuickWorkout()) ...[
                        Text('  ·  ',
                            style: ZType.lbl(11, color: textMuted)),
                        Text('QUICK',
                            style: ZType.lbl(11,
                                color: accent, letterSpacing: 1.5)),
                      ],
                      Text('  ·  ',
                          style: ZType.lbl(11, color: textMuted)),
                      Text(
                        workout.formattedDurationShort,
                        style: ZType.data(11, color: textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

/// Kind-tinted synced-workout card for the Workouts tab strip. Keeps the
/// visual system consistent with the Profile tab's `_SyncedWorkoutCard`.
class _WorkoutsTabSyncedCard extends ConsumerWidget {
  final Workout workout;
  final double height;

  const _WorkoutsTabSyncedCard({
    required this.workout,
    required this.height,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final metadata = workout.generationMetadata ?? {};
    final kind = SyncedKind.fromString(
      metadata['hc_activity_kind'] as String? ?? workout.type,
    );
    final palette = kind.palette(isDark);
    final textPrimary =
        isDark ? Colors.white : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final sourceApp = metadata['source_app'] as String?
        ?? metadata['source_app_name'] as String?
        ?? (Theme.of(context).platform == TargetPlatform.iOS
            ? 'Apple Health'
            : 'Health Connect');

    final chips = _chipsFor(kind, metadata, workout);
    final dateLabel = _formatDateShort(workout.scheduledDate);

    // Primary = real source-app title (e.g. "Imported Cardio Workout"),
    // kind label rendered as a small tag chip above. Matches Profile tab.
    final primaryTitle = (workout.name?.trim().isNotEmpty ?? false)
        ? workout.name!.trim()
        : kind.label;
    final kindTag = (workout.name?.trim().isNotEmpty ?? false) &&
            kind != SyncedKind.other
        ? kind.label
        : null;

    return GestureDetector(
      onTap: () {
        HapticService.selection();
        ref.read(floatingNavBarVisibleProvider.notifier).state = false;
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => SyncedWorkoutDetailScreen(workout: workout),
          ),
        )
            .whenComplete(() {
          ref.read(floatingNavBarVisibleProvider.notifier).state = true;
        });
      },
      child: Container(
        width: 180,
        height: height,
        decoration: BoxDecoration(
          // Signature: surface2 fill + hairline border (was kind-tinted glass).
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Stack(
          children: [
            PositionedDirectional(end: -10,
              bottom: -14,
              child: IgnorePointer(
                child: Transform.rotate(
                        angle: -0.21,
                  child: Icon(
                    kind.icon,
                    size: 96,
                    color: palette.fg.withValues(alpha: 0.10),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.max,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      KindAvatar(kind: kind, size: 36),
                      if (kindTag != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: Text(
                              kindTag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: ZType.lbl(9,
                                  color: textMuted, letterSpacing: 1.0),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            primaryTitle.toUpperCase(),
                            style: ZType.disp(15, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$dateLabel${workout.durationMinutes != null ? ' · ${workout.durationMinutes} min' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: ZType.lbl(10,
                                color: textMuted, letterSpacing: 0.8),
                          ),
                          if (chips.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                for (int i = 0; i < chips.length; i++) ...[
                                  if (i > 0) const SizedBox(width: 8),
                                  Flexible(child: chips[i]),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    sourceApp.toUpperCase(),
                    style: ZType.lbl(9.5,
                        color: textMuted, letterSpacing: 1.0),
                    maxLines: 1,
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

  List<Widget> _chipsFor(
    SyncedKind kind,
    Map<String, dynamic> metadata,
    Workout workout,
  ) {
    final out = <Widget>[];
    for (final key in kind.heroMetricOrder) {
      final chip = _chipForKey(key, metadata, workout);
      if (chip != null) {
        out.add(chip);
        if (out.length >= 2) break;
      }
    }
    return out;
  }

  Widget? _chipForKey(
    String key,
    Map<String, dynamic> metadata,
    Workout workout,
  ) {
    switch (key) {
      case 'distance_m':
        final m = (metadata['distance_m'] ?? metadata['distance_meters']) as num?;
        if (m == null || m <= 0) return null;
        final miles = m.toDouble() * 0.000621371;
        return MetricChip(
          dotColor: MetricColors.distance,
          value: miles < 0.03
              ? '${m.round()}'
              : miles.toStringAsFixed(miles >= 10 ? 1 : 2),
          unit: miles < 0.03 ? 'm' : 'mi',
        );
      case 'calories_active':
        final c = (metadata['calories_active'] ?? metadata['calories_burned']) as num?;
        if (c == null || c <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.calories,
          value: c.round().toString(),
          unit: 'kcal',
        );
      case 'steps':
        final s = (metadata['steps'] ?? metadata['total_steps']) as num?;
        if (s == null || s <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.steps,
          value: s >= 1000
              ? '${(s / 1000).toStringAsFixed(1)}k'
              : s.round().toString(),
          unit: 'steps',
        );
      case 'avg_heart_rate':
        final h = metadata['avg_heart_rate'] as num?;
        if (h == null || h <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.heartRate,
          value: h.round().toString(),
          unit: 'bpm',
        );
      case 'duration':
        if (workout.durationMinutes == null) return null;
        final m = workout.durationMinutes!;
        return MetricChip(
          dotColor: MetricColors.duration,
          value: m >= 60 ? '${m ~/ 60}h ${m % 60}m' : '${m}m',
        );
      case 'elevation_gain_m':
        final e = metadata['elevation_gain_m'] as num?;
        if (e == null || e <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.elevation,
          value: e.round().toString(),
          unit: 'm gain',
        );
      case 'avg_speed_mps':
        final v = metadata['avg_speed_mps'] as num?;
        if (v == null || v <= 0) return null;
        return MetricChip(
          dotColor: MetricColors.pace,
          value: (v.toDouble() * 2.23694).toStringAsFixed(1),
          unit: 'mph',
        );
    }
    return null;
  }

  String _formatDateShort(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}';
  }
}

/// Signature hairline action pill — a 40pt matte-hairline square for the
/// masthead action cluster. Replaces the old `_GlassmorphicButton` (blurred
/// glass). Pass [icon] + [tint] for the common case, or [child] to host a
/// custom widget (e.g. the tune PopupMenuButton, which owns its own tap).
class _HairlineActionPill extends StatelessWidget {
  /// Null when the pill hosts a widget with its own tap handling (e.g. a
  /// `PopupMenuButton`) — the inner widget must receive the taps.
  final VoidCallback? onTap;
  final IconData? icon;
  final Color? tint;
  final Widget? child;

  /// Fixed 40 pt square — every caller uses the same size.
  static const double size = 40;

  const _HairlineActionPill({
    this.onTap,
    this.icon,
    this.tint,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final tc = ThemeColors.of(context);
    final inner = child ??
        Icon(icon, color: tint ?? tc.textPrimary, size: 21);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Center(child: inner),
      ),
    );
  }
}

/// Overflow ⋮ menu for the Workouts top bar. Surface 2.1 removed it from
/// the header; this widget is retained for the Workout Settings screen
/// migration which will re-host the week-strip collapse toggle as a row.
// ignore: unused_element
class _WorkoutsOverflowMenu extends ConsumerWidget {
  final bool isDark;
  final Color accentColor;

  const _WorkoutsOverflowMenu({
    required this.isDark,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(weekCalendarCollapsedProvider);

    // Single-purpose toggle — was a 1-item PopupMenu; the menu form factor
    // mis-sold this as multi-option. Direct tap-to-toggle is one fewer
    // interaction and the icon already encodes the resulting state.
    return Tooltip(
      message: isCollapsed
          ? AppLocalizations.of(context).workoutsExpandWeekView
          : AppLocalizations.of(context).workoutsCollapseWeekView,
      child: _HairlineActionPill(
        onTap: () {
          HapticService.selection();
          ref.read(weekCalendarCollapsedProvider.notifier).toggle();
        },
        icon: isCollapsed
            ? Icons.unfold_more_rounded
            : Icons.unfold_less_rounded,
        tint: accentColor,
      ),
    );
  }
}

/// Bottom sheet that lists every supported workout-import path. Surface
/// 2.1 removed the header import button; this widget is retained for the
/// Workout Settings screen migration which will re-host import as a row.
// ignore: unused_element
class _ImportWorkoutsPickerSheet extends StatelessWidget {
  const _ImportWorkoutsPickerSheet();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GlassSheet(
      opaque: true,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).workoutsImportWorkouts,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                AppLocalizations.of(context)!.workoutsScreenBringYourPastWorkouts(Branding.appName),
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _ImportSourceTile(
                icon: Icons.upload_file_rounded,
                title: AppLocalizations.of(context).workoutsCsvOrJsonFile,
                subtitle: AppLocalizations.of(context).workoutsHevyStrongLiftinFitbod,
                accent: AppColors.purple,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/workout-history-import');
                },
              ),
              const SizedBox(height: 10),
              _ImportSourceTile(
                icon: Icons.edit_note_rounded,
                title: AppLocalizations.of(context).workoutsTypeAFewPrs,
                subtitle: AppLocalizations.of(context).workoutsBenchSquatDeadliftBest,
                accent: AppColors.cyan,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/workout-history-import');
                },
              ),
              const SizedBox(height: 10),
              _ImportSourceTile(
                icon: Icons.sync_rounded,
                title: AppLocalizations.of(context).workoutsHealthConnectAppleHealth,
                subtitle: AppLocalizations.of(context).workoutsSyncSessionsFromYour,
                accent: AppColors.success,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings');
                },
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context).workoutsYouCanEditUndo,
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImportSourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ImportSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return InkWell(
      onTap: () {
        HapticService.light();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accent.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: accent, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: textMuted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: textMuted, size: 20),
          ],
        ),
      ),
    );
  }
}

