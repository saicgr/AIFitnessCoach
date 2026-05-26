/// Tracks whether the user has minimized the persistent floating coach
/// head to its side-tab form for today.
///
/// Set true when the user drags the head into the bottom dismiss zone.
/// Auto-resets at midnight local (keyed by date in SharedPreferences),
/// so the head returns as the new daily insight generates.
///
/// State lives in Riverpod (not just SharedPreferences) so consumers see
/// the change immediately on the user's drag — no fire-and-forget disk
/// round-trip needed before the UI reflects the morph.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

String _prefsKey(DateTime now) =>
    'coach_bubble_minimized_'
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

class CoachBubbleMinimizedNotifier extends StateNotifier<bool> {
  CoachBubbleMinimizedNotifier() : super(false) {
    unawaited(_hydrate());
  }

  Future<void> _hydrate() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getBool(_prefsKey(DateTime.now()));
      if (raw == null) return; // false default (head visible)
      if (mounted && raw != state) state = raw;
    } catch (_) {
      // Pre-init or disk failure — keep default `false`.
    }
  }

  Future<void> _persist(bool next) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefsKey(DateTime.now()), next);
    } catch (_) {
      // Disk write failed — in-memory state still wins for the session.
    }
  }

  void minimize() {
    state = true;
    unawaited(_persist(true));
  }

  void expand() {
    state = false;
    unawaited(_persist(false));
  }

  void toggle() {
    state = !state;
    unawaited(_persist(state));
  }
}

final coachBubbleMinimizedProvider =
    StateNotifierProvider<CoachBubbleMinimizedNotifier, bool>(
        (ref) => CoachBubbleMinimizedNotifier());
