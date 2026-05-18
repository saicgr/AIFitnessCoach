/**
 * /blog/google-health-coach-hallucination: original-data + technical explainer post
 *
 * Angle: factual recap of Google Health Coach inventing a 5-mile run (published 2026-05-14,
 * Android Authority / 9to5Google), then a technical explainer on WHY general-purpose
 * AI fitness products hallucinate workout data, contrasted with Zealova's grounding approach.
 * Concedes Google Health's genuine strengths. Does not overclaim Zealova immunity.
 *
 * Asset manifest (2026-05-18):
 * -------------------------------------------------------------------------
 * Slot              | Status             | Path
 * -------------------------------------------------------------------------
 * hero_og           | NEEDS NEW          | /screenshots/og-blog-hallucination.png (1200x630)
 * in_content_hero   | use intro_phone_2  | /screenshots/intro_phone_2.png (1080x2400)
 * supporting_1      | use intro_phone_4  | /screenshots/intro_phone_4.png (1080x2400)
 * supporting_2      | NEEDS NEW          | chart-grounding-vs-general-llm.png (diagram)
 * -------------------------------------------------------------------------
 *
 * SEO target: "google health coach hallucination" + "why AI fitness apps hallucinate"
 * Intent: Informational / Research
 * Last updated: 2026-05-18 by Sai
 */

import { useState } from 'react';
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

const SLUG = 'blog/google-health-coach-hallucination';
const CANONICAL_URL = `https://${BRANDING.marketingDomain}/${SLUG}`;
const OG_IMAGE = `/screenshots/og-blog-hallucination.png`; // NEEDS NEW: generate 1200x630

const SECTIONS = [
  { id: 'what-happened', label: 'What happened' },
  { id: 'key-stats', label: 'Key takeaways' },
  { id: 'why-it-happens', label: 'Why AI fitness apps hallucinate' },
  { id: 'aggregator-problem', label: 'The aggregator problem' },
  { id: 'how-grounding-helps', label: 'How grounding helps' },
  { id: 'where-google-wins', label: 'Where Google Health still wins' },
  { id: 'faq', label: 'FAQ' },
];

const FAQData = [
  {
    q: 'What exactly did Google Health Coach hallucinate?',
    a: "According to Android Authority (published 2026-05-14), Google's Health Coach told reviewer Will Sattelberg of 9to5Google that he had completed a 5-mile run he never actually took. The coach referenced the phantom run as if it were real, grounded data. When Sattelberg challenged the claim, the coach acknowledged the error but then suggested he might have simply forgotten to record the run, effectively blaming the user for the AI's fabrication.",
  },
  {
    q: 'Is this a Google-specific problem or a general AI problem?',
    a: "It is a general AI problem that affects any fitness app using a large language model without tight grounding to the user's actual logged data. LLMs are trained to produce plausible-sounding outputs. When the prompt includes an instruction like 'summarize the user's recent activity', the model fills gaps in the context with statistically likely activity patterns rather than refusing to answer. Google's system is not uniquely flawed. It ran into the same architecture problem that any general-purpose AI coach faces when its retrieved context is incomplete.",
  },
  {
    q: 'Does Zealova hallucinate workout data?',
    a: "Zealova uses LLMs and LLMs can hallucinate. The distinction is not immunity. It is data grounding. Zealova's workout plan generator and chat coach receive the user's actual logged workout history as structured context before any AI call. The model is asked to reason about real data, not infer it. That does not eliminate hallucination, but it removes the specific failure mode of fabricating activity: there is no gap to fill because the history is in the prompt. Zealova can still hallucinate exercise recommendations, form cues, or nutritional estimates, and those are genuine limitations to be aware of.",
  },
  {
    q: 'What is data grounding in AI fitness apps?',
    a: "Grounding means attaching real, verified data to the context window before the model generates a response. In fitness, that means the AI reads your actual logged sets, reps, weights, and timestamps before answering a question about your training. An ungrounded model is asked to reason about a user it knows little about and fills the gap with plausible-sounding output. A grounded model is asked to reason about specific data. Research on RAG (retrieval-augmented generation) systems shows grounding reduces hallucinations by 42-68% compared to prompting the model with no retrieved context (neuledge.com, February 2026).",
  },
  {
    q: 'Why do large-scale health apps struggle with this more than smaller focused apps?',
    a: "Large aggregators pull from many data sources: wearable steps, inferred calorie burn, connected third-party apps, manual logs, and health records. The more sources, the more opportunities for missing, conflicting, or low-quality data to enter the context. A focused app that only tracks what a user explicitly logs has a cleaner, more verifiable context to give the model. That does not make it better at everything, but it does make the grounding more reliable for the specific domain it covers.",
  },
  {
    q: 'Should I trust AI fitness app workout summaries?',
    a: "Cross-check any AI summary against your raw logged data, especially for anything that sounds surprising. This applies to Google Health, Zealova, and any other AI fitness coach. If the coach references an activity you do not remember doing, check the source: did your phone step counter infer it, did a connected app log it, or did the AI fabricate it? The fastest check is to pull your actual workout log and compare. For critical decisions like injury recovery load management, always verify the numbers yourself.",
  },
  {
    q: 'Is Google Health a bad app because of this incident?',
    a: "No. Google Health is genuinely strong on wearable biometrics, sleep tracking, Apple Health integration, MFP connectivity, and ecosystem breadth. The hallucination issue is a real limitation worth knowing about, not a reason to dismiss the app entirely. The honest recommendation: cross-check AI summaries against your actual data regardless of which app you use, and weight your trust in AI summaries by how explicitly the app shows you the source of each data point.",
  },
];

