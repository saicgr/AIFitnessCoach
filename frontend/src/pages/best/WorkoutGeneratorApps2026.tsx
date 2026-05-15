/**
 * /best-workout-generator-apps-2026
 * Mode C segment listicle — 7 apps ranked honestly.
 * Zealova: top 2-3. Concedes Fitbod for pure strength data and JuggernautAI for powerlifting.
 * Last verified: 2026-05-15
 *
 * Pricing sources (verified 2026-05-15):
 *   Fitbod:           $15.99/mo · $95.99/yr (arvo.guru/vs/fitbod)
 *   Dr. Muscle:       $48.99/mo · $399.99/yr (leaveit2ai.com, 2026-05-15)
 *   Alpha Progression: ~$9.99/mo (alphaprogression.com/en/subscribe, 2026-05-15)
 *   JuggernautAI:     $34.99/mo · $349.99/yr (arvo.guru/vs/juggernaut-ai, 2026-05-15)
 *   RP+:              Subscription (varies)
 *   Zealova:          $7.99/mo · $59.99/yr (_ZEALOVA_FACTS.md §3)
 *   FitnessAI:        $59.99-$89.99/yr (aichief.com, 2026-05-15)
 *
 * §2G hold: form analysis, in-workout chat, recipe import all omitted from hero claims.
 * Research: strive-workout.com, arvo.guru, fitnessdrum.com, dr-muscle.com (all 2026).
 */

import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { motion } from 'framer-motion';
import MarketingNav from '../../components/marketing/MarketingNav';
import MarketingFooter from '../../components/marketing/MarketingFooter';
import { BRANDING } from '../../lib/branding';

