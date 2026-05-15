/**
 * /best-calorie-tracker-apps-2026
 * Mode C segment listicle — 10 apps ranked honestly.
 * Zealova: top 5. MacroFactor #1, Cronometer #2 (both conceded honestly).
 * Last verified: 2026-05-15
 *
 * Pricing sources (verified 2026-05-15):
 *   MacroFactor:    $11.99/mo · $71.99/yr (macrofactor.com/workouts/price/)
 *   Cronometer:     Free Basic · Gold ~$49.99/yr (askvora.com, 2026-05-15)
 *   MyFitnessPal:   Free · Premium $79.99/yr · Premium+ $99.99/yr (MFP facts §4C)
 *   Lose It:        Free · Premium $39.99/yr (nutriscan.app, 2026-05-15)
 *   Cal AI:         ~$30/yr (MFP-owned since March 2026, techcrunch.com)
 *   Lifesum:        Premium ~$50/yr (_ZEALOVA_FACTS.md §4C)
 *   YAZIO:          Free · Premium ~$40/yr (_ZEALOVA_FACTS.md §4C)
 *   FatSecret:      Free · Premium <$7/mo (_ZEALOVA_FACTS.md §4C)
 *   Zealova:        $7.99/mo · $59.99/yr (verified _ZEALOVA_FACTS.md §3)
 *   Hoot:           Free / paid (per prompt)
 *
 * §2G hold: MFP screenshot OCR claim removed (code found no implementation).
 */

