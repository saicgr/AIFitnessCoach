/// Persistent visibility state for the home Coach hero card.
///
/// Three modes:
///   * [CoachCardVisibility.expanded]      — full card visible (default).
///   * [CoachCardVisibility.minimized]     — eyebrow + headline only.
///     User reached via the chevron at the card's top-right.
///   * [CoachCardVisibility.dismissedToday] — card hidden entirely until
///     the next local day rollover. User reached via the X button.
///
/// State persists across tab switches (survives any single widget lifecycle
/// because the notifier outlives the home screen's State) and across app
/// restarts (SharedPreferences). It is keyed by user-local date, so each
/// new day starts with a clean `expanded` slate — a fresh daily insight
/// deserves the user's attention.
///
/// SharedPrefs schema:
///   `coach_card_visibility_<YYYY-MM-DD>` → 'expanded' | 'minimized' | 'dismissed'
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum CoachCardVisibility {
  expanded,
  minimized,
  dismissedToday,
}

String _keyForDate(DateTime now) =>
    'coach_card_visibility_'
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

class CoachCardVisibilityNotifier extends StateNotifier<CoachCardVisibility> {
  CoachCardVisibilityNotifier() : super(CoachCardVisibility.expanded) {
    unawaited(_hydrate());
  }

  String _currentKey() => _keyForDate(DateTime.now());

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_currentKey());
      if (raw == null) return; // expanded default
      final next = switch (raw) {
        'minimized' => CoachCardVisibility.minimized,
        'dismissed' => CoachCardVisibility.dismissedToday,
        _ => CoachCardVisibility.expanded,
      };
      if (mounted && next != state) state = next;
    } catch (_) {
      // Pre-init or disk failure — keep default `expanded`.
    }
  }

  Future<void> _persist(CoachCardVisibility next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = switch (next) {
        CoachCardVisibility.expanded => 'expanded',
        CoachCardVisibility.minimized => 'minimized',
        CoachCardVisibility.dismissedToday => 'dismissed',
      };
      await prefs.setString(_currentKey(), raw);
    } catch (_) {
      // Disk write failed — in-memory state still wins for this session.
    }
  }

  void setExpanded() {
    state = CoachCardVisibility.expanded;
    unawaited(_persist(state));
  }

  void setMinimized() {
    state = CoachCardVisibility.minimized;
    unawaited(_persist(state));
  }

  void setDismissedToday() {
    state = CoachCardVisibility.dismissedToday;
    unawaited(_persist(state));
  }

  /// Toggle between expanded and minimized. Does NOT affect dismissed.
  void toggleMinimized() {
    if (state == CoachCardVisibility.dismissedToday) return;
    state = state == CoachCardVisibility.expanded
        ? CoachCardVisibility.minimized
        : CoachCardVisibility.expanded;
    unawaited(_persist(state));
  }
}

final coachCardVisibilityProvider =
    StateNotifierProvider<CoachCardVisibilityNotifier, CoachCardVisibility>(
        (ref) => CoachCardVisibilityNotifier());

/// In-session expansion state for the `+N more` chip inside the contextual
/// nudge stack. Pure in-memory (Riverpod) — doesn't need disk persistence,
/// just needs to outlive widget rebuilds caused by tab switches. Resets to
/// false on app restart, which is fine: a fresh launch shouldn't surface
/// the full stack by default.
final nudgeStackExpandedProvider = StateProvider<bool>((ref) => false);
