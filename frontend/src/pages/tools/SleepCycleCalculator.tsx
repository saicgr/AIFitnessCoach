// /free-tools/sleep-cycle-calculator
//
// 90-minute sleep cycle planner. Two modes:
//   A: Given a wake time, recommend bedtimes working backwards.
//   B: Given a bedtime, recommend wake times working forwards.
// Both account for a 15-minute fall-asleep buffer.
//
// 5-6 cycles is flagged as ideal; fewer than 5 as suboptimal.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type Mode = 'wake' | 'sleep';

const FALL_ASLEEP_MINUTES = 15;
const CYCLE_MINUTES = 90;
const CYCLES_TO_SHOW = [3, 4, 5, 6, 7];

function minutesToTime(totalMinutes: number): { hh: number; mm: number; label: string } {
  // Normalize into 0..1439
  let m = ((totalMinutes % 1440) + 1440) % 1440;
  const hh24 = Math.floor(m / 60);
  const mm = m % 60;
  const period = hh24 >= 12 ? 'PM' : 'AM';
  const hh12 = hh24 % 12 === 0 ? 12 : hh24 % 12;
  return {
    hh: hh24,
    mm,
    label: `${hh12}:${mm.toString().padStart(2, '0')} ${period}`,
  };
}

function timeToMinutes(t: string): number {
  // HH:MM 24-hour from <input type="time">
  const [h, m] = t.split(':').map((x) => parseInt(x, 10));
  if (!Number.isFinite(h) || !Number.isFinite(m)) return 0;
  return h * 60 + m;
}

interface Option {
  cycles: number;
  totalMinutes: number;
  sleepDurationMinutes: number; // pure sleep minutes (excludes fall-asleep buffer)
  quality: 'ideal' | 'ok' | 'suboptimal';
}

function qualityFor(cycles: number): Option['quality'] {
  if (cycles >= 5 && cycles <= 6) return 'ideal';
  if (cycles === 4 || cycles === 7) return 'ok';
  return 'suboptimal';
}

function fmtDuration(totalMin: number): string {
  const h = Math.floor(totalMin / 60);
  const m = totalMin % 60;
  if (m === 0) return `${h}h`;
  return `${h}h ${m}m`;
}

