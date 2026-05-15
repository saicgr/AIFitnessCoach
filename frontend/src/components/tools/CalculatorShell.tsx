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
import { BRANDING } from '../../lib/branding';
import { findCalc } from './calcRegistry';

interface FaqEntry {
  q: string;
  a: string;
}

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
  children: ReactNode;
}

export default function CalculatorShell({
  slug,
  title,
  metaDescription,
  intro,
  faqs = [],
  emailCaptureResult,
  children,
}: CalculatorShellProps) {
  const calc = findCalc(slug);
  const canonical = `https://${BRANDING.marketingDomain}/free-tools/${slug}`;

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
    setMeta('twitter:card', 'summary_large_image');
    setMeta('twitter:title', title);
    setMeta('twitter:description', metaDescription);

    let canonicalLink = document.head.querySelector<HTMLLinkElement>('link[rel="canonical"]');
    if (!canonicalLink) {
      canonicalLink = document.createElement('link');
      canonicalLink.rel = 'canonical';
      document.head.appendChild(canonicalLink);
    }
    canonicalLink.href = canonical;
  }, [slug, title, metaDescription, canonical]);

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

      <main className="max-w-4xl mx-auto px-4 sm:px-6 pt-8 sm:pt-12 pb-16">
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
          <h1 className="text-3xl sm:text-4xl font-bold text-white tracking-tight">{title}</h1>
          {calc?.paidElsewhere && (
            <p className="mt-3 inline-flex items-center gap-2 text-xs px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-400 border border-emerald-500/20 font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-500" />
              Free here • Paid in {calc.competitor}
            </p>
          )}
          {intro && (
            <p className="mt-4 text-base sm:text-lg text-zinc-400 leading-relaxed">{intro}</p>
          )}
        </header>

        {/* Calculator body */}
        <div className="space-y-10">{children}</div>

        {/* FAQ */}
        {faqs.length > 0 && (
          <section className="mt-16 border-t border-zinc-800 pt-12">
            <h2 className="text-xl font-bold text-white mb-6">Frequently asked questions</h2>
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
    </div>
  );
}
