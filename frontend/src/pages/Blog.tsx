// Content hub — /blog. Lists every long-form marketing page (app
// comparisons, best-of roundups) plus a pointer to the glossary. This is the
// "home" the comparison + roundup pages were missing.

import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

const TITLE = 'Zealova Blog: AI Fitness App Comparisons and Guides';
const META_DESC =
  'Honest, research-backed comparisons of AI fitness apps, calorie trackers, and workout generators, plus best-of roundups for 2026. Written by the Zealova team.';
const CANONICAL = `https://${BRANDING.marketingDomain}/blog`;

interface Entry {
  to: string;
  title: string;
  blurb: string;
  tag: string;
}

const ARTICLES: Entry[] = [
  {
    to: '/blog/google-health-coach-hallucination',
    title: "Google Health Coach Invented a Workout. Here's Why AI Fitness Apps Do This.",
    blurb:
      "A factual recap of the Google Health Coach hallucination incident (May 2026) and a technical explainer on why general-purpose AI fitness products fabricate workout data.",
    tag: 'Article',
  },
];

const COMPARISONS: Entry[] = [
  {
    to: '/vs/google-health',
    title: 'Zealova vs Google Health',
    blurb:
      'How a focused AI strength-and-nutrition coach compares to a general-purpose health aggregator.',
    tag: 'Comparison',
  },
];

const ROUNDUPS: Entry[] = [
  {
    to: '/best-ai-fitness-apps-2026',
    title: 'Best AI Fitness Apps in 2026',
    blurb:
      'The AI training apps worth your money this year, ranked on coaching quality, adaptivity, and price.',
    tag: 'Roundup',
  },
  {
    to: '/best-calorie-tracker-apps-2026',
    title: 'Best Calorie Tracker Apps in 2026',
    blurb:
      'From MyFitnessPal to MacroFactor to Cronometer: which calorie tracker fits which kind of eater.',
    tag: 'Roundup',
  },
  {
    to: '/best-workout-generator-apps-2026',
    title: 'Best Workout Generator Apps in 2026',
    blurb:
      'The apps that actually build you a plan, compared on personalization, progression, and equipment fit.',
    tag: 'Roundup',
  },
  {
    to: '/best-fitbit-alternatives-2026',
    title: 'Best Fitbit Alternatives in 2026',
    blurb:
      'Where to go after Fitbit, sorted by what you actually tracked it for.',
    tag: 'Roundup',
  },
  {
    to: '/best-myfitnesspal-alternatives-2026',
    title: 'Best MyFitnessPal Alternatives in 2026',
    blurb:
      'Post Cal-AI acquisition, the calorie-tracking landscape shifted. Here is where MFP users are moving.',
    tag: 'Roundup',
  },
];

function ArticleCard({ entry }: { entry: Entry }) {
  return (
    <Link
      to={entry.to}
      className="group block rounded-2xl border border-zinc-800 bg-zinc-900 p-6 transition-colors hover:border-emerald-500/40 hover:bg-zinc-900/70"
    >
      <span className="inline-block text-[10px] font-semibold uppercase tracking-wider px-2 py-0.5 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 mb-3">
        {entry.tag}
      </span>
      <h3 className="text-lg font-bold text-white group-hover:text-emerald-400 transition leading-snug">
        {entry.title}
      </h3>
      <p className="mt-2 text-sm text-zinc-400 leading-relaxed">{entry.blurb}</p>
      <span className="mt-3 inline-flex items-center gap-1 text-xs font-medium text-emerald-400">
        Read <span aria-hidden>→</span>
      </span>
    </Link>
  );
}

export default function Blog() {
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

  const itemListJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'ItemList',
    name: 'Zealova fitness app comparisons and guides',
    itemListElement: [...ARTICLES, ...COMPARISONS, ...ROUNDUPS].map((e, i) => ({
      '@type': 'ListItem',
      position: i + 1,
      name: e.title,
      url: `https://${BRANDING.marketingDomain}${e.to}`,
    })),
  };

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(itemListJsonLd) }}
      />

      <main className="max-w-5xl mx-auto px-4 sm:px-6 pt-24 sm:pt-28 pb-20">
        <header className="mb-12 max-w-2xl">
          <p className="condensed-kicker text-sm text-emerald-400">
            Zealova Blog
          </p>
          <h1 className="display-heading mt-4 text-5xl sm:text-6xl text-white">
            Honest comparisons. No affiliate spin.
          </h1>
          <p className="mt-5 text-lg text-zinc-400 leading-relaxed">
            Research-backed breakdowns of the AI fitness apps, calorie
            trackers, and workout generators worth your time. We name where
            competitors win, and where Zealova does.
          </p>
          <div className="kinetic-rule mt-8" />
        </header>

        <section className="mb-12">
          <h2 className="condensed-kicker text-base text-zinc-300 mb-5 flex items-center gap-2">
            <span>📰</span> Articles
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {ARTICLES.map((e) => (
              <ArticleCard key={e.to} entry={e} />
            ))}
          </div>
        </section>

        <section className="mb-12">
          <h2 className="condensed-kicker text-base text-zinc-300 mb-5 flex items-center gap-2">
            <span>📊</span> Best-of roundups
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {ROUNDUPS.map((e) => (
              <ArticleCard key={e.to} entry={e} />
            ))}
          </div>
        </section>

        <section className="mb-12">
          <h2 className="condensed-kicker text-base text-zinc-300 mb-5 flex items-center gap-2">
            <span>⚖️</span> App comparisons
          </h2>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {COMPARISONS.map((e) => (
              <ArticleCard key={e.to} entry={e} />
            ))}
          </div>
        </section>

        <section className="rounded-2xl border border-zinc-800 bg-zinc-900/50 p-6 sm:p-8 flex flex-col sm:flex-row sm:items-center gap-4">
          <div className="flex-1">
            <h2 className="text-lg font-bold text-white">Fitness terms, explained</h2>
            <p className="text-sm text-zinc-400 mt-1.5">
              1RM, TDEE, mesocycle, RIR, and 11 more concepts, each with a plain-English definition and the math behind it.
            </p>
          </div>
          <Link
            to="/glossary"
            className="shrink-0 inline-flex items-center justify-center px-5 py-2.5 rounded-xl bg-zinc-800 border border-zinc-700 text-white text-sm font-semibold hover:border-emerald-500/40 hover:text-emerald-400 transition"
          >
            Open the glossary
          </Link>
        </section>
      </main>

      <MarketingFooter />
    </div>
  );
}
