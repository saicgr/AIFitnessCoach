import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/theme/theme_colors.dart';
import '../../../../core/widgets/line_icon.dart';
import '../../../../data/models/timeline_entry.dart';
import '../../../../data/models/workout.dart';
import '../../../../data/providers/fasting_provider.dart';
import '../../../../data/providers/home_sections_provider.dart' show selectedHomeDateProvider;
import '../../../../data/providers/timeline_provider.dart';
import '../../../../data/providers/today_workout_provider.dart';
import '../../../../data/services/haptic_service.dart';
import 'unified_home_widgets.dart' show kHomeHPad;

import '../../../../l10n/generated/app_localizations.dart';
/// "Today's Timeline" — a glanceable, time-ordered feed of EVERYTHING the
/// user logged or has planned for the selected day.
///
/// Logged events come from the backend-aggregated `timelineProvider`
/// (`GET /api/v1/timeline`) which already covers workout / food / water /
/// sleep / weight / mood / habit / achievement. Planned events (an
/// upcoming scheduled workout, an active fast, a "log your meals" nudge)
/// are merged in client-side.
///
/// The widget is date-aware: it follows `selectedHomeDateProvider` so the
/// user can scrub the week strip and see any day's events. A past day shows
/// logged events only; a future day shows planned items only.
class HomeTimeline extends ConsumerWidget {
  const HomeTimeline({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.colors(context);

    final selectedDate = ref.watch(selectedHomeDateProvider);
    final today = _dateOnly(DateTime.now());
    final selDay = _dateOnly(selectedDate);
    final isToday = selDay == today;
    final isPast = selDay.isBefore(today);
    final isFuture = selDay.isAfter(today);

    final timelineState = ref.watch(timelineProvider);

    // --- Build the body depending on the timeline feed state. -------------
    // Each branch carries a ValueKey so the AnimatedSwitcher below cross-fades
    // skeleton→content (and error→content) instead of hard-popping.
    Widget body;
    if (timelineState.isLoading && timelineState.days.isEmpty) {
      // Cold start, no cached feed yet → per-row shimmer skeletons.
      body = const _SkeletonList(key: ValueKey('tl-skeleton'));
    } else if (timelineState.error != null && timelineState.days.isEmpty) {
      // Feed failed and we have nothing cached → tile-level error + retry.
      body = _ErrorTile(
        key: const ValueKey('tl-error'),
        c: c,
        onRetry: () => ref.read(timelineProvider.notifier).refresh(),
      );
    } else {
      final events = _buildEvents(
        context: context,
        ref: ref,
        c: c,
        timelineState: timelineState,
        selectedDay: selDay,
        isToday: isToday,
        isPast: isPast,
        isFuture: isFuture,
      );
      if (events.isEmpty) {
        body = Padding(
          key: const ValueKey('tl-empty'),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            isFuture ? AppLocalizations.of(context).homeTimelineNothingPlannedForThis : AppLocalizations.of(context).homeTimelineNothingLoggedOrPlanned,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        );
      } else {
        body = Column(
          key: const ValueKey('tl-list'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < events.length; i++)
              _TimelineRow(
                event: events[i],
                isLast: i == events.length - 1,
                c: c,
              ),
          ],
        );
      }
    }

    return Padding(
      padding: kHomeHPad,
      // A5: the timeline is a tall multi-row card; isolate its paint so a
      // sibling Home tile rebuilding (or the shimmer sweep) doesn't force
      // the whole feed to re-rasterise.
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
                LineIcon('check', size: 15, color: c.textMuted),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _sectionTitle(selDay, isToday).toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                      color: c.textMuted,
                    ),
                  ),
                ),
                // Silent-refresh indicator: feed reloading but stale data shown.
                if (timelineState.isLoading && timelineState.days.isNotEmpty)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.6,
                      valueColor: AlwaysStoppedAnimation(c.textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            // Cross-fade skeleton→content (and error→content) so the feed
            // never hard-pops in. AnimatedSize absorbs the height delta
            // between the fixed-height skeleton and the real list so the
            // transition itself is smooth rather than a jump.
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: body,
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  /// Dynamic section title — "Today's Timeline" vs e.g. "Mon, May 12".
  String _sectionTitle(DateTime selDay, bool isToday) {
    if (isToday) return "Today's Timeline";
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final dow = days[selDay.weekday - 1];
    return '$dow, ${months[selDay.month - 1]} ${selDay.day}';
  }

  // ----------------------------------------------------------------------
  // Event assembly
  // ----------------------------------------------------------------------

  List<_TimelineEvent> _buildEvents({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors c,
    required TimelineState timelineState,
    required DateTime selectedDay,
    required bool isToday,
    required bool isPast,
    required bool isFuture,
  }) {
    final events = <_TimelineEvent>[];

    // --- 1. Logged events from the backend-aggregated feed. ---------------
    // `occurredAt` is ISO-8601 UTC — convert to device-local for both the
    // day-filter and the displayed timestamp so an 11pm log lands on the
    // correct local day.
    final loggedEntries = <TimelineEntry>[];
    for (final day in timelineState.days) {
      for (final e in day.entries) {
        final localTime = _parseLocal(e.occurredAt);
        if (localTime == null) continue;
        if (_dateOnly(localTime) == selectedDay) {
          loggedEntries.add(e);
        }
      }
    }

    // Track which workout ids already appear as logged entries so the
    // planned-workout merge can de-dup against them.
    final loggedWorkoutIds = <String>{};
    var hasFoodEntry = false;
    for (final e in loggedEntries) {
      if (e.type == 'workout') {
        loggedWorkoutIds.add(_bareId(e.id));
      }
      if (e.type == 'food') hasFoodEntry = true;
    }

    // Group consecutive same-type entries so a noisy day (e.g. 6 water cups)
    // collapses into one "Water · 3 cups" row instead of flooding the feed.
    events.addAll(_collapseLogged(context, loggedEntries, c));

    // --- 2. Planned events — only for today / future days. ----------------
    // Past days are historical: show logged events exactly as recorded.
    if (!isPast) {
      _addPlannedWorkouts(
        context: context,
        ref: ref,
        c: c,
        events: events,
        loggedWorkoutIds: loggedWorkoutIds,
        isToday: isToday,
      );

      if (isToday) {
        _addFasting(context: context, ref: ref, c: c, events: events);

        // "Log your meals" nudge — only when nothing was eaten today.
        if (!hasFoodEntry) {
          events.add(_TimelineEvent(
            iconName: 'nutrition',
            title: AppLocalizations.of(context).homeTimelineLogYourMeals,
            subtitle: AppLocalizations.of(context).homeTimelineNothingLoggedYetToday,
            status: _Status.upcoming,
            tint: c.success,
            sortKey: _sortUpcoming,
            onTap: () => _open(context, '/nutrition'),
          ));
        }
      }
    }

    // --- 3. Time order. ---------------------------------------------------
    events.sort((a, b) => a.sortKey.compareTo(b.sortKey));
    return events;
  }

  /// Collapse the logged feed into rows, merging runs of the same type
  /// (water/food/etc.) into a single counted row when there are 3+.
  List<_TimelineEvent> _collapseLogged(
    BuildContext context,
    List<TimelineEntry> entries,
    ThemeColors c,
  ) {
    // Sort by real local time first.
    final sorted = [...entries]
      ..sort((a, b) {
        final ta = _parseLocal(a.occurredAt);
        final tb = _parseLocal(b.occurredAt);
        if (ta == null || tb == null) return 0;
        return ta.compareTo(tb);
      });

    final out = <_TimelineEvent>[];
    var i = 0;
    while (i < sorted.length) {
      final entry = sorted[i];
      // Find a run of consecutive entries with the same collapsible type.
      var j = i;
      while (j + 1 < sorted.length &&
          sorted[j + 1].type == entry.type &&
          _isCollapsibleType(entry.type)) {
        j++;
      }
      final runLength = j - i + 1;
      if (runLength >= 3 && _isCollapsibleType(entry.type)) {
        // Collapse — anchor on the LAST entry's time (most recent).
        final last = sorted[j];
        final localTime = _parseLocal(last.occurredAt)!;
        out.add(_TimelineEvent(
          iconName: _iconFor(entry.type),
          title: '${_typeLabel(entry.type)} · $runLength ${_unitFor(entry.type, runLength)}',
          subtitle: 'Last at ${_fmtTime(localTime)}',
          status: _Status.done,
          tint: _tintFor(entry.type, c),
          sortKey: localTime.millisecondsSinceEpoch.toDouble(),
          onTap: () => _open(context, _routeFor(entry)),
        ));
        i = j + 1;
      } else {
        // Render each entry of this run individually.
        for (var k = i; k <= j; k++) {
          final e = sorted[k];
          final localTime = _parseLocal(e.occurredAt)!;
          out.add(_TimelineEvent(
            iconName: _iconFor(e.type, fallback: e.icon),
            title: e.title,
            subtitle: _loggedSubtitle(e, localTime),
            status: _Status.done,
            tint: _tintFor(e.type, c),
            sortKey: localTime.millisecondsSinceEpoch.toDouble(),
            onTap: () => _open(context, _routeFor(e)),
          ));
        }
        i = j + 1;
      }
    }
    return out;
  }

  String _loggedSubtitle(TimelineEntry e, DateTime localTime) {
    final timeStr = _fmtTime(localTime);
    final sub = e.subtitle?.trim();
    if (sub != null && sub.isNotEmpty) return '$sub · $timeStr';
    return timeStr;
  }

  // ----------------------------------------------------------------------
  // Planned: workouts
  // ----------------------------------------------------------------------

  void _addPlannedWorkouts({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors c,
    required List<_TimelineEvent> events,
    required Set<String> loggedWorkoutIds,
    required bool isToday,
  }) {
    final resp = ref.watch(todayWorkoutProvider).valueOrNull;
    if (resp == null) return;

    // Generating in progress → a single "Generating…" row.
    if (resp.isGenerating) {
      events.add(_TimelineEvent(
        iconName: 'refresh',
        title: AppLocalizations.of(context).homeTimelineGeneratingYourWorkout,
        subtitle: resp.generationMessage ?? AppLocalizations.of(context).homeTimelineHangTightAlmostReady,
        status: _Status.now,
        tint: c.accent,
        sortKey: _sortNow,
        onTap: () => _open(context, '/workouts'),
      ));
      return;
    }

    // Collect every planned workout for the day (today + extras), skipping
    // ones already present as a logged `workout` entry (de-dup by id) and
    // skipping completed ones (those are logged, not planned).
    final planned = <Workout>[];
    void consider(Workout? w, {bool completed = false}) {
      if (w == null) return;
      final id = _bareId(w.id);
      if (id.isNotEmpty && loggedWorkoutIds.contains(id)) {
        return; // already present in the logged feed
      }
      if (completed || (w.isCompleted ?? false)) return; // logged elsewhere
      if (id.isNotEmpty && planned.any((p) => _bareId(p.id) == id)) return;
      planned.add(w);
    }

    consider(resp.todayWorkout?.toWorkout());
    for (final extra in resp.extraTodayWorkouts) {
      consider(extra.toWorkout());
    }
    // A future-day view: nextWorkout may be the scheduled item.
    if (!isToday) {
      consider(resp.nextWorkout?.toWorkout());
    }
    // completedWorkout is intentionally NOT added — it shows in the logged
    // feed as a `workout` entry; adding it here would duplicate the row.

    for (final w in planned) {
      // A workout has a date but no time-of-day → deterministically anchor
      // it just after the last logged event (see `_sortPlannedWorkout`).
      events.add(_TimelineEvent(
        iconName: 'workout',
        title: w.name ?? AppLocalizations.of(context).navWorkout,
        subtitle: _workoutSubtitle(w),
        status: _Status.upcoming,
        tint: c.accent,
        sortKey: _sortPlannedWorkout,
        onTap: () => context.push('/active-workout', extra: w),
      ));
    }
  }

  String _workoutSubtitle(Workout w) {
    final count = w.exerciseCount;
    final dur = w.durationMinutes ?? 0;
    final parts = <String>[];
    parts.add('$count exercise${count == 1 ? '' : 's'}');
    if (dur > 0) parts.add('${dur}m');
    parts.add('Scheduled');
    return parts.join(' · ');
  }

  // ----------------------------------------------------------------------
  // Planned: fasting
  // ----------------------------------------------------------------------

  void _addFasting({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeColors c,
    required List<_TimelineEvent> events,
  }) {
    final fasting = ref.watch(fastingProvider);

    // Active fast → a "now" row. This stays a "now" row even if the fast
    // started yesterday and spans midnight.
    final fast = fasting.activeFast;
    if (fast != null) {
      events.add(_TimelineEvent(
        iconName: 'fasting',
        title: AppLocalizations.of(context).homeTimelineFastingWindow,
        subtitle: '${fast.remainingTimeString} left · '
            '${fast.elapsedTimeString} elapsed',
        status: _Status.now,
        tint: c.cyan,
        sortKey: _sortNow,
        onTap: () => context.push('/fasting'),
      ));
      return;
    }

    // No active fast but a protocol is configured → an "upcoming" row.
    final prefs = fasting.preferences;
    if (prefs != null && fasting.onboardingCompleted) {
      events.add(_TimelineEvent(
        iconName: 'fasting',
        title: AppLocalizations.of(context).homeTimelineFastingWindow,
        subtitle: '${prefs.defaultProtocol} protocol · not started',
        status: _Status.upcoming,
        tint: c.cyan,
        sortKey: _sortUpcoming,
        onTap: () => context.push('/fasting'),
      ));
    }
  }

  // ----------------------------------------------------------------------
  // Helpers
  // ----------------------------------------------------------------------

  // Sort anchors for planned items (logged items use real epoch millis).
  // Logged epoch millis are always far below these synthetic anchors so
  // planned items reliably sort after the last logged event.
  static const double _sortNow = 9.0e15; // active/in-progress items
  static const double _sortPlannedWorkout = 9.1e15; // scheduled workout
  static const double _sortUpcoming = 9.2e15; // upcoming nudges

  /// Parse an ISO-8601 UTC timestamp into device-local time.
  static DateTime? _parseLocal(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;
    return dt.isUtc ? dt.toLocal() : dt;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Timeline entry ids look like `workout:uuid` — strip the `type:` prefix
  /// so a logged `workout` entry can be matched against a `Workout.id` uuid.
  static String _bareId(String? id) {
    if (id == null) return '';
    final idx = id.indexOf(':');
    return idx >= 0 ? id.substring(idx + 1) : id;
  }

  static String _fmtTime(DateTime t) {
    final h24 = t.hour;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = h24 < 12 ? 'AM' : 'PM';
    return '$h12:$m $ampm';
  }

  static bool _isCollapsibleType(String type) =>
      type == 'water' || type == 'food' || type == 'habit';

  static String _iconFor(String type, {String? fallback}) {
    switch (type) {
      case 'workout':
        return 'workout';
      case 'food':
        return 'nutrition';
      case 'water':
        return 'water';
      case 'sleep':
        return 'sleep';
      case 'weight':
        return 'activity';
      case 'mood':
        return 'spark';
      case 'habit':
        return 'check';
      case 'achievement':
        return 'flame';
      default:
        // LineIcon renders a safe placeholder for unknown keys.
        return fallback ?? 'check';
    }
  }

  static String _typeLabel(String type) {
    switch (type) {
      case 'water':
        return 'Water';
      case 'food':
        return 'Meals';
      case 'habit':
        return 'Habits';
      default:
        return type;
    }
  }

  static String _unitFor(String type, int count) {
    switch (type) {
      case 'water':
        return count == 1 ? 'cup' : 'cups';
      case 'food':
        return count == 1 ? 'entry' : 'entries';
      case 'habit':
        return count == 1 ? 'habit' : 'habits';
      default:
        return 'items';
    }
  }

  static Color _tintFor(String type, ThemeColors c) {
    switch (type) {
      case 'workout':
        return c.accent;
      case 'food':
        return c.success;
      case 'water':
        return c.info;
      case 'achievement':
        return c.warning;
      case 'fasting':
        return c.cyan;
      default:
        return c.accent;
    }
  }

  /// Shell nav-tab routes. Navigating to one of these MUST use `go` (switch
  /// the tab) — `push` would stack a 2nd copy of a tab screen and its static
  /// tooltip GlobalKeys collide ("Multiple widgets used the same GlobalKey").
  static const _tabRoutes = {
    '/home', '/workouts', '/nutrition', '/discover', '/profile',
  };

  /// Navigate to [route]: `go` for nav tabs, `push` for standalone screens.
  static void _open(BuildContext context, String route) {
    if (_tabRoutes.contains(route)) {
      context.go(route);
    } else {
      context.push(route);
    }
  }

  /// Route to a timeline entry's source screen. Falls back to the relevant
  /// tab when there's no dedicated detail route, so a tap is never dead.
  static String _routeFor(TimelineEntry e) {
    switch (e.type) {
      case 'food':
      case 'water':
        return '/nutrition';
      case 'weight':
      case 'sleep':
        // Weight + sleep both surface in the measurements detail screen;
        // no standalone /sleep route exists.
        return '/measurements';
      case 'workout':
        return '/workouts';
      case 'mood':
        return '/mood-history';
      default:
        // achievement / habit / unknown → the nutrition tab is the safe,
        // always-present landing surface (no dead tap).
        return '/nutrition';
    }
  }
}

enum _Status { done, now, upcoming }

class _TimelineEvent {
  final String iconName;
  final String title;
  final String subtitle;
  final _Status status;
  final Color tint;

  /// Ordering key — real logged entries use `occurredAt` epoch millis;
  /// planned items use the synthetic anchors so they sort after logs.
  final double sortKey;
  final VoidCallback onTap;

  const _TimelineEvent({
    required this.iconName,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.tint,
    required this.sortKey,
    required this.onTap,
  });
}

class _TimelineRow extends StatelessWidget {
  final _TimelineEvent event;
  final bool isLast;
  final ThemeColors c;
  const _TimelineRow(
      {required this.event, required this.isLast, required this.c});

  @override
  Widget build(BuildContext context) {
    final dotColor = switch (event.status) {
      _Status.done => c.success,
      _Status.now => event.tint,
      _Status.upcoming => c.textMuted,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticService.selection();
        event.onTap();
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status track: dot + connecting line.
            Column(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: event.status == _Status.upcoming
                        ? Colors.transparent
                        : dotColor,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: c.cardBorder,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: event.tint.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: LineIcon(event.iconName,
                          size: 17, color: event.tint),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(event.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                  color: c.textPrimary)),
                          const SizedBox(height: 1),
                          Text(event.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: c.textMuted)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Per-row loading placeholders shown on a cold start before the feed lands.
///
/// The whole list is wrapped in ONE [Shimmer] so the sweep runs as a single
/// continuous gradient across all three rows (rather than three independent
/// shimmers). Every placeholder block is sized to mirror the loaded
/// `_TimelineRow` (11pt dot, 34pt icon chip, two text lines) so the real feed
/// cross-fades in with no layout shift.
class _SkeletonList extends StatelessWidget {
  const _SkeletonList({super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).dividerColor.withValues(alpha: 0.30);
    final highlight = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      period: const Duration(milliseconds: 1200),
      child: Column(
        children: [
          for (int i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == 2 ? 0 : 14),
              child: _SkeletonRow(block: base),
            ),
        ],
      ),
    );
  }
}

/// One skeleton row — geometry mirrors `_TimelineRow` exactly. [block] is the
/// shimmer base colour painted into every placeholder shape.
class _SkeletonRow extends StatelessWidget {
  final Color block;
  const _SkeletonRow({required this.block});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(shape: BoxShape.circle, color: block),
        ),
        const SizedBox(width: 12),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: block,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 11,
                width: 130,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 9,
                width: 80,
                decoration: BoxDecoration(
                  color: block,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tile-level error state with a retry action — never a blank or a crash.
class _ErrorTile extends StatelessWidget {
  final ThemeColors c;
  final VoidCallback onRetry;
  const _ErrorTile({super.key, required this.c, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            AppLocalizations.of(context).homeTimelineCouldnTLoadYour,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: c.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            HapticService.selection();
            onRetry();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: c.accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              AppLocalizations.of(context).buttonRetry,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: c.accent,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
