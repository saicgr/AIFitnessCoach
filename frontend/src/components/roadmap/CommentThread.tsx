import { useEffect, useMemo, useState } from 'react';
import {
  addComment,
  fetchComments,
  getIdentity,
  saveIdentity,
  MAX_COMMENT_DEPTH,
  type RoadmapComment,
} from '../../lib/roadmapApi';

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

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

const FIELD =
  'w-full rounded-lg border border-white/10 bg-white/5 px-3 py-2 text-[13px] text-white placeholder:text-white/35 focus:border-volt-500/60 focus:outline-none';

interface ComposerProps {
  featureSlug: string;
  parentId: string; // '' = top-level comment
  onPosted: (comment: RoadmapComment) => void;
  onCancel?: () => void;
}

/** Name + email + body composer. Email is prefilled from the shared identity
 *  (the same email used for voting) and never shown publicly. */
function Composer({ featureSlug, parentId, onPosted, onCancel }: ComposerProps) {
  const [name, setName] = useState(getIdentity().name || '');
  const [email, setEmail] = useState(getIdentity().email || '');
  const [body, setBody] = useState('');
  const [honeypot, setHoneypot] = useState('');
  const [posting, setPosting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const isReply = parentId !== '';

  const submit = async () => {
    const cleanEmail = email.trim().toLowerCase();
    if (!name.trim()) return setError('Add your name.');
    if (!EMAIL_RE.test(cleanEmail)) return setError('Enter a valid email.');
    if (!body.trim()) return setError(isReply ? 'Write a reply first.' : 'Write a comment first.');
    setPosting(true);
    setError(null);
    try {
      const res = await addComment(featureSlug, name.trim(), body.trim(), cleanEmail, parentId, honeypot);
      saveIdentity({ name: name.trim(), email: cleanEmail });
      if (res.comment) onPosted(res.comment);
      setBody('');
      onCancel?.();
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Could not post. Please try again.');
    } finally {
      setPosting(false);
    }
  };

  return (
    <div className="space-y-2">
      <div className="flex gap-2">
        <input
          className={`${FIELD} w-1/2`}
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="Your name"
          maxLength={80}
        />
        <input
          className={`${FIELD} w-1/2`}
          type="email"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="Your email"
        />
      </div>
      {/* Honeypot */}
      <input
        type="text"
        tabIndex={-1}
        autoComplete="off"
        aria-hidden="true"
        value={honeypot}
        onChange={(e) => setHoneypot(e.target.value)}
        className="absolute left-[-9999px] h-0 w-0"
      />
      <textarea
        className={`${FIELD} resize-none`}
        value={body}
        onChange={(e) => setBody(e.target.value)}
        rows={isReply ? 2 : 3}
        maxLength={1000}
        placeholder={isReply ? 'Write a reply…' : 'Share your thoughts on this idea…'}
        autoFocus={isReply}
      />
      {error && <p className="text-[12px] text-rose-500">{error}</p>}
      <div className="flex gap-2">
        <button
          onClick={submit}
          disabled={posting}
          className="btn-volt flex-1 rounded-lg py-2 text-[13px] disabled:opacity-60"
        >
          {posting ? 'Posting…' : isReply ? 'Post reply' : 'Post comment'}
        </button>
        {onCancel && (
          <button
            onClick={onCancel}
            className="rounded-lg border border-white/10 px-3 py-2 text-[13px] font-medium text-white/60 hover:text-white"
          >
            Cancel
          </button>
        )}
      </div>
    </div>
  );
}

interface CommentThreadProps {
  featureSlug: string;
  onCommentAdded: (slug: string) => void;
}

/** Reddit-style threaded comments (up to 10 levels). Flat list from the API,
 *  assembled into a tree here; replies post with a parent_id. */
export default function CommentThread({ featureSlug, onCommentAdded }: CommentThreadProps) {
  const [comments, setComments] = useState<RoadmapComment[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyTo, setReplyTo] = useState<string | null>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    fetchComments(featureSlug).then((list) => {
      if (active) {
        setComments(list);
        setLoading(false);
      }
    });
    return () => {
      active = false;
    };
  }, [featureSlug]);

  // Group children by parent. Orphans (parent hidden/removed) bubble to root.
  const childrenMap = useMemo(() => {
    const ids = new Set(comments.map((c) => c.id));
    const map = new Map<string, RoadmapComment[]>();
    for (const c of comments) {
      const key = c.parent_id && ids.has(c.parent_id) ? c.parent_id : 'root';
      const arr = map.get(key) || [];
      arr.push(c);
      map.set(key, arr);
    }
    return map;
  }, [comments]);

  const onPosted = (comment: RoadmapComment) => {
    setComments((prev) => [...prev, comment]);
    onCommentAdded(featureSlug);
    setReplyTo(null);
  };

  const renderNode = (c: RoadmapComment) => {
    const kids = childrenMap.get(c.id) || [];
    const canReply = c.depth < MAX_COMMENT_DEPTH;
    return (
      <div key={c.id}>
        <div className="rounded-lg border border-white/10 bg-white/[0.02] p-3">
          <div className="flex items-baseline justify-between gap-2">
            <span className="text-[13px] font-semibold text-white">{c.author_name}</span>
            <span className="text-[11px] text-white/45">{timeAgo(c.created_at)}</span>
          </div>
          <p className="mt-1 whitespace-pre-wrap text-[13px] leading-relaxed text-white/60">
            {c.body}
          </p>
          {canReply && (
            <button
              onClick={() => setReplyTo(replyTo === c.id ? null : c.id)}
              className="mt-2 text-[12px] font-semibold text-volt-400 hover:underline"
            >
              {replyTo === c.id ? 'Cancel' : 'Reply'}
            </button>
          )}
        </div>
        {replyTo === c.id && (
          <div className="mt-2">
            <Composer
              featureSlug={featureSlug}
              parentId={c.id}
              onPosted={onPosted}
              onCancel={() => setReplyTo(null)}
            />
          </div>
        )}
        {kids.length > 0 && (
          <div className="ml-1 mt-2.5 space-y-2.5 border-l-2 border-white/10 pl-2.5">
            {kids.map(renderNode)}
          </div>
        )}
      </div>
    );
  };

  const roots = childrenMap.get('root') || [];

  return (
    <div className="mt-7">
      <h3 className="text-sm font-bold text-white">
        Comments {comments.length > 0 && `(${comments.length})`}
      </h3>

      <div className="mt-3 space-y-2.5">
        {loading && <p className="text-[13px] text-white/45">Loading comments…</p>}
        {!loading && roots.length === 0 && (
          <p className="text-[13px] text-white/45">
            No comments yet. Be the first to weigh in.
          </p>
        )}
        {roots.map(renderNode)}
      </div>

      <div className="mt-4">
        <Composer featureSlug={featureSlug} parentId="" onPosted={onPosted} />
      </div>
      <p className="mt-2 text-[11px] leading-snug text-white/45">
        Your name shows on the comment. Your email never does — it's only used to keep
        comments accountable, the same email you vote with.
      </p>
    </div>
  );
}
