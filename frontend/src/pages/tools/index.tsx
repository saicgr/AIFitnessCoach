// /free-tools — directory page for all Zealova free calculators + tools.
// Hero, live search, category nav, featured row, paid-elsewhere badges,
// trust signals, bottom CTA. The single highest-traffic page in /free-tools/.

import { useEffect, useMemo, useRef, useState } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../../components/marketing/MarketingNav';
import MarketingFooter from '../../components/marketing/MarketingFooter';
import { BRANDING } from '../../lib/branding';
import {
  CATEGORIES,
  CALC_REGISTRY,
  calcsByCategory,
  type CalcEntry,
  type CalcCategory,
} from '../../components/tools/calcRegistry';
import { fetchToolUsageCounts } from '../../lib/aiToolsClient';

const TITLE = 'Free Fitness Tools, Calculators, and Timers';
const META_DESC = 'A growing library of free fitness calculators, timers, and tools. 1RM, TDEE, macros, body fat, fasting timer, HIIT timer, sleep cycle, photo composer, and more. No sign-up, no paywall.';
const CANONICAL = `https://${BRANDING.marketingDomain}/free-tools`;

// Curated "marquee" picks — the highest-signal entry points for new visitors.
// Featured: AI-first ordering since those tools have the most "wow" effect
// on first visit (camera-based, instant output, viral share moment).
const FEATURED_SLUGS = [
  'ai-form-check',
  'ai-physique-analyzer',
  'ai-food-photo',
  'ai-workout-generator',
  'ai-roast-my-routine',
  '1rm-calculator',
  'fasting-timer',
];

// Recently added — show NEW badge.
const NEW_SLUGS = new Set([
  'ai-form-check',
  'ai-food-photo',
  'ai-workout-generator',
  'ai-roast-my-routine',
  'fasting-timer',
  'photo-comparison',
  'workout-rest-timer',
  'hiit-interval-timer',
  'sleep-cycle-calculator',
  'pr-celebration-card',
  'streak-certificate',
  'workout-summary-card',
  'year-in-fitness-wrapped',
  'lifter-personality-quiz',
  'workout-vibe-generator',
  'aesthetic-body-type-matcher',
  'cost-of-skipping-calculator',
  'caffeine-cutoff-calculator',
  'recipe-scaler',
  'should-i-train-today',
  'workout-buddy-compatibility',
  'marathon-plan-generator',
]);

const CATEGORY_ICONS: Record<CalcCategory, string> = {
  'ai-tools': '🤖',
  'photo-tools': '📸',
  timers: '⏱️',
  strength: '🏋️',
  powerlifting: '💪',
  'body-composition': '📊',
  nutrition: '🥗',
  cardio: '🏃',
  programming: '📅',
  programs: '🎯',
  general: '🛠️',
  lifestyle: '✨',
  wellness: '💚',
};

// Allow optional 'wellness'/'lifestyle' categories added by later agents
// without breaking the icon map.
function iconFor(cat: string): string {
  if (cat in CATEGORY_ICONS) return CATEGORY_ICONS[cat as CalcCategory];
  if (cat === 'wellness') return '💚';
  if (cat === 'lifestyle') return '✨';
  return '🛠️';
}

// A card only shows its usage count once it crosses this floor, so a
// brand-new tool never displays an embarrassingly small number.
const USAGE_DISPLAY_THRESHOLD = 100;

