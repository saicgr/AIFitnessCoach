import { useMemo, useState } from 'react';
import {
  ROADMAP_COLUMNS,
  ROADMAP_FEATURES,
  ROADMAP_TAGS,
  TAG_COLORS,
  type RoadmapColumnId,
  type RoadmapFeature,
  type RoadmapTag,
} from '../../data/roadmap';
import type { RoadmapState } from '../../lib/roadmapApi';
import KanbanColumn from './KanbanColumn';

interface KanbanBoardProps {
  state: RoadmapState;
  votedSlugs: Set<string>;
  onOpen: (feature: RoadmapFeature) => void;
  onVote: (feature: RoadmapFeature) => void;
}

type SortMode = 'votes' | 'newest';

export default function KanbanBoard({ state, votedSlugs, onOpen, onVote }: KanbanBoardProps) {
  const [selectedTags, setSelectedTags] = useState<Set<RoadmapTag>>(new Set());
  const [search, setSearch] = useState('');
  const [sortMode, setSortMode] = useState<SortMode>('votes');
  const [mobileColumn, setMobileColumn] = useState<RoadmapColumnId>('under_consideration');

  const toggleTag = (tag: RoadmapTag) => {
    setSelectedTags((prev) => {
      const next = new Set(prev);
      next.has(tag) ? next.delete(tag) : next.add(tag);
      return next;
    });
  };

  // Per-column filtered + sorted feature lists.
  const byColumn = useMemo(() => {
    const q = search.trim().toLowerCase();
    const passes = (f: RoadmapFeature) => {
      const tagOk =
        selectedTags.size === 0 || f.tags.some((t) => selectedTags.has(t));
      const searchOk =
        q === '' || `${f.title} ${f.description}`.toLowerCase().includes(q);
      return tagOk && searchOk;
    };
    const result: Record<RoadmapColumnId, RoadmapFeature[]> = {
      under_consideration: [],
      planned: [],
      in_progress: [],
      released: [],
      wont_do: [],
    };
    for (const f of ROADMAP_FEATURES) {
      if (passes(f)) result[f.column].push(f);
    }
    if (sortMode === 'votes') {
      for (const col of Object.keys(result) as RoadmapColumnId[]) {
        // Stable sort: ties keep authored (newest-first) order.
        result[col] = [...result[col]].sort(
          (a, b) => (state[b.slug]?.vote_count ?? 0) - (state[a.slug]?.vote_count ?? 0),
        );
      }
    }
    return result;
  }, [selectedTags, search, sortMode, state]);

  return (
    <div>
      {/* ---- Filter bar ---- */}
      <div className="mb-7 space-y-3">
        <div className="flex flex-col gap-3 sm:flex-row sm:items-center">
          {/* Search */}
          <div className="relative sm:w-72">
            <svg
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-[var(--color-text-muted)]"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
              strokeWidth={2}
            >
              <path strokeLinecap="round" strokeLinejoin="round" d="M21 21l-5.2-5.2m2.2-5.3a7.5 7.5 0 11-15 0 7.5 7.5 0 0115 0z" />
            </svg>
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Search the roadmap"
              className="w-full rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] py-2.5 pl-9 pr-3 text-sm text-[var(--color-text)] placeholder:text-[var(--color-text-muted)] focus:border-blue-400 focus:outline-none"
            />
          </div>

          {/* Sort toggle */}
          <div className="flex items-center gap-1 rounded-xl border border-[var(--color-border)] bg-[var(--color-surface)] p-1 sm:ml-auto">
            {(['votes', 'newest'] as SortMode[]).map((mode) => (
              <button
                key={mode}
                onClick={() => setSortMode(mode)}
                className={`rounded-lg px-3 py-1.5 text-[12.5px] font-semibold transition-colors ${
                  sortMode === mode
                    ? 'bg-[var(--color-text)] text-[var(--color-surface)]'
                    : 'text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
                }`}
              >
                {mode === 'votes' ? 'Most voted' : 'Newest'}
              </button>
            ))}
          </div>
        </div>

        {/* Tag filter chips */}
        <div className="flex flex-wrap gap-1.5">
          <button
            onClick={() => setSelectedTags(new Set())}
            className={`rounded-full px-3 py-1 text-[12px] font-semibold transition-colors ${
              selectedTags.size === 0
                ? 'bg-[var(--color-text)] text-[var(--color-surface)]'
                : 'bg-[var(--color-surface-muted)] text-[var(--color-text-secondary)] hover:text-[var(--color-text)]'
            }`}
          >
            All
          </button>
          {ROADMAP_TAGS.map((tag) => {
            const active = selectedTags.has(tag);
            return (
              <button
                key={tag}
                onClick={() => toggleTag(tag)}
                className="rounded-full px-3 py-1 text-[12px] font-semibold transition-all"
                style={
                  active
                    ? { backgroundColor: TAG_COLORS[tag].text, color: '#fff' }
                    : { backgroundColor: TAG_COLORS[tag].bg, color: TAG_COLORS[tag].text }
                }
              >
                {tag}
              </button>
            );
          })}
        </div>
      </div>

      {/* ---- Desktop: 5 columns side by side ---- */}
      <div className="hidden gap-5 lg:grid lg:grid-cols-5">
        {ROADMAP_COLUMNS.map((column) => (
          <KanbanColumn
            key={column.id}
            column={column}
            features={byColumn[column.id]}
            state={state}
            votedSlugs={votedSlugs}
            onOpen={onOpen}
            onVote={onVote}
          />
        ))}
      </div>

      {/* ---- Mobile / tablet: column tabs ---- */}
      <div className="lg:hidden">
        <div className="-mx-1 mb-5 flex gap-1 overflow-x-auto px-1 pb-1">
          {ROADMAP_COLUMNS.map((column) => {
            const active = mobileColumn === column.id;
            return (
              <button
                key={column.id}
                onClick={() => setMobileColumn(column.id)}
                className={`flex shrink-0 items-center gap-1.5 rounded-xl border px-3 py-2 text-[12.5px] font-semibold transition-colors ${
                  active
                    ? 'border-transparent text-[var(--color-surface)]'
                    : 'border-[var(--color-border)] bg-[var(--color-surface)] text-[var(--color-text-secondary)]'
                }`}
                style={active ? { backgroundColor: column.accent } : undefined}
              >
                <span>{column.emoji}</span>
                <span>{column.label}</span>
                <span
                  className={`inline-flex h-4 min-w-[16px] items-center justify-center rounded-full px-1 text-[10px] font-bold ${
                    active ? 'bg-white/25' : 'bg-[var(--color-surface-muted)]'
                  }`}
                >
                  {byColumn[column.id].length}
                </span>
              </button>
            );
          })}
        </div>

        {ROADMAP_COLUMNS.filter((c) => c.id === mobileColumn).map((column) => (
          <KanbanColumn
            key={column.id}
            column={column}
            features={byColumn[column.id]}
            state={state}
            votedSlugs={votedSlugs}
            onOpen={onOpen}
            onVote={onVote}
          />
        ))}
      </div>
    </div>
  );
}
