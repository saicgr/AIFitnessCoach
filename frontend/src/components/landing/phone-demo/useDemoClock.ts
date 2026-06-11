import { useCallback, useEffect, useRef, useState } from 'react';

/**
 * Drives the auto-playing phone demo with a single rAF clock.
 *
 * - One requestAnimationFrame loop accumulates performance.now() deltas
 *   (rAF auto-pauses in background tabs for free).
 * - `active=false` (offscreen / prerender / reduced motion) freezes the
 *   clock entirely; the demo renders its static completed Scene 1 state.
 * - State updates are throttled to ~12fps — the scenes' inner animations
 *   (typing slices, count-ups) don't need 60fps re-renders, and CSS handles
 *   the smooth parts.
 */
export interface DemoClock {
  scene: number;       // index into SCENE_DURATIONS
  t: number;           // ms elapsed within the current scene
}

// chat, program build, log set, PR, photo nutrition, menu scan,
// photo comparison, settings
export const SCENE_DURATIONS = [8600, 7000, 6400, 4200, 6400, 7400, 5200, 5200];

export function useDemoClock(active: boolean): DemoClock & { jumpTo: (scene: number) => void } {
  const [state, setState] = useState<DemoClock>({ scene: 0, t: 0 });
  const elapsedRef = useRef(0);

  // Tappable scene pills: jump the clock to the start of a scene.
  const jumpTo = useCallback((scene: number) => {
    const idx = Math.max(0, Math.min(scene, SCENE_DURATIONS.length - 1));
    elapsedRef.current = SCENE_DURATIONS.slice(0, idx).reduce((a, b) => a + b, 0);
    setState({ scene: idx, t: 0 });
  }, []);

  useEffect(() => {
    if (!active) return;

    let raf = 0;
    let last = performance.now();
    let lastEmit = 0;
    const total = SCENE_DURATIONS.reduce((a, b) => a + b, 0);

    const tick = (now: number) => {
      const dt = Math.min(now - last, 100); // clamp huge tab-resume deltas
      last = now;
      elapsedRef.current = (elapsedRef.current + dt) % total;

      // Emit at ~12fps.
      if (now - lastEmit > 80) {
        lastEmit = now;
        let acc = elapsedRef.current;
        let scene = 0;
        for (let i = 0; i < SCENE_DURATIONS.length; i++) {
          if (acc < SCENE_DURATIONS[i]) {
            scene = i;
            break;
          }
          acc -= SCENE_DURATIONS[i];
        }
        setState((prev) =>
          prev.scene === scene && Math.abs(prev.t - acc) < 40 ? prev : { scene, t: acc }
        );
      }
      raf = requestAnimationFrame(tick);
    };

    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [active]);

  return { ...state, jumpTo };
}
