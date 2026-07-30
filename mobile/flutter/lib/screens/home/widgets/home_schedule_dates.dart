/// Home schedule date resolution — the ONE place that turns a workout's
/// `scheduled_date` into the user's LOCAL calendar day.
///
/// Why this file exists (E2E #21 / #65, the "date-resolution family"):
///
/// `workouts.scheduled_date` is a `timestamptz` stored at NOON of the day it
/// belongs to (see CLAUDE.md — noon so the anchor lands inside its own local-day
/// window in every realistic timezone). Two different shapes reach the client:
///
///   * `/workouts/today` serialises it as a bare `YYYY-MM-DD` — already the
///     user's local calendar day, resolved server-side against their tz.
///   * `/workouts` (→ `workoutsProvider`) serialises the raw instant, e.g.
///     `2026-07-31T17:00:00+00:00`.
///
/// Home used to day-match the second shape by slicing its first 10 characters
/// and comparing that to a LOCAL `YYYY-MM-DD` built from `DateTime.now()`.
/// That compares a **UTC** date against a **local** date. For every user whose
/// local noon lands on a different UTC date — UTC+12/+13 (Auckland, Fiji,
/// Kiritimati) and UTC−12 — today's workout stops matching "today", the hero
/// falls through to the generic next-workout, and the card names a day that
/// contradicts the week strip sitting directly above it. Formatting has the
/// mirror bug: `DateTime.parse(raw.split('T')[0])` formats the UTC date, so the
/// same workout renders as a different weekday than the strip highlights.
///
/// Everything on Home therefore goes through [scheduledLocalDay] /
/// [scheduledLocalDateKey] / [isScheduledOnLocalDay], never through a substring.
library;

/// The local `YYYY-MM-DD` key for a local [DateTime]. The canonical key format
/// for every day-match on Home.
String homeLocalDateKey(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The user's LOCAL calendar day (midnight, local) a `scheduled_date` belongs
/// to, or null when [raw] is absent / unparseable.
///
/// Handles both wire shapes:
///   * bare `YYYY-MM-DD` — already a local calendar day, taken verbatim.
///   * full ISO instant (`…T17:00:00+00:00`, `…Z`, or offset-less) — parsed and
///     converted to local before the calendar day is read.
DateTime? scheduledLocalDay(String? raw) {
  final s = raw?.trim();
  if (s == null || s.isEmpty) return null;

  // Bare date: the server already resolved it against the user's timezone.
  // Parsing it as an instant would be identical (Dart reads a date-only string
  // as local midnight) but being explicit documents the contract.
  if (s.length == 10) {
    final parts = s.split('-');
    if (parts.length == 3) {
      final y = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      final d = int.tryParse(parts[2]);
      if (y != null && m != null && d != null) return DateTime(y, m, d);
    }
    return null;
  }

  final parsed = DateTime.tryParse(s);
  if (parsed == null) return null;
  final local = parsed.toLocal();
  return DateTime(local.year, local.month, local.day);
}

/// The local `YYYY-MM-DD` key for a `scheduled_date`, or null when it can't be
/// resolved. Use this instead of `raw.substring(0, 10)`.
String? scheduledLocalDateKey(String? raw) {
  final day = scheduledLocalDay(raw);
  return day == null ? null : homeLocalDateKey(day);
}

/// True when [raw] is scheduled on the same LOCAL calendar day as [day].
bool isScheduledOnLocalDay(String? raw, DateTime day) {
  final resolved = scheduledLocalDay(raw);
  if (resolved == null) return false;
  return resolved.year == day.year &&
      resolved.month == day.month &&
      resolved.day == day.day;
}

/// Whole days from [from]'s local calendar day to [raw]'s local calendar day.
/// Negative in the past, 0 for the same day, positive in the future. Null when
/// [raw] can't be resolved.
int? scheduledDayOffset(String? raw, DateTime from) {
  final resolved = scheduledLocalDay(raw);
  if (resolved == null) return null;
  final base = DateTime(from.year, from.month, from.day);
  return resolved.difference(base).inDays;
}
