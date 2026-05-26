/**
 * Auto-scrolling marquee of all 36 languages Zealova ships in, rendered in
 * each language's native script. Sourced from `mobile/flutter/lib/l10n/app_*.arb`
 * (36 .arb files as of 2026-05-26 — see `i18n` directory; user-visible label
 * is the endonym, not the English exonym, per request).
 *
 * Pure CSS marquee: the row is rendered twice back-to-back and the wrapper
 * translates -50% over the configured duration so the loop is seamless.
 * Pauses on hover to let users read a specific entry.
 */

const LANGUAGES: { code: string; native: string }[] = [
  { code: 'en', native: 'English' },
  { code: 'es', native: 'Español' },
  { code: 'fr', native: 'Français' },
  { code: 'de', native: 'Deutsch' },
  { code: 'it', native: 'Italiano' },
  { code: 'pt', native: 'Português' },
  { code: 'nl', native: 'Nederlands' },
  { code: 'sv', native: 'Svenska' },
  { code: 'fi', native: 'Suomi' },
  { code: 'pl', native: 'Polski' },
  { code: 'cs', native: 'Čeština' },
  { code: 'tr', native: 'Türkçe' },
  { code: 'ru', native: 'Русский' },
  { code: 'ar', native: 'العربية' },
  { code: 'ur', native: 'اردو' },
  { code: 'hi', native: 'हिन्दी' },
  { code: 'bn', native: 'বাংলা' },
  { code: 'pa', native: 'ਪੰਜਾਬੀ' },
  { code: 'mr', native: 'मराठी' },
  { code: 'ta', native: 'தமிழ்' },
  { code: 'te', native: 'తెలుగు' },
  { code: 'kn', native: 'ಕನ್ನಡ' },
  { code: 'ml', native: 'മലയാളം' },
  { code: 'or', native: 'ଓଡ଼ିଆ' },
  { code: 'ne', native: 'नेपाली' },
  { code: 'zh', native: '中文' },
  { code: 'ja', native: '日本語' },
  { code: 'ko', native: '한국어' },
  { code: 'th', native: 'ไทย' },
  { code: 'vi', native: 'Tiếng Việt' },
  { code: 'id', native: 'Bahasa Indonesia' },
  { code: 'ms', native: 'Bahasa Melayu' },
  { code: 'jv', native: 'Basa Jawa' },
  { code: 'tl', native: 'Tagalog' },
  { code: 'sw', native: 'Kiswahili' },
  { code: 'ha', native: 'Hausa' },
];

const RTL = new Set(['ar', 'ur']);

interface LanguageMarqueeProps {
  /** Marquee duration in seconds. Lower = faster scroll. */
  durationSeconds?: number;
}

export default function LanguageMarquee({ durationSeconds = 60 }: LanguageMarqueeProps) {
  return (
    <section className="py-16 sm:py-20 px-6 overflow-hidden">
      <div className="max-w-[980px] mx-auto text-center mb-10">
        <p className="text-[13px] uppercase tracking-[0.18em] text-[#86868b] mb-3">
          Now in your language
        </p>
        <h3 className="text-[28px] sm:text-[36px] font-semibold tracking-[-0.02em] text-white">
          <span className="bg-gradient-to-r from-white to-white/60 bg-clip-text text-transparent">
            {LANGUAGES.length} languages, fully translated
          </span>
        </h3>
      </div>

      <div
        className="relative w-full"
        style={{
          maskImage:
            'linear-gradient(to right, transparent 0, black 96px, black calc(100% - 96px), transparent 100%)',
          WebkitMaskImage:
            'linear-gradient(to right, transparent 0, black 96px, black calc(100% - 96px), transparent 100%)',
        }}
      >
        <div
          className="flex w-max gap-3 sm:gap-4 hover:[animation-play-state:paused]"
          style={{
            animation: `language-marquee-scroll ${durationSeconds}s linear infinite`,
          }}
        >
          {[...LANGUAGES, ...LANGUAGES].map((lang, i) => (
            <span
              key={`${lang.code}-${i}`}
              dir={RTL.has(lang.code) ? 'rtl' : 'ltr'}
              lang={lang.code}
              className="shrink-0 inline-flex items-center px-5 py-2.5 rounded-full border border-white/10 bg-white/[0.03] text-[15px] sm:text-[16px] text-white/85 whitespace-nowrap backdrop-blur-sm"
            >
              {lang.native}
            </span>
          ))}
        </div>
      </div>

      <style>{`
        @keyframes language-marquee-scroll {
          from { transform: translateX(0); }
          to   { transform: translateX(-50%); }
        }
        @media (prefers-reduced-motion: reduce) {
          [style*="language-marquee-scroll"] {
            animation: none !important;
          }
        }
      `}</style>
    </section>
  );
}
