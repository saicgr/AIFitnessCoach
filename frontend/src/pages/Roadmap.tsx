// Public product roadmap — a live kanban board for zealova.com/roadmap.
//
// Board CONTENT is static (data/roadmap.ts) so the page prerenders for SEO.
// Vote counts + comments are dynamic: they hydrate client-side after mount
// from /api/v1/roadmap (see lib/roadmapApi.ts). Visitors vote by email and
// comment without an account.

import { useEffect, useMemo, useState } from 'react';
import { useSearchParams } from 'react-router-dom';
import { AnimatePresence } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';
import { ROADMAP_FEATURES, getFeatureBySlug, type RoadmapFeature } from '../data/roadmap';
import {
  fetchRoadmapState,
  getVotedSlugs,
  markVoted,
  type RoadmapState,
} from '../lib/roadmapApi';
import KanbanBoard from '../components/roadmap/KanbanBoard';
import VoteModal from '../components/roadmap/VoteModal';
import FeatureDrawer from '../components/roadmap/FeatureDrawer';
import SuggestFeatureModal from '../components/roadmap/SuggestFeatureModal';

const TITLE = 'Zealova Roadmap: What We Are Building Next';
const META_DESC =
  'The live Zealova product roadmap. See what is shipped, in progress, and under consideration — and vote on the features you want next.';
const CANONICAL = `https://${BRANDING.marketingDomain}/roadmap`;

export default function Roadmap() {
  const [searchParams, setSearchParams] = useSearchParams();
  const [state, setState] = useState<RoadmapState>({});
  const [votedSlugs, setVotedSlugs] = useState<Set<string>>(new Set());
  const [drawerFeature, setDrawerFeature] = useState<RoadmapFeature | null>(null);
  const [voteFeature, setVoteFeature] = useState<RoadmapFeature | null>(null);
  const [suggestOpen, setSuggestOpen] = useState(false);

  // SEO meta.
  useEffect(() => {
    document.title = `${TITLE} | Zealova`;
    const setMeta = (key: string, value: string, prop = false) => {
      const attr = prop ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    setMeta('description', META_DESC);
    setMeta('og:title', TITLE, true);
    setMeta('og:description', META_DESC, true);
    setMeta('og:url', CANONICAL, true);
    setMeta('og:type', 'website', true);
    setMeta('og:image', `https://${BRANDING.marketingDomain}/og/roadmap.png`, true);
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:image', `https://${BRANDING.marketingDomain}/og/roadmap.png`);
    setMeta('twitter:title', TITLE);
    setMeta('twitter:description', META_DESC);
    let canonical = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonical) {
      canonical = document.createElement('link');
      canonical.rel = 'canonical';
      document.head.appendChild(canonical);
    }
    canonical.href = CANONICAL;
  }, []);

  // Hydrate live counts + restore voted state + handle ?feature= deep link.
  useEffect(() => {
    setVotedSlugs(getVotedSlugs());
    fetchRoadmapState().then(setState);
    const slug = searchParams.get('feature');
    if (slug) {
      const f = getFeatureBySlug(slug);
      if (f) setDrawerFeature(f);
    }
    // Run once on mount; deep link handled here intentionally.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const openDrawer = (feature: RoadmapFeature) => {
    setDrawerFeature(feature);
    setSearchParams({ feature: feature.slug }, { replace: true });
  };
  const closeDrawer = () => {
    setDrawerFeature(null);
    searchParams.delete('feature');
    setSearchParams(searchParams, { replace: true });
  };

  const handleVoted = (slug: string, newCount: number) => {
    setState((prev) => ({
      ...prev,
      [slug]: { vote_count: newCount, comment_count: prev[slug]?.comment_count ?? 0 },
    }));
    setVotedSlugs((prev) => new Set(prev).add(slug));
    markVoted(slug);
  };

  const handleCommentAdded = (slug: string) => {
    setState((prev) => ({
      ...prev,
      [slug]: {
        vote_count: prev[slug]?.vote_count ?? 0,
        comment_count: (prev[slug]?.comment_count ?? 0) + 1,
      },
    }));
  };

  const stats = useMemo(() => {
    const shipped = ROADMAP_FEATURES.filter((f) => f.column === 'released').length;
    const inProgress = ROADMAP_FEATURES.filter((f) => f.column === 'in_progress').length;
    const openToVotes = ROADMAP_FEATURES.filter((f) => f.votable).length;
    return { shipped, inProgress, openToVotes };
  }, []);

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <main className="mx-auto max-w-[1800px] px-5 pt-28 pb-20 sm:px-8">
        {/* Header */}
        <div className="max-w-2xl">
          <h1
            className="text-[34px] font-semibold tracking-[-0.02em] sm:text-[44px]"
            style={{ fontFamily: 'var(--font-heading)' }}
          >
            Roadmap
          </h1>
          <p className="mt-3 text-[15px] leading-relaxed text-[var(--color-text-secondary)]">
            What we have shipped, what we are building, and what is up for debate. Vote on the
            ideas you want next — every vote is read, and we email you the day a feature you
            backed goes live.
          </p>
        </div>

        {/* Stat row + suggest CTA */}
        <div className="mt-6 flex flex-wrap items-center gap-x-6 gap-y-3">
          <div className="flex gap-6">
            <Stat value={stats.shipped} label="Shipped" />
            <Stat value={stats.inProgress} label="In progress" />
            <Stat value={stats.openToVotes} label="Open to votes" />
          </div>
          <button
            onClick={() => setSuggestOpen(true)}
            className="ml-auto inline-flex items-center gap-2 rounded-full bg-emerald-500 px-4 py-2 text-sm font-semibold text-white shadow-lg shadow-emerald-500/20 transition-all hover:bg-emerald-400"
          >
            <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
              <path strokeLinecap="round" strokeLinejoin="round" d="M12 4.5v15m7.5-7.5h-15" />
            </svg>
            Suggest a feature
          </button>
        </div>

        {/* Board */}
        <div className="mt-9">
          <KanbanBoard
            state={state}
            votedSlugs={votedSlugs}
            onOpen={openDrawer}
            onVote={(f) => setVoteFeature(f)}
          />
        </div>
      </main>

      <MarketingFooter />

      {/* Overlays */}
      <AnimatePresence>
        {drawerFeature && (
          <FeatureDrawer
            key="drawer"
            feature={drawerFeature}
            voteCount={state[drawerFeature.slug]?.vote_count ?? 0}
            voted={votedSlugs.has(drawerFeature.slug)}
            onClose={closeDrawer}
            onVote={(f) => setVoteFeature(f)}
            onCommentAdded={handleCommentAdded}
          />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {voteFeature && (
          <VoteModal
            key="vote"
            feature={voteFeature}
            onClose={() => setVoteFeature(null)}
            onVoted={handleVoted}
          />
        )}
      </AnimatePresence>
      <AnimatePresence>
        {suggestOpen && <SuggestFeatureModal key="suggest" onClose={() => setSuggestOpen(false)} />}
      </AnimatePresence>
    </div>
  );
}

function Stat({ value, label }: { value: number; label: string }) {
  return (
    <div>
      <div className="text-[22px] font-bold leading-none text-[var(--color-text)]">{value}</div>
      <div className="mt-1 text-[12px] font-medium text-[var(--color-text-muted)]">{label}</div>
    </div>
  );
}
