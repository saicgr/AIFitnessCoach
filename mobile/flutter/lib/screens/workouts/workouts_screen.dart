import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
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
import '../home/widgets/cards/weekly_progress_card.dart';
import 'widgets/workout_planner_section.dart';
import 'widgets/exercise_preferences_card.dart';
import 'widgets/workouts_floating_options_bar.dart';
import 'widgets/upcoming_workouts_sheet.dart';
import 'widgets/favorite_workouts_sheet.dart';
import '../home/widgets/manage_gym_profiles_sheet.dart';
import '../home/widgets/week_calendar_strip.dart';
import '../home/widgets/gym_profile_switcher.dart';
import 'package:fitwiz/core/constants/branding.dart';

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
  GlobalKey get _todayWorkoutKey => TooltipAnchors.workoutsToday;

  // Scroll controller + planner anchor key. The floating launcher bar's
  // "Plan" item jumps the scroll view back to the planner section; the
  // remaining items navigate / open sheets instead of scrolling.
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _planSectionKey = GlobalKey();
  int _activeOption = 0;

  // ---- Weekly-progress memoization ----------------------------------------
  // The day/count computation in _buildContent walks the whole workouts list
  // and was re-running on EVERY rebuild (scroll, accent change, sheet open).
  // Cache the result keyed by a cheap signature of its inputs so it only
  // recomputes when the underlying data — or the current calendar day —
  // actually changes.
  String? _weeklyProgressSignature;
  _WeeklyProgress? _weeklyProgressCache;

  /// Cheap content signature of the inputs to the weekly-progress calc. Built
  /// from the screen-summary counts (when present) plus each workout's
  /// scheduled date + completion flag, and the local calendar day (so the
  /// week window rolls over correctly across midnight).
  String _weeklyProgressKey(
    List<Workout> workouts,
    WorkoutScreenSummary? summary,
  ) {
    final today = DateTime.now();
    final buf = StringBuffer()
      ..write('${today.year}-${today.month}-${today.day}|')
      ..write('${summary?.completedThisWeek}/${summary?.plannedThisWeek}|');
    for (final w in workouts) {
      buf.write('${w.scheduledDate}:${w.isCompleted};');
    }
    return buf.toString();
  }

  /// Compute (or return the memoized) weekly-progress figures.
  _WeeklyProgress _computeWeeklyProgress(
    List<Workout> workouts,
    WorkoutScreenSummary? summary,
  ) {
    final signature = _weeklyProgressKey(workouts, summary);
    final cached = _weeklyProgressCache;
    if (cached != null && _weeklyProgressSignature == signature) {
      return cached;
    }

    final now = DateTime.now();

    // Completed / planned counts — prefer the lightweight screen summary.
    final int completedThisWeek;
    final int plannedThisWeek;
    if (summary != null) {
      completedThisWeek = summary.completedThisWeek;
      plannedThisWeek = summary.plannedThisWeek;
    } else {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      completedThisWeek = workouts.where((w) {
        if (w.isCompleted != true) return false;
        if (w.scheduledDate == null) return false;
        final scheduledDate = DateTime.tryParse(w.scheduledDate!);
        if (scheduledDate == null) return false;
        return scheduledDate.isAfter(startOfWeek) &&
            scheduledDate.isBefore(endOfWeek);
      }).length;
      plannedThisWeek = workouts.where((w) {
        if (w.scheduledDate == null) return false;
        final scheduledDate = DateTime.tryParse(w.scheduledDate!);
        if (scheduledDate == null) return false;
        return scheduledDate.isAfter(startOfWeek) &&
            scheduledDate.isBefore(startOfWeek.add(const Duration(days: 7)));
      }).length;
    }

    // Per-day indicators for the ring row. Day indices are 0=Mon … 6=Sun.
    final startOfWeek = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 7));
    final completedDayIndices = <int>{};
    final scheduledDayIndices = <int>{};
    for (final w in workouts) {
      if (w.scheduledDate == null) continue;
      final scheduled = DateTime.tryParse(w.scheduledDate!);
      if (scheduled == null) continue;
      // Normalize to local calendar date so UTC-stored noon timestamps map
      // to the right weekday in the user's zone.
      final local = DateTime(scheduled.year, scheduled.month, scheduled.day);
      if (local.isBefore(startOfWeek) || !local.isBefore(endOfWeek)) continue;
      final dayIdx = local.weekday - 1;
      scheduledDayIndices.add(dayIdx);
      if (w.isCompleted == true) completedDayIndices.add(dayIdx);
    }

    final result = _WeeklyProgress(
      completedThisWeek: completedThisWeek,
      plannedThisWeek: plannedThisWeek,
      completedDayIndices: completedDayIndices,
      scheduledDayIndices: scheduledDayIndices,
    );
    _weeklyProgressSignature = signature;
    _weeklyProgressCache = result;
    return result;
  }

  @override
  void initState() {
    super.initState();
    // Collapse nav bar labels on this secondary page
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navBarLabelsExpandedProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Dispatches the floating launcher bar action for [index].
  ///
  /// 0 Plan      → scroll back to the planner section.
  /// 1 Gym       → open the manage-gym-profiles sheet.
  /// 2 Library   → exercise library.
  /// 3 Programs  → multi-week program library (B.3.1 — replaced History,
  ///               which moved into the quick-actions row).
  void _onOptionSelected(int index) {
    switch (index) {
      case 0:
        setState(() => _activeOption = 0);
        final ctx = _planSectionKey.currentContext;
        if (ctx == null) return;
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
          alignment: 0.05,
        );
        break;
      case 1:
        showGlassSheet(
          context: context,
          builder: (_) => const ManageGymProfilesSheet(),
        );
        break;
      case 2:
        context.push('/library');
        break;
      case 3:
        context.push('/workout/program-library');
        break;
    }
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
                // Top padding for the floating header (title pill row).
                // 56 = 40 pt pill + 8 pt top + 8 pt bottom from
                // _buildFloatingHeader's container.
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.of(context).padding.top + 56),
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

            // Floating options bar — docked above MainShell's bottom nav,
            // mirroring the Nutrition / Discover / You tabs. Pills jump the
            // scroll view to the matching section.
            Positioned(
              left: 0,
              right: 0,
              bottom: MediaQuery.of(context).viewPadding.bottom + 68,
              child: Center(
                child: WorkoutsFloatingOptionsBar(
                  accentColor: accentColor,
                  activeIndex: _activeOption,
                  onSelected: _onOptionSelected,
                  items: const [
                    WorkoutsOptionItem(
                        label: 'Plan', icon: Icons.calendar_today_rounded),
                    WorkoutsOptionItem(
                        label: 'Gym', icon: Icons.storefront_outlined),
                    WorkoutsOptionItem(
                        label: 'Library',
                        icon: Icons.menu_book_outlined),
                    // B.3.1 — "Programs" replaces "History" here. History
                    // moved into the quick-actions row; Programs opens the
                    // multi-week program library beside the exercise Library.
                    WorkoutsOptionItem(
                        label: 'Programs', icon: Icons.list_alt_rounded),
                  ],
                ),
              ),
            ),

            // First-run spotlight tour. Anchors + copy live in
            // `widgets/tooltips/tours/workouts_tour.dart`.
            WorkoutsTour.overlay(),
          ],
        ),
      ),
    );
  }

  /// Floating header with back button, title, and action icons
  Widget _buildFloatingHeader(
    BuildContext context,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      // Three stacked BackdropFilter blurs in the header would otherwise
      // re-rasterize on every scroll pixel of the content below. Isolating
      // the header in its own painting layer pays the blur cost once per
      // header change instead of once per scrolled pixel.
      child: RepaintBoundary(
        child: Container(
        padding: EdgeInsets.only(top: topPadding + 8, left: 16, right: 16, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Plain bold title — slimmed from the old frosted pill so the
                // header reads as one clean row and can't overflow. Secondary
                // destinations (Library / Gym / Preferences) moved into the
                // floating launcher bar.
                Expanded(
                  child: Text(
                    'Workouts',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                // Single Import icon-button — surfaces the workout-history
                // import picker sheet (file / paste / Health sync). Tray-with-
                // down-arrow reads as "bring in / import".
                _GlassmorphicButton(
                  onTap: () {
                    HapticService.light();
                    showGlassSheet(
                      context: context,
                      builder: (_) => const _ImportWorkoutsPickerSheet(),
                    );
                  },
                  isDark: isDark,
                  child: Icon(
                    Icons.move_to_inbox_outlined,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                // Workout settings gear — opens workout-specific preferences
                // (replaces the old "Prefs" item in the floating bar).
                _GlassmorphicButton(
                  onTap: () {
                    HapticService.light();
                    context.push('/settings/workout-settings');
                  },
                  isDark: isDark,
                  child: Icon(
                    Icons.settings_outlined,
                    color: accentColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                // Overflow ⋮ menu — natural home for Workouts-tab actions.
                // Currently hosts the global week-strip collapse toggle so the
                // strip can be folded away from this tab too.
                _WorkoutsOverflowMenu(
                  isDark: isDark,
                  accentColor: accentColor,
                ),
              ],
            ),
            // Tier toggle moved into Exercise Preferences → Workout Mode
            // (1st option). Header stays focused on navigation only.
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
    // Weekly progress — memoized so this whole-list walk only runs when the
    // workouts data (or the calendar day) actually changes, not on every
    // scroll / accent / sheet rebuild.
    final weekly =
        _computeWeeklyProgress(workouts, screenSummary.valueOrNull);
    final completedThisWeek = weekly.completedThisWeek;
    final plannedThisWeek = weekly.plannedThisWeek;
    final completedDayIndices = weekly.completedDayIndices;
    final scheduledDayIndices = weekly.scheduledDayIndices;

    return SliverList(
      delegate: SliverChildListDelegate([
        // Gym profile switcher + calendar tune-menu share one row — the
        // switcher fills the former empty band below the title bar, and the
        // tune icon sits inline on its right instead of wasting its own
        // line. The week strip then sits directly beneath, no gap.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 12, 2),
          child: Row(
            children: [
              const Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GymProfileSwitcher(),
                ),
              ),
              WorkoutTuneMenu(
                tint: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.textMuted
                    : AppColorsLight.textMuted,
              ),
            ],
          ),
        ),

        // Date strip + workout carousel — moved here from the home screen.
        KeyedSubtree(
          key: _planSectionKey,
          child: KeyedSubtree(
            key: _todayWorkoutKey,
            child: const WorkoutPlannerSection(),
          ),
        ),

        const SizedBox(height: 20),

        // Quick Actions Row
        KeyedSubtree(
          key: _quickActionsKey,
          child: _buildQuickActions(context, isDark, textSecondary, accentColor),
        ),

        const SizedBox(height: 16),

        // Exercise Preferences (expandable)
        KeyedSubtree(
          key: _exercisePreferencesKey,
          child: const ExercisePreferencesCard(),
        ),

        const SizedBox(height: 24),

        // Weekly Progress. Gym management + History now live in the
        // floating launcher bar, so the in-body "Managed Gym" section and
        // the duplicate History action button were removed for a cleaner
        // single scroll.
        _buildSectionHeader('THIS WEEK', textSecondary),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: WeeklyProgressCard(
            completed: completedThisWeek,
            total: plannedThisWeek > 0 ? plannedThisWeek : 5,
            isDark: isDark,
            completedDayIndices: completedDayIndices,
            scheduledDayIndices: scheduledDayIndices,
          ),
        ),
        const SizedBox(height: 24),

        // Synced Workouts (Health Connect / Apple Health) — same rich
        // visual system as the Profile tab.
        _buildSyncedWorkoutsSection(context, isDark, textSecondary),

        // "Previous Sessions" was removed — it duplicated the floating
        // bar's History launcher (full schedule/history screen). History
        // is now the single entry point for past sessions.

        // JIT Generation: No "Generate More" button needed
        // Workouts are automatically generated after each completion
        // Show a subtle info message instead
        _buildJitInfoSection(isDark, textSecondary),

        // Bottom padding — clears both MainShell's nav bar and the
        // floating options bar docked above it.
        const SizedBox(height: 168),
      ]),
    );
  }

  Widget _buildQuickActions(
    BuildContext context,
    bool isDark,
    Color textSecondary,
    Color accentColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.add_circle_outline,
              label: 'Custom',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/workout/build');
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.calendar_month_rounded,
              label: 'Upcoming',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                showUpcomingWorkoutsSheet(context, ref);
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.favorite,
              label: 'Favorites',
              color: AppColors.error,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                showFavoriteWorkoutsSheet(context, ref);
              },
            ),
          ),
          const SizedBox(width: 8),
          // B.3.1 — History moved in from the floating bar. Opens the same
          // /schedule (history) screen the floating "History" pill used to.
          // Four Expanded buttons fit on iPhone SE (320pt wide); five would
          // overflow, so History is the cap.
          Expanded(
            child: _buildQuickActionButton(
              context,
              icon: Icons.history_rounded,
              label: 'History',
              color: accentColor,
              isDark: isDark,
              onTap: () {
                HapticService.light();
                context.push('/schedule');
              },
            ),
          ),
        ],
      ),
    );
  }

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
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.0,
              color: textColor,
            ),
          ),
          if (actionText != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionText,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
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
              'Your next workout is created automatically after each session',
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

    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    if (completedWorkouts.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: elevatedColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.history, size: 32, color: textSecondary),
                const SizedBox(height: 8),
                Text(
                  'No completed workouts yet',
                  style: TextStyle(color: textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete your first workout to see it here',
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
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final typeColor = AppColors.getWorkoutTypeColor(workout.type ?? 'strength');

    // Format the date
    String dateText = '';
    if (workout.scheduledDate != null) {
      final date = DateTime.tryParse(workout.scheduledDate!);
      if (date != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final workoutDate = DateTime(date.year, date.month, date.day);
        final difference = today.difference(workoutDate).inDays;

        if (difference == 0) {
          dateText = 'Today';
        } else if (difference == 1) {
          dateText = 'Yesterday';
        } else if (difference < 7) {
          dateText = '$difference days ago';
        } else {
          dateText = '${date.day}/${date.month}/${date.year}';
        }
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Completed checkmark icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: textSecondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.check_circle,
                color: textPrimary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            // Workout details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    workout.name ?? 'Workout',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          workout.type?.toUpperCase() ?? 'STRENGTH',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                        ),
                      ),
                      // Quick workout badge
                      if (_isQuickWorkout()) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'QUICK',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 8),
                      Icon(Icons.timer_outlined, size: 12, color: textSecondary),
                      const SizedBox(width: 2),
                      Text(
                        workout.formattedDurationShort,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                      if (dateText.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          dateText,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
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
          color: palette.bg(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: palette.fg.withValues(alpha: isDark ? 0.28 : 0.35),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              bottom: -14,
              child: IgnorePointer(
                child: Transform.rotate(
                  angle: -0.21,
                  child: Icon(
                    kind.icon,
                    size: 96,
                    color: palette.fg.withValues(alpha: 0.12),
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
                                horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: palette.fg.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              kindTag.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                                color: palette.fg,
                              ),
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
                            primaryTitle,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                              height: 1.15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$dateLabel${workout.durationMinutes != null ? ' · ${workout.durationMinutes} min' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: textMuted),
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
                    sourceApp,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: palette.fg
                          .withValues(alpha: isDark ? 0.9 : 0.8),
                    ),
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

/// Glassmorphic button with blur effect
class _GlassmorphicButton extends StatelessWidget {
  /// Null when the button is hosted inside a `PopupMenuButton`, which
  /// supplies its own tap handling — the inner widget must let taps fall
  /// through to the menu rather than swallowing them.
  final VoidCallback? onTap;
  final Widget child;
  final bool isDark;

  /// Fixed 40 pt square — every caller uses the same size.
  static const double size = 40;

  const _GlassmorphicButton({
    this.onTap,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size / 2),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(size / 2),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.08),
                width: 1,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

/// Overflow ⋮ menu for the Workouts top bar. Rendered as a glassmorphic
/// icon-button so it matches the Import button beside it. Hosts the global
/// week-strip collapse/expand toggle (label reflects live
/// `weekCalendarCollapsedProvider` state) and is the natural home for any
/// future Workouts-tab overflow actions.
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
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

    return PopupMenuButton<int>(
      tooltip: 'More options',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: (value) {
        if (value == 0) {
          HapticService.selection();
          ref.read(weekCalendarCollapsedProvider.notifier).toggle();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(
                isCollapsed
                    ? Icons.unfold_more_rounded
                    : Icons.unfold_less_rounded,
                size: 18,
                color: textPrimary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isCollapsed ? 'Expand week view' : 'Collapse week view',
                  style: TextStyle(color: textPrimary),
                ),
              ),
            ],
          ),
        ),
      ],
      // PopupMenuButton supplies its own tap handling — the inner button
      // omits `onTap` so the tap reaches the menu.
      child: _GlassmorphicButton(
        isDark: isDark,
        child: Icon(
          Icons.more_vert_rounded,
          color: accentColor,
          size: 22,
        ),
      ),
    );
  }
}

/// Bottom sheet that lists every supported workout-import path. Surfaces
/// the existing `WorkoutHistoryImportScreen` and Health Connect / Apple
/// Health hooks from one entry point so users don't have to dig through
/// Settings → Training → Import Workout History.
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
                'Import workouts',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Bring your past workouts and PRs into ${Branding.appName} so the AI can pick the right weights from day one.',
                style: TextStyle(
                  fontSize: 13,
                  color: textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 18),
              _ImportSourceTile(
                icon: Icons.upload_file_rounded,
                title: 'CSV or JSON file',
                subtitle: 'Hevy, Strong, Liftin\', Fitbod, Stronger by the Day, custom CSV',
                accent: AppColors.purple,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/workout-history-import');
                },
              ),
              const SizedBox(height: 10),
              _ImportSourceTile(
                icon: Icons.edit_note_rounded,
                title: 'Type a few PRs manually',
                subtitle: 'Bench, squat, deadlift — best when you only know your top sets',
                accent: AppColors.cyan,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings/workout-history-import');
                },
              ),
              const SizedBox(height: 10),
              _ImportSourceTile(
                icon: Icons.sync_rounded,
                title: 'Health Connect / Apple Health',
                subtitle: 'Sync sessions from your watch (already syncing in the background)',
                accent: AppColors.success,
                onTap: () {
                  Navigator.of(context).pop();
                  context.push('/settings');
                },
              ),
              const SizedBox(height: 14),
              Text(
                'You can edit, undo, or remap any import afterward — nothing is destructive.',
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

/// Memoized result of the weekly-progress computation in
/// `_WorkoutsScreenState._computeWeeklyProgress`. Holds the four figures the
/// `WeeklyProgressCard` needs so the whole-list walk that produces them runs
/// at most once per data/day change instead of once per rebuild.
class _WeeklyProgress {
  /// Workouts completed in the current Mon–Sun week.
  final int completedThisWeek;

  /// Workouts scheduled in the current Mon–Sun week.
  final int plannedThisWeek;

  /// Day indices (0=Mon … 6=Sun) with at least one completed workout.
  final Set<int> completedDayIndices;

  /// Day indices (0=Mon … 6=Sun) with at least one scheduled workout.
  final Set<int> scheduledDayIndices;

  const _WeeklyProgress({
    required this.completedThisWeek,
    required this.plannedThisWeek,
    required this.completedDayIndices,
    required this.scheduledDayIndices,
  });
}
