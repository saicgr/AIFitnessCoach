// Shared page shell for every calculator under /tools/<slug>.
//
// Handles: SEO metadata (title, description, canonical, OG/Twitter, JSON-LD),
// the nav + footer, the page hero, layout slots for inputs/results/methodology,
// breadcrumbs, related-calcs section.
//
// Each calculator page renders a <CalculatorShell ...> wrapper with its own
// content inside.

import { useEffect, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../marketing/MarketingNav';
import MarketingFooter from '../marketing/MarketingFooter';
import RelatedCalcs from './RelatedCalcs';
import EmailCapture from './EmailCapture';
import InstallCta from './InstallCta';
import StickyMobileInstallBar from './StickyMobileInstallBar';
import ExitIntentCapture from './ExitIntentCapture';
import { pingToolUsage } from '../../lib/aiToolsClient';
import { BRANDING } from '../../lib/branding';
import { findCalc } from './calcRegistry';

interface FaqEntry {
  q: string;
  a: string;
}

// Tool -> matching glossary entry. Spreads authority from high-traffic
// calculators to the "what is X" definition pages and captures users who
// land on the tool before they understand the concept.
const GLOSSARY_LINKS: Record<string, { slug: string; term: string }> = {
  'tdee-calculator': { slug: 'tdee', term: 'TDEE' },
  'adaptive-calorie-calculator': { slug: 'tdee', term: 'TDEE' },
  '1rm-calculator': { slug: '1rm', term: 'a one-rep max (1RM)' },
  'bmr-calculator': { slug: 'bmr', term: 'BMR' },
  'macro-calculator': { slug: 'macros', term: 'macros' },
  'adaptive-macro-calculator': { slug: 'macros', term: 'macros' },
  'protein-per-meal-calculator': { slug: 'macros', term: 'macros' },
  'body-fat-calculator': { slug: 'body-fat-percentage', term: 'body fat percentage' },
  'lean-body-mass-calculator': { slug: 'body-fat-percentage', term: 'body fat percentage' },
  'wilks-calculator': { slug: 'wilks-score', term: 'a Wilks score' },
  'vo2-max-calculator': { slug: 'vo2-max', term: 'VO2 max' },
  'sleep-cycle-calculator': { slug: 'sleep-cycles', term: 'sleep cycles' },
  'rir-rpe-converter': { slug: 'rir-rpe', term: 'RIR and RPE' },
  'deload-week-calculator': { slug: 'deload', term: 'a deload' },
  'cut-bulk-duration-calculator': { slug: 'cut-bulk', term: 'cutting and bulking' },
  'mesocycle-volume-calculator': { slug: 'mesocycle', term: 'a mesocycle' },
  'fasting-timer': { slug: 'intermittent-fasting', term: 'intermittent fasting' },
  'target-heart-rate-calculator': { slug: 'zone-2-cardio', term: 'Zone 2 cardio' },
};

interface CalculatorShellProps {
  slug: string;
  title: string;            // <title> + h1
  metaDescription: string;
  intro?: string;           // 1-3 sentence intro under h1
  faqs?: FaqEntry[];        // FAQ accordion + FAQPage JSON-LD
  // Optional anonymized result snapshot. Tool pages that produce a result
  // (e.g. 1RM, AI food photo) pass it so the email-capture row carries
  // context. Plain calculators omit it.
  emailCaptureResult?: Record<string, unknown>;
  // Result-aware install CTA copy. Tools pass these when they have a
  // computed result to phrase the CTA in user-specific terms.
  installPrimary?: string;
  installSecondary?: string;
  // Short headline used for the OG share image and result-aware copy.
  // e.g. "My TDEE", "My 1RM Bench". Falls back to the tool title.
  ogHeadline?: string;
  // Short result string shown big on the OG share card.
  // e.g. "2,450 cal/day" or "235 lb bench".
  ogResult?: string;
  children: ReactNode;
}

export default function CalculatorShell({
  slug,
  title,
  metaDescription,
  intro,
  faqs = [],
  emailCaptureResult,
  installPrimary,
  installSecondary,
  ogHeadline,
  ogResult,
  children,
}: CalculatorShellProps) {
  const calc = findCalc(slug);
  const canonical = `https://${BRANDING.marketingDomain}/free-tools/${slug}`;
  // Per-tool OG image. scripts/generate-og.mjs renders a branded 1200x630
  // card per tool at build time into public/og/tools/<slug>.png, so a
  // shared tool link shows the right preview (not the old hardcoded Google
  // Health card). Per-RESULT dynamic images would need an edge function;
  // the per-tool card is the reliable, bundler-free fix.
  void ogHeadline;
  void ogResult;
  const ogImage = `https://${BRANDING.marketingDomain}/og/tools/${slug}.png`;

  useEffect(() => {
    document.title = `${title} | Zealova`;
    const setMeta = (key: string, value: string, isProperty = false) => {
      const attr = isProperty ? 'property' : 'name';
      let el = document.head.querySelector<HTMLMetaElement>(`meta[${attr}="${key}"]`);
      if (!el) {
        el = document.createElement('meta');
        el.setAttribute(attr, key);
        document.head.appendChild(el);
      }
      el.content = value;
    };
    setMeta('description', metaDescription);
    setMeta('og:title', title, true);
    setMeta('og:description', metaDescription, true);
    setMeta('og:url', canonical, true);
    setMeta('og:type', 'website', true);
    setMeta('og:image', ogImage, true);
    setMeta('og:image:width', '1200', true);
    setMeta('og:image:height', '630', true);
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', title);
    setMeta('twitter:description', metaDescription);
    setMeta('twitter:image', ogImage);
    // iOS smart banner. Apple's native one-tap "Open in App / View" banner
    // for mobile Safari. app-argument carries the slug so the app can
    // route on first open.
    setMeta('apple-itunes-app', `app-id=6745218419, app-argument=zealova://tools/${slug}`);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = canonical;
  }, [slug, title, metaDescription, canonical, ogImage]);

  // Usage counter ping — fires once per (tool, browser session) the first
  // time the tool produces a result. sessionStorage dedup so recomputes
  // and refreshes within one visit don't multi-count.
  useEffect(() => {
    if (!emailCaptureResult) return;
    const key = `zealova-usage-pinged-${slug}`;
    try {
      if (sessionStorage.getItem(key) === '1') return;
      sessionStorage.setItem(key, '1');
    } catch {
      return;
    }
    void pingToolUsage(slug);
  }, [slug, emailCaptureResult]);

  const breadcrumbJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}/` },
      { '@type': 'ListItem', position: 2, name: 'Free Tools', item: `https://${BRANDING.marketingDomain}/free-tools` },
      { '@type': 'ListItem', position: 3, name: title, item: canonical },
    ],
  };

  const faqJsonLd =
    faqs.length > 0
      ? {
          '@context': 'https://schema.org',
          '@type': 'FAQPage',
          mainEntity: faqs.map((f) => ({
            '@type': 'Question',
            name: f.q,
            acceptedAnswer: { '@type': 'Answer', text: f.a },
          })),
        }
      : null;

  const softwareJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'WebApplication',
    name: title,
    url: canonical,
    description: metaDescription,
    applicationCategory: 'HealthApplication',
    operatingSystem: 'All',
    offers: { '@type': 'Offer', price: '0', priceCurrency: 'USD' },
    publisher: { '@type': 'Organization', name: 'Zealova', url: `https://${BRANDING.marketingDomain}` },
  };

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(softwareJsonLd) }}
      />
      {faqJsonLd && (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
        />
      )}

      <main className="max-w-4xl mx-auto px-4 sm:px-6 pt-24 sm:pt-28 pb-16">
        {/* Breadcrumbs */}
        <nav className="text-xs text-zinc-500 mb-6">
          <Link to="/" className="hover:text-zinc-300">Home</Link>
          <span className="mx-2">/</span>
          <Link to="/free-tools" className="hover:text-zinc-300">Free Tools</Link>
          <span className="mx-2">/</span>
          <span className="text-zinc-400">{title}</span>
        </nav>

        {/* Hero */}
        <header className="mb-10">
          <p className="condensed-kicker text-xs text-emerald-400 mb-3">Free Tool</p>
          <h1 className="display-heading text-4xl sm:text-5xl md:text-6xl text-white">{title}</h1>
          {calc?.paidElsewhere && (
            <p className="mt-4 inline-flex items-center gap-2 text-xs px-3 py-1 rounded-full bg-emerald-500 text-black font-semibold">
              <span className="w-1.5 h-1.5 rounded-full bg-black" />
              Free here • Paid in {calc.competitor}
            </p>
          )}
          {intro && (
            <p className="mt-4 text-base sm:text-lg text-zinc-400 leading-relaxed">{intro}</p>
          )}
          {GLOSSARY_LINKS[slug] && (
            <p className="mt-3 text-sm text-zinc-500">
              New to {GLOSSARY_LINKS[slug].term}?{' '}
              <Link
                to={`/glossary/${GLOSSARY_LINKS[slug].slug}`}
                className="text-emerald-400 hover:text-emerald-300 transition-colors"
              >
                Read the plain-English definition &rarr;
              </Link>
            </p>
          )}
        </header>

        {/* Calculator body */}
        <div className="space-y-10">{children}</div>

        {/* Install CTA — peak intent. Only renders when a result exists so
            we don't pitch the app before the user has felt any value.
            Tools omit `emailCaptureResult` until they compute a result;
            static calcs pass it as soon as inputs are valid. */}
        {emailCaptureResult && (
        <div id="install-cta-card" className="mt-10">
          <InstallCta
            slug={slug}
            result={emailCaptureResult}
            primary={installPrimary || `Save this in the Zealova app`}
            secondary={
              installSecondary ||
              'One tap to open. Your result carries over so you can track it for free.'
            }
          />
          {/* Social proof + store badges */}
          <div className="mt-4 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 text-xs text-zinc-500">
            <p>
              Free. No sign-up. Live on Google Play, with a 7-day free trial.
            </p>
            <div className="flex items-center gap-2">
              <a
                href={`https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3D${slug}%26utm_content%3Dbadge`}
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Get it on Google Play"
                className="opacity-80 hover:opacity-100 transition"
              >
                <img
                  src="https://upload.wikimedia.org/wikipedia/commons/7/78/Google_Play_Store_badge_EN.svg"
                  alt="Get it on Google Play"
                  className="h-9"
                  loading="lazy"
                />
              </a>
              <span className="text-[10px] uppercase tracking-wider text-zinc-600">iOS soon</span>
            </div>
          </div>
        </div>
        )}

        {/* FAQ */}
        {faqs.length > 0 && (
          <section className="mt-16 border-t border-zinc-800 pt-12">
            <h2 className="display-heading text-2xl sm:text-3xl text-white mb-6">Frequently asked questions</h2>
            <div className="space-y-3">
              {faqs.map((f, i) => (
                <details
                  key={i}
                  className="group rounded-xl border border-zinc-800 bg-zinc-900 px-4 py-3"
                >
                  <summary className="cursor-pointer list-none flex items-center justify-between font-medium text-white text-sm sm:text-base">
                    <span>{f.q}</span>
                    <span className="ml-3 text-emerald-500 group-open:rotate-45 transition-transform">+</span>
                  </summary>
                  <p className="mt-3 text-sm text-zinc-400 leading-relaxed">{f.a}</p>
                </details>
              ))}
            </div>
          </section>
        )}

        {/* Email capture (banner). Shows after 3s, dismissible per-tool,
            globally suppressed once a user subscribes anywhere. */}
        <div className="mt-12">
          <EmailCapture
            toolSlug={slug}
            variant="banner"
            resultSummary={emailCaptureResult}
          />
        </div>

        <RelatedCalcs currentSlug={slug} />
      </main>

      <MarketingFooter />

      <StickyMobileInstallBar
        slug={slug}
        result={emailCaptureResult}
        primary={installPrimary}
      />

      <ExitIntentCapture toolSlug={slug} resultSummary={emailCaptureResult} />
    </div>
  );
}
