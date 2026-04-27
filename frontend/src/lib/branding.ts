// Single source of truth for brand identity in the Zealova web frontend.
//
// To rename the app: edit this file ONLY (plus matching Flutter
// `lib/core/constants/branding.dart` and backend `core/branding.py`).
//
// LOCKED identifiers (packageId*, deepLinkScheme) must never change
// post-launch — changing them breaks installs, subscriptions, and
// share/widget links on existing user devices.

const MARKETING_DOMAIN = 'zealova.com';

export const BRANDING = {
  // Identity
  appName: 'Zealova',
  fullTitle: 'Zealova: Workout & Meal Coach',
  tagline: 'Workout & Meal Coach',

  // Contact
  supportEmail: `support@${MARKETING_DOMAIN}`,
  privacyEmail: `privacy@${MARKETING_DOMAIN}`,
  websiteUrl: `https://${MARKETING_DOMAIN}`,
  marketingDomain: MARKETING_DOMAIN,

  // Social
  instagram: 'https://instagram.com/getzealova',

  // Locked identifiers (informational; never change post-launch)
  packageIdAndroid: 'com.aifitnesscoach.app',
  packageIdIos: 'com.aifitnesscoach.app',
  deepLinkScheme: 'fitwiz',
} as const;
