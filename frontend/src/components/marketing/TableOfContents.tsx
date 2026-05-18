// Table-of-contents nav for long-form marketing pages.
//
// Renders a jump-link list built from the page's section ids, and highlights
// the section currently in view (scroll-spy via IntersectionObserver). Used
// twice by ArticleLayout — once as the sticky desktop sidebar, once inside the
// mobile collapsible <details>.

import { useEffect, useState } from 'react';

export interface TocSection {
  /** The DOM id of the section element this entry jumps to. */
  id: string;
  /** Human label shown in the TOC. */
  label: string;
}

interface Props {
  sections: TocSection[];
  /** Show the "On this page" heading. False inside the mobile <details>, whose
   *  <summary> already says it. */
  showHeading?: boolean;
}

export default function TableOfContents({ sections, showHeading = true }: Props) {
  const [activeId, setActiveId] = useState<string>(sections[0]?.id ?? '');

  useEffect(() => {
    // Highlight the topmost section currently within the reading viewport.
    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => a.boundingClientRect.top - b.boundingClientRect.top);
        if (visible.length > 0) setActiveId(visible[0].target.id);
      },
      // Top offset clears the sticky nav; bottom -70% makes a section "active"
      // once its heading is in the upper third of the viewport.
      { rootMargin: '-80px 0px -70% 0px', threshold: 0 },
    );
    sections.forEach((s) => {
      const el = document.getElementById(s.id);
      if (el) observer.observe(el);
    });
    return () => observer.disconnect();
  }, [sections]);

  const jumpTo = (e: React.MouseEvent, id: string) => {
    e.preventDefault();
    const el = document.getElementById(id);
    if (el) {
      el.scrollIntoView({ behavior: 'smooth', block: 'start' });
      // Update the hash without a jump so the link is shareable.
      window.history.replaceState(null, '', `#${id}`);
      setActiveId(id);
    }
  };

  return (
    <nav aria-label="On this page">
      {showHeading && (
        <p className="text-xs font-semibold uppercase tracking-wider text-zinc-500 mb-3">
          On this page
        </p>
      )}
      <ul className="space-y-0.5">
        {sections.map((s) => {
          const active = activeId === s.id;
          return (
            <li key={s.id}>
              <a
                href={`#${s.id}`}
                onClick={(e) => jumpTo(e, s.id)}
                aria-current={active ? 'true' : undefined}
                className={`block border-l-2 pl-3 py-1.5 text-sm leading-snug transition-colors ${
                  active
                    ? 'border-emerald-400 text-emerald-300 font-medium'
                    : 'border-zinc-800 text-zinc-400 hover:text-zinc-200 hover:border-zinc-600'
                }`}
              >
                {s.label}
              </a>
            </li>
          );
        })}
      </ul>
    </nav>
  );
}
