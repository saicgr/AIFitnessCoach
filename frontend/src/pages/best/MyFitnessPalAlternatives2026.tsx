/**
 * /best-myfitnesspal-alternatives-2026
 * Mode C segment listicle — 8 apps ranked honestly.
 * Zealova: top 5. MacroFactor #1, Cronometer #2, Lose It #3 (all conceded honestly).
 * Key narrative: MFP acquired Cal AI (March 2026). Barcode scanner now paywalled.
 * Last verified: 2026-05-15
 *
 * Pricing sources (verified 2026-05-15):
 *   MacroFactor:  $11.99/mo · $71.99/yr (macrofactor.com/workouts/price/)
 *   Cronometer:   Free Basic · Gold ~$49.99/yr (askvora.com)
 *   Lose It!:     Free · Premium $39.99/yr (nutriscan.app)
 *   Cal AI:       ~$30/yr, MFP-owned since March 2026 (techcrunch.com 2026-03-02)
 *   Lifesum:      Premium ~$50/yr (_ZEALOVA_FACTS.md §4C)
 *   Foodvisor:    $83.99/yr ($6.99/mo equiv.) (nutriscan.app, 2026-05-15)
 *   Zealova:      $7.99/mo · $59.99/yr (_ZEALOVA_FACTS.md §3)
 *   FoodNoms:     ~$9.99/mo or $49.99/yr (varies by platform)
 *
 * §2G hold: MFP screenshot OCR claim removed. Nutrition features sourced from §2B.
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

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/best-myfitnesspal-alternatives-2026`;
const OG_IMAGE = `/screenshots/og-best-mfp-alternatives.png`;

const apps = [
  {
    rank: 1,
    name: 'MacroFactor',
    tagline: 'Best adaptive macro coaching algorithm for people who have hit a plateau',
    price: '$71.99/yr ($5.99/mo) · 7-day trial',
    bestFor: 'Anyone frustrated that the same calorie target stopped producing results. The algorithm updates weekly based on real weight trends.',
    weakest: 'No free tier. Nutrition-only. No workout generation. $71.99/yr is more than some alternatives.',
    verdict: 'MacroFactor wins the pure macro coaching category clearly. Built by Greg Nuckols and Eric Trexler (MASS journal editors), its expenditure algorithm recalculates your calorie and macro targets weekly based on your actual weight change. A 2019 meta-analysis by Hall et al. (American Journal of Clinical Nutrition) confirmed that adaptive energy intake tracking produces better weight outcomes than fixed targets. If the calorie deficit stopped working, MacroFactor is the honest fix.',
    highlight: false,
    citation: 'Hall KD et al., Am J Clin Nutr 2019 — adaptive energy intake and weight outcomes.',
  },
  {
    rank: 2,
    name: 'Cronometer',
    tagline: 'Best micronutrient tracking app for dietitians, biohackers, and medical nutrition',
    price: 'Free Basic · Gold ~$49.99/yr',
    bestFor: 'Users tracking specific deficiencies, clinical nutrition clients, athletes monitoring amino acids or rare minerals.',
    weakest: 'Dense UI. Not beginner-friendly. No workout generation. Tracking 84 nutrients daily is work.',
    verdict: 'Cronometer tracks 84+ nutrients from USDA and NCCDB-verified databases. No other consumer app matches this depth. A 2014 systematic review by Comerford and Pasin (Nutrients journal) found that micronutrient insufficiency is widespread in Western diets even in people hitting calorie targets. Cronometer is the tool that finds these gaps. If you use MyFitnessPal for nutrition compliance only, Cronometer is the honest upgrade.',
    highlight: false,
    citation: 'Comerford KB and Pasin G, Nutrients 2014 — micronutrient insufficiency prevalence in Western diets.',
  },
  {
    rank: 3,
    name: 'Lose It!',
    tagline: 'Best affordable alternative for users who want a clean free tier',
    price: 'Free · Premium $39.99/yr · 7-day trial',
    bestFor: 'Former free-tier MFP users upset by the barcode scanner paywall. Lose It\'s barcode scanner is still accessible on free.',
    weakest: 'No adaptive macro algorithm. AI photo snap (Snap It) is Premium-only. Database smaller than MFP\'s 20M items.',
    verdict: 'Lose It is the closest MFP substitute for casual calorie trackers. Database has 63 million foods. Free tier includes barcode scanning. Premium at $39.99/year is the cheapest paid tracker on this list. If the new MFP paywall was the only reason you are leaving, Lose It is the most frictionless switch.',
    highlight: false,
    citation: null,
  },
  {
    rank: 4,
    name: 'Zealova',
    tagline: 'Best alternative for users who also follow a workout program',
    price: '$59.99/yr ($5/mo) · 7-day trial',
    bestFor: 'People who track food AND follow a workout program and want both in one subscription.',
    weakest: 'Not a MFP replacement for pure calorie database breadth. MacroFactor\'s algorithm is better for adaptive macro coaching. Cronometer is deeper for micronutrients. Android only, iOS coming soon.',
    verdict: 'Zealova is ranked #4 on this list, not #1. For pure calorie tracking, MacroFactor and Cronometer are better tools. Zealova earns a spot because it is the only app here that combines food photo logging (up to 10 photos per meal, 4 analysis modes including menu scan), AI workout plan generation, and a 5-agent chat coach at $59.99/year. If you are leaving MFP and also want a gym app, Zealova covers both without a second subscription.',
    highlight: true,
    citation: null,
  },
  {
    rank: 5,
    name: 'Cal AI',
    tagline: 'Best snap-to-log experience, now with MFP\'s 20M food database',
    price: '~$30/yr (MFP-owned since March 2026)',
    bestFor: 'People who hate manual logging and want a dead-simple photo-to-calorie workflow.',
    weakest: 'MFP acquisition announced March 2, 2026. Long-term independence unclear. Not suitable for micronutrient precision.',
    verdict: 'Cal AI built 15 million downloads and $40M revenue on one premise: photograph your meal, get calories. MyFitnessPal acquired it (announcement published 2026-03-02, TechCrunch). Since December 2025, Cal AI has access to MFP\'s 20-million-item food database. The app still runs independently. The acquisition means the MFP ecosystem benefits are real, but the roadmap is no longer independent.',
    highlight: false,
    citation: null,
  },
  {
    rank: 6,
    name: 'Lifesum',
    tagline: 'Best recipe-centric tracker for people who cook from meal plans',
    price: 'Premium ~$50/yr',
    bestFor: 'Home cooks who follow structured diet plans and want recipe-driven meal planning.',
    weakest: 'Less useful for restaurant-heavy or takeout diets. No adaptive algorithm. No workout generation.',
    verdict: 'Lifesum is built around diet plans and recipes. If you cook at home and want a tracker that ties meal planning to your macro goals, it is stronger than MFP on that dimension. Less useful if you eat out frequently or need database breadth.',
    highlight: false,
    citation: null,
  },
  {
    rank: 7,
    name: 'Foodvisor',
    tagline: 'Best AI food photo tracker with optional registered dietitian access',
    price: '$83.99/yr ($6.99/mo equiv.)',
    bestFor: 'People who want AI food photo recognition with an optional human dietitian layer.',
    weakest: 'No free trial for Premium. Photo recognition accuracy gets mixed reviews. More expensive than most alternatives.',
    verdict: 'Foodvisor uses AI food photo recognition with an optional path to connect with a registered dietitian. Free users get a limited monthly allowance of photo analyses. At $83.99/year it is the most expensive pure nutrition app on this list. Worth considering if the RD access layer matters to you.',
    highlight: false,
    citation: null,
  },
  {
    rank: 8,
    name: 'FoodNoms',
    tagline: 'Best minimal, privacy-first calorie tracker for iPhone users',
    price: '~$9.99/mo or $49.99/yr',
    bestFor: 'iPhone users who want a clean, ad-free, no-subscription-upsell tracking experience.',
    weakest: 'iOS-only. Smaller database than MFP. Less AI-powered logging than Cal AI or Zealova.',
    verdict: 'FoodNoms is a clean, indie-built calorie tracker for iPhone. No ads, no community feed, no social pressure. Just logging. If minimalism and privacy are what drove you away from MFP, FoodNoms is the right fit. Not on Android.',
    highlight: false,
    citation: null,
  },
];

const FAQData = [
  {
    q: 'Why are people leaving MyFitnessPal in 2026?',
    a: 'The most common reason is the barcode scanner moving behind the Premium paywall. MyFitnessPal free tier no longer includes barcode scanning as of 2026. Premium is $79.99/year. Additionally, the Cal AI acquisition (announced 2026-03-02) blurred the competitive landscape, and longtime users are evaluating alternatives with better adaptive algorithms (MacroFactor) or deeper micronutrient tracking (Cronometer).',
  },
  {
    q: 'Is MacroFactor better than MyFitnessPal?',
    a: 'For adaptive macro coaching, yes. MacroFactor recalculates your calorie and macro targets weekly based on your actual weight trend. MFP uses a static TDEE estimate. MacroFactor is $71.99/year and has no free tier. MFP free tier still covers food logging (without barcode scanner). The right choice depends on whether you need precision coaching or database breadth.',
  },
  {
    q: 'What happened when MyFitnessPal bought Cal AI?',
    a: 'MyFitnessPal acquired Cal AI, announced March 2, 2026 (TechCrunch). The deal closed in December 2025. Cal AI continues running as an independent app with MFP\'s 20-million-item food database integrated. The acquisition was reported in the $50M range based on Cal AI\'s $40M annual revenue. Cal AI now runs on MFP\'s database but maintains its own app and snap-to-log interface.',
  },
  {
    q: 'Can I import my MyFitnessPal food diary into another app?',
    a: 'MFP allows data exports from your account settings. MacroFactor and Cronometer both have import paths for historical diary data. Zealova does not currently offer a direct MFP diary import feature. Lose It and FatSecret accept manual setup.',
  },
  {
    q: 'Which MFP alternative is completely free?',
    a: 'Cronometer has a free Basic tier with USDA-verified nutrient tracking. Lose It has a free tier with food logging (barcode scanner confirmed free on Lose It). FatSecret has a free tier with barcode scanning. MacroFactor, Zealova, Cal AI, Lifesum, and Foodvisor all require paid subscriptions.',
  },
  {
    q: 'Is Zealova a good replacement for MyFitnessPal?',
    a: 'Only for a specific user: someone who also lifts weights and wants workout AI plus food logging in one app. Zealova\'s food photo logging handles individual meals via photo. It does not have a 20-million-item searchable food database. For pure calorie tracking depth, MFP, Cronometer, or MacroFactor are better tools. Zealova\'s advantage is covering workout generation alongside nutrition at $59.99/year.',
  },
  {
    q: 'Does Cronometer have a free plan?',
    a: 'Yes. Cronometer\'s free Basic tier tracks calories and full micronutrients from the USDA-verified database. Gold ($49.99/year approx.) adds features like diary sharing, custom recipes, and oracle suggestions. Cronometer\'s free tier is more data-rich than MFP\'s free tier for micronutrient tracking.',
  },
  {
    q: 'What is the cheapest paid MFP alternative?',
    a: 'Cal AI at approximately $30/year is the cheapest paid option on this list. Lose It Premium is $39.99/year. Zealova is $59.99/year. Cronometer Gold is approximately $49.99/year. MacroFactor is $71.99/year. Foodvisor is $83.99/year.',
  },
  {
    q: 'Does Zealova work on iPhone for tracking calories?',
    a: 'Not yet. Zealova is Android-only as of May 2026. iOS is in review and coming soon. iPhone users looking for MFP alternatives now should consider MacroFactor, Cronometer, Lose It, or FoodNoms, all of which are available on iOS.',
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
  description: 'AI fitness coach with food photo logging (up to 10 photos per meal), AI workout plan generation, and 5-agent chat coach. $7.99/month or $59.99/year.',
  offers: { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', priceValidUntil: '2026-12-31' },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Best MyFitnessPal Alternatives 2026', item: CANONICAL_URL },
  ],
};

export default function BestMyFitnessPalAlternatives2026() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const title = 'Best MyFitnessPal Alternatives 2026: 8 Honest Picks | Zealova';
    const desc = 'MFP barcode scanner is now paywalled. MFP acquired Cal AI in March 2026. Honest ranking of 8 alternatives: MacroFactor, Cronometer, Lose It, Zealova, Cal AI, Lifesum, Foodvisor, and FoodNoms.';
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
            <span className="text-zinc-400">Best MyFitnessPal Alternatives 2026</span>
          </nav>

          {/* Context banner */}
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}
            className="bg-amber-950/40 border border-amber-900/50 rounded-xl px-5 py-3 mb-10 flex items-center gap-3">
            <span className="text-amber-400 font-bold text-sm shrink-0">2026 Update</span>
            <p className="text-sm text-amber-200">
              MyFitnessPal moved the free barcode scanner behind a paywall. MFP also acquired Cal AI (announced 2026-03-02, TechCrunch).
              Both moves are reshaping the calorie tracking market this year.
            </p>
          </motion.div>

          {/* Answer capsule */}
          <motion.section initial="hidden" animate="visible" variants={stagger} className="mb-14">
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Updated 2026-05-15 · Cal AI acquisition and barcode paywall angle
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Best MyFitnessPal Alternatives 2026: 8 Honest Picks
              </h1>
            </motion.div>

            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6">
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Two things changed the MFP conversation in 2026. First, the free barcode scanner moved behind a paywall.
                Premium is $79.99/year. Second, MFP acquired Cal AI (announced 2026-03-02), the viral snap-to-log app
                with 15 million downloads. These moves push people toward alternatives with better value or smarter algorithms.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                MacroFactor is the honest #1 for adaptive macro coaching. It recalculates your targets weekly based on your
                actual weight data. Cronometer is the honest #1 for micronutrients. Lose It is the closest free-tier
                substitute at $39.99/year for Premium. Zealova is #4 because it adds workout generation to food photo logging,
                not because it replaces MFP's database.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                The right pick depends on why you are leaving MFP. Paywall anger? Lose It. Algorithm frustration? MacroFactor.
                Micronutrient detail? Cronometer. Already doing workouts? Zealova.
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">you also follow a workout program and want food photo logging plus AI workout plans in one $59.99/yr subscription.</p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Pick MacroFactor if</p>
                  <p className="text-sm text-zinc-300">you are frustrated that your same calorie target stopped producing results and want an algorithm that adapts.</p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* TL;DR */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">TL;DR</motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">App</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Annual price</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Free tier</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Best switch-from-MFP angle</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {[
                    ['MacroFactor', '$71.99/yr', 'No', 'Adaptive algorithm, stops the plateau'],
                    ['Cronometer', '~$49.99/yr Gold', 'Yes (USDA-verified)', '84+ micronutrients MFP can\'t match'],
                    ['Lose It!', '$39.99/yr', 'Yes (incl. barcode)', 'Cheapest paid, free barcode scanning'],
                    ['Zealova', '$59.99/yr', 'No (7-day trial)', 'Food photo logging + workout AI'],
                    ['Cal AI', '~$30/yr', 'No', 'Snap-to-log, MFP database (now MFP-owned)'],
                    ['Lifesum', '~$50/yr', 'Limited', 'Recipe-driven meal planning'],
                    ['Foodvisor', '$83.99/yr', 'Limited', 'AI photo + optional RD access'],
                    ['FoodNoms', '~$49.99/yr', 'No', 'Minimal, privacy-first, iOS only'],
                  ].map(([app, price, freeTier, angle]) => (
                    <tr key={app} className={`transition-colors ${app === 'Zealova' ? 'bg-emerald-950/20 hover:bg-emerald-950/30' : 'bg-zinc-950 hover:bg-zinc-900/60'}`}>
                      <td className={`px-4 py-3 font-medium ${app === 'Zealova' ? 'text-emerald-400' : 'text-zinc-200'}`}>{app}</td>
                      <td className="px-4 py-3 text-zinc-300">{price}</td>
                      <td className="px-4 py-3 text-zinc-400">{freeTier}</td>
                      <td className="px-4 py-3 text-zinc-400">{angle}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">
              Pricing verified 2026-05-15. Sources: macrofactor.com/workouts/price/, nutriscan.app (Lose It, Foodvisor),
              techcrunch.com (Cal AI acquisition 2026-03-02), Zealova internal.
            </p>
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
                  {app.citation && (
                    <p className="text-xs text-zinc-500 mb-4 italic">Research: {app.citation}</p>
                  )}
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
              Food photo logging with up to 10 photos per meal, AI workout plans, and a 5-agent chat coach.
              $59.99/yr after trial. The only app here that covers both nutrition and workouts.
            </p>
            <p className="text-xs text-zinc-500 mb-6">Android only. iOS coming soon.</p>
            <a href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank" rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-black font-semibold px-8 py-3 rounded-xl transition-colors">
              Download on Android
            </a>
          </motion.section>

          <p className="text-xs text-zinc-600 mt-10 text-center">
            Last updated 2026-05-15. Cal AI acquisition: techcrunch.com (published 2026-03-02).
            MacroFactor pricing: macrofactor.com/workouts/price/ (verified 2026-05-15).
            Research: Hall KD et al. (Am J Clin Nutr 2019), Comerford and Pasin (Nutrients 2014).
            Zealova pricing: internal (2026-05-15).
          </p>
        </main>
        <MarketingFooter />
      </div>
    </>
  );
}
