import { useRef, useState, useEffect, useCallback } from 'react';
import type { LandingFluxProps } from './types';
import { createSketch } from './sketch';

export function LandingFlux({
  className = '',
  rows = 8,
  barHeight = 16,
  gap = 10,
  color = '#3525F3',
  disableMarquee = false,
}: LandingFluxProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const p5Ref = useRef<any>(null);
  const [mounted, setMounted] = useState(false);

  const getContainerWidth = useCallback(() => {
    return containerRef.current?.clientWidth ?? window.innerWidth;
  }, []);

  useEffect(() => {
    if (typeof window === 'undefined') return;

    let p5Instance: any = null;
    let observer: IntersectionObserver | null = null;
    let destroyed = false;

    const loadP5 = async () => {
      if (destroyed || !containerRef.current) return;

      const p5Module = await import('p5');
      const p5 = p5Module.default;

      if (destroyed || !containerRef.current) return;

      const sketch = createSketch(
        rows,
        barHeight,
        gap,
        color,
        disableMarquee,
        getContainerWidth,
      );

      p5Instance = new p5(sketch, containerRef.current);
      p5Ref.current = p5Instance;

      // Remove wheel listener to prevent scroll hijacking
      try {
        const canvas = containerRef.current.querySelector('canvas');
        if (canvas) {
          canvas.style.display = 'block';
          canvas.addEventListener('wheel', (e) => e.stopPropagation(), { passive: true });
        }
      } catch {
        // no-op
      }

      // Visibility-based pause
      const handleVisibility = () => {
        if (!p5Instance) return;
        if (document.hidden) {
          p5Instance.noLoop();
        } else {
          p5Instance.loop();
        }
      };
      document.addEventListener('visibilitychange', handleVisibility);

      // IntersectionObserver-based pause
      observer = new IntersectionObserver(
        ([entry]) => {
          if (!p5Instance) return;
          if (entry.isIntersecting) {
            p5Instance.loop();
          } else {
            p5Instance.noLoop();
          }
        },
        { threshold: 0.05 },
      );
      observer.observe(containerRef.current);

      // Resize handler
      const handleResize = () => {
        if (!p5Instance || !containerRef.current) return;
        const w = containerRef.current.clientWidth;
        const h = rows * barHeight + (rows - 1) * gap + 40;
        p5Instance.resizeCanvas(w, h);
      };
      window.addEventListener('resize', handleResize);

      // Fade in
      setMounted(true);

      // Cleanup closures
      (p5Instance as any).__cleanupExtras = () => {
        document.removeEventListener('visibilitychange', handleVisibility);
        window.removeEventListener('resize', handleResize);
      };
    };

    loadP5();

    return () => {
      destroyed = true;
      if (observer && containerRef.current) {
        observer.disconnect();
      }
      if (p5Instance) {
        (p5Instance as any).__cleanupExtras?.();
        p5Instance.remove();
        p5Ref.current = null;
      }
    };
  }, [rows, barHeight, gap, color, disableMarquee, getContainerWidth]);

  const canvasHeight = rows * barHeight + (rows - 1) * gap + 40;

  return (
    <div
      ref={containerRef}
      className={className}
      style={{
        width: '100%',
        height: canvasHeight,
        opacity: mounted ? 1 : 0,
        transition: 'opacity 0.3s ease-in-out',
        maskImage:
          'linear-gradient(to right, transparent 0%, black 32px, black calc(100% - 32px), transparent 100%)',
        WebkitMaskImage:
          'linear-gradient(to right, transparent 0%, black 32px, black calc(100% - 32px), transparent 100%)',
        overflow: 'hidden',
        position: 'relative',
      }}
    />
  );
}

export default LandingFlux;
