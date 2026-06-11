import { useEffect } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

interface PricingPlan {
  name: string;
  description: string;
  monthlyPrice: string;
  yearlyPrice: string;
  yearlyTotal: string;
  billedNote: string;
  savings?: string;
  features: string[];
  highlight?: boolean;
  badge?: string;
  cta: string;
}

const sharedFeatures = [
  '1,722 exercises with video demos',
  'Unlimited AI coach chat',
  'AI workout generation (monthly/weekly/quick)',
  'AI photo food logging (Vision)',
  'Unlimited workout logging',
  'Manual food logging & barcode scanner',
  'Fasting timer (3 protocols)',
  'Workout environment aware (gym, home, hotel, outdoors)',
  'Adaptive TDEE & smart weight suggestions',
  'Advanced charts (all-time history)',
  'Muscle group heatmap & balance analysis',
  'Skill progressions (7 chains, 52+ exercises)',
  'Injury tracking & body part exclusion',
  'Coach personas (5+ AI personalities)',
  'Hell Mode: max intensity regeneration',
  'No ads, ever',
];

const plans: PricingPlan[] = [
  {
    name: 'Premium Yearly',
    description: 'Full AI-powered fitness & nutrition',
    monthlyPrice: '$7.99',
    yearlyPrice: '$5.00',
    yearlyTotal: '$59.99',
    billedNote: '$59.99 billed yearly',
    savings: 'Save 37%',
    features: sharedFeatures,
    highlight: true,
    badge: 'Best Value',
    cta: 'Start 7-Day Free Trial',
  },
  {
    name: 'Premium Monthly',
    description: 'Pay as you go, cancel anytime',
    monthlyPrice: '$7.99',
    yearlyPrice: '$7.99',
    yearlyTotal: '$95.88',
    billedNote: 'billed monthly',
    features: sharedFeatures,
    cta: 'Start 7-Day Free Trial',
  },
];

const premiumFeaturesList = [
  { feature: 'Exercise Library', detail: '1,722 with video demos' },
  { feature: 'Workout Logging', detail: 'Unlimited' },
  { feature: 'AI Chat Messages', detail: 'Unlimited' },
  { feature: 'AI Workout Generation', detail: 'Monthly / Weekly / Quick' },
  { feature: 'AI Food Photo Scanning', detail: 'Gemini Vision' },
  { feature: 'Manual Food Logging', detail: 'Yes' },
  { feature: 'Barcode Scanner', detail: 'Yes' },
  { feature: 'Macro Tracking', detail: 'Full + Micronutrients' },
  { feature: 'Adaptive TDEE', detail: 'Research-grade' },
  { feature: 'Charts & Analytics', detail: 'All-time history' },
  { feature: 'Muscle Heatmap', detail: 'Yes' },
  { feature: 'Skill Progressions', detail: '7 chains (52+ exercises)' },
  { feature: 'Injury Tracking', detail: 'Auto-adapt workouts' },
  { feature: 'Coach Personas', detail: '5+ personalities' },
  { feature: 'Environment Aware', detail: 'Gym, home, hotel, outdoors' },
  { feature: 'Hell Mode', detail: 'Max intensity regeneration' },
  { feature: 'Social Feed & Leaderboards', detail: 'Yes' },
  { feature: 'Ads', detail: 'None' },
];

const zealovaIncludes = [
  { category: 'AI Workout Generation', icon: '🤖' },
  { category: 'Nutrition Tracking', icon: '🥗' },
  { category: 'Intermittent Fasting', icon: '⏱️' },
  { category: 'AI Coach (5 agents)', icon: '💬' },
  { category: 'Workout Logging', icon: '📋' },
  { category: 'Adaptive TDEE', icon: '📊' },
  { category: 'Habit Tracking', icon: '✅' },
  { category: 'Hormonal Health', icon: '🧬' },
  { category: 'Barcode Scanner', icon: '📷' },
  { category: 'No Ads, Ever', icon: '🚫' },
];