export default function ToolsIndex() {
  const [query, setQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');
  const [usageCounts, setUsageCounts] = useState<Record<string, number>>({});
  const resultsRef = useRef<HTMLDivElement>(null);

  // Load usage counts once. Soft-fails to an empty map (no counts render).
  useEffect(() => {
    let cancelled = false;
    fetchToolUsageCounts().then((counts) => {
      if (!cancelled) setUsageCounts(counts);
    });
    return () => {
      cancelled = true;
    };
  }, []);

  // When the user changes filters from a long-scrolled position, the right
  // column suddenly shrinks (57 tools → 3 for "Goal-Based Plans"). The
  // browser preserves scrollTop, which lands the user looking at blank
  // space below the new shorter grid. Scroll the viewport up to the top
  // of the results column so the filter feels responsive.
  useEffect(() => {
    if (!resultsRef.current) return;
    const top = resultsRef.current.getBoundingClientRect().top + window.scrollY - 80;
    if (window.scrollY > top + 40) {
      window.scrollTo({ top, behavior: 'smooth' });
    }
  }, [categoryFilter, query]);

  useEffect(() => {
    document.title = `${TITLE} | Zealova`;
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
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
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', TITLE);
    setMeta('twitter:description', META_DESC);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = CANONICAL;
  }, []);

  const totalCount = CALC_REGISTRY.length;
  const paidElsewhereCount = CALC_REGISTRY.filter((c) => c.paidElsewhere).length;

  const featured = useMemo(
    () =>
      FEATURED_SLUGS.map((slug) => CALC_REGISTRY.find((c) => c.slug === slug)).filter(
        Boolean,
      ) as CalcEntry[],
    [],
  );

  const isFiltering = query.trim().length > 0 || categoryFilter !== 'all';

  const filtered = useMemo(() => {
    if (!isFiltering) return null;
    const q = query.trim().toLowerCase();
    return CALC_REGISTRY.filter((c) => {
      const matchesCategory = categoryFilter === 'all' || c.category === categoryFilter;
      if (!matchesCategory) return false;
      if (!q) return true;
      return (
        c.name.toLowerCase().includes(q) ||
        c.description.toLowerCase().includes(q) ||
        c.keywords.some((k) => k.toLowerCase().includes(q))
      );
    });
  }, [query, categoryFilter, isFiltering]);

  // Collect all categories that appear in the registry (including any added
  // by later agents that aren't in the static CATEGORIES list).
  const allCategories = useMemo(() => {
    const seen = new Set<string>();
    const order: { key: string; name: string; description: string }[] = [];
    for (const cat of CATEGORIES) {
      seen.add(cat.key);
      order.push(cat);
    }
    for (const calc of CALC_REGISTRY) {
      if (!seen.has(calc.category)) {
        seen.add(calc.category);
        order.push({
          key: calc.category,
          name: prettyCategoryName(calc.category),
          description: '',
        });
      }
    }
    return order;
  }, []);

  const categoryCounts = useMemo(() => {
    const m: Record<string, number> = {};
    for (const c of CALC_REGISTRY) m[c.category] = (m[c.category] ?? 0) + 1;
    return m;
  }, []);

  const visibleCalcs: CalcEntry[] = useMemo(() => {
    if (filtered !== null) return filtered;
    if (categoryFilter !== 'all') {
      return CALC_REGISTRY.filter((c) => c.category === categoryFilter);
    }
    return CALC_REGISTRY;
  }, [filtered, categoryFilter]);

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <main className="max-w-7xl mx-auto px-4 sm:px-6 pt-24 sm:pt-28 pb-20">
        {/* Compact hero */}
        <header className="mb-6 text-center max-w-3xl mx-auto">
          <p className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-wider px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            Free forever · No sign-up
          </p>
          <h1 className="mt-4 text-3xl sm:text-5xl font-bold text-white tracking-tight leading-tight">
            Every fitness tool you need.{' '}
            <span className="text-emerald-400">Free.</span>
          </h1>
          <p className="mt-3 text-base text-zinc-400 leading-relaxed max-w-2xl mx-auto">
            {totalCount} calculators, timers, and AI tools. Nothing leaves your device.
            {' '}{paidElsewhereCount} cost money on competitor apps.
          </p>
        </header>

        {/* Top secondary CTA — sends users to the tools below before pitching
            the app. The download CTA is moved to the bottom of the grid,
            after they've actually used a tool. */}
        <div className="mb-8 flex items-center justify-center gap-4 text-sm">
          <a
            href="#tools-grid"
            className="inline-flex items-center gap-1.5 px-4 py-2 rounded-full bg-zinc-900 border border-zinc-800 text-zinc-300 hover:border-emerald-500/40 hover:text-emerald-400 transition font-medium"
          >
            See all {totalCount} tools <span aria-hidden>↓</span>
          </a>
          <span className="text-xs text-zinc-500">No sign-up, nothing leaves your device</span>
        </div>

        {/* Mobile search + category select (stacked, simple) */}
        <div className="lg:hidden mb-6 sticky top-0 z-10 -mx-4 px-4 pt-3 pb-3 bg-zinc-950/95 backdrop-blur-sm border-b border-zinc-800/60">
          <div className="flex flex-col gap-2">
            <div className="relative">
              <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none">🔍</span>
              <input
                type="search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder={`Search ${totalCount} tools`}
                className="w-full pl-10 pr-3 py-3 rounded-xl bg-zinc-900 border border-zinc-800 text-white placeholder-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
            </div>
            <div className="flex gap-2 overflow-x-auto -mx-1 px-1 pb-1 scrollbar-hide">
              <CategoryPill
                active={categoryFilter === 'all' && !query.trim()}
                icon="✨"
                label={`All ${totalCount}`}
                onClick={() => { setCategoryFilter('all'); setQuery(''); }}
              />
              {allCategories.map((cat) => (
                <CategoryPill
                  key={cat.key}
                  active={categoryFilter === cat.key}
                  icon={iconFor(cat.key)}
                  label={`${cat.name} · ${categoryCounts[cat.key] ?? 0}`}
                  onClick={() => setCategoryFilter(cat.key)}
                />
              ))}
            </div>
          </div>
        </div>

        {/* Desktop two-column layout */}
        <div id="tools-grid" className="lg:grid lg:grid-cols-[260px_1fr] lg:gap-8 scroll-mt-20">
          {/* Sidebar — sticky, scroll-independent of grid */}
          <aside className="hidden lg:block">
            <div className="sticky top-20 max-h-[calc(100vh-6rem)] overflow-y-auto pr-2 scrollbar-hide">
              <div className="relative mb-4">
                <span className="absolute left-3.5 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none">🔍</span>
                <input
                  type="search"
                  value={query}
                  onChange={(e) => setQuery(e.target.value)}
                  placeholder="Search tools"
                  className="w-full pl-10 pr-3 py-2.5 rounded-xl bg-zinc-900 border border-zinc-800 text-white placeholder-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
              </div>

              <button
                onClick={() => { setCategoryFilter('all'); setQuery(''); }}
                className={`w-full flex items-center justify-between text-left px-3 py-2.5 rounded-lg text-sm font-medium transition ${
                  categoryFilter === 'all' && !query.trim()
                    ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                    : 'text-zinc-300 hover:bg-zinc-900 border border-transparent'
                }`}
              >
                <span className="flex items-center gap-2">
                  <span>✨</span> All tools
                </span>
                <span className="text-xs text-zinc-500 tabular-nums">{totalCount}</span>
              </button>

              <div className="mt-1 space-y-0.5">
                {allCategories.map((cat) => {
                  const count = categoryCounts[cat.key] ?? 0;
                  if (count === 0) return null;
                  const active = categoryFilter === cat.key;
                  return (
                    <button
                      key={cat.key}
                      onClick={() => setCategoryFilter(cat.key)}
                      className={`w-full flex items-center justify-between text-left px-3 py-2 rounded-lg text-sm transition ${
                        active
                          ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/30'
                          : 'text-zinc-400 hover:bg-zinc-900 hover:text-zinc-200 border border-transparent'
                      }`}
                    >
                      <span className="flex items-center gap-2">
                        <span className="text-base">{iconFor(cat.key)}</span>
                        <span className="truncate">{cat.name}</span>
                      </span>
                      <span className="text-xs text-zinc-500 tabular-nums shrink-0 ml-2">{count}</span>
                    </button>
                  );
                })}
              </div>

              {isFiltering && (
                <button
                  onClick={() => { setQuery(''); setCategoryFilter('all'); }}
                  className="mt-3 w-full text-xs text-emerald-400 hover:text-emerald-300 underline text-left px-3"
                >
                  Clear filters
                </button>
              )}
            </div>
          </aside>

          {/* Right column — results */}
          <div ref={resultsRef} className="min-w-0 scroll-mt-20">
            {/* Results summary */}
            <div className="mb-4 flex items-center justify-between gap-3 flex-wrap">
              <p className="text-sm text-zinc-400">
                <span className="font-semibold text-white">{visibleCalcs.length}</span>{' '}
                {visibleCalcs.length === 1 ? 'tool' : 'tools'}
                {categoryFilter !== 'all' && ` in ${categoryNameFor(categoryFilter, allCategories)}`}
                {query.trim() && ` matching "${query.trim()}"`}
              </p>
              {isFiltering && (
                <button
                  type="button"
                  onClick={() => { setQuery(''); setCategoryFilter('all'); }}
                  className="text-xs text-emerald-400 hover:text-emerald-300 underline"
                >
                  Clear
                </button>
              )}
            </div>

            {/* Featured row only on "all" view */}
            {!isFiltering && (
              <section className="mb-10">
                <div className="mb-4">
                  <h2 className="text-xl sm:text-2xl font-bold text-white flex items-center gap-2 tracking-tight">
                    <span>⭐</span> Start Here: The Tools Everyone Uses First
                  </h2>
                  <p className="text-sm text-zinc-400 mt-1.5">
                    Picked by usage data. AI tools that turn a photo into a plan,
                    plus the static calculators 80% of visitors search for.
                  </p>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
                  {featured.map((c) => (
                    <CalcCard key={c.slug} calc={c} featured usageCount={usageCounts[c.slug]} />
                  ))}
                </div>
              </section>
            )}

            {/* Grid — filtered list OR all-by-category sections */}
            {isFiltering || categoryFilter !== 'all' ? (
              visibleCalcs.length === 0 ? (
                <div className="text-center py-16">
                  <p className="text-zinc-500">No tools match those filters.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
                  {visibleCalcs.map((c) => (
                    <CalcCard key={c.slug} calc={c} usageCount={usageCounts[c.slug]} />
                  ))}
                </div>
              )
            ) : (
              allCategories.map((cat) => {
                const calcs = calcsByCategory(cat.key as CalcCategory);
                if (calcs.length === 0) return null;
                return (
                  <section key={cat.key} id={`cat-${cat.key}`} className="mb-10 scroll-mt-24">
                    <div className="border-b border-zinc-800 pb-2.5 mb-4 flex items-center gap-2.5">
                      <span className="text-xl shrink-0">{iconFor(cat.key)}</span>
                      <h2 className="text-lg font-bold text-white">{cat.name}</h2>
                      <span className="ml-auto text-xs text-zinc-500 shrink-0">{calcs.length} tools</span>
                    </div>
                    <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-3">
                      {calcs.map((c) => (
                        <CalcCard key={c.slug} calc={c} usageCount={usageCounts[c.slug]} />
                      ))}
                    </div>
                  </section>
                );
              })
            )}

            {/* Trust signals */}
            <section className="mt-12 grid grid-cols-1 sm:grid-cols-3 gap-3">
              <TrustBox icon="🔒" title="100% client-side" body="Everything runs in your browser. No data is sent to a server." />
              <TrustBox icon="📚" title="Real citations" body="Every calculator cites the peer-reviewed source for its formula." />
              <TrustBox icon="💚" title="Built solo" body="Sai builds Zealova solo. These tools sustain the company, no ads." />
            </section>

            {/* Bottom install CTA — shown AFTER the tools so users have
                seen the value before they're asked to install. */}
            <section className="mt-16 rounded-3xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 via-zinc-900 to-zinc-950 p-8 sm:p-12">
              <div className="max-w-2xl">
                <p className="text-xs font-semibold uppercase tracking-wider text-emerald-400 mb-3">
                  Loved a tool? Run them on autopilot.
                </p>
                <h2 className="text-2xl sm:text-3xl font-bold text-white mb-3 tracking-tight">
                  Want every calculation applied automatically?
                </h2>
                <p className="text-zinc-400 leading-relaxed mb-5 text-sm sm:text-base">
                  Zealova runs every calculation here against your real training and food logs.
                  1RM updates after each lift. TDEE auto-adjusts to your weight trend. Macros adapt weekly.
                </p>
                <div className="flex flex-wrap gap-3 items-center">
                  <a
                    href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dindex%26utm_content%3Dbottom-cta"
                    target="_blank"
                    rel="noopener noreferrer"
                    className="inline-block px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
                  >
                    Get Zealova for Android
                  </a>
                  <span className="text-xs text-zinc-500">
                    Live on Google Play · 7-day free trial · cancel anytime
                  </span>
                </div>
              </div>
            </section>
          </div>
        </div>
      </main>

      <MarketingFooter />
    </div>
  );
}

