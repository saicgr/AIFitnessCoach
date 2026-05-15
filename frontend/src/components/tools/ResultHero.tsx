// Big-number hero result block, used by upgraded calculators.
// Animated count-up on value change. Optional label, suffix, sub-stat.

import { useEffect, useRef, useState } from 'react';

interface ResultHeroProps {
  label: string;            // e.g. "Total expected fat loss"
  value: number;
  suffix?: string;          // e.g. "lbs", "cal", "g"
  decimals?: number;
  subLabel?: string;        // small label under main value (e.g. "over 8 weeks")
  emphasis?: 'emerald' | 'amber' | 'rose' | 'sky';
  size?: 'lg' | 'xl';       // lg = section hero, xl = page hero
}

const COLOR_MAP = {
  emerald: 'text-emerald-400',
  amber: 'text-amber-400',
  rose: 'text-rose-400',
  sky: 'text-sky-400',
};

export default function ResultHero({
  label,
  value,
  suffix,
  decimals = 0,
  subLabel,
  emphasis = 'emerald',
  size = 'xl',
}: ResultHeroProps) {
  const [displayed, setDisplayed] = useState(value);
  const prevRef = useRef(value);
  const frameRef = useRef<number | null>(null);

  useEffect(() => {
    const start = prevRef.current;
    const end = value;
    if (Math.abs(end - start) < 0.001) {
      setDisplayed(end);
      return;
    }
    const startTime = performance.now();
    const duration = 500; // ms
    const tick = (now: number) => {
      const elapsed = now - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const eased = 1 - Math.pow(1 - progress, 3); // ease-out-cubic
      setDisplayed(start + (end - start) * eased);
      if (progress < 1) {
        frameRef.current = requestAnimationFrame(tick);
      } else {
        prevRef.current = end;
      }
    };
    frameRef.current = requestAnimationFrame(tick);
    return () => {
      if (frameRef.current) cancelAnimationFrame(frameRef.current);
    };
  }, [value]);

  const formatted = formatNumber(displayed, decimals);
  const heroTextClass =
    size === 'xl'
      ? 'text-7xl sm:text-8xl font-extrabold tracking-tight tabular-nums'
      : 'text-5xl sm:text-6xl font-bold tracking-tight tabular-nums';

  return (
    <div className="text-center py-6">
      <p className="text-xs sm:text-sm uppercase tracking-wider text-zinc-500 font-semibold mb-2">
        {label}
      </p>
      <p className={`${heroTextClass} ${COLOR_MAP[emphasis]}`}>
        {formatted}
        {suffix && (
          <span className="text-2xl sm:text-3xl text-zinc-400 font-bold ml-2">
            {suffix}
          </span>
        )}
      </p>
      {subLabel && (
        <p className="text-sm text-zinc-400 mt-2">{subLabel}</p>
      )}
    </div>
  );
}

function formatNumber(n: number, decimals: number): string {
  const rounded = Number(n.toFixed(decimals));
  if (decimals === 0) {
    return rounded.toLocaleString('en-US');
  }
  return rounded.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}
