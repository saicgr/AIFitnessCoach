import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/posthog_service.dart';

/// In-app rating prompt orchestrator. Implements the "two-step" pattern
/// (Cal AI / Realtor.com / Lose It): a custom pre-prompt asks "Enjoying
/// Zealova?" before triggering the platform's native review sheet. Only
/// users who tap 👍 see the system rating dialog — 👎 routes to feedback
/// so we never feed the App Store / Play Store a bad-faith review.
///
/// Triggers: incremented from "happy moments" (workout completed, meal
/// logged, menu scan completed). After the threshold for any one event
/// type is hit, [shouldPrompt] returns true and the host calls
/// [presentNativeReview] (or shows the custom sheet first).
///
/// Apple system limits this to 3 native prompts per 365 days per user
/// regardless of what we ask, and we additionally:
///   - wait at least 7 days post-install before the first prompt
///   - cap at one prompt per app version
///   - respect "Maybe later" with a 7-day cooldown
///   - respect "Don't ask again" permanently
///   - never re-ask if the user already submitted
class RatingPromptService {
  // ── State keys (SharedPreferences) ────────────────────────────────
  static const _kFirstLaunchAt = 'rating_first_launch_at';
  static const _kWorkoutCount = 'rating_workout_count';
  static const _kMealCount = 'rating_meal_count';
  static const _kScanCount = 'rating_scan_count';
  static const _kLastPromptedAt = 'rating_last_prompted_at';
  static const _kLastPromptedVersion = 'rating_last_prompted_version';
  static const _kRemindLaterUntil = 'rating_remind_later_until';
  static const _kSubmitted = 'rating_submitted';
  static const _kDismissedPermanently = 'rating_dismissed_permanently';
  static const _kBannerDismissed = 'rating_banner_dismissed';

  // ── Thresholds (override via constructor for tests) ───────────────
  /// Minimum days post-install before any prompt fires. Matches Apple's
  /// own published guideline + every category leader's recommendation.
  static const Duration _minInstallAge = Duration(days: 7);
  static const Duration _remindLaterCooldown = Duration(days: 7);
  static const Duration _afterDismissCooldown = Duration(days: 90);

  /// Threshold for any single event type to trigger eligibility. We use
  /// 3 to match Cal AI / BetterMe — enough that the user has clearly
  /// engaged, low enough that we ask while they're still in the
  /// initial-honeymoon happiness window.
  static const int _eventThreshold = 3;

  final InAppReview _review;
  final Ref _ref;

  RatingPromptService(this._ref, {InAppReview? review})
      : _review = review ?? InAppReview.instance;

  // ── Recorders (call from trigger sites) ────────────────────────────

  Future<void> recordWorkoutCompleted() async =>
      _bumpAndCheck(_kWorkoutCount, 'workout_completed');
  Future<void> recordMealLogged() async =>
      _bumpAndCheck(_kMealCount, 'meal_logged');
  Future<void> recordMenuScanned() async =>
      _bumpAndCheck(_kScanCount, 'menu_scanned');

