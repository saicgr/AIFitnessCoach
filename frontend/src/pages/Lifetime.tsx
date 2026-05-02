/**
 * Founding 500 Lifetime — web-only.
 *
 * Two states:
 *   1. checkoutEnabled === false (now)  → "Coming Soon" + waitlist email capture
 *   2. checkoutEnabled === true (Phase 2) → "Buy Now" → POST /lifetime-web/checkout
 *      → redirect to Stripe-hosted checkout URL
 *
 * Counter ("247 / 500 reserved") is fetched live from `GET /lifetime-web/seats`
 * and re-polled every 30s so the scarcity number stays fresh during launch peaks.
 *
 * iMPORTANT: this page is NEVER linked from inside the iOS / Android app.
 * Apple's anti-steering rule disallows linking to non-IAP commerce. Drive
 * traffic via email, social, SEO. The footer link below is on the web only.
 */
import { useState, useEffect, useMemo } from 'react';
import { Link } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

const API_BASE = (import.meta.env.VITE_API_URL as string | undefined) ?? '/api/v1';

type AvailabilityLabel = 'available' | 'going_fast' | 'almost_gone' | 'sold_out';

interface FounderSeats {
  seats_total: number;
  seats_claimed: number;
  seats_remaining: number;
  availability_label: AvailabilityLabel;
  checkout_enabled: boolean;
  price_usd: number;
}

interface WaitlistResponse {
  success: boolean;
  already_on_waitlist: boolean;
  position: number | null;
}

const PRICE_USD = 149.99;
const FOUNDER_BENEFITS = [
  { icon: '🔓', title: 'Lifetime Premium access', body: 'All current and future Premium features, forever. No renewals, no surprises.' },
  { icon: '🥇', title: 'Founder badge in-app', body: 'Permanent gold badge on your profile + leaderboards. Only Founding 500 ever get it.' },
  { icon: '🎯', title: 'Founder-only AI coach perks', body: 'Priority queue on AI generation, exclusive coach personas, beta access to upcoming features.' },
  { icon: '👕', title: 'Free Founder merch drop', body: 'Founding 500 tee shipped to your door once we hit 500 (S–XXL, US/CA/UK/EU/AU shipping).' },
  { icon: '📞', title: 'Direct founder line', body: 'Email the actual builder. Feature requests jump the queue.' },
  { icon: '💎', title: 'Locked at $149.99', body: `Lifetime price will be $${PRICE_USD} ONLY for the first 500. After that, it closes — possibly forever.` },
];

const FAQS = [
  {
    q: 'Is this really a one-time payment?',
    a: 'Yes. $149.99 once, then never again. No annual renewal. No "upgrade to Premium Plus" trap. You own it forever.',
  },
  {
    q: 'When will checkout open?',
    a: 'Within ~3 months of the app launching publicly. Waitlist members get an exclusive 24-hour head start before public release.',
  },
  {
    q: 'How do I activate it in the app?',
    a: 'Sign in to the Zealova app with the same email you used at checkout. Premium unlocks automatically — no codes, no support tickets.',
  },
  {
    q: 'What if you build features that need to be paid separately later?',
    a: 'Founding 500 covers every feature on the public roadmap as of the day you buy. Net-new product lines launched years later (e.g. a hardware accessory) may be separate, but core app features stay yours forever.',
  },
  {
    q: 'Refunds?',
    a: 'Yes — within 30 days of purchase, no questions. After 30 days, all sales final (it is a lifetime product).',
  },
  {
    q: 'Why isn\'t this in the app?',
    a: 'Apple takes a 15% cut of in-app purchases. Selling on web lets us pass the savings to you — and run things like the Founder merch drop without app-store red tape.',
  },
];

function formatNumber(n: number): string {
  return n.toLocaleString('en-US');
}

