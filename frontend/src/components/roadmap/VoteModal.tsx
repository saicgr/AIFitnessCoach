import { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import type { RoadmapFeature } from '../../data/roadmap';
import { voteForFeature, markVoted, getIdentity, saveIdentity } from '../../lib/roadmapApi';

interface VoteModalProps {
  feature: RoadmapFeature;
  onClose: () => void;
  onVoted: (slug: string, newCount: number) => void;
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;
const CONFETTI = ['#3b82f6', '#10b981', '#f59e0b', '#ec4899', '#8b5cf6'];

/** Lightweight dependency-free confetti burst. */
function ConfettiBurst() {
  return (
    <div className="pointer-events-none absolute inset-0 overflow-hidden">
      {Array.from({ length: 22 }).map((_, i) => {
        const angle = (i / 22) * Math.PI * 2;
        const dist = 90 + Math.random() * 70;
        return (
          <motion.span
            key={i}
            className="absolute left-1/2 top-1/3 h-2 w-2 rounded-[2px]"
            style={{ backgroundColor: CONFETTI[i % CONFETTI.length] }}
            initial={{ x: 0, y: 0, opacity: 1, scale: 1, rotate: 0 }}
            animate={{
              x: Math.cos(angle) * dist,
              y: Math.sin(angle) * dist + 40,
              opacity: 0,
              scale: 0.4,
              rotate: Math.random() * 360,
            }}
            transition={{ duration: 1.1, ease: 'easeOut' }}
          />
        );
      })}
    </div>
  );
}

export default function VoteModal({ feature, onClose, onVoted }: VoteModalProps) {
  const [email, setEmail] = useState(getIdentity().email || '');
  const [notify, setNotify] = useState(true);
  const [honeypot, setHoneypot] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'done'>('idle');
  const [error, setError] = useState<string | null>(null);
  const inputRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    inputRef.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  const submit = async () => {
    const clean = email.trim().toLowerCase();
    if (!EMAIL_RE.test(clean)) {
      setError('Enter a valid email address.');
      return;
    }
    setStatus('sending');
    setError(null);
    try {
      const res = await voteForFeature(feature.slug, clean, notify, honeypot);
      markVoted(feature.slug);
      saveIdentity({ email: clean });
      onVoted(feature.slug, res.vote_count);
      setStatus('done');
      setTimeout(onClose, 1900);
    } catch (e) {
      setStatus('idle');
      setError(e instanceof Error ? e.message : 'Something went wrong.');
    }
  };

  return (
    <motion.div
      className="fixed inset-0 z-[60] flex items-center justify-center p-4"
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/55 backdrop-blur-sm" />

      <motion.div
        className="relative w-full max-w-sm rounded-2xl border border-white/10 bg-[#0D0D0D] text-white p-7 shadow-2xl"
        initial={{ scale: 0.94, y: 12 }}
        animate={{ scale: 1, y: 0 }}
        exit={{ scale: 0.94, y: 12 }}
        transition={{ type: 'spring', damping: 24, stiffness: 320 }}
        onClick={(e) => e.stopPropagation()}
      >
        <button
          onClick={onClose}
          aria-label="Close"
          className="absolute right-3.5 top-3.5 flex h-8 w-8 items-center justify-center rounded-full text-white/40 hover:bg-white/10 hover:text-white transition-colors"
        >
          <svg className="h-4 w-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={2}>
            <path strokeLinecap="round" strokeLinejoin="round" d="M6 18L18 6M6 6l12 12" />
          </svg>
        </button>

        <AnimatePresence mode="wait">
          {status === 'done' ? (
            <motion.div
              key="done"
              className="relative py-6 text-center"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <ConfettiBurst />
              <div className="relative">
                <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-full bg-volt-500 text-black">
                  <svg className="h-7 w-7" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={3}>
                    <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                  </svg>
                </div>
                <h3 className="text-lg font-bold text-white">Vote counted</h3>
                <p className="mt-1 text-sm text-white/60">
                  Thanks for shaping the roadmap.
                  {notify && ' We’ll email you the day this ships.'}
                </p>
              </div>
            </motion.div>
          ) : (
            <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
              <p className="condensed-kicker text-xs text-volt-400">Vote for</p>
              <h3 className="mt-1.5 text-xl font-bold leading-snug text-white">
                {feature.title}
              </h3>

              <input
                ref={inputRef}
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                onKeyDown={(e) => e.key === 'Enter' && submit()}
                placeholder="you@email.com"
                className="mt-5 w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder:text-white/35 focus:border-volt-500/60 focus:outline-none focus:ring-2 focus:ring-volt-500/20"
              />

              {/* Honeypot — hidden from humans, bots fill it. */}
              <input
                type="text"
                tabIndex={-1}
                autoComplete="off"
                value={honeypot}
                onChange={(e) => setHoneypot(e.target.value)}
                className="absolute left-[-9999px] h-0 w-0"
                aria-hidden="true"
              />

              <label className="mt-3 flex cursor-pointer items-center gap-2.5 text-[13px] text-white/60">
                <input
                  type="checkbox"
                  checked={notify}
                  onChange={(e) => setNotify(e.target.checked)}
                  className="h-4 w-4 rounded border-white/10 accent-volt-500"
                />
                Email me when this ships
              </label>

              {error && <p className="mt-3 text-[13px] text-rose-500">{error}</p>}

              <button
                onClick={submit}
                disabled={status === 'sending'}
                className="btn-volt mt-5 w-full rounded-xl py-3 text-sm disabled:opacity-60"
              >
                {status === 'sending' ? 'Counting…' : 'Vote'}
              </button>
              <p className="mt-3 text-center text-[11px] text-white/45">
                One vote per email. We never share it.
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}