function CategoryPill({ active, icon, label, onClick }: { active: boolean; icon: string; label: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`shrink-0 inline-flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full border transition whitespace-nowrap ${
        active
          ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/40'
          : 'bg-zinc-900 text-zinc-300 border-zinc-800 hover:border-emerald-500/40 hover:text-emerald-400'
      }`}
    >
      <span>{icon}</span>
      <span>{label}</span>
    </button>
  );
}

// ─── Sub-components ──────────────────────────────────────────────────

function CalcCard({
  calc,
  featured = false,
  usageCount,
}: {
  calc: CalcEntry;
  featured?: boolean;
  usageCount?: number;
}) {
  const isNew = NEW_SLUGS.has(calc.slug);
  const showUsage =
    typeof usageCount === 'number' && usageCount >= USAGE_DISPLAY_THRESHOLD;
  return (
    <Link
      to={`/free-tools/${calc.slug}`}
      className={`group relative block rounded-2xl border bg-zinc-900 p-5 transition hover:border-emerald-500/40 hover:bg-zinc-900/70 hover:-translate-y-0.5 ${
        featured ? 'border-emerald-500/20' : 'border-zinc-800'
      }`}
    >
      <div className="flex items-start justify-between gap-2 mb-2">
        <h3 className="font-semibold text-white text-base group-hover:text-emerald-400 transition leading-tight">
          {calc.name}
        </h3>
        <div className="flex flex-col gap-1 items-end shrink-0">
          {/* Solid-fill badges with literal text colors so they stay
              high-contrast in both light and dark mode (the zinc/white
              palette remap does not touch literal [#hex] values). */}
          {isNew && (
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-amber-400 text-[#3a2606] font-bold uppercase tracking-wide">
              New
            </span>
          )}
          {/* Every Zealova tool is free. Highlight the ones paid elsewhere
              with the bolder "Free here" pill; show a quieter "Free" pill on
              the rest so no tile reads as "maybe not free". */}
          {calc.paidElsewhere ? (
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-emerald-500 text-[#06281a] font-bold uppercase tracking-wide">
              Free here
            </span>
          ) : (
            <span className="text-[10px] px-2 py-0.5 rounded-full bg-zinc-500 text-[#ffffff] font-bold uppercase tracking-wide">
              Free
            </span>
          )}
        </div>
      </div>
      <p className="text-sm text-zinc-400 leading-relaxed">{calc.description}</p>
      {calc.competitor && (
        <p className="text-xs text-zinc-600 mt-2.5">
          Paid in: <span className="text-zinc-500">{calc.competitor}</span>
        </p>
      )}
      {showUsage && (
        <p className="text-xs text-emerald-400/80 mt-2.5 flex items-center gap-1.5">
          <span aria-hidden>🔢</span>
          <span>
            <span className="font-semibold tabular-nums">
              {usageCount!.toLocaleString()}
            </span>{' '}
            calculations run
          </span>
        </p>
      )}
    </Link>
  );
}

function TrustBox({ icon, title, body }: { icon: string; title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-zinc-800 bg-zinc-900/50 p-5">
      <p className="text-2xl mb-2">{icon}</p>
      <p className="font-semibold text-white text-sm mb-1">{title}</p>
      <p className="text-xs text-zinc-400 leading-relaxed">{body}</p>
    </div>
  );
}

function prettyCategoryName(key: string): string {
  return key
    .split('-')
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(' ');
}

function categoryNameFor(
  key: string,
  list: { key: string; name: string }[],
): string {
  return list.find((c) => c.key === key)?.name ?? prettyCategoryName(key);
}
