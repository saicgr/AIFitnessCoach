/// `nudgeSnoozeProvider` — per-nudge 4-hour snooze state, persisted to
/// SharedPreferences so a swipe-dismiss survives an app restart but clears
/// at midnight local. Used by `contextualNudgeProvider` to filter the
/// stacked nudge list inside the Coach hero card.
///
/// Storage key: `nudge_snooze_<id.name>`. Value: ISO-8601 UTC string of
/// the snooze-until time. Reads are hydrated lazily on the first
/// `state` access; writes go to SharedPreferences synchronously-ish
/// (fire-and-forget — the in-memory map flips immediately, the disk
/// write follows).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/contextual_nudge.dart';

const Duration kNudgeSnoozeDuration = Duration(hours: 4);

String _prefsKey(NudgeId id) => 'nudge_snooze_${id.name}';

class NudgeSnoozeNotifier extends StateNotifier<Map<NudgeId, DateTime>> {
  NudgeSnoozeNotifier() : super(const {}) {
    // Fire-and-forget hydration. Until the disk read returns, the in-memory
    // state is empty — which means no nudges are snoozed yet. That's the
    // safe default (worst case a freshly-snoozed nudge shows once on cold
    // start before the disk catches up; the snooze will then re-apply).
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final out = <NudgeId, DateTime>{};
      for (final id in NudgeId.values) {
        final raw = prefs.getString(_prefsKey(id));
        if (raw == null || raw.isEmpty) continue;
        final until = DateTime.tryParse(raw);
        if (until == null) continue;
        // Drop stale entries — past-now AND past-midnight-today both
        // count as expired.
        if (until.isBefore(now)) {
          await prefs.remove(_prefsKey(id));
          continue;
        }
        if (until.toLocal().day != now.day &&
            until.toLocal().isAfter(now)) {
          // Snooze was set yesterday and would extend into today — drop it.
          // Day-rollover semantic from the spec.
          await prefs.remove(_prefsKey(id));
          continue;
        }
        out[id] = until;
      }
      if (mounted) state = out;
    } catch (_) {
      // Best-effort hydration — pre-init or disk failure leaves the in-mem
      // map empty, which simply means "nothing is snoozed yet". The next
      // snooze action still writes successfully.
    }
  }

  /// Snooze the given nudge for [kNudgeSnoozeDuration] from now.
  Future<void> snooze(NudgeId id) async {
    final until = DateTime.now().add(kNudgeSnoozeDuration);
    state = {...state, id: until};
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey(id), until.toUtc().toIso8601String());
    } catch (_) {
      // Disk write failed — the in-memory snooze still works for this session.
    }
  }

  /// Clear a snooze (used when the underlying state changes — e.g. user
  /// logs the meal that was snoozed; we don't want a stale snooze to keep
  /// a future re-trigger suppressed).
  Future<void> clear(NudgeId id) async {
    if (!state.containsKey(id)) return;
    final next = {...state}..remove(id);
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey(id));
    } catch (_) {}
  }

  /// True iff this nudge is currently snoozed.
  bool isSnoozed(NudgeId id) {
    final until = state[id];
    if (until == null) return false;
    if (until.isBefore(DateTime.now())) return false;
    return true;
  }
}

final nudgeSnoozeProvider =
    StateNotifierProvider<NudgeSnoozeNotifier, Map<NudgeId, DateTime>>(
        (ref) => NudgeSnoozeNotifier());
