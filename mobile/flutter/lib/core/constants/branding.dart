/// Single source of truth for ALL brand identity in the Flutter app.
///
/// To rename the app: edit this file ONLY (and the matching backend
/// `core/branding.py` + web `lib/branding.ts` files). Everything else —
/// class names, native configs, top-level docs — is updated by
/// `scripts/rename_brand.sh` from these values, or already references
/// this class.
///
/// LOCKED identifiers below (packageId, widgetAppGroupId, deepLinkScheme)
/// must NEVER change post-launch — changing them breaks installs,
/// subscriptions, share links, and widget data on existing user devices.
library;

import 'app_links.dart';

class Branding {
  Branding._();

  // ── Identity ─────────────────────────────────────────────────────────────
  static const String appName = 'Zealova';
  static const String fullTitle = 'Zealova: Workout & Meal Coach';
  static const String tagline = 'Workout & Meal Coach';

  // ── Contact (re-exports from AppLinks for one-stop import) ───────────────
  static const String supportEmail = AppLinks.supportEmail;
  static const String websiteUrl = AppLinks.website;
  static const String marketingDomain = 'zealova.com';

  // ── Bundle / package identifiers (LOCKED — never change post-launch) ─────
  static const String packageIdAndroid = 'com.aifitnesscoach.app';
  static const String packageIdIos = 'com.aifitnesscoach.app';
  static const String widgetAppGroupId = 'group.com.aifitnesscoach.widgets';

  // ── Deep link scheme (LOCKED — share/widget links break if changed) ──────
  static const String deepLinkScheme = 'fitwiz';

  // ── Watermark / share-card branding ──────────────────────────────────────
  static const String watermarkText = appName;

  // ── App version (read by AppInfoSection / settings) ──────────────────────
  static const String version = '1.0.0';
}
