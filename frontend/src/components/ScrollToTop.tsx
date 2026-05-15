// Route-level concerns that need to happen on every navigation:
//   1. Scroll back to top (React Router preserves position by default).
//   2. Lock the dark-mode class while on dark-only marketing surfaces so
//      the shared nav stays legible. The user's stored theme is restored
//      whenever they leave those routes.

import { useEffect } from 'react';
import { useLocation } from 'react-router-dom';
import { useAppStore } from '../store';

const DARK_ONLY_PREFIXES = ['/free-tools', '/glossary', '/best-', '/vs/'];

function isDarkOnlyRoute(pathname: string): boolean {
  return DARK_ONLY_PREFIXES.some((prefix) => pathname.startsWith(prefix));
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
    if (isDarkOnlyRoute(pathname)) {
      html.classList.add('dark-mode');
    } else if (userTheme === 'light') {
      html.classList.remove('dark-mode');
    } else {
      html.classList.add('dark-mode');
    }
  }, [pathname, userTheme]);

  return null;
}