function availabilityCopy(label: AvailabilityLabel): { text: string; tone: string } {
  switch (label) {
    case 'sold_out':
      return { text: 'Sold out', tone: 'text-red-400' };
    case 'almost_gone':
      return { text: 'Almost gone', tone: 'text-orange-400' };
    case 'going_fast':
      return { text: 'Going fast', tone: 'text-amber-300' };
    case 'available':
    default:
      return { text: 'Available', tone: 'text-emerald-400' };
  }
}

export default function Lifetime() {
  const [seats, setSeats] = useState<FounderSeats | null>(null);
  const [seatsError, setSeatsError] = useState<string | null>(null);
  const [email, setEmail] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [waitlistResult, setWaitlistResult] = useState<WaitlistResponse | null>(null);
  const [submitError, setSubmitError] = useState<string | null>(null);
  const [expandedFaq, setExpandedFaq] = useState<number | null>(null);

  // Fetch seat counter on mount + refresh every 30s
  useEffect(() => {
    let cancelled = false;
    async function load() {
      try {
        const res = await fetch(`${API_BASE}/subscriptions/lifetime-web/seats`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = (await res.json()) as FounderSeats;
        if (!cancelled) {
          setSeats(data);
          setSeatsError(null);
        }
      } catch (err) {
        if (!cancelled) {
          setSeatsError('Could not load live counter');
          // Fallback so the page still renders — pessimistic full availability
          setSeats((prev) => prev ?? {
            seats_total: 500,
            seats_claimed: 0,
            seats_remaining: 500,
            availability_label: 'available',
            checkout_enabled: false,
            price_usd: PRICE_USD,
          });
        }
      }
    }
    load();
    const id = window.setInterval(load, 30_000);
    return () => {
      cancelled = true;
      window.clearInterval(id);
    };
  }, []);

  const progressPct = useMemo(() => {
    if (!seats || seats.seats_total === 0) return 0;
    return Math.min(100, Math.round((seats.seats_claimed / seats.seats_total) * 100));
  }, [seats]);

  const availability = useMemo(
    () => availabilityCopy(seats?.availability_label ?? 'available'),
    [seats?.availability_label],
  );

  // Capture URL params for source attribution
  const sourceParam = useMemo(() => {
    if (typeof window === 'undefined') return undefined;
    const params = new URLSearchParams(window.location.search);
    return params.get('utm_source') || params.get('ref') || undefined;
  }, []);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitError(null);

    const trimmed = email.trim();
    if (!trimmed || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) {
      setSubmitError('Please enter a valid email address.');
      return;
    }

    setSubmitting(true);
    try {
      // Phase 2 path: open Stripe Checkout in a new tab
      if (seats?.checkout_enabled) {
        const res = await fetch(`${API_BASE}/subscriptions/lifetime-web/checkout`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ email: trimmed, source: sourceParam }),
        });
        if (!res.ok) {
          const detail = await res.json().catch(() => ({}));
          throw new Error(detail.detail || 'Could not start checkout. Please try again.');
        }
        const data = await res.json();
        if (data.checkout_url) {
          window.location.href = data.checkout_url;
          return;
        }
        throw new Error('Checkout URL missing from response.');
      }

      // Phase 1 path: waitlist capture
      const res = await fetch(`${API_BASE}/subscriptions/lifetime-web/waitlist`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: trimmed,
          source: sourceParam,
          referrer: typeof document !== 'undefined' ? document.referrer || undefined : undefined,
          marketing_opt_in: true,
        }),
      });
      if (!res.ok) {
        const detail = await res.json().catch(() => ({}));
        throw new Error(detail.detail || 'Could not join the waitlist. Please try again.');
      }
      const data = (await res.json()) as WaitlistResponse;
      setWaitlistResult(data);
    } catch (err) {
      setSubmitError(err instanceof Error ? err.message : 'Something went wrong.');
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      {/* Hero */}
      <section className="pt-28 pb-16 px-6">
        <div className="max-w-[980px] mx-auto text-center">
          {/* "Coming Soon" badge */}
          <motion.div
            initial={{ opacity: 0, y: -10 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.4 }}
            className="inline-flex items-center gap-2 px-4 py-1.5 rounded-full border border-amber-400/30 bg-amber-400/10 text-amber-300 text-xs font-semibold uppercase tracking-wider mb-6"
          >
            <span className="w-2 h-2 rounded-full bg-amber-400 animate-pulse" />
            {seats?.checkout_enabled ? 'Now Available — Web Only' : 'Coming Soon — Web Only'}
          </motion.div>

          <motion.h1
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5 }}
            className="text-4xl md:text-6xl font-bold tracking-tight mb-6"
          >
            <span className="bg-gradient-to-r from-amber-300 via-amber-200 to-amber-400 bg-clip-text text-transparent">
              Founding 500
            </span>
            <br />
            <span className="text-[var(--color-text)]">Lifetime Access</span>
          </motion.h1>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.1 }}
            className="text-lg md:text-xl text-[var(--color-text-secondary)] max-w-2xl mx-auto mb-2"
          >
            Pay once. Use {BRANDING.appName} forever. Help build the AI coach you want — and own it for life.
          </motion.p>

          <motion.p
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.15 }}
            className="text-sm text-[var(--color-text-muted)] mb-10"
          >
            Only 500 seats. Then it closes. Available exclusively on {BRANDING.marketingDomain}.
          </motion.p>

          {/* Live seat counter */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.2 }}
            className="max-w-md mx-auto mb-10"
          >
            <div className="rounded-2xl border border-white/10 bg-white/[0.03] backdrop-blur-sm p-6">
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs uppercase tracking-wider text-[var(--color-text-muted)]">Founder seats</span>
                <span className={`text-xs font-bold uppercase tracking-wider ${availability.tone}`}>
                  {availability.text}
                </span>
              </div>

              <div className="flex items-baseline gap-2 mb-4">
                <span className="text-5xl font-bold tabular-nums">
                  {seats ? formatNumber(seats.seats_claimed) : '—'}
                </span>
                <span className="text-2xl text-[var(--color-text-muted)] tabular-nums">
                  / {seats ? formatNumber(seats.seats_total) : '500'}
                </span>
                <span className="text-sm text-[var(--color-text-muted)] ml-auto">reserved</span>
              </div>

              {/* Progress bar */}
              <div className="h-2 bg-white/5 rounded-full overflow-hidden">
                <motion.div
                  className="h-full rounded-full bg-gradient-to-r from-amber-400 via-amber-300 to-amber-500"
                  initial={{ width: 0 }}
                  animate={{ width: `${progressPct}%` }}
                  transition={{ duration: 0.8, ease: 'easeOut' }}
                />
              </div>
              <div className="mt-2 text-xs text-[var(--color-text-muted)] text-right tabular-nums">
                {seats ? formatNumber(seats.seats_remaining) : '500'} remaining
              </div>
            </div>
            {seatsError && (
              <p className="mt-2 text-xs text-[var(--color-text-muted)]">{seatsError} — counter will update on retry.</p>
            )}
          </motion.div>

          {/* Price + CTA */}
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ duration: 0.5, delay: 0.3 }}
            className="max-w-md mx-auto"
          >
            <div className="text-center mb-6">
              <div className="text-5xl md:text-6xl font-bold tabular-nums">
                ${PRICE_USD.toFixed(2)}
              </div>
              <div className="text-sm text-[var(--color-text-muted)] mt-1">one-time, no renewals</div>
              <div className="text-xs text-[var(--color-text-muted)] mt-1">
                vs. ${(7.99 * 12 * 5).toFixed(0)} over 5 years on monthly · ${(59.99 * 5).toFixed(2)} on yearly
              </div>
            </div>

            {/* Form */}
            <AnimatePresence mode="wait">
              {waitlistResult?.success ? (
                <motion.div
                  key="success"
                  initial={{ opacity: 0, scale: 0.95 }}
                  animate={{ opacity: 1, scale: 1 }}
                  exit={{ opacity: 0 }}
                  className="rounded-xl border border-emerald-400/30 bg-emerald-400/5 p-6 text-center"
                >
                  <div className="text-4xl mb-3">🎉</div>
                  <h3 className="font-semibold text-lg mb-2">
                    {waitlistResult.already_on_waitlist ? "You're already on the list" : "You're on the list!"}
                  </h3>
                  <p className="text-sm text-[var(--color-text-secondary)]">
                    {waitlistResult.position && !waitlistResult.already_on_waitlist
                      ? `Approximately #${waitlistResult.position} in line. `
                      : ''}
                    We&apos;ll email you 24 hours before checkout opens — waitlist members get first access before the public launch.
                  </p>
                </motion.div>
              ) : seats?.availability_label === 'sold_out' ? (
                <motion.div
                  key="soldout"
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="rounded-xl border border-red-400/30 bg-red-400/5 p-6 text-center"
                >
                  <h3 className="font-semibold text-lg mb-2">All 500 founder seats are claimed</h3>
                  <p className="text-sm text-[var(--color-text-secondary)] mb-4">
                    Thank you to the Founding 500. Lifetime is now closed — Premium subscriptions are still available in the app.
                  </p>
                  <Link
                    to="/pricing"
                    className="inline-block px-6 py-2.5 rounded-lg bg-white text-black font-semibold text-sm hover:bg-white/90 transition"
                  >
                    See Premium pricing →
                  </Link>
                </motion.div>
              ) : (
                <motion.form
                  key="form"
                  onSubmit={handleSubmit}
                  initial={{ opacity: 0 }}
                  animate={{ opacity: 1 }}
                  className="space-y-3"
                >
                  <input
                    type="email"
                    required
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="you@example.com"
                    autoComplete="email"
                    className="w-full px-4 py-3.5 rounded-xl bg-white/5 border border-white/10 text-[var(--color-text)] placeholder-[var(--color-text-muted)] outline-none focus:border-amber-400/50 focus:bg-white/[0.07] transition"
                  />
                  <button
                    type="submit"
                    disabled={submitting}
                    className="w-full py-3.5 rounded-xl bg-gradient-to-r from-amber-400 via-amber-300 to-amber-500 text-black font-bold tracking-wide hover:opacity-90 disabled:opacity-50 disabled:cursor-not-allowed transition shadow-lg shadow-amber-400/20"
                  >
                    {submitting
                      ? 'Working…'
                      : seats?.checkout_enabled
                        ? `Buy Founding Lifetime — $${PRICE_USD}`
                        : 'Reserve my spot on the waitlist'}
                  </button>
                  <p className="text-xs text-[var(--color-text-muted)] text-center">
                    {seats?.checkout_enabled
                      ? 'Secure checkout via Stripe. 30-day money-back guarantee.'
                      : 'No payment yet — just join the waitlist for early access. Cancel anytime.'}
                  </p>
                  {submitError && (
                    <p className="text-sm text-red-400 text-center">{submitError}</p>
                  )}
                </motion.form>
              )}
            </AnimatePresence>
          </motion.div>
        </div>
      </section>

      {/* Benefits grid */}
      <section className="px-6 pb-16">
        <div className="max-w-[1100px] mx-auto">
          <div className="text-center mb-10">
            <h2 className="text-3xl md:text-4xl font-bold mb-3">What Founding 500 gets you</h2>
            <p className="text-[var(--color-text-secondary)]">Premium for life, plus six perks no future {BRANDING.appName} member can ever buy.</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {FOUNDER_BENEFITS.map((b, i) => (
              <motion.div
                key={b.title}
                initial={{ opacity: 0, y: 16 }}
                whileInView={{ opacity: 1, y: 0 }}
                viewport={{ once: true }}
                transition={{ duration: 0.4, delay: i * 0.05 }}
                className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 hover:bg-white/[0.04] transition"
              >
                <div className="text-3xl mb-3">{b.icon}</div>
                <h3 className="font-semibold mb-2">{b.title}</h3>
                <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed">{b.body}</p>
              </motion.div>
            ))}
          </div>
        </div>
      </section>

      {/* Math comparison — why $149.99 is a steal */}
      <section className="px-6 pb-16">
        <div className="max-w-[820px] mx-auto rounded-3xl border border-white/10 bg-white/[0.02] p-8 md:p-12">
          <h2 className="text-2xl md:text-3xl font-bold mb-6 text-center">The math (you might want to sit down)</h2>
          <div className="space-y-3">
            <div className="flex items-center justify-between py-3 border-b border-white/5">
              <span className="text-[var(--color-text-secondary)]">{BRANDING.appName} Premium Yearly × 5 years</span>
              <span className="font-semibold tabular-nums">${(59.99 * 5).toFixed(2)}</span>
            </div>
            <div className="flex items-center justify-between py-3 border-b border-white/5">
              <span className="text-[var(--color-text-secondary)]">{BRANDING.appName} Premium Monthly × 5 years</span>
              <span className="font-semibold tabular-nums">${(7.99 * 60).toFixed(2)}</span>
            </div>
            <div className="flex items-center justify-between py-3 border-b border-white/5">
              <span className="text-[var(--color-text-secondary)]">5 personal training sessions</span>
              <span className="font-semibold tabular-nums">$375.00</span>
            </div>
            <div className="flex items-center justify-between py-3 border-b border-white/5">
              <span className="text-[var(--color-text-secondary)]">1 year of MacroFactor + Workouts</span>
              <span className="font-semibold tabular-nums">$89.99</span>
            </div>
            <div className="flex items-center justify-between py-3 border-b border-white/5">
              <span className="text-[var(--color-text-secondary)]">5 years of Netflix Standard</span>
              <span className="font-semibold tabular-nums">${(19.99 * 60).toFixed(2)}</span>
            </div>
            <div className="flex items-center justify-between pt-5">
              <span className="font-bold text-lg">Founding {BRANDING.appName} Lifetime</span>
              <span className="font-bold text-lg text-amber-400 tabular-nums">${PRICE_USD.toFixed(2)} once</span>
            </div>
          </div>
        </div>
      </section>

      {/* FAQ */}
      <section className="px-6 pb-20">
        <div className="max-w-[820px] mx-auto">
          <h2 className="text-2xl md:text-3xl font-bold mb-8 text-center">Common questions</h2>
          <div className="space-y-2">
            {FAQS.map((faq, i) => (
              <div
                key={faq.q}
                className="rounded-xl border border-white/10 bg-white/[0.02] overflow-hidden"
              >
                <button
                  type="button"
                  onClick={() => setExpandedFaq(expandedFaq === i ? null : i)}
                  className="w-full px-5 py-4 flex items-center justify-between text-left hover:bg-white/[0.03] transition"
                  aria-expanded={expandedFaq === i}
                >
                  <span className="font-medium pr-4">{faq.q}</span>
                  <span className={`text-xl transition-transform ${expandedFaq === i ? 'rotate-45' : ''}`}>+</span>
                </button>
                <AnimatePresence>
                  {expandedFaq === i && (
                    <motion.div
                      initial={{ height: 0, opacity: 0 }}
                      animate={{ height: 'auto', opacity: 1 }}
                      exit={{ height: 0, opacity: 0 }}
                      transition={{ duration: 0.2 }}
                      className="overflow-hidden"
                    >
                      <div className="px-5 pb-4 text-sm text-[var(--color-text-secondary)] leading-relaxed">
                        {faq.a}
                      </div>
                    </motion.div>
                  )}
                </AnimatePresence>
              </div>
            ))}
          </div>
        </div>
      </section>

      <MarketingFooter />
    </div>
  );
}
