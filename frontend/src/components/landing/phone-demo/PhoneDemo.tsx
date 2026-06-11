import { useEffect, useState } from 'react';
import { motionAllowed } from '../../../lib/runtimeEnv';
import { useOnScreen } from '../useOnScreen';
import { useDemoClock, SCENE_DURATIONS } from './useDemoClock';
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
export default function PhoneDemo({
  frameWrapper,
}: {
  /** Wraps just the phone frame (e.g. 3D tilt) — the scene pills stay
   *  outside any transform so they always hit-test reliably. */
  frameWrapper?: (frame: React.ReactNode) => React.ReactNode;
}) {
  const { ref, onScreen } = useOnScreen<HTMLDivElement>('80px');
  const [motionOk, setMotionOk] = useState(false);

  // motionAllowed() reads navigator/matchMedia — defer to effect so the
  // initial (prerendered) render is always the static state.
  useEffect(() => {
    setMotionOk(motionAllowed());
  }, []);

  const active = motionOk && onScreen;
  const { scene, t, jumpTo } = useDemoClock(active);
  const isStatic = !motionOk;
  const current = isStatic ? 0 : scene;

  return (
    // The animated mockup is decorative for assistive tech: one stable
    // label on the wrapper, everything inside hidden from the a11y tree.
    <div ref={ref} className="relative mx-auto w-[290px] sm:w-[340px]">
      {/* Volt aura behind the phone */}
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -inset-10 rounded-full opacity-60"
        style={{ background: 'radial-gradient(50% 50% at 50% 50%, rgba(255,122,0,0.14), transparent 70%)' }}
      />

      {(() => {
        const frame = (
          <>
      {/* Titanium frame + bezel */}
        <div
          role="img"
          aria-label="Animated demo of the Zealova app: AI coach chat, program building, set logging, PR tracking, photo food logging, menu scanning, progress photo comparison, and settings control"
          className="vl-titanium relative rounded-[2.9rem] p-[3px]"
          style={{ boxShadow: '0 34px 80px -24px rgba(0,0,0,0.85), 0 4px 18px rgba(0,0,0,0.5)' }}
        >
        <div
          className="relative rounded-[2.7rem] bg-[#060607] p-2"
          style={{ aspectRatio: '9 / 19' }}
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
        </div>
          </>
        );
        return frameWrapper ? frameWrapper(frame) : frame;
      })()}

      {/* Scene pills — tappable with 24px hit areas, prev/next chevrons,
          and a story-style countdown fill inside the active pill. */}
      <div className="relative z-10 mt-5 flex flex-wrap items-center justify-center gap-1">
        <button
          type="button"
          onClick={() => jumpTo((current - 1 + SCENE_LABELS.length) % SCENE_LABELS.length)}
          aria-label="Previous scene"
          className="flex h-6 w-6 items-center justify-center rounded-full border border-white/15 text-[11px] text-zinc-400 transition-colors hover:border-volt-500/50 hover:text-white"
        >
          ‹
        </button>
        {SCENE_LABELS.map((label, i) => (
          <button
            key={label}
            type="button"
            onClick={() => jumpTo(i)}
            aria-label={`Show ${label}`}
            aria-pressed={current === i}
            className="group flex h-6 items-center justify-center"
          >
            {current === i ? (
              <span className="relative flex h-5 items-center overflow-hidden rounded-full px-2.5" style={{ background: '#6b3200' }}>
                {/* countdown fill: how far into this scene we are */}
                <span
                  className="absolute inset-y-0 left-0 bg-volt-500"
                  style={{ width: `${Math.min((t / SCENE_DURATIONS[current]) * 100, 100)}%`, transition: 'width 120ms linear' }}
                />
                <span className="condensed-kicker relative z-10 whitespace-nowrap text-[8px] text-white">
                  {label}
                </span>
              </span>
            ) : (
              <span className="h-2 w-2 rounded-full bg-white/25 transition-all group-hover:scale-150 group-hover:bg-white/50" />
            )}
          </button>
        ))}
        <button
          type="button"
          onClick={() => jumpTo((current + 1) % SCENE_LABELS.length)}
          aria-label="Next scene"
          className="flex h-6 w-6 items-center justify-center rounded-full border border-white/15 text-[11px] text-zinc-400 transition-colors hover:border-volt-500/50 hover:text-white"
        >
          ›
        </button>
      </div>
    </div>
  );
}
