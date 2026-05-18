import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/widgets/line_icon.dart';
import '../../../../core/providers/week_start_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/providers/gym_profile_provider.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/home_sections_provider.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';
import '../../../../data/services/image_url_cache.dart';
import '../../../../widgets/health_connect_sheet.dart';
import '../../../nutrition/log_meal_sheet.dart';
import '../week_calendar_strip.dart';
import '../workout_options_sheet.dart';

/// ============================================================================
/// Unified home (v27) section widgets.
///
/// Each is a self-contained `ConsumerWidget` bound to the real providers and
/// themed through `ref.colors(context)` — light/dark + per-gym accent follow
/// automatically (no hardcoded hex). Dropped into the home `CustomScrollView`
/// by `home_screen.dart`.
/// ============================================================================

const double kHomeGap = 14.0;
const EdgeInsets kHomeHPad = EdgeInsets.symmetric(horizontal: 16);

// ----------------------------------------------------------------------------
// Compact week strip — matches the Nutrition tab's light date strip
// (weekday letter + date number, today as a filled accent pill, subtle
// status dot). Reuses the shared WeekCalendarStrip with home-appropriate
// wiring; tapping a day drives `selectedHomeDateProvider` in-place.
// ----------------------------------------------------------------------------
class HomeWeekStrip extends ConsumerWidget {
  const HomeWeekStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final activeGymProfile = ref.watch(activeGymProfileProvider);
    final workoutDays = (activeGymProfile?.workoutDays.isNotEmpty == true)
        ? activeGymProfile!.workoutDays
        : user.workoutDays;
    if (workoutDays.isEmpty) return const SizedBox.shrink();

    final weekConfig = ref.watch(weekDisplayConfigProvider);
    final workoutsAsync = ref.watch(workoutsProvider);
    final todayResp = ref.watch(todayWorkoutProvider).valueOrNull;
    final selectedDate = ref.watch(selectedHomeDateProvider);

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = weekConfig.weekStart(today);

    // Map the selected date to a data-model weekday index (0=Mon). Only days
    // inside the visible week can be selected on the strip; a selected date
    // outside this week falls back to today's highlight.
    final selDayOnly =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final inThisWeek = !selDayOnly.isBefore(weekStart) &&
        selDayOnly.isBefore(weekStart.add(const Duration(days: 7)));
    final selectedDayIndex =
        inThisWeek ? (selDayOnly.weekday - 1) : (now.weekday - 1);

    final merged = <Workout>[...(workoutsAsync.valueOrNull ?? [])];
    void mergeIfNew(Workout? w) {
      if (w == null || merged.any((e) => e.id == w.id)) return;
      merged.add(w);
    }
    mergeIfNew(todayResp?.todayWorkout?.toWorkout());
    mergeIfNew(todayResp?.completedWorkout?.toWorkout());
    for (final extra in todayResp?.extraTodayWorkouts ?? const []) {
      mergeIfNew(extra.toWorkout());
    }