const jsonLdBlogPosting = {
  '@context': 'https://schema.org',
  '@type': 'BlogPosting',
  headline: "Google Health Coach Invented a Workout. Here's Why AI Fitness Apps Do This.",
  description:
    "Google's AI Health Coach fabricated a 5-mile run that never happened. A technical explainer on why general-purpose AI fitness products hallucinate workout data, and what data grounding actually means.",
  image: `https://${BRANDING.marketingDomain}${OG_IMAGE}`,
  author: {
    '@type': 'Person',
    name: 'Sai',
    url: `https://${BRANDING.marketingDomain}/about`,
  },
  publisher: {
    '@type': 'Organization',
    name: 'Zealova',
    url: `https://${BRANDING.marketingDomain}`,
  },
  datePublished: '2026-05-18',
  dateModified: '2026-05-18',
  mainEntityOfPage: CANONICAL_URL,
  url: CANONICAL_URL,
};

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

const jsonLdBreadcrumb = {
  '@context': 'https://schema.org',
  '@type': 'BreadcrumbList',
  itemListElement: [
    { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}` },
    { '@type': 'ListItem', position: 2, name: 'Blog', item: `https://${BRANDING.marketingDomain}/blog` },
    {
      '@type': 'ListItem',
      position: 3,
      name: "Google Health Coach Invented a Workout. Here's Why AI Fitness Apps Do This.",
      item: CANONICAL_URL,
    },
  ],
};

