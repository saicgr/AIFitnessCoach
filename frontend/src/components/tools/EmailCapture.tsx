// Email-capture card. Renders on every free-tool page (via CalculatorShell)
// and inline during AI-tool loading states. Two variants:
//   - 'banner'             : full card under the result, with a 3s show delay
//   - 'inline-processing'  : compact card that shows immediately during a
//                            loading state on an AI tool page
//
// Persistence rules (localStorage):
//   - zealova-email-captured              -> true once user submits anywhere
//   - zealova-email-dismissed-<toolSlug>  -> true if user closed it on a tool
//
// Either flag silently suppresses the component, so a user who subscribed on
// one tool never sees a capture card again, and a user who dismissed it on a
// specific tool only loses that one slot.
//
// Voice rules (project-wide):
//   - No em dashes. Periods or commas only.
//   - No scare quotes.

import { useEffect, useState, useRef, type FormEvent } from 'react';
import { submitEmailSignup, type EmailSignupPayload } from '../../lib/aiToolsClient';

interface EmailCaptureProps {
  toolSlug: string;
  resultSummary?: Record<string, unknown>;
  source?: 'after_result' | 'during_processing';
  variant?: 'banner' | 'inline-processing';
  className?: string;
}

const LS_CAPTURED = 'zealova-email-captured';
const LS_DISMISSED_PREFIX = 'zealova-email-dismissed-';

function readLs(key: string): boolean {
  try {
    return typeof window !== 'undefined' && window.localStorage.getItem(key) === 'true';
  } catch {
    return false;
  }
}
function writeLs(key: string, value: boolean) {
  try {
    if (typeof window === 'undefined') return;
    if (value) window.localStorage.setItem(key, 'true');
    else window.localStorage.removeItem(key);
  } catch {
    /* ignore */
  }
}

