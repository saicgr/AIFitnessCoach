/**
 * /lifetime/success — landed here after Stripe redirects post-payment.
 *
 * Race window: Stripe sends the browser here BEFORE its webhook reaches our
 * backend. So we poll /checkout-status/{session_id} every 1s for up to 15s
 * waiting for the row to flip from 'pending' → 'active' (which assigns the
 * founder seat number). Once active, we show the seat number + the "sign in
 * to the app with this email" activation copy.
 *
 * If polling exhausts without flipping active (Stripe webhook delivery is
 * delayed beyond 15s — rare), we show a "we'll email you when it lands"
 * fallback. The webhook is the source of truth — it WILL eventually fire,
 * even if this page polled past its window.
 */
import { useEffect, useState } from 'react';
import { Link, useSearchParams } from 'react-router-dom';
import { motion, AnimatePresence } from 'framer-motion';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

const API_BASE = (import.meta.env.VITE_API_URL as string | undefined) ?? '/api/v1';

type PurchaseStatus = 'pending' | 'active' | 'refunded' | 'disputed';

interface CheckoutStatusResponse {
  status: PurchaseStatus;
  seat_number: number | null;
  email: string | null;
}

const POLL_INTERVAL_MS = 1500;
const POLL_MAX_ATTEMPTS = 12;  // ~18s total

