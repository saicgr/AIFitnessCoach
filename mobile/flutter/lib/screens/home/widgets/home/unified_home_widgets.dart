import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

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
import '../../../../data/providers/sleep_score_provider.dart';
import '../../../../data/services/api_client.dart';
import '../score_colors.dart';
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

/// Shared cross-fade duration for skeleton→content (and stale→fresh)
/// transitions on every Home tile. Short enough to feel instant, long
/// enough to read as a fade rather than a hard pop.
const Duration kHomeCrossFade = Duration(milliseconds: 220);

/// Fixed height of the workout hero card. Shared by the loaded
/// `_WorkoutHeroBody`, its loading skeleton and every status state so all
/// three render at an identical size (zero layout shift on data arrival).
const double _kWorkoutHeroHeight = 132;

/// A single shimmering rounded rectangle — the building block for every
/// layout-matched Home skeleton. The shimmer sweep colours follow the
/// active theme (light/dark) via [ThemeColors] so the placeholder never
/// flashes a hardcoded grey on the wrong surface.
class _SkeletonBox extends StatelessWidget {
  final double height;
  final double radius;
  final ThemeColors c;
  const _SkeletonBox({
    required this.height,
    required this.c,
    this.radius = 8,
  });

  @override
  Widget build(BuildContext context) {
    // `cardBorder` is the subtlest theme surface tone — using it as the base
    // keeps the skeleton from out-shouting real content on either theme.
    final base = c.cardBorder;
    final highlight = c.glassSurface;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Container(
        height: height,
        decoration: BoxDecoration(
          color: base,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

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
    // Master visibility switch from the home overflow menu's "Hide day strip".
    if (ref.watch(weekCalendarHiddenProvider)) return const SizedBox.shrink();

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

    // The card cross-fades between its loading skeleton, status states and
    // the loaded hero. Every branch is sized to the SAME 132pt hero height
    // (see `_kWorkoutHeroHeight`) so real data swaps in with zero
    // layout shift — no taller/shorter "pop".
    Widget content;

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
        // Cold load → hero-shaped shimmer skeleton (matches loaded size).
        body = _heroSkeleton(c, key: const ValueKey('wk-loading'));
      } else if (dayWorkout == null) {
        final isFuture = selDay.isAfter(today);
        body = _heroStatus(
          context,
          c,
          key: const ValueKey('wk-empty'),
          msg: isFuture
              ? 'Rest day — nothing scheduled'
              : 'No workout was scheduled this day',
          accent: c.textMuted,
          iconName: 'sleep',
        );
      } else {
        // The hero body carries its own card surface + horizontal padding.
        body = _workoutRow(context, ref, c, dayWorkout,
            isToday: false, completed: dayWorkout.isCompleted == true);
      }
      // Cross-fade the body so skeleton→content (and rest-day↔workout)
      // never hard-pops as the user scrubs the week strip. The hero's
      // "SCHEDULED" badge + the highlighted today pill on the week strip
      // already tell the user they're off today and how to get back — no
      // separate "viewing past date" chip needed.
      return AnimatedSwitcher(
        duration: kHomeCrossFade,
        child: body,
      );
    }

    final state = ref.watch(todayWorkoutProvider);
    final resp = state.valueOrNull;

    // Loading / generating states — both render the hero-shaped skeleton so
    // the swap to the real hero is a pure cross-fade with no resize.
    if (state.isLoading && !state.hasValue) {
      content = _heroSkeleton(c, key: const ValueKey('today-loading'));
    } else if (resp?.isGenerating == true &&
        resp?.hasDisplayableContent != true) {
      content = _heroSkeleton(c, key: const ValueKey('today-generating'));
    } else {
      // Resolve today's workout. /workouts/today is authoritative when it
      // returns one, but it resolves "today" off the gym-profile schedule —
      // a workout rescheduled onto a non-profile day (a "Do this today"
      // move) is NOT returned even though its scheduled_date is today. So
      // when todayWorkout is null, fall back to a workoutsProvider row
      // dated today — the SAME source the Workouts-tab carousel trusts —
      // before dropping to the generic future nextWorkout.
      final todayKey = _dateKey(today);
      Workout? todayWorkout = resp?.todayWorkout?.toWorkout();
      if (todayWorkout == null) {
        final all =
            ref.watch(workoutsProvider).valueOrNull ?? const <Workout>[];
        final hits = <Workout>[];
        for (final w in all) {
          final raw = w.scheduledDate;
          if (raw == null) continue;
          final d = raw.length >= 10 ? raw.substring(0, 10) : raw;
          if (d == todayKey) hits.add(w);
        }
        if (hits.isNotEmpty) {
          // Prefer a not-yet-completed workout if the day has several.
          hits.sort((a, b) => (a.isCompleted == true ? 1 : 0)
              .compareTo(b.isCompleted == true ? 1 : 0));
          todayWorkout = hits.first;
        }
      }

      if (resp?.completedToday == true ||
          (todayWorkout != null && todayWorkout.isCompleted == true)) {
        content = _heroStatus(context, c,
            key: const ValueKey('today-complete'),
            msg: 'Workout complete — great job today!',
            accent: c.success,
            iconName: 'check');
      } else {
        final workout = todayWorkout ?? resp?.nextWorkout?.toWorkout();
        if (workout == null) {
          // Rest day / nothing scheduled.
          content = _heroStatus(context, c,
              key: const ValueKey('today-rest'),
              msg: 'Rest day — no workout scheduled',
              accent: c.textMuted,
              iconName: 'sleep');
        } else {
          // "Today" badge only when this is the workout actually
          // resolved/dated for today — not the generic nextWorkout
          // fallback (a genuine future workout stays badged "Scheduled").
          final isToday =
              todayWorkout != null || resp?.hasWorkoutToday == true;
          // The hero body carries its own card surface + horizontal padding.
          content = KeyedSubtree(
            key: ValueKey('today-workout-${workout.id}'),
            child: _workoutRow(context, ref, c, workout,
                isToday: isToday, completed: false),
          );
        }
      }
    }

    return AnimatedSwitcher(
      duration: kHomeCrossFade,
      child: content,
    );
  }

