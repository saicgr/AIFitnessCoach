// Shared page shell for every glossary entry under /glossary/<term>.
//
// Each page targets a single high-volume "what is X" search query and is
// optimized for AI Overviews. The shell handles SEO metadata, JSON-LD
// (DefinedTerm + BreadcrumbList + FAQPage + Article), breadcrumbs, and a
// prominent funnel to the matching calculator.

import { useEffect, type ReactNode } from 'react';
import { Link } from 'react-router-dom';
import MarketingNav from '../marketing/MarketingNav';
import MarketingFooter from '../marketing/MarketingFooter';
import { BRANDING } from '../../lib/branding';

interface FaqEntry {
  q: string;
  a: string;
}

interface GlossaryShellProps {
  term: string;                  // Display name, e.g. "One-Rep Max (1RM)"
  slug: string;                  // URL slug, e.g. "1rm"
  metaDescription: string;
  relatedCalcSlug?: string;      // e.g. "1rm-calculator"
  relatedCalcName?: string;      // e.g. "1RM Calculator"
  faqs?: FaqEntry[];
  children: ReactNode;
}

export default function GlossaryShell({
  term,
  slug,
  metaDescription,
  relatedCalcSlug,
  relatedCalcName,
  faqs = [],
  children,
}: GlossaryShellProps) {
  const canonical = `https://${BRANDING.marketingDomain}/glossary/${slug}`;
  const title = `What is ${term}? Definition, Formula, and Use`;

  useEffect(() => {
    document.title = `${term} | Zealova Glossary`;
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
    setMeta('og:type', 'article', true);
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
  }, [slug, term, title, metaDescription, canonical]);

  const breadcrumbJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'BreadcrumbList',
    itemListElement: [
      { '@type': 'ListItem', position: 1, name: 'Home', item: `https://${BRANDING.marketingDomain}/` },
      { '@type': 'ListItem', position: 2, name: 'Glossary', item: `https://${BRANDING.marketingDomain}/glossary` },
      { '@type': 'ListItem', position: 3, name: term, item: canonical },
    ],
  };

  const definedTermJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'DefinedTerm',
    name: term,
    description: metaDescription,
    url: canonical,
    inDefinedTermSet: {
      '@type': 'DefinedTermSet',
      name: 'Zealova Fitness Glossary',
      url: `https://${BRANDING.marketingDomain}/glossary`,
    },
  };

  const articleJsonLd = {
    '@context': 'https://schema.org',
    '@type': 'Article',
    headline: title,
    description: metaDescription,
    url: canonical,
    author: { '@type': 'Organization', name: 'Zealova' },
    publisher: {
      '@type': 'Organization',
      name: 'Zealova',
      url: `https://${BRANDING.marketingDomain}`,
    },
    mainEntityOfPage: canonical,
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

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(definedTermJsonLd) }}
      />
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }}
      />
      {faqJsonLd && (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
        />
      )}

      <main className="max-w-3xl mx-auto px-4 sm:px-6 pt-8 sm:pt-12 pb-16">
        <nav className="text-xs text-zinc-500 mb-6">
          <Link to="/" className="hover:text-zinc-300">Home</Link>
          <span className="mx-2">/</span>
          <Link to="/glossary" className="hover:text-zinc-300">Glossary</Link>
          <span className="mx-2">/</span>
          <span className="text-zinc-400">{term}</span>
        </nav>

        <header className="mb-8">
          <p className="text-xs uppercase tracking-widest text-emerald-400 font-semibold mb-3">
            Fitness Glossary
          </p>
          <h1 className="text-3xl sm:text-4xl font-bold text-white tracking-tight">
            What is {term}?
          </h1>
        </header>

        {relatedCalcSlug && relatedCalcName && (
          <div className="mb-10 rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 to-zinc-900 p-5">
            <p className="text-xs uppercase tracking-widest text-emerald-400 font-semibold mb-2">
              Skip the math
            </p>
            <Link
              to={`/free-tools/${relatedCalcSlug}`}
              className="text-lg font-bold text-white hover:text-emerald-300 transition"
            >
              Use our free {relatedCalcName} &rarr;
            </Link>
            <p className="text-sm text-zinc-400 mt-1">
              No signup. Instant results in your browser.
            </p>
          </div>
        )}

        <article className="prose prose-invert prose-zinc max-w-none prose-headings:text-white prose-headings:font-bold prose-h2:text-2xl prose-h2:mt-12 prose-h2:mb-4 prose-p:text-zinc-300 prose-p:leading-relaxed prose-li:text-zinc-300 prose-strong:text-white prose-a:text-emerald-400 prose-a:no-underline hover:prose-a:text-emerald-300">
          {children}
        </article>

        {relatedCalcSlug && relatedCalcName && (
          <div className="mt-12 rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950 to-zinc-900 p-6 text-center">
            <p className="text-sm text-zinc-300 mb-3">Ready to put this into practice?</p>
            <Link
              to={`/free-tools/${relatedCalcSlug}`}
              className="inline-block px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
            >
              Open the free {relatedCalcName}
            </Link>
          </div>
        )}

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

        <div className="mt-16 border-t border-zinc-800 pt-8">
          <Link
            to="/glossary"
            className="text-sm text-emerald-400 hover:text-emerald-300"
          >
            &larr; Back to the full glossary
          </Link>
        </div>
      </main>

      <MarketingFooter />
    </div>
  );
}
