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
          <h2 className="text-[15px] font-bold text-white">
            <span className="mr-1.5">{column.emoji}</span>
            {column.label}
          </h2>
          <span className="inline-flex h-5 min-w-[20px] items-center justify-center rounded-full bg-white/10 px-1.5 text-[11px] font-bold text-white/60">
            {features.length}
          </span>
        </div>
        <div className="mt-1.5 h-[3px] w-full rounded-full" style={{ backgroundColor: column.accent }} />
        <p className="mt-2 text-[11.5px] leading-snug text-white/40">
          {column.blurb}
        </p>
      </div>

      {/* Cards — each column scrolls independently on desktop */}
      <div className="flex flex-col gap-2.5 lg:max-h-[70vh] lg:overflow-y-auto lg:pr-1.5">
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
          <p className="rounded-xl border border-dashed border-white/10 px-3 py-6 text-center text-[12px] text-white/40">
            Nothing here matches your filters.
          </p>
        )}
      </div>
    </div>
  );
}
