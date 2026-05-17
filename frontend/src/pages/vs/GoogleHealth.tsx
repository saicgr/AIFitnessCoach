/**
 * /vs/google-health — Zealova vs Google Health comparison page
 * v6 — 2026-05-14 (research citations + wedge-sharpening pass per Sai review of v5)
 *
 * What changed from v3:
 *  - Comparison table moved BEFORE hero wedges (recon: Fitbod/vs/Caliber + MacroFactor pages
 *    put the table earlier; readers scan table first, then read depth)
 *  - "How this comparison was made" methodology block added after TL;DR
 *    (MacroFactor's explicit methodology is a proven ranking trust signal)
 *  - "What Fitbit users are frustrated about" pain-point section added BEFORE
 *    the use-case picker (Hoot exemplar: leading with the problem builds emotional
 *    case before any product pitch)
 *  - FAQ expanded from 12 to 14 Q/As (Hoot exemplar: 15 beats competitors' 7-10;
 *    two new Qs: workout export migration + Google Health wearable-free limitations)
 *  - Zealova wins trimmed from 9 to 7 bullets (tighter, more defensible per recon:
 *    pages with 9+ one-sided wins are flagged by LLMs; 7:7 is the winning ratio)
 *  - Google Health wins trimmed from 9 to 7 bullets (same reasoning, sharper)
 *  - Answer capsule tightened: removed one redundant sentence
 *  - Methodology footnote promoted from page bottom to a visible inline block
 *    (recon: Foodnoms and MacroFactor both surface the methodology early)
 *  - Section h2 text updates: "Feature comparison" now comes before "Why gym-focused
 *    users pick Zealova" to match table-first SERP pattern
 *
 * DEMOTED from v2 (§2G reliability hold — do NOT restore without Sai sign-off):
 *   - Form video analysis       — removed from all claims
 *   - In-workout AI coach chat  — removed; chat between workouts only
 *   - Menu scan                 — removed from all claims
 *   - Recipe import             — removed from table
 *   - MFP screenshot OCR        — removed from all claims
 *   - Audio coach daily brief   — removed from table
 *   - Skill progressions        — removed from table
 *   - Multi-execution UI tiers  — demoted to "easy-to-read workout layout" language
 *
 * Asset manifest (2026-05-14 — unchanged from v3):
 * -------------------------------------------------------------------------
 * Slot              | Status            | Path
 * -------------------------------------------------------------------------
 * hero_og           | NEEDS NEW         | /screenshots/og-google-health-vs.png  (1200x630)
 * answer_capsule    | NEEDS NEW         | /screenshots/answer-capsule-hero.png  (1200x630)
 * food_logging      | use intro_phone_1 | /screenshots/intro_phone_1.png        (1080x2400)
 * workout_ai        | use intro_phone_2 | /screenshots/intro_phone_2.png        (1080x2400)
 * multiagent_chat   | use intro_phone_3 | /screenshots/intro_phone_3.png        (1080x2400)
 * workout_history   | use intro_phone_4 | /screenshots/intro_phone_4.png        (1080x2400)
 * workout_export    | use intro_phone_5 | /screenshots/intro_phone_5.png        (1080x2400)
 * cta_visual        | use intro_phone_6 | /screenshots/intro_phone_6.png        (1080x2400)
 * -------------------------------------------------------------------------
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

const stagger = {
  visible: { transition: { staggerChildren: 0.1 } },
};

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/vs/google-health`;

const OG_IMAGE = `/screenshots/og-google-health-vs.png`; // NEEDS NEW: generate 1200x630

// 14 FAQs (up from 12 in v3) — two new Qs: workout migration + wearable-free cap
const FAQData = [
  {
    q: 'Do I need a Fitbit or Pixel Watch to use Google Health?',
    a: 'Google Health works with hundreds of apps and devices via Health Connect, Apple Health, and Google Health APIs. The AI Coach is built around the Fitbit Air ecosystem. Continuous biometrics like HR, HRV, SpO2, and sleep stages require a paired compatible wearable for full functionality. Worth knowing: a 2017 Stanford study tested 7 wrist-worn devices including Fitbit and found calorie burn error ranged from 27% to 93% across devices. No device came within 20% of accurate energy expenditure (Shcherbina et al., 2017, Journal of Personalized Medicine). Heart rate was accurate; calorie burn was not. Zealova runs full-featured on any Android phone with no hardware required and does not rely on wearable calorie estimates.',
  },
  {
    q: 'Does Google Health offer a free trial?',
    a: 'Yes. New Google Health users get a 3-month trial of Google Health Premium when they update to the app on or after May 19, 2026. Fitbit Air buyers also get a 3-month trial bundled with the $99.99 tracker.',
  },
  {
    q: 'What happened to the Fitbit app?',
    a: 'The Fitbit app permanently became Google Health on May 19, 2026. Accounts not migrated to a Google account by May 16 lost data access. Social features, badges, sleep animals, snore detection, group challenges, and the Fitbit community forums were removed in the transition.',
  },
  {
    q: 'Does Google Health support food photo logging?',
    a: "Yes. Google Health Coach supports meal photo logging. You snap a photo and it estimates nutritional content. Zealova also supports food photo logging with up to 10 photos per meal and 4 analysis modes (auto, plate, menu, buffet). The difference is precision: Zealova extracts individual items, calories, macros, and micronutrients per item and auto-logs them to your diary.",
  },
  {
    q: 'Does Google Health generate full workout plans?',
    a: "Google Health Coach provides workout suggestions and lets you create custom workouts using natural language. It does not generate full structured monthly workout plans. Zealova generates personalized monthly workout plans that adapt based on your progress and feedback.",
  },
  {
    q: 'Can I chat with the Google Health coach during a workout?',
    a: 'Google Health Coach is available 24/7 for conversation. Real-time in-workout chat during an active session is not a documented feature in the launch spec. Zealova supports chat with the AI coach between workouts, including workout plan modification, exercise swaps for injuries, and training questions.',
  },
  {
    q: 'Can Google Health read my MyFitnessPal data?',
    a: 'Yes, through Connected Apps you can link MFP and import your meals via Health Connect or the Google Health APIs. Some links need to be reauthorized after the Fitbit-to-Google-Health transition.',
  },
  {
    q: 'I was a Fitbit user. Does Zealova let me take my workout data with me?',
    a: "Yes. Zealova exports your completed workouts in 10 formats: Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, and Parquet. You can also import custom exercises with AI-assisted import. Your lifting history is yours. Zealova won't lock you in.",
  },
  {
    q: 'Is Google Health available on iPhone?',
    a: 'Yes. The Google Health app is available on iOS (requires iOS 16.4 or higher). Zealova is currently Android only. iOS is in progress but not yet available in the App Store.',
  },
  {
    q: 'How much does Google Health Premium cost vs Zealova?',
    a: 'Google Health Premium is $9.99/month or $99/year (verified at store.google.com, May 2026). Zealova is $7.99/month or $59.99/year, about 40% cheaper on the annual plan. Both offer free trials: Zealova is 7 days, Google Health Premium is 3 months for new users.',
  },
  {
    q: 'Does Zealova work with Health Connect?',
    a: "Yes. Zealova has Health Connect integration on Android (limited scope per the May 2026 Play Store resubmit). This lets Zealova read and write compatible health metrics through Android's standardized health data layer.",
  },
  {
    q: 'Does Zealova have workout export?',
    a: 'Yes. Zealova exports workouts to 10 formats: Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, and Parquet. Google Health does not currently offer third-party workout export in these formats.',
  },
  {
    q: 'What can Google Health do without a Fitbit or Pixel Watch?',
    a: "Google Health works with hundreds of apps and devices via Health Connect, Apple Health, and Google Health APIs. The AI Coach is optimized for the Fitbit Air ecosystem. Continuous biometrics like HR, HRV, SpO2, and sleep stages require a paired compatible wearable for full functionality. Zealova runs full-featured on any Android phone with no hardware required.",
  },
  {
    q: 'I want to migrate from Fitbit to a workout-focused app. What do I need to know?',
    a: "If your primary goal is structured strength training, Zealova generates a full monthly workout plan, tracks your history per exercise and per muscle group, and exports everything in 10 formats including Hevy, Fitbod, and PDF. It won't replace the biometric tracking a Fitbit provides. Step counts, sleep stages, HRV, and SpO2 all require hardware. But for gym coaching, Zealova covers what Google Health does not.",
  },
];

const comparisonRows = [
  { feature: 'Hardware required for full AI coach', zealova: 'None (any Android phone)', google: 'Fitbit Air / compatible wearable' },
  { feature: 'AI workout plan generation (full monthly plan)', zealova: 'yes', google: 'no' },
  { feature: 'Workout suggestions / natural language workouts', zealova: 'yes', google: 'yes' },
  { feature: 'Food photo logging (AI calorie estimate)', zealova: 'yes', google: 'yes' },
  { feature: 'Multi-image meal input (up to 10 photos, 4 modes)', zealova: 'yes', google: 'no' },
  { feature: 'Chat coach between workouts', zealova: 'yes', google: 'yes' },
  { feature: 'Workout modification via chat (RAG exercise swap)', zealova: 'yes', google: 'partial' },
  { feature: 'Multi-agent chat (5 specialist sub-agents)', zealova: 'yes', google: 'no' },
  { feature: 'Injury-aware exercise swaps via chat', zealova: 'yes', google: 'no' },
  { feature: 'Per-exercise + per-muscle workout history', zealova: 'yes', google: 'no' },
  { feature: '3rd-party workout export (10 formats)', zealova: 'yes', google: 'no' },
  { feature: 'Custom exercises + AI-assisted import', zealova: 'yes', google: 'no' },
  { feature: 'Supersets', zealova: 'yes', google: 'no' },
  { feature: 'Gym equipment profiles (home / commercial / hotel)', zealova: 'yes', google: 'no' },
  { feature: 'Easy-to-read active workout layout', zealova: 'yes', google: 'yes' },
  { feature: 'MFP integration (Connected Apps)', zealova: 'no', google: 'yes' },
  { feature: 'Peloton integration', zealova: 'no', google: 'yes' },
  { feature: 'Apple Health integration', zealova: 'no', google: 'yes' },
  { feature: 'Health Connect (Android)', zealova: 'yes', google: 'yes' },
  { feature: 'Continuous biometric tracking (HR, SpO2, HRV)', zealova: 'no', google: 'yes (with Fitbit/Pixel Watch)' },
  { feature: 'Sleep tracking', zealova: 'no', google: 'yes' },
  { feature: 'Medical record summaries (US)', zealova: 'no', google: 'yes' },
  { feature: 'Readiness / recovery score', zealova: 'no', google: 'yes (with hardware)' },
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
    'AI fitness coach with personalized workout plan generation, food photo logging with multi-image input, workout history per exercise and muscle group, and 10-format workout export. $7.99/month or $59.99/year.',
  offers: {
    '@type': 'Offer',
    price: '7.99',
    priceCurrency: 'USD',
    priceValidUntil: '2026-12-31',
  },
  url: `https://${BRANDING.marketingDomain}`,
};

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Comparisons', item: `https://${BRANDING.marketingDomain}/vs` },
    { '@type': 'ListItem', position: 3, name: 'Zealova vs Google Health', item: CANONICAL_URL },
  ],
};

export default function GoogleHealthVs() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    document.title = 'Google Health vs Zealova (2026): Honest Comparison | Zealova';

    const descContent =
      'Google Health replaces Fitbit on May 19, 2026. Honest comparison of price, AI coaching, food photo logging, workout plans, and data portability vs Zealova. With honest pros and cons for both.';

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
      'og:title': 'Google Health vs Zealova (2026): Honest Comparison',
      'og:description': descContent,
      'og:url': CANONICAL_URL,
      'og:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
      'og:type': 'article',
      'twitter:card': 'summary_large_image',
      'twitter:title': 'Google Health vs Zealova (2026): Honest Comparison',
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

      <div className="min-h-screen bg-zinc-950 text-zinc-100">
        <MarketingNav />
        <ScrollSpyToc />

        <main className="max-w-4xl mx-auto px-4 sm:px-6 py-16 sm:py-24">

          {/* Breadcrumb */}
          <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
            <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
            <span className="mx-2">/</span>
            <span className="text-zinc-400">Zealova vs Google Health</span>
          </nav>

          {/* Answer capsule — first ~200 words, LLM-quote target */}
          <motion.section
            initial="hidden"
            animate="visible"
            variants={stagger}
            className="mb-14"
          >
            <motion.div variants={fadeUp}>
              <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
                Published 2026-05-14 · Updated 2026-05-16 for Google Health launch May 19, 2026
              </p>
              <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
                Google Health vs Zealova (2026): Honest Comparison
              </h1>
            </motion.div>

            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6"
            >
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                The clearest difference between these two apps is hardware. Google Health is built
                around Fitbit and Pixel Watch. Its AI Coach delivers continuous biometrics, sleep
                stages, HRV, and readiness scores through those devices. Without a compatible wearable,
                you get a fraction of what you're paying for. Zealova runs full-featured on any Android
                phone. No tracker purchase required, ever.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                Google Health launched May 19, 2026 as the permanent replacement for Fitbit. It costs
                $9.99/month or $99/year. It connects to Apple Health, MyFitnessPal, and Peloton, and
                supports meal photo logging and workout suggestions via natural language. Zealova is
                $7.99/month or $59.99/year, live on Android. It generates full personalized monthly
                workout plans, supports food photo logging with up to 10 photos per meal and 4 analysis
                modes, and tracks history per exercise and per muscle group.
              </p>
              <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-6">
                Google Health wins on ecosystem: wearable biometrics, sleep tracking, Apple Health,
                Peloton, medical records, and Google-brand data trust. Zealova wins on workout depth:
                full AI-generated monthly plans, multi-image food logging, granular exercise history,
                and 10-format workout export at 40% cheaper per year than Google Health annual. One
                early caution: reviewers found Google Health's AI Coach fabricating activity it never
                recorded — Android Authority documented it inventing a 5-mile run that never happened
                (May 2026) — so cross-check its summaries against your real data.
              </p>
              <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
                <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                  <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                  <p className="text-sm text-zinc-300">
                    you don't own a Fitbit or Pixel Watch and don't plan to buy one. Zealova gives
                    you AI workout plans and food photo logging on the phone you already own.
                  </p>
                </div>
                <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                  <p className="text-sm font-semibold text-blue-400 mb-1">Pick Google Health if</p>
                  <p className="text-sm text-zinc-300">
                    you own a Fitbit or Pixel Watch and want continuous biometrics, sleep analysis,
                    and a single app connecting your existing health ecosystem.
                  </p>
                </div>
              </div>
            </motion.div>
          </motion.section>

          {/* TL;DR Table */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-8"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              TL;DR
            </motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium w-1/3"></th>
                    <th className="text-left px-4 py-3 text-emerald-400 font-semibold">Zealova</th>
                    <th className="text-left px-4 py-3 text-blue-400 font-semibold">Google Health</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {[
                    ['Monthly price', '$7.99/mo', '$9.99/mo'],
                    ['Annual price', '$59.99/yr ($5/mo)', '$99/yr ($8.25/mo)'],
                    ['Free trial', '7 days', '3 months (new users)'],
                    ['Platforms', 'Android (iOS coming soon)', 'Android + iOS'],
                    ['Hardware required', 'None', 'Fitbit / Pixel Watch for full AI coach'],
                    ['Workout plans', 'Full monthly AI-generated plans', 'Suggestions + custom workouts'],
                    ['Food logging', 'Multi-image (up to 10 photos, 4 modes)', 'Single meal photo'],
                    ['Primary differentiator', 'AI workout plans + multi-image food logging', 'Wearable biometrics + sleep tracking'],
                  ].map(([label, zVal, gVal]) => (
                    <tr key={label} className="bg-zinc-950 hover:bg-zinc-900/60 transition-colors">
                      <td className="px-4 py-3 text-zinc-400">{label}</td>
                      <td className="px-4 py-3 text-zinc-200">{zVal}</td>
                      <td className="px-4 py-3 text-zinc-200">{gVal}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">
              Pricing verified: Zealova as of 2026-05-14. Google Health at store.google.com, 2026-05-14.
            </p>
          </motion.section>

          {/* Methodology block — NEW in v4, moved inline per recon (MacroFactor / Hoot move) */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900/60 border border-zinc-800 rounded-xl px-5 py-4"
            >
              <p className="text-xs font-semibold uppercase tracking-widest text-zinc-500 mb-2">
                How this comparison was made
              </p>
              <p className="text-sm text-zinc-400 leading-relaxed">
                Google Health pricing was verified at store.google.com on 2026-05-14. Feature claims
                are sourced from the Google Health launch blog (blog.google, published 2026-05-07),
                the Google Health Coach post (blog.google, 2026-05), TechCrunch (published 2026-05-07),
                and the Fitbit Help Center (support.google.com/fitbit, checked 2026-05-14). Zealova
                features and pricing are sourced from internal app router audit and
                _ZEALOVA_FACTS.md v1.3 (audited 2026-05-14). Research citations: Shcherbina A et al.
                (2017, J Pers Med, doi:10.3390/jpm7020003) for wearable energy expenditure accuracy;
                Schoenfeld BJ, Ogborn D, Krieger JW (2017, J Sports Sci 35:11) for training volume
                dose-response; Burke LE, Wang J, Sevick MA (2011, J Am Diet Assoc 111:1) and
                Turner-McGrievy GM et al. (2019, J Acad Nutr Diet 119:9) for dietary self-monitoring
                adherence. I am the founder of Zealova. I am not a neutral third party. I have tried
                to concede every honest Google Health advantage. If something looks wrong, email me:
                sai@zealova.com.
              </p>
            </motion.div>
          </motion.section>

          {/* Who this comparison is for — NEW in v6 */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.div
              variants={fadeUp}
              className="bg-amber-950/20 border border-amber-900/30 rounded-xl px-5 py-4"
            >
              <p className="text-xs font-semibold uppercase tracking-widest text-amber-400 mb-2">
                Who this comparison is for
              </p>
              <p className="text-sm text-zinc-300 leading-relaxed">
                This page is most useful if you don't already own a Fitbit or Pixel Watch. If you do,
                Google Health's automatic upgrade path and integrated biometrics make it the obvious
                choice. Switching apps isn't worth losing your data continuity. This comparison exists
                for everyone else: people evaluating their first fitness app, former Fitbit users who
                don't want to pay $99.99 for the Fitbit Air, or anyone who just wants a gym coach on
                the phone they already own.
              </p>
            </motion.div>
          </motion.section>

          {/* Full Feature Comparison Table — MOVED BEFORE hero wedges per recon */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Feature comparison
            </motion.h2>
            <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
              <table className="w-full text-sm">
                <thead>
                  <tr className="bg-zinc-900 border-b border-zinc-800">
                    <th className="text-left px-4 py-3 text-zinc-400 font-medium">Feature</th>
                    <th className="text-left px-4 py-3 text-emerald-400 font-semibold">Zealova</th>
                    <th className="text-left px-4 py-3 text-blue-400 font-semibold">Google Health</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-zinc-800/60">
                  {comparisonRows.map((row) => (
                    <tr key={row.feature} className="bg-zinc-950 hover:bg-zinc-900/50 transition-colors">
                      <td className="px-4 py-3 text-zinc-300">{row.feature}</td>
                      <td className={`px-4 py-3 ${getCellClass(row.zealova)}`}>
                        {getCellDisplay(row.zealova)}
                      </td>
                      <td className={`px-4 py-3 ${getCellClass(row.google)}`}>
                        {getCellDisplay(row.google)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </motion.div>
            <p className="text-xs text-zinc-500 mt-2">
              Partial = feature exists with meaningful limitations. Sources: Google Health launch blog
              (blog.google, 2026-05-07), Google Health Coach post (blog.google, 2026-05), TechCrunch
              (2026-05-07), Fitbit Help Center (2026-05-14).
            </p>
          </motion.section>

          {/* Pricing Detail */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Pricing breakdown
            </motion.h2>
            <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-6">
              <motion.div variants={fadeUp} className="bg-zinc-900 border border-emerald-900/40 rounded-xl p-6">
                <p className="text-xs uppercase tracking-widest text-emerald-400 mb-3">Zealova</p>
                <p className="text-2xl font-bold text-white mb-1">
                  $7.99<span className="text-base font-normal text-zinc-400">/mo</span>
                </p>
                <p className="text-sm text-zinc-400 mb-4">or $59.99/year ($5/mo, save $36/yr vs monthly)</p>
                <ul className="space-y-1 text-sm text-zinc-300">
                  <li>7-day free trial, all features included</li>
                  <li>No hardware required</li>
                  <li>Android live, iOS coming soon</li>
                </ul>
                <p className="text-xs text-zinc-500 mt-4">Pricing as of 2026-05-14. Rolling out on Play Store.</p>
              </motion.div>
              <motion.div variants={fadeUp} className="bg-zinc-900 border border-blue-900/30 rounded-xl p-6">
                <p className="text-xs uppercase tracking-widest text-blue-400 mb-3">Google Health Premium</p>
                <p className="text-2xl font-bold text-white mb-1">
                  $9.99<span className="text-base font-normal text-zinc-400">/mo</span>
                </p>
                <p className="text-sm text-zinc-400 mb-4">or $99/year ($8.25/mo)</p>
                <ul className="space-y-1 text-sm text-zinc-300">
                  <li>3-month free trial (new users)</li>
                  <li>Included with Google AI Pro and AI Ultra</li>
                  <li>Fitbit Air bundle: $99.99 tracker + 3-month trial</li>
                  <li>Android + iOS available</li>
                </ul>
                <p className="text-xs text-zinc-500 mt-4">
                  Verified at store.google.com, 2026-05-14. Annual price increased from Fitbit Premium's $79.99/yr.
                </p>
              </motion.div>
            </motion.div>
          </motion.section>

          {/* Hidden cost callout + 5-year calculator — NEW in v6 */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-amber-900/40 rounded-xl p-6 mb-4"
            >
              <p className="text-xs font-semibold uppercase tracking-widest text-amber-400 mb-3">
                The hidden cost of full Google Health functionality
              </p>
              <p className="text-sm text-zinc-300 leading-relaxed mb-3">
                Google Health Premium is $99/yr. But the AI Coach is built around the Fitbit Air
                ecosystem. If you don't already own a compatible wearable, you need one to get full
                biometric coaching. The Fitbit Air is $99.99. That's $198.99 in year one for the
                complete Google Health experience. Zealova is $59.99/yr on the phone you already own.
                That's a $139 gap in year one alone.
              </p>
              <div className="grid sm:grid-cols-3 gap-3 pt-3 border-t border-zinc-800">
                <div className="text-center">
                  <p className="text-xs text-zinc-500 mb-1">Google Health year one</p>
                  <p className="text-lg font-bold text-amber-400">$198.99</p>
                  <p className="text-xs text-zinc-500">$99/yr + $99.99 Fitbit Air</p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-zinc-500 mb-1">Zealova year one</p>
                  <p className="text-lg font-bold text-emerald-400">$59.99</p>
                  <p className="text-xs text-zinc-500">No hardware needed</p>
                </div>
                <div className="text-center">
                  <p className="text-xs text-zinc-500 mb-1">Year-one gap</p>
                  <p className="text-lg font-bold text-white">$139.00</p>
                  <p className="text-xs text-zinc-500">in Zealova's favor</p>
                </div>
              </div>
            </motion.div>
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900/60 border border-zinc-800 rounded-xl px-5 py-4"
            >
              <p className="text-xs font-semibold uppercase tracking-widest text-zinc-500 mb-3">
                5-year cost comparison (annual plans, no hardware upgrade)
              </p>
              <div className="grid sm:grid-cols-3 gap-4">
                <div>
                  <p className="text-xs text-zinc-500 mb-1">Zealova (5 years)</p>
                  <p className="text-base font-bold text-emerald-400">$299.95</p>
                  <p className="text-xs text-zinc-500">$59.99 x 5</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 mb-1">Google Health Premium (5 years)</p>
                  <p className="text-base font-bold text-blue-400">$495.00</p>
                  <p className="text-xs text-zinc-500">$99 x 5</p>
                </div>
                <div>
                  <p className="text-xs text-zinc-500 mb-1">Subscription savings</p>
                  <p className="text-base font-bold text-white">$195.05</p>
                  <p className="text-xs text-zinc-500">+ $99.99 if no Fitbit owned</p>
                </div>
              </div>
              <p className="text-xs text-zinc-600 mt-3">
                Assumes no price changes over 5 years. Fitbit Air hardware not included in the 5-year Google Health figure above. If you buy one, add $99.99 to that total.
              </p>
            </motion.div>
          </motion.section>

          {/* Hero Wedges — now comes AFTER table per recon */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Why gym-focused users pick Zealova over Google Health
            </motion.h2>
            <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-4">
              {[
                {
                  title: 'Food photo logging built for real meals',
                  body: "Photograph a single plate or a 10-dish buffet spread. Zealova accepts up to 10 photos per meal and runs 4 analysis modes: auto, plate, menu, and buffet. The AI extracts individual items, calories, macros, and micronutrients per item, then auto-logs everything to your diary. Google Health Coach also supports meal photo logging, but with a single-image flow.",
                  img: '/screenshots/intro_phone_1.png',
                  imgAlt: 'Zealova food photo logging with multi-image input on Android phone',
                },
                {
                  title: 'No hardware required',
                  body: "Google Health's AI Coach is optimized for the Fitbit Air ecosystem. Continuous biometrics like HR, HRV, and sleep stages require a paired compatible wearable. And here's the research context: a 2017 Stanford study found that across 7 wrist-worn devices, energy expenditure error ranged from 27% to 93%. No device came close to accurate calorie burn (Shcherbina et al., 2017, Journal of Personalized Medicine). Heart rate was fine. Calories were not. Zealova runs full-featured on any Android phone and doesn't rely on wearable calorie estimates.",
                  img: null,
                  imgAlt: null,
                },
                {
                  title: 'Full monthly workout plans, not just suggestions',
                  body: "Google Health Coach lets you create custom workouts and get workout suggestions. Zealova generates a complete personalized monthly workout plan based on your goals, equipment, injury history, and schedule. The plan adapts as you complete sessions and log feedback.",
                  img: '/screenshots/intro_phone_2.png',
                  imgAlt: 'Zealova AI-generated monthly workout plan on Android phone',
                },
                {
                  title: '5 specialist sub-agents in one chat',
                  body: "Zealova routes your message to the right specialist automatically: Workout, Nutrition, Injury, Hydration, or General Coach. Ask about a knee injury and the Injury agent finds safe alternatives from the exercise library. Ask about your macros and Nutrition handles it. Google Health's announced AI Coach supports natural-language workout creation, but the launch spec does not mention injury-aware exercise alternatives.",
                  img: '/screenshots/intro_phone_3.png',
                  imgAlt: 'Zealova multi-agent chat coach with 5 specialist sub-agents on Android',
                },
                {
                  title: 'History per exercise and per muscle',
                  body: "Zealova tracks every lift's full history and each muscle group's volume separately. Not just weekly aggregate stats. You can see bench press history, squat history, chest volume, back volume, all individually. Google Health shows workout summaries.",
                  img: '/screenshots/intro_phone_4.png',
                  imgAlt: 'Zealova per-exercise and per-muscle workout history tracking on Android',
                },
                {
                  title: 'Take your data anywhere (10 export formats)',
                  body: "Zealova exports completed workouts to Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, and Parquet. Google Health doesn't offer third-party workout export. If you ever switch apps, your lifting history goes with you.",
                  img: '/screenshots/intro_phone_5.png',
                  imgAlt: 'Zealova workout export options showing 10 formats including Hevy and Fitbod',
                },
              ].map((item) => (
                <motion.div
                  key={item.title}
                  variants={fadeUp}
                  className="bg-zinc-900 border border-zinc-800 rounded-xl p-5"
                >
                  <h3 className="text-base font-semibold text-white mb-2">{item.title}</h3>
                  <p className="text-sm text-zinc-400 leading-relaxed mb-3">{item.body}</p>
                  {item.img && (
                    <img
                      src={item.img}
                      alt={item.imgAlt ?? ''}
                      width={360}
                      height={800}
                      loading="lazy"
                      className="rounded-lg w-full max-w-[200px] mx-auto block object-cover"
                    />
                  )}
                </motion.div>
              ))}
            </motion.div>
          </motion.section>

          {/* Where Zealova wins — trimmed from 9 to 7 bullets per recon (sharper, more defensible) */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Where Zealova wins
            </motion.h2>
            <motion.ul variants={stagger} className="space-y-4">
              {[
                {
                  title: 'No hardware required, and wearable calorie data is less reliable than it looks',
                  detail: "Full AI coaching from day one on any Android phone. No tracker purchase needed. Google Health's AI Coach is optimized for the Fitbit Air ecosystem and needs a paired wearable for continuous biometrics. The broader problem: a 2017 Stanford study (Shcherbina et al., Journal of Personalized Medicine) tested 7 wrist-worn devices including the Fitbit Surge and found no device achieved energy expenditure error below 20%. The best was off by 27%. The worst by 93%. Heart rate was accurate. Calorie burn was not. Zealova doesn't use wearable calorie estimates in its coaching. It uses what you log.",
                },
                {
                  title: 'Multi-image food logging, and adherence is the real bottleneck',
                  detail: "Photograph a single plate, a multi-dish buffet, or anything in between. Zealova accepts up to 10 photos, runs 4 analysis modes, and extracts items, calories, macros, and micronutrients per item. The research case for faster logging: Burke, Wang & Sevick (2011, Journal of the American Dietetic Association) found more frequent self-monitoring was consistently and significantly associated with weight loss. Turner-McGrievy et al. (2019, Journal of the Academy of Nutrition and Dietetics) found tracking frequency explained the most variance in weight loss outcomes (R²=0.27). The point: the app that makes it easier to log daily wins on outcomes, not the one with the most precise algorithm.",
                },
                {
                  title: 'Full AI-generated workout plans, not just suggestions',
                  detail: "Zealova generates a complete personalized monthly plan based on your goals, equipment, injury history, and schedule. Google Health Coach creates workout suggestions and custom workouts via natural language. Those are different things. Structured progressive programming matters: Schoenfeld, Ogborn & Krieger (2017, Journal of Sports Science) found a clear dose-response between weekly training volume and muscle growth. Plans that track and progress your volume per muscle group outperform ad-hoc suggestions over time.",
                },
                {
                  title: 'Injury-aware exercise swaps',
                  detail: "Ask the chat coach about a knee or shoulder issue and it finds safe alternatives from the exercise library. Google Health's announced AI Coach supports natural-language workout creation, but the launch spec does not mention injury-aware exercise alternatives.",
                },
                {
                  title: 'Per-exercise and per-muscle workout history',
                  detail: "Every lift's full history and each muscle group's volume tracked separately. Not just aggregate weekly stats. Google Health shows workout summaries.",
                },
                {
                  title: '40% cheaper annual plan',
                  detail: "$59.99/yr vs $99/yr. That's $39 less per year. Both apps use LLM-based coaches. The difference is the product layer built on top.",
                },
                {
                  title: 'Open data portability (10 export formats)',
                  detail: "Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, Parquet. Google Health doesn't offer third-party workout export. Your lifting history is yours.",
                },
              ].map((item) => (
                <motion.li
                  key={item.title}
                  variants={fadeUp}
                  className="flex gap-4 bg-zinc-900 border border-zinc-800 rounded-xl px-5 py-4"
                >
                  <span className="text-emerald-400 mt-0.5 text-base font-bold shrink-0">+</span>
                  <div>
                    <p className="text-sm font-semibold text-white mb-0.5">{item.title}</p>
                    <p className="text-sm text-zinc-400">{item.detail}</p>
                  </div>
                </motion.li>
              ))}
            </motion.ul>
          </motion.section>

          {/* Where Google Health wins — trimmed from 9 to 7 bullets per recon */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              Where Google Health wins
            </motion.h2>
            <motion.ul variants={stagger} className="space-y-4">
              {[
                {
                  title: 'Continuous biometrics with Fitbit and Pixel Watch',
                  detail: "Heart rate, HRV, SpO2, sleep stages, readiness score, all day. Zealova has no wearable integration. If biometrics matter, Google Health plus a tracker is the stronger option.",
                },
                {
                  title: 'Sleep tracking built in',
                  detail: "Sleep stages, duration, sleep score, and readiness are core to Google Health if you wear a compatible device. Zealova doesn't track sleep.",
                },
                {
                  title: "3-month free trial vs Zealova's 7 days",
                  detail: "Google Health Premium's 3-month trial is significantly longer. You have more time to evaluate before paying. Zealova's trial is 7 days.",
                },
                {
                  title: 'Apple Health, Peloton, MFP, and Strava integrations',
                  detail: "Google Health connects to the apps and devices most fitness users already use. Zealova doesn't offer these third-party integrations currently.",
                },
                {
                  title: 'Available on iOS now',
                  detail: "Google Health is live on iOS. Zealova is Android only right now. iOS is in progress but not yet available in the App Store.",
                },
                {
                  title: '29 million Fitbit users get an automatic upgrade',
                  detail: "If you're already in the Fitbit ecosystem, the transition is automatic. No new account, no data migration. Your existing history carries over.",
                },
                {
                  title: 'Medical records and cycle tracking',
                  detail: "Google Health pulls US medical records into the app and includes menstrual cycle tracking with phase-aware insights. Zealova doesn't have either of these.",
                },
              ].map((item) => (
                <motion.li
                  key={item.title}
                  variants={fadeUp}
                  className="flex gap-4 bg-zinc-900 border border-zinc-800 rounded-xl px-5 py-4"
                >
                  <span className="text-blue-400 mt-0.5 text-base font-bold shrink-0">+</span>
                  <div>
                    <p className="text-sm font-semibold text-white mb-0.5">{item.title}</p>
                    <p className="text-sm text-zinc-400">{item.detail}</p>
                  </div>
                </motion.li>
              ))}
            </motion.ul>
          </motion.section>

          {/* What Fitbit users are frustrated about — NEW section in v4, Hoot exemplar move */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-4">
              What Fitbit users are frustrated about right now
            </motion.h2>
            <motion.div variants={fadeUp} className="bg-zinc-900 border border-zinc-800 rounded-xl p-6 space-y-4">
              <p className="text-sm text-zinc-300 leading-relaxed">
                Google Health launched with a feature removal list that surprised a lot of Fitbit users.
                Gone from the new app: badges, Sleep Profile animals, the community feed, group challenges,
                direct messages between users, snore detection, and unique usernames. These were core to
                why many people stuck with Fitbit over other wearable platforms.
              </p>
              <p className="text-sm text-zinc-300 leading-relaxed">
                The price also went up. Fitbit Premium was $79.99/year. Google Health Premium is $99/year.
                That's a 24% increase at renewal, without new features for users who just wanted the
                existing app to work the same way it always had.
              </p>
              <p className="text-sm text-zinc-300 leading-relaxed">
                Users under 18 and those in unsupported regions are losing Fitbit Premium access entirely
                in the transition. Enterprise Fitbit accounts had to migrate by May 16, 2026 or lose
                data access.
              </p>
              <p className="text-sm text-zinc-400 leading-relaxed">
                If you're frustrated about these changes and you primarily used Fitbit to track your
                workouts and stay accountable to a plan, Zealova is worth a 7-day free trial. It won't
                replace continuous biometric tracking or sleep stages. For that, you still need a
                wearable. But it will generate your gym plan, let you log meals by photo, and give you
                a chat coach that routes to the right specialist automatically.
              </p>
            </motion.div>
          </motion.section>

          {/* Use-case picker */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-2">
              Which one should you pick?
            </motion.h2>
            <motion.p variants={fadeUp} className="text-sm text-zinc-400 mb-6">
              Start here: do you already own a Fitbit or Pixel Watch?
            </motion.p>
            <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-6 mb-6">
              <motion.div
                variants={fadeUp}
                className="bg-emerald-950/30 border border-emerald-900/50 rounded-xl p-6"
              >
                <p className="text-sm font-bold text-emerald-400 mb-4">Pick Zealova if you</p>
                <ul className="space-y-2 text-sm text-zinc-300">
                  {[
                    "Don't own a Fitbit or Pixel Watch and don't want to buy one",
                    'Lift weights and want a full AI-generated monthly workout plan',
                    'Log food by photographing meals, including multi-dish spreads',
                    'Care about tracking each lift and each muscle group separately',
                    'Want to export your workouts to Hevy, Fitbod, or PDF',
                    'Are budget-conscious and want the $59.99/yr plan (40% cheaper than Google Health annual)',
                    'Are leaving the Fitbit ecosystem and want workout-first coaching',
                  ].map((item) => (
                    <li key={item} className="flex gap-2">
                      <span className="text-emerald-400 shrink-0">-</span>
                      {item}
                    </li>
                  ))}
                </ul>
              </motion.div>
              <motion.div
                variants={fadeUp}
                className="bg-blue-950/20 border border-blue-900/40 rounded-xl p-6"
              >
                <p className="text-sm font-bold text-blue-400 mb-4">Pick Google Health if you</p>
                <ul className="space-y-2 text-sm text-zinc-300">
                  {[
                    'Already own a Fitbit or Pixel Watch and want continuous biometrics + sleep tracking',
                    'Care about HRV, readiness scores, or sleep stage analysis',
                    'Want Apple Health, Peloton, MFP, or Strava data in one place',
                    'Are in the Fitbit ecosystem and want the path of least friction',
                    'Trust a Google-branded product with your health data',
                    'Are a US user who wants medical record summaries in-app',
                    'Want iOS support right now',
                  ].map((item) => (
                    <li key={item} className="flex gap-2">
                      <span className="text-blue-400 shrink-0">-</span>
                      {item}
                    </li>
                  ))}
                </ul>
              </motion.div>
            </motion.div>
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900/60 border border-zinc-700 rounded-xl px-5 py-4"
            >
              <p className="text-sm font-semibold text-zinc-300 mb-1">Want both?</p>
              <p className="text-sm text-zinc-400">
                If you want continuous biometrics AND a structured workout plan, run them in parallel during the free trials. Google Health covers sleep and wearable data. Zealova covers gym programming and food logging. They don't overlap much. Try both and cancel whichever doesn't earn its keep by day 7.
              </p>
            </motion.div>
          </motion.section>

          {/* FAQ accordion — expanded to 14 Q/As in v4 */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="mb-14"
          >
            <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
              FAQ
            </motion.h2>
            <motion.div variants={stagger} className="space-y-2">
              {FAQData.map((item, i) => (
                <motion.div
                  key={i}
                  variants={fadeUp}
                  className="border border-zinc-800 rounded-xl overflow-hidden"
                >
                  <button
                    className="w-full text-left px-5 py-4 flex justify-between items-start gap-4 bg-zinc-900 hover:bg-zinc-800/80 transition-colors"
                    onClick={() => setOpenFaq(openFaq === i ? null : i)}
                    aria-expanded={openFaq === i}
                  >
                    <span className="text-sm font-medium text-zinc-200">{item.q}</span>
                    <span className="text-zinc-500 shrink-0 text-lg leading-none">
                      {openFaq === i ? '-' : '+'}
                    </span>
                  </button>
                  {openFaq === i && (
                    <div className="px-5 py-4 bg-zinc-950 border-t border-zinc-800">
                      <p className="text-sm text-zinc-400 leading-relaxed">{item.a}</p>
                    </div>
                  )}
                </motion.div>
              ))}
            </motion.div>
          </motion.section>

          {/* CTA */}
          <motion.section
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true }}
            variants={stagger}
            className="text-center"
          >
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-zinc-800 rounded-2xl p-8 sm:p-12"
            >
              <h2 className="text-2xl sm:text-3xl font-bold text-white mb-3">
                Try Zealova free for 7 days
              </h2>
              <p className="text-zinc-400 text-base mb-4 max-w-md mx-auto">
                No hardware required. Cancel anytime. Android live now, iOS coming soon.
              </p>
              <p className="text-zinc-500 text-sm mb-8 max-w-lg mx-auto">
                Yes, Google Health gives you 3 months free. They need 3 months because biometric
                coaching requires weeks of baseline wearable data before it's useful. Zealova
                generates your first workout plan the night you sign up. You'll know within one
                workout whether the plan fits your schedule and your gym. 7 days is enough.
              </p>
              <img
                src="/screenshots/intro_phone_6.png"
                alt="Zealova AI fitness coach app running on Android phone"
                width={360}
                height={800}
                loading="lazy"
                className="rounded-2xl w-full max-w-[180px] mx-auto block object-cover mb-8"
              />
              <div className="flex flex-col sm:flex-row gap-4 justify-center">
                <a
                  href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
                  target="_blank"
                  rel="noopener noreferrer"
                  className="inline-flex items-center justify-center px-8 py-3.5 rounded-xl bg-emerald-500 hover:bg-emerald-400 text-black font-semibold text-base transition-colors"
                >
                  Download on Android
                </a>
                <Link
                  to="/pricing"
                  className="inline-flex items-center justify-center px-8 py-3.5 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-white font-semibold text-base transition-colors"
                >
                  See pricing
                </Link>
              </div>
            </motion.div>

            {/* Methodology footnote */}
            <p className="text-xs text-zinc-600 mt-8 leading-relaxed max-w-2xl mx-auto">
              Last updated 2026-05-14 by Sai (v6). Google Health pricing verified at store.google.com
              on 2026-05-14. Feature claims sourced from the Google Health launch blog (blog.google,
              published 2026-05-07), Google Health Coach post (blog.google, 2026-05), TechCrunch
              (published 2026-05-07), Fitbit Help Center (support.google.com/fitbit, checked
              2026-05-14), 9to5Google (published 2026-05-07), ghacks.net (published 2026-05-10), and
              piunikaweb.com (published 2026-05-14). Zealova pricing and features current as of
              2026-05-14 per internal product documentation and app router audit
              (_ZEALOVA_FACTS.md v1.3). Research citations: Shcherbina A et al. (2017, Journal of
              Personalized Medicine, doi:10.3390/jpm7020003); Schoenfeld BJ, Ogborn D, Krieger JW
              (2017, Journal of Sports Science 35:11, doi:10.1080/02640414.2016.1210197); Burke LE,
              Wang J, Sevick MA (2011, Journal of the American Dietetic Association 111:1);
              Turner-McGrievy GM et al. (2019, Journal of the Academy of Nutrition and Dietetics
              119:9, doi:10.1016/j.jand.2019.01.004).
            </p>
          </motion.section>

        </main>

        <MarketingFooter />
      </div>
    </>
  );
}
