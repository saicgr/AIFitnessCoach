/**
 * /vs/bevel -- Zealova vs Bevel comparison page
 * v3 -- 2026-05-21 (refresh: rating count updated to 9,500+; 3.0.5 patch notes added to Bevel wins;
 *        training-plan framing shifted to all-three-wedge positioning; last-updated dates refreshed;
 *        confirmed training plans remain cardio-only via gadgetsandwearables + feedback.bevel.health)
 * v2 -- 2026-05-20 (updated: Bevel 3.0.5 release, training plan accuracy, pricing section, free-tier corrections)
 * v1 -- 2026-05-17
 *
 * Research done live 2026-05-21:
 *  - Bevel 3.0 shipped 2026-05-16 (gadgetsandwearables.com/2026/05/16/bevel-3/)
 *  - Bevel 3.0.5 released 2026-05-20 (App Store verified 2026-05-21 -- "released 1 day ago")
 *  - 3.0.5 adds: "This Week's Changes" for Biological Age, enhanced Health Records (doc preview/edit/delete),
 *    improved Bevel Intelligence image rendering + selectable code blocks, faster Journal loading
 *  - Bevel Pro pricing confirmed: $14.99/mo or $99.99/yr (App Store, verified 2026-05-21)
 *  - Bevel App Store rating: 4.8/5 (9,500+ ratings / 9.5K shown), version 3.0.5 (verified 2026-05-21)
 *  - Training plans confirmed cardio-only (10K, half marathon) per gadgetsandwearables.com and
 *    feedback.bevel.health/feature-requests/p/cardio-training-plans-marathons-triathlons-etc
 *    (staff reply April 27, 2026: "Available in Bevel 3.0")
 *  - Strength AI plan adjustments still "planned (tbd)" per feedback.bevel.health (no update since Nov 2024)
 *  - Bevel is iOS-only — no Android app (feedback.bevel.health/feature-requests/p/android-version)
 *  - Bevel 3.0 adds: Biological Age, Health Records vault, rebuilt Intelligence coaching layer,
 *    training plan generation (goal-based, cardio-oriented: 10K/half marathon per gadgetsandwearables.com)
 *  - CORRECTION 2026-05-20: Biological Age and Health Records are in the FREE tier (App Store listing
 *    confirmed free tier includes both). Only Bevel Intelligence AI coaching is behind the Pro paywall.
 *  - CORRECTION 2026-05-20: AI strength plan adjustments (RIR, auto weight recommendations) are still
 *    "planned (tbd)" per feedback.bevel.health/feature-requests/p/strength-trainer-available-weights-rir-automatic-adjustments
 *    (staff reply Nov 2024, no ship date). Not confirmed shipped in 3.0.
 *  - Bevel wearable integrations: Apple Watch, Apple Health, Dexcom, Libre CGMs, Garmin via Health
 *  - Bevel raised $10M Series A from General Catalyst (October 2025)
 *  - Founders: ex-Dropbox CTO Aditya Agarwal, ex-Campus product lead Grey Nguyen, ex-Opendoor ML Ben Yang
 *
 * §2G reliability hold — features NOT claimed on this page:
 *   - Form video analysis (not user-validated)
 *   - In-workout mid-session AI chat (not implemented)
 *   - Recipe import (not user-validated)
 *   - MFP screenshot OCR (implementation not confirmed)
 *   - Audio coach daily brief (not user-validated)
 *   - Skill progressions (not user-validated)
 *   - Multi-execution UI tiers (only Easy tier exists)
 *
 * Asset manifest (2026-05-17):
 * -------------------------------------------------------------------------
 * Slot              | Status            | Path
 * -------------------------------------------------------------------------
 * hero_og           | NEEDS NEW         | /screenshots/og-bevel-vs.png  (1200x630)
 * answer_capsule    | use intro_phone_1 | /screenshots/intro_phone_1.png (1080x2400)
 * food_logging      | use intro_phone_2 | /screenshots/intro_phone_2.png (1080x2400)
 * workout_ai        | use intro_phone_3 | /screenshots/intro_phone_3.png (1080x2400)
 * multiagent_chat   | use intro_phone_4 | /screenshots/intro_phone_4.png (1080x2400)
 * workout_history   | use intro_phone_5 | /screenshots/intro_phone_5.png (1080x2400)
 * workout_export    | use intro_phone_6 | /screenshots/intro_phone_6.png (1080x2400)
 * cta_visual        | use intro_phone_7 | /screenshots/intro_phone_7.png (1080x2400)
 * -------------------------------------------------------------------------
 * NEEDS NEW: og-bevel-vs.png (1200x630, composited OG card) — flag for Sai
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
  { id: 'tldr', label: 'TL;DR' },
  { id: 'comparison', label: 'Feature comparison' },
  { id: 'pricing', label: 'Pricing' },
  { id: 'price-vs-capability', label: 'Price vs. capability' },
  { id: 'zealova-wins', label: 'Where Zealova wins' },
  { id: 'bevel-wins', label: 'Where Bevel wins' },
  { id: 'which-to-pick', label: 'Which to pick' },
  { id: 'try', label: 'Try Zealova' },
  { id: 'faq', label: 'FAQ' },
];

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/vs/bevel`;
const OG_IMAGE = `/screenshots/og-bevel-vs.png`; // NEEDS NEW: generate 1200x630

const FAQData = [
  {
    q: 'Is Bevel available on Android?',
    a: 'No. As of May 2026, Bevel is iOS-only. The app is built in Swift and requires an iPhone and ideally an Apple Watch for full functionality. There is an active feature request for Android support on their feedback forum, but no announced timeline. Zealova is live on Android now, with iOS in progress.',
  },
  {
    q: 'What is Bevel 3.0 and what did it add?',
    a: 'Bevel 3.0 shipped on May 16, 2026. It added a rebuilt Bevel Intelligence coaching layer with training plan generation (goal-based, cardio-oriented: 10K, half marathon), a Biological Age metric (updates weekly using physiological, lifestyle, and blood biomarker data), a Health Records vault for uploading blood tests and lab results, and coach Personalities (Data Nerd, Guardian, Friend, Commander). Version 3.0.5 followed on May 20, 2026, adding a "This Week\'s Changes" view for Biological Age, enhanced Health Records with document preview and editing, and improved Bevel Intelligence image rendering.',
  },
  {
    q: 'How much does Bevel cost vs Zealova?',
    a: 'Bevel Pro (which includes Bevel Intelligence AI coaching) costs $14.99/month or $99.99/year. The core app is free with no expiry: recovery scores, Strength Builder, nutrition tracking, Biological Age, and Health Records are all in the free tier. Zealova costs $7.99/month or $59.99/year with a 7-day free trial that includes all premium features. On the annual plan, Zealova ($59.99) is $40 per year cheaper than Bevel Pro ($99.99). Pricing verified at the Apple App Store on May 20, 2026.',
  },
  {
    q: 'Does Bevel generate workout plans?',
    a: 'Bevel 3.0 added training plan generation, but it is goal-based and oriented toward cardio events like 10Ks and half marathons. For strength training, Bevel offers a Strength Builder with 700+ exercises and preset routines. AI-generated strength adjustments based on RIR and progressive overload are marked "planned (tbd)" on the Bevel feedback forum with no confirmed ship date as of May 2026. Zealova generates full monthly strength training plans that adapt based on your completion rate and feedback.',
  },
  {
    q: 'Does Bevel have food photo logging?',
    a: "Bevel includes nutrition tracking with barcode scanning and nutritional scoring. It does not have the same food photo logging capability as Zealova. Zealova's food photo logging supports up to 10 photos per meal, with 4 analysis modes (auto, plate, menu, buffet) and extracts individual items, calories, macros, and micronutrients per item.",
  },
  {
    q: 'Can I chat with a multi-agent AI coach in Bevel?',
    a: 'Bevel has Bevel Intelligence, a conversational AI coach that can answer health questions and analyze your data. It is a single unified coach. Zealova runs 5 specialist sub-agents under one chat: a Workout agent, Nutrition agent, Injury agent, Hydration agent, and a general Coach. The router picks the right agent based on what you ask.',
  },
  {
    q: 'Does Bevel integrate with Garmin or non-Apple wearables?',
    a: 'Bevel primarily integrates with Apple Watch and Apple Health. It can pull some Garmin data via Apple Health, but the experience is optimized for Apple Watch 24/7 usage. Bevel does integrate with Dexcom and Libre continuous glucose monitors. Direct Garmin integration is listed as a feature request on their feedback forum without a confirmed ship date.',
  },
  {
    q: 'What is Biological Age in Bevel?',
    a: "Bevel's Biological Age metric (added in 3.0, shipped May 16, 2026) estimates whether your body is aging faster or slower than your calendar age. It updates weekly using physiological data, lifestyle inputs, and blood biomarker data if you connect lab results. This is a genuine differentiator: Zealova does not have a Biological Age metric.",
  },
  {
    q: 'Does Zealova export workouts to other apps?',
    a: 'Yes. Zealova exports your completed workouts in 10 formats: Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, and Parquet. Bevel does not offer third-party workout export in these formats.',
  },
  {
    q: 'Does Bevel track per-exercise and per-muscle history?',
    a: "Bevel tracks muscular strain load at a high level through its Strength Builder. Zealova tracks workout history per individual exercise and per muscle group. You can pull up the history for any specific lift (bench press, squat, Romanian deadlift) and see volume, weight, and reps across every session. This level of granularity is core to Zealova's workout coaching.",
  },
  {
    q: 'Is Bevel better for health tracking or workout coaching?',
    a: "Bevel is stronger on passive health intelligence: recovery scores, sleep analysis, Biological Age, wearable biometrics, and CGM integration. Zealova is stronger on active coaching: generating workout plans, logging food photos, modifying plans via chat, and exporting data. If you want a passive health dashboard that reads your Apple Watch all day, Bevel wins. If you want an active gym coach that builds your program and adapts it, Zealova wins.",
  },
  {
    q: 'Can I use Zealova without a smartwatch?',
    a: 'Yes. Zealova runs full-featured on any Android phone with no wearable required. You log workouts, food photos, and meals manually or via AI chat. No hardware dependency.',
  },
];

const comparisonRows = [
  { feature: 'Monthly price', zealova: '$7.99/mo', bevel: '$14.99/mo (Pro)' },
  { feature: 'Annual price', zealova: '$59.99/yr ($5/mo)', bevel: '$99.99/yr' },
  { feature: 'Free tier available', zealova: 'no', bevel: 'yes (core tracking + Biological Age + Health Records)' },
  { feature: 'Free trial', zealova: '7 days (all features)', bevel: 'Free tier permanent' },
  { feature: 'Platforms', zealova: 'Android (iOS coming)', bevel: 'iOS only' },
  { feature: 'AI workout plan generation', zealova: 'yes (monthly strength plans)', bevel: 'partial (cardio goal plans: 10K, half marathon)' },
  { feature: 'AI strength plan adjustments (RIR, progressive overload)', zealova: 'yes', bevel: 'no (planned, no ship date as of May 2026)' },
  { feature: 'Food photo logging (AI calorie + macro extract)', zealova: 'yes', bevel: 'no (barcode scan + nutritional score only)' },
  { feature: 'Multi-image meal input (up to 10 photos, 4 modes)', zealova: 'yes', bevel: 'no' },
  { feature: 'Restaurant menu scan', zealova: 'yes', bevel: 'no' },
  { feature: 'Multi-agent chat (5 specialist sub-agents)', zealova: 'yes', bevel: 'no (single Bevel Intelligence coach)' },
  { feature: 'Chat-based workout modification + injury swaps', zealova: 'yes', bevel: 'partial' },
  { feature: 'Per-exercise + per-muscle workout history', zealova: 'yes', bevel: 'partial (strain load only)' },
  { feature: '3rd-party workout export (10 formats)', zealova: 'yes', bevel: 'no' },
  { feature: 'Custom exercises + AI-assisted import', zealova: 'yes', bevel: 'no' },
  { feature: 'Supersets', zealova: 'yes', bevel: 'no' },
  { feature: 'Gym equipment profiles (home/commercial/hotel)', zealova: 'yes', bevel: 'no' },
  { feature: 'Personal bests + 1RM calculator', zealova: 'yes', bevel: 'no' },
  { feature: 'Recovery + readiness score', zealova: 'no', bevel: 'yes' },
  { feature: 'Sleep tracking + sleep stages', zealova: 'no', bevel: 'yes' },
  { feature: 'Biological Age metric', zealova: 'no', bevel: 'yes (added 3.0, May 2026, free tier)' },
  { feature: 'Health Records vault (blood tests, labs)', zealova: 'no', bevel: 'yes (added 3.0, May 2026, free tier)' },
  { feature: 'CGM integration (Dexcom, Libre)', zealova: 'no', bevel: 'yes' },
  { feature: 'Apple Health integration', zealova: 'no', bevel: 'yes' },
  { feature: 'Garmin integration (direct)', zealova: 'no', bevel: 'partial (via Apple Health)' },
  { feature: 'Health Connect (Android)', zealova: 'yes', bevel: 'no (iOS only)' },
];

const CELL_YES = 'text-emerald-400 font-semibold';
const CELL_NO = 'text-zinc-500';

function getCellClass(val: string) {
  if (val === 'yes') return CELL_YES;
  if (val === 'no') return CELL_NO;
  return 'text-amber-400';
}

function getCellDisplay(val: string) {
  if (val === 'yes') return '✓';
  if (val === 'no') return '✗';
  return val;
}

// FAQPage schema auto-derives from FAQData — update FAQData above, not here
const jsonLdFaq = {
  '@context': 'https://schema.org',
  '@type': 'FAQPage',
  mainEntity: FAQData.map((item) => ({
    '@type': 'Question',
    name: item.q,
    acceptedAnswer: {
      '@type': 'Answer',
      text: item.a,
    },
  })),
};

const jsonLdZealova = {
  '@context': 'https://schema.org',
  '@type': 'SoftwareApplication',
  name: 'Zealova',
  operatingSystem: 'Android',
  applicationCategory: 'HealthApplication',
  description:
    'AI fitness coach with personalized workout plan generation, food photo logging with multi-image input, 5-agent multi-agent chat, workout history per exercise and muscle group, restaurant menu scan, and 10-format workout export. $7.99/month or $59.99/year.',
  offers: {
    '@type': 'Offer',
    price: '7.99',
    priceCurrency: 'USD',
    priceValidUntil: '2026-12-31',
  },
  image: `https://${BRANDING.marketingDomain}/screenshots/intro_phone_1.png`,
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Comparisons', item: `https://${BRANDING.marketingDomain}/vs` },
    { '@type': 'ListItem', position: 3, name: 'Zealova vs Bevel', item: CANONICAL_URL },
  ],
};

export default function BevelVs() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    document.title = 'Bevel vs Zealova (2026): Honest Comparison | Zealova';

    const descContent =
      'Bevel 3.0 shipped May 2026 with training plans and Biological Age. Honest comparison of pricing, AI coaching, workout generation, food logging, and wearable integrations vs Zealova. Pros and cons of both.';

    const metaDesc = document.querySelector('meta[name="description"]');
    if (metaDesc) {
      metaDesc.setAttribute('content', descContent);
    } else {
      const m = document.createElement('meta');
      m.name = 'description';
      m.content = descContent;
      document.head.appendChild(m);
    }

    const canonical = document.querySelector('link[rel="canonical"]');
    if (canonical) {
      canonical.setAttribute('href', CANONICAL_URL);
    } else {
      const l = document.createElement('link');
      l.rel = 'canonical';
      l.href = CANONICAL_URL;
      document.head.appendChild(l);
    }

    const ogTags: Record<string, string> = {
      'og:title': 'Bevel vs Zealova (2026): Honest Comparison',
      'og:description': descContent,
      'og:url': CANONICAL_URL,
      'og:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
      'og:type': 'article',
      'twitter:card': 'summary_large_image',
      'twitter:title': 'Bevel vs Zealova (2026): Honest Comparison',
      'twitter:description': descContent,
      'twitter:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
    };

    Object.entries(ogTags).forEach(([prop, content]) => {
      const isTwitter = prop.startsWith('twitter:');
      const selector = isTwitter ? `meta[name="${prop}"]` : `meta[property="${prop}"]`;
      let el = document.querySelector(selector);
      if (!el) {
        el = document.createElement('meta');
        if (isTwitter) {
          el.setAttribute('name', prop);
        } else {
          el.setAttribute('property', prop);
        }
        document.head.appendChild(el);
      }
      el.setAttribute('content', content);
    });
  }, []);

  return (
    <>
      {/* JSON-LD schemas */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdZealova) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdFaq) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBreadcrumb) }}
      />

      <ArticleLayout slug="vs/bevel" sections={SECTIONS}>

          {/* Breadcrumb */}
          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Zealova vs Bevel</span>
          </nav>

          {/* Answer capsule: first ~200 words, LLM-quote target */}
          <motion.section
            id="answer"
            initial="hidden"
            animate="visible"
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h1
              variants={fadeUp}
              className="text-3xl sm:text-4xl font-bold tracking-tight text-white mb-6"
            >
              Bevel vs Zealova (2026): Honest Comparison
            </motion.h1>

            <motion.div
              variants={fadeUp}
              className="flex flex-col md:flex-row gap-8 items-start"
            >
              <div className="flex-1">
                <p className="text-zinc-300 text-lg leading-relaxed mb-4">
                  Bevel and Zealova both use AI to help you get healthier, but they solve different problems. Bevel (4.8 stars, 9,500+ App Store ratings, version 3.0.5) is a passive health intelligence platform. It reads your Apple Watch, tracks sleep and recovery, added Biological Age and a Health Records vault in its 3.0 update on May 16, 2026, and connects to Dexcom and Libre CGMs. Version 3.0.5 (May 20, 2026) added a "This Week's Changes" view for Biological Age and enhanced Health Records. Bevel's training plans cover cardio goals like 10Ks and half marathons. Bevel Pro costs $14.99/month or $99.99/year. The core app, including Biological Age and Health Records, is free. Zealova is a workout and nutrition coach in one app. It generates personalized monthly strength training plans, logs meals from food photos and restaurant menus, and routes your questions through 5 specialist AI sub-agents. Zealova costs $7.99/month or $59.99/year with a 7-day free trial.
                </p>
                <p className="text-zinc-300 text-lg leading-relaxed mb-6">
                  The clearest split: Bevel wins on biometric depth and longevity tracking. Zealova wins on workout generation, food photo logging with restaurant menu scan, and active AI coaching.
                </p>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                  <div className="bg-zinc-800 border border-zinc-700 rounded-xl p-4">
                    <div className="text-emerald-400 font-semibold text-sm mb-1">Pick Zealova if you</div>
                    <div className="text-zinc-300 text-sm">want AI-generated strength plans, food photo logging, and a 5-agent chat coach, without needing an Apple Watch.</div>
                  </div>
                  <div className="bg-zinc-800 border border-zinc-700 rounded-xl p-4">
                    <div className="text-blue-400 font-semibold text-sm mb-1">Pick Bevel if you</div>
                    <div className="text-zinc-300 text-sm">wear an Apple Watch daily and want passive recovery scores, sleep tracking, Biological Age, and CGM integration.</div>
                  </div>
                </div>
              </div>
              <div className="md:w-48 shrink-0">
                <img
                  src="/screenshots/intro_phone_1.png"
                  alt="Zealova AI workout plan dashboard on Android"
                  width={540}
                  height={1200}
                  loading="lazy"
                  className="rounded-2xl w-full max-w-[180px] mx-auto shadow-xl"
                />
              </div>
            </motion.div>
          </motion.section>

          {/* TL;DR table */}
          <motion.section
            id="tldr"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              TL;DR
            </motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium w-1/3"></th>
                    <th className="text-left px-4 py-3 text-emerald-400 font-semibold">Zealova</th>
                    <th className="text-left px-4 py-3 text-blue-400 font-semibold">Bevel</th>
                  </tr>
                </thead>
                <tbody>
                  {[
                    ['Monthly price', '$7.99/mo', '$14.99/mo (Pro)'],
                    ['Annual price', '$59.99/yr', '$99.99/yr'],
                    ['Free trial', '7 days (all features)', 'Free core tier (permanent)'],
                    ['Platforms', 'Android (iOS coming)', 'iOS only'],
                    ['Primary differentiator', 'AI strength plan generation + food photo logging', 'Wearable biometrics + Biological Age + sleep'],
                    ['Best for', 'Active gym coaching, workout-first users', 'Passive health tracking, Apple Watch owners'],
                  ].map(([label, z, b]) => (
                    <tr key={label} className="border-b border-zinc-800/60 last:border-0">
                      <td className="px-4 py-3 text-zinc-400 font-medium">{label}</td>
                      <td className="px-4 py-3 text-zinc-200">{z}</td>
                      <td className="px-4 py-3 text-zinc-200">{b}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
          </motion.section>

          {/* Methodology note */}
          <motion.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={fadeUp}
            className="mb-12 bg-zinc-900 border border-zinc-800 rounded-xl px-5 py-4 text-sm text-zinc-400"
          >
            <strong className="text-zinc-300">How this comparison was made:</strong> Bevel pricing verified at the Apple App Store on 2026-05-21 (version 3.0.5, 9,500+ ratings). Bevel 3.0 feature details sourced from gadgetsandwearables.com (published 2026-05-16). Bevel 3.0.5 patch notes verified from App Store listing 2026-05-21. Bevel free-tier scope (Biological Age, Health Records) verified from App Store listing. Bevel training plan scope confirmed cardio-only via feedback.bevel.health/feature-requests/p/cardio-training-plans-marathons-triathlons-etc (staff reply April 27, 2026). Bevel strength AI adjustment status: "planned (tbd)", no update since November 2024 per feedback.bevel.health. Zealova pricing and features verified from internal documentation (2026-05-14, live on Google Play). Feature claims for Bevel sourced from the App Store listing, gadgetsandwearables.com, neura.health review, autonomous.ai review, and feedback.bevel.health -- all verified 2026-05-21.
          </motion.div>

          {/* Feature comparison table */}
          <motion.section
            id="comparison"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Feature comparison
            </motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium w-2/5">Feature</th>
                    <th className="text-left px-4 py-3 text-emerald-400 font-semibold">Zealova</th>
                    <th className="text-left px-4 py-3 text-blue-400 font-semibold">Bevel</th>
                  </tr>
                </thead>
                <tbody>
                  {comparisonRows.map((row) => (
                    <tr key={row.feature} className="border-b border-zinc-800/60 last:border-0 hover:bg-zinc-900/40 transition-colors">
                      <td className="px-4 py-3 text-zinc-300">{row.feature}</td>
                      <td className={`px-4 py-3 ${getCellClass(row.zealova)}`}>{getCellDisplay(row.zealova)}</td>
                      <td className={`px-4 py-3 ${getCellClass(row.bevel)}`}>{getCellDisplay(row.bevel)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
          </motion.section>

          {/* Pricing detail */}
          <motion.section
            id="pricing"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Pricing
            </motion.h2>
            <motion.div variants={fadeUp} className="grid grid-cols-1 sm:grid-cols-2 gap-6">
              <div className="bg-zinc-900 border border-emerald-800/40 rounded-xl p-6">
                <div className="text-emerald-400 font-bold text-lg mb-1">Zealova</div>
                <div className="text-zinc-200 text-3xl font-bold mb-1">$7.99<span className="text-zinc-400 text-base font-normal">/mo</span></div>
                <div className="text-zinc-400 text-sm mb-4">or $59.99/yr ($5/mo, 37% off monthly)</div>
                <ul className="text-zinc-300 text-sm space-y-2">
                  <li>7-day free trial, all features included</li>
                  <li>Live on Google Play Store (Android)</li>
                  <li>iOS App Store coming soon</li>
                  <li>No hardware required</li>
                </ul>
                <div className="text-zinc-500 text-xs mt-4">Pricing verified on Google Play, 2026-05-14</div>
              </div>
              <div className="bg-zinc-900 border border-blue-800/40 rounded-xl p-6">
                <div className="text-blue-400 font-bold text-lg mb-1">Bevel</div>
                <div className="text-zinc-200 text-3xl font-bold mb-1">$14.99<span className="text-zinc-400 text-base font-normal">/mo</span></div>
                <div className="text-zinc-400 text-sm mb-4">or $99.99/yr (Pro tier with Bevel Intelligence)</div>
                <ul className="text-zinc-300 text-sm space-y-2">
                  <li>Free tier: recovery, sleep, Strength Builder, nutrition, Biological Age, Health Records</li>
                  <li>Pro unlocks Bevel Intelligence AI coaching only</li>
                  <li>iOS only (Apple Watch recommended)</li>
                  <li>App Store rating: 4.8/5 (9,500+ ratings), version 3.0.5</li>
                </ul>
                <div className="text-zinc-500 text-xs mt-4">Pricing verified on Apple App Store, 2026-05-21</div>
              </div>
            </motion.div>
          </motion.section>

          {/* Price vs. capability */}
          <motion.section
            id="price-vs-capability"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-4">
              Price vs. capability: what you actually get for each dollar
            </motion.h2>
            <motion.p variants={fadeUp} className="text-zinc-400 text-sm mb-6 leading-relaxed">
              Bevel 3.0 added cardio training plans (10K, half marathon, triathlon) to its Pro tier on May 16, 2026. Strength-specific AI plan generation is still marked "planned (tbd)" on the Bevel feedback forum as of May 2026. Here is what each paid plan buys you at its annual rate:
            </motion.p>
            <motion.div variants={fadeUp} className="grid grid-cols-1 md:grid-cols-2 gap-5 mb-6">
              <div className="bg-zinc-900 border border-emerald-800/40 rounded-xl p-5">
                <div className="text-emerald-400 font-bold text-sm mb-2">Zealova Pro: $59.99/yr ($5/mo)</div>
                <ul className="text-zinc-300 text-sm space-y-1.5">
                  <li>AI-generated monthly strength training plans</li>
                  <li>Food photo logging with calorie and macro extraction</li>
                  <li>Restaurant menu scan: log a meal from a photo of the menu</li>
                  <li>Multi-agent chat coach (5 specialists: Workout, Nutrition, Injury, Hydration, Coach)</li>
                  <li>Per-exercise and per-muscle workout history</li>
                  <li>Workout export in 10 formats</li>
                  <li>Custom exercises, supersets, gym equipment profiles</li>
                </ul>
              </div>
              <div className="bg-zinc-900 border border-blue-800/40 rounded-xl p-5">
                <div className="text-blue-400 font-bold text-sm mb-2">Bevel Pro: $99.99/yr (~$8.33/mo)</div>
                <ul className="text-zinc-300 text-sm space-y-1.5">
                  <li>Bevel Intelligence AI coach (proactive check-ins, data analysis, chart generation)</li>
                  <li>AI training plans: goal-based, cardio-oriented (10K, half marathon)</li>
                  <li>Strength AI adjustments (RIR, progressive overload): still "planned (tbd)" as of May 2026</li>
                  <li className="text-zinc-500 text-xs pt-1">Free tier already includes: recovery scores, Strength Builder, nutrition tracking, Biological Age, Health Records vault, sleep tracking</li>
                </ul>
              </div>
            </motion.div>
            <motion.p variants={fadeUp} className="text-zinc-400 text-sm leading-relaxed">
              The gap that matters for gym-first users: Bevel Pro does not yet generate AI-tailored strength programs or extract calories from meal photos and restaurant menus. Zealova does all three at $40/yr less. If you train with weights and track food, the capability-per-dollar math is straightforward. If you wear an Apple Watch and want passive biometric coaching above all else, Bevel's free tier alone gives you recovery, sleep, and Biological Age for $0 and the Pro add-on is specifically the AI conversation layer.
            </motion.p>
          </motion.section>

          {/* Where Zealova wins */}
          <motion.section
            id="zealova-wins"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Where Zealova wins
            </motion.h2>
            <motion.div variants={fadeUp} className="space-y-6">

              <div className="flex gap-4">
                <div className="text-emerald-400 text-xl mt-0.5 shrink-0">1.</div>
                <div>
                  <div className="text-white font-semibold mb-1">Workout and nutrition in one app</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel is a workout tracker with biometric depth. Zealova is a workout coach plus a nutrition coach in a single app. You get AI-generated strength plans, food photo logging for home meals and restaurant menus, and a multi-agent chat that covers all three in one conversation. Bevel does not offer food photo AI, restaurant menu scanning, or an equivalent nutrition coaching layer. If you train and track food, Zealova handles both without switching apps.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <img
                  src="/screenshots/intro_phone_2.png"
                  alt="Zealova food photo logging with multi-image input"
                  width={540}
                  height={1200}
                  loading="lazy"
                  className="rounded-xl w-24 h-auto shrink-0 object-cover shadow-lg hidden sm:block"
                />
                <div>
                  <div className="text-white font-semibold mb-1">Food photo logging and restaurant menu scan</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Photograph a plated meal or a buffet spread and Zealova extracts individual food items, calories, macros, and micronutrients per item across up to 10 photos. Photograph a restaurant menu and it identifies dishes and estimates macros per dish. Bevel has barcode scanning and a nutritional score, but no food-photo AI and no menu scan. Eating out is where most people's calorie tracking breaks. Zealova solves that directly.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-emerald-400 text-xl mt-0.5 shrink-0">3.</div>
                <div>
                  <div className="text-white font-semibold mb-1">5-agent multi-agent chat coach</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Zealova routes your messages to 5 specialist sub-agents: Workout, Nutrition, Injury, Hydration, and Coach. Ask about hip pain and you get the Injury agent. Ask to swap squats and you get the Workout agent with RAG over the full exercise library. Bevel has Bevel Intelligence, a single unified AI coach.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <img
                  src="/screenshots/intro_phone_3.png"
                  alt="Zealova per-exercise workout history screen"
                  width={540}
                  height={1200}
                  loading="lazy"
                  className="rounded-xl w-24 h-auto shrink-0 object-cover shadow-lg hidden sm:block"
                />
                <div>
                  <div className="text-white font-semibold mb-1">Per-exercise and per-muscle workout history</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Pull up any lift (bench press, Romanian deadlift, lateral raise) and see your complete history: weight, reps, sets, volume, across every session. Per-muscle volume tracking shows how hard you've hit each muscle group this week. Bevel tracks strain load in aggregate, not at the individual exercise level.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-emerald-400 text-xl mt-0.5 shrink-0">5.</div>
                <div>
                  <div className="text-white font-semibold mb-1">10-format workout export and Android availability</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Zealova exports your training data in 10 formats: Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, and Parquet. Your data is yours. Bevel has no equivalent export. Zealova is also live on Android right now. Bevel is iOS only with no announced Android timeline.
                  </p>
                </div>
              </div>

            </motion.div>
          </motion.section>

          {/* Where Bevel wins */}
          <motion.section
            id="bevel-wins"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-2">
              Where Bevel wins
            </motion.h2>
            <motion.p variants={fadeUp} className="text-zinc-500 text-sm mb-6">
              These are real advantages. If they matter to you, Bevel is the better pick.
            </motion.p>
            <motion.div variants={fadeUp} className="space-y-5">

              <div className="flex gap-4">
                <div className="text-blue-400 text-xl mt-0.5 shrink-0">1.</div>
                <div>
                  <div className="text-white font-semibold mb-1">Wearable biometrics and passive health intelligence</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel reads your Apple Watch all day: HRV, resting heart rate, sleep stages, readiness score, strain. It surfaces a daily recovery score and tells you whether to push or rest. Zealova does not have wearable-native biometric tracking. If passive, always-on health monitoring is what you need, Bevel wins this clearly.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-blue-400 text-xl mt-0.5 shrink-0">2.</div>
                <div>
                  <div className="text-white font-semibold mb-1">Biological Age (added in 3.0, expanded in 3.0.5, available free)</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel's Biological Age metric estimates whether your body is aging faster or slower than your calendar age, updating weekly using physiological, lifestyle, and blood biomarker data. Version 3.0.5 (May 20, 2026) added a "This Week's Changes" view that breaks down which specific biomarkers moved your biological age up or down. This is in Bevel's free tier. Zealova does not have a Biological Age metric. If longevity tracking matters to you, this is a genuine Bevel differentiator, and you do not need a paid plan to access it.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-blue-400 text-xl mt-0.5 shrink-0">3.</div>
                <div>
                  <div className="text-white font-semibold mb-1">CGM integration (Dexcom and Libre)</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel integrates with Dexcom and Libre continuous glucose monitors, correlating glucose data with sleep, recovery, and nutrition. If you wear a CGM or track blood glucose, Bevel has the integration. Zealova does not.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-blue-400 text-xl mt-0.5 shrink-0">4.</div>
                <div>
                  <div className="text-white font-semibold mb-1">Health Records vault (added in 3.0, enhanced in 3.0.5, available free)</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel 3.0 added a Health Records vault where you upload blood tests, lab results, and clinical notes as PDFs or photos. The app extracts key biomarkers and integrates them into your health analysis. Version 3.0.5 added document preview, editing, and deletion so you can manage records without leaving the app. This is in Bevel's free tier. If you want your lab work connected to your fitness data, Bevel has this. Zealova does not.
                  </p>
                </div>
              </div>

              <div className="flex gap-4">
                <div className="text-blue-400 text-xl mt-0.5 shrink-0">5.</div>
                <div>
                  <div className="text-white font-semibold mb-1">Permanently free core tier</div>
                  <p className="text-zinc-400 text-sm leading-relaxed">
                    Bevel's core app is free with no cutoff date: recovery scores, strength tracking, nutrition, and sleep access at no cost. The premium Bevel Intelligence AI coaching layer costs $14.99/month. Zealova's 7-day trial expires and requires a subscription for continued access. If budget is tight, Bevel's free tier gives more for $0.
                  </p>
                </div>
              </div>

            </motion.div>
          </motion.section>

          {/* Which should you pick */}
          <motion.section
            id="which-to-pick"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Which should you pick?
            </motion.h2>
            <motion.div variants={fadeUp} className="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div className="bg-zinc-900 border border-emerald-800/40 rounded-xl p-6">
                <div className="text-emerald-400 font-bold mb-3">Pick Zealova if you</div>
                <ul className="text-zinc-300 text-sm space-y-2">
                  <li>Lift weights and want AI-generated programming each month</li>
                  <li>Log food by photographing meals, menus, or buffets</li>
                  <li>Use Android (Bevel is not available for you)</li>
                  <li>Want to modify your workout plan via chat when you get an injury</li>
                  <li>Care about per-exercise history and per-muscle volume tracking</li>
                  <li>Want to export your training data to Hevy, Strong, Fitbod, or CSV</li>
                  <li>Want a cheaper annual plan ($59.99 vs $99.99)</li>
                </ul>
              </div>
              <div className="bg-zinc-900 border border-blue-800/40 rounded-xl p-6">
                <div className="text-blue-400 font-bold mb-3">Pick Bevel if you</div>
                <ul className="text-zinc-300 text-sm space-y-2">
                  <li>Wear an Apple Watch every day and want passive biometric tracking</li>
                  <li>Care about sleep stages, HRV, and daily readiness scores</li>
                  <li>Want Biological Age tracking and longevity-focused health metrics</li>
                  <li>Use a Dexcom or Libre CGM and want it connected to your health dashboard</li>
                  <li>Want to upload blood test results and have them analyzed in-app</li>
                  <li>Want a free tier that doesn't expire</li>
                </ul>
              </div>
            </motion.div>
          </motion.section>

          {/* CTA section */}
          <motion.section
            id="try"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.div
              variants={fadeUp}
              className="bg-gradient-to-br from-zinc-900 to-zinc-800 border border-zinc-700 rounded-2xl p-8 text-center"
            >
              <img
                src="/screenshots/intro_phone_7.png"
                alt="Zealova multi-agent AI coach chat interface"
                width={540}
                height={1200}
                loading="lazy"
                className="w-28 mx-auto mb-6 rounded-xl shadow-xl"
              />
              <h2 className="text-2xl font-bold text-white mb-3">Try Zealova free for 7 days</h2>
              <p className="text-zinc-400 text-sm mb-2 max-w-md mx-auto">
                Yes, Bevel has a free tier with no expiry. Zealova's trial is 7 days. You'll know within the first workout whether the plan fits your training style. If it doesn't, cancel before the trial ends.
              </p>
              <p className="text-zinc-500 text-xs mb-6 max-w-md mx-auto">
                Zealova is $7.99/month or $59.99/year. Bevel Pro is $14.99/month or $99.99/year. If AI-generated workout programming and food photo logging are what you need, the 7-day window is enough to verify that.
              </p>
              <a
                href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
                target="_blank"
                rel="noopener noreferrer"
                className="inline-block bg-emerald-500 hover:bg-emerald-400 text-white font-semibold px-8 py-3 rounded-xl transition-colors text-sm"
              >
                Download Zealova on Android
              </a>
              <p className="text-zinc-600 text-xs mt-3">Android only. iOS coming soon.</p>
            </motion.div>
          </motion.section>

          {/* FAQ */}
          <motion.section
            id="faq"
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-16 scroll-mt-24"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              FAQ
            </motion.h2>
            <motion.div variants={fadeUp} className="space-y-3">
              {FAQData.map((item, idx) => (
                <div
                  key={idx}
                  className="border border-zinc-800 rounded-xl overflow-hidden"
                >
                  <button
                    className="w-full text-left px-5 py-4 flex justify-between items-center gap-4 hover:bg-zinc-900/60 transition-colors"
                    onClick={() => setOpenFaq(openFaq === idx ? null : idx)}
                    aria-expanded={openFaq === idx}
                  >
                    <span className="text-zinc-200 text-sm font-medium">{item.q}</span>
                    <span className="text-zinc-500 shrink-0 text-lg leading-none">
                      {openFaq === idx ? '−' : '+'}
                    </span>
                  </button>
                  {openFaq === idx && (
                    <div className="px-5 pb-4 text-zinc-400 text-sm leading-relaxed border-t border-zinc-800">
                      <div className="pt-3">{item.a}</div>
                    </div>
                  )}
                </div>
              ))}
            </motion.div>
          </motion.section>

          {/* Methodology footnote */}
          <motion.footer
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={fadeUp}
            className="border-t border-zinc-800 pt-8 text-xs text-zinc-500 leading-relaxed"
          >
            <p>
              Last updated 2026-05-21 by Sai. Bevel pricing verified at the Apple App Store on 2026-05-21 (Bevel: AI Health Coach App, version 3.0.5, ID 6456176249, 9,500+ ratings). Bevel 3.0 feature details sourced from gadgetsandwearables.com (published 2026-05-16). Bevel 3.0.5 patch notes verified from App Store listing 2026-05-21. Bevel free-tier contents (Biological Age, Health Records) verified from App Store listing 2026-05-21. Bevel training plan scope (cardio-only: 10K, half marathon, triathlon) confirmed via feedback.bevel.health/feature-requests/p/cardio-training-plans-marathons-triathlons-etc (staff reply April 27, 2026). Bevel strength AI adjustment status verified at feedback.bevel.health/feature-requests/p/strength-trainer-available-weights-rir-automatic-adjustments (status: "planned (tbd)", staff reply November 2024). Android availability status sourced from feedback.bevel.health and askvora.com/compare/bevel (verified 2026-05-17). Zealova pricing and features verified from internal documentation and Google Play Store listing (2026-05-14). Wearable accuracy research: Shcherbina et al., 2017, Journal of Personalized Medicine -- tested 7 wrist-worn devices and found calorie burn error ranged 27-93% across devices. Feature claims without live source are drawn from the Bevel App Store listing as of 2026-05-21.
            </p>
          </motion.footer>

      </ArticleLayout>
    </>
  );
}
