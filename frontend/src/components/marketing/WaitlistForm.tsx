import { useState } from 'react';
import type { FormEvent } from 'react';
import { motion } from 'framer-motion';

interface WaitlistFormProps {
  source: string;                 // 'marketing_landing' | 'waitlist_page' | etc
  platformInterest?: 'ios' | 'android' | 'both';
  successMessage?: string;
  className?: string;
  variant?: 'inline' | 'stacked';
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const WAITLIST_ENDPOINT = '/api/v1/waitlist/';

export default function WaitlistForm({
  source,
  platformInterest = 'both',
  successMessage = "You're in. Check your inbox — we sent you what's next.",
  className = '',
  variant = 'inline',
}: WaitlistFormProps) {
  const [email, setEmail] = useState('');
  // Honeypot field — bots fill every input; humans don't see this one.
  const [website, setWebsite] = useState('');
  const [status, setStatus] = useState<'idle' | 'submitting' | 'success' | 'error'>('idle');
  const [errorMsg, setErrorMsg] = useState<string>('');

  const onSubmit = async (e: FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    if (status === 'submitting') return;

    if (website) {
      // Honeypot tripped — bot. Fake success and drop.
      setStatus('success');
      return;
    }

    const trimmed = email.trim();
    if (!EMAIL_RE.test(trimmed)) {
      setStatus('error');
      setErrorMsg('That email looks off — double-check the format?');
      return;
    }

    setStatus('submitting');
    setErrorMsg('');

    try {
      const res = await fetch(WAITLIST_ENDPOINT, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          email: trimmed.toLowerCase(),
          source,
          platform_interest: platformInterest,
          referrer: typeof document !== 'undefined' ? document.referrer || null : null,
          user_agent: typeof navigator !== 'undefined' ? navigator.userAgent : null,
          website,  // honeypot — empty for humans
        }),
      });

      if (!res.ok) {
        if (res.status === 429) {
          setStatus('error');
          setErrorMsg("Too many tries — wait a minute then try again.");
          return;
        }
        const body = await res.json().catch(() => ({}));
        setStatus('error');
        setErrorMsg(body?.detail || "Couldn't save that — try again in a sec?");
        return;
      }

      setStatus('success');
    } catch (err) {
      console.error('[Waitlist] network error:', err);
      setStatus('error');
      setErrorMsg("Network error — check your connection?");
    }
  };

  if (status === 'success') {
    return (
      <motion.div
        initial={{ opacity: 0, scale: 0.96, y: 8 }}
        animate={{ opacity: 1, scale: 1, y: 0 }}
        transition={{ duration: 0.4, ease: [0.16, 1, 0.3, 1] }}
        className={`rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-500/10 to-emerald-500/5 p-8 text-center ${className}`}
      >
        <motion.div
          initial={{ scale: 0 }}
          animate={{ scale: 1 }}
          transition={{ delay: 0.15, type: 'spring', stiffness: 200, damping: 15 }}
          className="text-4xl mb-3"
        >
          ✨
        </motion.div>
        <h3 className="text-xl font-semibold text-[var(--color-text)]">{successMessage}</h3>
        <p className="mt-3 text-sm text-[var(--color-text-muted)]">
          You'll be among the first when we launch — no spam, no newsletters, just the link.
        </p>
      </motion.div>
    );
  }

  const inputClass =
    'flex-1 rounded-full bg-[var(--color-surface)] border border-[var(--color-border)] px-5 py-3 text-[var(--color-text)] placeholder:text-[var(--color-text-muted)] focus:outline-none focus:border-emerald-500/60 focus:ring-2 focus:ring-emerald-500/20 transition-all';
  const buttonClass =
    'rounded-full bg-emerald-500 hover:bg-emerald-400 active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed text-black font-semibold px-6 py-3 transition-all shadow-lg shadow-emerald-500/20';

  return (
    <div className={className}>
      <form
        onSubmit={onSubmit}
        className={
          variant === 'inline'
            ? 'flex flex-col sm:flex-row gap-3 max-w-[520px] mx-auto'
            : 'flex flex-col gap-3 max-w-[420px] mx-auto'
        }
        noValidate
      >
        {/* Honeypot — visually hidden but still rendered. */}
        <label className="sr-only" aria-hidden="true">
          Don't fill this out if you're human
          <input
            type="text"
            tabIndex={-1}
            autoComplete="off"
            value={website}
            onChange={(e) => setWebsite(e.target.value)}
          />
        </label>

        <input
          type="email"
          inputMode="email"
          autoComplete="email"
          required
          value={email}
          onChange={(e) => setEmail(e.target.value)}
          placeholder="you@email.com"
          aria-label="Email address"
          className={inputClass}
          disabled={status === 'submitting'}
        />
        <button
          type="submit"
          disabled={status === 'submitting'}
          className={buttonClass}
        >
          {status === 'submitting' ? 'Joining…' : 'Notify me first'}
        </button>
      </form>

      {status === 'error' && errorMsg && (
        <motion.p
          initial={{ opacity: 0, y: -4 }}
          animate={{ opacity: 1, y: 0 }}
          className="mt-3 text-sm text-rose-400 text-center"
          role="alert"
        >
          {errorMsg}
        </motion.p>
      )}

      <p className="mt-4 text-xs text-[var(--color-text-muted)] text-center">
        One email at launch. Unsubscribe anytime.
      </p>
    </div>
  );
}
