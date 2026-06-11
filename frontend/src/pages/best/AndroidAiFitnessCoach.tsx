/**
 * /android-ai-fitness-coach
 * Mode C segment page — "Best AI Fitness Coach for Android (2026)"
 * Strategic context: WWDC June 8 2026 is expected to preview Apple Health+.
 * Apple Health+ requires iPhone + Apple Watch. This page captures Android users
 * searching for an alternative BEFORE that news cycle peaks.
 *
 * Competitor pricing verified 2026-05-20:
 *   Google Health Premium: $9.99/mo or $99/yr (store.google.com, launched 2026-05-19)
 *   Apple Health+: iPhone + Apple Watch required; not yet launched as of 2026-05-20
 *   Fitbit Premium (now Google Health): $9.99/mo or $99/yr (became Google Health 2026-05-19)
 *   Fitbod: $15.99/mo or $95.99/yr (verified arvo.guru/vs/fitbod, 2026-05-15)
 *   Zealova: $7.99/mo or $59.99/yr (Google Play, verified 2026-05-14)
 *
 * §2G reliability hold: form video analysis, in-workout chat, recipe import,
 * audio coach, MFP OCR all omitted. Menu scan is §2B Core — included.
 *
 * Asset manifest (2026-05-20):
 * -----------------------------------------------------------------
 * Slot              | Status            | Path
 * -----------------------------------------------------------------
 * hero_og           | NEEDS NEW         | /screenshots/og-android-ai-fitness-coach.png (1200x630)
 * answer_capsule    | use intro_phone_1 | /screenshots/intro_phone_1.png (1080x2400)
 * food_logging      | use intro_phone_2 | /screenshots/intro_phone_2.png (1080x2400)
 * workout_ai        | use intro_phone_3 | /screenshots/intro_phone_3.png (1080x2400)
 * multiagent_chat   | use intro_phone_4 | /screenshots/intro_phone_4.png (1080x2400)
 * workout_history   | use intro_phone_5 | /screenshots/intro_phone_5.png (1080x2400)
 * cta_visual        | use intro_phone_6 | /screenshots/intro_phone_6.png (1080x2400)
 * -----------------------------------------------------------------
 * NEEDS NEW: og-android-ai-fitness-coach.png (1200x630 OG card, green Android
 * phone silhouette + Zealova logo). Flag for Sai.
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
  { id: 'tldr', label: 'TL;DR comparison' },
  { id: 'comparison', label: 'Feature comparison' },
  { id: 'why-no-wearable', label: 'Why no wearable needed' },
  { id: 'zealova-wins', label: 'Where Zealova wins' },
  { id: 'honest-limits', label: 'Honest limits' },
  { id: 'which-to-pick', label: 'Which to pick' },
  { id: 'faq', label: 'FAQ' },
];

const CANONICAL_URL = `https://${BRANDING.marketingDomain}/android-ai-fitness-coach`;
const OG_IMAGE = `/screenshots/intro_phone_1.png`; // NEEDS NEW: og-android-ai-fitness-coach.png 1200x630

const FAQData = [
  {
    q: 'Is there a good AI fitness app for Android in 2026?',
    a: "Yes. Zealova is an AI fitness coach built for Android, available on Google Play now. It generates personalized monthly workout plans, logs food from photos and restaurant menus, and runs a 5-agent chat coach across workout, nutrition, injury, hydration, and general coaching. No wearable required. $7.99/month or $59.99/year with a 7-day free trial.",
  },
  {
    q: 'Do I need a smartwatch or fitness tracker to use an AI fitness app?',
    a: "No. Zealova runs full-featured on any Android phone. No Fitbit, Pixel Watch, Apple Watch, or Garmin required. Google Health Premium is optimized for Fitbit and Pixel Watch users. Apple Health+ (expected to require an Apple Watch) will not be available for Android at all. Zealova requires only the phone you already own.",
  },
  {
    q: 'What is the best AI workout app for Android without Apple Watch?',
    a: "Zealova is built Android-first and has no wearable requirement. It generates full personalized monthly workout plans, lets you log meals by photographing food or a restaurant menu, and has a multi-agent chat coach. For pure strength programming without nutrition, Fitbod ($15.99/mo, Android) is the leading alternative. For a free option, Hevy tracks workouts but does not generate plans.",
  },
  {
    q: 'Is Zealova free?',
    a: "Zealova offers a 7-day free trial with all premium features included. After the trial it costs $7.99/month or $59.99/year (about $5/month). There is no permanent free tier. The 7-day window is enough to generate and complete your first workout plan.",
  },
  {
    q: 'What is Apple Health+ and does it work on Android?',
    a: "Apple Health+ is Apple's AI coaching service expected to be announced at WWDC 2026 (June 8) and tied to iOS and Apple Watch. Based on reporting from Wareable and MacRumors, it will live inside Apple Health on iPhone and require an Apple Watch for biometric coaching. It will not be available for Android. Zealova is the Android-native alternative.",
  },
  {
    q: 'How does Google Health compare to Zealova for Android users?',
    a: "Google Health Premium launched May 19, 2026 at $9.99/month or $99/year. Its AI Coach is optimized for Fitbit and Pixel Watch users. Without one of those devices, you get a partial experience. Zealova runs full-featured on any Android phone at $7.99/month or $59.99/year, with no hardware requirement. Zealova is 40% cheaper on the annual plan and generates full monthly workout plans that Google Health does not.",
  },
  {
    q: 'Can I log food by taking photos on Android fitness apps?',
    a: "Yes. Zealova supports food photo logging on Android. Photograph a plated meal, a buffet spread (up to 10 photos), or a restaurant menu. The AI extracts individual items, calories, macros, and micronutrients per item and logs them to your diary. Google Health also supports meal photo logging with a single-image flow.",
  },
  {
    q: 'What happened to Fitbit Premium?',
    a: "Fitbit Premium officially became Google Health Premium on May 19, 2026. The price increased from $79.99/year to $99/year. Fitbit's social features, badges, sleep animals, and community forums were removed in the transition. If you were a Fitbit Premium user primarily using it for gym tracking, Zealova is a workout-first alternative at $59.99/year.",
  },
];

const comparisonRows = [
  { feature: 'Platforms', zealova: 'Android (iOS coming)', google: 'Android + iOS', apple: 'iPhone + Apple Watch only', fitbod: 'iOS + Android' },
  { feature: 'Wearable required', zealova: 'No', google: 'Fitbit / Pixel Watch for full AI coach', apple: 'Apple Watch (expected)', fitbod: 'No' },
  { feature: 'Monthly price', zealova: '$7.99/mo', google: '$9.99/mo', apple: 'Not yet announced', fitbod: '$15.99/mo' },
  { feature: 'Annual price', zealova: '$59.99/yr', google: '$99/yr', apple: 'Not yet announced', fitbod: '$95.99/yr' },
  { feature: 'Free trial', zealova: '7 days (all features)', google: '3 months (new users)', apple: 'Unknown', fitbod: '3 workouts free' },
  { feature: 'AI workout plan generation (full monthly plan)', zealova: 'yes', google: 'no', apple: 'partial', fitbod: 'yes' },
  { feature: 'Food photo logging (AI calorie estimate)', zealova: 'yes', google: 'yes', apple: 'via Apple Health integrations', fitbod: 'no' },
  { feature: 'Multi-image meal input (up to 10 photos, 4 modes)', zealova: 'yes', google: 'no', apple: 'unknown', fitbod: 'no' },
  { feature: 'Restaurant menu scan', zealova: 'yes', google: 'no', apple: 'unknown', fitbod: 'no' },
  { feature: 'Multi-agent chat coach (5 specialist sub-agents)', zealova: 'yes', google: 'no', apple: 'unknown', fitbod: 'no' },
  { feature: 'Injury-aware exercise swaps via chat', zealova: 'yes', google: 'no', apple: 'unknown', fitbod: 'no' },
  { feature: 'Per-exercise + per-muscle workout history', zealova: 'yes', google: 'no', apple: 'partial (via Health app)', fitbod: 'yes' },
  { feature: '3rd-party workout export (10 formats)', zealova: 'yes', google: 'no', apple: 'no', fitbod: 'partial (CSV only)' },
  { feature: 'Custom exercises + AI-assisted import', zealova: 'yes', google: 'no', apple: 'no', fitbod: 'partial' },
  { feature: 'Supersets', zealova: 'yes', google: 'no', apple: 'unknown', fitbod: 'yes' },
  { feature: 'Gym equipment profiles', zealova: 'yes', google: 'no', apple: 'via Health app', fitbod: 'yes' },
  { feature: 'Sleep tracking', zealova: 'no', google: 'yes', apple: 'yes (Apple Watch)', fitbod: 'no' },
  { feature: 'Continuous biometric tracking (HR, HRV)', zealova: 'no', google: 'yes (with Fitbit/Pixel Watch)', apple: 'yes (Apple Watch)', fitbod: 'no' },
  { feature: 'Health Connect (Android)', zealova: 'yes', google: 'yes', apple: 'no', fitbod: 'partial' },
  { feature: 'Available on Android right now', zealova: 'yes', google: 'yes', apple: 'no', fitbod: 'yes' },
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
    'AI fitness coach for Android. Generates personalized monthly workout plans, logs food from photos and restaurant menus, and runs a 5-agent chat coach. No wearable required. $7.99/month or $59.99/year.',
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
    { '@type': 'ListItem', position: 2, name: 'Best AI Fitness Coach for Android (2026)', item: CANONICAL_URL },
  ],
};

export default function AndroidAiFitnessCoach() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  useEffect(() => {
    document.title = 'Best AI Fitness Coach for Android (2026): No Apple Watch Needed | Zealova';

    const descContent =
      'Apple Health+ requires iPhone and Apple Watch. Google Health needs Fitbit or Pixel Watch. Zealova is the AI fitness coach built for Android, no wearable required. Free 7-day trial.';

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
      'og:title': 'Best AI Fitness Coach for Android (2026): No Apple Watch Needed',
      'og:description': descContent,
      'og:url': CANONICAL_URL,
      'og:image': `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
      'og:type': 'article',
      'twitter:card': 'summary_large_image',
      'twitter:title': 'Best AI Fitness Coach for Android (2026): No Apple Watch Needed',
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

      <ArticleLayout slug="android-ai-fitness-coach" sections={SECTIONS}>

        {/* Breadcrumb */}
        <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
          <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
          <span className="mx-2">/</span>
          <span className="text-zinc-400">Best AI Fitness Coach for Android (2026)</span>
        </nav>

        {/* Answer capsule — first ~200 words, LLM-quote target */}
        <motion.section
          id="answer"
          initial="hidden"
          animate="visible"
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.div variants={fadeUp}>
            <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
              Published 2026-05-20. Pricing verified 2026-05-19.
            </p>
            <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
              Best AI Fitness Coach for Android (2026): No Apple Watch Needed
            </h1>
          </motion.div>

          <motion.div
            variants={fadeUp}
            className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-6"
          >
            <div className="flex flex-col sm:flex-row gap-6 mb-4">
              <div className="flex-1">
                <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                  Most AI fitness apps in 2026 require hardware you don't own. Apple Health+
                  (expected at WWDC June 8, 2026) ties AI coaching to iPhone and Apple Watch.
                  It will not run on Android. Google Health Premium launched May 19, 2026 at
                  $9.99/month and is built around Fitbit and Pixel Watch. Without one of those
                  devices, its AI Coach works in a limited mode. Fitbod ($15.99/month) is strong
                  for workout programming but has no nutrition tracking.
                </p>
                <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
                  Zealova is built for Android and requires only your phone. No tracker purchase
                  required. It generates personalized monthly workout plans, logs food from
                  photos of meals and restaurant menus, and routes your questions through 5
                  specialist AI sub-agents: Workout, Nutrition, Injury, Hydration, and Coach.
                  It costs $7.99/month or $59.99/year, with a 7-day free trial.
                </p>
                <p className="text-zinc-200 text-base sm:text-lg leading-relaxed">
                  The short verdict: if you own an Android phone and don't plan to buy a
                  wearable, Zealova covers workout generation, food photo logging, and menu
                  scan in one app, at a price below every alternative here.
                </p>
              </div>
              <div className="shrink-0 flex justify-center sm:justify-end">
                <img
                  src="/screenshots/intro_phone_1.png"
                  alt="Zealova AI fitness coach home screen on Android phone"
                  width={160}
                  height={356}
                  loading="eager"
                  className="rounded-2xl object-cover"
                />
              </div>
            </div>

            <div className="grid sm:grid-cols-2 gap-4 pt-4 border-t border-zinc-800">
              <div className="bg-emerald-950/40 border border-emerald-900/50 rounded-xl p-4">
                <p className="text-sm font-semibold text-emerald-400 mb-1">Pick Zealova if</p>
                <p className="text-sm text-zinc-300">
                  you use Android and want AI workout plans, food photo logging, and menu scan
                  in one app with no hardware requirement.
                </p>
              </div>
              <div className="bg-blue-950/30 border border-blue-900/40 rounded-xl p-4">
                <p className="text-sm font-semibold text-blue-400 mb-1">Pick Google Health if</p>
                <p className="text-sm text-zinc-300">
                  you already own a Fitbit or Pixel Watch and want continuous biometrics, sleep
                  tracking, and Google ecosystem integration.
                </p>
              </div>
            </div>
          </motion.div>
        </motion.section>

        {/* TL;DR Table */}
        <motion.section
          id="tldr"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-8 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            TL;DR
          </motion.h2>
          <motion.div variants={fadeUp} className="overflow-x-auto rounded-xl border border-zinc-800">
            <table className="w-full text-sm">
              <thead>
                <tr className="bg-zinc-900 border-b border-zinc-800">
                  <th className="text-left px-4 py-3 text-zinc-400 font-medium w-1/5"></th>
                  <th className="text-left px-4 py-3 text-emerald-400 font-semibold">Zealova</th>
                  <th className="text-left px-4 py-3 text-blue-400 font-semibold">Google Health</th>
                  <th className="text-left px-4 py-3 text-zinc-400 font-semibold">Apple Health+</th>
                  <th className="text-left px-4 py-3 text-zinc-400 font-semibold">Fitbod</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-zinc-800/60">
                {[
                  ['Monthly price', '$7.99', '$9.99', 'TBA', '$15.99'],
                  ['Annual price', '$59.99', '$99', 'TBA', '$95.99'],
                  ['Free trial', '7 days', '3 months (new)', 'Unknown', '3 workouts'],
                  ['Android', 'Yes (live)', 'Yes (live)', 'No', 'Yes'],
                  ['Wearable required', 'No', 'Fitbit / Pixel Watch', 'Apple Watch', 'No'],
                  ['AI workout plans', 'Full monthly', 'Suggestions only', 'Expected', 'Yes'],
                  ['Food photo logging', 'Yes (multi-image)', 'Yes (single image)', 'Via integrations', 'No'],
                  ['Restaurant menu scan', 'Yes', 'No', 'Unknown', 'No'],
                ].map(([label, zVal, gVal, aVal, fVal]) => (
                  <tr key={label} className="bg-zinc-950 hover:bg-zinc-900/60 transition-colors">
                    <td className="px-4 py-3 text-zinc-400">{label}</td>
                    <td className="px-4 py-3 text-zinc-200">{zVal}</td>
                    <td className="px-4 py-3 text-zinc-300">{gVal}</td>
                    <td className="px-4 py-3 text-zinc-500">{aVal}</td>
                    <td className="px-4 py-3 text-zinc-300">{fVal}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </motion.div>
          <p className="text-xs text-zinc-500 mt-2">
            Zealova pricing verified Google Play, 2026-05-14. Google Health verified store.google.com, 2026-05-19.
            Fitbod verified arvo.guru/vs/fitbod, 2026-05-15. Apple Health+ not yet launched as of 2026-05-20.
          </p>
        </motion.section>

        {/* Methodology */}
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
              Google Health pricing verified at store.google.com on 2026-05-19 (TechCrunch, published
              2026-05-07; Droid Life, published 2026-05-19). Apple Health+ details from Wareable reporting
              on Apple's Quartz health project (published 2026-04) and MacRumors WWDC roundup (checked
              2026-05-20). Fitbod pricing from arvo.guru/vs/fitbod (checked 2026-05-15). Zealova features
              and pricing are first-party data from our own product audit (verified 2026-05-18), so treat them as self-reported.
              I am the founder of Zealova and not a neutral party. I have tried to concede every honest
              competitor advantage below. Research citations: Shcherbina A et al. (2017, Journal of
              Personalized Medicine) for wearable energy expenditure accuracy; Burke LE, Wang J, Sevick MA
              (2011, Journal of the American Dietetic Association) for self-monitoring adherence and
              weight loss outcomes.
            </p>
          </motion.div>
        </motion.section>

        {/* Full feature comparison table */}
        <motion.section
          id="comparison"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
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
                  <th className="text-left px-4 py-3 text-zinc-400 font-semibold">Apple Health+</th>
                  <th className="text-left px-4 py-3 text-zinc-400 font-semibold">Fitbod</th>
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
                    <td className={`px-4 py-3 ${getCellClass(row.apple)}`}>
                      {getCellDisplay(row.apple)}
                    </td>
                    <td className={`px-4 py-3 ${getCellClass(row.fitbod)}`}>
                      {getCellDisplay(row.fitbod)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </motion.div>
          <p className="text-xs text-zinc-500 mt-2">
            Partial or "unknown" = feature either has meaningful limitations or has not been confirmed
            for Apple Health+ (not yet launched). Apple Health+ rows marked "expected" are based on
            pre-launch reporting, not confirmed specs. Sources: Google Health launch blog (blog.google,
            2026-05-07), TechCrunch (2026-05-07), MacRumors WWDC roundup (2026-05-20).
          </p>
        </motion.section>

        {/* Why no wearable required */}
        <motion.section
          id="why-no-wearable"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            Why no wearable required
          </motion.h2>
          <motion.div variants={stagger} className="space-y-4">
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-zinc-800 rounded-xl p-6"
            >
              <h3 className="text-base font-semibold text-white mb-2">
                Wearable calorie data is less useful than it looks
              </h3>
              <p className="text-sm text-zinc-400 leading-relaxed">
                A 2017 Stanford study tested 7 wrist-worn devices including Fitbit and Apple Watch
                and found calorie burn error ranged from 27% to 93% across all devices tested. Not
                one came within 20% of accurate energy expenditure (Shcherbina et al., 2017,
                Journal of Personalized Medicine). Heart rate was reasonably accurate. Calorie burn
                was not. Zealova doesn't use wearable calorie estimates in its coaching. It works
                from what you log: your meals, your completed sets, your weight trend.
              </p>
            </motion.div>
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-zinc-800 rounded-xl p-6"
            >
              <h3 className="text-base font-semibold text-white mb-2">
                The phone camera is already a better logging tool than a wrist sensor
              </h3>
              <p className="text-sm text-zinc-400 leading-relaxed">
                Photograph a meal and get instant calorie and macro estimates per item. Scan a
                restaurant menu and see calorie counts for each dish before ordering. You don't
                need step data or passive HR monitoring to build a better body. You need to know
                what you're eating and follow a progressive workout plan. A camera handles the
                first. Zealova generates the second.
              </p>
              <img
                src="/screenshots/intro_phone_2.png"
                alt="Zealova food photo logging showing AI calorie analysis on Android"
                width={200}
                height={444}
                loading="lazy"
                className="rounded-xl mt-4 mx-auto block object-cover"
              />
            </motion.div>
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900 border border-zinc-800 rounded-xl p-6"
            >
              <h3 className="text-base font-semibold text-white mb-2">
                Logging adherence matters more than logging precision
              </h3>
              <p className="text-sm text-zinc-400 leading-relaxed">
                Research by Burke, Wang and Sevick (2011, Journal of the American Dietetic
                Association) found that more frequent self-monitoring was consistently and
                significantly associated with weight loss. The friction that breaks logging
                habits is not inaccuracy. It's the time it takes to log. Photo logging from
                your existing phone removes that friction. Buying and syncing a wearable adds it.
              </p>
            </motion.div>
          </motion.div>
        </motion.section>

        {/* Where Zealova wins */}
        <motion.section
          id="zealova-wins"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            Where Zealova wins
          </motion.h2>
          <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-4">
            {[
              {
                title: 'Full monthly workout plan generation',
                body: "Zealova generates a complete personalized monthly workout plan based on your goals, equipment, schedule, and injury history. Google Health Coach provides workout suggestions and lets you build custom workouts via natural language. Fitbod generates next-session workouts based on your logged history. Those are three different things. A full monthly plan gives you structure across 4-5 weeks, not just tonight's session.",
                img: '/screenshots/intro_phone_3.png',
                imgAlt: 'Zealova AI-generated monthly workout plan on Android',
              },
              {
                title: 'Food photo logging with menu scan',
                body: "Photograph a single plate or a 10-dish buffet spread across up to 10 photos. The AI extracts individual items, calories, macros, and micronutrients per item in 4 analysis modes: auto, plate, menu, and buffet. Scan a restaurant menu before you order and see calorie estimates per dish. Google Health supports single-image meal logging. Fitbod has no nutrition tracking at all.",
                img: null,
                imgAlt: null,
              },
              {
                title: '5-agent multi-agent chat coach',
                body: "Zealova routes your question to the right specialist: Workout (exercise swaps, plan changes), Nutrition (macros, meal advice), Injury (safe alternatives when something hurts), Hydration, or general Coach. Ask about a shoulder issue and the Injury agent finds safe alternatives from the exercise library. No other app here matches this routing depth on Android.",
                img: '/screenshots/intro_phone_4.png',
                imgAlt: 'Zealova multi-agent chat coach with 5 specialist AI agents on Android',
              },
              {
                title: 'Per-exercise and per-muscle history',
                body: "Pull up any lift and see its full history: weight, reps, sets, volume across every session. Pull up any muscle group and see its weekly volume. This is the data layer that makes progressive overload visible. Schoenfeld, Ogborn and Krieger (2017, Journal of Sports Science) found a clear dose-response between weekly training volume and hypertrophy. Zealova makes that volume trackable per muscle, not just in total.",
                img: '/screenshots/intro_phone_5.png',
                imgAlt: 'Zealova per-exercise and per-muscle workout history on Android',
              },
              {
                title: '40% cheaper annual plan, no hardware cost',
                body: "Zealova is $59.99/year. Google Health Premium is $99/year. Full Google Health functionality also needs a Fitbit or Pixel Watch, which starts at $99.99 for the Fitbit Air. That's a $139 gap in year one. Fitbod is $95.99/year and has no nutrition tracking. Zealova covers workout generation, food photo logging, and menu scan in one plan.",
                img: null,
                imgAlt: null,
              },
              {
                title: 'Open data portability (10 export formats)',
                body: "Export your completed workouts to Hevy, Strong, Fitbod, CSV, JSON, XLSX, PDF, TCX, GPX, or Parquet. Google Health has no third-party workout export. Fitbod exports CSV only. Your lifting history belongs to you.",
                img: null,
                imgAlt: null,
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
                    className="rounded-lg w-full max-w-[180px] mx-auto block object-cover"
                  />
                )}
              </motion.div>
            ))}
          </motion.div>
        </motion.section>

        {/* Honest limits */}
        <motion.section
          id="honest-limits"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            Honest limits of Zealova
          </motion.h2>
          <motion.ul variants={stagger} className="space-y-4">
            {[
              {
                title: 'No iOS app yet',
                detail: "Zealova is live on Android. iOS is in development but not yet available in the App Store. If you use iPhone, your current option here is Google Health or Fitbod. Zealova iOS is in progress.",
              },
              {
                title: 'No wearable biometric tracking',
                detail: "Zealova doesn't track HR, HRV, SpO2, sleep stages, or readiness scores. There is no Apple Watch, Fitbit, or Garmin integration. If passive biometric monitoring matters to you, Google Health is the better choice.",
              },
              {
                title: 'No sleep tracking',
                detail: "Zealova doesn't track sleep. Google Health and Fitbit do, with detailed sleep stage analysis via compatible hardware.",
              },
              {
                title: 'No third-party integrations (Peloton, Strava, Apple Health)',
                detail: "Zealova doesn't connect to Peloton, Strava, Apple Health, or MyFitnessPal. Google Health does. If you're already invested in one of those ecosystems, Zealova doesn't import your existing data automatically.",
              },
              {
                title: '7-day trial vs Google Health\'s 3-month trial',
                detail: "Google Health Premium gives new users a 3-month trial. Zealova's trial is 7 days. Google Health needs months to collect enough wearable data for its AI to be useful. Zealova generates your first workout plan the night you sign up. 7 days is usually enough to know if it fits.",
              },
            ].map((item) => (
              <motion.li
                key={item.title}
                variants={fadeUp}
                className="flex gap-4 bg-zinc-900 border border-zinc-800 rounded-xl px-5 py-4"
              >
                <span className="text-amber-400 mt-0.5 text-base font-bold shrink-0">!</span>
                <div>
                  <p className="text-sm font-semibold text-white mb-0.5">{item.title}</p>
                  <p className="text-sm text-zinc-400">{item.detail}</p>
                </div>
              </motion.li>
            ))}
          </motion.ul>
        </motion.section>

        {/* Use-case picker */}
        <motion.section
          id="which-to-pick"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-2">
            Which one should you pick?
          </motion.h2>
          <motion.p variants={fadeUp} className="text-sm text-zinc-400 mb-6">
            Start here: do you already own an Android phone without a paired wearable?
          </motion.p>
          <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-6 mb-6">
            <motion.div
              variants={fadeUp}
              className="bg-emerald-950/30 border border-emerald-900/50 rounded-xl p-6"
            >
              <p className="text-sm font-bold text-emerald-400 mb-4">Pick Zealova if you</p>
              <ul className="space-y-2 text-sm text-zinc-300">
                {[
                  "Use Android and don't own a Fitbit, Pixel Watch, or Apple Watch",
                  'Want AI-generated monthly workout plans, not just exercise suggestions',
                  'Log food by photographing meals, menus, or restaurant dishes',
                  'Want to modify your workout plan via chat when you get an injury',
                  'Care about per-exercise history and per-muscle volume tracking',
                  'Want to export workouts to Hevy, Fitbod, Strong, or CSV',
                  'Want the lowest annual price ($59.99/yr) across these options',
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
                  'Already own a Fitbit or Pixel Watch and want continuous biometrics',
                  'Care about sleep stages, HRV, readiness scores, and recovery tracking',
                  'Want Peloton, Strava, Apple Health, or MFP data in one place',
                  'Are an existing Fitbit user and want a path of least friction',
                  'Want iOS support right now',
                  'Prefer a 3-month free trial to evaluate before paying',
                ].map((item) => (
                  <li key={item} className="flex gap-2">
                    <span className="text-blue-400 shrink-0">-</span>
                    {item}
                  </li>
                ))}
              </ul>
            </motion.div>
          </motion.div>
          <motion.div variants={stagger} className="grid sm:grid-cols-2 gap-6">
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900/60 border border-zinc-700 rounded-xl p-6"
            >
              <p className="text-sm font-bold text-zinc-300 mb-4">Pick Fitbod if you</p>
              <ul className="space-y-2 text-sm text-zinc-400">
                {[
                  'Only want strength programming and care nothing about nutrition',
                  'Want the most data-driven progressive overload algorithm available',
                  'Already use MyFitnessPal or another nutrition app separately',
                ].map((item) => (
                  <li key={item} className="flex gap-2">
                    <span className="text-zinc-500 shrink-0">-</span>
                    {item}
                  </li>
                ))}
              </ul>
            </motion.div>
            <motion.div
              variants={fadeUp}
              className="bg-zinc-900/40 border border-zinc-800 rounded-xl p-6"
            >
              <p className="text-sm font-bold text-zinc-500 mb-4">Wait on Apple Health+ if you</p>
              <ul className="space-y-2 text-sm text-zinc-500">
                {[
                  'Use iPhone and own an Apple Watch',
                  'Want Apple\'s full health data integration (ECG, Blood Oxygen, crash detection)',
                  'Are willing to wait for a confirmed launch post-WWDC June 2026',
                ].map((item) => (
                  <li key={item} className="flex gap-2">
                    <span className="shrink-0">-</span>
                    {item}
                  </li>
                ))}
              </ul>
            </motion.div>
          </motion.div>
        </motion.section>

        {/* FAQ */}
        <motion.section
          id="faq"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
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
              No hardware required. Android live now. Cancel anytime.
            </p>
            <p className="text-zinc-500 text-sm mb-8 max-w-lg mx-auto">
              Yes, Google Health gives new users 3 months free. They need 3 months because
              wearable-based AI coaching takes weeks to collect a useful baseline. Zealova
              generates your first workout plan the night you sign up. You'll know within
              one session whether it fits your schedule and your gym. 7 days is enough.
            </p>
            <img
              src="/screenshots/intro_phone_6.png"
              alt="Zealova AI fitness coach workout screen on Android phone"
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
            Last updated 2026-05-20 by Sai. Google Health pricing verified at store.google.com
            on 2026-05-19. Google Health Coach features sourced from TechCrunch (published 2026-05-07)
            and Google Health blog (blog.google, 2026-05-07). Apple Health+ details based on
            Wareable reporting on Apple Quartz project (2026-04) and MacRumors WWDC roundup
            (checked 2026-05-20); not yet launched, rows marked accordingly. Fitbod pricing
            verified arvo.guru/vs/fitbod (2026-05-15). Zealova pricing and features current as of
            2026-05-14, first-party and self-reported. Research: Shcherbina A et al. (2017, Journal
            of Personalized Medicine, doi:10.3390/jpm7020003); Burke LE, Wang J, Sevick MA (2011,
            Journal of the American Dietetic Association 111:1); Schoenfeld BJ, Ogborn D, Krieger
            JW (2017, Journal of Sports Science 35:11, doi:10.1080/02640414.2016.1210197).
          </p>
        </motion.section>

      </ArticleLayout>
    </>
  );
}