export default function LifetimeSuccess() {
  const [params] = useSearchParams();
  const sessionId = params.get('session_id');

  const [status, setStatus] = useState<PurchaseStatus>('pending');
  const [seatNumber, setSeatNumber] = useState<number | null>(null);
  const [email, setEmail] = useState<string | null>(null);
  const [attempts, setAttempts] = useState(0);
  const [pollExhausted, setPollExhausted] = useState(false);
  const [networkError, setNetworkError] = useState(false);

  useEffect(() => {
    if (!sessionId) return;
    let cancelled = false;
    let attemptCount = 0;
    let timer: number | undefined;

    async function poll() {
      attemptCount += 1;
      if (cancelled) return;
      try {
        const res = await fetch(`${API_BASE}/subscriptions/lifetime-web/checkout-status/${encodeURIComponent(sessionId!)}`);
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data = (await res.json()) as CheckoutStatusResponse;
        if (cancelled) return;

        setStatus(data.status);
        setSeatNumber(data.seat_number);
        setEmail(data.email);
        setAttempts(attemptCount);
        setNetworkError(false);

        // Stop polling on terminal states
        if (data.status === 'active' || data.status === 'refunded' || data.status === 'disputed') {
          return;
        }
        if (attemptCount >= POLL_MAX_ATTEMPTS) {
          setPollExhausted(true);
          return;
        }
        timer = window.setTimeout(poll, POLL_INTERVAL_MS);
      } catch (err) {
        if (cancelled) return;
        setNetworkError(true);
        if (attemptCount >= POLL_MAX_ATTEMPTS) {
          setPollExhausted(true);
          return;
        }
        timer = window.setTimeout(poll, POLL_INTERVAL_MS);
      }
    }

    poll();
    return () => {
      cancelled = true;
      if (timer) window.clearTimeout(timer);
    };
  }, [sessionId]);

  if (!sessionId) {
    return (
      <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
        <MarketingNav />
        <div className="max-w-[680px] mx-auto px-6 pt-32 pb-20 text-center">
          <h1 className="text-3xl font-bold mb-4">Missing checkout session</h1>
          <p className="text-[var(--color-text-secondary)] mb-8">
            This page should be reached after a successful Stripe checkout. If you completed a purchase and landed here without a session ID, check your email — your activation details will be there.
          </p>
          <Link to="/lifetime" className="inline-block px-6 py-3 rounded-lg bg-white text-black font-semibold hover:bg-white/90 transition">
            Back to Lifetime →
          </Link>
        </div>
        <MarketingFooter />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[var(--color-background)] text-[var(--color-text)]">
      <MarketingNav />

      <div className="max-w-[720px] mx-auto px-6 pt-28 pb-20">
        <AnimatePresence mode="wait">
          {status === 'pending' && !pollExhausted && (
            <motion.div
              key="pending"
              initial={{ opacity: 0, y: 12 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0 }}
              className="text-center"
            >
              <div className="inline-block w-16 h-16 mb-6 relative">
                <span className="absolute inset-0 rounded-full border-4 border-amber-400/20" />
                <span className="absolute inset-0 rounded-full border-4 border-amber-400 border-t-transparent animate-spin" />
              </div>
              <h1 className="text-2xl md:text-3xl font-bold mb-3">Confirming your Founding Lifetime…</h1>
              <p className="text-[var(--color-text-secondary)] max-w-md mx-auto">
                Stripe is finalizing your payment. This usually takes a few seconds.
              </p>
              <p className="text-xs text-[var(--color-text-muted)] mt-6">
                Attempt {attempts} of {POLL_MAX_ATTEMPTS}{networkError && ' · retrying after a hiccup'}
              </p>
            </motion.div>
          )}

          {status === 'active' && (
            <motion.div
              key="active"
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.5 }}
            >
              {/* Confetti-style hero */}
              <div className="text-center mb-10">
                <motion.div
                  initial={{ scale: 0 }}
                  animate={{ scale: 1, rotate: 360 }}
                  transition={{ type: 'spring', stiffness: 180, damping: 18 }}
                  className="inline-flex items-center justify-center w-20 h-20 mb-6 rounded-full bg-gradient-to-br from-amber-300 via-amber-400 to-amber-500 shadow-xl shadow-amber-500/30"
                >
                  <span className="text-4xl">🏆</span>
                </motion.div>
                <h1 className="text-3xl md:text-5xl font-bold mb-3">
                  Welcome, Founder.
                </h1>
                <p className="text-lg text-[var(--color-text-secondary)] max-w-md mx-auto">
                  You&apos;re officially Founding Member <span className="font-bold text-amber-400">#{seatNumber ?? '—'}</span> of <span className="font-semibold">{BRANDING.appName}</span>.
                </p>
              </div>

              {/* Activation card — the most important content on this page */}
              <div className="rounded-3xl border-2 border-amber-400/40 bg-gradient-to-br from-amber-400/[0.07] via-white/[0.02] to-white/[0.02] p-8 mb-8">
                <div className="flex items-start gap-4">
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-amber-400/20 text-amber-300 flex items-center justify-center text-lg font-bold">
                    1
                  </div>
                  <div>
                    <h2 className="font-semibold text-lg mb-2">Sign in to the {BRANDING.appName} app</h2>
                    <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mb-3">
                      Use this exact email when you sign in — Premium unlocks automatically.
                    </p>
                    <div className="rounded-lg bg-black/40 border border-white/10 px-4 py-3 font-mono text-sm break-all">
                      {email ?? 'Your purchase email'}
                    </div>
                  </div>
                </div>

                <div className="flex items-start gap-4 mt-6 pt-6 border-t border-white/5">
                  <div className="flex-shrink-0 w-10 h-10 rounded-full bg-amber-400/20 text-amber-300 flex items-center justify-center text-lg font-bold">
                    2
                  </div>
                  <div>
                    <h2 className="font-semibold text-lg mb-2">Don&apos;t have the app yet?</h2>
                    <p className="text-sm text-[var(--color-text-secondary)] leading-relaxed mb-4">
                      Download {BRANDING.appName} and create an account with the email above. Your Lifetime is waiting.
                    </p>
                    <div className="flex flex-wrap gap-3">
                      <Link
                        to="/"
                        className="inline-block px-5 py-2.5 rounded-lg bg-white text-black font-semibold text-sm hover:bg-white/90 transition"
                      >
                        Download options →
                      </Link>
                    </div>
                  </div>
                </div>
              </div>

              {/* Founder benefits checklist */}
              <div className="rounded-2xl border border-white/10 bg-white/[0.02] p-6 mb-8">
                <h3 className="font-semibold mb-4 flex items-center gap-2">
                  <span>✨</span> What&apos;s unlocked for you
                </h3>
                <ul className="space-y-2 text-sm text-[var(--color-text-secondary)]">
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Lifetime Premium — every current and future feature</li>
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Permanent gold Founder badge on your profile</li>
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Priority queue on AI workout/nutrition generation</li>
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Founder-only AI coach personas</li>
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Free Founding 500 tee (we&apos;ll email you to collect shipping when we ship the run)</li>
                  <li className="flex gap-2"><span className="text-amber-400">✓</span> Direct line to the builder — feature requests jump the queue</li>
                </ul>
              </div>

              {/* Receipt + support */}
              <div className="text-center text-sm text-[var(--color-text-muted)] space-y-2">
                <p>A receipt is in your inbox. Save it — Stripe handles all billing inquiries.</p>
                <p>
                  Questions? <a href={`mailto:${BRANDING.supportEmail}`} className="text-amber-400 underline hover:no-underline">
                    {BRANDING.supportEmail}
                  </a>
                </p>
              </div>
            </motion.div>
          )}

          {status === 'refunded' && (
            <motion.div
              key="refunded"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center"
            >
              <h1 className="text-2xl font-bold mb-3">This purchase was refunded</h1>
              <p className="text-[var(--color-text-secondary)] mb-8">
                Looks like this checkout session was refunded. If you didn&apos;t request the refund, contact us.
              </p>
              <a
                href={`mailto:${BRANDING.supportEmail}`}
                className="inline-block px-6 py-3 rounded-lg bg-white text-black font-semibold hover:bg-white/90 transition"
              >
                Contact support →
              </a>
            </motion.div>
          )}

          {status === 'disputed' && (
            <motion.div
              key="disputed"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center"
            >
              <h1 className="text-2xl font-bold mb-3">A dispute is in progress on this payment</h1>
              <p className="text-[var(--color-text-secondary)] mb-8">
                We&apos;ve been notified by Stripe of a chargeback on this payment. Your Lifetime is paused while it&apos;s reviewed. We&apos;ll email you when it&apos;s resolved.
              </p>
              <a
                href={`mailto:${BRANDING.supportEmail}`}
                className="inline-block px-6 py-3 rounded-lg bg-white text-black font-semibold hover:bg-white/90 transition"
              >
                Contact support →
              </a>
            </motion.div>
          )}

          {pollExhausted && status === 'pending' && (
            <motion.div
              key="exhausted"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              className="text-center"
            >
              <div className="inline-block w-16 h-16 rounded-full bg-amber-400/20 text-amber-300 flex items-center justify-center text-3xl mb-6">
                ⏳
              </div>
              <h1 className="text-2xl md:text-3xl font-bold mb-3">Almost there</h1>
              <p className="text-[var(--color-text-secondary)] max-w-md mx-auto mb-3">
                Your payment went through, but our system is taking a moment to confirm with Stripe. This is normal during launch peaks.
              </p>
              <p className="text-sm text-[var(--color-text-muted)] max-w-md mx-auto mb-8">
                You&apos;ll get an email at the address you used at checkout within a few minutes confirming your Founder seat number and activation steps. No need to refresh — it&apos;ll arrive.
              </p>
              <Link
                to="/lifetime"
                className="inline-block px-6 py-3 rounded-lg bg-white text-black font-semibold hover:bg-white/90 transition"
              >
                Back to Lifetime →
              </Link>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      <MarketingFooter />
    </div>
  );
}
