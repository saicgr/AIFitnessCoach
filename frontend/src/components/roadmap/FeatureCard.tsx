import { motion } from 'framer-motion';
import type { RoadmapFeature } from '../../data/roadmap';
import { TAG_COLORS } from '../../data/roadmap';

interface FeatureCardProps {
  feature: RoadmapFeature;
  voteCount: number;
  commentCount: number;
  voted: boolean;
  onOpen: (feature: RoadmapFeature) => void;
  onVote: (feature: RoadmapFeature) => void;
}

/** The left badge slot — MacroFactor-style vote pill, a ✓ for shipped,
 *  or nothing for Won't Do (the reason tag carries that column). */
function BadgeSlot({
  feature,
  voteCount,
  voted,
  onVote,
}: {
  feature: RoadmapFeature;
  voteCount: number;
  voted: boolean;
  onVote: (feature: RoadmapFeature) => void;
}) {
  if (feature.column === 'released') {
    return (
      <div className="flex flex-col items-center justify-center w-12 h-12 rounded-xl shrink-0 bg-emerald-500/12 text-emerald-500">
        <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2.5}>
          <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
        </svg>
      </div>
    );
  }
  if (feature.column === 'wont_do') {
    return (
      <div className="flex items-center justify-center w-12 h-12 rounded-xl shrink-0 bg-rose-500/10 text-rose-500 text-lg">
        ✕
      </div>
    );
  }
  // Votable: clickable pill. Blue filled = voted.
  return (
    <button
      type="button"
      onClick={(e) => {
        e.stopPropagation();
        onVote(feature);
      }}
      aria-label={voted ? `Voted for ${feature.title}` : `Vote for ${feature.title}`}
      className={`group/vote flex flex-col items-center justify-center w-12 h-12 rounded-xl shrink-0 border transition-all ${
        voted
          ? 'bg-blue-500 border-blue-500 text-white shadow-sm shadow-blue-500/30'
          : 'bg-[var(--color-surface-muted)] border-[var(--color-border)] text-[var(--color-text-secondary)] hover:border-blue-400 hover:text-blue-500'
      }`}
    >
      <svg
        className={`w-3.5 h-3.5 transition-transform ${voted ? '' : 'group-hover/vote:-translate-y-0.5'}`}
        fill={voted ? 'currentColor' : 'none'}
        stroke="currentColor"
        viewBox="0 0 24 24"
        strokeWidth={2.5}
      >
        <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 15.75l7.5-7.5 7.5 7.5" />
      </svg>
      <span className="text-[13px] font-bold leading-none mt-0.5 tabular-nums">{voteCount}</span>
    </button>
  );
}

export default function FeatureCard({
  feature,
  voteCount,
  commentCount,
  voted,
  onOpen,
  onVote,
}: FeatureCardProps) {
  return (
    <motion.div
      layout
      onClick={() => onOpen(feature)}
      role="button"
      tabIndex={0}
      onKeyDown={(e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          onOpen(feature);
        }
      }}
      className="group cursor-pointer rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-4 transition-all hover:border-[var(--color-text-muted)] hover:-translate-y-0.5 hover:shadow-md focus:outline-none focus-visible:ring-2 focus-visible:ring-blue-500/50"
    >
      <div className="flex gap-3.5">
        <BadgeSlot feature={feature} voteCount={voteCount} voted={voted} onVote={onVote} />

        <div className="min-w-0 flex-1">
          <h3 className="text-[15px] font-semibold leading-snug text-[var(--color-text)] group-hover:text-blue-500 transition-colors">
            {feature.title}
          </h3>
          <p className="mt-1 text-[13px] leading-relaxed text-[var(--color-text-secondary)] line-clamp-2">
            {feature.description}
          </p>

          <div className="mt-2.5 flex flex-wrap items-center gap-1.5">
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
              <span className="inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-semibold tracking-wide bg-[var(--color-surface-muted)] text-[var(--color-text-muted)]">
                {feature.eta}
              </span>
            )}

            {commentCount > 0 && (
              <span className="inline-flex items-center gap-1 text-[11px] font-medium text-[var(--color-text-muted)] ml-auto">
                <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={1.8}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M8 12h8M8 8h8m-8 8h5m4-13H5a2 2 0 00-2 2v14l4-4h12a2 2 0 002-2V5a2 2 0 00-2-2z" />
                </svg>
                {commentCount}
              </span>
            )}
          </div>

          {feature.reason && (
            <p className="mt-2.5 rounded-lg bg-rose-500/8 px-2.5 py-1.5 text-[11.5px] leading-snug text-rose-500/90">
              {feature.reason}
            </p>
          )}
        </div>
      </div>
    </motion.div>
  );
}
