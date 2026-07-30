/// One resolution point for "which LOCAL calendar day is this workout on".
///
/// `workouts.scheduled_date` is a `timestamptz` stored at **noon** of the
/// intended day (see CLAUDE.md — noon-local via `target_date_to_utc_iso`, or
/// noon-UTC for writers with no timezone). Reading it with `DateTime.parse`
/// therefore yields a **UTC instant**, and every surface that formats or
/// date-picker-seeds off that instant without `.toLocal()` is the client
/// mirror of the UTC-window class the backend fixed with `utc_to_local_date`.
///
/// Concretely, the workout-detail reschedule picker seeded itself from
/// `DateTime.tryParse(workout.scheduledDate)` and compared that UTC instant
/// against a *local* `firstDate` — so a legacy midnight-UTC row
/// (`2026-07-28T00:00:00Z` = 19:00 local the previous evening) sorted before
/// `firstDate` and the picker silently opened on today instead of the
/// workout's own day (E2E #31).
library;

/// The workout's scheduled day as a **local** midnight `DateTime`.
///
/// Accepts every shape `scheduled_date` reaches the client in:
///   * `2026-07-29T17:00:00+00:00` / `...Z` — noon-anchored timestamptz
///   * `2026-07-29 17:00:00+00`            — Postgres text form
///   * `2026-07-29`                        — a bare DATE column
///
/// **Resolution rule: the calendar-date PREFIX is the day.** This is the
/// app-wide convention, not a local choice — `Workout.scheduledDateKey` /
/// `Workout.scheduledLocalDate` (`data/models/workout.dart`),
/// `HeroWorkoutCarousel._scheduledDate`, `HeroWorkoutCard`,
/// `WorkoutPlannerSection._buildDateStrip`'s dot keys and every home-screen
/// bucket already split the string rather than parsing it, each with the same
/// comment: *"avoiding UTC→local timezone shift bugs"*.
///
/// Parsing the instant and calling `.toLocal()` instead looks more correct but
/// is NOT interchangeable, and disagrees on real production rows. Measured on
/// the live table (1,256 non-null `workouts.scheduled_date` rows), the count
/// where `(scheduled_date AT TIME ZONE tz)::date <> (… AT TIME ZONE 'UTC')::date`
/// — i.e. where `.toLocal()` names a different day than the prefix — is:
///   * America/Chicago … 45 rows (legacy writers anchored before 06:00 UTC)
///   * Asia/Tokyo …… 334 rows
///   * Pacific/Auckland … 1,155 rows (92% of the table)
/// Either way two adjacent surfaces would assert different days — which is
/// literally E2E #21 — and `reschedulePickerSeed` would see the workout's own
/// day as "in the past" and clamp the picker to today, which is literally the
/// second half of E2E #31. So: prefix, like everywhere else.
///
/// Returns null when the field is absent or unparseable — callers must handle
/// that honestly rather than substituting "today".
DateTime? scheduledLocalDay(String? raw) {
  final value = raw?.trim();
  if (value == null || value.isEmpty) return null;

  // Calendar-date prefix, before any time-of-day / zone designator. Handles
  // `T`-separated ISO, the Postgres space-separated text form, and a bare
  // DATE identically — and never converts, so it cannot shift the day.
  final datePart = value.split(RegExp(r'[T ]')).first;
  final parts = datePart.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  return DateTime(y, m, d);
}

/// Human label for a scheduled day, relative to [now] (defaults to the real
/// clock): `TODAY` / `TOMORROW` / `YESTERDAY`, otherwise `WED, JUL 29`
/// (with the year appended when it is not the current one).
///
/// Uppercase because every caller renders it in the app's label face.
String? scheduledDayLabel(DateTime? day, {DateTime? now}) {
  if (day == null) return null;
  final ref = now ?? DateTime.now();
  final today = DateTime(ref.year, ref.month, ref.day);
  final diff = day.difference(today).inDays;
  if (diff == 0) return 'TODAY';
  if (diff == 1) return 'TOMORROW';
  if (diff == -1) return 'YESTERDAY';

  const weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
  const months = [
    'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
    'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
  ];
  final base = '${weekdays[day.weekday - 1]}, '
      '${months[day.month - 1]} ${day.day}';
  return day.year == today.year ? base : '$base ${day.year}';
}

/// Order-independent resolver for "which local day is the workout carousel
/// focused on", used to keep a date strip and the card beneath it asserting
/// the SAME day (E2E #21).
///
/// The carousel reports its focus through two callbacks that arrive in either
/// order, and specifically in the WRONG order on first paint: it auto-jumps to
/// the next actionable session and fires `onPageChanged(index)` in a post-frame
/// callback registered *before* the one that publishes its item list. A
/// consumer that resolves the index against the list it holds at that instant
/// sees an empty list, bails out, and leaves its strip pinned to today — which
/// is exactly how "Tuesday 28" ended up next to "Wednesday — No workout yet".
///
/// This holds the index and the days independently and resolves only when both
/// are known, so neither arrival order can drop the sync.
class CarouselDateFocus {
  int? _index;
  List<DateTime?> _days = const [];

  /// Days of the carousel cards, in display order. `null` for a card with no
  /// date (never fabricate one).
  List<DateTime?> get days => _days;

  /// The focused card index, or null before the carousel has reported one.
  int? get index => _index;

  /// Records the focused page. Accepted even when [days] is still empty.
  /// Returns true when the resolved date changed.
  bool onPageChanged(int index) {
    if (index < 0) return false;
    final before = resolvedDay;
    _index = index;
    return resolvedDay != before;
  }

  /// Records the carousel's item days. Returns true when the resolved date
  /// changed (including the first time the index becomes resolvable).
  bool onDaysChanged(List<DateTime?> days) {
    final before = resolvedDay;
    _days = List<DateTime?>.unmodifiable(days);
    return resolvedDay != before;
  }

  /// True when [days] describes a different ordered run of days than the one
  /// currently held — a placeholder turning into a real workout mid-week
  /// leaves both the length and the first date untouched, so length-only
  /// comparisons go stale and mis-resolve every later lookup.
  bool sameDays(List<DateTime?> days) {
    if (days.length != _days.length) return false;
    for (int i = 0; i < days.length; i++) {
      if (days[i] != _days[i]) return false;
    }
    return true;
  }

  /// The focused card's day at local midnight, or null while unresolvable.
  ///
  /// A ONE-card carousel never reports a page: `HeroWorkoutCarousel` only runs
  /// its initial-jump → `onPageChanged` path when it holds more than one item,
  /// and renders a lone card without a `PageView` at all. That card is
  /// unambiguously the focused one, so resolve it rather than leaving the
  /// strip pinned to today beside a card showing another day — the same #21
  /// symptom, one card down.
  DateTime? get resolvedDay {
    var i = _index;
    if (i == null && _days.length == 1) i = 0;
    if (i == null || i < 0 || i >= _days.length) return null;
    final d = _days[i];
    if (d == null) return null;
    return DateTime(d.year, d.month, d.day);
  }
}

/// Seed date for a reschedule picker whose `firstDate` is [firstDate].
///
/// Prefers the workout's own scheduled day; falls back to [firstDate] when the
/// workout has no usable date or sits in the past (a missed session cannot be
/// re-scheduled into the past, and `showDatePicker` asserts on an
/// `initialDate` before `firstDate`).
DateTime reschedulePickerSeed(String? rawScheduledDate, DateTime firstDate) {
  final day = scheduledLocalDay(rawScheduledDate);
  if (day == null || day.isBefore(firstDate)) return firstDate;
  return day;
}
