import { useEffect, useRef, useState } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { suggestFeature } from '../../lib/roadmapApi';

interface SuggestFeatureModalProps {
  onClose: () => void;
}

const EMAIL_RE = /^[^@\s]+@[^@\s]+\.[^@\s]+$/;

export default function SuggestFeatureModal({ onClose }: SuggestFeatureModalProps) {
  const [email, setEmail] = useState('');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [honeypot, setHoneypot] = useState('');
  const [status, setStatus] = useState<'idle' | 'sending' | 'done'>('idle');
  const [error, setError] = useState<string | null>(null);
  const titleRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    titleRef.current?.focus();
    const onKey = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [onClose]);

  const submit = async () => {
    if (title.trim().length < 3) return setError('Give your idea a short title.');
    if (body.trim().length < 10) return setError('Add a sentence or two of detail.');
    if (!EMAIL_RE.test(email.trim())) return setError('Enter a valid email so we can follow up.');
    setStatus('sending');
    setError(null);
    try {
      await suggestFeature(email.trim().toLowerCase(), title.trim(), body.trim(), honeypot);
      setStatus('done');
      setTimeout(onClose, 2100);
    } catch (e) {
      setStatus('idle');
      setError(e instanceof Error ? e.message : 'Something went wrong.');
    }
  };

  const fieldClass =
    'w-full rounded-xl border border-white/10 bg-white/5 px-4 py-3 text-sm text-white placeholder:text-white/35 focus:border-volt-500/60 focus:outline-none focus:ring-2 focus:ring-volt-500/20';

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
        className="relative w-full max-w-md rounded-2xl border border-white/10 bg-[#0D0D0D] text-white p-7 shadow-2xl"
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
              className="py-6 text-center"
              initial={{ opacity: 0, scale: 0.9 }}
              animate={{ opacity: 1, scale: 1 }}
            >
              <div className="mx-auto mb-3 flex h-14 w-14 items-center justify-center rounded-full bg-volt-500 text-black">
                <svg className="h-7 w-7" fill="none" stroke="currentColor" viewBox="0 0 24 24" strokeWidth={3}>
                  <path strokeLinecap="round" strokeLinejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                </svg>
              </div>
              <h3 className="text-lg font-bold text-white">Idea received</h3>
              <p className="mt-1 text-sm text-white/60">
                We read every suggestion. If it makes the board, you’ll be the first to know.
              </p>
            </motion.div>
          ) : (
            <motion.div key="form" initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
              <p className="condensed-kicker text-xs text-volt-400">
                Suggest a feature
              </p>
              <h3 className="mt-1.5 text-xl font-bold text-white">
                What should we build?
              </h3>
              <p className="mt-1 text-[13px] text-white/60">
                Good ideas get added to the board for everyone to vote on.
              </p>

              <div className="mt-5 space-y-3">
                <input
                  ref={titleRef}
                  type="text"
                  value={title}
                  onChange={(e) => setTitle(e.target.value)}
                  placeholder="Feature in a few words"
                  maxLength={140}
                  className={fieldClass}
                />
                <textarea
                  value={body}
                  onChange={(e) => setBody(e.target.value)}
                  placeholder="What would it do, and why does it matter to you?"
                  rows={4}
                  maxLength={1000}
                  className={`${fieldClass} resize-none`}
                />
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@email.com"
                  className={fieldClass}
                />
                {/* Honeypot */}
                <input
                  type="text"
                  tabIndex={-1}
                  autoComplete="off"
                  value={honeypot}
                  onChange={(e) => setHoneypot(e.target.value)}
                  className="absolute left-[-9999px] h-0 w-0"
                  aria-hidden="true"
                />
              </div>

              {error && <p className="mt-3 text-[13px] text-rose-500">{error}</p>}

              <button
                onClick={submit}
                disabled={status === 'sending'}
                className="btn-volt mt-5 w-full rounded-xl py-3 text-sm disabled:opacity-60"
              >
                {status === 'sending' ? 'Sending…' : 'Send suggestion'}
              </button>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </motion.div>
  );
}
