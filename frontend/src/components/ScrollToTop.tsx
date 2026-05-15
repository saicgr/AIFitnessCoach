// Route-level concerns that run on every navigation:
//   1. Scroll back to top (React Router preserves position by default).
//   2. Apply the user's theme everywhere (no route now force-locks dark).
//   3. Tag tool/glossary/comparison routes with a `tool-route` class so the
//      light-mode zinc-palette remap in index.css can scope to them. Those
//      pages are built with hardcoded zinc-* utilities; the remap flips the
//      palette in light mode without editing 60 page files.

import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useAppStore } from '../store';

const TOOL_ROUTE_PREFIXES = ['/free-tools', '/glossary', '/best-', '/vs/', '/blog'];

function isToolRoute(pathname: string): boolean {
  return TOOL_ROUTE_PREFIXES.some((prefix) => pathname.startsWith(prefix));
}

export default function ScrollToTop() {
  const { pathname } = useLocation();
  const userTheme = useAppStore((s) => s.theme);

  useEffect(() => {
    if (!window.location.hash) {
      window.scrollTo({ top: 0, left: 0, behavior: 'auto' });
    }
  }, [pathname]);

  useEffect(() => {
    if (typeof document === 'undefined') return;
    const html = document.documentElement;

    // Theme follows the user's stored preference on every route.
    if (userTheme === 'dark') html.classList.add('dark-mode');
    else html.classList.remove('dark-mode');

    // Tool routes get the palette-remap hook class.
    if (isToolRoute(pathname)) html.classList.add('tool-route');
    else html.classList.remove('tool-route');
  }, [pathname, userTheme]);

  return null;
}