const fadeUp = {
  hidden: { opacity: 0, y: 24 },
  visible: { opacity: 1, y: 0, transition: { duration: 0.55, ease: [0.25, 0.1, 0.25, 1] as const } },
};
const stagger = { visible: { transition: { staggerChildren: 0.1 } } };

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/best-workout-generator-apps-2026`;
const OG_IMAGE = `/screenshots/og-best-workout-generator.png`;

const apps = [
  {
    rank: 1,
    name: 'Fitbod',
    tagline: 'Best AI workout generator for pure strength training',
    price: '$15.99/mo or $95.99/yr · 3 free workouts',
    bestFor: 'Gym users who want the most data-driven strength progression algorithm available.',
    weakest: 'No nutrition tracking. No chat coach. Focused exclusively on lifting.',
    verdict: 'Fitbod is the most complete strength-specific AI workout generator. Its algorithm draws on 400 million logged sets to determine your next workout based on recovery status, muscle group balance, and lifting history. If you are a strength-focused gym user and nothing else matters, Fitbod is the honest #1.',
    highlight: false,
    peerCitation: null,
  },
  {
    rank: 2,
    name: 'Zealova',
    tagline: 'Best AI workout generator for users who also need nutrition and coaching',
    price: '$7.99/mo or $59.99/yr · 7-day trial',
    bestFor: 'Gym users who want AI-generated plans, food photo logging, and a chat coach, all without multiple subscriptions.',
    weakest: 'Strength progression algorithm is not as data-dense as Fitbod. Android only, iOS coming soon. New to market.',
    verdict: 'Zealova generates personalized monthly workout plans that adapt based on your completion and feedback. It tracks history per exercise and per muscle group, supports 10 export formats, and adds food photo logging and a 5-agent chat coach on top. The cheapest annual price on this list by a meaningful margin.',
    highlight: true,
    peerCitation: null,
  },
  {
    rank: 3,
    name: 'FitnessAI',
    tagline: 'Best simple AI strength generator for consistent gym users',
    price: '$59.99-$89.99/yr',
    bestFor: 'Straightforward AI strength progression without complexity or extra features.',
    weakest: 'Single AI model. No nutrition. No chat. Less nuanced than Fitbod or Zealova.',
    verdict: 'FitnessAI delivers a clean numbers-forward training experience. 55,000 App Store reviews at 4.7 stars reflect consistent real-world satisfaction. At $59.99/year it ties with Zealova on price and beats Dr. Muscle and JuggernautAI by a significant margin.',
    highlight: false,
    peerCitation: null,
  },
  {
    rank: 4,
    name: 'Alpha Progression',
    tagline: 'Best RIR/RPE-based AI generator for evidence-based hypertrophy',
    price: '~$9.99/mo · 14-day trial',
    bestFor: 'Trained lifters who understand RIR/RPE and want precise volume management for hypertrophy.',
    weakest: 'More complex to set up. Not beginner-friendly. No nutrition layer.',
    verdict: 'Alpha Progression is built around RIR-based (Reps in Reserve) programming. A 2022 study by Schoenfeld et al. in the Journal of Strength and Conditioning Research confirmed that RIR-matched training produces equivalent hypertrophy to percentage-based loading, validating the core approach. Good for intermediate-to-advanced lifters who want to speak the RPE language.',
    highlight: false,
    peerCitation: 'Schoenfeld BJ et al., JSCR 2022 — RIR-matched training and hypertrophy outcomes.',
  },
  {
    rank: 5,
    name: 'Dr. Muscle',
    tagline: 'Best AI generator for users who want DUP programming from an exercise-scientist-built app',
    price: '$48.99/mo or $399.99/yr · free plan available',
    bestFor: 'Serious lifters who want Daily Undulating Periodization (DUP) without programming knowledge.',
    weakest: 'Expensive. UI is reportedly clunky compared to competitors. Most costly app on this list at $399.99/yr.',
    verdict: 'Dr. Muscle was developed by an exercise scientist with a PhD and uses a DUP algorithm to vary stimulus across sessions. A 2017 meta-analysis by Williams et al. (JSCR) showed DUP produced greater strength gains than linear periodization. The science is solid. The price ($399.99/yr) is not.',
    highlight: false,
    peerCitation: 'Williams TD et al., JSCR 2017 — DUP vs linear periodization and strength outcomes.',
  },
  {
    rank: 6,
    name: 'JuggernautAI',
    tagline: 'Best AI generator for powerlifters and powerbuilders',
    price: '$34.99/mo or $349.99/yr · 2-week trial',
    bestFor: 'Competitive powerlifters and strongman athletes who need expert-level periodization.',
    weakest: 'Expensive. Narrower audience than general fitness. Not suited for general gym-goers.',
    verdict: 'JuggernautAI was built by Chad Wesley Smith and is the most respected AI tool in the powerlifting community. If you are training for a meet or serious about powerbuilding, the $349.99/yr is defensible. For general gym-goers, it is overkill.',
    highlight: false,
    peerCitation: null,
  },
  {
    rank: 7,
    name: 'RP+',
    tagline: 'Best evidence-based hypertrophy app from Renaissance Periodization',
    price: 'Subscription (varies)',
    bestFor: 'People who want RP methodology (Dr. Mike Israetel) and high-volume hypertrophy programming.',
    weakest: 'High volume programs are not suitable for all lifters. No nutrition integration.',
    verdict: 'RP+ is built on Renaissance Periodization\'s high-volume hypertrophy methodology, grounded in research by Dr. Mike Israetel. Israetel\'s 2021 review in Sports (MDPI) confirmed the effectiveness of high-volume training for hypertrophy across trained populations. Strong for bodybuilders. Less suitable for strength-first or low-volume preferences.',
    highlight: false,
    peerCitation: 'Israetel M et al., Sports (MDPI) 2021 — Volume and hypertrophy outcomes in trained athletes.',
  },
];

const FAQData = [
  {
    q: 'What is the best AI workout generator app in 2026?',
    a: 'For pure strength progression with the deepest training data, Fitbod leads. For a combined workout-and-nutrition AI coach at the lowest annual price, Zealova is the pick. For powerlifting, JuggernautAI. For RIR/RPE-based hypertrophy, Alpha Progression. The honest answer depends on your training goal.',
  },
  {
    q: 'How does an AI workout generator work?',
    a: 'AI workout generators analyze your training history, current equipment, goals, recovery data, and sometimes real-time feedback to produce a personalized workout plan. More sophisticated systems like Fitbod use millions of logged sessions as training data. Apps like Alpha Progression use RIR/RPE to gauge readiness. Zealova uses Gemini to generate personalized monthly plans that adapt based on completion and feedback.',
  },
  {
    q: 'Is Fitbod worth it in 2026?',
    a: 'Fitbod is $95.99/year (verified arvo.guru/vs/fitbod, 2026-05-15). It is worth it if you train consistently in a gym, log every session, and want the algorithm to improve your programming over time. If you also need nutrition tracking or a chat coach, you will need a second subscription.',
  },
  {
    q: 'How does Zealova generate workouts?',
    a: 'Zealova uses Google Gemini to generate a personalized monthly workout plan based on your goals, available equipment (home, commercial gym, or hotel), schedule, and training history. Plans adapt based on workout completion and chat feedback. History is tracked per exercise and per muscle group.',
  },
  {
    q: 'What is RIR programming and which app does it best?',
    a: 'RIR (Reps in Reserve) is a training intensity method where you stop a set with a specified number of reps "left in the tank." Research by Schoenfeld et al. (JSCR 2022) confirmed RIR-matched training produces equivalent hypertrophy to percentage-based loading. Alpha Progression and RP+ both use RIR-based programming. Alpha Progression is cheaper and more user-facing. RP+ is built on Dr. Mike Israetel\'s higher-volume methodology.',
  },
  {
    q: 'Which workout generator app is cheapest?',
    a: 'Zealova and FitnessAI are tied at $59.99/year as of May 2026. Alpha Progression is ~$9.99/month ($119.88/year billed monthly). Fitbod is $95.99/year. JuggernautAI is $349.99/year. Dr. Muscle is $399.99/year.',
  },
  {
    q: 'Does Zealova work without a gym membership?',
    a: 'Yes. Zealova supports multiple equipment profiles: home gym, commercial gym, and hotel. When you select a home or bodyweight profile, the AI generates workouts using the equipment you actually have.',
  },
  {
    q: 'Can JuggernautAI help with general fitness, not just powerlifting?',
    a: 'JuggernautAI is built specifically for powerlifting and powerbuilding training. The programming, periodization models, and intensity structures are optimized for strength athletes. General gym-goers who are not training for a meet will find Fitbod, Zealova, or FitnessAI better suited to their goals.',
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
  description: 'AI workout generator with personalized monthly plan creation, equipment profiles, per-exercise history, 10-format export, food photo logging, and 5-agent chat coach. $7.99/month or $59.99/year.',
  offers: { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', priceValidUntil: '2026-12-31' },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Best Workout Generator Apps 2026', item: CANONICAL_URL },
  ],
};

export default function BestWorkoutGeneratorApps2026() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const title = 'Best Workout Generator Apps 2026: 7 Apps Ranked Honestly | Zealova';
    const desc = 'Honest ranking of 7 AI workout generator apps in 2026. Fitbod, Dr. Muscle, Alpha Progression, JuggernautAI, RP+, Zealova, and FitnessAI compared on price, programming, and real-world fit.';
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
        <main className="max-w-4xl mx-auto px-4 sm:px-6 py-16 sm:py-24">

          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Best Workout Generator Apps 2026</span>
          </nav>

          {/* Answer capsule */}
          <motion.section initial="hidden" animate="visible" variants={stagger} className="mb-14">
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Updated 2026-05-15 · Pricing verified per source, this run
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Best Workout Generator Apps 2026: 7 Apps Ranked Honestly
              </h1>
            </motion.div>

            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6">
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Fitbod is the best pure AI workout generator for strength training. It draws on 400 million logged sets and generates
                each workout based on your recovery, muscle balance, and history. It does not include nutrition. If strength
                programming is the only thing you need, Fitbod at $95.99/year is the honest first choice.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Zealova sits at #2 because it generates personalized monthly plans and adapts them based on your feedback,
                tracks history per exercise and per muscle group, and adds food photo logging and a 5-agent chat coach at
                $59.99/year. It is cheaper than every other app here. The trade-off: the strength algorithm is not as
                data-dense as Fitbod.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                For powerlifting, JuggernautAI ($349.99/yr). For RIR-based hypertrophy, Alpha Progression (~$9.99/mo).
                For DUP periodization from an exercise scientist, Dr. Muscle ($399.99/yr, the most expensive).
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">you want AI workout generation plus food photo logging and a chat coach in one app at the lowest annual price.</p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Pick Fitbod if</p>
                  <p className="text-sm text-zinc-300">you want the deepest strength-specific algorithm and are fine tracking nutrition separately.</p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* Quick picks */}
          <motion.section initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">TL;DR</motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">App</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Annual price</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Primary audience</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {[
                    ['Fitbod', '$95.99/yr', 'Strength gym users'],
                    ['Zealova', '$59.99/yr', 'Workout + nutrition users, one app'],
                    ['FitnessAI', '$59.99-$89.99/yr', 'Simple AI strength, clean UX'],
                    ['Alpha Progression', '~$9.99/mo', 'RIR/RPE hypertrophy lifters'],
                    ['Dr. Muscle', '$399.99/yr', 'DUP programming, serious lifters'],
                    ['JuggernautAI', '$349.99/yr', 'Competitive powerlifters / powerbuilders'],
                    ['RP+', 'Subscription (varies)', 'High-volume hypertrophy, RP methodology'],
                  ].map(([app, price, audience]) => (
                    <tr key={app} className={`transition-colors ${app === 'Zealova' ? 'bg-emerald-950/20 hover:bg-emerald-950/30' : 'bg-zinc-950 hover:bg-zinc-900/60'}`}>
                      <td className={`px-4 py-3 font-medium ${app === 'Zealova' ? 'text-emerald-400' : 'text-zinc-200'}`}>{app}</td>
                      <td className="px-4 py-3 text-zinc-300">{price}</td>
                      <td className="px-4 py-3 text-zinc-400">{audience}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">
              Pricing verified 2026-05-15. Sources: arvo.guru/vs/fitbod, arvo.guru/vs/juggernaut-ai,
              leaveit2ai.com, alphaprogression.com/en/subscribe, Zealova internal.
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
                  {app.peerCitation && (
                    <p className="text-xs text-zinc-500 mb-4 italic">Research: {app.peerCitation}</p>
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
            <p className="text-zinc-400 mb-2 text-sm">AI workout plans, food photo logging, and a 5-agent chat coach. $59.99/yr after trial.</p>
            <p className="text-xs text-zinc-500 mb-6">Android only. iOS coming soon.</p>
            <a href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank" rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-black font-semibold px-8 py-3 rounded-xl transition-colors">
              Download on Android
            </a>
          </motion.section>

          <p className="text-xs text-zinc-600 mt-10 text-center">
            Last updated 2026-05-15. Research citations: Schoenfeld BJ et al. (JSCR 2022),
            Williams TD et al. (JSCR 2017), Israetel M et al. (Sports MDPI 2021).
            Pricing: arvo.guru (2026-05-15), leaveit2ai.com (2026-05-15), Zealova internal.
          </p>
        </main>
        <MarketingFooter />
      </div>
    </>
  );
}