    final Map<int, bool?> statusMap = {};
    for (int d = 0; d < 7; d++) {
      final i = weekConfig.displayOrder[d];
      if (!workoutDays.contains(i)) {
        statusMap[i] = null;
        continue;
      }
      final dayDate = weekStart.add(Duration(days: d));
      final key =
          '${dayDate.year}-${dayDate.month.toString().padLeft(2, '0')}-${dayDate.day.toString().padLeft(2, '0')}';
      final dayWorkouts = merged.where((w) {
        final raw = w.scheduledDate;
        if (raw == null) return false;
        return (raw.length >= 10 ? raw.substring(0, 10) : raw) == key;
      });
      final done = dayWorkouts.any(
        (w) => w.isCompleted == true && !w.isSyncedFromHealthApp,
      );
      statusMap[i] = (dayWorkouts.isNotEmpty && done) ? true : false;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: WeekCalendarStrip(
        workoutDays: workoutDays,
        workoutStatusMap: statusMap,
        selectedDayIndex: selectedDayIndex,
        onDaySelected: (dataIndex) {
          HapticService.selection();
          // Tapping a day changes the home data IN-PLACE — resolve the
          // tapped weekday index back to a concrete date in the visible
          // week and store it. Cards downstream react to this provider.
          final displayIndex = weekConfig.displayOrder.indexOf(dataIndex);
          final tapped = weekStart
              .add(Duration(days: displayIndex >= 0 ? displayIndex : 0));
          ref.read(selectedHomeDateProvider.notifier).state =
              DateTime(tapped.year, tapped.month, tapped.day);
        },
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Workout card — compact launch card with play + ⋮ menu.
// ----------------------------------------------------------------------------
class HomeWorkoutCard extends ConsumerWidget {
  const HomeWorkoutCard({super.key});

  static String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final selectedDate = ref.watch(selectedHomeDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final viewingToday = selDay == today;

    // --- Non-today selection: drive the card off workoutsProvider, filtered
    // by scheduledDate. The /today provider only ever knows about today. ---
    if (!viewingToday) {
      final workoutsAsync = ref.watch(workoutsProvider);
      final key = _dateKey(selDay);
      Workout? dayWorkout;
      for (final w in workoutsAsync.valueOrNull ?? const <Workout>[]) {
        final raw = w.scheduledDate;
        if (raw == null) continue;
        final d = raw.length >= 10 ? raw.substring(0, 10) : raw;
        if (d == key) {
          dayWorkout = w;
          break;
        }
      }

      Widget body;
      if (workoutsAsync.isLoading && !workoutsAsync.hasValue) {
        body = _shell(context, c,
            child: _statusBody(c, 'Loading…', accent: c.accent));
      } else if (dayWorkout == null) {
        final isFuture = selDay.isAfter(today);
        body = _shell(
          context,
          c,
          child: _statusBody(
            c,
            isFuture
                ? 'Rest day — nothing scheduled'
                : 'No workout was scheduled this day',
            accent: c.textMuted,
            iconName: 'sleep',
          ),
        );
      } else {
        // The hero body carries its own card surface + horizontal padding.
        body = _workoutRow(context, ref, c, dayWorkout,
            isToday: false, completed: dayWorkout.isCompleted == true);
      }
      return Column(
        children: [
          _viewingBanner(context, ref, c, selDay),
          body,
        ],
      );
    }

    final state = ref.watch(todayWorkoutProvider);
    final resp = state.valueOrNull;

    // Loading / generating states.
    if (state.isLoading && !state.hasValue) {
      return _shell(context, c,
          child: _statusBody(c, 'Loading your workout…', accent: c.accent));
    }
    if (resp?.isGenerating == true && resp?.hasDisplayableContent != true) {
      return _shell(context, c,
          child: _statusBody(
              c, resp?.generationMessage ?? 'Generating your workout…',
              accent: c.accent));
    }

    final summary = resp?.todayWorkout ?? resp?.nextWorkout;
    final workout = summary?.toWorkout();

    // Rest day / nothing scheduled.
    if (workout == null) {
      if (resp?.completedToday == true) {
        return _shell(context, c,
            child: _statusBody(c, 'Workout complete — great job today!',
                accent: c.success, iconName: 'check'));
      }
      return _shell(context, c,
          child: _statusBody(c, 'Rest day — no workout scheduled',
              accent: c.textMuted, iconName: 'sleep'));
    }

    final isToday = resp?.hasWorkoutToday == true;
    // The hero body carries its own card surface + horizontal padding.
    return _workoutRow(context, ref, c, workout,
        isToday: isToday, completed: false);
  }

  /// Small "viewing <date>" affordance with a tap-to-return-to-today action.
  Widget _viewingBanner(
      BuildContext context, WidgetRef ref, ThemeColors c, DateTime date) {
    final now = DateTime.now();
    final isPast = date.isBefore(DateTime(now.year, now.month, now.day));
    final label = _friendlyDate(date);
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: GestureDetector(
        onTap: () {
          HapticService.selection();
          ref.read(selectedHomeDateProvider.notifier).state =
              DateTime(now.year, now.month, now.day);
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: c.accent.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.accent.withValues(alpha: 0.30)),
          ),
          child: Row(
            children: [
              LineIcon(isPast ? 'refresh' : 'spark', size: 13, color: c.accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Viewing $label',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary),
                ),
              ),
              Text('Back to today',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: c.accent)),
            ],
          ),
        ),
      ),
    );
  }

  static String _friendlyDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  /// The shared workout body — a compact image hero. Renders the first
  /// exercise's photo as a background behind an accent-tinted gradient scrim,
  /// with the workout name + meta legible on top and a prominent play button.
  /// Returned without padding; callers wrap with [kHomeHPad].
  Widget _workoutRow(
      BuildContext context, WidgetRef ref, ThemeColors c, Workout workout,
      {required bool isToday, required bool completed}) {
    return Padding(
      padding: kHomeHPad,
      child: _WorkoutHeroBody(
        workout: workout,
        isToday: isToday,
        completed: completed,
      ),
    );
  }

  Widget _shell(BuildContext context, ThemeColors c, {required Widget child}) {
    return Padding(
      padding: kHomeHPad,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        child: child,
      ),
    );
  }

  Widget _statusBody(ThemeColors c, String msg,
      {required Color accent, String iconName = 'workout'}) {
    return Row(
      children: [
        LineIcon(iconName, color: accent, size: 22),
        const SizedBox(width: 11),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary)),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------------------
// Workout hero body — a compact image-backed hero. Fetches the first
// exercise's photo from `/exercise-images/{name}`, caches it via
// `ImageUrlCache`, and renders it as a `CachedNetworkImage` background behind
// an accent-tinted gradient scrim. Kept compact (fixed height) so it reads as
// a home card, not the full-screen hero. Ported from `HeroWorkoutCard`.
// ----------------------------------------------------------------------------
class _WorkoutHeroBody extends ConsumerStatefulWidget {
  final Workout workout;
  final bool isToday;
  final bool completed;
  const _WorkoutHeroBody({
    required this.workout,
    required this.isToday,
    required this.completed,
  });

  @override
  ConsumerState<_WorkoutHeroBody> createState() => _WorkoutHeroBodyState();
}

class _WorkoutHeroBodyState extends ConsumerState<_WorkoutHeroBody> {
  static const double _kHeroHeight = 132;

  String? _imageUrl;
  bool _loadingImage = true;

  @override
  void initState() {
    super.initState();
    _resolveImage();
  }

  @override
  void didUpdateWidget(covariant _WorkoutHeroBody old) {
    super.didUpdateWidget(old);
    // The card is reused across date selection — re-resolve when the
    // underlying workout (and thus its first exercise) changes.
    if (old.workout.id != widget.workout.id ||
        _firstExerciseName(old.workout) != _firstExerciseName(widget.workout)) {
      _imageUrl = null;
      _loadingImage = true;
      _resolveImage();
    }
  }

  /// Name of the workout's first real exercise, or null if there isn't one.
  static String? _firstExerciseName(Workout w) {
    final exercises = w.exercises;
    if (exercises.isEmpty) return null;
    final name = exercises.first.name;
    if (name.isEmpty || name == 'Exercise') return null;
    return name;
  }

  /// Check the cache synchronously (no loading flash), else fetch async.
  void _resolveImage() {
    final name = _firstExerciseName(widget.workout);
    if (name == null) {
      _loadingImage = false;
      return;
    }
    final cached = ImageUrlCache.get(name);
    if (cached != null) {
      _imageUrl = cached;
      _loadingImage = false;
      return;
    }
    _fetchImage(name);
  }

  Future<void> _fetchImage(String exerciseName) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(
        '/exercise-images/${Uri.encodeComponent(exerciseName)}',
      );
      if (response.statusCode == 200 && response.data != null) {
        final url = response.data['url'] as String?;
        if (url != null && mounted) {
          await ImageUrlCache.set(exerciseName, url);
          if (!mounted) return;
          setState(() {
            _imageUrl = url;
            _loadingImage = false;
          });
          return;
        }
      }
    } catch (_) {
      // No exercise image available — fall through to the accent gradient.
    }
    if (mounted) setState(() => _loadingImage = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.colors(context);
    final workout = widget.workout;
    final accent = widget.completed ? c.success : c.accent;

    final type = (workout.type ?? 'strength').toUpperCase();
    final mins = workout.durationMinutes ?? workout.durationMinutesMax ?? 0;
    final exCount = workout.exerciseCount;
    final prefix =
        widget.completed ? 'DONE' : (widget.isToday ? 'TODAY' : 'SCHEDULED');
    final meta = '$prefix · $type'
        '${mins > 0 ? ' · ${mins}m' : ''}'
        '${exCount > 0 ? ' · $exCount exercises' : ''}';

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        context.push('/active-workout', extra: workout);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: _kHeroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Background image (or accent gradient while loading / missing).
              _buildBackground(c, accent),
              // Accent-tinted gradient scrim — keeps the name legible over any
              // image and gives the card its energy.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                    colors: [
                      accent.withValues(alpha: 0.92),
                      accent.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.18),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),
              // Foreground content.
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LineIcon(
                                  widget.completed ? 'check' : 'workout',
                                  size: 12,
                                  color: Colors.white),
                              const SizedBox(width: 5),
                              Text(
                                prefix,
                                style: const TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        _OverImageMenuButton(workout: workout),
                      ],
                    ),
                    const Spacer(),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                workout.name ?? 'Workout',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  height: 1.12,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 6,
                                      color: Color(0x66000000),
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                meta,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.88),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.22),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: LineIcon(
                              widget.completed ? 'check' : 'play',
                              color: accent,
                              size: 22),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The background layer: the exercise photo, a loading shimmer, or — when no
  /// image is available — a pure accent gradient so the card never looks bare.
  Widget _buildBackground(ThemeColors c, Color accent) {
    if (_imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: _imageUrl!,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        // Limit decoded size in the memory cache (matches HeroWorkoutCard).
        memCacheWidth: 600,
        memCacheHeight: 360,
        placeholder: (_, __) => _accentFill(accent),
        errorWidget: (_, __, ___) => _accentFill(accent),
      );
    }
    // Loading or no-image: an accent gradient fill keeps the hero energetic.
    return _accentFill(accent);
  }

  Widget _accentFill(Color accent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent, accent.withValues(alpha: 0.7)],
        ),
      ),
      child: _loadingImage
          ? Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white.withValues(alpha: 0.6),
                ),
              ),
            )
          : null,
    );
  }
}

