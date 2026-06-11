import { useEffect, useState } from 'react';
import { motionAllowed } from '../../../lib/runtimeEnv';
import { useOnScreen } from '../useOnScreen';
import { useDemoClock } from './useDemoClock';
import {
  ChatScene,
  ProgramScene,
  LogSetScene,
  PRScene,
  NutritionScene,
  MenuScanScene,
  PhotoComparisonScene,
  SettingsScene,
} from './scenes';

const SCENE_LABELS = [
  'AI coach',
  'Builds your program',
  'Live logging',
  'PR tracking',
  'Photo nutrition',
  'Menu scan',
  'Progress photos',
  'Coach changes settings',
];

/**
 * One crisp phone running a live, auto-playing recreation of the actual app
 * UI (no screenshots). Under prerender / reduced motion the demo freezes on
 * the completed chat scene, so the SEO snapshot contains a real coach
 * conversation as crawlable text.
 */
export default function PhoneDemo() {
  const { ref, onScreen } = useOnScreen<HTMLDivElement>('80px');
  const [motionOk, setMotionOk] = useState(false);

  // motionAllowed() reads navigator/matchMedia — defer to effect so the
  // initial (prerendered) render is always the static state.
  useEffect(() => {
    setMotionOk(motionAllowed());
  }, []);

  const active = motionOk && onScreen;
  const { scene, t } = useDemoClock(active);
  const isStatic = !motionOk;
  const current = isStatic ? 0 : scene;

  return (
    // The animated mockup is decorative for assistive tech: one stable
    // label on the wrapper, everything inside hidden from the a11y tree.
    <div
      ref={ref}
      className="relative mx-auto w-[270px] sm:w-[300px]"
      role="img"
      aria-label="Animated demo of the Zealova app: AI coach chat, program building, set logging, PR tracking, photo food logging, menu scanning, progress photo comparison, and settings control"
    >
      {/* Volt aura behind the phone */}
      <div
        aria-hidden="true"
        className="absolute -inset-10 rounded-full opacity-60"
        style={{ background: 'radial-gradient(50% 50% at 50% 50%, rgba(255,122,0,0.14), transparent 70%)' }}
      />

      {/* Bezel */}
      <div
        aria-hidden="true"
        className="relative rounded-[2.6rem] border border-white/15 bg-[#0a0a0a] p-2"
        style={{ aspectRatio: '9 / 19', boxShadow: '0 24px 60px -20px rgba(0,0,0,0.8), 0 0 0 1px rgba(0,0,0,0.6)' }}
      >
        {/* Screen — light base, matching the real app's default theme */}
        <div className="relative h-full w-full overflow-hidden rounded-[2rem] bg-white">
          {/* Scenes — crossfade on opacity only */}
          <div className={`absolute inset-0 transition-opacity duration-300 ${current === 0 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
            <ChatScene t={current === 0 ? t : 0} isStatic={isStatic} />
          </div>
          {!isStatic && (
            <>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 1 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <ProgramScene t={current === 1 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 2 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <LogSetScene t={current === 2 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 3 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <PRScene t={current === 3 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 4 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <NutritionScene t={current === 4 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 5 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <MenuScanScene t={current === 5 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 6 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <PhotoComparisonScene t={current === 6 ? t : 0} isStatic={false} />
              </div>
              <div className={`absolute inset-0 transition-opacity duration-300 ${current === 7 ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}>
                <SettingsScene t={current === 7 ? t : 0} isStatic={false} />
              </div>
            </>
          )}

          {/* Notch (scene headers pad below it via pt-8) */}
          <div className="absolute left-1/2 top-1.5 z-10 h-4 w-16 -translate-x-1/2 rounded-full bg-black" />
          {/* Home indicator */}
          <div className="absolute bottom-1.5 left-1/2 z-10 h-1 w-16 -translate-x-1/2 rounded-full bg-black/25" />
        </div>
      </div>

      {/* Scene indicator dots */}
      <div className="mt-5 flex items-center justify-center gap-2" aria-hidden="true">
        {SCENE_LABELS.map((label, i) => (
          <span
            key={label}
            className={`h-1.5 rounded-full transition-all duration-300 ${
              current === i ? 'w-6 bg-[var(--volt)]' : 'w-1.5 bg-white/20'
            }`}
            title={label}
          />
        ))}
      </div>
      <p className="condensed-kicker mt-2 text-center text-[10px] text-zinc-500">
        {SCENE_LABELS[current]}
      </p>
    </div>
  );
}
