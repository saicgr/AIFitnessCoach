// Comment section for long-form marketing pages (/vs/* and /best-*-2026).
//
// Email-keyed and frictionless — no account. The visitor supplies name + email
// (both required) once; identity is remembered in localStorage and shared with
// the roadmap board so it prefills everywhere. Comments publish immediately.
//
// The page shell is prerendered static; this component hydrates client-side
// and fetches comments from /api/v1/page-comments at runtime.

import { useEffect, useState } from 'react';
import type { FormEvent } from 'react';
import { fetchPageComments, addPageComment } from '../../lib/pageCommentsApi';
import type { PageComment } from '../../lib/pageCommentsApi';
import { getIdentity, saveIdentity } from '../../lib/roadmapApi';

/** Compact relative time, e.g. "3d ago". Falls back to a date for old comments. */
function timeAgo(iso: string): string {
  const then = new Date(iso).getTime();
  if (Number.isNaN(then)) return '';
  const secs = Math.max(0, (Date.now() - then) / 1000);
  if (secs < 60) return 'just now';
  const mins = Math.floor(secs / 60);
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(iso).toLocaleDateString();
}

/** Deterministic zinc-tinted avatar initial from the author name. */
function initial(name: string): string {
  return (name.trim()[0] || '?').toUpperCase();
}

export default function CommentSection({ slug }: { slug: string }) {
  const [comments, setComments] = useState<PageComment[]>([]);
  const [loading, setLoading] = useState(true);

  const [name, setName] = useState('');
  const [email, setEmail] = useState('');
  const [body, setBody] = useState('');
  const [honeypot, setHoneypot] = useState(''); // bots fill this; humans never see it

  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState('');
  const [justPosted, setJustPosted] = useState(false);

  useEffect(() => {
    // Prefill identity captured on a previous comment / roadmap vote.
    const id = getIdentity();
    if (id.name) setName(id.name);
    if (id.email) setEmail(id.email);

    let alive = true;
    fetchPageComments(slug).then((rows) => {
      if (alive) {
        setComments(rows);
        setLoading(false);
      }
    });
    return () => {
      alive = false;
    };
  }, [slug]);

  async function handleSubmit(e: FormEvent) {
    e.preventDefault();
    setError('');

    const n = name.trim();
    const em = email.trim();
    const b = body.trim();
    if (!n || !em || !b) {
      setError('Name, email, and a comment are all required.');
      return;
    }
    // Light client-side email shape check; the backend validates strictly.
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(em)) {
      setError('Please enter a valid email address.');
      return;
    }

    setSubmitting(true);
    try {
      const res = await addPageComment(slug, n, b, em, honeypot);
      if (res.comment) setComments((prev) => [...prev, res.comment as PageComment]);
      saveIdentity({ name: n, email: em }); // remember for next time + roadmap
      setBody('');
      setJustPosted(true);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not post your comment.');
    } finally {
      setSubmitting(false);
    }
  }

  const inputClass =
    'w-full rounded-lg bg-zinc-900 border border-zinc-700 px-3 py-2 text-sm text-zinc-100 ' +
    'placeholder-zinc-500 focus:outline-none focus:border-emerald-500 focus:ring-1 focus:ring-emerald-500';

  return (
    <section id="comments" className="mt-16 sm:mt-24 border-t border-zinc-800 pt-10 scroll-mt-24">
      <h2 className="text-2xl font-bold text-white mb-1">
        Comments{comments.length > 0 ? ` (${comments.length})` : ''}
      </h2>
      <p className="text-sm text-zinc-500 mb-8">
        Questions or your own experience with these apps? Leave a note below.
      </p>

      {/* ---- Comment list ---- */}
      {loading ? (
        <p className="text-sm text-zinc-500">Loading comments…</p>
      ) : comments.length === 0 ? (
        <p className="text-sm text-zinc-500 mb-8">No comments yet — be the first.</p>
      ) : (
        <ul className="space-y-5 mb-10">
          {comments.map((c) => (
            <li key={c.id} className="flex gap-3">
              <div
                className="flex-shrink-0 w-9 h-9 rounded-full bg-zinc-800 text-zinc-300 grid place-items-center text-sm font-semibold"
                aria-hidden="true"
              >
                {initial(c.author_name)}
              </div>
              <div className="min-w-0">
                <div className="flex items-baseline gap-2">
                  <span className="text-sm font-semibold text-zinc-100">{c.author_name}</span>
                  <span className="text-xs text-zinc-500">{timeAgo(c.created_at)}</span>
                </div>
                <p className="text-sm text-zinc-300 leading-relaxed whitespace-pre-wrap break-words">
                  {c.body}
                </p>
              </div>
            </li>
          ))}
        </ul>
      )}

      {/* ---- Comment form ---- */}
      {justPosted ? (
        <div className="rounded-xl border border-emerald-800 bg-emerald-950/40 px-4 py-3 text-sm text-emerald-300">
          Thanks — your comment is posted.{' '}
          <button
            type="button"
            onClick={() => setJustPosted(false)}
            className="underline hover:text-emerald-200"
          >
            Add another
          </button>
        </div>
      ) : (
        <form onSubmit={handleSubmit} className="rounded-xl border border-zinc-800 bg-zinc-900/40 p-4 sm:p-5">
          <p className="text-sm font-semibold text-zinc-200 mb-3">Leave a comment</p>
          <div className="grid sm:grid-cols-2 gap-3 mb-3">
            <div>
              <label htmlFor="cs-name" className="block text-xs text-zinc-500 mb-1">
                Name
              </label>
              <input
                id="cs-name"
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                maxLength={80}
                placeholder="Your name"
                className={inputClass}
              />
            </div>
            <div>
              <label htmlFor="cs-email" className="block text-xs text-zinc-500 mb-1">
                Email <span className="text-zinc-600">(required, never shown)</span>
              </label>
              <input
                id="cs-email"
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                maxLength={160}
                placeholder="you@example.com"
                className={inputClass}
              />
            </div>
          </div>
          <div className="mb-3">
            <label htmlFor="cs-body" className="block text-xs text-zinc-500 mb-1">
              Comment
            </label>
            <textarea
              id="cs-body"
              value={body}
              onChange={(e) => setBody(e.target.value)}
              maxLength={1000}
              rows={4}
              placeholder="Share your take…"
              className={`${inputClass} resize-y`}
            />
            <p className="text-right text-xs text-zinc-600 mt-1">{body.length}/1000</p>
          </div>

          {/* Honeypot — visually hidden, off-screen; bots fill it, humans don't. */}
          <input
            type="text"
            tabIndex={-1}
            autoComplete="off"
            aria-hidden="true"
            value={honeypot}
            onChange={(e) => setHoneypot(e.target.value)}
            className="absolute -left-[9999px] w-px h-px opacity-0"
          />

          {error && <p className="text-sm text-red-400 mb-3">{error}</p>}

          <button
            type="submit"
            disabled={submitting}
            className="rounded-lg bg-emerald-500 hover:bg-emerald-400 disabled:opacity-50 disabled:cursor-not-allowed px-5 py-2 text-sm font-semibold text-zinc-950 transition-colors"
          >
            {submitting ? 'Posting…' : 'Post comment'}
          </button>
        </form>
      )}
    </section>
  );
}
