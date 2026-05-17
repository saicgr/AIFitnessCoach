import { useEffect, useState } from 'react';
import { motion } from 'framer-motion';
import type { RoadmapFeature } from '../../data/roadmap';
import { ROADMAP_COLUMNS, TAG_COLORS } from '../../data/roadmap';
import CommentThread from './CommentThread';

interface FeatureDrawerProps {
  feature: RoadmapFeature;
  voteCount: number;
  voted: boolean;
  onClose: () => void;
  onVote: (feature: RoadmapFeature) => void;
  onCommentAdded: (slug: string) => void;
}

export default function FeatureDrawer({
  feature,
  voteCount,
  voted,
  onClose,
  onVote,
  onCommentAdded,
}: FeatureDrawerProps) {
  const [copied, setCopied] = useState(false);
  const [expanded, setExpanded] = useState(false);

  const column = ROADMAP_COLUMNS.find((c) => c.id === feature.column)!;

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

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

  // When expanded to full screen, content is centered in a readable column.
  const inner = expanded ? 'mx-auto w-full max-w-3xl' : 'w-full';

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
        className={`relative flex h-full w-full flex-col bg-[var(--color-surface)] shadow-2xl transition-[max-width] duration-300 ${
          expanded ? 'max-w-full' : 'max-w-md'
        }`}
        initial={{ x: '100%' }}
        animate={{ x: 0 }}
        exit={{ x: '100%' }}
        transition={{ type: 'spring', damping: 30, stiffness: 300 }}
        onClick={(e) => e.stopPropagation()}
      >
        {/* Header */}
        <div className="border-b border-[var(--color-border)] p-5">
          <div className={`flex items-start justify-between gap-3 ${inner}`}>
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
            <div className="flex shrink-0 items-center gap-1">
              <button
                onClick={() => setExpanded((v) => !v)}
                aria-label={expanded ? 'Exit full screen' : 'Full screen'}
                className="hidden h-9 w-9 items-center justify-center rounded-full text-[var(--color-text-muted)] hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-text)] transition-colors sm:flex"
              >
                {expanded ? (
                  <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M9 9V4.5M9 9H4.5M9 9L3.75 3.75M15 9h4.5M15 9V4.5M15 9l5.25-5.25M9 15v4.5M9 15H4.5M9 15l-5.25 5.25M15 15h4.5M15 15v4.5m0-4.5l5.25 5.25" />
                  </svg>
                ) : (
                  <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9m11.25-5.25v4.5m0-4.5h-4.5m4.5 0L15 9m-11.25 11.25v-4.5m0 4.5h4.5m-4.5 0L9 15m11.25 5.25v-4.5m0 4.5h-4.5m4.5 0L15 15" />
                  </svg>
                )}
              </button>
              <button
                onClick={onClose}
                aria-label="Close"
                className="flex h-9 w-9 items-center justify-center rounded-full text-[var(--color-text-muted)] hover:bg-[var(--color-surface-muted)] hover:text-[var(--color-text)] transition-colors"
              >
                <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          </div>
        </div>

        {/* Scrollable body */}
        <div className="flex-1 overflow-y-auto p-5">
          <div className={inner}>
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

            {/* Threaded comments */}
            <CommentThread featureSlug={feature.slug} onCommentAdded={onCommentAdded} />
          </div>
        </div>
      </motion.aside>
    </motion.div>
  );
}