const faqs = [
  {
    question: 'How does the 7-day free trial work?',
    answer:
      "You get 7 days of full access to every feature, no payment upfront. After the trial, choose monthly ($7.99/mo) or yearly ($59.99/yr, that's $5/mo, 37% off) to keep going.",
  },
  {
    question: 'Can I cancel whenever I want?',
    answer:
      'Yes, cancel anytime through Google Play. No fees, no questions. You keep access until the end of your billing period.',
  },
  {
    question: 'What payment methods are accepted?',
    answer:
      'Everything supported by Google Play: credit cards, debit cards, Google Pay, and carrier billing in supported regions.',
  },
  {
    question: 'Can I switch between monthly and yearly?',
    answer:
      'Yes, you can switch anytime. When moving to yearly, the change takes effect at the end of your current billing period and you start saving immediately.',
  },
  {
    question: `How can ${BRANDING.appName} offer so much for $5/month?`,
    answer:
      "We believe premium fitness coaching shouldn't cost $20/month. By leveraging cutting-edge AI efficiently, we deliver workouts + nutrition + fasting + AI coaching all in one app at a price that's accessible to everyone: $59.99/yr ($5/mo) on the annual plan, or $7.99/mo if you'd rather pay monthly.",
  },
];

const costBreakdown = [
  {
    icon: '🤖',
    title: 'AI Infrastructure',
    desc: 'Gemini-powered workout generation, nutrition analysis, and real-time coaching',
  },
  {
    icon: '☁️',
    title: 'Cloud Servers',
    desc: 'Fast, reliable servers running 24/7 to sync your data, workouts, and chat history',
  },
  {
    icon: '📱',
    title: 'App Development',
    desc: 'Continuous updates, bug fixes, and new features based on your feedback',
  },
  {
    icon: '💪',
    title: 'Exercise Library',
    desc: '1,722 exercises with video demos, instructions, and AI-powered alternatives',
  },
];

const beforeItems = [
  'One app for workouts, another for nutrition, another for fasting',
  'Generic programs that ignore your injuries and equipment',
  'Paying $15-20/month and still not getting AI coaching',
  "No idea if you're actually progressing",
  'Googling exercises and hoping for the best',
];

const afterItems = [
  'Workouts + nutrition + fasting + coaching in one $5/mo app',
  'AI generates plans around your goals, equipment, and injuries',
  '5 specialist AI agents for coaching, nutrition, and recovery',
  'Track every rep and see clear progress analytics',
  '1,722 exercises with video demos and smart alternatives',
];

const stats = [
  { value: '1,722+', label: 'Exercises' },
  { value: '5', label: 'AI Agents' },
  { value: '1,000+', label: 'Features' },
];

const VoltCheck = () => (
  <svg className="w-4 h-4 text-volt-500 flex-shrink-0 mt-0.5" fill="currentColor" viewBox="0 0 20 20" aria-hidden="true">
    <path
      fillRule="evenodd"
      d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z"
      clipRule="evenodd"
    />
  </svg>
);

const MutedX = () => (
  <svg className="w-4 h-4 text-zinc-600 flex-shrink-0 mt-0.5" fill="none" stroke="currentColor" viewBox="0 0 24 24" aria-hidden="true">
    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
  </svg>
);

