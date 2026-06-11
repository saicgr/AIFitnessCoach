import { Link } from 'react-router-dom';

// Plan copy migrated verbatim from the previous homepage pricing section.
const premiumFeatures = [
  '1,722 exercises with video demos',
  'Unlimited AI coach chat',
  'AI workout generation',
  'AI photo food logging',
  'Unlimited workout logging',
  'Manual food logging & barcode scanner',
  'Environment aware (gym, home, hotel, outdoors)',
  'Adaptive TDEE & smart suggestions',
  'Advanced charts (all-time history)',
  'Muscle heatmap & balance analysis',
  'Skill progressions (52+ exercises)',
  'Injury tracking & body part exclusion',
  'Coach personas (5+ AI personalities)',
  'Hell Mode: max intensity',
  'No ads, ever',
];

const check = (
  <svg className="mt-0.5 h-5 w-5 flex-shrink-0 text-volt-500" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
    <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
  </svg>
);

export default function PricingSection() {
  return (
    <section className="relative border-t border-white/5 py-24 sm:py-32" aria-labelledby="pricing-heading">
      {/* Static volt bloom */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute inset-0"
        style={{ background: 'radial-gradient(50% 35% at 50% 0%, rgba(255,122,0,0.06), transparent)' }}
      />

      <div className="relative mx-auto max-w-[900px] px-6">
        <div className="mb-14 text-center">
          <p className="condensed-kicker mb-4 text-xs text-volt-500">Simple pricing</p>
          <h2 id="pricing-heading" className="display-heading text-4xl text-white sm:text-6xl">
            One plan.<br className="sm:hidden" /> Everything included.
          </h2>
          <p className="mx-auto mt-5 max-w-[500px] text-zinc-400">
            Try every feature free for 7 days. No credit card required.
          </p>
        </div>

        <div className="mx-auto grid max-w-[700px] grid-cols-1 gap-6 md:grid-cols-2">
          {/* Premium Yearly — Best Value */}
          <div
            className="relative rounded-3xl border border-volt-500/40 bg-gradient-to-b from-volt-500/10 to-[#0e0c0a] p-8"
            style={{ boxShadow: 'var(--shadow-volt)' }}
          >
            <div className="condensed-kicker absolute -top-3 left-1/2 -translate-x-1/2 rounded-full bg-volt-500 px-4 py-1 text-xs text-black">
              Best Value
            </div>
            <h3 className="text-2xl font-semibold text-white">Yearly</h3>
            <p className="mb-6 mt-1 text-sm text-zinc-400">Full AI-powered fitness</p>
            <div className="mb-1 flex items-baseline gap-1">
              <span className="vl-tabular text-6xl font-bold text-volt-400" style={{ fontFamily: 'var(--font-condensed)' }}>$5</span>
              <span className="text-sm text-zinc-400">/month</span>
            </div>
            <p className="text-[13px] text-zinc-500">Billed as $59.99/year, 37% off</p>
            <p className="mb-6 mt-1 text-[13px] font-medium text-volt-400">7-day free trial included</p>
            <ul className="mb-8 space-y-3">
              {premiumFeatures.map((f) => (
                <li key={f} className="flex items-start gap-3 text-[15px] text-zinc-200">
                  {check}
                  <span>{f}</span>
                </li>
              ))}
            </ul>
            <Link to="/waitlist" className="btn-volt block w-full rounded-full py-3.5 text-center text-sm">
              Join Waitlist
            </Link>
          </div>

          {/* Premium Monthly */}
          <div className="rounded-3xl border border-white/10 bg-[#0e0c0a] p-8">
            <h3 className="text-2xl font-semibold text-white">Monthly</h3>
            <p className="mb-6 mt-1 text-sm text-zinc-400">Pay as you go</p>
            <div className="mb-2 flex items-baseline gap-1">
              <span className="vl-tabular text-6xl font-bold text-white" style={{ fontFamily: 'var(--font-condensed)' }}>$7.99</span>
              <span className="text-sm text-zinc-400">/month</span>
            </div>
            <p className="mb-8 text-[13px] text-zinc-500">Billed monthly, cancel anytime</p>
            <ul className="mb-8 space-y-3">
              {premiumFeatures.map((f) => (
                <li key={f} className="flex items-start gap-3 text-[15px] text-zinc-200">
                  {check}
                  <span>{f}</span>
                </li>
              ))}
            </ul>
            <Link
              to="/waitlist"
              className="block w-full rounded-full border border-white/15 py-3.5 text-center text-sm font-medium text-white transition-colors hover:border-volt-500/50 hover:text-volt-300"
            >
              Join Waitlist
            </Link>
          </div>
        </div>

        <div className="mt-8 text-center">
          <Link to="/pricing" className="text-sm text-volt-400 transition-colors hover:text-volt-300">
            See full feature comparison →
          </Link>
        </div>
      </div>
    </section>
  );
}
