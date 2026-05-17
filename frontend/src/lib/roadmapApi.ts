// Fetch client for the public /roadmap board API (backend: api/v1/public_roadmap.py).
//
// The base is a RELATIVE path on purpose. The marketing site reaches the
// backend via a same-origin Vercel rewrite (vercel.json `/api/v1/roadmap/
// :path*`) — same approach as the waitlist form. Calling the Render URL
// directly (via VITE_API_URL) would be cross-origin and CORS-blocked.

const BASE = '/api/v1/roadmap';

export interface RoadmapStateEntry {
  vote_count: number;
  comment_count: number;
}
export type RoadmapState = Record<string, RoadmapStateEntry>;

export interface RoadmapComment {
  id: string;
  author_name: string;
  body: string;
  created_at: string;
}

export interface VoteResult {
  success: boolean;
  already_voted: boolean;
  vote_count: number;
}

async function postJson<T>(path: string, body: unknown): Promise<T> {
  const res = await fetch(`${BASE}${path}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    if (res.status === 429) {
      throw new Error('Too many requests — please slow down and try again shortly.');
    }
    const detail = await res.json().catch(() => ({}));
    throw new Error((detail as { detail?: string }).detail || 'Something went wrong. Please try again.');
  }
  return res.json() as Promise<T>;
}

/** Vote + comment counts for the whole board (one call, drives hydration). */
export async function fetchRoadmapState(): Promise<RoadmapState> {
  try {
    const res = await fetch(`${BASE}/state`);
    if (!res.ok) return {};
    return (await res.json()) as RoadmapState;
  } catch {
    // Counts are non-critical — the static board still renders without them.
    return {};
  }
}

export function voteForFeature(
  featureSlug: string,
  email: string,
  notifyOnShip: boolean,
  honeypot = '',
): Promise<VoteResult> {
  return postJson<VoteResult>('/vote', {
    feature_slug: featureSlug,
    email,
    notify_on_ship: notifyOnShip,
    website: honeypot,
  });
}

export async function fetchComments(featureSlug: string): Promise<RoadmapComment[]> {
  try {
    const res = await fetch(`${BASE}/comments/${encodeURIComponent(featureSlug)}`);
    if (!res.ok) return [];
    const data = (await res.json()) as { comments: RoadmapComment[] };
    return data.comments || [];
  } catch {
    return [];
  }
}

export function addComment(
  featureSlug: string,
  authorName: string,
  body: string,
  email = '',
  honeypot = '',
): Promise<{ success: boolean; comment: RoadmapComment | null }> {
  return postJson('/comment', {
    feature_slug: featureSlug,
    author_name: authorName,
    body,
    // Omit when blank — the backend validates email as EmailStr when present.
    email: email || undefined,
    website: honeypot,
  });
}

export function suggestFeature(
  email: string,
  title: string,
  body: string,
  honeypot = '',
): Promise<{ success: boolean; message: string }> {
  return postJson('/suggest', { email, title, body, website: honeypot });
}

// --- Local "I voted for this" memory ----------------------------------
// Voting is email-keyed server-side; this just lets the UI keep the badge
// in its blue voted-state across reloads without a round-trip.

const VOTED_KEY = 'zealova_roadmap_voted';

export function getVotedSlugs(): Set<string> {
  try {
    return new Set(JSON.parse(localStorage.getItem(VOTED_KEY) || '[]'));
  } catch {
    return new Set();
  }
}

export function markVoted(slug: string): void {
  try {
    const set = getVotedSlugs();
    set.add(slug);
    localStorage.setItem(VOTED_KEY, JSON.stringify([...set]));
  } catch {
    /* localStorage unavailable — voted state just won't persist */
  }
}

// --- Visitor identity (name + email), captured once -------------------
// Shared by voting and commenting so the visitor enters their email once
// and it's prefilled everywhere after — no account, no repeated typing.

const IDENTITY_KEY = 'zealova_roadmap_identity';

export interface RoadmapIdentity {
  name?: string;
  email?: string;
}

export function getIdentity(): RoadmapIdentity {
  try {
    return JSON.parse(localStorage.getItem(IDENTITY_KEY) || '{}');
  } catch {
    return {};
  }
}

export function saveIdentity(patch: RoadmapIdentity): void {
  try {
    localStorage.setItem(IDENTITY_KEY, JSON.stringify({ ...getIdentity(), ...patch }));
  } catch {
    /* localStorage unavailable — identity just won't persist */
  }
}
