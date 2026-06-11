import { useEffect, useRef, useState } from 'react';
import { createVoltScene, type VoltSceneHandle } from './voltScene';

/**
 * WebGL volt flow-field behind the hero. This component only ever mounts
 * after KineticHero's gate passes (no prerender, no reduced motion, WebGL
 * available, browser idle) — so it can assume a live, capable client.
 *
 * The canvas is created PER EFFECT RUN (not in JSX): dispose() force-loses
 * the GL context, so under React StrictMode's dev double-mount a JSX canvas
 * would be reused with a dead context and render blank. A fresh canvas per
 * mount sidesteps that entirely.
 *
 * Pauses its own rAF loop when the hero scrolls offscreen or the tab hides;
 * fully disposes GL resources on unmount.
 */
export default function VoltBackdrop() {
  const containerRef = useRef<HTMLDivElement>(null);
  const [ready, setReady] = useState(false);

  useEffect(() => {
    const container = containerRef.current;
    if (!container) return;

    const canvas = document.createElement('canvas');
    canvas.style.cssText = 'position:absolute;inset:0;width:100%;height:100%;';
    canvas.setAttribute('aria-hidden', 'true');
    container.appendChild(canvas);

    let handle: VoltSceneHandle | null = createVoltScene(canvas);
    if (!handle) {
      container.removeChild(canvas);
      return;
    }
    setReady(true);

    const observer = new IntersectionObserver(
      ([entry]) => handle?.setRunning(entry.isIntersecting && !document.hidden),
      { rootMargin: '120px' }
    );
    observer.observe(container);

    const onVisibility = () => {
      if (!document.hidden) {
        // Re-check intersection on tab return.
        const rect = container.getBoundingClientRect();
        const visible = rect.bottom > -120 && rect.top < window.innerHeight + 120;
        handle?.setRunning(visible);
      }
    };
    document.addEventListener('visibilitychange', onVisibility);

    return () => {
      observer.disconnect();
      document.removeEventListener('visibilitychange', onVisibility);
      handle?.dispose();
      handle = null;
      if (canvas.parentNode === container) container.removeChild(canvas);
    };
  }, []);

  return (
    <div
      ref={containerRef}
      aria-hidden="true"
      className={`absolute inset-0 z-[1] transition-opacity duration-1000 ${
        ready ? 'opacity-100' : 'opacity-0'
      }`}
    />
  );
}