/// ⋮ menu button styled for placement over the hero image — frosted white
/// chip instead of the glass-surface chip used on plain cards.
class _OverImageMenuButton extends ConsumerWidget {
  final Workout workout;
  const _OverImageMenuButton({required this.workout});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        showWorkoutOptionsSheet(context, ref, workout);
      },
      child: Container(
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(9),
        ),
        child: const LineIcon('more', size: 16, color: Colors.white),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Nutrition card — calories left + P/C/F vs goals + integrated water row.
// ----------------------------------------------------------------------------
class HomeNutritionCard extends ConsumerWidget {
  const HomeNutritionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final nutrition = ref.watch(nutritionProvider);
    final summary = nutrition.todaySummary;

    final prefs = ref.watch(nutritionPreferencesProvider);
    final calTarget = prefs.currentCalorieTarget;
    final proteinTarget = prefs.currentProteinTarget;
    final carbsTarget = prefs.currentCarbsTarget;
    final fatTarget = prefs.currentFatTarget;

    final eatenCal = summary?.totalCalories ?? 0;
    final eatenP = (summary?.totalProteinG ?? 0).round();
    final eatenC = (summary?.totalCarbsG ?? 0).round();
    final eatenF = (summary?.totalFatG ?? 0).round();

    final calLeft = calTarget - eatenCal;
    final over = calLeft < 0;

