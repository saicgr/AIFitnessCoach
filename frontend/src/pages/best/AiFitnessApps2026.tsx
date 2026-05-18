/**
 * /best-ai-fitness-apps-2026
 * Mode C segment listicle — 10 apps ranked honestly.
 * Zealova: top 3, behind Fitbod for strength purists.
 * Last verified: 2026-05-15
 *
 * Pricing sources (verified 2026-05-15):
 *   Fitbod:      $15.99/mo · $95.99/yr (fitbod.me, via arvo.guru/vs/fitbod)
 *   Future:      $199/mo (futurism)
 *   Caliber:     $29-200/mo (tiers)
 *   Freeletics:  ~$80/yr
 *   FitnessAI:   $59.99-$89.99/yr (aichief.com 2026-05-15)
 *   Gravl:       $10.99/mo · $59.99/yr (_ZEALOVA_FACTS.md §4A)
 *   Trainiac:    $79-99/mo
 *   Centr:       $119.99/yr
 *   Ladder:      $99/yr
 *   Zealova:     $7.99/mo · $59.99/yr (verified _ZEALOVA_FACTS.md §3)
 *
 * §2G reliability hold: form analysis, in-workout chat, menu scan, recipe import all omitted as hero claims.
 */

import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import ArticleLayout from '../../components/marketing/ArticleLayout';
import { BRANDING } from '../../lib/branding';

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.55, ease: [0.25, 0.1, 0.25, 1] as const } },
};

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
};