export default function Pricing() {
  const canonical = `https://${BRANDING.marketingDomain}/pricing`;

  useEffect(() => {
    document.title = `Pricing | ${BRANDING.appName}`;
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
    const description = `${BRANDING.appName} Premium: $7.99/mo or $59.99/yr ($5/mo, save 37%). AI workouts, nutrition tracking, fasting, and AI coaching in one app. 7-day free trial, no credit card required.`;
    setMeta('description', description);
    setMeta('og:title', `Pricing | ${BRANDING.appName}`, true);
    setMeta('og:description', description, true);
    setMeta('og:url', canonical, true);
    setMeta('og:type', 'website', true);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = canonical;
  }, [canonical]);

  const productJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Product',
    name: `${BRANDING.appName} Premium`,
    description:
      'AI-powered fitness and nutrition coaching: AI workout generation, photo food logging, macro tracking, fasting timer, adaptive TDEE, and an AI coach with 5 specialist agents. Includes a 7-day free trial.',
    brand: { '@type': 'Brand', name: BRANDING.appName },
    url: canonical,
    offers: [
      {
        '@type': 'Offer',
        name: 'Premium Monthly',
        price: '7.99',
        priceCurrency: 'USD',
        url: canonical,
        availability: 'https://schema.org/InStock',
        description: '$7.99 per month after a 7-day free trial. Cancel anytime.',
      },
      {
        '@type': 'Offer',
        name: 'Premium Yearly',
        price: '59.99',
        priceCurrency: 'USD',
        url: canonical,
        availability: 'https://schema.org/InStock',
        description: '$59.99 per year ($5/mo, save 37%) after a 7-day free trial. Cancel anytime.',
      },
    ],
  };

  const faqJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'FAQPage',
    mainEntity: faqs.map((f) => ({
      '@type': 'Question',
      name: f.question,
      acceptedAnswer: { '@type': 'Answer', text: f.answer },
    })),
  };

  return (
    <div className="min-h-screen bg-[#050505] text-white">
      <MarketingNav />

      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(productJsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} />

      {/* Hero */}
      <section className="relative pt-28 sm:pt-32 pb-12 px-4 sm:px-6 bg-[radial-gradient(60%_40%_at_50%_0%,rgba(255,122,0,0.08),transparent)]">
        <div className="max-w-[980px] mx-auto text-center">
          <p className="condensed-kicker text-xs text-volt-500 mb-4">One Plan. Everything Included.</p>
          <h1 className="display-heading text-5xl sm:text-7xl text-white mb-5">
            Simple, transparent pricing
          </h1>
          <p className="text-base sm:text-xl text-zinc-400 max-w-[600px] mx-auto">
            Try everything free for 7 days. No credit card required.
          </p>
        </div>
      </section>

      {/* Pricing Cards */}
      <section className="px-4 sm:px-6 pb-20">
        <div className="max-w-[860px] mx-auto grid grid-cols-1 md:grid-cols-2 gap-6 items-start">
          {plans.map((plan) => (
            <div
              key={plan.name}
              className={`relative p-6 sm:p-8 rounded-3xl ${
                plan.highlight
                  ? 'bg-[#0D0D0D] border border-volt-500/40 shadow-[var(--shadow-volt)]'
                  : 'bg-[#0D0D0D] border border-white/10'
              }`}
            >
              {plan.badge && (
                <div className="condensed-kicker absolute -top-3 left-1/2 -translate-x-1/2 px-4 py-1 text-[11px] rounded-full bg-volt-500 text-black whitespace-nowrap">
                  {plan.badge}
                </div>
              )}

              <h2 className="condensed-kicker text-sm text-zinc-300 mb-1">{plan.name}</h2>
              <p className="text-sm text-zinc-500 mb-6">{plan.description}</p>

              <div className="mb-2 flex items-baseline gap-2 flex-wrap">
                <span
                  className={`text-6xl sm:text-7xl font-bold leading-none ${plan.highlight ? 'text-volt-300' : 'text-white'}`}
                  style={{ fontFamily: 'var(--font-condensed)' }}
                >
                  {plan.yearlyPrice}
                </span>
                <span className="text-base text-zinc-500">/mo</span>
              </div>
              <p className="text-[13px] text-zinc-500 mb-6">
                {plan.billedNote}
                {plan.savings && (
                  <span className="ml-2 text-volt-400 font-medium">{plan.savings}</span>
                )}
              </p>

              <Link
                to="/waitlist"
                className={`block w-full py-3 px-6 rounded-full text-center text-sm mb-8 transition-colors ${
                  plan.highlight
                    ? 'btn-volt'
                    : 'border border-white/15 text-white hover:border-volt-500/50 hover:text-volt-300'
                }`}
              >
                Join Waitlist: {plan.cta}
              </Link>

              <div className="kinetic-rule mb-6" />

              <ul className="space-y-3">
                {plan.features.map((feature, i) => (
                  <li key={i} className="flex items-start gap-2.5 text-[13px] text-zinc-400">
                    <VoltCheck />
                    {feature}
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
      </section>

      {/* Feature Comparison Table */}
      <section className="px-4 sm:px-6 py-20 border-t border-white/5">
        <div className="max-w-[800px] mx-auto">
          <p className="condensed-kicker text-xs text-volt-500 text-center mb-4">No Tiers, No Gates</p>
          <h2 className="display-heading text-3xl sm:text-5xl text-white text-center mb-12">
            Everything included
          </h2>

          <div className="overflow-x-auto rounded-2xl border border-white/10 bg-[#0D0D0D]">
            <table className="w-full">
              <thead>
                <tr className="border-b border-white/10">
                  <th className="text-left py-4 px-4 sm:px-5 text-sm font-semibold text-white">Feature</th>
                  <th className="condensed-kicker text-right sm:text-center py-4 px-4 sm:px-5 text-xs text-volt-500 sm:w-[220px]">
                    Included
                  </th>
                </tr>
              </thead>
              <tbody>
                {premiumFeaturesList.map((row, index) => (
                  <tr key={index} className="border-b border-white/5 last:border-b-0">
                    <td className="py-3.5 px-4 sm:px-5 text-sm text-zinc-300">{row.feature}</td>
                    <td className="py-3.5 px-4 sm:px-5 text-right sm:text-center text-sm text-zinc-400">
                      {row.detail === 'Yes' ? (
                        <span className="inline-flex justify-end sm:justify-center w-full">
                          <VoltCheck />
                        </span>
                      ) : (
                        row.detail
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </section>

      {/* Before & After */}
      <section className="px-4 sm:px-6 py-20">
        <div className="max-w-[1100px] mx-auto">
          <div className="text-center mb-14">
            <p className="condensed-kicker text-xs text-volt-500 mb-4">Stop Juggling Apps</p>
            <h2 className="display-heading text-3xl sm:text-5xl text-white mb-4">
              Before & after {BRANDING.appName}
            </h2>
            <p className="text-base sm:text-lg text-zinc-400 max-w-[600px] mx-auto">
              Stop juggling multiple apps. Get everything in one place.
            </p>
          </div>

          {/* Stats */}
          <div className="grid grid-cols-3 gap-3 sm:gap-6 mb-14 max-w-[700px] mx-auto">
            {stats.map((stat) => (
              <div key={stat.label} className="text-center p-4 sm:p-6 rounded-2xl bg-[#0D0D0D] border border-white/10">
                <div
                  className="text-4xl sm:text-6xl font-bold text-volt-300 leading-none mb-2"
                  style={{ fontFamily: 'var(--font-condensed)' }}
                >
                  {stat.value}
                </div>
                <div className="condensed-kicker text-[10px] sm:text-xs text-zinc-500">{stat.label}</div>
              </div>
            ))}
          </div>

          {/* Before / After Cards */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mb-16">
            <div className="p-6 sm:p-8 rounded-3xl bg-[#0D0D0D] border border-white/10">
              <h3 className="condensed-kicker text-sm text-zinc-500 mb-6">Before {BRANDING.appName}</h3>
              <div className="space-y-3.5">
                {beforeItems.map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <MutedX />
                    <span className="text-sm text-zinc-500">{item}</span>
                  </div>
                ))}
              </div>
            </div>

            <div className="p-6 sm:p-8 rounded-3xl bg-volt-950 border border-volt-500/30">
              <h3 className="condensed-kicker text-sm text-volt-400 mb-6">After {BRANDING.appName}</h3>
              <div className="space-y-3.5">
                {afterItems.map((item, i) => (
                  <div key={i} className="flex items-start gap-3">
                    <VoltCheck />
                    <span className="text-sm text-zinc-200">{item}</span>
                  </div>
                ))}
              </div>
            </div>
          </div>

          {/* Everything Included Grid */}
          <h3 className="display-heading text-2xl sm:text-3xl text-white text-center mb-8">
            Everything included with {BRANDING.appName}
          </h3>
          <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
            {zealovaIncludes.map((feature, index) => (
              <div
                key={index}
                className="text-center p-4 rounded-2xl bg-[#0D0D0D] border border-white/10 hover:border-volt-500/30 transition-colors"
              >
                <span className="text-2xl block mb-2">{feature.icon}</span>
                <div className="text-xs sm:text-[13px] text-zinc-300 font-medium">{feature.category}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Why It Costs This Much */}
      <section className="px-4 sm:px-6 py-20 border-t border-white/5">
        <div className="max-w-[800px] mx-auto">
          <div className="text-center mb-10">
            <p className="condensed-kicker text-xs text-volt-500 mb-4">Where Your Money Goes</p>
            <h2 className="display-heading text-3xl sm:text-5xl text-white mb-4">
              Why does it cost this much?
            </h2>
            <p className="text-base text-zinc-400 max-w-[600px] mx-auto">
              Transparency matters to us. Here's where your subscription goes.
            </p>
          </div>

          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            {costBreakdown.map((item, i) => (
              <div key={i} className="p-5 rounded-2xl bg-[#0D0D0D] border border-white/10">
                <span className="text-2xl mb-3 block">{item.icon}</span>
                <h3 className="text-[15px] font-semibold text-white mb-1">{item.title}</h3>
                <p className="text-[13px] text-zinc-400 leading-relaxed">{item.desc}</p>
              </div>
            ))}
          </div>

          <p className="text-center text-[15px] text-zinc-400 mt-8">
            Most fitness apps charge $10-20/month for a single feature. {BRANDING.appName} delivers everything starting at $5/month.
          </p>
        </div>
      </section>

      {/* FAQs */}
      <section className="px-4 sm:px-6 py-20">
        <div className="max-w-[800px] mx-auto">
          <h2 className="display-heading text-3xl sm:text-5xl text-white text-center mb-12">
            Frequently asked questions
          </h2>

          <div className="space-y-3">
            {faqs.map((faq, index) => (
              <details key={index} className="group rounded-xl border border-white/10 bg-[#0D0D0D] px-5 py-4">
                <summary className="cursor-pointer list-none flex items-center justify-between gap-3 font-medium text-white text-sm sm:text-base">
                  <span>{faq.question}</span>
                  <span className="ml-3 text-volt-500 group-open:rotate-45 transition-transform flex-shrink-0">+</span>
                </summary>
                <p className="mt-3 text-sm text-zinc-400 leading-relaxed">{faq.answer}</p>
              </details>
            ))}
          </div>
        </div>
      </section>

      {/* CTA */}
      <section className="relative px-4 sm:px-6 py-24 border-t border-white/5 bg-[radial-gradient(60%_50%_at_50%_100%,rgba(255,122,0,0.07),transparent)]">
        <div className="max-w-[680px] mx-auto text-center">
          <h2 className="display-heading text-4xl sm:text-6xl text-white mb-5">
            Ready to transform your fitness?
          </h2>
          <p className="text-base sm:text-lg text-zinc-400 mb-9">
            Try every feature free for 7 days. No credit card required.
          </p>
          <div className="flex flex-col sm:flex-row items-center justify-center gap-4">
            <Link to="/waitlist" className="btn-volt rounded-full px-8 py-3.5 text-base">
              Join Waitlist: iOS + Android
            </Link>
            <Link
              to="/features"
              className="px-8 py-3.5 rounded-full border border-white/15 text-white text-sm hover:border-volt-500/50 hover:text-volt-300 transition-colors"
            >
              View all features
            </Link>
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