    final hydration = ref.watch(hydrationProvider);
    final userId = ref.watch(currentUserProvider).valueOrNull?.id;
    const mlPerCup = 250;
    final cups = ((hydration.todaySummary?.totalMl ?? 0) / mlPerCup).floor();
    final cupGoal = (hydration.dailyGoalMl > 0 ? hydration.dailyGoalMl : 2000) ~/
        mlPerCup;

    return Padding(
      padding: kHomeHPad,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineIcon('nutrition', size: 15, color: c.textMuted),
                const SizedBox(width: 6),
                Text('NUTRITION',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: c.textMuted)),
                const Spacer(),
                Text(
                  over ? '${-calLeft} over' : '$calLeft',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: over ? c.warning : c.textPrimary),
                ),
                Text(over ? ' kcal' : ' kcal left',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: c.textMuted)),
                const SizedBox(width: 8),
                _PlusButton(
                  color: AppColors.macroFat,
                  // The "+" opens the food-log sheet directly. Switch to the
                  // Nutrition branch FIRST (`go`, not `push` — /nutrition is a
                  // shell nav tab; pushing stacks a 2nd NutritionScreen and
                  // its static GlobalKeys collide), then open the log sheet so
                  // dismissing it lands the user on Nutrition with the meal.
                  onTap: () {
                    HapticService.light();
                    context.go('/nutrition');
                    Future.microtask(() {
                      if (context.mounted) showLogMealSheet(context, ref);
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 11),
            _MacroBar(
                label: 'Protein',
                eaten: eatenP,
                goal: proteinTarget,
                color: AppColors.macroProtein,
                c: c),
            const SizedBox(height: 7),
            _MacroBar(
                label: 'Carbs',
                eaten: eatenC,
                goal: carbsTarget,
                color: AppColors.macroCarbs,
                c: c),
            const SizedBox(height: 7),
            _MacroBar(
                label: 'Fat',
                eaten: eatenF,
                goal: fatTarget,
                color: AppColors.macroFat,
                c: c),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Divider(height: 1, color: c.cardBorder),
            ),
            // Water + Fasting sit side-by-side as two compact tiles.
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _NutriTileShell(
                      c: c,
                      iconName: 'water',
                      tint: AppColors.cyan,
                      label: 'Water',
                      fraction: cupGoal > 0 ? cups / cupGoal : 0,
                      onTap: () => context.go('/nutrition'),
                      trailing: _PlusButton(
                        color: AppColors.cyan,
                        onTap: () {
                          HapticService.light();
                          if (userId != null) {
                            ref.read(hydrationProvider.notifier).quickLog(
                                userId: userId, amountMl: mlPerCup);
                          } else {
                            context.go('/nutrition');
                          }
                        },
                      ),
                      value: Text('$cups / $cupGoal cups',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: c.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(child: _NutritionFastingTile()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fasting tile inside the nutrition card — sits beside the Water tile as
/// one of two compact squares. Binds to `fastingProvider`; when a fast is
/// active it watches `fastingTimerProvider` so the elapsed value ticks every
/// second. Tappable → `/fasting`.
class _NutritionFastingTile extends ConsumerWidget {
  const _NutritionFastingTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final fast = ref.watch(fastingProvider).activeFast;
    final elapsedSeconds = ref.watch(fastingTimerProvider).value ?? 0;
    final bool active = fast != null;

    double fraction = 0;
    Widget value;
    if (active) {
      final goalMinutes = fast.goalDurationMinutes;
      final elapsedMinutes = elapsedSeconds ~/ 60;
      fraction = goalMinutes > 0
          ? (elapsedMinutes / goalMinutes).clamp(0.0, 1.0)
          : 0.0;
      value = Text('${elapsedMinutes ~/ 60}h ${elapsedMinutes % 60}m',
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: c.textPrimary));
    } else {
      value = Text('Start a fast →',
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.textMuted));
    }

    return _NutriTileShell(
      c: c,
      iconName: 'fasting',
      tint: AppColors.cyan,
      label: 'Fasting',
      fraction: fraction,
      value: value,
      onTap: () {
        HapticService.light();
        context.push('/fasting');
      },
    );
  }
}

/// Shared chrome for the two side-by-side nutrition-card tiles (Water,
/// Fasting): tinted icon chip + label (+ optional trailing) · value · track.
class _NutriTileShell extends StatelessWidget {
  final ThemeColors c;
  final String iconName;
  final Color tint;
  final String label;
  final Widget value;
  final double fraction;
  final VoidCallback onTap;
  final Widget? trailing;

  const _NutriTileShell({
    required this.c,
    required this.iconName,
    required this.tint,
    required this.label,
    required this.value,
    required this.fraction,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: c.glassSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: LineIcon(iconName, size: 15, color: tint),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 9),
            value,
            const SizedBox(height: 8),
            _Track(
                fraction: fraction.clamp(0.0, 1.0), color: tint, c: c),
          ],
        ),
      ),
    );
  }
}

