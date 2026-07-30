import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// The ONE formatter for a chat message's timestamp. Every chat surface
/// (thread bubbles, the floating overlay, session list rows) must route
/// through this so a message can never be labelled with two different clocks.
///
/// Two defects this exists to make impossible (E2E register #69 / #95):
///
///  1. **UTC-date bucketing.** `chat_history.created_at` is a `timestamptz`,
///     so `DateTime.parse('2026-07-29T04:49:00+00:00')` returns a DateTime
///     with `isUtc == true`. Reading `.hour` / `.day` straight off it prints
///     the UTC clock *and* buckets "is this today?" by the UTC date — a
///     message sent at 23:49 CDT rendered as `Jul 29, 04:49`: the UTC instant
///     on tomorrow's date. Every field here is read off `.toLocal()` first,
///     including the day used for the today / yesterday comparison. This is
///     the Flutter mirror of the backend's `utc_to_local_date` rule.
///
///  2. **A hardcoded 24-hour clock.** The bubble printed `14:06` while the
///     rest of the app renders `2:06 PM`. Time-of-day now goes through
///     [MaterialLocalizations], so it follows the app locale *and* the
///     device's own 24-hour switch (which `app.dart` already forwards via
///     `alwaysUse24HourFormat`) instead of asserting one format for everyone.
String formatChatTimestamp(BuildContext context, DateTime raw) {
  // Resolve the instant into the user's local zone BEFORE anything reads a
  // calendar field off it. `toLocal()` on an already-local DateTime is a no-op.
  final local = raw.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final messageDay = DateTime(local.year, local.month, local.day);

  final timeStr = formatChatTimeOfDay(context, local);

  if (messageDay == today) return timeStr;
  if (messageDay == today.subtract(const Duration(days: 1))) {
    return 'Yesterday, $timeStr';
  }

  final locale = Localizations.localeOf(context).toString();
  final dateStr = messageDay.year == today.year
      ? DateFormat.MMMd(locale).format(local)
      : DateFormat.yMMMd(locale).format(local);
  return '$dateStr, $timeStr';
}

/// Locale- and device-aware time-of-day for an ALREADY-LOCAL DateTime.
/// Split out so callers that only need the clock (e.g. a grouped day header)
/// cannot accidentally re-introduce a hand-rolled `HH:mm`.
String formatChatTimeOfDay(BuildContext context, DateTime local) {
  return MaterialLocalizations.of(context).formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    // `alwaysUse24HourFormatOf`, not `MediaQuery.of(...)`: this runs once per
    // message bubble, and depending on the whole MediaQueryData would rebuild
    // every bubble in the thread on any metrics change — and in chat the
    // keyboard opens and closes constantly.
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
}