  /// Increment the counter and return whether the threshold was just
  /// crossed (i.e. this is the call that pushed it over the line).
  /// Used by the trigger sites to decide whether to immediately surface
  /// the prompt sheet — but [shouldPrompt] is the canonical eligibility
  /// gate (also runs all the other checks: install age, cooldowns,
  /// version flags, submitted, etc.).
  Future<bool> _bumpAndCheck(String key, String eventName) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFirstLaunchSeeded(prefs);
    final current = prefs.getInt(key) ?? 0;
    final next = current + 1;
    await prefs.setInt(key, next);
    final crossed = current < _eventThreshold && next >= _eventThreshold;
    debugPrint(
        '⭐ [Rating] $eventName count: $current → $next (threshold $_eventThreshold)${crossed ? " ← crossed" : ""}');
    return crossed;
  }

  Future<void> _ensureFirstLaunchSeeded(SharedPreferences prefs) async {
    if (prefs.getString(_kFirstLaunchAt) == null) {
      await prefs.setString(
          _kFirstLaunchAt, DateTime.now().toIso8601String());
    }
  }

  // ── Eligibility ────────────────────────────────────────────────────

  /// True if the prompt sheet may be shown right now. Single source of
  /// truth — combines install-age, cooldown, version, submitted, and
  /// permanent-dismiss flags. Trigger sites should call this BEFORE
  /// surfacing the custom sheet.
  Future<bool> shouldPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureFirstLaunchSeeded(prefs);

    if (prefs.getBool(_kSubmitted) ?? false) return false;
    if (prefs.getBool(_kDismissedPermanently) ?? false) return false;

    // Install age gate.
    final firstLaunch = DateTime.tryParse(
        prefs.getString(_kFirstLaunchAt) ?? '');
    if (firstLaunch != null) {
      if (DateTime.now().difference(firstLaunch) < _minInstallAge) {
        return false;
      }
    }

    // "Maybe later" cooldown.
    final remindUntil = DateTime.tryParse(
        prefs.getString(_kRemindLaterUntil) ?? '');
    if (remindUntil != null && DateTime.now().isBefore(remindUntil)) {
      return false;
    }

    // Once per version (Apple's published recommendation).
    final lastVersion = prefs.getString(_kLastPromptedVersion);
    if (lastVersion != null) {
      try {
        final info = await PackageInfo.fromPlatform();
        if (lastVersion == info.version) return false;
      } catch (_) {}
    }

    // Threshold check across any event type.
    final anyThresholdHit =
        (prefs.getInt(_kWorkoutCount) ?? 0) >= _eventThreshold ||
            (prefs.getInt(_kMealCount) ?? 0) >= _eventThreshold ||
            (prefs.getInt(_kScanCount) ?? 0) >= _eventThreshold;
    return anyThresholdHit;
  }

  /// Lighter check used by the home banner: shows after the install-age
  /// gate is past + at least one threshold hit + not submitted/dismissed
  /// + banner not dismissed for this version. Lets users self-serve the
  /// rating from home even when the auto-trigger window passed.
  Future<bool> shouldShowBanner() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_kSubmitted) ?? false) return false;
    if (prefs.getBool(_kDismissedPermanently) ?? false) return false;
    if (prefs.getBool(_kBannerDismissed) ?? false) return false;

    await _ensureFirstLaunchSeeded(prefs);
    final firstLaunch = DateTime.tryParse(
        prefs.getString(_kFirstLaunchAt) ?? '');
    if (firstLaunch != null &&
        DateTime.now().difference(firstLaunch) < _minInstallAge) {
      return false;
    }

    final anyThresholdHit =
        (prefs.getInt(_kWorkoutCount) ?? 0) >= _eventThreshold ||
            (prefs.getInt(_kMealCount) ?? 0) >= _eventThreshold ||
            (prefs.getInt(_kScanCount) ?? 0) >= _eventThreshold;
    return anyThresholdHit;
  }

  // ── Actions ────────────────────────────────────────────────────────

  /// Trigger the platform-native review sheet. Routes to
  /// SKStoreReviewController on iOS (in-app stars + system review) and
  /// Google Play ReviewManager on Android (in-app review card). The
  /// system silently no-ops if quota exceeded — that's fine, mark as
  /// submitted so we don't keep retrying.
  Future<void> presentNativeReview() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (await _review.isAvailable()) {
        await _review.requestReview();
        await _markPromptedThisVersion(prefs);
        await prefs.setBool(_kSubmitted, true);
        _captureEvent('rating_native_sheet_shown');
      } else {
        // Not available — fall back to opening the store listing so the
        // user can rate the long way. Still better than swallowing.
        await openStoreListing();
      }
    } catch (e) {
      debugPrint('⚠️ [Rating] presentNativeReview failed: $e');
    }
  }

  /// Open the App Store / Play Store listing page directly. Used as a
  /// fallback when the in-app review sheet is unavailable, and from the
  /// settings → "Rate app" tap (where the in-app sheet is rate-limited
  /// to 3/year).
  Future<void> openStoreListing() async {
    try {
      await _review.openStoreListing(
        // App Store ID for iOS — fill in once published
        appStoreId: '6743068856',
      );
      _captureEvent('rating_store_listing_opened');
    } catch (e) {
      debugPrint('⚠️ [Rating] openStoreListing failed: $e');
    }
  }

  /// User tapped 👎 — route them to feedback path INSTEAD of the
  /// system review sheet. Marks "submitted" so we don't re-ask;
  /// negative respondents have already told us they're unhappy and
  /// asking again is bad UX.
  Future<void> markFeedbackTaken() async {
    final prefs = await SharedPreferences.getInstance();
    await _markPromptedThisVersion(prefs);
    await prefs.setBool(_kSubmitted, true);
    _captureEvent('rating_feedback_path_taken');
  }

  Future<void> markRemindLater() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_remindLaterCooldown);
    await prefs.setString(_kRemindLaterUntil, until.toIso8601String());
    _captureEvent('rating_remind_later');
  }

  Future<void> markDismissedPermanently() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now().add(_afterDismissCooldown);
    await prefs.setString(_kRemindLaterUntil, until.toIso8601String());
    await prefs.setBool(_kDismissedPermanently, true);
    _captureEvent('rating_dismissed_permanently');
  }

  Future<void> dismissBanner() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBannerDismissed, true);
    _captureEvent('rating_banner_dismissed');
  }

  Future<void> _markPromptedThisVersion(SharedPreferences prefs) async {
    await prefs.setString(_kLastPromptedAt, DateTime.now().toIso8601String());
    try {
      final info = await PackageInfo.fromPlatform();
      await prefs.setString(_kLastPromptedVersion, info.version);
    } catch (_) {}
  }

  void _captureEvent(String event) {
    try {
      _ref.read(posthogServiceProvider).capture(
        eventName: event,
        properties: <String, Object>{
          'platform': Platform.isIOS ? 'ios' : 'android',
        },
      );
    } catch (_) {
      // PostHog may not be initialized in tests — non-fatal.
    }
  }
}

final ratingPromptServiceProvider = Provider<RatingPromptService>(
  (ref) => RatingPromptService(ref),
);
