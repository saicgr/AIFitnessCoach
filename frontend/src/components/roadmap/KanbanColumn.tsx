import { AnimatePresence } from 'framer-motion';
import type { RoadmapColumnMeta, RoadmapFeature } from '../../data/roadmap';
import type { RoadmapState } from '../../lib/roadmapApi';
import FeatureCard from './FeatureCard';

interface KanbanColumnProps {
  column: RoadmapColumnMeta;
  features: RoadmapFeature[];
  state: RoadmapState;
  votedSlugs: Set<string>;
  onOpen: (feature: RoadmapFeature) => void;
  onVote: (feature: RoadmapFeature) => void;
}

export default function KanbanColumn({
  column,
  features,
  state,
  votedSlugs,
  onOpen,
  onVote,
}: KanbanColumnProps) {
  return (
    <div className="flex min-w-0 flex-col">
      {/* Column header */}
      <div className="mb-3">
        <div className="flex items-center gap-2">
          <h2 className="text-[15px] font-bold text-[var(--color-text)]">
            <span className="mr-1.5">{column.emoji}</span>
            {column.label}
          </h2>
          <span className="inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-[var(--color-surface-muted)] px-1.5 text-[11px] font-bold text-[var(--color-text-secondary)]">
            {features.length}
          </span>
        </div>
        <div className="mt-1.5 h-[3px] w-full rounded-full" style={{ backgroundColor: column.accent }} />
        <p className="mt-2 text-[11.5px] leading-snug text-[var(--color-text-muted)]">
          {column.blurb}
        </p>
      </div>

      {/* Cards */}
      <div className="flex flex-col gap-2.5">
        <AnimatePresence mode="popLayout">
          {features.map((feature) => {
            const entry = state[feature.slug];
            return (
              <FeatureCard
                key={feature.slug}
                feature={feature}
                voteCount={entry?.vote_count ?? 0}
                commentCount={entry?.comment_count ?? 0}
                voted={votedSlugs.has(feature.slug)}
                onOpen={onOpen}
                onVote={onVote}
              />
            );
          })}
        </AnimatePresence>

        {features.length === 0 && (
          <p className="rounded-xl border border-dashed border-[var(--color-border)] px-3 py-6 text-center text-[12px] text-[var(--color-text-muted)]">
            Nothing here matches your filters.
          </p>
        )}
      </div>
    </div>
  );
}