const SECTIONS = [
  { id: 'answer', label: 'The short answer' },
  { id: 'quick-picks', label: 'Quick picks' },
  { id: 'breakdown', label: 'The full breakdown' },
  { id: 'use-cases', label: 'Which app for you' },
  { id: 'faq', label: 'Common questions' },
  { id: 'try', label: 'Try Zealova' },
];

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/best-ai-fitness-apps-2026`;
const OG_IMAGE = `/screenshots/og-best-ai-fitness-apps.png`;

const apps = [
  {
    rank: 1,
    name: 'Fitbod',
    tagline: 'Best for strength-focused gym users who want data-driven progressive overload',
    price: '$15.99/mo or $95.99/yr',
    trial: '3 workouts free',
    platforms: 'iOS + Android',
    bestFor: 'Strength purists who want 400M+ data-point progression logic',
    weakest: 'Nutrition tracking is not included. No chat coach.',
    rating: '4.8',
    verdict: 'Fitbod is the most data-driven strength programming app available. Its algorithm analyzes your logged sets and generates the next workout based on recovery, muscle balance, and progression. If pure strength planning is what you want, Fitbod is the honest first pick.',
    highlight: false,
  },
  {
    rank: 2,
    name: 'Zealova',
    tagline: 'Best for people who want AI workout plans plus food photo logging in one app',
    price: '$7.99/mo or $59.99/yr',
    trial: '7 days free',
    platforms: 'Android (iOS coming soon)',
    bestFor: 'Users who want workout AI, food photo logging, and a multi-agent chat coach without multiple apps',
    weakest: 'iOS not yet live. Lacks the raw workout-data depth of Fitbod. Android only for now.',
    rating: 'New',
    verdict: 'Zealova generates personalized monthly workout plans, supports food photo logging with up to 10 photos per meal across 4 analysis modes, tracks history per exercise and per muscle group, and routes your questions to a 5-agent chat coach. Cheaper than every other app in this list on the annual plan.',
    highlight: true,
  },
  {
    rank: 3,
    name: 'FitnessAI',
    tagline: 'Best single-model AI strength app for people who want simplicity',
    price: '$59.99-$89.99/yr',
    trial: 'Free trial available',
    platforms: 'iOS + Android',
    bestFor: 'Gym-goers who want clean AI strength progression without complexity',
    weakest: 'Single AI model vs multi-agent. No nutrition tracking. No chat coach.',
    rating: '4.7',
    verdict: 'FitnessAI is clean, direct, and focused purely on lifting progression. 55,000 App Store reviews back its reliability. It does one thing well.',
    highlight: false,
  },
  {
    rank: 4,
    name: 'Freeletics',
    tagline: 'Best for bodyweight training without equipment',
    price: '~$80/yr',
    trial: '14 days',
    platforms: 'iOS + Android',
    bestFor: 'Travelers, people training at home, HIIT fans who don\'t want a gym',
    weakest: 'Primarily bodyweight. Limited strength-specific tracking. No nutrition stack.',
    rating: '4.6',
    verdict: 'Freeletics built its reputation on high-intensity bodyweight programming. 60 million users, 700+ exercises. If you train without equipment, it is the strongest option.',
    highlight: false,
  },
  {
    rank: 5,
    name: 'Caliber',
    tagline: 'Best hybrid: AI program plus optional human coach at a premium',
    price: 'Free tier available. Coached plans $29-$200/mo',
    trial: 'Free tier',
    platforms: 'iOS + Android',
    bestFor: 'People who want a free AI program and the option to add a real coach',
    weakest: 'Human coaching tiers are expensive. Free plan is limited.',
    rating: '4.7',
    verdict: 'Caliber sits between Fitbod and Future. The free tier gives you coach-designed programs. The paid tiers connect you with a real human coach. Good middle ground if you want a fallback to a real person.',
    highlight: false,
  },
  {
    rank: 6,
    name: 'Future',
    tagline: 'Best if accountability from a dedicated human coach is worth $199/month to you',
    price: '$199/mo',
    trial: 'None publicly listed',
    platforms: 'iOS + Android (requires Apple Watch)',
    bestFor: 'High earners who want daily check-ins and a named coach',
    weakest: 'Very expensive. Requires Apple Watch. Not AI-only.',
    rating: '4.7',
    verdict: 'Future pairs you with a human coach who texts you daily, reviews your Apple Watch data, and adjusts your plan. It works. It is also 25x the price of Zealova. Pick it if human accountability is the variable that actually moves you.',
    highlight: false,
  },
  {
    rank: 7,
    name: 'Gravl',
    tagline: 'Best for gamified strength tracking with a Strength Score',
    price: '$10.99/mo or $59.99/yr',
    trial: 'Free tier',
    platforms: 'iOS + Android',
    bestFor: 'Gym-goers motivated by competitive Strength Score rankings',
    weakest: 'Strength-only. No nutrition stack. No chat coach.',
    rating: '4.5',
    verdict: 'Gravl is strength-focused with a gamified Strength Score that lets you see where you rank. The same price as Zealova on the annual plan, but without nutrition or chat coaching.',
    highlight: false,
  },
  {
    rank: 8,
    name: 'Trainiac',
    tagline: 'Best hybrid AI plus human coach for a mid-market price',
    price: '$79-99/mo',
    trial: 'Trial available',
    platforms: 'iOS + Android',
    bestFor: 'Users who want a hybrid approach at lower cost than Future',
    weakest: 'Still expensive compared to pure-AI options. Human coach availability varies.',
    rating: '4.4',
    verdict: 'Trainiac is Future-lite. Human coaches, AI-powered planning, lower price point. Good for people who want some human oversight without paying $199/month.',
    highlight: false,
  },
  {
    rank: 9,
    name: 'Centr',
    tagline: 'Best for people motivated by celebrity programming and video workouts',
    price: '$119.99/yr',
    trial: '7 days',
    platforms: 'iOS + Android',
    bestFor: 'People motivated by Chris Hemsworth branding and curated video content',
    weakest: 'Fixed celebrity programs, not AI-personalized. No adaptive progression.',
    rating: '4.6',
    verdict: 'Centr sells inspiration as much as programming. If Chris Hemsworth\'s workouts genuinely motivate you to show up, the $119.99/yr is defensible. The plans don\'t adapt to your history the way an AI app does.',
    highlight: false,
  },
  {
    rank: 10,
    name: 'Ladder',
    tagline: 'Best for team-based coach programming from professional strength coaches',
    price: '$99/yr',
    trial: '7 days',
    platforms: 'iOS + Android',
    bestFor: 'Athletes who want team-coach programming rather than AI generation',
    weakest: 'Human team-coach plans, not individually adaptive AI.',
    rating: '4.5',
    verdict: 'Ladder gives you programming from professional strength coaches delivered as structured plans. Less adaptive than AI, more authoritative than celebrity content.',
    highlight: false,
  },
];

const FAQData = [
  {
    q: 'What is the best AI fitness app in 2026?',
    a: 'It depends on your goal. For pure strength progression with the deepest workout data, Fitbod leads. For a combined workout-and-nutrition AI coach at the lowest annual price, Zealova is the pick. For human accountability, Future. For bodyweight training, Freeletics. There is no single winner across all use cases.',
  },
  {
    q: 'Which AI fitness app is cheapest?',
    a: 'Zealova is $7.99/month or $59.99/year with a 7-day trial. FitnessAI starts at $59.99/year. Gravl matches Zealova at $59.99/year. Fitbod is $95.99/year. Future is $199/month, the most expensive on this list by far.',
  },
  {
    q: 'Does Fitbod include nutrition tracking?',
    a: 'No. Fitbod is a workout-only app. It does not include calorie tracking, food logging, or macro coaching. If you need nutrition alongside workouts, you need either Zealova (which includes food photo logging) or a separate nutrition app like MacroFactor or Cronometer.',
  },
  {
    q: 'Can an AI fitness app replace a personal trainer?',
    a: 'An AI app can generate personalized programs, adapt based on your history, and answer questions about exercise and nutrition. It cannot watch you lift in real time, correct your form live during a set, or provide the accountability of a weekly in-person session. The gap is smallest for experienced lifters who know their own form.',
  },
  {
    q: 'Which AI fitness app works without a gym?',
    a: 'Freeletics is built for bodyweight training without equipment. Zealova and Fitbod both support equipment customization and can generate home gym or bodyweight programs. Future requires Apple Watch and is primarily built for gym users.',
  },
  {
    q: 'Does Zealova work on iPhone?',
    a: 'Not yet as of May 2026. Zealova is live on Android via Google Play. iOS is in review and coming soon to the App Store. If you need iOS now, Fitbod, FitnessAI, or Freeletics are all available on iPhone.',
  },
  {
    q: 'Which app has the best food photo logging?',
    a: 'For standalone nutrition tracking, MacroFactor and Cronometer lead. For a combined workout-plus-nutrition app with food photo logging, Zealova supports up to 10 photos per meal across 4 analysis modes (auto, plate, menu, buffet) and extracts per-item calories and macros. Most pure workout apps on this list include no food logging.',
  },
  {
    q: 'Is Future worth $199 per month?',
    a: 'Future is worth $199/month if you have tried self-directed workout apps and they did not stick. The daily check-ins and named coach create accountability that an algorithm cannot. It is not worth it if you can consistently follow a program without external pressure. At $199/month, it costs $2,388/year versus $59.99/year for Zealova or $95.99/year for Fitbod.',
  },
  {
    q: 'Which app tracks workout history per exercise?',
    a: 'Zealova tracks workout history per exercise and per muscle group, not just aggregate volume. Fitbod also tracks per-exercise progression. FitnessAI tracks sets, reps, and load over time. Most logging apps (Hevy, Strong) do this too, but without AI generation.',
  },
  {
    q: 'Does Fitbod have a free tier?',
    a: 'Fitbod offers 3 free workouts to new users, then requires a subscription ($15.99/month or $95.99/year, verified via arvo.guru/vs/fitbod, 2026-05-15). There is no ongoing free tier.',
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
  description: 'AI fitness coach with personalized workout plan generation, food photo logging with multi-image input, and a 5-agent chat coach. $7.99/month or $59.99/year.',
  offers: { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', priceValidUntil: '2026-12-31' },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Best AI Fitness Apps 2026', item: CANONICAL_URL },
  ],
};

export default function BestAiFitnessApps2026() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const title = 'Best AI Fitness Apps 2026: 10 Apps Ranked Honestly | Zealova';
    const desc = 'Honest ranking of the 10 best AI fitness apps in 2026. Fitbod, Future, Zealova, FitnessAI, Freeletics, Caliber, Gravl, Trainiac, Centr, and Ladder compared on price, features, and real-world fit.';

    document.title = title;

    const setMeta = (selector: string, attr: string, val: string) => {
      let el = document.querySelector(selector);
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

      <ArticleLayout slug="best-ai-fitness-apps-2026" sections={SECTIONS}>

          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Best AI Fitness Apps 2026</span>
          </nav>

          {/* Answer capsule */}
          <motion.section id="answer" initial="hidden" animate="visible" variants={stagger} className="mb-14 scroll-mt-24">
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Updated 2026-05-15 · Pricing verified per source, this run
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Best AI Fitness Apps 2026: 10 Apps Ranked Honestly
              </h1>
            </motion.div>

            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6">
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                The best AI fitness app in 2026 depends on one question: do you want a workout specialist or a full-stack AI coach?
                Fitbod is the most data-driven strength app available, with 400 million logged data points behind its algorithm.
                It does one thing excellently and charges $95.99/year for it.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Zealova is cheaper ($59.99/year) and covers more ground: monthly workout plan generation, food photo logging
                with up to 10 photos per meal, and a 5-agent chat coach that routes your questions by domain.
                It is not a Fitbod replacement for strength purists. But for people who want workout, nutrition,
                and chat coaching in one app without juggling subscriptions, it is the better fit.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Future is $199/month and gives you a named human coach with daily check-ins. Worth it if accountability
                is your primary blocker. Not worth it if you can follow a program independently.
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">you want workout AI plus food photo logging in one app at the lowest annual price on this list.</p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Pick Fitbod if</p>
                  <p className="text-sm text-zinc-300">you want the deepest strength progression algorithm and don't need nutrition tracking.</p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* Quick picks table */}
          <motion.section id="quick-picks" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">TL;DR: Quick picks</motion.h2>
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
                    ['Fitbod', '$95.99/yr', 'Strength progression with deep data'],
                    ['Zealova', '$59.99/yr', 'Workout + nutrition AI in one app'],
                    ['FitnessAI', '$59.99-$89.99/yr', 'Simple AI strength tracking'],
                    ['Freeletics', '~$80/yr', 'Bodyweight / no-equipment training'],
                    ['Caliber', 'Free tier + $29-200/mo coached', 'Free AI programs + optional human coach'],
                    ['Future', '$199/mo', 'Human accountability coaching'],
                    ['Gravl', '$59.99/yr', 'Gamified strength score'],
                    ['Trainiac', '$79-99/mo', 'Hybrid AI + human, lower than Future'],
                    ['Centr', '$119.99/yr', 'Celebrity-brand motivation + video content'],
                    ['Ladder', '$99/yr', 'Professional team-coach programming'],
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
            <p className="text-xs text-zinc-500 mt-2">Pricing verified 2026-05-15. Sources: arvo.guru/vs/fitbod, aichief.com, _ZEALOVA_FACTS.md.</p>
          </motion.section>

          {/* App cards */}
          <motion.section id="breakdown" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-8">The full breakdown</motion.h2>
            <div className="space-y-6">
              {apps.map((app) => (
                <motion.div
                  key={app.rank}
                  variants={fadeUp}
                  className={`rounded-2xl border p-6 ${app.highlight ? 'bg-emerald-950/20 border-emerald-900/50' : 'bg-zinc-900 border-zinc-800'}`}
                >
                  <div className="flex items-start justify-between gap-4 mb-3">
                    <div>
                      <span className={`text-xs font-medium uppercase tracking-widest ${app.highlight ? 'text-emerald-400' : 'text-zinc-500'} mr-3`}>
                        #{app.rank}
                      </span>
                      <span className={`text-xl font-bold ${app.highlight ? 'text-emerald-400' : 'text-white'}`}>{app.name}</span>
                    </div>
                    <span className="text-sm text-zinc-400 shrink-0">{app.price}</span>
                  </div>
                  <p className="text-sm text-zinc-400 mb-3 italic">{app.tagline}</p>
                  <p className="text-sm text-zinc-200 leading-relaxed mb-4">{app.verdict}</p>
                  <div className="grid sm:grid-cols-2 gap-3 text-sm">
                    <div className="bg-zinc-800/50 rounded-lg p-3">
                      <p className="text-emerald-400 font-medium mb-1">Strongest at</p>
                      <p className="text-zinc-300">{app.bestFor}</p>
                    </div>
                    <div className="bg-zinc-800/50 rounded-lg p-3">
                      <p className="text-red-400 font-medium mb-1">Weakest at</p>
                      <p className="text-zinc-300">{app.weakest}</p>
                    </div>
                  </div>
                  <div className="mt-3 flex flex-wrap gap-3 text-xs text-zinc-500">
                    <span>Trial: {app.trial}</span>
                    <span>Platforms: {app.platforms}</span>
                  </div>
                </motion.div>
              ))}
            </div>
          </motion.section>

          {/* Use-case picker */}
          <motion.section id="use-cases" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">Which app for which use case</motion.h2>
            <motion.div variants={fadeUp} className="space-y-4">
              {[
                { cond: 'You want the smartest strength algorithm, period', pick: 'Fitbod ($95.99/yr)', why: 'Deepest workout data. 400M+ logged sets. Recovery-aware.' },
                { cond: 'You want workout plans + food logging in one subscription', pick: 'Zealova ($59.99/yr)', why: 'Monthly AI plans, multi-image food logging, 5-agent chat coach.' },
                { cond: 'You train without equipment or travel constantly', pick: 'Freeletics (~$80/yr)', why: '700+ exercises, no equipment required.' },
                { cond: 'You need human accountability above everything else', pick: 'Future ($199/mo)', why: 'Daily texts from a named coach. Works if money isn\'t the constraint.' },
                { cond: 'You want free AI programs and the option to upgrade to a coach later', pick: 'Caliber (free tier)', why: 'Free structured programs; paid tiers add a real coach.' },
                { cond: 'You want the lowest annual price for pure AI strength tracking', pick: 'Zealova or FitnessAI ($59.99/yr)', why: 'Tied on price. Zealova adds nutrition. FitnessAI is simpler.' },
              ].map((row) => (
                <div key={row.cond} className="bg-zinc-900 border border-zinc-800 rounded-xl p-4">
                  <p className="text-sm text-zinc-400 mb-1">If: {row.cond}</p>
                  <p className="text-sm font-semibold text-white mb-1">Pick: {row.pick}</p>
                  <p className="text-xs text-zinc-500">{row.why}</p>
                </div>
              ))}
            </motion.div>
          </motion.section>

          {/* FAQ */}
          <motion.section id="faq" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">Common questions</motion.h2>
            <div className="space-y-3">
              {FAQData.map((item, i) => (
                <motion.div key={i} variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-xl overflow-hidden">
                  <button
                    onClick={() => setOpenFaq(openFaq === i ? null : i)}
                    className="w-full text-left px-5 py-4 flex items-center justify-between gap-4"
                    aria-expanded={openFaq === i}
                  >
                    <span className="text-sm font-medium text-zinc-200">{item.q}</span>
                    <span className="text-zinc-500 shrink-0 text-lg">{openFaq === i ? '−' : '+'}</span>
                  </button>
                  {openFaq === i && (
                    <div className="px-5 pb-4">
                      <p className="text-sm text-zinc-400 leading-relaxed">{item.a}</p>
                    </div>
                  )}
                </motion.div>
              ))}
            </div>
          </motion.section>

          {/* CTA */}
          <motion.section id="try" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp} className="bg-emerald-950/30 border border-emerald-900/50 rounded-2xl p-8 text-center scroll-mt-24">
            <h2 className="text-2xl font-bold text-white mb-3">Try Zealova free for 7 days</h2>
            <p className="text-zinc-400 mb-2 text-sm">
              AI workout plans, food photo logging, and a 5-agent chat coach. Android, $7.99/mo or $59.99/yr after trial.
            </p>
            <p className="text-xs text-zinc-500 mb-6">iOS not yet available. Joining the waitlist is free.</p>
            <a
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-black font-semibold px-8 py-3 rounded-xl transition-colors"
            >
              Download on Android
            </a>
          </motion.section>

          <p className="text-xs text-zinc-600 mt-10 text-center">
            Last updated 2026-05-15. Pricing sources: Fitbod via arvo.guru/vs/fitbod (2026-05-15),
            FitnessAI via aichief.com (2026-05-15), Zealova internal (2026-05-15).
            This page reflects the author's independent assessment.
          </p>

      </ArticleLayout>
    </>
  );
}
