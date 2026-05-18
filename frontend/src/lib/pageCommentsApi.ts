// Fetch client for marketing-page comments (backend: api/v1/public_page_comments.py).
//
// The base is a RELATIVE path on purpose — the marketing site reaches the
// backend via a same-origin Vercel rewrite (vercel.json `/api/v1/page-comments/
// :path*`), the same approach as the roadmap board. A direct Render URL would
// be cross-origin and CORS-blocked.

const BASE = '/api/v1/page-comments';

export interface PageComment {
  id: string;
  author_name: string;
  body: string;
  created_at: string;
}

/** All visible comments for a page, oldest-first. Non-critical — returns [] on failure. */
export async function fetchPageComments(pageSlug: string): Promise<PageComment[]> {
  try {
    // pageSlug may contain a slash (e.g. 'vs/bevel'); the backend route uses a
    // :path converter, so the slash is passed through raw (not encoded).
    const res = await fetch(`${BASE}/comments/${pageSlug}`);
    if (!res.ok) return [];
    const data = (await res.json()) as { comments: PageComment[] };
    return data.comments || [];
  } catch {
    return [];
  }
}

/** Post a comment. Email is required by the backend. Throws on failure. */
export async function addPageComment(
  pageSlug: string,
  authorName: string,
  body: string,
  email: string,
  honeypot = '',
): Promise<{ success: boolean; comment: PageComment | null }> {
  const res = await fetch(`${BASE}/comment`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      page_slug: pageSlug,
      author_name: authorName,
      body,
      email,
      website: honeypot,
    }),
  });
  if (!res.ok) {
    if (res.status === 429) {
      throw new Error('Too many comments — please slow down and try again shortly.');
    }
    const detail = await res.json().catch(() => ({}));
    throw new Error(
      (detail as { detail?: string }).detail || 'Could not post your comment. Please try again.',
    );
  }
  return res.json() as Promise<{ success: boolean; comment: PageComment | null }>;
}
