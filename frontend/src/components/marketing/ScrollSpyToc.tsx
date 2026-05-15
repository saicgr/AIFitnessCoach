// Auto-generating table-of-contents sidebar for long-form marketing pages
// (comparison /vs/* pages, /best-* roundups).
//
// Self-managing: on mount it scans the page for <h2> elements, assigns each a
// slug id if it lacks one, and renders a sticky left rail. An Intersection
// Observer highlights the section currently in view. Clicking scrolls to it.
//
// Renders nothing on screens narrower than xl (no room for a side rail) and
// nothing if the page has fewer than 3 headings (not worth a TOC).
//
// Usage: drop <ScrollSpyToc /> anywhere in a page. It positions itself fixed.

import { useEffect, useState } from 'react';

interface Heading {
  id: string;
  text: string;
}

function slugify(text: string): string {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
    .slice(0, 60);
}

export default function ScrollSpyToc() {
  const [headings, setHeadings] = useState<Heading[]>([]);
  const [activeId, setActiveId] = useState<string>('');

  // Scan for h2s after the page has painted. A small delay lets lazy /
  // animated sections mount first.
  useEffect(() => {
    const scan = () => {
      const main = document.querySelector('main') || document.body;
      const h2s = Array.from(main.querySelectorAll('h2'));
      const found: Heading[] = [];
      const usedIds = new Set<string>();
      for (const h2 of h2s) {
        const text = (h2.textContent || '').trim();
        if (!text || text.length > 90) continue;
        let id = h2.id;
        if (!id) {
          let base = slugify(text) || 'section';
          id = base;
          let n = 2;
          while (usedIds.has(id) || document.getElementById(id)) {
            id = `${base}-${n++}`;
          }
          h2.id = id;
        }
        usedIds.add(id);
        // scroll-margin so the sticky nav doesn't cover the heading.
        h2.style.scrollMarginTop = '96px';
        found.push({ id, text });
      }
      setHeadings(found);
    };
    const t = window.setTimeout(scan, 400);
    return () => window.clearTimeout(t);
  }, []);

  // Highlight the heading nearest the top of the viewport.
  useEffect(() => {
    if (headings.length === 0) return;
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible[0]) setActiveId(visible[0].target.id);
      },
      { rootMargin: '-80px 0px -70% 0px', threshold: 0 },
    );
    for (const h of headings) {
      const el = document.getElementById(h.id);
      if (el) observer.observe(el);
    }
    return () => observer.disconnect();
  }, [headings]);

  if (headings.length < 3) return null;

  const handleClick = (e: React.MouseEvent, id: string) => {
    e.preventDefault();
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
      setActiveId(id);
      history.replaceState(null, '', `#${id}`);
    }
  };

  return (
    <nav
      aria-label="On this page"
      // Comparison + roundup pages center their content at max-w-4xl (56rem).
      // Park the 14rem rail just left of that column with a 1rem gap, and
      // never let it slip off-screen (the max() floor pins it at 1rem).
      className="hidden xl:block fixed left-[max(1rem,calc((100vw-56rem)/2-15rem))] top-28 w-56 z-20"
    >
      <p className="text-[11px] font-bold uppercase tracking-widest text-[var(--color-text-muted)] mb-3">
        On this page
      </p>
      <ul className="space-y-1 border-l border-[var(--color-border)] max-h-[calc(100vh-12rem)] overflow-y-auto">
        {headings.map((h) => {
          const active = h.id === activeId;
          return (
            <li key={h.id}>
              <a
                href={`#${h.id}`}
                onClick={(e) => handleClick(e, h.id)}
                className={`block pl-3 -ml-px py-1.5 text-[13px] leading-snug border-l-2 transition ${
                  active
                    ? 'border-emerald-500 text-emerald-400 font-medium'
                    : 'border-transparent text-[var(--color-text-secondary)] hover:text-[var(--color-text)] hover:border-[var(--color-border-light)]'
                }`}
              >
                {h.text}
              </a>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
