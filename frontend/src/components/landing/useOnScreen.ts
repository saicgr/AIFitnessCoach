import { useEffect, useRef, useState } from 'react';

/**
 * IntersectionObserver hook shared by the landing sections — used to pause
 * marquees / demo timers / the WebGL loop when their section scrolls
 * offscreen so the page never burns frames it isn't showing.
 */
export function useOnScreen<T extends HTMLElement>(rootMargin = '120px') {
  const ref = useRef<T | null>(null);
  const [onScreen, setOnScreen] = useState(false);

  useEffect(() => {
    const el = ref.current;
    if (!el || typeof IntersectionObserver === 'undefined') {
      setOnScreen(true);
      return;
    }
    const observer = new IntersectionObserver(
      ([entry]) => setOnScreen(entry.isIntersecting),
      { rootMargin }
    );
    observer.observe(el);
    return () => observer.disconnect();
  }, [rootMargin]);

  return { ref, onScreen } as const;
}
