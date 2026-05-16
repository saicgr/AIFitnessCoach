import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import type { RoadmapFeature } from '../../data/roadmap';
import { ROADMAP_COLUMNS, TAG_COLORS } from '../../data/roadmap';
import { addComment, fetchComments, type RoadmapComment } from '../../lib/roadmapApi';

interface FeatureDrawerProps {
  feature: RoadmapFeature;
  voteCount: number;
  voted: boolean;
  onClose: () => void;
  onVote: (feature: RoadmapFeature) => void;
  onCommentAdded: (slug: string) => void;
}

function timeAgo(iso: string): string {
  const diff = Date.now() - new Date(iso).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hrs = Math.floor(mins / 60);
  if (hrs < 24) return `${hrs}h ago`;
  const days = Math.floor(hrs / 24);
  if (days < 30) return `${days}d ago`;
  return new Date(iso).toLocaleDateString(undefined, { month: 'short', day: 'numeric' });
}

export default function FeatureDrawer({
  feature,
  voteCount,
  voted,
  onClose,
  onVote,
  onCommentAdded,
}: FeatureDrawerProps) {
  const [comments, setComments] = useState<RoadmapComment[]>([]);
  const [loadingComments, setLoadingComments] = useState(true);
  const [name, setName] = useState('');
  const [body, setBody] = useState('');
  const [honeypot, setHoneypot] = useState('');
  const [posting, setPosting] = useState(false);
  const [commentError, setCommentError] = useState<string | null>(null);
  const [copied, setCopied] = useState(false);

  const column = ROADMAP_COLUMNS.find((c) => c.id === feature.column)!;

  useEffect(() => {
    let active = true;
    setLoadingComments(true);
    fetchComments(feature.slug).then((list) => {
      if (active) {
        setComments(list);
        setLoadingComments(false);
      }
    });
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => {
      active = false;
      window.removeEventListener('keydown', onKey);
    };
  }, [feature.slug, onClose]);

  const share = async () => {
    const url = `${window.location.origin}/roadmap?feature=${feature.slug}`;
    try {
      await navigator.clipboard.writeText(url);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch {
      /* clipboard blocked — silently ignore */
    }
  };

  const postComment = async () => {
    if (!name.trim() || !body.trim()) {
      setCommentError('Add your name and a comment.');
      return;
    }
    setPosting(true);
    setCommentError(null);
    try {
      const res = await addComment(feature.slug, name.trim(), body.trim(), honeypot);
      if (res.comment) setComments((c) => [...c, res.comment!]);
      setBody('');
      onCommentAdded(feature.slug);
    } catch (e) {
      setCommentError(e instanceof Error ? e.message : 'Could not post comment.');
    } finally {
      setPosting(false);
    }
  };

  return (
    <motion.div
      className="fixed inset-0 z-[55] flex justify-end"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/50 backdrop-blur-sm" />

      <motion.aside
        className="relative flex h-full w-full max-w-md flex-col bg-[var(--color-surface)] shadow-2xl"
        initial={{ x: '100%' }}
        animate={{ x: 0 }}
        exit={{ x: '100%' }}
        transition={{ type: 'spring', damping: 30, stiffness: 300 }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="flex items-start justify-between gap-3 border-b border-[var(--color-border)] p-5">
          <div className="min-w-0">
            <span
              className="inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[11px] font-semibold"
              style={{ backgroundColor: `${column.accent}22`, color: column.accent }}
            >
              {column.emoji} {column.label}
            </span>
            <h2 className="mt-2.5 text-xl font-bold leading-snug text-[var(--color-text)]">
              {feature.title}
            </h2>
          </div>
          <button
            onClick={onClose}
            aria-label="Close"
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full text-[var(--color-text-muted)] hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-text)] transition-colors"
          >
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {/* Scrollable body */}
        <div className="flex-1 overflow-y-auto p-5">
          <p className="text-sm leading-relaxed text-[var(--color-text-secondary)]">
            {feature.description}
          </p>

          <div className="mt-3 flex flex-wrap gap-1.5">
            {feature.tags.map((tag) => (
              <span
                key={tag}
                className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold tracking-wide"
                style={{ backgroundColor: TAG_COLORS[tag].bg, color: TAG_COLORS[tag].text }}
              >
                {tag}
              </span>
            ))}
            {feature.eta && (
              <span className="inline-flex items-center rounded-full bg-[var(--color-surface-muted)] px-2 py-0.5 text-[10px] font-semibold text-[var(--color-text-muted)]">
                {feature.eta}
              </span>
            )}
          </div>

          {feature.reason && (
            <p className="mt-3 rounded-lg bg-rose-500/8 px-3 py-2 text-[13px] leading-snug text-rose-500/90">
              <span className="font-semibold">Why not: </span>
              {feature.reason}
            </p>
          )}

          {/* Vote + share actions */}
          <div className="mt-5 flex gap-2.5">
            {feature.votable && (
              <button
                onClick={() => onVote(feature)}
                className={`flex flex-1 items-center justify-center gap-2 rounded-xl py-2.5 text-sm font-semibold transition-all ${
                  voted
                    ? 'bg-blue-500 text-white'
                    : 'border border-[var(--color-border)] bg-[var(--color-surface-muted)] text-[var(--color-text)] hover:border-blue-400 hover:text-blue-500'
                }`}
              >
                <svg
                  className="h-4 w-4"
                  fill={voted ? 'currentColor' : 'none'}
                  stroke="currentColor"
                  viewBox="0 0 24 24"
                  strokeWidth={2.5}
                >
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5" />
                </svg>
                {voted ? 'Voted' : 'Vote'} · {voteCount}
              </button>
            )}
            <button
              onClick={share}
              className="flex items-center justify-center gap-2 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface-muted)] px-4 py-2.5 text-sm font-semibold text-[var(--color-text)] transition-colors hover:text-blue-500"
            >
              <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.8}>
                <path strokeLinecap="round" strokeLinejoin="round" d="M13.19 8.688a4.5 4.5 0 011.242 7.244l-4.5 4.5a4.5 4.5 0 01-6.364-6.364l1.757-1.757m13.35-.622l1.757-1.757a4.5 4.5 0 00-6.364-6.364l-4.5 4.5a4.5 4.5 0 001.242 7.244" />
              </svg>
              {copied ? 'Copied' : 'Share'}
            </button>
          </div>

          {/* Comments — flat, no threading, no sort */}
          <div className="mt-7">
            <h3 className="text-sm font-bold text-[var(--color-text)]">
              Comments {comments.length > 0 && `(${comments.length})`}
            </h3>

            <div className="mt-3 space-y-3">
              {loadingComments && (
                <p className="text-[13px] text-[var(--color-text-muted)]">Loading comments…</p>
              )}
              {!loadingComments && comments.length === 0 && (
                <p className="text-[13px] text-[var(--color-text-muted)]">
                  No comments yet. Be the first to weigh in.
                </p>
              )}
              {comments.map((c) => (
                <div key={c.id} className="rounded-lg border border-[var(--color-border)] p-3">
                  <div className="flex items-baseline justify-between gap-2">
                    <span className="text-[13px] font-semibold text-[var(--color-text)]">
                      {c.author_name}
                    </span>
                    <span className="text-[11px] text-[var(--color-text-muted)]">
                      {timeAgo(c.created_at)}
                    </span>
                  </div>
                  <p className="mt-1 whitespace-pre-wrap text-[13px] leading-relaxed text-[var(--color-text-secondary)]">
                    {c.body}
                  </p>
                </div>
              ))}
            </div>

            {/* Add-comment form */}
            <div className="mt-4 space-y-2.5">
              <input
                type="text"
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="Your name"
                maxLength={80}
                className="w-full rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] px-3 py-2 text-[13px] text-[var(--color-text)] placeholder:text-[var(--color-text-muted)] focus:border-blue-400 focus:outline-none"
              />
              <input
                type="text"
                tabIndex={-1}
                autoComplete="off"
                value={honeypot}
                onChange={(e) => setHoneypot(e.target.value)}
                className="absolute left-[-9999px] h-0 w-0"
                aria-hidden="true"
              />
              <textarea
                value={body}
                onChange={(e) => setBody(e.target.value)}
                placeholder="Share your thoughts on this idea…"
                rows={3}
                maxLength={1000}
                className="w-full resize-none rounded-lg border border-[var(--color-border)] bg-[var(--color-surface-muted)] px-3 py-2 text-[13px] text-[var(--color-text)] placeholder:text-[var(--color-text-muted)] focus:border-blue-400 focus:outline-none"
              />
              {commentError && <p className="text-[12px] text-rose-500">{commentError}</p>}
              <button
                onClick={postComment}
                disabled={posting}
                className="w-full rounded-lg bg-[var(--color-text)] py-2.5 text-[13px] font-semibold text-[var(--color-surface)] transition-opacity hover:opacity-90 disabled:opacity-60"
              >
                {posting ? 'Posting…' : 'Post comment'}
              </button>
            </div>
          </div>
        </div>
      </motion.aside>
    </motion.div>
  );
}