export default function EmailCapture({
  toolSlug,
  resultSummary,
  source,
  variant = 'banner',
  className = '',
}: EmailCaptureProps) {
  const dismissKey = `${LS_DISMISSED_PREFIX}${toolSlug}`;

  // hidden = suppressed for this render. Driven by LS + the dismiss button.
  const [hidden, setHidden] = useState<boolean>(() => readLs(LS_CAPTURED) || readLs(dismissKey));
  // visible = rendered on the page (after the show delay).
  const [visible, setVisible] = useState<boolean>(variant === 'inline-processing');
  const [email, setEmail] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [confirmMessage, setConfirmMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);
  const fadeTimer = useRef<number | null>(null);

  // 3-second show delay for the banner variant so users see their result
  // first. Inline-processing has no delay.
  useEffect(() => {
    if (hidden) return;
    if (variant === 'inline-processing') {
      setVisible(true);
      return;
    }
    const t = window.setTimeout(() => setVisible(true), 3000);
    return () => window.clearTimeout(t);
  }, [hidden, variant]);

  // Cleanup any pending fade timer on unmount.
  useEffect(() => {
    return () => {
      if (fadeTimer.current !== null) window.clearTimeout(fadeTimer.current);
    };
  }, []);

  if (hidden || !visible) return null;

  const inferredSource: EmailSignupPayload['source'] =
    source || (variant === 'inline-processing' ? 'during_processing' : 'after_result');

  const onDismiss = () => {
    writeLs(dismissKey, true);
    setHidden(true);
  };

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setError(null);
    const trimmed = email.trim();
    if (!trimmed) {
      setError('Add your email first.');
      return;
    }
    // Cheap client-side shape check. Server is the source of truth.
    if (!/^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$/.test(trimmed)) {
      setError("That email doesn't look right.");
      return;
    }
    setSubmitting(true);
    try {
      const res = await submitEmailSignup({
        email: trimmed,
        tool_slug: toolSlug,
        result_summary: resultSummary,
        source: inferredSource,
      });
      writeLs(LS_CAPTURED, true);
      setConfirmMessage(res.already_subscribed ? "You're already in. Thanks." : "You're in.");
      setConfirmed(true);
      // Fade out after 4 seconds.
      fadeTimer.current = window.setTimeout(() => {
        setHidden(true);
      }, 4000);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not save your email.');
    } finally {
      setSubmitting(false);
    }
  };

  if (confirmed) {
    return (
      <div
        className={`rounded-2xl border border-emerald-500/30 bg-emerald-500/10 px-5 py-4 text-sm text-emerald-200 flex items-center gap-3 transition-opacity ${className}`}
        role="status"
        aria-live="polite"
      >
        <span className="text-emerald-400 text-lg" aria-hidden>✓</span>
        <span className="font-semibold">{confirmMessage}</span>
      </div>
    );
  }

  if (variant === 'inline-processing') {
    return (
      <div
        className={`relative rounded-xl border border-zinc-800 bg-zinc-900/80 px-4 py-3 ${className}`}
      >
        <button
          type="button"
          onClick={onDismiss}
          aria-label="Dismiss"
          className="absolute top-2 right-2 text-zinc-600 hover:text-zinc-300 text-sm leading-none"
        >
          ×
        </button>
        <p className="text-sm font-semibold text-white pr-6">While AI works...</p>
        <p className="text-xs text-zinc-400 mt-0.5 pr-6 leading-snug">
          Drop your email. We'll send next week's free tool. No spam.
        </p>
        <form onSubmit={onSubmit} className="mt-2.5 flex gap-2">
          <input
            type="email"
            inputMode="email"
            autoComplete="email"
            placeholder="you@example.com"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            disabled={submitting}
            className="flex-1 min-w-0 rounded-lg bg-zinc-950 border border-zinc-800 px-3 py-2 text-sm text-white placeholder-zinc-600 focus:border-emerald-500 focus:outline-none disabled:opacity-60"
          />
          <button
            type="submit"
            disabled={submitting}
            className="shrink-0 rounded-lg bg-emerald-500 px-3 py-2 text-sm font-semibold text-zinc-900 hover:bg-emerald-400 transition disabled:bg-zinc-700 disabled:text-zinc-500"
          >
            {submitting ? '…' : '→'}
          </button>
        </form>
        {error && <p className="mt-2 text-xs text-red-300">{error}</p>}
      </div>
    );
  }

  // Banner variant.
  return (
    <section
      className={`relative rounded-2xl border border-zinc-800 bg-gradient-to-br from-zinc-900 to-zinc-950 p-5 sm:p-6 ${className}`}
    >
      <button
        type="button"
        onClick={onDismiss}
        aria-label="Dismiss"
        className="absolute top-3 right-3 text-zinc-600 hover:text-zinc-300 text-lg leading-none"
      >
        ×
      </button>
      <div className="flex items-center gap-2 mb-1">
        <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" aria-hidden />
        <p className="text-xs uppercase tracking-wide text-emerald-400 font-semibold">
          Liked this tool?
        </p>
      </div>
      <h3 className="text-lg sm:text-xl font-bold text-white">
        Get 1 new free tool per week.
      </h3>
      <p className="text-sm text-zinc-400 mt-1 pr-6">
        No spam. Unsubscribe anytime.
      </p>
      <form
        onSubmit={onSubmit}
        className="mt-4 flex flex-col sm:flex-row gap-2"
      >
        <input
          type="email"
          inputMode="email"
          autoComplete="email"
          placeholder="you@example.com"
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          disabled={submitting}
          className="flex-1 min-w-0 rounded-xl bg-zinc-950 border border-zinc-800 px-4 py-2.5 text-sm text-white placeholder-zinc-600 focus:border-emerald-500 focus:outline-none disabled:opacity-60"
        />
        <button
          type="submit"
          disabled={submitting}
          className="shrink-0 rounded-xl bg-emerald-500 px-5 py-2.5 text-sm font-bold text-zinc-900 hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:shadow-none"
        >
          {submitting ? 'Saving…' : 'Get it'}
        </button>
      </form>
      {error && <p className="mt-2 text-xs text-red-300">{error}</p>}
      <p className="mt-3 text-[11px] text-zinc-500">
        We send 1 email per week max.
      </p>
    </section>
  );
}
