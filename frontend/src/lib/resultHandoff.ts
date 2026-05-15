// Result handoff — encodes a tool's result snapshot into a URL hash that the
// Zealova mobile app reads on first open after install.
//
// Flow:
//   1. Web tool computes a result (e.g. TDEE = 2,450 cal).
//   2. User taps "Open in Zealova" or the Play Store badge.
//   3. We append `#zealova-handoff=<base64url JSON>` to the destination URL.
//   4. On Android, the Play Store referrer carries through to first launch.
//   5. The Flutter app's deep-link handler reads the hash on cold open and
//      pre-fills the relevant in-app screen (e.g. TDEE in nutrition settings).
//
// This converts anonymous web users to identified app users with their
// computed result pre-loaded — no re-entry friction.

export interface HandoffPayload {
  slug: string;
  result: Record<string, unknown>;
  // Optional pre-fill targets the app should hydrate.
  prefill?: {
    nutrition?: { calorieTarget?: number; protein?: number; carbs?: number; fat?: number };
    workout?: { exercise?: string; oneRm?: number; weightUnit?: 'lb' | 'kg' };
    profile?: { bodyFatPercent?: number; bodyWeight?: number };
  };
  // Compact timestamp so the app can age out stale handoffs (>30 days).
  ts: number;
}

function base64UrlEncode(str: string): string {
  return btoa(str)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

export function encodeHandoff(payload: Omit<HandoffPayload, 'ts'>): string {
  const full: HandoffPayload = { ...payload, ts: Date.now() };
  return base64UrlEncode(JSON.stringify(full));
}

/**
 * Build a deep-link URL with the handoff payload appended as a hash.
 * Use for "Open in app" buttons on result pages.
 */
export function buildHandoffDeepLink(slug: string, result: Record<string, unknown>, prefill?: HandoffPayload['prefill']): string {
  const encoded = encodeHandoff({ slug, result, prefill });
  return `zealova://tools/${slug}?result=${encoded}#zealova-handoff=${encoded}`;
}

/**
 * Build a Play Store URL with the handoff payload in the referrer.
 * Android passes referrer params to the app on first install, so the user's
 * result survives an "install → open" round trip.
 */
export function buildPlayStoreHandoffUrl(slug: string, result: Record<string, unknown>, prefill?: HandoffPayload['prefill']): string {
  const encoded = encodeHandoff({ slug, result, prefill });
  const referrer = new URLSearchParams({
    utm_source: 'tools',
    utm_medium: slug,
    utm_content: 'handoff',
    handoff: encoded,
  });
  return `https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=${referrer.toString()}`;
}