class _MacroBar extends StatelessWidget {
  final String label;
  final int eaten;
  final int goal;
  final Color color;
  final ThemeColors c;
  const _MacroBar({
    required this.label,
    required this.eaten,
    required this.goal,
    required this.color,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: c.textPrimary)),
            const Spacer(),
            Text('$eaten / $goal g',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted)),
          ],
        ),
        const SizedBox(height: 5),
        _Track(fraction: goal > 0 ? eaten / goal : 0, color: color, c: c),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  final double fraction;
  final Color color;
  final ThemeColors c;
  const _Track({required this.fraction, required this.color, required this.c});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: LinearProgressIndicator(
        value: fraction.clamp(0.0, 1.0),
        minHeight: 7,
        backgroundColor: c.cardBorder,
        valueColor: AlwaysStoppedAnimation<Color>(color),
      ),
    );
  }
}

class _PlusButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _PlusButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: LineIcon('plus', size: 15, color: color),
      ),
    );
  }
}

// ----------------------------------------------------------------------------
// Metric pair — Activity · Sleep. (Fasting now lives in the nutrition card.)
// ----------------------------------------------------------------------------
class HomeMetricTrio extends ConsumerWidget {
  const HomeMetricTrio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final activity = ref.watch(dailyActivityProvider).today;
    final healthConnected = ref.watch(healthSyncProvider).isConnected;

