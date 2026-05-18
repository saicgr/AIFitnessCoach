/**
 * /best-fitbit-alternatives-2026
 * Mode C segment listicle — 8 apps/platforms ranked honestly.
 * Timely angle: Fitbit app becomes Google Health on May 19, 2026.
 * Zealova: #4-5, positioned as "different segment" (software coach, no hardware required).
 * Last verified: 2026-05-15
 *
 * Pricing sources (verified 2026-05-15):
 *   Google Health:    $9.99/mo · $99/yr (9to5google.com, 2026-05-07)
 *   Garmin Connect+:  $6.99/mo · $69.99/yr (garmin.com, 2026-05-15)
 *   Apple Health:     Free (bundled with Apple Watch $249+)
 *   Strava:           $11.99/mo · $79.99/yr (_ZEALOVA_FACTS.md §4E)
 *   WHOOP 5.0:        $199-$359/yr (whoop.com, 2026-05-15)
 *   Oura Ring 4:      Ring purchase + $5.99/mo (lifestack.ai, 2026-05-15)
 *   Bevel:            $6/mo · $50/yr (_ZEALOVA_FACTS.md §4E)
 *   Zealova:          $7.99/mo · $59.99/yr (_ZEALOVA_FACTS.md §3)
 *   Polar Beat:       Free
 *
 * §2G hold: form analysis, in-workout chat all omitted as hero claims.
 * Key news: Fitbit shutdown 2026-05-19 (9to5google.com 2026-05-07)
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
const stagger = { visible: { transition: { staggerChildren: 0.1 } } };

const SECTIONS = [
  { id: 'answer', label: 'The short answer' },
  { id: 'quick-picks', label: 'TL;DR' },
  { id: 'breakdown', label: 'Full breakdown' },
  { id: 'faq', label: 'Common questions' },
  { id: 'try', label: 'Try Zealova' },
];

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/best-fitbit-alternatives-2026`;
const OG_IMAGE = `/screenshots/og-best-fitbit-alternatives.png`;

const apps = [
  {
    rank: 1,
    name: 'Google Health',
    tagline: 'The official Fitbit replacement (same data, new name)',
    type: 'Wearable ecosystem app',
    price: '$9.99/mo or $99/yr · 3-month trial for new users',
    hardware: 'Fitbit Air or Pixel Watch for full AI coach',
    bestFor: 'Existing Fitbit users. Your data migrates automatically. The app updates on May 19, 2026.',
    weakest: 'Full AI coach requires Fitbit Air or Pixel Watch. Users under 18 and unsupported regions lost Fitbit Premium with no Google Health equivalent.',
    verdict: 'Google Health is the natural path for current Fitbit users. Your data follows you. The AI Coach is powered by Gemini. If you own a compatible wearable, the transition is seamless. If you don\'t, the reduced two-tab experience at launch may feel like a downgrade.',
    isHardware: true,
    highlight: false,
  },
  {
    rank: 2,
    name: 'Garmin Connect',
    tagline: 'Best for serious athletes who want wearable data without mandatory subscription costs',
    type: 'Wearable + optional premium insights',
    price: 'Free core · Garmin Connect+ $6.99/mo or $69.99/yr',
    hardware: 'Garmin watch required',
    bestFor: 'Runners, cyclists, triathletes who want detailed performance data. Core metrics stay free.',
    weakest: 'Requires a Garmin device. Connect+ adds AI insights; core is free but limited. Garmin watches start around $199.',
    verdict: 'Garmin does not lock core health metrics behind a paywall, unlike WHOOP. Connect+ ($6.99/mo) adds AI-driven insights and custom graphs. 30-day free trial. For endurance athletes, Garmin\'s data depth beats every app-only alternative.',
    isHardware: true,
    highlight: false,
  },
  {
    rank: 3,
    name: 'WHOOP 5.0',
    tagline: 'Best for recovery-first athletes who want 24/7 strain and readiness data',
    type: 'Subscription-first wearable',
    price: '$199-$359/yr (device included)',
    hardware: 'WHOOP band (included in subscription)',
    bestFor: 'Athletes obsessed with HRV, sleep quality, and daily readiness scores.',
    weakest: 'Subscription-only, no outright purchase. Annual commitment. No screen. Takes time to learn.',
    verdict: 'WHOOP 5.0 is the category benchmark for recovery tracking. Battery life of 14 days. Three tiers: One ($199/yr), Peak ($239/yr), Life with FDA-cleared ECG ($359/yr, verified whoop.com 2026-05-15). No screen means all data is viewed in the app. Good if you want continuous strain monitoring above anything else.',
    isHardware: true,
    highlight: false,
  },
  {
    rank: 4,
    name: 'Zealova',
    tagline: 'Best software-only pick for gym users who want AI coaching without buying new hardware',
    type: 'AI coaching app (no hardware required)',
    price: '$7.99/mo or $59.99/yr · 7-day trial',
    hardware: 'None. Runs on any Android phone.',
    bestFor: 'Gym users who want AI workout plans and food photo logging and do not want to buy a new wearable.',
    weakest: 'Does not replace wearable biometrics (heart rate, HRV, sleep stages, SpO2). Android only, iOS coming soon. Not a hardware device.',
    verdict: 'Zealova is a different category from Fitbit entirely. It does not track your heart rate or sleep. It generates monthly workout plans, logs food via photo (up to 10 photos per meal), and runs a 5-agent chat coach for workouts, nutrition, injuries, and hydration. If you are leaving Fitbit because the tracking felt passive and you want an app that actively coaches you, Zealova is the pick.',
    isHardware: false,
    highlight: true,
  },
  {
    rank: 5,
    name: 'Bevel',
    tagline: 'Best AI health companion for passive tracking across sleep, exercise, nutrition, and lifestyle',
    type: 'AI health companion app',
    price: '$6/mo or $50/yr',
    hardware: 'Connects to Apple Health, Dexcom, Libre, Garmin (no proprietary hardware)',
    bestFor: 'People who want a low-effort AI health insight layer without changing their wearable.',
    weakest: 'Passive health tracking, not active workout coaching. No workout plan generation.',
    verdict: 'Bevel raised $10M Series A from General Catalyst (October 2025). 100K DAU, 80% 90-day retention. Built by ex-Dropbox CTO Aditya Agarwal and team. At $50/yr it\'s the cheapest app here. It connects to your existing wearables and provides AI health insights. Passive and holistic, not gym-focused.',
    isHardware: false,
    highlight: false,
  },
  {
    rank: 6,
    name: 'Oura Ring 4',
    tagline: 'Best for sleep tracking and recovery insights without a wrist device',
    type: 'Smart ring + app',
    price: 'Ring ($299-$349) + $5.99/mo app subscription',
    hardware: 'Oura Ring 4 required',
    bestFor: 'People who want discreet biometric tracking and the best sleep stage analysis on the market.',
    weakest: 'Ring purchase required upfront. Workout tracking is basic compared to GPS watches.',
    verdict: 'Oura tracks sleep stages, readiness, HRV, and body temperature with ring sensors. Multiple studies have validated its sleep-stage accuracy. The 2019 study by de Zambotti et al. (SLEEP journal) found Oura ring showed high agreement with polysomnography for sleep staging. Great for sleep data. Not a Fitbit replacement if step counting, GPS, or workout tracking were your primary use.',
    isHardware: true,
    highlight: false,
  },
  {
    rank: 7,
    name: 'Apple Health + Apple Watch',
    tagline: 'Best for iPhone users who want the most accurate wrist-worn health tracking',
    type: 'Wearable + native iOS app',
    price: 'Apple Health free · Apple Watch SE $249+',
    hardware: 'Apple Watch + iPhone',
    bestFor: 'iPhone users who want heart rate, ECG, fall detection, crash detection, and fitness rings in one ecosystem.',
    weakest: 'iOS-only ecosystem. Apple Watch required for health metrics. Expensive entry point.',
    verdict: 'Apple Watch is the most accurate consumer heart rate tracker tested by independent researchers. Apple Health ties together nutrition, sleep, workout, and medical data through HealthKit integrations. Zealova is not yet on iOS, so this is currently an either-or choice for iPhone users.',
    isHardware: true,
    highlight: false,
  },
  {
    rank: 8,
    name: 'Polar Beat',
    tagline: 'Best free heart rate and workout tracking app without a subscription',
    type: 'Workout logging app',
    price: 'Free (optional Polar heart rate hardware)',
    hardware: 'Optional Polar chest strap for HR; phone GPS works without',
    bestFor: 'People who want free workout logging and GPS tracking without paying for a subscription.',
    weakest: 'Free app is basic. No AI coaching. No nutrition. No adaptive programming.',
    verdict: 'Polar Beat is the free fallback. GPS tracking, basic heart rate, workout summaries. No AI, no nutrition, no workout generation. A step down from Fitbod in features but costs nothing.',
    isHardware: false,
    highlight: false,
  },
];

const FAQData = [
  {
    q: 'What happened to the Fitbit app?',
    a: 'The Fitbit app permanently became Google Health starting May 19, 2026. The update rolls out automatically between May 19 and May 26, 2026. Data migrates with the account. Social features, badges, sleep animals, snore detection, group challenges, and the Fitbit community forums were removed in the transition. Source: 9to5google.com, published 2026-05-07.',
  },
  {
    q: 'Do I need to buy a new device to use Google Health?',
    a: 'No. Google Health works with many devices via Health Connect and Google Health APIs. However, the full AI Coach experience at launch is optimized for Fitbit Air or Pixel Watch. Without a compatible wearable, you get a reduced two-tab view at launch.',
  },
  {
    q: 'Is Zealova a Fitbit replacement?',
    a: 'Not directly. Zealova is an AI workout and nutrition coach. It does not track heart rate, sleep stages, HRV, or SpO2. If you used Fitbit primarily for gym workout planning and food tracking, Zealova covers both. If you used Fitbit for continuous biometrics, step counting, and sleep tracking, you need a hardware-based alternative like Google Health, Garmin, or WHOOP.',
  },
  {
    q: 'Which Fitbit alternative is cheapest?',
    a: 'Bevel is $50/year. Polar Beat is free. Zealova is $59.99/year. Oura is $5.99/month ($71.88/year) plus a ring purchase. WHOOP starts at $199/year (device included). Garmin Connect+ is $69.99/year (requires a Garmin device purchase separate). Google Health is $99/year.',
  },
  {
    q: 'Can I migrate my Fitbit workout history to another app?',
    a: 'Google Health migrates your Fitbit data automatically. If you want to move to a different workout app, Zealova exports workouts in 10 formats (Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, Parquet) once you have logged workouts there. Fitbit does allow a data export from your account settings before the migration completes.',
  },
  {
    q: 'Which app is best for sleep tracking after Fitbit?',
    a: 'For sleep stage accuracy, Oura Ring leads, with validated agreement against polysomnography (de Zambotti et al., SLEEP 2019). WHOOP 5.0 also provides detailed sleep and HRV data. Google Health retains Fitbit\'s sleep tracking when paired with a compatible device. Zealova does not track sleep.',
  },
  {
    q: 'Does WHOOP require a new device purchase every year?',
    a: 'WHOOP 5.0 includes the device in the subscription at $199-$359/year depending on tier (verified whoop.com, 2026-05-15). You do not pay separately for the hardware. The subscription covers both device and app features.',
  },
  {
    q: 'I used Fitbit mainly to track my gym workouts. What should I switch to?',
    a: 'If your primary goal was structured strength or cardio programming, Zealova ($59.99/yr), Fitbod ($95.99/yr), or FitnessAI ($59.99-$89.99/yr) all generate AI workout plans. Zealova adds food photo logging and a chat coach. Fitbod has deeper strength progression data. None of these replace wearable step counting or sleep stages.',
  },
  {
    q: 'What is Bevel and how does it compare to Fitbit?',
    a: 'Bevel is an AI health companion that connects to Apple Health, Garmin, Dexcom, and Libre to provide insights across sleep, exercise, nutrition, and lifestyle. It costs $6/month or $50/year. It raised $10M from General Catalyst in October 2025. It does not replace Fitbit hardware but provides AI insight layers on top of your existing wearables. Source: _ZEALOVA_FACTS.md §4E.',
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
  description: 'AI workout and nutrition coach. No hardware required. Monthly workout plan generation, food photo logging with up to 10 photos per meal, 5-agent chat coach. $7.99/month or $59.99/year.',
  offers: { '@type': 'Offer', price: '7.99', priceCurrency: 'USD', priceValidUntil: '2026-12-31' },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Best Fitbit Alternatives 2026', item: CANONICAL_URL },
  ],
};

export default function BestFitbitAlternatives2026() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    const title = 'Best Fitbit Alternatives 2026: 8 Picks After the App Shutdown | Zealova';
    const desc = 'Fitbit became Google Health on May 19, 2026. Honest comparison of 8 alternatives: Google Health, Garmin, WHOOP, Oura, Bevel, Apple Health, Polar Beat, and Zealova. Hardware and software picks.';
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

      <ArticleLayout slug="best-fitbit-alternatives-2026" sections={SECTIONS}>

          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Best Fitbit Alternatives 2026</span>
          </nav>

          {/* Urgency banner */}
          <motion.div initial={{ opacity: 0, y: -8 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: 0.4 }}
            className="bg-amber-950/40 border border-amber-900/50 rounded-xl px-5 py-3 mb-10 flex items-center gap-3">
            <span className="text-amber-400 font-bold text-sm shrink-0">News</span>
            <p className="text-sm text-amber-200">
              The Fitbit app became Google Health on May 19, 2026. Your data migrated automatically.
              Social features, sleep animals, badges, and group challenges were removed.
              (Source: 9to5google.com, published 2026-05-07)
            </p>
          </motion.div>

          {/* Answer capsule */}
          <motion.section id="answer" initial="hidden" animate="visible" variants={stagger} className="mb-14 scroll-mt-24">
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Updated 2026-05-15 · Fitbit-to-Google-Health transition angle
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Best Fitbit Alternatives 2026: 8 Picks After the App Shutdown
              </h1>
            </motion.div>

            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6">
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                The Fitbit app is gone. Google Health is the replacement. For most people it is an automatic transition:
                same biometric data, same wearable, new brand and new AI coach powered by Gemini.
                It costs $9.99/month or $99/year, and the AI Coach is built around Fitbit Air and Pixel Watch.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                But if you used Fitbit mainly to track gym sessions and log food, you may find a software-only app
                covers your actual use case better. Zealova at $59.99/year generates AI workout plans, logs food via photo,
                and runs a 5-agent chat coach on any Android phone with no hardware purchase.
                It does not track heart rate or sleep.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                For biometric tracking, Google Health is the no-friction path. WHOOP leads for recovery athletes.
                Garmin leads for endurance athletes. Oura leads for sleep. Bevel leads for passive AI insight at the lowest price.
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">you used Fitbit for gym tracking and food logging and don't need heart rate or sleep data.</p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Stay with Google Health if</p>
                  <p className="text-sm text-zinc-300">you own a Fitbit or Pixel Watch and want your biometric data to follow you seamlessly.</p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* TL;DR */}
          <motion.section id="quick-picks" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">TL;DR</motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">App / platform</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Annual price</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Hardware needed</th>
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Best for</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {[
                    ['Google Health', '$99/yr', 'Fitbit / Pixel Watch', 'Existing Fitbit users'],
                    ['Garmin Connect', '$69.99/yr (Connect+)', 'Garmin watch', 'Endurance athletes'],
                    ['WHOOP 5.0', '$199-$359/yr', 'WHOOP band (included)', 'Recovery-first athletes'],
                    ['Zealova', '$59.99/yr', 'None', 'AI gym + nutrition coaching'],
                    ['Bevel', '$50/yr', 'None (uses your existing data)', 'Passive AI health insights'],
                    ['Oura Ring 4', '$71.88/yr + ring', 'Oura Ring', 'Sleep and recovery tracking'],
                    ['Apple Health', 'Free + Watch $249+', 'Apple Watch', 'iPhone users, ecosystem'],
                    ['Polar Beat', 'Free', 'Optional HR strap', 'Free workout GPS logging'],
                  ].map(([app, price, hw, best]) => (
                    <tr key={app} className={`transition-colors ${app === 'Zealova' ? 'bg-emerald-950/20 hover:bg-emerald-950/30' : 'bg-zinc-950 hover:bg-zinc-900/60'}`}>
                      <td className={`px-4 py-3 font-medium ${app === 'Zealova' ? 'text-emerald-400' : 'text-zinc-200'}`}>{app}</td>
                      <td className="px-4 py-3 text-zinc-300">{price}</td>
                      <td className="px-4 py-3 text-zinc-400">{hw}</td>
                      <td className="px-4 py-3 text-zinc-400">{best}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">
              Pricing verified 2026-05-15. Sources: 9to5google.com (Google Health), garmin.com (Garmin+),
              whoop.com (WHOOP), Zealova internal. Oura app subscription via lifestack.ai.
            </p>
          </motion.section>

          {/* App cards */}
          <motion.section id="breakdown" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-8">Full breakdown</motion.h2>
            <div className="space-y-6">
              {apps.map((app) => (
                <motion.div key={app.rank} variants={fadeUp}
                  className={`rounded-2xl border p-6 ${app.highlight ? 'bg-emerald-950/20 border-emerald-900/50' : 'bg-zinc-900 border-zinc-800'}`}>
                  <div className="flex items-start justify-between gap-4 mb-3">
                    <div className="flex items-center gap-3">
                      <span className={`text-xs font-medium uppercase tracking-widest ${app.highlight ? 'text-emerald-400' : 'text-zinc-500'}`}>#{app.rank}</span>
                      <span className={`text-xl font-bold ${app.highlight ? 'text-emerald-400' : 'text-white'}`}>{app.name}</span>
                      <span className={`text-xs px-2 py-0.5 rounded-full ${app.isHardware ? 'bg-blue-950/50 text-blue-400' : 'bg-emerald-950/50 text-emerald-400'}`}>
                        {app.isHardware ? 'Hardware' : 'Software only'}
                      </span>
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
                  <p className="text-xs text-zinc-600 mt-2">Hardware required: {app.hardware}</p>
                </motion.div>
              ))}
            </div>
          </motion.section>

          {/* FAQ */}
          <motion.section id="faq" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={stagger} className="mb-14 scroll-mt-24">
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
          <motion.section id="try" initial="hidden" whileInView="visible" viewport={{ once: true }} variants={fadeUp}
            className="bg-emerald-950/30 border border-emerald-900/50 rounded-2xl p-8 text-center scroll-mt-24">
            <h2 className="text-2xl font-bold text-white mb-3">No hardware needed. Try Zealova free.</h2>
            <p className="text-zinc-400 mb-2 text-sm">
              AI workout plans, food photo logging, and a 5-agent chat coach. Works on any Android phone.
              $7.99/mo or $59.99/yr after the 7-day trial.
            </p>
            <p className="text-xs text-zinc-500 mb-6">Android only. iOS coming soon.</p>
            <a href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              target="_blank" rel="noopener noreferrer"
              className="inline-flex items-center gap-2 bg-emerald-500 hover:bg-emerald-400 text-black font-semibold px-8 py-3 rounded-xl transition-colors">
              Download on Android
            </a>
          </motion.section>

          <p className="text-xs text-zinc-600 mt-10 text-center">
            Last updated 2026-05-15. Fitbit shutdown source: 9to5google.com (published 2026-05-07).
            Google Health pricing: store.google.com (2026-05-14). WHOOP pricing: whoop.com (2026-05-15).
            Garmin Connect+ pricing: garmin.com (2026-05-15). Sleep research: de Zambotti et al., SLEEP 2019.
          </p>
      </ArticleLayout>
    </>
  );
}
