// Sticky mobile install bar — pinned to bottom of viewport on mobile only.
// Appears after user scrolls past the result (so it doesn't compete with the
// primary result hero on first paint). Dismissible per-session.
//
// Voice rules:
//   - No em dashes.
//   - No scare quotes.

import { useEffect, useState } from 'react';

const PLAY_STORE_ID = 'com.aifitnesscoach.app';
const SESSION_DISMISS_KEY = 'zealova-sticky-install-dismissed';

interface Props {
  slug: string;
  result?: Record<string, unknown>;
  primary?: string;
}

export default function StickyMobileInstallBar({ slug, result, primary }: Props) {
  const [visible, setVisible] = useState(false);
  const [dismissed, setDismissed] = useState(false);

  useEffect(() => {
    try {
      if (sessionStorage.getItem(SESSION_DISMISS_KEY) === 'true') {
        setDismissed(true);
        return;
      }
    } catch {
      /* ignore */
    }

    const onScroll = () => {
      if (window.scrollY > 600) setVisible(true);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  if (dismissed || !visible) return null;

  const handleOpen = () => {
    const isIos = /iPad|iPhone|iPod/.test(navigator.userAgent);
    if (isIos) {
      // iOS: scroll to install card so user lands on the waitlist form.
      const card = document.getElementById('install-cta-card');
      if (card) card.scrollIntoView({ behavior: 'smooth', block: 'center' });
      return;
    }
    try {
      const payload = result ? btoa(JSON.stringify(result)) : '';
      const deepLink = `zealova://tools/${slug}${payload ? `?result=${payload}` : ''}`;
      const utm = new URLSearchParams({
        utm_source: 'tools',
        utm_medium: slug,
        utm_content: 'sticky-bar',
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
    } catch {
      window.location.href = `https://play.google.com/store/apps/details?id=${PLAY_STORE_ID}`;
    }
  };

  const onDismiss = () => {
    try {
      sessionStorage.setItem(SESSION_DISMISS_KEY, 'true');
    } catch {
      /* ignore */
    }
    setDismissed(true);
  };

  return (
    <div className="sm:hidden fixed bottom-0 left-0 right-0 z-40 px-3 pb-3 pt-2 bg-gradient-to-t from-[#0a0a0a] via-[#0a0a0a]/95 to-transparent pointer-events-none">
      <div className="pointer-events-auto flex items-center gap-2 rounded-2xl border border-emerald-500/30 bg-[#0f1713] shadow-2xl shadow-emerald-500/10 p-2">
        <div className="flex-1 min-w-0 pl-2">
          <p className="text-[11px] uppercase tracking-wider text-[#34d399] font-semibold">Save this result</p>
          <p className="text-xs text-[#d4d4d8] truncate">{primary || 'Track everything in the Zealova app.'}</p>
        </div>
        <button
          onClick={handleOpen}
          className="shrink-0 px-3 py-2 rounded-xl bg-emerald-500 text-[#0a0a0a] text-xs font-bold hover:bg-emerald-400 transition"
        >
          Open app
        </button>
        <button
          onClick={onDismiss}
          aria-label="Dismiss"
          className="shrink-0 w-7 h-7 rounded-lg text-[#71717a] hover:text-[#d4d4d8] hover:bg-[#27272a] transition flex items-center justify-center text-base"
        >
          ×
        </button>
      </div>
    </div>
  );
}
