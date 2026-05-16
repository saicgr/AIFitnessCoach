// Exit-intent capture — triggers when the mouse leaves the viewport from the
// top edge (signals the user is about to leave the tab). Mobile fallback: shows
// after 60s of inactivity. Cheap +2-4% email conversion.
//
// Suppressed if the user already captured their email anywhere on the site
// (shares the LS flag with EmailCapture) or dismissed this modal this session.

import { useEffect, useState, type FormEvent } from 'react';
import { submitEmailSignup } from '../../lib/aiToolsClient';

const LS_CAPTURED = 'zealova-email-captured';
const SESSION_DISMISSED = 'zealova-exit-intent-dismissed';

interface Props {
  toolSlug: string;
  resultSummary?: Record<string, unknown>;
}

export default function ExitIntentCapture({ toolSlug, resultSummary }: Props) {
  const [open, setOpen] = useState(false);
  const [email, setEmail] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [confirmed, setConfirmed] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    try {
      if (window.localStorage.getItem(LS_CAPTURED) === 'true') return;
      if (window.sessionStorage.getItem(SESSION_DISMISSED) === 'true') return;
    } catch {
      return;
    }

    let fired = false;
    const fire = () => {
      if (fired) return;
      fired = true;
      setOpen(true);
    };

    // Desktop: mouse leaves viewport from the top.
    const onMouseLeave = (e: MouseEvent) => {
      if (e.clientY <= 0) fire();
    };
    document.addEventListener('mouseleave', onMouseLeave);

    // Mobile: 60s of no interaction.
    let inactivityTimer = window.setTimeout(fire, 60000);
    const resetTimer = () => {
      window.clearTimeout(inactivityTimer);
      inactivityTimer = window.setTimeout(fire, 60000);
    };
    document.addEventListener('touchstart', resetTimer, { passive: true });
    document.addEventListener('scroll', resetTimer, { passive: true });

    return () => {
      document.removeEventListener('mouseleave', onMouseLeave);
      document.removeEventListener('touchstart', resetTimer);
      document.removeEventListener('scroll', resetTimer);
      window.clearTimeout(inactivityTimer);
    };
  }, []);

  const onDismiss = () => {
    try {
      window.sessionStorage.setItem(SESSION_DISMISSED, 'true');
    } catch {
      /* ignore */
    }
    setOpen(false);
  };

  const onSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setSubmitting(true);
    setError(null);
    try {
      await submitEmailSignup({
        email,
        tool_slug: toolSlug,
        source: 'after_result',
        result_summary: resultSummary,
      });
      try {
        window.localStorage.setItem(LS_CAPTURED, 'true');
      } catch {
        /* ignore */
      }
      setConfirmed(true);
      window.setTimeout(() => setOpen(false), 2200);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Could not send. Try again.');
    } finally {
      setSubmitting(false);
    }
  };

  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end sm:items-center justify-center bg-black/70 backdrop-blur-sm p-4"
      onClick={onDismiss}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-md rounded-3xl border border-emerald-500/30 bg-[#0f1713] shadow-2xl shadow-emerald-500/10 p-6 sm:p-8 relative"
      >
        <button
          onClick={onDismiss}
          aria-label="Close"
          className="absolute top-3 right-3 w-9 h-9 rounded-lg text-[#71717a] hover:text-[#e4e4e7] hover:bg-[#27272a] transition flex items-center justify-center text-xl"
        >
          ×
        </button>

        {confirmed ? (
          <div className="text-center py-4">
            <div className="text-4xl mb-3">✓</div>
            <p className="text-lg font-bold text-[#fafafa]">You're in.</p>
            <p className="text-sm text-[#a1a1aa] mt-2">
              Your result is on its way to your inbox.
            </p>
          </div>
        ) : (
          <>
            <p className="text-xs uppercase tracking-widest text-[#34d399] font-bold mb-2">
              Don't lose this
            </p>
            <h3 className="text-2xl font-bold text-[#fafafa] tracking-tight leading-tight">
              Want this saved? We'll email it to you.
            </h3>
            <p className="mt-3 text-sm text-[#a1a1aa] leading-relaxed">
              One email with your result and a 1-tap link to track it in the Zealova app. No spam. No drip campaigns.
            </p>

            <form onSubmit={onSubmit} className="mt-5 flex flex-col gap-2">
              <input
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="you@example.com"
                autoComplete="email"
                className="w-full px-4 py-3 rounded-xl bg-[#27272a] border border-[#3f3f46] text-[#fafafa] text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <button
                type="submit"
                disabled={submitting}
                className="w-full px-4 py-3 rounded-xl bg-emerald-500 text-[#0a0a0a] text-sm font-bold hover:bg-emerald-400 disabled:opacity-60 transition"
              >
                {submitting ? 'Sending...' : 'Email me my result'}
              </button>
              {error && <p className="text-xs text-red-400 mt-1">{error}</p>}
            </form>

            <p className="text-[11px] text-[#71717a] mt-4 text-center">
              We use this to send your result. Unsubscribe any time.
            </p>
          </>
        )}
      </div>
    </div>
  );
}
