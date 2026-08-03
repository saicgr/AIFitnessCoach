/**
 * Waitlist submission chokepoint.
 *
 * Every waitlist surface (the landing CTA form, the /waitlist hero) posts
 * through `submitWaitlist` so source attribution, honeypot handling, and
 * FastAPI error flattening live in exactly one place.
 */

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const WAITLIST_ENDPOINT = '/api/v1/waitlist/';

// Allowed by backend ALLOWED_SOURCES — anything else is coerced to 'other'.
const ALLOWED_SOURCES = new Set([
  'marketing_landing',
  'waitlist_page',
  'twitter',
  'linkedin',
  'tiktok',
  'instagram',
  'reddit',
  'other',
]);

// Map common ?utm_source= values to the backend's canonical set.
const UTM_SOURCE_MAP: Record<string, string> = {
  twitter: 'twitter',
  x: 'twitter',
  'twitter.com': 'twitter',
  't.co': 'twitter',
  linkedin: 'linkedin',
  'linkedin.com': 'linkedin',
  li: 'linkedin',
  tiktok: 'tiktok',
  'tiktok.com': 'tiktok',
  tt: 'tiktok',
  instagram: 'instagram',
  'instagram.com': 'instagram',
  ig: 'instagram',
  reddit: 'reddit',
  'reddit.com': 'reddit',
};

// Referrer hostname → canonical source. Only used as a fallback when no
// UTM params are present — direct visits keep the page-default source.
const REFERRER_HOST_MAP: Record<string, string> = {
  'twitter.com': 'twitter',
  'mobile.twitter.com': 'twitter',
  'x.com': 'twitter',
  't.co': 'twitter',
  'linkedin.com': 'linkedin',
  'www.linkedin.com': 'linkedin',
  'lnkd.in': 'linkedin',
  'tiktok.com': 'tiktok',
  'www.tiktok.com': 'tiktok',
  'instagram.com': 'instagram',
  'www.instagram.com': 'instagram',
  'l.instagram.com': 'instagram',
  'reddit.com': 'reddit',
  'www.reddit.com': 'reddit',
  'old.reddit.com': 'reddit',
};

export function resolveWaitlistSource(defaultSource: string): string {
  if (typeof window === 'undefined') return defaultSource;

  // 1. ?utm_source= wins — explicit campaign tagging.
  try {
    const utm = new URLSearchParams(window.location.search)
      .get('utm_source')
      ?.trim()
      .toLowerCase();
    if (utm) {
      const mapped = UTM_SOURCE_MAP[utm] ?? utm;
      if (ALLOWED_SOURCES.has(mapped)) return mapped;
    }
  } catch {
    // URL parsing failed — fall through.
  }

  // 2. document.referrer hostname — covers organic clicks from socials.
  try {
    const ref = typeof document !== 'undefined' ? document.referrer : '';
    if (ref) {
      const host = new URL(ref).hostname.toLowerCase();
      const mapped = REFERRER_HOST_MAP[host];
      if (mapped && ALLOWED_SOURCES.has(mapped)) return mapped;
    }
  } catch {
    // Referrer wasn't a parseable URL — fall through.
  }

  // 3. Page default (marketing_landing / waitlist_page).
  return defaultSource;
}

export function isValidWaitlistEmail(email: string): boolean {
  return EMAIL_RE.test(email.trim());
}

export interface WaitlistSubmission {
  email: string;
  /** Page default source; overridden by ?utm_source= / referrer when present. */
  source: string;
  platformInterest?: 'ios' | 'android' | 'both';
  /** Honeypot field value — non-empty means bot. */
  website?: string;
}

export type WaitlistResult =
  | { ok: true }
  | { ok: false; message: string };

const BAD_EMAIL_MSG = 'That email looks off — double-check the format?';
const GENERIC_MSG = "Couldn't save that — try again in a sec?";

export async function submitWaitlist({
  email,
  source,
  platformInterest = 'both',
  website = '',
}: WaitlistSubmission): Promise<WaitlistResult> {
  // Honeypot tripped — bot. Report success and drop the payload.
  if (website) return { ok: true };

  const trimmed = email.trim();
  if (!isValidWaitlistEmail(trimmed)) {
    return { ok: false, message: BAD_EMAIL_MSG };
  }

  try {
    const res = await fetch(WAITLIST_ENDPOINT, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: trimmed.toLowerCase(),
        source: resolveWaitlistSource(source),
        platform_interest: platformInterest,
        referrer: typeof document !== 'undefined' ? document.referrer || null : null,
        user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
        website, // honeypot — empty for humans
      }),
    });

    if (res.ok) return { ok: true };

    if (res.status === 429) {
      return { ok: false, message: 'Too many tries — wait a minute then try again.' };
    }

    const body = await res.json().catch(() => ({}));
    // FastAPI/Pydantic returns `detail` as either a string OR an array of
    // `{type, loc, msg, ...}` validation objects. Rendering the array
    // directly into JSX crashes React (#31), so flatten it to a string.
    if (typeof body?.detail === 'string' && body.detail) {
      return { ok: false, message: body.detail };
    }
    if (Array.isArray(body?.detail)) {
      const emailIssue = body.detail.some(
        (e: { loc?: unknown[] }) => Array.isArray(e?.loc) && e.loc.includes('email'),
      );
      return { ok: false, message: emailIssue ? BAD_EMAIL_MSG : GENERIC_MSG };
    }
    return { ok: false, message: GENERIC_MSG };
  } catch (err) {
    console.error('[Waitlist] network error:', err);
    return { ok: false, message: 'Network error — check your connection?' };
  }
}