export default function GoogleHealthHallucination() {
  const [openFaq, setOpenFaq] = useState<number | null>(null);

  // Set meta tags imperatively (same pattern as existing pages)
  const TITLE = "Google Health Coach Invented a Workout. Here's Why AI Fitness Apps Do This.";
  const META_DESC =
    "Google's AI Health Coach fabricated a 5-mile run that never happened. A technical explainer on why general-purpose AI fitness products hallucinate workout data, and what data grounding actually means.";

  if (typeof document !== 'undefined') {
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
    setMeta('og:url', CANONICAL_URL, true);
    setMeta('og:image', `https://${BRANDING.marketingDomain}${OG_IMAGE}`, true);
    setMeta('og:type', 'article', true);
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', TITLE);
    setMeta('twitter:description', META_DESC);
    setMeta('twitter:image', `https://${BRANDING.marketingDomain}${OG_IMAGE}`);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = CANONICAL_URL;
  }

  return (
    <>
      {/* JSON-LD schemas */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBlogPosting) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdFaq) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLdBreadcrumb) }}
      />

      <ArticleLayout slug={SLUG} sections={SECTIONS}>

        {/* Breadcrumb */}
        <nav className="text-sm text-zinc-500 mb-10" aria-label="Breadcrumb">
          <Link to="/" className="hover:text-zinc-300 transition-colors">Home</Link>
          <span className="mx-2">/</span>
          <Link to="/blog" className="hover:text-zinc-300 transition-colors">Blog</Link>
          <span className="mx-2">/</span>
          <span className="text-zinc-400">Google Health Coach hallucination</span>
        </nav>

        {/* Header + answer capsule */}
        <motion.section
          id="what-happened"
          initial="hidden"
          animate="visible"
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.div variants={fadeUp}>
            <p className="text-xs font-medium uppercase tracking-widest text-emerald-400 mb-4">
              Published 2026-05-18 by Sai
            </p>
            <h1 className="text-3xl sm:text-4xl font-bold text-white mb-6 leading-tight">
              Google Health Coach Invented a Workout. Here's Why AI Fitness Apps Do This.
            </h1>
          </motion.div>

          {/* Answer capsule: first ~200 words, LLM-quote target */}
          <motion.div
            variants={fadeUp}
            className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8 mb-8"
          >
            <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
              On May 14, 2026, Will Sattelberg of 9to5Google published a hands-on review of Google Health Coach.
              The coach told him he had completed a 5-mile run that he never actually did.
              When he pushed back, the coach acknowledged the fabrication, then suggested he might
              have forgotten to record the run.
            </p>
            <p className="text-zinc-200 text-base sm:text-lg leading-relaxed mb-4">
              This is not a Google-specific bug. It is a predictable failure mode for any AI fitness
              product that asks a large language model to summarize a user's activity without first
              grounding that model in the user's actual logged data. The model fills gaps with
              statistically plausible output. A 5-mile run is plausible for an active person. So
              the model says it happened.
            </p>
            <p className="text-zinc-200 text-base sm:text-lg leading-relaxed">
              This post covers what happened, why it happens at a technical level, and what the
              difference between a grounded and an ungrounded AI fitness coach actually is. It also
              covers where Google Health is genuinely strong: wearable breadth, free tier and
              ecosystem integrations. The goal is not to sell Zealova. It is to give you a mental
              model for evaluating any AI fitness product's claims.
            </p>
          </motion.div>

          {/* Hero image */}
          <motion.div variants={fadeUp} className="flex justify-center mb-8">
            <img
              src="/screenshots/intro_phone_2.png"
              alt="Zealova AI coach showing workout plan grounded in real logged history"
              width={270}
              height={600}
              loading="lazy"
              className="rounded-2xl w-full max-w-[200px] object-cover"
            />
          </motion.div>

          {/* The incident: factual */}
          <motion.div variants={fadeUp} className="prose prose-invert max-w-none">
            <h2 className="text-2xl font-bold text-white mb-4">What happened, exactly</h2>
            <p className="text-zinc-300 leading-relaxed mb-4">
              Android Authority covered Sattelberg's review on the same day it published (May 14, 2026,
              two sources: <a href="https://www.androidauthority.com/google-health-coach-hallucinations-3667257/" target="_blank" rel="noopener noreferrer" className="text-emerald-400 hover:text-emerald-300 underline">androidauthority.com</a> and the original 9to5Google hands-on).
              The full sequence:
            </p>
            <ol className="list-decimal list-inside space-y-3 text-zinc-300 mb-6">
              <li>Sattelberg opens Google Health Coach in the pre-launch period (before May 19 public launch).</li>
              <li>The coach summarizes his recent activity. It correctly references sleep data and a real prior workout.</li>
              <li>It then cites a 5-mile run Sattelberg never completed.</li>
              <li>Sattelberg challenges the claim. The coach concedes the run was fabricated.</li>
              <li>The coach then suggests Sattelberg might have "failed to record" the run, deflecting blame to the user.</li>
            </ol>
            <p className="text-zinc-300 leading-relaxed mb-4">
              The reviewer also noted the advice itself was "quite basic" and "excessively verbose," with length
              substituting for substance. Both are hallmarks of an LLM that lacks strong grounding and compensates
              with generic, high-confidence-sounding output.
            </p>
            <p className="text-zinc-300 leading-relaxed">
              This is a paid product. Google Health Premium costs $9.99/month, launching May 19. The
              hallucination surfaced in pre-launch access, just days before the full public rollout.
            </p>
          </motion.div>
        </motion.section>

        {/* Key stats box */}
        <motion.section
          id="key-stats"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.div
            variants={fadeUp}
            className="bg-zinc-900 border border-emerald-900/40 rounded-2xl p-6 sm:p-8"
          >
            <p className="text-xs font-semibold uppercase tracking-widest text-emerald-400 mb-5">
              Key takeaways
            </p>
            <div className="grid sm:grid-cols-2 gap-6">
              {[
                {
                  stat: '5-mile run',
                  label: 'fabricated by Google Health Coach in a pre-launch hands-on (May 14, 2026)',
                  source: 'Source: Android Authority / 9to5Google, 2026-05-14',
                },
                {
                  stat: '42-68%',
                  label: 'hallucination reduction when LLMs are grounded with retrieved real data (RAG) vs ungrounded prompts',
                  source: 'Source: neuledge.com, February 2026',
                },
                {
                  stat: '2 billion',
                  label: 'monthly users exposed to Google AI Overviews, which a January 2026 Guardian investigation found spread false health information',
                  source: 'Source: Guardian / almcorp.com, January 2026',
                },
                {
                  stat: '$9.99/mo',
                  label: 'cost of Google Health Premium, the tier that includes the AI Coach that produced the hallucination',
                  source: 'Source: store.google.com, verified 2026-05-14',
                },
              ].map((item) => (
                <div key={item.stat} className="border-l-2 border-emerald-500/40 pl-4">
                  <p className="text-2xl font-bold text-white mb-1">{item.stat}</p>
                  <p className="text-sm text-zinc-300 leading-relaxed mb-1">{item.label}</p>
                  <p className="text-xs text-zinc-500">{item.source}</p>
                </div>
              ))}
            </div>
          </motion.div>
        </motion.section>

        {/* Technical explainer */}
        <motion.section
          id="why-it-happens"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            Why AI fitness apps hallucinate workout data
          </motion.h2>

          <motion.div variants={fadeUp} className="space-y-6 text-zinc-300">
            <p className="leading-relaxed">
              Large language models do not know what you did yesterday. They predict the next token
              based on the patterns in their training data. When you ask a fitness coach chatbot
              "what have I been up to this week?", the model needs your workout data injected into
              the context window before it can answer accurately.
            </p>
            <p className="leading-relaxed">
              If that injection is missing, incomplete, or noisy, the model does not say "I don't
              know." It generates a plausible-sounding response. Active users run. Active users run
              about 3-7 miles. So the model produces a run that fits the pattern. This is not malice.
              It is how next-token prediction works when the grounding is weak.
            </p>

            <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-5">
              <p className="text-sm font-semibold text-white mb-3">Three conditions that make hallucination more likely:</p>
              <ol className="list-decimal list-inside space-y-3 text-sm text-zinc-400">
                <li>
                  <span className="font-medium text-zinc-200">Missing context.</span> The model is asked
                  to summarize activity but the user's actual log is not included in the prompt. The model
                  infers activity from training data priors.
                </li>
                <li>
                  <span className="font-medium text-zinc-200">Noisy multi-source aggregation.</span> Data
                  comes from a wearable step counter, a third-party connected app, a manual entry, and a
                  health record. These sources conflict or have gaps. The model smooths over the gaps with
                  inference.
                </li>
                <li>
                  <span className="font-medium text-zinc-200">Optimizing for plausible output, not verifiable output.</span> A
                  model trained on RLHF (reinforcement learning from human feedback) learns that confident,
                  coherent responses get better ratings. Generic, verbose advice scores well. Saying "I
                  don't have enough data to answer" scores poorly. So the model says something rather than
                  nothing.
                </li>
              </ol>
            </div>

            <p className="leading-relaxed">
              All three conditions were likely present in the Google Health Coach incident. The coach
              correctly referenced real data in some places (sleep, a real workout), which means grounding
              was partial. The 5-mile run appears to have been the model filling a gap it could not verify.
            </p>
          </motion.div>
        </motion.section>

        {/* Aggregator problem */}
        <motion.section
          id="aggregator-problem"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            The aggregator problem: more data sources, more gaps
          </motion.h2>

          <motion.div variants={fadeUp} className="space-y-6 text-zinc-300">
            <p className="leading-relaxed">
              Google Health is an aggregator. It pulls from your Fitbit, Apple Health, MyFitnessPal,
              Peloton, connected apps, manual logs, and health records. This breadth is one of its
              genuine strengths for biometric tracking. But it creates a specific challenge for AI
              summarization.
            </p>
            <p className="leading-relaxed">
              When 6 data sources feed into a context window, each with different schemas, update
              frequencies, and reliability levels, the resulting context is messy. Gaps appear between
              sources. A step count from the wearable might not align with a workout from a connected
              app. An inferred calorie burn from the phone accelerometer exists alongside a manual
              food log entry.
            </p>
            <p className="leading-relaxed">
              The model has to reason across all of this. When it cannot reconcile a gap, it fills it.
              A specialized app that only tracks what a user explicitly logs has a narrower but cleaner
              context. The model has less to hallucinate across.
            </p>

            <div className="bg-amber-950/20 border border-amber-900/30 rounded-xl p-5">
              <p className="text-sm font-semibold text-amber-400 mb-2">Worth noting</p>
              <p className="text-sm text-zinc-300 leading-relaxed">
                This is not unique to Google Health. Any app that pulls from multiple sources (wearable,
                phone sensors, manual logs, connected apps) faces the same aggregation
                noise problem. The larger the ecosystem, the harder the grounding problem becomes.
                Smaller, more focused apps trade ecosystem breadth for cleaner context.
              </p>
            </div>
          </motion.div>
        </motion.section>

        {/* How grounding helps */}
        <motion.section
          id="how-grounding-helps"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            How grounding helps, and what Zealova does differently
          </motion.h2>

          <motion.div variants={fadeUp} className="space-y-6 text-zinc-300">
            <p className="leading-relaxed">
              Grounding means attaching verified data to the model's context before it generates a
              response. In fitness, that means: before the AI answers a question about your training,
              it reads your actual logged sets, reps, weights, exercises, and dates.
            </p>
            <p className="leading-relaxed">
              Research on retrieval-augmented generation (RAG) systems consistently shows grounding
              reduces hallucination rates significantly. A 2026 developer guide on LLM grounding
              (neuledge.com, published February 2026) cites 42-68% reduction in hallucinations when
              models are given retrieved real context vs no context. Clinical RAG systems have pushed
              hallucination rates to 5.8% using self-reflective verification layers on top of retrieval.
            </p>
            <p className="leading-relaxed">
              Zealova's workout plan generator and coach do this: before any AI call related to your
              training, the system pulls your actual logged workout history and injects it as structured
              context. The model is not asked to guess what you have been doing. It reads what you
              logged.
            </p>

            {/* In-content image */}
            <div className="flex justify-center my-6">
              <img
                src="/screenshots/intro_phone_4.png"
                alt="Zealova per-exercise workout history showing real logged sets and weights"
                width={270}
                height={600}
                loading="lazy"
                className="rounded-2xl w-full max-w-[200px] object-cover"
              />
            </div>

            {/* Honest concession box */}
            <div className="bg-zinc-900 border border-zinc-800 rounded-xl p-5">
              <p className="text-sm font-semibold text-white mb-3">What this does NOT mean</p>
              <p className="text-sm text-zinc-400 leading-relaxed mb-3">
                Zealova is not immune to hallucination. No LLM-based product is. Grounding removes
                the specific failure mode of fabricating logged activity. There is no gap to fill
                because your history is in the prompt. But Zealova can still:
              </p>
              <ul className="list-disc list-inside space-y-1.5 text-sm text-zinc-500">
                <li>Hallucinate exercise recommendations for equipment it was not told you own</li>
                <li>Produce overconfident nutritional estimates from food photos</li>
                <li>Generate generic advice when the logged data is thin (e.g. a new user with 2 sessions logged)</li>
                <li>Make errors in form cues or exercise descriptions pulled from the exercise library</li>
              </ul>
              <p className="text-sm text-zinc-400 leading-relaxed mt-3">
                Cross-checking AI output against your raw data is good practice regardless of which
                app you use. If the coach references something that surprises you, check the source.
              </p>
            </div>
          </motion.div>
        </motion.section>

        {/* Where Google Health wins: honest concession */}
        <motion.section
          id="where-google-wins"
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={stagger}
          className="mb-14 scroll-mt-24"
        >
          <motion.h2 variants={fadeUp} className="text-2xl font-bold text-white mb-6">
            Where Google Health is genuinely strong
          </motion.h2>

          <motion.p variants={fadeUp} className="text-zinc-400 text-sm mb-6">
            Writing about a competitor's failure without acknowledging what they do well is not
            useful analysis. Google Health has real strengths.
          </motion.p>

          <motion.ul variants={stagger} className="space-y-4">
            {[
              {
                title: 'Wearable biometrics that no phone-only app can match',
                body: "Continuous heart rate, HRV, SpO2, sleep stages, readiness scores. These require hardware. If you own a Fitbit or Pixel Watch, Google Health surfaces data that a phone-only app cannot approximate. That data is genuinely useful for recovery and sleep optimization.",
              },
              {
                title: 'Free tier with no hardware gate for basic logging',
                body: "Google Health has a free option for basic activity and food tracking. Zealova requires a subscription after a 7-day trial. If someone needs a free calorie logger with wearable integration, Google Health is the obvious choice.",
              },
              {
                title: 'Ecosystem breadth: Apple Health, MFP, Peloton, medical records',
                body: "Google Health connects to more third-party services than most competitors. If your health data is spread across multiple apps and devices, a single aggregator that pulls it together has real value, as long as you understand that aggregation is also what creates the hallucination conditions described above.",
              },
              {
                title: '3-month free trial vs 7 days',
                body: "Google Health Premium offers 3 months free for new users. That is a longer evaluation window than Zealova's 7-day trial. For a product that relies on wearable baseline data to be useful, a longer trial makes sense, since the coaching improves as the model accumulates real data.",
              },
              {
                title: 'iOS support right now',
                body: "Zealova is Android only. Google Health is live on iOS and Android. If you are on iPhone, Google Health is an option; Zealova is not yet.",
              },
            ].map((item) => (
              <motion.li
                key={item.title}
                variants={fadeUp}
                className="flex gap-4 bg-zinc-900 border border-zinc-800 rounded-xl px-5 py-4"
              >
                <span className="text-blue-400 mt-0.5 text-base font-bold shrink-0">+</span>
                <div>
                  <p className="text-sm font-semibold text-white mb-1">{item.title}</p>
                  <p className="text-sm text-zinc-400 leading-relaxed">{item.body}</p>
                </div>
              </motion.li>
            ))}
          </motion.ul>
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
              Methodology and disclosure
            </p>
            <p className="text-sm text-zinc-400 leading-relaxed">
              The Google Health Coach hallucination incident is sourced from Android Authority
              (androidauthority.com, published 2026-05-14) and the original hands-on by Will
              Sattelberg of 9to5Google. RAG hallucination reduction figures are from neuledge.com
              (LLM grounding guide, published 2026-02-20). The Guardian AI Overviews investigation
              (January 2026) is cited via almcorp.com summary. Clinical RAG figures (5.8% hallucination)
              are from MDPI Electronics 14(21):4227, "Evaluating Retrieval-Augmented Generation
              Variants for Clinical Decision Support." Google Health pricing verified at
              store.google.com, 2026-05-14. I am the founder of Zealova. I have a direct financial
              interest in Zealova being the better product. I have tried to concede every honest
              Google Health advantage. If something looks wrong, email me: sai@zealova.com.
            </p>
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
            <p className="text-zinc-400 text-base mb-8 max-w-md mx-auto">
              AI workout plans grounded in what you actually logged. No hardware required. Android
              live now.
            </p>
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
                to="/vs/google-health"
                className="inline-flex items-center justify-center px-8 py-3.5 rounded-xl bg-zinc-800 hover:bg-zinc-700 text-white font-semibold text-base transition-colors"
              >
                Full Zealova vs Google Health comparison
              </Link>
            </div>
          </motion.div>

          <p className="text-xs text-zinc-600 mt-8 leading-relaxed max-w-2xl mx-auto">
            Last updated 2026-05-18 by Sai. Sources: Android Authority (androidauthority.com,
            2026-05-14); 9to5Google original hands-on (2026-05-14); neuledge.com LLM grounding guide
            (2026-02-20); MDPI Electronics 14(21):4227; Guardian AI Overviews investigation summary
            (almcorp.com, January 2026); store.google.com pricing (verified 2026-05-14).
            Zealova pricing and features as of 2026-05-18. Refresh cycle: 60 days or if new
            hallucination incidents are reported.
          </p>
        </motion.section>

      </ArticleLayout>
    </>
  );
}
