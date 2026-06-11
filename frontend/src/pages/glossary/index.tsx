// Glossary index: lists all 15 entries with a one-line summary each.
// SEO-targeted at "fitness glossary" / "gym terms" plus internal hub linking
// to drive crawler depth across the entry pages.

import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../../components/marketing/MarketingNav';
import MarketingFooter from '../../components/marketing/MarketingFooter';
import { BRANDING } from '../../lib/branding';

interface GlossaryEntry {
  slug: string;
  term: string;
  blurb: string;
}

const ENTRIES: GlossaryEntry[] = [
  { slug: '1rm', term: 'One-Rep Max (1RM)', blurb: 'The maximum weight you can lift for a single rep, the universal benchmark for strength programming.' },
  { slug: 'tdee', term: 'Total Daily Energy Expenditure', blurb: 'Every calorie you burn in a day. BMR plus food digestion, exercise, and daily movement.' },
  { slug: 'bmr', term: 'Basal Metabolic Rate', blurb: 'Calories your body burns at complete rest to keep organs, brain, and cells running.' },
  { slug: 'macros', term: 'Macronutrients', blurb: 'Protein, carbohydrates, and fat. The three energy-yielding nutrients that make up every calorie you eat.' },
  { slug: 'progressive-overload', term: 'Progressive Overload', blurb: 'Gradually increasing training demand over time. The single non-negotiable principle of getting stronger or bigger.' },
  { slug: 'rir-rpe', term: 'RIR and RPE', blurb: 'Reps in Reserve and Rate of Perceived Exertion. How lifters quantify set intensity without a 1RM test.' },
  { slug: 'deload', term: 'Deload', blurb: 'A planned reduction in training volume or intensity to dissipate fatigue and supercompensate.' },
  { slug: 'cut-bulk', term: 'Cutting and Bulking', blurb: 'Phases of intentional fat loss or muscle gain through controlled calorie deficits and surpluses.' },
  { slug: 'mesocycle', term: 'Mesocycle', blurb: 'A 4 to 6 week training block that ramps volume from MEV to MRV, then deloads.' },
  { slug: 'wilks-score', term: 'Wilks Score', blurb: 'A sex-adjusted bodyweight coefficient that lets powerlifters across weight classes compare totals.' },
  { slug: 'body-fat-percentage', term: 'Body Fat Percentage', blurb: 'The share of your body weight that is fat tissue, as opposed to muscle, bone, and water.' },
  { slug: 'sleep-cycles', term: 'Sleep Cycles', blurb: 'The 90-minute NREM-to-REM rotations your brain runs all night. Waking between cycles feels best.' },
  { slug: 'intermittent-fasting', term: 'Intermittent Fasting', blurb: 'Time-restricted eating protocols like 16:8 and OMAD that compress all calories into a fixed window.' },
  { slug: 'vo2-max', term: 'VO2 Max', blurb: 'The maximum volume of oxygen your body can use per minute. The gold-standard aerobic fitness marker.' },
  { slug: 'zone-2-cardio', term: 'Zone 2 Cardio', blurb: 'Conversational-pace aerobic training at 60 to 70 percent of max heart rate. Builds the mitochondrial base.' },
];

export default function GlossaryIndex() {
  const canonical = `https://${BRANDING.marketingDomain}/glossary`;
  const title = 'Fitness Glossary: Every Term Defined, Explained, and Linked';
  const description =
    'Definitions for the 15 fitness terms people actually search for. 1RM, TDEE, macros, deload, VO2 max, Zone 2, and more. Each entry funnels to a free calculator.';

  useEffect(() => {
    document.title = `${title} | Zealova`;
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
    setMeta('description', description);
    setMeta('og:title', title, true);
    setMeta('og:description', description, true);
    setMeta('og:url', canonical, true);
    setMeta('og:type', 'website', true);
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', title);
    setMeta('twitter:description', description);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = canonical;
  }, [title, description, canonical]);

  const collectionJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'DefinedTermSet',
    name: 'Zealova Fitness Glossary',
    url: canonical,
    hasDefinedTerm: ENTRIES.map((e) => ({
      '@type': 'DefinedTerm',
      name: e.term,
      description: e.blurb,
      url: `${canonical}/${e.slug}`,
    })),
  };

  const breadcrumbJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}/` },
      { '@type': 'ListItem', position: 2, name: 'Glossary', item: canonical },
    ],
  };

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(collectionJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />

      <main className="max-w-4xl mx-auto px-4 sm:px-6 pt-24 sm:pt-28 pb-20">
        <nav className="text-xs text-zinc-500 mb-6">
          <Link to="/" className="hover:text-zinc-300">Home</Link>
          <span className="mx-2">/</span>
          <span className="text-zinc-400">Glossary</span>
        </nav>

        <header className="mb-10">
          <p className="condensed-kicker text-sm text-emerald-400 mb-3">
            Fitness Glossary
          </p>
          <h1 className="display-heading text-4xl sm:text-6xl text-white mb-5">
            Every fitness term, defined plainly.
          </h1>
          <p className="text-base sm:text-lg text-zinc-400 leading-relaxed">
            Fifteen entries. Each one answers what the term means, how it is calculated, and which
            free Zealova calculator puts it to work. Citations included.
          </p>
          <div className="kinetic-rule mt-8" />
        </header>

        <div className="grid sm:grid-cols-2 gap-4">
          {ENTRIES.map((e) => (
            <Link
              key={e.slug}
              to={`/glossary/${e.slug}`}
              className="group block rounded-2xl border border-zinc-800 bg-zinc-900 p-5 hover:border-emerald-500/40 hover:bg-zinc-900/80 transition-colors"
            >
              <h2 className="text-base font-bold text-white group-hover:text-emerald-400 transition-colors mb-1">{e.term}</h2>
              <p className="text-sm text-zinc-400 leading-relaxed">{e.blurb}</p>
            </Link>
          ))}
        </div>

        <div className="mt-12 rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 to-zinc-900 p-6">
          <p className="condensed-kicker text-sm text-emerald-400 mb-2">
            Want the calculators directly?
          </p>
          <Link
            to="/free-tools"
            className="text-lg font-bold text-white hover:text-emerald-300 transition"
          >
            Browse all 40+ free Zealova tools &rarr;
          </Link>
        </div>
      </main>

      <MarketingFooter />
    </div>
  );
}
