import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user.dart' as app_user;

/// Coordinates the first-home-load modal experience so a brand-new user is NOT
/// hit by a STACK of pop-ups the moment they reach home after onboarding.
///
/// Two problems this solves:
///  1. **Version-update modals shown to brand-new users.** "What's New" and the
///     score-change announcement explain what changed *since a previous version*
///     — meaningless (and confusing) for someone who just installed. A fresh
///     account is "caught up" to the current release, so these are marked seen
///     and never fire for them.
///  2. **Modal storm.** Level-up, health-connect, nav-tour, what's-new and the
///     score sheet each fired independently on home mount and could stack. They
///     now run through [FirstRunModalQueue] one at a time.
class FirstRunGate {
  FirstRunGate._();

  /// Pref keys owned by the version-update modals (so we can pre-mark them seen
  /// for fresh accounts). Bump the suffixes when a NEW announcement ships — a
  /// user who was fresh at v1 will still correctly see the v2 announcement once
  /// they've been around, because the new key won't be pre-marked for them.
  static const String _scoreChangeSeenKey = 'score_change_v2_seen';
  static const String _whatsNewSeenKey = 'whats_new_seen_gravl_v1';

  /// A just-onboarded user. We treat an account created within the last 24h as
  /// "fresh" — they have no prior app version to be told "what's new" about.
  static bool isFreshAccount(app_user.User? user) {
    final raw = user?.createdAt;
    if (raw == null || raw.isEmpty) {
      // No timestamp → fall back to the explicit new-user flag.
      return user?.isFirstLogin ?? false;
    }
    final created = DateTime.tryParse(raw);
    if (created == null) return user?.isFirstLogin ?? false;
    return DateTime.now().toUtc().difference(created.toUtc()) <
        const Duration(hours: 24);
  }

  /// Mark every current version-update announcement as already seen, so a fresh
  /// account never gets a "what changed" popup for a version they never used.
  /// Idempotent.
  static Future<void> markVersionAnnouncementsSeenForFreshUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scoreChangeSeenKey, true);
      await prefs.setBool(_whatsNewSeenKey, true);
      if (kDebugMode) {
        debugPrint(
          '🆕 [FirstRun] Fresh account — version announcements '
          'pre-marked seen (no What\'s New / score-change popup).',
        );
      }
    } catch (e) {
      debugPrint('⚠️ [FirstRun] Failed to pre-mark announcements seen: $e');
    }
  }
}

/// Serializes first-run modals so only ONE is visible at a time. Each entry is
/// a thunk that shows a modal and completes when that modal is dismissed
/// (e.g. `context.push(...)`, `showGlassSheet(...)`, `showLevelUpDialog(...)`),
/// so the next entry only starts after the previous closes.
class FirstRunModalQueue {
  FirstRunModalQueue._();

  static Future<void> _tail = Future<void>.value();
  static bool _busy = false;

  /// True while a queued modal is showing — lets independent listeners (e.g.
  /// the app-wide level-up listener) avoid popping over a running first-run modal.
  static bool get isBusy => _busy;

  /// Enqueue [show] to run after any currently-running/queued modal closes.
  /// [show] MUST await the modal's dismissal for serialization to hold.
  /// A thrown error in one entry never blocks the queue.
  static Future<void> enqueue(Future<void> Function() show) {
    final next = _tail.then((_) async {
      _busy = true;
      try {
        await show();
      } catch (e) {
        debugPrint('⚠️ [FirstRun] queued modal threw (non-fatal): $e');
      } finally {
        _busy = false;
      }
    });
    // Keep the chain alive even if an entry throws.
    _tail = next.catchError((_) {});
    return next;
  }
}