  /// Hero-shaped shimmer skeleton — 132pt tall, 18pt radius, exactly the
  /// dimensions of the loaded `_WorkoutHeroBody`. Wrapped in [kHomeHPad] so
  /// it occupies the identical footprint and there is zero layout shift when
  /// the real hero cross-fades in.
  Widget _heroSkeleton(ThemeColors c, {required Key key}) {
    return Padding(
      key: key,
      padding: kHomeHPad,
      child: _SkeletonBox(
        height: _kWorkoutHeroHeight,
        radius: 18,
        c: c,
      ),
    );
  }

  /// Hero-shaped status card (rest day / complete / empty). Uses the SAME
  /// 132pt height as the loaded hero so the card never changes size between
  /// states. Replaces the old small `_shell` container that caused a visible
  /// shrink-then-grow when a workout finally loaded.
  Widget _heroStatus(
    BuildContext context,
    ThemeColors c, {
    required Key key,
    required String msg,
    required Color accent,
    String iconName = 'workout',
  }) {
    return Padding(
      key: key,
      padding: kHomeHPad,
      child: Container(
        height: _kWorkoutHeroHeight,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.elevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: c.cardBorder),
        ),
        alignment: Alignment.centerLeft,
        child: _statusBody(c, msg, accent: accent, iconName: iconName),
      ),
    );
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
  // Hero height comes from the shared top-level `_kWorkoutHeroHeight`.

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
      // A9 (pre-cache): the hero is above-the-fold — warm the decoded image
      // into Flutter's ImageCache so it paints instantly when the card mounts
      // instead of fading in a frame or two later. Deferred to post-frame so
      // a valid context (with MediaQuery) is available for precacheImage.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _precacheHeroImage(cached);
      });
      return;
    }
    _fetchImage(name);
  }

  /// A9 (pre-cache): warm the exercise illustration into the global image
  /// cache. Uses the same `CachedNetworkImageProvider` the card paints with
  /// (and the same decode bounds) so the precache populates the exact cache
  /// entry the `CachedNetworkImage` widget will hit — no double download.
  void _precacheHeroImage(String url) {
    if (!mounted) return;
    precacheImage(
      CachedNetworkImageProvider(url, maxWidth: 600, maxHeight: 360),
      context,
    ).catchError((_) {
      // Best-effort warm-up — a failed precache just means the
      // CachedNetworkImage placeholder shows briefly. No user-facing impact.
    });
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
          // A9 (pre-cache): warm the decoded image before it paints.
          _precacheHeroImage(url);
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
        // Card tap → workout detail screen, matching the Workouts-tab hero
        // carousel (HeroWorkoutCard inCarousel=true). Starting the workout
        // is the play-button's job below; the rest of the card opens detail.
        HapticService.medium();
        context.push('/workout/${workout.id}', extra: workout);
      },
      // A5: the image-backed hero is the heaviest paint on Home (network
      // image + gradient scrim). Isolating it in a RepaintBoundary stops a
      // sibling tile's repaint (e.g. the per-second fasting tick) from
      // forcing this expensive layer to re-rasterise.
      child: RepaintBoundary(
        child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: _kWorkoutHeroHeight,
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
                        // Play button — Material+InkWell, NOT a nested
                        // GestureDetector. Two nested GestureDetectors
                        // with onTap both register tap recognizers in
                        // the gesture arena, and the inner-deepest-wins
                        // rule is not actually guaranteed across Flutter
                        // versions / hit-test paths — in practice taps
                        // here were bleeding to the outer card handler
                        // and opening the detail screen instead of
                        // starting the workout. InkWell claims taps via
                        // the Material gesture system, which reliably
                        // beats a parent GestureDetector (same pattern
                        // the Workouts-tab HeroWorkoutCard uses for its
                        // START button via ElevatedButton.icon).
                        Container(
                          width: 48,
                          height: 48,
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
                          child: Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                HapticService.medium();
                                if (widget.completed) {
                                  context.push(
                                      '/workout-summary/${workout.id}?tab=summary');
                                } else {
                                  context.push('/active-workout',
                                      extra: workout);
                                }
                              },
                              child: Center(
                                child: LineIcon(
                                    widget.completed ? 'check' : 'play',
                                    color: accent,
                                    size: 22),
                              ),
                            ),
                          ),
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
      // A3: while the exercise image URL resolves, sweep a soft shimmer over
      // the accent gradient instead of a blocking spinner. The fill itself is
      // already the final card size, so this is purely a texture change — the
      // real image cross-fades in over it with no layout shift.
      child: _loadingImage
          ? Shimmer.fromColors(
              baseColor: Colors.white.withValues(alpha: 0.04),
              highlightColor: Colors.white.withValues(alpha: 0.22),
              period: const Duration(milliseconds: 1200),
              child: const ColoredBox(color: Colors.white),
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
      // A5: paint-isolate the nutrition card. It's a multi-layer card
      // (macro bars + two sub-tiles); a sibling Home tile rebuilding should
      // not drag this whole surface into a repaint.
      child: RepaintBoundary(
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
                  // A5: the fasting tile watches `fastingTimerProvider`,
                  // which ticks every second. RepaintBoundary confines that
                  // per-second repaint to the tile alone — the Water tile,
                  // macro bars and the rest of the nutrition card stay put.
                  const Expanded(
                    child: RepaintBoundary(child: _NutritionFastingTile()),
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

    // Sleep tile shows the live computed sleep score + duration + bedtime
    // from the shared sleepScoreProvider — matches the Sleep detail screen.
    final sleepAsync = ref.watch(sleepScoreProvider);

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
              onTap: () {
                try {
                  context.push('/neat');
                } catch (_) {
                  context.go('/profile');
                }
              },
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _SleepTile(c: c, sleepAsync: sleepAsync),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k' : '$n';
}

/// Sleep tile — primary line shows the 0-100 score + tier label, secondary
/// shows duration + bedtime. Reuses the shared `sleepScoreProvider` so the
/// home tile and the Sleep detail screen never disagree.
class _SleepTile extends StatelessWidget {
  final ThemeColors c;
  final AsyncValue<SleepScoreSnapshot?> sleepAsync;
  const _SleepTile({required this.c, required this.sleepAsync});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        try {
          context.push('/health/sleep');
        } catch (_) {
          context.go('/profile');
        }
      },
      behavior: HitTestBehavior.opaque,
      child: sleepAsync.when(
        data: (snapshot) => _content(snapshot),
        loading: () => _MetricTile(
          c: c,
          iconName: 'sleep',
          tint: AppColors.macroProtein,
          label: 'SLEEP',
          value: '…',
          sub: 'last night',
          onTap: null,
        ),
        error: (_, __) => _MetricTile(
          c: c,
          iconName: 'sleep',
          tint: AppColors.macroProtein,
          label: 'SLEEP',
          value: 'No data',
          sub: 'last night',
          onTap: null,
        ),
      ),
    );
  }

  Widget _content(SleepScoreSnapshot? snapshot) {
    final score = snapshot?.score;
    final summary = snapshot?.summary;

    if (score == null || (summary?.totalMinutes ?? 0) == 0) {
      return _MetricTile(
        c: c,
        iconName: 'sleep',
        tint: AppColors.macroProtein,
        label: 'SLEEP',
        value: 'No data',
        sub: 'last night',
        onTap: null,
      );
    }

    final tier = tierFor(score.total);
    final totalMin = summary!.totalMinutes;
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final bed = summary.bedTime;
    final bedString = bed != null
        ? '${bed.hour > 12 ? bed.hour - 12 : (bed.hour == 0 ? 12 : bed.hour)}:'
            '${bed.minute.toString().padLeft(2, '0')}'
            '${bed.hour >= 12 ? 'pm' : 'am'}'
        : '';
    final sub = bedString.isNotEmpty
        ? '${h}h ${m}m · $bedString'
        : '${h}h ${m}m last night';

    return _MetricTile(
      c: c,
      iconName: 'sleep',
      tint: tier.color,
      label: 'SLEEP',
      value: '${score.total} / ${tier.label}',
      sub: sub,
      onTap: null,
    );
  }
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
  /// Optional — when null the tile renders without ink/feedback so an outer
  /// GestureDetector (e.g. _SleepTile) can own the tap behavior.
  final VoidCallback? onTap;
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
