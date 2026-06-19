import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/widgets/line_icon.dart';
import '../../../../core/providers/week_start_provider.dart';
import '../../../../core/theme/theme_colors.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/providers/gym_profile_provider.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/home_sections_provider.dart';
import '../../../../data/providers/nutrition_preferences_provider.dart';
import '../../../../data/providers/scores_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/repositories/hydration_repository.dart';
import '../../../../data/repositories/nutrition_repository.dart';
import '../../../../data/repositories/workout_repository.dart';
import '../../../../data/providers/sleep_score_provider.dart';
import '../../../../data/providers/user_history_snapshot_provider.dart';
import '../../../../data/services/api_client.dart';
import '../../../../data/providers/consistency_provider.dart';
import '../../../../shareables/adapters/workout_adapter.dart';
import '../../../../shareables/shareable_sheet.dart';
import '../../../../widgets/main_shell.dart' show floatingNavBarVisibleProvider;
import '../../../settings/sections/social_privacy_section.dart'
    show publicShareLinksProvider;
import '../../../../services/strain_recommendation_service.dart';
import '../score_colors.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/services/health_service.dart';
import '../../../../data/services/image_url_cache.dart';
import '../../../../widgets/health_connect_sheet.dart';
import '../../../../l10n/generated/app_localizations.dart';
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
              ? AppLocalizations.of(context)!.unifiedHomeWidgetsRestDayNothingScheduled
              : AppLocalizations.of(context)!.unifiedHomeWidgetsNoWorkoutWasScheduled,
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

    // Loading / generating states — render NOTHING (collapse) rather than a
    // hero-shaped grey skeleton box. On cold start the cache resolves in
    // ~1-3s, and a large empty placeholder reads as "broken"; the user would
    // rather the hero simply appear (cross-faded by the AnimatedSwitcher
    // below) once there's real content than stare at a blank box first.
    if (state.isLoading && !state.hasValue) {
      content = const SizedBox.shrink(key: ValueKey('today-loading'));
    } else if (resp?.isGenerating == true &&
        resp?.hasDisplayableContent != true) {
      content = const SizedBox.shrink(key: ValueKey('today-generating'));
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
        // Mirror the Workouts-tab carousel's completed-state: a blurred shot of
        // the workout's exercise art behind a frosted-green scrim with a big
        // green check, "Workout complete" and the workout name — at the home
        // hero's footprint (132pt). Falls back to the flat status banner only
        // when we genuinely have no workout object to render art/name for
        // (e.g. /today says completedToday with no todayWorkout payload).
        if (todayWorkout != null) {
          content = KeyedSubtree(
            key: ValueKey('today-complete-${todayWorkout.id}'),
            child: _workoutRow(context, ref, c, todayWorkout,
                isToday: true, completed: true),
          );
        } else {
          content = _heroStatus(context, c,
              key: const ValueKey('today-complete'),
              msg: AppLocalizations.of(context)!.unifiedHomeWidgetsWorkoutCompleteGreatJob,
              accent: c.success,
              iconName: 'check');
        }
      } else {
        final workout = todayWorkout ?? resp?.nextWorkout?.toWorkout();
        if (workout == null && state.hasError && !state.hasValue) {
          // The /today fetch FAILED and neither workoutsProvider nor a cached
          // response gave us anything — this is a genuine load error, NOT a
          // rest day. Surfacing it honestly (with retry) instead of silently
          // showing "Rest day" so a network blip never masquerades as a real
          // schedule (see feedback_no_silent_fallbacks).
          content = _heroError(context, c, ref,
              key: const ValueKey('today-error'));
        } else if (workout == null) {
          // Rest day / nothing scheduled.
          content = _heroStatus(context, c,
              key: const ValueKey('today-rest'),
              msg: AppLocalizations.of(context)!.unifiedHomeWidgetsRestDayNoWorkoutScheduled,
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

  /// Hero-shaped ERROR card with a Retry action. Same 132pt footprint as the
  /// loaded hero / status states (zero layout shift). Shown when the /today
  /// workout fetch failed with no cached or schedule fallback — so the user
  /// sees an honest "couldn't load + retry" instead of a phantom rest day.
  Widget _heroError(
    BuildContext context,
    ThemeColors c,
    WidgetRef ref, {
    required Key key,
  }) {
    final l10n = AppLocalizations.of(context)!;
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
        child: Row(
          children: [
            LineIcon('workout', color: c.textMuted, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.quickStartCardCouldNotLoadWorkout,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: c.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticService.selection();
                ref.invalidate(todayWorkoutProvider);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: c.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Text(
                  l10n.buttonRetry,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: c.accent,
                  ),
                ),
              ),
            ),
          ],
        ),
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

  /// Status label for a non-today, non-completed workout: the scheduled
  /// DAY/DATE instead of a generic "SCHEDULED" (e.g. "WED, JUN 3", "TOMORROW").
  /// Safe on null/malformed dates and uses the user's local calendar day.
  String _scheduledLabel(String? iso) {
    final dt = DateTime.tryParse(iso ?? '');
    if (dt == null) return 'SCHEDULED';
    final local = dt.toLocal();
    final now = DateTime.now();
    final dayDiff = DateTime(local.year, local.month, local.day)
        .difference(DateTime(now.year, now.month, now.day))
        .inDays;
    if (dayDiff == 1) return 'TOMORROW';
    return DateFormat('EEE, MMM d').format(local).toUpperCase(); // "WED, JUN 3"
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.colors(context);
    final workout = widget.workout;
    final accent = widget.completed ? c.success : c.accent;

    // Completed workouts get a distinct celebratory treatment — the blurred
    // exercise art + frosted-green scrim + centered check, matching the
    // Workouts-tab carousel's completed overlay (see hero_workout_card_ui.dart).
    if (widget.completed) {
      return _buildCompletedHero(c, workout);
    }

    final type = (workout.type ?? 'strength').toUpperCase();
    final mins = workout.durationMinutes ?? workout.durationMinutesMax ?? 0;
    final exCount = workout.exerciseCount;
    final prefix = widget.completed
        ? 'DONE'
        : (widget.isToday ? 'TODAY' : _scheduledLabel(workout.scheduledDate));
    final meta = '$prefix · $type'
        '${mins > 0 ? ' · ${mins}m' : ''}'
        '${exCount > 0 ? ' · $exCount exercises' : ''}';

    // Signature v2 rh-card: a restrained dark surface2 card with a hairline
    // top rule, an Anton masthead title, a Barlow subtitle, the scheduled
    // date pill (orange when TODAY), a meta line, and a single orange
    // "Start workout →" CTA. No photo background, no full-orange gradient.
    final subtitle = _heroSubtitle(workout, type);
    final isToday = widget.isToday;

    // Legibility split: the muted theme greys (textMuted #71717A) were tuned for
    // the flat surface2 fallback. The moment an exercise photo sits behind the
    // text they wash out (subtitle/meta/date-pill became near-invisible — the
    // bug). So when there's an image we switch the title/subtitle/meta and the
    // non-today date pill to white-on-scrim with a drop shadow; without an image
    // we keep the restrained greys over the dark surface.
    final bool overImage = _imageUrl != null;
    final Color subColor =
        overImage ? Colors.white.withValues(alpha: 0.88) : c.textMuted;
    final Color metaColor = overImage
        ? Colors.white.withValues(alpha: 0.80)
        : c.textMuted.withValues(alpha: 0.7);
    final List<Shadow> textShadows = overImage
        ? const [Shadow(color: Colors.black, blurRadius: 8, offset: Offset(0, 1))]
        : const <Shadow>[];
    final Color pillFill = isToday
        ? c.accent
        : (overImage ? Colors.black.withValues(alpha: 0.42) : Colors.transparent);
    final Color pillBorder = isToday
        ? c.accent
        : (overImage ? Colors.white.withValues(alpha: 0.38) : AppColors.cardBorder);
    final Color pillText = isToday
        ? c.accentContrast
        : (overImage ? Colors.white.withValues(alpha: 0.92) : c.textMuted);

    return GestureDetector(
      onTap: () {
        HapticService.medium();
        context.push('/workout/${workout.id}', extra: workout);
      },
      child: RepaintBoundary(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0F0F11), // --d-surface2
              border: const Border(
                top: BorderSide(color: AppColors.hairlineStrong),
              ),
              // Exercise illustration behind the text. Lightly darkened here; the
              // bottom-anchored scrim below does the heavy lifting for text
              // legibility so the photo still reads as a photo up top.
              image: overImage
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(_imageUrl!,
                          maxWidth: 600, maxHeight: 360),
                      fit: BoxFit.cover,
                      alignment: const Alignment(0.0, -0.25),
                      colorFilter: ColorFilter.mode(
                          Colors.black.withValues(alpha: 0.45),
                          BlendMode.darken),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                // Bottom→top scrim: keeps the title/subtitle/meta/CTA legible
                // over ANY exercise photo. Without it the muted greys vanished
                // over the mid-tone illustration (the reported bug).
                if (overImage)
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.10),
                            Colors.black.withValues(alpha: 0.48),
                            Colors.black.withValues(alpha: 0.90),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Date pill, right-aligned (orange for TODAY).
                      Row(
                        children: [
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: pillFill,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: pillBorder),
                            ),
                            child: Text(
                              prefix,
                              style: ZType.lbl(
                                10,
                                color: pillText,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        (workout.name ?? 'Workout').toUpperCase(),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: ZType.disp(30,
                                color: c.textPrimary, letterSpacing: 0.5)
                            .copyWith(height: 0.98, shadows: textShadows),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(subtitle.toUpperCase(),
                            style: ZType.lbl(12.5,
                                    color: subColor, letterSpacing: 2)
                                .copyWith(shadows: textShadows),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 5),
                      Text(
                        meta,
                        style: TextStyle(
                            fontSize: 11.5,
                            color: metaColor,
                            shadows: textShadows),
                      ),
                      const SizedBox(height: 14),
                      // Single orange CTA — Start (today / available).
                      GestureDetector(
                        onTap: () {
                          HapticService.medium();
                          context.push('/active-workout', extra: workout);
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: c.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'START WORKOUT →',
                            style: ZType.lbl(14,
                                color: c.accentContrast,
                                weight: FontWeight.w800,
                                letterSpacing: 2.5),
                          ),
                        ),
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

  /// Short Signature subtitle for the hero — the muscle focus when known,
  /// else the workout type ("LEGS", "CHEST & TRICEPS", …).
  String _heroSubtitle(Workout workout, String type) {
    // Clean the muscle names: strip "(Latin name)" parentheticals, dedupe, keep
    // at most two → "Chest & Triceps", never a raw multi-line anatomical dump.
    final seen = <String>{};
    final cleaned = <String>[];
    for (final m in workout.primaryMuscles) {
      final name = m.replaceAll(RegExp(r'\s*\([^)]*\)'), '').trim();
      if (name.isEmpty) continue;
      if (seen.add(name.toLowerCase())) cleaned.add(name);
      if (cleaned.length >= 2) break;
    }
    if (cleaned.isNotEmpty) return cleaned.join(' & ');
    return type;
  }

  /// The background layer: the exercise photo, a loading shimmer, or — when no
  /// image is available — a pure accent gradient so the card never looks bare.
  Widget _buildBackground(ThemeColors c, Color accent) {
    if (_imageUrl != null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: _imageUrl!,
            fit: BoxFit.cover,
            // Many exercise illustrations in the S3 library are full-figure
            // line drawings with the head near the top of the canvas.
            // BoxFit.cover scales the image to fill the wide-short hero
            // crop, which means with `Alignment.center` the visible window
            // shows the middle stripe (chest → thighs) and crops the head
            // off the top. Anchoring at y = -0.25 shifts the visible
            // window UP (closer to the image's top), pulling the head
            // into the frame. The leftover top sliver of head is then
            // blended into the accent scrim by the gradient below so a
            // crop never reads as a decapitation.
            alignment: const Alignment(0.0, -0.25),
            // Limit decoded size in the memory cache (matches HeroWorkoutCard).
            memCacheWidth: 600,
            memCacheHeight: 360,
            placeholder: (_, __) => _accentFill(accent),
            errorWidget: (_, __, ___) => _accentFill(accent),
          ),
          // Top-fade gradient — masks the head-crop edge so any leftover
          // sliver of forehead reads as a stylistic fade into the card's
          // accent scrim rather than a hard cut. Covers the upper ~38%
          // of the hero with a heavy accent overlay that decays to fully
          // transparent at the action area (mid-image).
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    accent.withValues(alpha: 0.85),
                    accent.withValues(alpha: 0.30),
                    accent.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.18, 0.38],
                ),
              ),
            ),
          ),
        ],
      );
    }
    // Loading or no-image: an accent gradient fill keeps the hero energetic.
    return _accentFill(accent);
  }

  /// Completed-workout hero — same 132pt footprint as the live hero, but
  /// rendered as a celebration: a heavily blurred shot of the exercise art
  /// sits behind a frosted accent-green scrim, with a green check, "Workout
  /// complete", the workout name, and the same Repeat / Summary / Share
  /// actions the Workouts-tab carousel offers — so the two surfaces read and
  /// behave identically. The action buttons own their own taps; the card body
  /// is deliberately not a single tap target so the buttons never bleed.
  Widget _buildCompletedHero(ThemeColors c, Workout workout) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = c.success;
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: _kWorkoutHeroHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Blurred exercise art (or accent gradient when none).
              _buildCompletedBackground(c, accent),
              // Legibility scrim. The old flat 28-34% green tint was far too
              // weak: over a LIGHT blurred exercise photo it barely darkened
              // anything, so the white "Workout complete" title + name + button
              // labels vanished into the pale wash (the user reported "I can't
              // see the words at all"). Replace it with a dark-green vertical
              // scrim — the accent darkened toward black at high opacity — so
              // white text always clears ~6:1 contrast while the card keeps its
              // green identity, regardless of how bright the art behind it is.
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.30), accent)
                          .withValues(alpha: 0.82),
                      Color.alphaBlend(
                        Colors.black.withValues(alpha: 0.52), accent)
                          .withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: accent.withValues(alpha: 0.45),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 18,
                            weight: 800,
                          ),
                        ),
                        const SizedBox(width: 9),
                        Flexible(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)
                                    .workoutShowcaseWorkoutComplete,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
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
                              if ((workout.name ?? '').isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  workout.name!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white.withValues(alpha: 0.88),
                                    shadows: const [
                                      Shadow(
                                        blurRadius: 5,
                                        color: Color(0x55000000),
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _completedActionButton(
                            icon: Icons.replay,
                            label: AppLocalizations.of(context)
                                .heroWorkoutCardRepeat,
                            onTap: _repeatWorkout,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _completedActionButton(
                            icon: Icons.bar_chart,
                            label: AppLocalizations.of(context)
                                .workoutCompleteSummary,
                            onTap: _viewSummary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _completedActionButton(
                            icon: Icons.ios_share_rounded,
                            label: AppLocalizations.of(context).commonShare,
                            onTap: _shareCompletedWorkout,
                            isDark: isDark,
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
    );
  }

  /// A single compact pill action on the completed hero (Repeat / Summary /
  /// Share). Frosted translucent fill so it reads over the blurred art, sized
  /// to share the row equally via the parent [Expanded].
  Widget _completedActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Material(
      color: Colors.white.withValues(alpha: isDark ? 0.18 : 0.24),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticService.light();
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.35)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 13, color: Colors.white),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Repeat: start the just-completed workout again (same as the live hero's
  /// play button and the carousel's Repeat).
  void _repeatWorkout() {
    HapticService.medium();
    context.push('/active-workout', extra: widget.workout);
  }

  /// Summary: deep-link to the Summary pane of the workout summary screen.
  void _viewSummary() {
    HapticService.selection();
    context.push('/workout-summary/${widget.workout.id}?tab=summary');
  }

  /// Share a completed workout through the unified `ShareableSheet` — the same
  /// gallery (Wrapped / Trading Card / Receipt / Workout Details + public
  /// share-link pill) the Workouts-tab carousel uses, so Home and Workouts
  /// share one share flow.
  Future<void> _shareCompletedWorkout() async {
    HapticService.light();
    final workout = widget.workout;
    final id = workout.id;
    if (id == null || id.isEmpty) return;

    final streak = ref.read(currentStreakProvider);
    final shareable = WorkoutAdapter.fromCompletion(
      ref: ref,
      workoutName: workout.name ?? 'Workout',
      durationSeconds:
          (workout.estimatedDurationMinutes ?? workout.durationMinutes ?? 45) *
              60,
      plannedExercises: workout.exercises,
      totalSets: workout.exercises.fold<int>(0, (a, e) => a + (e.sets ?? 0)),
      totalReps: workout.exercises
          .fold<int>(0, (a, e) => a + ((e.sets ?? 0) * (e.reps ?? 0))),
      currentStreak: streak > 0 ? streak : null,
    );
    if (shareable == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context).heroWorkoutCardNothingToShareYet),
          ),
        );
      }
      return;
    }

    ref.read(floatingNavBarVisibleProvider.notifier).state = false;
    final allowPublicLinks = ref.read(publicShareLinksProvider);
    await ShareableSheet.show(
      context,
      data: shareable,
      onGenerateShareLink: !allowPublicLinks
          ? null
          : () async {
              try {
                final api = ref.read(apiClientProvider);
                final res = await api.dio.post('/workouts/$id/share-link');
                final data = res.data;
                if (data is Map && data['url'] is String) {
                  return data['url'] as String;
                }
                return null;
              } catch (e) {
                debugPrint('❌ [HomeHero] share-link failed: $e');
                return null;
              }
            },
    );
    if (mounted) {
      ref.read(floatingNavBarVisibleProvider.notifier).state = true;
    }
  }

  /// Background for the completed hero: the exercise photo blurred behind the
  /// frosted scrim, or a plain accent gradient when no image is available.
  Widget _buildCompletedBackground(ThemeColors c, Color accent) {
    if (_imageUrl != null) {
      return ImageFiltered(
        imageFilter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: CachedNetworkImage(
          imageUrl: _imageUrl!,
          fit: BoxFit.cover,
          alignment: const Alignment(0.0, -0.25),
          memCacheWidth: 600,
          memCacheHeight: 360,
          placeholder: (_, __) => _accentFill(accent),
          errorWidget: (_, __, ___) => _accentFill(accent),
        ),
      );
    }
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

/// The meta line under the Workout hero name, augmented with a leading
/// strain-tier pill (REST / LIGHT / MODERATE / HARD) + a trailing sleep
/// score when both signals are available.
///
/// Replaces the standalone `StrainCoachCard` that used to live between the
/// Coach hero and the Workout hero on home. The tier is computed by the
/// same `chooseStrainRecommendation()` decision tree the old card used;
/// tap on the pill opens the same rationale screen the old card's
/// chevron led to (`/chat?source=strain_coach&prefill=…`).
class _WorkoutHeroIntensityLine extends ConsumerWidget {
  final String meta;
  const _WorkoutHeroIntensityLine({required this.meta});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepAsync = ref.watch(sleepScoreProvider);
    final historyAsync = ref.watch(userHistorySnapshotProvider);

    final sleepScore = sleepAsync.valueOrNull?.score?.total;
    final history = historyAsync.valueOrNull;

    // No usable signal → render the meta line alone, matching the old card's
    // "we don't fabricate a tier" rule (see `strain_coach_card.dart` :53).
    if (sleepScore == null && history == null) {
      return Text(
        meta,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white.withValues(alpha: 0.88),
        ),
      );
    }

    final priorHard = history?.priorTwoDaysHardCount ?? 0;
    final median = history?.volume30dMedianKg ?? 0.0;
    final yesterdayVolume = history?.yesterdayVolumeKg ?? 0.0;
    final yesterdayStrainRatio =
        median > 0 ? yesterdayVolume / median : 0.0;
    final rec = chooseStrainRecommendation(
      sleepScore: sleepScore,
      yesterdayStrainRatio: yesterdayStrainRatio,
      priorTwoDaysHardCount: priorHard,
    );

    final composedMeta =
        sleepScore != null ? '$meta · sleep $sleepScore' : meta;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _WorkoutHeroTierPill(
          tier: rec.tier,
          onTap: () {
            HapticService.light();
            final prefill = Uri.encodeComponent(
                'Strain Coach says: ${rec.rationale} Can you explain?');
            try {
              context.push('/chat?source=strain_coach&prefill=$prefill');
            } catch (_) {
              context.go('/chat');
            }
          },
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            composedMeta,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            softWrap: false,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tier pill sized for the workout-hero meta line. Sits over the accented
/// image so it uses a frosted white background to read on any tier color.
class _WorkoutHeroTierPill extends StatelessWidget {
  final StrainTier tier;
  final VoidCallback onTap;
  const _WorkoutHeroTierPill({required this.tier, required this.onTap});

  String get _label {
    switch (tier) {
      case StrainTier.rest:
        return 'REST';
      case StrainTier.light:
        return 'LIGHT';
      case StrainTier.moderate:
        return 'MODERATE';
      case StrainTier.hard:
        return 'HARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          _label,
          style: const TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: Colors.white,
          ),
        ),
      ),
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
// P5 §2 (2026-05-24): adds morning Hydration Reset + Breakfast Slot rows that
// conditionally render above the macros section, plus a post-workout refuel
// highlight + a late-day "end at goal" chip.
// ----------------------------------------------------------------------------
/// Signature v2 compact FUEL strip — the one-line fuel summary that leads the
/// nutrition slot on Home (replaces the full nutrition card above the fold).
/// `Fuel  1,460 / 2,200 · 740 left` + semantic P/C/F dots + a floating 🥣.
/// Reads the exact same providers as [HomeNutritionCard] (no new data path);
/// tapping the whole strip opens the Nutrition tab.
class HomeFuelStrip extends ConsumerWidget {
  const HomeFuelStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final nutrition = ref.watch(dailyNutritionProvider(todayNutritionKey()));
    final summary = nutrition.summary;

    // Cold load → slim one-line skeleton (never blank, never a fake target).
    if (summary == null && nutrition.isLoading) {
      return Padding(
        padding: kHomeHPad,
        child: _SkeletonBox(height: 44, radius: 10, c: c),
      );
    }
    // Fetch failed with nothing cached → honest inline retry, no silent target.
    if (summary == null && nutrition.error != null) {
      return Padding(padding: kHomeHPad, child: _NutritionErrorCard(c: c));
    }

    final prefs = ref.watch(nutritionPreferencesProvider);
    final calTarget = prefs.currentCalorieTarget;
    final pTarget = prefs.currentProteinTarget;
    final cTarget = prefs.currentCarbsTarget;
    final fTarget = prefs.currentFatTarget;
    final eatenCal = summary?.totalCalories ?? 0;
    final eatenP = (summary?.totalProteinG ?? 0).round();
    final eatenC = (summary?.totalCarbsG ?? 0).round();
    final eatenF = (summary?.totalFatG ?? 0).round();
    final calLeft = calTarget - eatenCal;
    final over = calLeft < 0;
    final nf = NumberFormat.decimalPattern();

    return Padding(
      padding: kHomeHPad,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticService.light();
          context.go('/nutrition');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top row — eaten/target small on the left, the prominent "left"
            // (or "over") number as the large accent value on the right. The
            // remaining-budget figure is what the user glances for, so it gets
            // the display-size numeral (issue 9).
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('FUEL', style: ZType.lbl(11, color: c.textMuted)),
                      const SizedBox(height: 4),
                      Text(
                        '${nf.format(eatenCal)} / ${nf.format(calTarget)}',
                        style: ZType.lbl(11.5, color: c.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      nf.format(over ? -calLeft : calLeft),
                      style: ZType.disp(30,
                              color: over ? c.warning : c.accent)
                          .copyWith(height: 1.0),
                    ),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Text(
                        over ? 'KCAL OVER' : 'KCAL LEFT',
                        style: ZType.lbl(9,
                            color: over ? c.warning : c.textMuted,
                            letterSpacing: 1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Text('🥣', style: TextStyle(fontSize: 30)),
              ],
            ),
            const SizedBox(height: 10),
            // Per-macro LEFT row — replaces the eaten-only dots so the macro
            // figures match the headline number (remaining, not consumed).
            // 0-floor clamp; falls back to eaten when no target is set.
            Row(
              children: [
                _FuelMacroLeft(
                  color: AppColors.macroProtein,
                  letter: 'P',
                  eaten: eatenP,
                  target: pTarget,
                  c: c,
                ),
                const SizedBox(width: 12),
                _FuelMacroLeft(
                  color: AppColors.macroCarbs,
                  letter: 'C',
                  eaten: eatenC,
                  target: cTarget,
                  c: c,
                ),
                const SizedBox(width: 12),
                _FuelMacroLeft(
                  color: AppColors.macroFat,
                  letter: 'F',
                  eaten: eatenF,
                  target: fTarget,
                  c: c,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// One per-macro "left" cell for the FUEL strip — a semantic dot + the macro
/// letter + the remaining grams (`● P 48g left`). When no target is set it
/// degrades to the eaten figure so a fresh account still reads coherently.
/// Macro-specific colours per `feedback_accent_colors`.
class _FuelMacroLeft extends StatelessWidget {
  final Color color;
  final String letter;
  final int eaten;
  final int target;
  final ThemeColors c;
  const _FuelMacroLeft({
    required this.color,
    required this.letter,
    required this.eaten,
    required this.target,
    required this.c,
  });

  @override
  Widget build(BuildContext context) {
    final hasTarget = target > 0;
    final left = hasTarget ? (target - eaten).clamp(0, target) : eaten;
    final suffix = hasTarget ? 'g left' : 'g';
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$letter $left$suffix',
              style: ZType.lbl(10.5, color: c.textSecondary, letterSpacing: 0.4),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Signature v2 below-fold STRENGTH breakdown — typographic, NO ring (the spec
/// explicitly drops the activity ring here; steps/sleep live on the top strip).
/// Big Anton overall score + a weekly delta, then hairline component bars for
/// the top muscle groups, then a "Full breakdown ›" link. Self-hides with no
/// data so an empty account doesn't show a bare "0".
class HomeStrengthBreakdown extends ConsumerWidget {
  const HomeStrengthBreakdown({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);
    final overall = ref.watch(overallStrengthScoreProvider);
    final muscles = ref.watch(muscleScoresProvider);
    if (overall <= 0 && muscles.isEmpty) return const SizedBox.shrink();

    final entries = muscles.values.toList()
      ..sort((a, b) => b.strengthScore.compareTo(a.strengthScore));
    final top = entries.take(3).toList();
    final weekChange =
        entries.fold<int>(0, (s, e) => s + (e.scoreChange ?? 0));

    return Padding(
      padding: kHomeHPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('STRENGTH', style: ZType.lbl(11, color: c.textMuted)),
          const SizedBox(height: 9),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('$overall',
                  style: ZType.disp(48, color: c.textPrimary)
                      .copyWith(height: 0.9)),
              const SizedBox(width: 11),
              if (weekChange != 0)
                Text(
                  '${weekChange > 0 ? '+' : ''}$weekChange this week',
                  style: ZType.lbl(11, color: c.accent, letterSpacing: 1),
                ),
            ],
          ),
          // Component bars only when there's per-muscle data; otherwise a
          // one-line hint instead of an empty void (the user saw blank space).
          if (top.isNotEmpty) ...[
            const SizedBox(height: 11),
            ...top.map((m) => Padding(
                  padding: const EdgeInsets.only(bottom: 7),
                  child: _StrengthBar(
                    label: m.muscleGroup,
                    value: m.strengthScore,
                    c: c,
                  ),
                )),
            const SizedBox(height: 4),
          ] else ...[
            const SizedBox(height: 7),
            Text('Log a few workouts to build your muscle breakdown.',
                style: TextStyle(
                    fontSize: 11.5,
                    color: c.textMuted.withValues(alpha: 0.65))),
            const SizedBox(height: 7),
          ],
          GestureDetector(
            onTap: () {
              HapticService.light();
              context.push('/stats');
            },
            child: Text('Full breakdown ›',
                style: ZType.lbl(10,
                    color: c.textMuted.withValues(alpha: 0.7),
                    letterSpacing: 0.8)),
          ),
        ],
      ),
    );
  }
}

/// One hairline component bar for the strength breakdown (`label · bar · n`).
class _StrengthBar extends StatelessWidget {
  final String label;
  final int value;
  final ThemeColors c;
  const _StrengthBar(
      {required this.label, required this.value, required this.c});

  @override
  Widget build(BuildContext context) {
    final frac = (value / 100).clamp(0.0, 1.0);
    return Row(
      children: [
        SizedBox(
          width: 54,
          child: Text(label.toUpperCase(),
              style: ZType.lbl(10.5, color: c.textSecondary, letterSpacing: 1),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 4,
              backgroundColor: AppColors.hairlineStrong,
              valueColor: AlwaysStoppedAnimation<Color>(c.textSecondary),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: 26,
          child: Text('$value',
              textAlign: TextAlign.right,
              style: ZType.data(12, color: c.textPrimary)),
        ),
      ],
    );
  }
}

class HomeNutritionCard extends ConsumerStatefulWidget {
  const HomeNutritionCard({super.key});

  @override
  ConsumerState<HomeNutritionCard> createState() => _HomeNutritionCardState();
}

class _HomeNutritionCardState extends ConsumerState<HomeNutritionCard> {
  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final c = ref.colors(context);
    final nutrition = ref.watch(dailyNutritionProvider(todayNutritionKey()));
    final summary = nutrition.summary;

    // Cold load (no cached summary yet) → a card-shaped shimmer skeleton, so
    // an in-flight fetch is never indistinguishable from "ate nothing today".
    if (summary == null && nutrition.isLoading) {
      return Padding(
        padding: kHomeHPad,
        child: _SkeletonBox(height: 232, radius: 18, c: c),
      );
    }
    // Fetch failed with nothing cached → honest inline error + retry instead
    // of a full target rendered as "kcal left" (see feedback_no_silent_fallbacks).
    if (summary == null && nutrition.error != null) {
      return Padding(
        padding: kHomeHPad,
        child: _NutritionErrorCard(c: c),
      );
    }

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
    final cupFraction = cupGoal > 0 ? cups / cupGoal : 0.0;

    // Hydration + breakfast morning rows used to render here. Both moved
    // to the Coach hero card's contextual-nudge stack (see
    // `coach_contextual_nudge_row.dart`). The post-workout transition
    // tracker (`_workoutJustCompletedAt`) and the breakfast-logged scan
    // moved with them — driven now by `contextualNudgeProvider`.

    final now = DateTime.now();

    // Late-day reminder chip on the macros row: ≥ 8 PM AND under 60% of cup goal.
    final showLateDayChip = now.hour >= 20 && cupFraction < 0.60;
    final cupsLeftLateDay = cupGoal - cups;

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
                Text(AppLocalizations.of(context)!.unifiedHomeWidgetsNutrition,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.7,
                        color: c.textMuted)),
                const Spacer(),
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
            // kcal-left line grouped with the macros (was in the header row;
            // moved so calories + macros read as one block).
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  over ? '${-calLeft}' : '$calLeft',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: over ? c.warning : c.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  over
                      ? AppLocalizations.of(context)!.unifiedHomeWidgetsKcal
                      : AppLocalizations.of(context)!.unifiedHomeWidgetsKcalLeft,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: c.textMuted,
                  ),
                ),
                if (over) ...[
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.unifiedHomeWidgetsOver,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: c.warning,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            _MacroBar(
                label: AppLocalizations.of(context)!.unifiedHomeWidgetsProtein,
                eaten: eatenP,
                goal: proteinTarget,
                color: AppColors.macroProtein,
                c: c),
            const SizedBox(height: 7),
            _MacroBar(
                label: AppLocalizations.of(context)!.unifiedHomeWidgetsCarbs,
                eaten: eatenC,
                goal: carbsTarget,
                color: AppColors.macroCarbs,
                c: c),
            const SizedBox(height: 7),
            _MacroBar(
                label: AppLocalizations.of(context)!.unifiedHomeWidgetsFat,
                eaten: eatenF,
                goal: fatTarget,
                color: AppColors.macroFat,
                c: c),
            // P5 §2: small inline chip at 20:00+ when hydration < 60%.
            if (showLateDayChip && cupsLeftLateDay > 0) ...[
              const SizedBox(height: 9),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💧', style: TextStyle(fontSize: 12)),
                    const SizedBox(width: 6),
                    Text(
                      AppLocalizations.of(context)!.unifiedHomeWidgetsEndTheDayAtGoal(cupsLeftLateDay),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                      label: AppLocalizations.of(context)!.unifiedHomeWidgetsWater,
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

/// Inline error card for the nutrition section — shown when the day's summary
/// failed to load and nothing is cached. Mirrors the timeline's error tile:
/// a quiet message + a Retry that re-fetches today's summary. Never blank,
/// never a phantom "full target left".
class _NutritionErrorCard extends ConsumerWidget {
  final ThemeColors c;
  const _NutritionErrorCard({required this.c});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.elevated,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.cardBorder),
      ),
      child: Row(
        children: [
          LineIcon('nutrition', size: 18, color: c.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              l10n.nutritionErrorStateUnableToLoadNutrition,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: c.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.selection();
              final userId = ref.read(currentUserProvider).valueOrNull?.id;
              if (userId != null) {
                ref
                    .read(dailyNutritionProvider(todayNutritionKey()).notifier)
                    .load(userId, forceRefresh: true);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: c.accent.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                l10n.buttonRetry,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: c.accent,
                ),
              ),
            ),
          ),
        ],
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
      value = Text(AppLocalizations.of(context)!.unifiedHomeWidgetsStartAFast,
          style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: c.textMuted));
    }

    return _NutriTileShell(
      c: c,
      iconName: 'fasting',
      tint: AppColors.cyan,
      label: AppLocalizations.of(context)!.unifiedHomeWidgetsFasting,
      fraction: fraction,
      value: value,
      onTap: () {
        HapticService.light();
        context.push('/fasting');
      },
    );
  }
}

// `_breakfastLoggedCountLast7d`, `_HydrationResetRow`, and `_BreakfastSlotRow`
// were removed when the nutrition card's morning nudges moved to the Coach
// hero card's contextual-nudge stack. Their logic now lives in
// `lib/data/providers/contextual_nudge_provider.dart` (eligibility) and
// `lib/widgets/coach/coach_contextual_nudge_row.dart` (presentation). The
// `unifiedHomeWidgetsBreakfastSuggestion` / `unifiedHomeWidgetsBreakfastLogged`
// / `unifiedHomeWidgetsWakeHydration` / `unifiedHomeWidgetsRefuelHydration`
// localization keys are now unreferenced from Dart code; they're kept in
// the .arb files for one release cycle in case the rollback is needed.

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
              label: AppLocalizations.of(context)!.unifiedHomeWidgetsActivity,
              value: _fmt(steps),
              sub: AppLocalizations.of(context)!.unifiedHomeWidgetsKcalBurned(burned),
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
        data: (snapshot) => _content(snapshot, context),
        loading: () => _MetricTile(
          c: c,
          iconName: 'sleep',
          tint: AppColors.macroProtein,
          label: AppLocalizations.of(context)!.unifiedHomeWidgetsSleep,
          value: '…',
          sub: AppLocalizations.of(context)!.unifiedHomeWidgetsLastNight,
          onTap: null,
        ),
        error: (_, __) => _MetricTile(
          c: c,
          iconName: 'sleep',
          tint: AppColors.macroProtein,
          label: AppLocalizations.of(context)!.unifiedHomeWidgetsSleep,
          value: AppLocalizations.of(context)!.unifiedHomeWidgetsNoData,
          sub: AppLocalizations.of(context)!.unifiedHomeWidgetsLastNight,
          onTap: null,
        ),
      ),
    );
  }

  Widget _content(SleepScoreSnapshot? snapshot, BuildContext context) {
    final score = snapshot?.score;
    final summary = snapshot?.summary;
    final l10n = AppLocalizations.of(context)!;

    if (score == null || (summary?.totalMinutes ?? 0) == 0) {
      return _MetricTile(
        c: c,
        iconName: 'sleep',
        tint: AppColors.macroProtein,
        label: l10n.unifiedHomeWidgetsSleep,
        value: l10n.unifiedHomeWidgetsNoData,
        sub: l10n.unifiedHomeWidgetsLastNight,
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
        : '${h}h ${m}m ${l10n.unifiedHomeWidgetsLastNight}';

    return _MetricTile(
      c: c,
      iconName: 'sleep',
      tint: tier.color,
      label: l10n.unifiedHomeWidgetsSleep,
      value: '${score.total} / ${localizedTierLabel(context, score.total)}',
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
                    AppLocalizations.of(context)!.unifiedHomeWidgetsConnectAppleHealth,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: c.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    AppLocalizations.of(context)!.unifiedHomeWidgetsSeeYourStepsCalories,
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
              child: Text(
                AppLocalizations.of(context)!.unifiedHomeWidgetsConnect,
                style: const TextStyle(
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
                          fontSize: 10,
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
                    fontSize: 10.5, fontWeight: FontWeight.w600, color: c.textMuted)),
          ],
        ),
      ),
    );
  }
}
