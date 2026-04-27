import { useEffect, useMemo, useRef, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import MarketingNav from '../components/marketing/MarketingNav';
import MarketingFooter from '../components/marketing/MarketingFooter';
import { BRANDING } from '../lib/branding';

// Keep the store URLs co-located with MarketingLanding's usage. iOS App
// Store link will become live once the App Store listing ships; until
// then the Play Store link is the primary CTA and the iOS button links
// to the TestFlight placeholder (same link used on the homepage).
const PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app';
const APP_STORE =
  'https://apps.apple.com/app/zealova/id0000000000'; // TODO: replace when live

// Reject obviously bogus codes up-front — server enforces the same shape,
// but a cheap client-side check avoids asking the user to copy-paste
// garbage like "ABC-123!" that the apply endpoint will 400 anyway.
const CODE_SHAPE = /^[A-Z0-9]{4,12}$/;

function normalizeCode(raw: string | undefined | null): string | null {
  if (!raw) return null;
  const cleaned = raw
    .toUpperCase()
    .replace(/[^A-Z0-9]/g, '')
    .trim();
  if (!cleaned || !CODE_SHAPE.test(cleaned)) return null;
  return cleaned;
}

function detectPlatform(): 'ios' | 'android' | 'desktop' {
  if (typeof navigator === 'undefined') return 'desktop';
  const ua = navigator.userAgent || '';
  if (/iPhone|iPad|iPod/i.test(ua)) return 'ios';
  if (/Android/i.test(ua)) return 'android';
  return 'desktop';
}

/**
 * `/invite/:code` landing page.
 *
 * Two goals:
 *   1. If the user has the Zealova app installed AND we're on iOS/Android,
 *      try to open it via the custom `zealova://` scheme. The OS silently
 *      swallows the navigation if no app handles it — so we also show
 *      store CTAs as a fallback.
 *   2. If the app isn't installed, show the code prominently so the user
 *      can copy it, install the app, and paste it into the in-app
 *      "Have a code from a friend?" row. The Universal Link path can't
 *      survive the App Store round-trip (no Branch.io), so this is the
 *      intentional backstop for deferred installs.
 */
export default function Invite() {
  const { code } = useParams<{ code: string }>();
  const normalized = useMemo(() => normalizeCode(code), [code]);
  const [copied, setCopied] = useState(false);
  const [attemptedOpen, setAttemptedOpen] = useState(false);
  const platform = useMemo(detectPlatform, []);
  const didAutoOpenRef = useRef(false);

  // On iOS/Android, try the custom scheme once on first paint. Desktop
  // browsers don't have an app, so we skip the redirect there.
  useEffect(() => {
    if (didAutoOpenRef.current) return;
    if (!normalized) return;
    if (platform === 'desktop') return;
    didAutoOpenRef.current = true;
    setAttemptedOpen(true);
    // iframe-based trigger avoids the Safari "cannot open page" modal
    // that appears with window.location when no handler is registered.
    const iframe = document.createElement('iframe');
    iframe.style.display = 'none';
    iframe.src = `zealova://invite/${normalized}`;
    document.body.appendChild(iframe);
    const cleanup = window.setTimeout(() => {
      document.body.removeChild(iframe);
    }, 1500);
    return () => {
      window.clearTimeout(cleanup);
      if (iframe.parentNode) iframe.parentNode.removeChild(iframe);
    };
  }, [normalized, platform]);

  const handleCopy = async () => {
    if (!normalized) return;
    try {
      await navigator.clipboard.writeText(normalized);
      setCopied(true);
      window.setTimeout(() => setCopied(false), 2000);
    } catch {
      setCopied(false);
    }
  };

  if (!normalized) {
    return (
      <div className="min-h-screen bg-black text-white">
        <MarketingNav />
        <div className="max-w-xl mx-auto px-6 pt-28 pb-24 text-center">
          <div className="text-5xl mb-6">😕</div>
          <h1 className="text-3xl font-bold mb-4">Invite link not recognized</h1>
          <p className="text-white/70 mb-8">
            The code in this link looks invalid. Ask your friend to re-share the
            invite from their Invite Friends screen.
          </p>
          <Link
            to="/"
            className="inline-block px-6 py-3 bg-white text-black rounded-full font-semibold hover:bg-white/90 transition-colors"
          >
            Back to {BRANDING.appName}
          </Link>
        </div>
        <MarketingFooter />
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black text-white">
      <MarketingNav />

      <div className="max-w-2xl mx-auto px-6 pt-20 pb-24">
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-2 px-4 py-1.5 bg-green-500/10 border border-green-500/30 rounded-full text-green-400 text-xs font-semibold mb-6 uppercase tracking-wider">
            <svg className="w-3.5 h-3.5" fill="currentColor" viewBox="0 0 20 20">
              <path
                fillRule="evenodd"
                d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z"
                clipRule="evenodd"
              />
            </svg>
            You've been invited
          </div>
          <h1 className="text-4xl md:text-5xl font-bold mb-3 leading-tight">
            Your friend wants you<br />on {BRANDING.appName}.
          </h1>
          <p className="text-white/70 text-lg">
            Use their code at sign-up and you both earn a bonus once you
            complete your first workout.
          </p>
        </div>

        {/* Code card */}
        <div className="bg-gradient-to-br from-green-500/15 to-green-500/5 border border-green-500/30 rounded-2xl p-8 mb-6">
          <div className="text-xs font-bold text-white/60 uppercase tracking-widest mb-3 text-center">
            Your referral code
          </div>
          <button
            type="button"
            onClick={handleCopy}
            className="w-full bg-black/40 border border-white/20 rounded-xl py-5 px-4 hover:bg-black/60 transition-colors group"
            aria-label="Copy code to clipboard"
          >
            <div className="flex items-center justify-center gap-3">
              <span
                className="text-4xl md:text-5xl font-bold tracking-[0.3em] font-mono"
                data-testid="referral-code"
              >
                {normalized}
              </span>
              <svg
                className="w-6 h-6 text-white/50 group-hover:text-white transition-colors"
                fill="none"
                stroke="currentColor"
                viewBox="0 0 24 24"
              >
                <path
                  strokeLinecap="round"
                  strokeLinejoin="round"
                  strokeWidth="2"
                  d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
                />
              </svg>
            </div>
          </button>
          <p className="text-center text-xs text-white/50 mt-3">
            {copied ? '✓ Copied — paste it after you sign up' : 'Tap to copy'}
          </p>
        </div>

        {/* Install CTAs */}
        <div className="bg-white/5 border border-white/10 rounded-2xl p-6 mb-6">
          <h2 className="text-sm font-bold uppercase tracking-widest text-white/60 mb-4 text-center">
            {attemptedOpen
              ? "Don't have the app yet?"
              : 'Step 1 — install the app'}
          </h2>
          <div className="flex flex-col sm:flex-row gap-3">
            <a
              href={APP_STORE}
              target="_blank"
              rel="noopener noreferrer"
              className="flex-1 flex items-center justify-center gap-3 bg-white text-black rounded-xl py-4 px-5 font-semibold hover:bg-white/90 transition-colors"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M17.05 20.28c-.98.95-2.05.8-3.08.35-1.09-.46-2.09-.48-3.24 0-1.44.62-2.2.44-3.06-.35C2.79 15.25 3.51 7.59 9.05 7.31c1.35.07 2.29.74 3.08.8 1.18-.24 2.31-.93 3.57-.84 1.51.12 2.65.72 3.4 1.8-3.12 1.87-2.38 5.98.48 7.13-.57 1.5-1.31 2.99-2.54 4.09l.01-.01zM12.03 7.25c-.15-2.23 1.66-4.07 3.74-4.25.29 2.58-2.34 4.5-3.74 4.25z" />
              </svg>
              App Store
            </a>
            <a
              href={PLAY_STORE}
              target="_blank"
              rel="noopener noreferrer"
              className="flex-1 flex items-center justify-center gap-3 bg-white text-black rounded-xl py-4 px-5 font-semibold hover:bg-white/90 transition-colors"
            >
              <svg className="w-6 h-6" viewBox="0 0 24 24" fill="currentColor">
                <path d="M3.609 1.814L13.792 12 3.61 22.186a.996.996 0 01-.61-.92V2.734a1 1 0 01.609-.92zm10.89 10.893l2.302 2.302-10.937 6.333 8.635-8.635zm3.199-3.198l2.807 1.626a1 1 0 010 1.73l-2.808 1.626L15.195 12l2.503-2.491zM5.864 2.658L16.802 8.99l-2.302 2.302-8.636-8.634z" />
              </svg>
              Google Play
            </a>
          </div>
          <p className="text-center text-xs text-white/50 mt-4 leading-relaxed">
            After installing, open the app and tap{' '}
            <strong className="text-white/80">Got a code from a friend?</strong>{' '}
            on the sign-in screen to redeem <code className="px-1.5 py-0.5 bg-white/10 rounded text-green-400">{normalized}</code>.
          </p>
        </div>

        {/* How it works */}
        <div className="bg-white/5 border border-white/10 rounded-2xl p-6">
          <h2 className="text-sm font-bold uppercase tracking-widest text-white/60 mb-4">
            What you both get
          </h2>
          <ul className="space-y-3 text-sm text-white/80">
            <li className="flex items-start gap-3">
              <span className="text-green-400 font-bold">✓</span>
              <span>2× Premium Crate + 500 XP + 24h 2× XP token — for each of you</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-green-400 font-bold">✓</span>
              <span>Rewards unlock after the invited friend completes their first workout</span>
            </li>
            <li className="flex items-start gap-3">
              <span className="text-green-400 font-bold">✓</span>
              <span>Hit 3 / 10 / 25 / 50 / 100 / 250 referrals for free {BRANDING.appName} merch</span>
            </li>
          </ul>
        </div>

        <div className="text-center mt-12 text-sm text-white/40">
          <Link to="/" className="hover:text-white/80 transition-colors">
            Learn more about {BRANDING.appName} →
          </Link>
        </div>
      </div>

      <MarketingFooter />
    </div>
  );
}