import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import MarketingNav from '../../components/marketing/MarketingNav';
import ScrollSpyToc from '../../components/marketing/ScrollSpyToc';
import MarketingFooter from '../../components/marketing/MarketingFooter';
import { BRANDING } from '../../lib/branding';

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.55, ease: [0.25, 0.1, 0.25, 1] as const } },
};
const stagger = { visible: { transition: { staggerChildren: 0.1 } } };

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/best-calorie-tracker-apps-2026`;
const OG_IMAGE = `/screenshots/og-best-calorie-tracker.png`;

const apps = [
  {
    rank: 1,
    name: 'MacroFactor',
    tagline: 'Best adaptive macro coaching with an evidence-based algorithm',
    price: '$71.99/yr ($5.99/mo) · 7-day trial',
    bestFor: 'People frustrated that their "calorie deficit stopped working." MacroFactor\'s algorithm recalculates your targets weekly based on your actual weight trend.',
    weakest: 'No workout generation. Nutrition-only. Paid-only with no free tier.',
    verdict: 'Built by Greg Nuckols and Eric Trexler, MacroFactor is the most honest macro coaching app available. The expenditure algorithm adjusts your calorie targets based on your real-world weight data, not a static formula. It wins the adaptive-coaching category clearly.',
    highlight: false,
  },
  {
    rank: 2,
    name: 'Cronometer',
    tagline: 'Best micronutrient tracking with USDA-verified food database',
    price: 'Free Basic · Gold ~$49.99/yr',
    bestFor: 'Dietitians, clinical nutrition clients, biohackers, anyone tracking deficiencies or precise micronutrient intake.',
    weakest: 'UI is dense. Not beginner-friendly. No workout generation. Tracking 84 nutrients can feel like homework.',
    verdict: 'Cronometer tracks 84+ nutrients from USDA and NCCDB-verified databases. No other consumer app matches this depth. If micronutrient accuracy matters to your health goal, Cronometer is the honest first pick, ahead of every other app on this list.',
    highlight: false,
  },
  {
    rank: 3,
    name: 'MyFitnessPal',
    tagline: 'Best food database depth and ecosystem integrations',
    price: 'Free · Premium $79.99/yr · Premium+ $99.99/yr',
    bestFor: '280 million users, 20 million food items. Strongest database breadth and the widest integration network.',
    weakest: 'Free tier now paywalls barcode scanner. Database has user-submitted inaccuracies. Cal AI photo snap is now MFP-owned (acquired March 2026).',
    verdict: 'MFP is the default choice for first-time calorie trackers because the database covers almost everything. The paywall shift on the barcode scanner in 2026 frustrated long-term free users. For precision macro coaching, MacroFactor or Cronometer are better. For breadth, MFP is hard to beat.',
    highlight: false,
  },
  {
    rank: 4,
    name: 'Zealova',
    tagline: 'Best for people who want food photo logging plus workout generation in one app',
    price: '$59.99/yr ($5/mo) · 7-day trial',
    bestFor: 'People who are already tracking food and also follow a workout program. One subscription covers both.',
    weakest: 'MacroFactor\'s adaptive macro algorithm is better for pure nutrition coaching. Cronometer\'s micronutrient database is deeper. Android only (iOS coming soon).',
    verdict: 'Zealova is not the deepest pure calorie tracker. MacroFactor beats it on adaptive algorithms. Cronometer beats it on micronutrients. But Zealova is the only app on this list that combines food photo logging (up to 10 photos per meal, 4 analysis modes) with AI workout plan generation and a 5-agent chat coach, all at $59.99/year.',
    highlight: true,
  },
  {
    rank: 5,
    name: 'Lose It!',
    tagline: 'Best free calorie tracker for weight-loss-focused users',
    price: 'Free · Premium $39.99/yr',
    bestFor: 'People who want a free tracking experience with a clear weight-loss interface.',
    weakest: 'AI "Snap It" photo logging is Premium-only. No workout generation. 63M food items is smaller than MFP.',
    verdict: 'Lose It is one of the cheapest premium options at $39.99/year. The free tier is generous. The weight-loss UI is clean. Not a nutrition-depth tool, but solid for basic calorie tracking.',
    highlight: false,
  },
  {
    rank: 6,
    name: 'Cal AI',
    tagline: 'Best snap-and-go food photo calorie estimator',
    price: '~$30/yr (now MFP-owned, acquired March 2026)',
    bestFor: 'People who refuse to manually log and want a single-photo estimate for every meal.',
    weakest: 'MFP acquisition closed December 2025, announced March 2026. Long-term independence unclear. Photo estimates are not as precise as a full logging workflow.',
    verdict: 'Cal AI built 15 million downloads and $40M revenue on a simple premise: snap a photo, get calories. Now MFP-owned (announced 2026-03-02). The app runs independently for now but the roadmap will follow MFP\'s direction.',
    highlight: false,
  },
  {
    rank: 7,
    name: 'YAZIO',
    tagline: 'Best calorie tracker with a European-market focus',
    price: 'Free · Premium ~$40/yr',
    bestFor: 'European users, people who want fasting + calorie logging in one app.',
    weakest: 'Less known in the US market. No workout generation. AI recognition varies by food type.',
    verdict: 'YAZIO leads in European markets and combines calorie counting with fasting tracking. Reliable if MFP doesn\'t work well with your food choices. Less compelling in the US market.',
    highlight: false,
  },
  {
    rank: 8,
    name: 'Lifesum',
    tagline: 'Best recipe-driven calorie tracker for users who cook at home',
    price: 'Premium ~$50/yr',
    bestFor: 'People who follow diet plans and cook from recipes. Strong recipe library.',
    weakest: 'No workout generation. Recipe-first design is less useful for restaurant or takeout-heavy diets.',
    verdict: 'Lifesum is the strongest recipe-centric tracker. If you cook at home and want meal plans tied to your macro goals, it delivers. Less useful if you eat out frequently.',
    highlight: false,
  },
  {
    rank: 9,
    name: 'FatSecret',
    tagline: 'Best free calorie tracker with no paywalled core features',
    price: 'Free · Premium under $7/mo',
    bestFor: 'People who want the full tracking experience at no cost. Barcode scanner is free.',
    weakest: 'UI is dated. Community-driven database has accuracy gaps. Less adaptive than MacroFactor.',
    verdict: 'FatSecret is the best free pick for people who need the basics without a paywall on core features. The community recipe database is extensive. Not the choice for precise macro coaching.',
    highlight: false,
  },
  {
    rank: 10,
    name: 'Hoot',
    tagline: 'Best AI-powered insight layer on top of your existing tracking',
    price: 'Free / paid tiers',
    bestFor: 'Users who already log food and want AI commentary on patterns, trends, and suggestions.',
    weakest: 'Less established. Core tracking features are not as deep as MFP or Cronometer.',
    verdict: 'Hoot approaches nutrition tracking from an AI-insight angle. Less a raw tracker and more an analysis layer. Worth watching as the AI-nutrition category matures.',
    highlight: false,
  },
];

const FAQData = [
  {
    q: 'What is the most accurate calorie tracking app in 2026?',
    a: 'For micronutrient accuracy, Cronometer leads with 84+ nutrients from USDA and NCCDB databases. For adaptive macro coaching that adjusts based on your real weight trend, MacroFactor is the most accurate approach. For pure food database breadth, MyFitnessPal has 20 million items but user-submitted entries vary in accuracy.',
  },
  {
    q: 'Is MacroFactor worth the price?',
    a: 'MacroFactor costs $71.99/year ($5.99/mo, verified at macrofactor.com/workouts/price/ 2026-05-15). It is worth it if you are frustrated by hitting a calorie target that stopped producing results. The expenditure algorithm recalculates your targets weekly based on your actual weight trend, not a static formula. Most other apps use the same TDEE estimate indefinitely. MacroFactor does not.',
  },
  {
    q: 'Does MyFitnessPal still have a free barcode scanner?',
    a: 'As of 2026, MyFitnessPal has moved the barcode scanner behind a paywall on the free tier. Premium is $79.99/year. FatSecret and Cronometer still offer free barcode scanning on their free tiers.',
  },
  {
    q: 'What happened to Cal AI after MyFitnessPal acquired it?',
    a: 'MyFitnessPal announced the acquisition of Cal AI on March 2, 2026 (TechCrunch, published 2026-03-02). The deal closed in December 2025. Cal AI continues to run as an independent app with MFP\'s 20-million-item food database integrated. The app\'s future roadmap will follow MFP\'s direction.',
  },
  {
    q: 'Can Zealova replace MyFitnessPal?',
    a: 'Zealova is not a MyFitnessPal replacement for pure calorie tracking. MFP has 20 million food items; Zealova\'s strength is food photo logging (photograph a meal and get AI-estimated calories and macros), not database breadth. If you also do structured workouts and want AI workout generation plus food logging in one app, Zealova covers both for $59.99/year.',
  },
  {
    q: 'Which calorie tracker is best for weight loss?',
    a: 'For adaptive calorie coaching based on real weight trend data, MacroFactor is the honest pick. For basic weight-loss tracking with a clean interface, Lose It ($39.99/year) is the most affordable premium option. For free tracking without a paywall, FatSecret.',
  },
  {
    q: 'Does Zealova work on iPhone for calorie tracking?',
    a: 'Zealova is currently Android-only. iOS is in review and coming soon. For iPhone calorie tracking now, MacroFactor, Cronometer, or Lose It are all available on iOS.',
  },
  {
    q: 'Which app tracks the most micronutrients?',
    a: 'Cronometer tracks 84+ nutrients including amino acid profiles, individual fatty acids, and all major vitamins and minerals, sourced from USDA, NCCDB, and IFCT databases. No other consumer calorie tracking app matches this depth.',
  },
  {
    q: 'How does Zealova food logging work?',
    a: 'Zealova supports photo-based food logging with up to 10 photos per meal and 4 analysis modes: auto, plate, menu, and buffet. The AI extracts individual food items, estimates calories and macros per item, and auto-logs them to your diary. It works for single dishes, multi-course meals, and restaurant menus.',
  },
  {
    q: 'Is FatSecret really free?',
    a: 'FatSecret\'s core tracking features are free, including barcode scanning and manual logging. A premium subscription adds extra features but the basic daily log, food diary, and nutrient tracking stay free.',
  },
];

const jsonLdFaq = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: FAQData.map((item) => ({
    '@type': 'Question',
    name: item.q,
    acceptedAnswer: { '@type': 'Answer', text: item.a },
  })),
};

const jsonLdZealova = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'Zealova',
  operatingSystem: 'Android',
  applicationCategory: 'HealthApplication',
  description: 'AI fitness coach with food photo logging (up to 10 photos per meal, 4 analysis modes), AI workout plan generation, and 5-agent chat coach. $7.99/month or $59.99/year.',
  offers: { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', priceValidUntil: '2026-12-31' },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Best Calorie Tracker Apps 2026', item: CANONICAL_URL },
  ],
};

export default function BestCalorieTrackerApps2026() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const title = 'Best Calorie Tracker Apps 2026: 10 Apps Ranked Honestly | Zealova';
    const desc = 'Honest ranking of 10 calorie tracking apps in 2026. MacroFactor, Cronometer, MyFitnessPal, Zealova, Lose It, Cal AI, YAZIO, Lifesum, FatSecret, and Hoot compared on price, accuracy, and real-world fit.';
    document.title = title;
    const setMeta = (sel: string, attr: string, val: string) => {
      let el = document.querySelector(sel);
      if (!el) { el = document.createElement('meta'); document.head.appendChild(el); }
      el.setAttribute(attr, val);
    };
    setMeta('meta[name="description"]', 'content', desc);
    const canon = document.querySelector('link[rel="canonical"]') || (() => { const l = document.createElement('link'); l.rel = 'canonical'; document.head.appendChild(l); return l; })();
    (canon as HTMLLinkElement).href = CANONICAL_URL;
    const ogTags: Record<string, string> = {
      'og:title': title, 'og:description': desc, 'og:url': CANONICAL_URL,
      'og:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`, 'og:type': 'article',
      'twitter:card': 'summary_large_image', 'twitter:title': title, 'twitter:description': desc,
      'twitter:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
    };
    Object.entries(ogTags).forEach(([prop, content]) => {
      const isT = prop.startsWith('twitter:');
      const sel = isT ? `meta[name="${prop}"]` : `meta[property="${prop}"]`;
      let el = document.querySelector(sel);
      if (!el) { el = document.createElement('meta'); if (isT) el.setAttribute('name', prop); else el.setAttribute('property', prop); document.head.appendChild(el); }
      el.setAttribute('content', content);
    });
  }, []);

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdZealova) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdFaq) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBreadcrumb) }} />

      <div className="min-h-screen bg-zinc-950 text-zinc-100">
        <MarketingNav />
        <ScrollSpyToc />
        <main className="max-w-4xl mx-auto px-4 sm:px-6 py-16 sm:py-24">

          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Best Calorie Tracker Apps 2026</span>
          </nav>

          {/* Answer capsule */}
          <motion.section initial="hidden" animate="visible" variants={stagger} className="mb-14">
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Updated 2026-05-15 · Pricing verified per source, this run
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Best Calorie Tracker Apps 2026: 10 Apps Ranked Honestly
              </h1>
            </motion.div>

            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6">
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                For pure macro coaching, MacroFactor is the honest pick. Its algorithm recalculates your calorie and macro targets
                weekly based on your actual weight trend, not a fixed formula. Cronometer is the pick for micronutrient depth,
                tracking 84+ nutrients from USDA-verified databases. Everything else competes on price, convenience, and features.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Zealova is #4 on this list. It is not the deepest calorie tracker. But it is the only app here that combines food
                photo logging (up to 10 photos per meal, 4 analysis modes), AI workout plan generation, and a 5-agent chat coach
                in one $59.99/year subscription. The audience for Zealova on this list is people who already lift and want their
                nutrition and workouts under one roof.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                MyFitnessPal has the largest food database and the strongest integrations. But it moved the free barcode scanner
                behind a paywall in 2026, and its Cal AI acquisition (announced 2026-03-02) adds photo logging to Premium.
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">you also work out and want food logging plus workout AI in one subscription at $59.99/yr.</p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Pick MacroFactor if</p>
                  <p className="text-sm text-zinc-300">adaptive macro coaching based on your real weight data is the primary goal.</p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* Quick picks table */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">TL;DR</motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">App</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Annual price</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Best for</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {[
                    ['MacroFactor', '$71.99/yr', 'Adaptive macro coaching algorithm'],
                    ['Cronometer', '~$49.99/yr Gold', '84+ micronutrients, USDA-verified'],
                    ['MyFitnessPal', '$79.99/yr Premium', '20M food items, ecosystem integrations'],
                    ['Zealova', '$59.99/yr', 'Food photo logging + workout AI in one app'],
                    ['Lose It!', '$39.99/yr', 'Cheapest premium tracker with weight-loss UX'],
                    ['Cal AI', '~$30/yr', 'Snap-to-log food photo (MFP-owned Mar 2026)'],
                    ['YAZIO', '~$40/yr', 'European market, fasting + calorie combo'],
                    ['Lifesum', '~$50/yr', 'Recipe-driven, home cooks'],
                    ['FatSecret', '<$7/mo', 'Free barcode scanning, community DB'],
                    ['Hoot', 'Free / paid', 'AI insight layer on top of your tracking'],
                  ].map(([app, price, best]) => (
                    <tr key={app} className={`transition-colors ${app === 'Zealova' ? 'bg-emerald-950/20 hover:bg-emerald-950/30' : 'bg-zinc-950 hover:bg-zinc-900/60'}`}>
                      <td className={`px-4 py-3 font-medium ${app === 'Zealova' ? 'text-emerald-400' : 'text-zinc-200'}`}>{app}</td>
                      <td className="px-4 py-3 text-zinc-300">{price}</td>
                      <td className="px-4 py-3 text-zinc-400">{best}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">Pricing verified 2026-05-15. MacroFactor: macrofactor.com/workouts/price/. Cronometer: askvora.com. MFP: platform-listed. Zealova: internal.</p>
          </motion.section>

          {/* App cards */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-8">Full breakdown</motion.h2>
            <div className="space-y-6">
              {apps.map((app) => (
                <motion.div key={app.rank} variants={fadeUp}
                  className={`rounded-2xl border p-6 ${app.highlight ? 'bg-emerald-950/20 border-emerald-900/50' : 'bg-zinc-900 border-zinc-800'}`}>
                  <div className="flex items-start justify-between gap-4 mb-3">
                    <div>
                      <span className={`text-xs font-medium uppercase tracking-widest ${app.highlight ? 'text-emerald-400' : 'text-zinc-500'} mr-3`}>#{app.rank}</span>
                      <span className={`text-xl font-bold ${app.highlight ? 'text-emerald-400' : 'text-white'}`}>{app.name}</span>
                    </div>
                    <span className="text-sm text-zinc-400 shrink-0">{app.price}</span>
                  </div>
                  <p className="text-sm text-zinc-400 mb-3 italic">{app.tagline}</p>
                  <p className="text-sm text-zinc-200 leading-relaxed mb-4">{app.verdict}</p>
                  <div className="grid sm:grid-cols-2 gap-3 text-sm">
                    <div className="bg-zinc-800/50 rounded-lg p-3">
                      <p className="text-emerald-400 font-medium mb-1">Best for</p>
                      <p className="text-zinc-300">{app.bestFor}</p>
                    </div>
                    <div className="bg-zinc-800/50 rounded-lg p-3">
                      <p className="text-red-400 font-medium mb-1">Not ideal if</p>
                      <p className="text-zinc-300">{app.weakest}</p>
                    </div>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.section>

          {/* FAQ */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">Common questions</motion.h2>
            <div className="space-y-3">
              {FAQData.map((item, i) => (
                <motion.div key={i} variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-xl overflow-hidden">
                  <button onClick={() => setOpenFaq(openFaq === i ? null : i)}
                    className="w-full text-left px-5 py-4 flex items-center justify-between gap-4" aria-expanded={openFaq === i}>
                    <span className="text-sm font-medium text-zinc-200">{item.q}</span>
                    <span className="text-zinc-500 shrink-0 text-lg">{openFaq === i ? '−' : '+'}</span>
                  </button>
                  {openFaq === i && (
                    <div className="px-5 pb-4"><p className="text-sm text-zinc-400 leading-relaxed">{item.a}</p></div>
                  )}
                </motion.div>
              ))}
            </div>
          </motion.section>

          {/* CTA */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            className="bg-emerald-950/30 border border-emerald-900/50 rounded-2xl p-8 text-center">
            <h2 className="text-2xl font-bold text-white mb-3">Try Zealova free for 7 days</h2>
            <p className="text-zinc-400 mb-2 text-sm">
              Food photo logging with up to 10 photos per meal, AI workout plans, and a 5-agent chat coach. $59.99/yr after trial.
            </p>
            <p className="text-xs text-zinc-500 mb-6">Android only. iOS coming soon.</p>
            <a href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank" rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-black font-semibold px-8 py-3 rounded-xl transition-colors">
              Download on Android
            </a>
          </motion.section>

          <p className="text-xs text-zinc-600 mt-10 text-center">
            Last updated 2026-05-15. MacroFactor pricing: macrofactor.com/workouts/price/.
            Cronometer pricing: askvora.com (2026-05-15). MFP-Cal AI acquisition: techcrunch.com (2026-03-02).
            Zealova pricing: internal (2026-05-15).
          </p>
        </main>
        <MarketingFooter />
      </div>
    </>
  );
}