    // Health gates the Activity + Sleep tiles. When it's off, two identical
    // "Connect" tiles read as broken — show ONE combined connect prompt.
    if (!healthConnected) {
      return Padding(
        padding: kHomeHPad,
        child: _HealthConnectPrompt(c: c),
      );
    }

    final steps = activity?.steps ?? 0;
    final burned = (activity?.caloriesBurned ?? 0).round();
    final sleepMin = activity?.sleepMinutes;

    return Padding(
      padding: kHomeHPad,
      child: Row(
        children: [
          Expanded(
            child: _MetricTile(
              c: c,
              iconName: 'activity',
              tint: AppColors.success,
              label: 'ACTIVITY',
              value: _fmt(steps),
              sub: '$burned kcal burned',
              // `go` not `push` — /profile is a shell nav tab.
              onTap: () => context.go('/profile'),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _MetricTile(
              c: c,
              iconName: 'sleep',
              tint: AppColors.macroProtein,
              label: 'SLEEP',
              value: sleepMin != null
                  ? '${sleepMin ~/ 60}h ${sleepMin % 60}m'
                  : 'No data',
              sub: 'last night',
              onTap: () => context.go('/profile'),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

/// Combined "Connect Apple Health" prompt — shown in place of the metric trio
/// when health isn't connected. One polished card (icon + value-prop + button)
/// instead of three confusing "Connect" tiles. The Connect button opens the
/// same Health Connect flow the Activity tile used to route to.
class _HealthConnectPrompt extends ConsumerWidget {
  final ThemeColors c;
  const _HealthConnectPrompt({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        HapticService.selection();
        showHealthConnectSheet(context, ref);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: LineIcon('activity', size: 22, color: AppColors.success),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Connect Apple Health',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'See your steps, calories & sleep on your home screen',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                      color: c.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [c.accent, c.accent.withValues(alpha: 0.78)],
                ),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Text(
                'Connect',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final ThemeColors c;
  final String iconName;
  final Color tint;
  final String label;
  final String value;
  final String sub;
  final VoidCallback onTap;
  const _MetricTile({
    required this.c,
    required this.iconName,
    required this.tint,
    required this.label,
    required this.value,
    required this.sub,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: c.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineIcon(iconName, size: 14, color: tint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: c.textMuted)),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: c.textPrimary)),
            const SizedBox(height: 3),
            Text(sub,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