export default function SleepCycleCalculator() {
  const [mode, setMode] = useState<Mode>('wake');
  const [wakeTime, setWakeTime] = useState('06:30');
  const [bedTime, setBedTime] = useState('23:00');
  const [useNow, setUseNow] = useState(false);

  // For "go to bed now": refresh base time each render
  const nowMinutes = useMemo(() => {
    const d = new Date();
    return d.getHours() * 60 + d.getMinutes();
    // intentionally not memoized on a timer; user can toggle to refresh
  }, [useNow]);

  const options: Option[] = useMemo(() => {
    if (mode === 'wake') {
      const wakeMin = timeToMinutes(wakeTime);
      // bed = wake - (cycles * 90) - 15 (fall asleep)
      return CYCLES_TO_SHOW.map((cycles) => {
        const sleepMin = cycles * CYCLE_MINUTES;
        const bedMin = wakeMin - sleepMin - FALL_ASLEEP_MINUTES;
        return {
          cycles,
          totalMinutes: bedMin,
          sleepDurationMinutes: sleepMin,
          quality: qualityFor(cycles),
        };
      });
    }
    // sleep mode -> wake times
    const bedMin = useNow ? nowMinutes : timeToMinutes(bedTime);
    return CYCLES_TO_SHOW.map((cycles) => {
      const sleepMin = cycles * CYCLE_MINUTES;
      const wake = bedMin + FALL_ASLEEP_MINUTES + sleepMin;
      return {
        cycles,
        totalMinutes: wake,
        sleepDurationMinutes: sleepMin,
        quality: qualityFor(cycles),
      };
    });
  }, [mode, wakeTime, bedTime, useNow, nowMinutes]);

  return (
    <CalculatorShell
      slug="sleep-cycle-calculator"
      title="Sleep Cycle Calculator"
      metaDescription="Find the best bedtime or wake time based on 90-minute sleep cycles. Wake at the end of a cycle, not the middle, and feel rested with 5-6 full cycles per night."
      intro="Sleep runs in roughly 90-minute cycles. Waking at the end of a cycle feels lighter than waking mid-cycle. Pick whether you have a fixed wake time or a fixed bedtime, and we will show you the times that line up with full cycles."
      faqs={[
        {
          q: 'Are sleep cycles really 90 minutes?',
          a: 'On average, yes, but individual cycles vary from about 70 to 120 minutes and tend to lengthen toward morning. Ninety minutes is the population mean used in most sleep research and clinical practice. Treat the results here as guidance, not a stopwatch.',
        },
        {
          q: 'How many cycles should I aim for?',
          a: 'Five to six full cycles, which works out to 7.5 to 9 hours. The National Sleep Foundation recommends 7-9 hours for adults aged 18-64. Three or four cycles can work in a pinch but is not a long-term strategy.',
        },
        {
          q: 'Why the 15-minute fall-asleep buffer?',
          a: 'Healthy adults take an average of 10-20 minutes to fall asleep (sleep latency). We add 15 minutes between bedtime and the start of cycle 1 so the math reflects actual sleep, not time in bed.',
        },
        {
          q: 'Does this replace a sleep tracker?',
          a: 'No. A tracker measures your actual cycles using movement and heart rate. This tool plans your schedule using population averages. Both have a place.',
        },
        {
          q: 'I want to nap. What about that?',
          a: 'For naps, either keep it under 20 minutes (no deep sleep entry, no grogginess) or do a full 90-minute cycle. The 30-60 minute range is the worst, because you wake mid-cycle in slow-wave sleep.',
        },
      ]}
    >
      {/* Mode picker */}
      <section>
        <div className="grid grid-cols-2 gap-2">
          <button
            onClick={() => setMode('wake')}
            className={`p-4 rounded-xl border text-left transition ${
              mode === 'wake'
                ? 'bg-emerald-500/10 border-emerald-500'
                : 'bg-zinc-900 border-zinc-800 hover:border-zinc-700'
            }`}
          >
            <div className="text-base font-bold text-white">I want to wake at...</div>
            <div className="text-xs text-zinc-500 mt-1">Work backwards to find bedtimes</div>
          </button>
          <button
            onClick={() => setMode('sleep')}
            className={`p-4 rounded-xl border text-left transition ${
              mode === 'sleep'
                ? 'bg-emerald-500/10 border-emerald-500'
                : 'bg-zinc-900 border-zinc-800 hover:border-zinc-700'
            }`}
          >
            <div className="text-base font-bold text-white">I am going to bed at...</div>
            <div className="text-xs text-zinc-500 mt-1">Work forwards to find wake times</div>
          </button>
        </div>
      </section>

      {/* Input */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        {mode === 'wake' ? (
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Wake time</span>
            <input
              type="time"
              value={wakeTime}
              onChange={(e) => setWakeTime(e.target.value)}
              className="w-full sm:w-56 px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            />
            <p className="text-xs text-zinc-500 mt-2">
              We assume 15 minutes to fall asleep, then full 90-minute cycles.
            </p>
          </label>
        ) : (
          <div className="space-y-3">
            <label className="flex items-center gap-2 text-sm text-zinc-300 cursor-pointer">
              <input
                type="checkbox"
                checked={useNow}
                onChange={(e) => setUseNow(e.target.checked)}
                className="w-4 h-4 accent-emerald-500"
              />
              Going to bed right now
            </label>
            {!useNow && (
              <label className="block">
                <span className="block text-sm font-medium text-zinc-300 mb-1.5">Bedtime</span>
                <input
                  type="time"
                  value={bedTime}
                  onChange={(e) => setBedTime(e.target.value)}
                  className="w-full sm:w-56 px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
                />
              </label>
            )}
            {useNow && (
              <p className="text-sm text-zinc-400">
                Using {minutesToTime(nowMinutes).label} as your bedtime.
              </p>
            )}
          </div>
        )}
      </section>

      {/* Results */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">
          {mode === 'wake' ? 'Recommended bedtimes' : 'Recommended wake times'}
        </h2>
        <p className="text-sm text-zinc-400 mb-4">
          5-6 cycles is the sweet spot. Below 5 cycles is short-term only.
        </p>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          {options.map((opt) => {
            const t = minutesToTime(opt.totalMinutes);
            const qualityStyles =
              opt.quality === 'ideal'
                ? 'border-emerald-500 bg-emerald-500/5'
                : opt.quality === 'ok'
                  ? 'border-zinc-700 bg-zinc-900'
                  : 'border-rose-500/40 bg-rose-500/5';
            const qualityLabel =
              opt.quality === 'ideal'
                ? { text: 'Ideal', color: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/30' }
                : opt.quality === 'ok'
                  ? { text: 'OK', color: 'text-zinc-300 bg-zinc-800 border-zinc-700' }
                  : { text: 'Short', color: 'text-rose-400 bg-rose-500/10 border-rose-500/30' };
            return (
              <div key={opt.cycles} className={`p-5 rounded-xl border ${qualityStyles}`}>
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <div className="font-mono text-3xl font-bold text-white tabular-nums">{t.label}</div>
                    <div className="text-sm text-zinc-400 mt-1">
                      {opt.cycles} cycles · {fmtDuration(opt.sleepDurationMinutes)} sleep
                    </div>
                  </div>
                  <span className={`text-[10px] font-bold uppercase tracking-wider px-2 py-1 rounded-full border ${qualityLabel.color}`}>
                    {qualityLabel.text}
                  </span>
                </div>
              </div>
            );
          })}
        </div>
      </section>

      {/* Sleep stages visual */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
        <h3 className="text-base font-bold text-white mb-3">What happens in a 90-minute cycle</h3>
        <div className="space-y-2 text-sm">
          <Stage color="bg-sky-500" label="N1 light sleep" range="5%" />
          <Stage color="bg-sky-600" label="N2 light sleep" range="45%" />
          <Stage color="bg-indigo-600" label="N3 deep sleep (slow-wave)" range="25%" />
          <Stage color="bg-violet-500" label="REM" range="25%" />
        </div>
        <p className="text-xs text-zinc-500 mt-4 leading-relaxed">
          Early cycles favor deep sleep (physical recovery). Later cycles favor REM (memory consolidation). Both matter, which is why cutting sleep short hits cognitive performance harder than people expect.
        </p>
      </section>

      <InstallCta
        slug="sleep-cycle-calculator"
        result={{ mode, wakeTime, bedTime }}
        primary="Get smart bedtime reminders based on your morning workout schedule in Zealova"
        secondary="Tell Zealova when you train and it will schedule a nightly wind-down prompt so you hit 5-6 cycles before your alarm."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Stickgold R, Walker MP (2013). Sleep-dependent memory triage: evolving generalization through selective processing. Nat Neurosci 16(2):139-45.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/23354387/',
          },
          {
            text: 'Hirshkowitz M et al. (2015). National Sleep Foundation\'s sleep time duration recommendations. Sleep Health 1(1):40-43.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/29073412/',
          },
          {
            text: 'Carskadon MA, Dement WC (2011). Normal human sleep: an overview. Principles and Practice of Sleep Medicine, 5th ed.',
          },
          {
            text: 'Walker MP (2017). Why We Sleep. Sleep latency and cycle architecture references.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function Stage({ color, label, range }: { color: string; label: string; range: string }) {
  return (
    <div className="flex items-center gap-3">
      <span className={`inline-block w-3 h-3 rounded-sm ${color}`} />
      <span className="text-zinc-200 flex-1">{label}</span>
      <span className="text-zinc-500 font-mono text-xs">{range}</span>
    </div>
  );
}
