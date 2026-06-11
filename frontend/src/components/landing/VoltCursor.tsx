import { useEffect, useRef } from 'react';
import { motionAllowed } from '../../lib/runtimeEnv';

/**
 * Custom cursor for the landing page: a volt dot that sticks to the
 * pointer + a trailing ring that lags behind and flares over interactive
 * elements. Desktop-hover devices only; native cursor is hidden via the
 * .vl-cursor-on class scoped in landing.css. Single rAF, transform-only.
 */
export default function VoltCursor() {
  const dotRef = useRef<HTMLDivElement>(null);
  const ringRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const dot = dotRef.current;
    const ring = ringRef.current;
    if (!dot || !ring || !motionAllowed() || window.matchMedia('(hover: none)').matches) return;

    document.documentElement.classList.add('vl-cursor-on');

    let x = -100, y = -100;       // pointer
    let rx = -100, ry = -100;     // ring (lerped)
    let scale = 1;
    let targetScale = 1;
    let raf = 0;
    let visible = false;

    const tick = () => {
      rx += (x - rx) * 0.16;
      ry += (y - ry) * 0.16;
      scale += (targetScale - scale) * 0.2;
      dot.style.transform = `translate(${x}px, ${y}px) translate(-50%, -50%)`;
      ring.style.transform = `translate(${rx.toFixed(1)}px, ${ry.toFixed(1)}px) translate(-50%, -50%) scale(${scale.toFixed(3)})`;
      raf = requestAnimationFrame(tick);
    };

    const onMove = (e: PointerEvent) => {
      x = e.clientX;
      y = e.clientY;
      if (!visible) {
        visible = true;
        dot.style.opacity = '1';
        ring.style.opacity = '1';
        raf = requestAnimationFrame(tick);
      }
      const interactive = (e.target as Element | null)?.closest?.(
        'a, button, [role="button"], input, summary, label'
      );
      targetScale = interactive ? 1.8 : 1;
      ring.classList.toggle('vl-ring-hot', Boolean(interactive));
    };

    const onLeave = () => {
      visible = false;
      dot.style.opacity = '0';
      ring.style.opacity = '0';
      cancelAnimationFrame(raf);
      raf = 0;
    };

    window.addEventListener('pointermove', onMove, { passive: true });
    document.documentElement.addEventListener('pointerleave', onLeave);
    return () => {
      window.removeEventListener('pointermove', onMove);
      document.documentElement.removeEventListener('pointerleave', onLeave);
      cancelAnimationFrame(raf);
      document.documentElement.classList.remove('vl-cursor-on');
    };
  }, []);

  return (
    <>
      <div
        ref={dotRef}
        aria-hidden="true"
        className="pointer-events-none fixed left-0 top-0 z-[100] h-1.5 w-1.5 rounded-full bg-volt-500 opacity-0"
      />
      <div
        ref={ringRef}
        aria-hidden="true"
        className="vl-cursor-ring pointer-events-none fixed left-0 top-0 z-[100] h-8 w-8 rounded-full opacity-0"
      />
    </>
  );
}
