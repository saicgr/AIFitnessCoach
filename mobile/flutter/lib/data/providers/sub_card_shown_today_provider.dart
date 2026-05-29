/// Tracks the set of sub-card `dedupKey`s the user has dismissed or whose
/// CTA they tapped earlier today. The SubCardRanker uses this to suppress
/// already-acted-on cards for the rest of the local day.
///
/// Persisted to SharedPreferences keyed by `<userId>:<isoDate>` so a
/// cold-start re-loads the day's history. Auto-rolls over at local
/// midnight (the key changes when the date changes).
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../repositories/auth_repository.dart' show authStateProvider;

class SubCardShownTodayNotifier extends StateNotifier<Set<String>> {
  SubCardShownTodayNotifier(this._userId) : super(<String>{}) {
    if (_userId != null) {
      unawaited(_load());
    }
  }

  final String? _userId;

  String _todayKey() {
    final now = DateTime.now();
    final iso =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    return 'sub_card_shown_${_userId ?? "anon"}_$iso';
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_todayKey());
      if (raw != null && raw.isNotEmpty) {
        state = raw.toSet();
      }
    } catch (e) {
      debugPrint('[SubCardShownToday] _load failed: $e');
    }
  }

  Future<void> _persist() async {
    if (_userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_todayKey(), state.toList(growable: false));
    } catch (e) {
      debugPrint('[SubCardShownToday] _persist failed: $e');
    }
  }

  Future<void> markShown(String dedupKey) async {
    if (state.contains(dedupKey)) return;
    state = {...state, dedupKey};
    await _persist();
  }

  /// Un-hide a dedupKey hidden earlier today. Backs the "Undo" action on the
  /// swipe-to-hide snackbar so an accidental swipe is recoverable.
  Future<void> removeShown(String dedupKey) async {
    if (!state.contains(dedupKey)) return;
    state = {...state}..remove(dedupKey);
    await _persist();
  }

  Future<void> clearAll() async {
    state = <String>{};
    await _persist();
  }
}

final subCardShownTodayProvider =
    StateNotifierProvider<SubCardShownTodayNotifier, Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).user?.id;
  return SubCardShownTodayNotifier(uid);
});
