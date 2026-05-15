// Full-screen interstitial shown when an AI tool's per-IP rate limit is hit.
// Converts a dead-end (locked tool) into the highest-intent install moment.
//
// Triggered by the parent passing `open={true}` once the API has returned
// a 429 or a result with uses_remaining_today === 0. Dismissible.

import { useEffect } from 'react';

interface Props {
  open: boolean;
  onClose: () => void;
  slug: string;
  toolName: string;
  resetWindow?: string; // e.g. "24 hours", "1 hour"
  // 'limit'    = caller hit their own per-IP cap.
  // 'capacity' = tool is globally budget-locked for everyone right now.
  kind?: 'limit' | 'capacity';
}

const PLAY_STORE_ID = 'com.aifitnesscoach.app';

export default function RateLimitModal({
  open,
  onClose,
  slug,
  toolName,
  resetWindow = '24 hours',
  kind = 'limit',
}: Props) {
  useEffect(() => {
    if (!open) return;
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') onClose();
    };
    document.addEventListener('keydown', onKey);
    document.body.style.overflow = 'hidden';
    return () => {
      document.removeEventListener('keydown', onKey);
      document.body.style.overflow = '';
    };
  }, [open, onClose]);

  if (!open) return null;

  const playStoreUrl = `https://play.google.com/store/apps/details?id=${PLAY_STORE_ID}&referrer=${new URLSearchParams(
    {
      utm_source: 'tools',
      utm_medium: slug,
      utm_content: 'rate-limit-interstitial',
    },
  ).toString()}`;

  const isIos =
    typeof navigator !== 'undefined' && /iPad|iPhone|iPod/.test(navigator.userAgent);

  return (
    <div
      className="fixed inset-0 z-50 flex items-center justify-center bg-black/80 backdrop-blur-md p-4"
      onClick={onClose}
    >
      <div
        onClick={(e) => e.stopPropagation()}
        className="w-full max-w-lg rounded-3xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 via-zinc-900 to-zinc-950 shadow-2xl shadow-emerald-500/10 p-7 sm:p-9 relative"
      >
        <button
          onClick={onClose}
          aria-label="Close"
          className="absolute top-3 right-3 w-9 h-9 rounded-lg text-zinc-500 hover:text-zinc-200 hover:bg-zinc-800 transition flex items-center justify-center text-xl"
        >
          ×
        </button>

        <p className="text-xs font-bold uppercase tracking-widest text-emerald-400 mb-3">
          {kind === 'capacity' ? 'Tool at capacity' : 'Daily limit reached'}
        </p>
        <h3 className="text-2xl sm:text-3xl font-bold text-white tracking-tight leading-tight">
          {kind === 'capacity'
            ? `The free ${toolName} is busy right now.`
            : `You hit your free ${toolName} limit.`}
        </h3>
        <p className="mt-3 text-sm text-zinc-400 leading-relaxed">
          {kind === 'capacity'
            ? `So many people are using this free tool that we've hit today's shared limit. The Zealova app has no shared cap, so you can run it now.`
            : `To keep this tool free for everyone, web access resets every ${resetWindow}. Get unlimited use in the Zealova app, plus auto-tracking and weekly adaptation.`}
        </p>

        <div className="mt-6 grid grid-cols-1 gap-2 text-sm">
          <div className="flex items-center gap-2 text-zinc-300">
            <span className="text-emerald-400">✓</span>
            <span>Unlimited AI analyses</span>
          </div>
          <div className="flex items-center gap-2 text-zinc-300">
            <span className="text-emerald-400">✓</span>
            <span>Every result auto-saved to your history</span>
          </div>
          <div className="flex items-center gap-2 text-zinc-300">
            <span className="text-emerald-400">✓</span>
            <span>7-day free trial. $7.99/mo or $59.99/yr.</span>
          </div>
        </div>

        <div className="mt-7 flex flex-col gap-3">
          {isIos ? (
            <a
              href="/waitlist"
              className="w-full text-center px-5 py-3.5 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
            >
              Join iOS waitlist
            </a>
          ) : (
            <a
              href={playStoreUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="w-full text-center px-5 py-3.5 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
            >
              Get Zealova for Android
            </a>
          )}
          <button
            onClick={onClose}
            className="w-full text-center px-5 py-2.5 rounded-xl text-sm text-zinc-400 hover:text-zinc-200 transition"
          >
            I&apos;ll come back tomorrow
          </button>
        </div>

        <p className="mt-5 text-[11px] text-zinc-600 text-center">
          <span className="text-amber-400">★ 4.9</span> from 1,200+ users on Google Play
        </p>
      </div>
    </div>
  );
}
