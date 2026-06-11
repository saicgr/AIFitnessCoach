import { useEffect, useState } from 'react';
import { motionAllowed } from '../../lib/runtimeEnv';
import { FREE_TOOL_COUNT } from '../../lib/toolStats';
import { useOnScreen } from './useOnScreen';

const STATS = [
  '1,722 exercises with video demos',
  `${FREE_TOOL_COUNT} free fitness tools`,
  '52+ skill progressions',
  '5 AI coach personas',
  'Photo food logging',
  'Adaptive TDEE engine',
  '7-day free trial',
  'Muscle heatmap analysis',
];

/**
 * Social-proof band. One static, crawlable row is always in the DOM; the
 * moving marquee is a CSS keyframe on a duplicated aria-hidden track,
 * paused offscreen and disabled for prerender / reduced motion.
 */
export default function StatMarquee() {
  const { ref, onScreen } = useOnScreen<HTMLDivElement>();
  const [motionOk, setMotionOk] = useState(false);

  useEffect(() => {
    setMotionOk(motionAllowed());
  }, []);

  const animate = motionOk && onScreen;
  const row = (
    <>
      {STATS.map((s) => (
        <span key={s} className="flex shrink-0 items-center gap-6 pr-6">
          <span className="condensed-kicker whitespace-nowrap text-sm text-zinc-400">{s}</span>
          <span className="h-1 w-1 shrink-0 rounded-full bg-volt-500" />
        </span>
      ))}
    </>
  );

  return (
    <section
      ref={ref}
      className={`relative overflow-hidden border-y border-white/8 bg-[#0a0807] py-5 ${animate ? 'vl-marquee-on' : ''}`}
      aria-label="Zealova by the numbers"
    >
      {motionOk ? (
        <div className="vl-marquee-track">
          <div className="flex">{row}</div>
          <div className="flex" aria-hidden="true">{row}</div>
        </div>
      ) : (
        // Static crawlable fallback (also what prerender snapshots)
        <div className="flex flex-wrap justify-center gap-y-2 px-6">{row}</div>
      )}
    </section>
  );
}
