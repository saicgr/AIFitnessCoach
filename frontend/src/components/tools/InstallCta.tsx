// Smart deep-link CTA: tries to open the Zealova Android app via `zealova://`.
// Falls back to the Play Store after 1.5s if the app didn't take over.
// On iOS, shows an "iOS coming soon" email capture instead of a dead link.
//
// Each calculator passes a `slug` (the in-app deep-link path) and a `result`
// object that the app reads from URL params on open. So a user who calculates
// their 1RM on the web can tap "Open in Zealova" and the app pre-fills the
// result on the workout-edit screen.

import { useState } from 'react';

interface InstallCtaProps {
  slug: string;
  result?: Record<string, unknown>;
  primary?: string;          // Main CTA copy, contextual per calc
  secondary?: string;        // Optional sub-text under the button
  className?: string;
}

const PLAY_STORE_ID = 'com.aifitnesscoach.app';

export default function InstallCta({
  slug,
  result,
  primary = 'Open in Zealova',
  secondary,
  className = '',
}: InstallCtaProps) {
  const [iosEmail, setIosEmail] = useState('');
  const [iosSubmitted, setIosSubmitted] = useState(false);
  const isIos =
    typeof navigator !== 'undefined' &&
    /iPad|iPhone|iPod/.test(navigator.userAgent);

  const handleOpen = () => {
    try {
      const payload = result ? btoa(JSON.stringify(result)) : '';
      const deepLink = `zealova://tools/${slug}${payload ? `?result=${payload}` : ''}`;
      const utm = new URLSearchParams({
        utm_source: 'tools',
        utm_medium: slug,
        utm_content: 'result-cta',
      });
      const playStore = `https://play.google.com/store/apps/details?id=${PLAY_STORE_ID}&referrer=${utm}`;

      let appOpened = false;
      const handler = () => {
        if (document.hidden) appOpened = true;
      };
      document.addEventListener('visibilitychange', handler);

      window.location.href = deepLink;

      window.setTimeout(() => {
        document.removeEventListener('visibilitychange', handler);
        if (!appOpened) window.location.href = playStore;
      }, 1500);
    } catch (err) {
      window.location.href = `https://play.google.com/store/apps/details?id=${PLAY_STORE_ID}`;
    }
  };

  const handleIosSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setIosSubmitted(true);
    // TODO: wire to /api/waitlist endpoint when backend supports it.
  };

  if (isIos) {
    return (
      <div className={`rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 to-zinc-900 p-6 ${className}`}>
        <p className="text-sm font-semibold text-emerald-400 mb-1">iOS coming soon</p>
        <p className="text-base text-white font-bold mb-2">{primary}</p>
        {secondary && <p className="text-sm text-zinc-400 mb-4">{secondary}</p>}
        {iosSubmitted ? (
          <p className="text-sm text-emerald-400">You're on the iOS waitlist. We'll email you at launch.</p>
        ) : (
          <form onSubmit={handleIosSubmit} className="flex gap-2 flex-col sm:flex-row">
            <input
              type="email"
              required
              value={iosEmail}
              onChange={(e) => setIosEmail(e.target.value)}
              placeholder="you@example.com"
              className="flex-1 px-3 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <button
              type="submit"
              className="px-4 py-2 rounded-lg bg-emerald-500 text-zinc-900 text-sm font-semibold hover:bg-emerald-400 transition"
            >
              Notify me
            </button>
          </form>
        )}
      </div>
    );
  }

  return (
    <div className={`rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 to-zinc-900 p-6 ${className}`}>
      <p className="text-base text-white font-bold mb-1">{primary}</p>
      {secondary && <p className="text-sm text-zinc-400 mb-4">{secondary}</p>}
      <button
        onClick={handleOpen}
        className="w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
      >
        Open in Zealova
      </button>
      <p className="text-xs text-zinc-500 mt-3">
        Free 7-day trial. $7.99/mo or $59.99/yr after. Cancel anytime.
      </p>
    </div>
  );
}
