// /free-tools — directory page for all Zealova free calculators + tools.
// Hero, live search, category nav, featured row, paid-elsewhere badges,
// trust signals, bottom CTA. The single highest-traffic page in /free-tools/.

import { useEffect, useMemo, useState } from 'react';
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

const TITLE = 'Free Fitness Tools, Calculators, and Timers';
const META_DESC = 'A growing library of free fitness calculators, timers, and tools. 1RM, TDEE, macros, body fat, fasting timer, HIIT timer, sleep cycle, photo composer, and more. No sign-up, no paywall.';
const CANONICAL = `https://${BRANDING.marketingDomain}/free-tools`;

// Curated "marquee" picks — the highest-signal entry points for new visitors.
const FEATURED_SLUGS = [
  'ai-food-photo',
  'ai-workout-generator',
  'ai-roast-my-routine',
  'fasting-timer',
  '1rm-calculator',
  'photo-comparison',
];

// Recently added — show NEW badge.
const NEW_SLUGS = new Set([
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

export default function ToolsIndex() {
  const [query, setQuery] = useState('');
  const [categoryFilter, setCategoryFilter] = useState<string>('all');

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

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <main className="max-w-6xl mx-auto px-4 sm:px-6 pt-10 sm:pt-16 pb-20">
        {/* Hero */}
        <header className="mb-10 text-center max-w-3xl mx-auto">
          <p className="inline-flex items-center gap-2 text-xs font-semibold uppercase tracking-wider px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            Free forever · No sign-up
          </p>
          <h1 className="mt-5 text-4xl sm:text-6xl font-bold text-white tracking-tight leading-tight">
            Every fitness tool you need.{' '}
            <span className="text-emerald-400">Free.</span>
          </h1>
          <p className="mt-5 text-lg text-zinc-400 leading-relaxed max-w-2xl mx-auto">
            {totalCount} calculators, timers, and share-ready cards. Built by Sai, founder of Zealova.
            Nothing leaves your device. {paidElsewhereCount} of these cost money on competitor apps.
          </p>

          {/* Stat strip */}
          <div className="mt-8 flex flex-wrap items-center justify-center gap-x-8 gap-y-3 text-xs">
            <Stat label="Tools" value={String(totalCount)} />
            <Stat label="Paid elsewhere" value={String(paidElsewhereCount)} />
            <Stat label="Sign-up required" value="Zero" />
            <Stat label="Data uploaded" value="Zero" />
          </div>
        </header>

        {/* Search + category filter */}
        <div className="mb-10 sticky top-0 z-10 -mx-4 sm:mx-0 px-4 sm:px-0 pt-4 pb-4 bg-zinc-950/85 backdrop-blur-sm">
          <div className="max-w-3xl mx-auto flex flex-col sm:flex-row gap-2">
            <div className="relative flex-1">
              <span className="absolute left-4 top-1/2 -translate-y-1/2 text-zinc-500 pointer-events-none">
                🔍
              </span>
              <input
                type="search"
                value={query}
                onChange={(e) => setQuery(e.target.value)}
                placeholder={`Search ${totalCount} tools (try "1rm", "macro", "fasting")`}
                className="w-full pl-11 pr-4 py-3.5 rounded-xl bg-zinc-900 border border-zinc-800 text-white placeholder-zinc-500 text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
              />
            </div>
            <div className="relative sm:w-56">
              <select
                value={categoryFilter}
                onChange={(e) => setCategoryFilter(e.target.value)}
                className="appearance-none w-full pl-4 pr-10 py-3.5 rounded-xl bg-zinc-900 border border-zinc-800 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 cursor-pointer"
                aria-label="Filter by category"
              >
                <option value="all">All categories</option>
                {allCategories.map((cat) => (
                  <option key={cat.key} value={cat.key}>
                    {iconFor(cat.key)} {cat.name}
                  </option>
                ))}
              </select>
              <span className="pointer-events-none absolute right-4 top-1/2 -translate-y-1/2 text-zinc-500 text-xs">
                ▼
              </span>
            </div>
          </div>
          {isFiltering && (
            <div className="max-w-3xl mx-auto mt-2 flex items-center justify-between gap-3">
              <p className="text-xs text-zinc-500">
                {filtered?.length ?? 0} matching {(filtered?.length ?? 0) === 1 ? 'tool' : 'tools'}
                {categoryFilter !== 'all' && ` in ${categoryNameFor(categoryFilter, allCategories)}`}
                {query.trim() && ` for "${query.trim()}"`}
              </p>
              <button
                type="button"
                onClick={() => {
                  setQuery('');
                  setCategoryFilter('all');
                }}
                className="text-xs text-emerald-400 hover:text-emerald-300 underline"
              >
                Clear filters
              </button>
            </div>
          )}
        </div>

        {/* Search results OR category sections */}
        {filtered !== null ? (
          <SearchResults results={filtered} />
        ) : (
          <>
            {/* Featured row */}
            <section className="mb-14">
              <div className="flex items-end justify-between mb-5 gap-3 flex-wrap">
                <h2 className="text-2xl font-bold text-white flex items-center gap-2">
                  <span>⭐</span> Most useful, start here
                </h2>
                <p className="text-xs text-zinc-500">The 6 tools 80% of visitors actually need</p>
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                {featured.map((c) => (
                  <CalcCard key={c.slug} calc={c} featured />
                ))}
              </div>
            </section>

            {/* Category quick-nav */}
            <nav className="mb-10 -mx-4 sm:mx-0 px-4 sm:px-0">
              <div className="flex gap-2 overflow-x-auto pb-2 -mb-2 scrollbar-hide">
                {allCategories.map((cat) => (
                  <a
                    key={cat.key}
                    href={`#cat-${cat.key}`}
                    className="shrink-0 inline-flex items-center gap-1.5 text-xs font-medium px-3 py-1.5 rounded-full bg-zinc-900 border border-zinc-800 text-zinc-300 hover:border-emerald-500/40 hover:text-emerald-400 transition"
                  >
                    <span>{iconFor(cat.key)}</span>
                    <span>{cat.name}</span>
                  </a>
                ))}
              </div>
            </nav>

            {/* Categories */}
            {allCategories.map((cat) => {
              const calcs = calcsByCategory(cat.key as CalcCategory);
              if (calcs.length === 0) return null;
              return (
                <section key={cat.key} id={`cat-${cat.key}`} className="mb-14 scroll-mt-24">
                  <div className="border-b border-zinc-800 pb-3 mb-5 flex items-start gap-3">
                    <span className="text-2xl shrink-0 mt-0.5">{iconFor(cat.key)}</span>
                    <div>
                      <h2 className="text-xl font-bold text-white">{cat.name}</h2>
                      {cat.description && (
                        <p className="text-sm text-zinc-500 mt-0.5">{cat.description}</p>
                      )}
                    </div>
                    <span className="ml-auto text-xs text-zinc-500 shrink-0">{calcs.length} tools</span>
                  </div>
                  <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
                    {calcs.map((c) => (
                      <CalcCard key={c.slug} calc={c} />
                    ))}
                  </div>
                </section>
              );
            })}
          </>
        )}

        {/* Trust section */}
        <section className="mt-16 grid grid-cols-1 sm:grid-cols-3 gap-3 max-w-4xl mx-auto">
          <TrustBox icon="🔒" title="100% client-side" body="Everything runs in your browser. No photos, weights, or data are ever sent to a server." />
          <TrustBox icon="📚" title="Real research, real citations" body="Every calculator cites the peer-reviewed source for its formula. No vibes-based math." />
          <TrustBox icon="💚" title="Built by an indie founder" body="Sai builds Zealova solo. These tools sustain the company without ads or paywalls." />
        </section>

        {/* Bottom CTA */}
        <section className="mt-16 rounded-3xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 via-zinc-900 to-zinc-950 p-8 sm:p-12">
          <div className="max-w-2xl">
            <h2 className="text-3xl sm:text-4xl font-bold text-white mb-3 tracking-tight">
              Want every calculation applied automatically?
            </h2>
            <p className="text-zinc-400 leading-relaxed mb-6 text-base sm:text-lg">
              Zealova runs every calculation here against your real training and food logs.
              Your 1RM updates after each lift. Your TDEE auto-adjusts to your weight trend.
              Your macros adapt weekly.
            </p>
            <div className="flex flex-wrap gap-3">
              <a
                href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block px-6 py-3.5 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
              >
                Get Zealova for Android
              </a>
              <span className="self-center text-xs text-zinc-500">
                iOS coming soon · 7-day free trial · $7.99/mo or $59.99/yr
              </span>
            </div>
          </div>
        </section>
      </main>

      <MarketingFooter />
    </div>
  );
}

// ─── Sub-components ──────────────────────────────────────────────────

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-2xl font-bold text-white tabular-nums">{value}</p>
      <p className="text-zinc-500 mt-0.5 uppercase tracking-wider">{label}</p>
    </div>
  );
}

function CalcCard({ calc, featured = false }: { calc: CalcEntry; featured?: boolean }) {
  const isNew = NEW_SLUGS.has(calc.slug);
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
          {isNew && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-amber-500/15 text-amber-400 border border-amber-500/25 font-semibold uppercase tracking-wide">
              New
            </span>
          )}
          {calc.paidElsewhere && (
            <span className="text-[10px] px-1.5 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-semibold uppercase tracking-wide">
              Free here
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
    </Link>
  );
}

function SearchResults({ results }: { results: CalcEntry[] }) {
  if (results.length === 0) {
    return (
      <p className="text-center text-zinc-500 py-16">
        No tools matched. Try a different keyword.
      </p>
    );
  }
  return (
    <section className="mb-14">
      <p className="text-sm text-zinc-500 mb-4">{results.length} matches</p>
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3">
        {results.map((c) => (
          <CalcCard key={c.slug} calc={c} />
        ))}
      </div>
    </section>
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
