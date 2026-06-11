import { useEffect, useRef } from 'react';
import { motionAllowed } from '../../lib/runtimeEnv';

/**
 * Magnetic hover — the element leans toward the cursor (max `strength` px)
 * and springs back on leave. Transform-only, driven by a single rAF lerp,
 * disabled for prerender / reduced motion / touch.
 */
export function useMagnetic<T extends HTMLElement>(strength = 7) {
  const ref = useRef<T | null>(null);

  useEffect(() => {
    const el = ref.current;
    if (!el || !motionAllowed() || window.matchMedia('(hover: none)').matches) return;

    let raf = 0;
    let targetX = 0;
    let targetY = 0;
    let curX = 0;
    let curY = 0;
    let active = false;

    const tick = () => {
      curX += (targetX - curX) * 0.18;
      curY += (targetY - curY) * 0.18;
      el.style.transform = `translate(${curX.toFixed(2)}px, ${curY.toFixed(2)}px)`;
      if (active || Math.abs(curX) > 0.05 || Math.abs(curY) > 0.05) {
        raf = requestAnimationFrame(tick);
      } else {
        el.style.transform = '';
      }
    };

    const onMove = (e: PointerEvent) => {
      const r = el.getBoundingClientRect();
      targetX = ((e.clientX - (r.left + r.width / 2)) / (r.width / 2)) * strength;
      targetY = ((e.clientY - (r.top + r.height / 2)) / (r.height / 2)) * strength;
      if (!active) {
        active = true;
        cancelAnimationFrame(raf);
        raf = requestAnimationFrame(tick);
      }
    };
    const onLeave = () => {
      active = false;
      targetX = 0;
      targetY = 0;
    };

    el.addEventListener('pointermove', onMove, { passive: true });
    el.addEventListener('pointerleave', onLeave, { passive: true });
    return () => {
      el.removeEventListener('pointermove', onMove);
      el.removeEventListener('pointerleave', onLeave);
      cancelAnimationFrame(raf);
      el.style.transform = '';
    };
  }, [strength]);

  return ref;
}
