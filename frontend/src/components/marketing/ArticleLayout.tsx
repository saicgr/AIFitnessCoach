// Shared layout for long-form marketing pages — the /vs/* comparison pages
// and the /best-*-2026 roundup pages.
//
// Three parts, exactly as the brief asked:
//   1. a left table-of-contents sidebar to jump to any section
//   2. the main article (passed as children)
//   3. a comment section at the bottom
//
// On desktop the TOC is a sticky left rail. On mobile/tablet it collapses to a
// <details> dropdown above the article, so nothing overflows on small screens.
//
// The page keeps its own <Helmet>/SEO + JSON-LD; this component owns only the
// visual shell (nav, TOC grid, comments, footer).

import type { ReactNode } from 'react';
import MarketingNav from './MarketingNav';
import MarketingFooter from './MarketingFooter';
import TableOfContents from './TableOfContents';
import type { TocSection } from './TableOfContents';
import CommentSection from './CommentSection';

interface Props {
  /** Stable page key for comments, e.g. 'vs/bevel' or 'best-ai-fitness-apps-2026'. */
  slug: string;
  /** Article sections, in order. Each id must match a section element id on the page. */
  sections: TocSection[];
  /** The article body — the page's sections. */
  children: ReactNode;
}

export default function ArticleLayout({ slug, sections, children }: Props) {
  // The comment section is itself a jump target in the TOC.
  const tocSections: TocSection[] = [...sections, { id: 'comments', label: 'Comments' }];

  return (
    <div className="min-h-screen bg-zinc-950 text-zinc-100">
      <MarketingNav />

      <div className="max-w-6xl mx-auto px-4 sm:px-6 py-12 sm:py-20 lg:grid lg:grid-cols-[210px_minmax(0,1fr)] lg:gap-12">
        {/* Mobile / tablet — collapsible TOC above the article */}
        <details className="lg:hidden mb-8 rounded-xl border border-zinc-800 bg-zinc-900/50">
          <summary className="cursor-pointer select-none px-4 py-3 text-sm font-semibold text-zinc-200">
            On this page
          </summary>
          <div className="px-4 pb-4">
            <TableOfContents sections={tocSections} showHeading={false} />
          </div>
        </details>

        {/* Desktop — sticky left sidebar */}
        <aside className="hidden lg:block">
          <div className="sticky top-24">
            <TableOfContents sections={tocSections} />
          </div>
        </aside>

        {/* Article + comments. min-w-0 keeps long content from overflowing the grid cell. */}
        <div className="min-w-0">
          <main>{children}</main>
          <CommentSection slug={slug} />
        </div>
      </div>

      <MarketingFooter />
    </div>
  );
}
