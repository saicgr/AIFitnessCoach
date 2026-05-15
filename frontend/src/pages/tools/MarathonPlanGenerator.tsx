// /free-tools/marathon-plan-generator
//
// Generates a week-by-week marathon training plan. Phases: Base, Build, Peak,
// Taper. Long run ramps ~10%/wk to a peak of ~20-22 mi, with weekly mileage
// growing from current to a peak determined by experience level. Daily
// breakdown: easy, tempo, intervals, long run, rest.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type Unit = 'mi' | 'km';
type Experience = 'first' | 'some' | 'experienced';

interface DayRow {
  day: string;
  type: string;
  distance: number;
  pace?: string;
  note?: string;
}

interface WeekPlan {
  weekNum: number;
  phase: string;
  longRun: number;
  totalMileage: number;
  days: DayRow[];
}

function parseGoalTime(h: number, m: number, s: number): number {
  return h * 3600 + m * 60 + s;
}

function secondsToPace(secPerMile: number, unit: Unit): string {
  const sec = unit === 'mi' ? secPerMile : secPerMile / 1.609;
  const mm = Math.floor(sec / 60);
  const ss = Math.round(sec % 60);
  return `${mm}:${String(ss).padStart(2, '0')}`;
}

const MARATHON_MI = 26.2188;

function weeksBetween(raceDate: string): number {
  if (!raceDate) return 16;
  const race = new Date(raceDate);
  const now = new Date();
  const ms = race.getTime() - now.getTime();
  const w = Math.floor(ms / (7 * 24 * 60 * 60 * 1000));
  return Math.max(8, Math.min(16, w));
}

function buildPlan(args: {
  weeks: number;
  currentMileage: number;
  goalSeconds: number;
  daysPerWeek: number;
  experience: Experience;
  unit: Unit;
}): WeekPlan[] {
  const { weeks, currentMileage, goalSeconds, daysPerWeek, experience, unit } = args;

  // Phase boundaries
  const taperWeeks = 3;
  const peakWeeks = 2;
  const remaining = weeks - taperWeeks - peakWeeks;
  const baseWeeks = Math.ceil(remaining / 2);
  const buildWeeks = remaining - baseWeeks;

  // Peak weekly mileage by experience
  const peakWeeklyByExp = {
    first: 35,
    some: 45,
    experienced: 55,
  };
  const peakWeekly = Math.max(peakWeeklyByExp[experience], currentMileage + 10);

  // Goal pace per mile in seconds
  const goalPaceSec = goalSeconds / MARATHON_MI;
  const easyPaceSec = goalPaceSec + 90;
  const tempoPaceSec = goalPaceSec + 10;
  const intervalPaceSec = goalPaceSec - 30;
  const longPaceSec = goalPaceSec + 60;

  const plans: WeekPlan[] = [];
  for (let w = 1; w <= weeks; w += 1) {
    let phase = 'Base';
    let phaseProgress = 0;
    if (w <= baseWeeks) {
      phase = 'Base';
      phaseProgress = w / baseWeeks;
    } else if (w <= baseWeeks + buildWeeks) {
      phase = 'Build';
      phaseProgress = (w - baseWeeks) / buildWeeks;
    } else if (w <= baseWeeks + buildWeeks + peakWeeks) {
      phase = 'Peak';
      phaseProgress = (w - baseWeeks - buildWeeks) / peakWeeks;
    } else {
      phase = 'Taper';
      phaseProgress = (w - baseWeeks - buildWeeks - peakWeeks) / taperWeeks;
    }

    // Weekly mileage ramp
    let weekly: number;
    if (phase === 'Base') {
      weekly = currentMileage + (peakWeekly * 0.7 - currentMileage) * phaseProgress;
    } else if (phase === 'Build') {
      weekly = peakWeekly * 0.7 + (peakWeekly - peakWeekly * 0.7) * phaseProgress;
    } else if (phase === 'Peak') {
      weekly = peakWeekly;
    } else {
      weekly = peakWeekly * (1 - phaseProgress * 0.55);
    }

    // Every 4th week in Base/Build is a cutback week
    if ((phase === 'Base' || phase === 'Build') && w % 4 === 0) {
      weekly *= 0.8;
    }

    // Long run
    let longRun: number;
    if (phase === 'Base') {
      longRun = Math.min(8 + (16 - 8) * phaseProgress, 16);
    } else if (phase === 'Build') {
      longRun = 16 + (20 - 16) * phaseProgress;
    } else if (phase === 'Peak') {
      longRun = 20 + (22 - 20) * phaseProgress;
    } else {
      longRun = Math.max(8, 22 * (1 - phaseProgress * 0.7));
    }
    if (w === weeks) longRun = 4; // race week shake-out

    // Day distribution
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // 7 slots, fill based on daysPerWeek
    const tempoDist = Math.min(6, weekly * 0.15);
    const intervalDist = Math.min(5, weekly * 0.12);
    const remainingDist = Math.max(0, weekly - longRun - tempoDist - intervalDist);
    const easyCount = Math.max(1, daysPerWeek - 3);
    const easyDist = remainingDist / easyCount;

    // Standard schedule
    const schedule: { day: string; type: string; dist: number; paceSec?: number; note?: string }[] = [];

    if (daysPerWeek >= 6) {
      schedule.push(
        { day: 'Mon', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Tue', type: 'Intervals', dist: intervalDist, paceSec: intervalPaceSec, note: '6x800m or 4x1mi' },
        { day: 'Wed', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Thu', type: 'Tempo', dist: tempoDist, paceSec: tempoPaceSec, note: 'Marathon pace ± 10s' },
        { day: 'Fri', type: 'Rest', dist: 0 },
        { day: 'Sat', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Sun', type: 'Long', dist: longRun, paceSec: longPaceSec },
      );
    } else if (daysPerWeek === 5) {
      schedule.push(
        { day: 'Mon', type: 'Rest', dist: 0 },
        { day: 'Tue', type: 'Intervals', dist: intervalDist, paceSec: intervalPaceSec, note: '6x800m or 4x1mi' },
        { day: 'Wed', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Thu', type: 'Tempo', dist: tempoDist, paceSec: tempoPaceSec, note: 'Marathon pace ± 10s' },
        { day: 'Fri', type: 'Rest', dist: 0 },
        { day: 'Sat', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Sun', type: 'Long', dist: longRun, paceSec: longPaceSec },
      );
    } else if (daysPerWeek === 4) {
      schedule.push(
        { day: 'Mon', type: 'Rest', dist: 0 },
        { day: 'Tue', type: 'Intervals', dist: intervalDist, paceSec: intervalPaceSec, note: '6x800m' },
        { day: 'Wed', type: 'Rest', dist: 0 },
        { day: 'Thu', type: 'Tempo', dist: tempoDist, paceSec: tempoPaceSec },
        { day: 'Fri', type: 'Rest', dist: 0 },
        { day: 'Sat', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Sun', type: 'Long', dist: longRun, paceSec: longPaceSec },
      );
    } else {
      schedule.push(
        { day: 'Mon', type: 'Rest', dist: 0 },
        { day: 'Tue', type: 'Tempo', dist: tempoDist, paceSec: tempoPaceSec },
        { day: 'Wed', type: 'Rest', dist: 0 },
        { day: 'Thu', type: 'Easy', dist: easyDist, paceSec: easyPaceSec },
        { day: 'Fri', type: 'Rest', dist: 0 },
        { day: 'Sat', type: 'Rest', dist: 0 },
        { day: 'Sun', type: 'Long', dist: longRun, paceSec: longPaceSec },
      );
    }

    // Race week override
    if (w === weeks) {
      schedule.length = 0;
      schedule.push(
        { day: 'Mon', type: 'Easy', dist: 3, paceSec: easyPaceSec },
        { day: 'Tue', type: 'Rest', dist: 0 },
        { day: 'Wed', type: 'Tune-up', dist: 3, paceSec: tempoPaceSec, note: 'Last 1mi at goal pace' },
        { day: 'Thu', type: 'Rest', dist: 0 },
        { day: 'Fri', type: 'Easy shake-out', dist: 2, paceSec: easyPaceSec },
        { day: 'Sat', type: 'Rest', dist: 0 },
        { day: 'Sun', type: 'RACE', dist: MARATHON_MI, paceSec: goalPaceSec, note: 'Send it' },
      );
    }

    const total = schedule.reduce((s, d) => s + d.dist, 0);

    const dayRows: DayRow[] = schedule.map((d) => ({
      day: dayNames[dayNames.indexOf(d.day)],
      type: d.type,
      distance: unit === 'mi' ? d.dist : d.dist * 1.609,
      pace: d.paceSec ? secondsToPace(d.paceSec, unit) : undefined,
      note: d.note,
    }));

    plans.push({
      weekNum: w,
      phase,
      longRun: unit === 'mi' ? longRun : longRun * 1.609,
      totalMileage: unit === 'mi' ? total : total * 1.609,
      days: dayRows,
    });
  }

  return plans;
}

const phaseColors: Record<string, string> = {
  Base: 'bg-sky-500/15 text-sky-400 border-sky-500/30',
  Build: 'bg-emerald-500/15 text-emerald-400 border-emerald-500/30',
  Peak: 'bg-amber-500/15 text-amber-400 border-amber-500/30',
  Taper: 'bg-violet-500/15 text-violet-400 border-violet-500/30',
};

export default function MarathonPlanGenerator() {
  const [raceDate, setRaceDate] = useState(() => {
    const d = new Date();
    d.setDate(d.getDate() + 16 * 7);
    return d.toISOString().slice(0, 10);
  });
  const [goalH, setGoalH] = useState(4);
  const [goalM, setGoalM] = useState(0);
  const [goalS, setGoalS] = useState(0);
  const [currentMileage, setCurrentMileage] = useState(20);
  const [unit, setUnit] = useState<Unit>('mi');
  const [daysPerWeek, setDaysPerWeek] = useState(5);
  const [experience, setExperience] = useState<Experience>('first');
  const [expandedWeek, setExpandedWeek] = useState<number | null>(1);

  const weeks = useMemo(() => weeksBetween(raceDate), [raceDate]);
  const goalSeconds = parseGoalTime(goalH, goalM, goalS);
  const currentInMiles = unit === 'mi' ? currentMileage : currentMileage / 1.609;

  const plan = useMemo(
    () =>
      buildPlan({
        weeks,
        currentMileage: currentInMiles,
        goalSeconds,
        daysPerWeek,
        experience,
        unit,
      }),
    [weeks, currentInMiles, goalSeconds, daysPerWeek, experience, unit],
  );

  const goalPaceSecPerMile = goalSeconds / MARATHON_MI;
  const goalPaceDisplay = secondsToPace(goalPaceSecPerMile, unit);

  return (
    <CalculatorShell
      slug="marathon-plan-generator"
      title="Marathon Plan Generator"
      metaDescription="Free week-by-week marathon training plan tailored to your race date, goal time, current mileage, and experience. Includes pace zones for easy, tempo, intervals, and long runs."
      intro="Enter your race date, finish goal, and current weekly mileage. We build the full plan: base, build, peak, taper, with daily pace targets for every run. No subscription. No email gate."
      faqs={[
        {
          q: 'How is the plan structured?',
          a: 'Four phases. Base builds aerobic foundation. Build adds threshold and interval work. Peak pushes long-run distance to 20-22 miles. Taper cuts volume by half over three weeks while preserving intensity. Every fourth week in Base and Build is a cutback week at 80 percent volume to allow recovery.',
        },
        {
          q: 'Where do the pace zones come from?',
          a: 'Easy pace is goal-marathon pace plus 90 seconds per mile (Daniels conversational pace). Tempo is goal pace plus 10 seconds (lactate threshold). Intervals are goal pace minus 30 seconds (VO2 work). Long runs are goal pace plus 60 seconds. Pace zones drift faster as you adapt, but these are sound starting targets.',
        },
        {
          q: 'My current weekly mileage is below 20. Can I follow this?',
          a: 'You can, but consider adding 4-6 weeks of pre-base before starting. The plan assumes you can already run 20 miles per week comfortably. Below that, increase weekly mileage by no more than 10 percent per week until you reach the starting point, then begin.',
        },
        {
          q: 'How does this compare to Runna or TrainingPeaks plans?',
          a: 'Conceptually identical phase structure and pace zoning. Runna costs $14.99/month and adds in-app workouts, GPS coaching, and live adjustments. TrainingPeaks plans run $40-150 one-time. This generator gives you the full periodized plan free. Zealova ($7.99/mo) adds the in-app execution and adaptive adjustments.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-6">Your race</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Race date</span>
            <input
              type="date"
              value={raceDate}
              onChange={(e) => setRaceDate(e.target.value)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <p className="text-xs text-zinc-500 mt-1.5">
              {weeks} weeks until race (capped 8-16)
            </p>
          </label>
          <div>
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Goal finish time</span>
            <div className="grid grid-cols-3 gap-2">
              <input
                type="number"
                min={2}
                max={7}
                value={goalH}
                onChange={(e) => setGoalH(parseInt(e.target.value) || 0)}
                className="px-3 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
                placeholder="h"
              />
              <input
                type="number"
                min={0}
                max={59}
                value={goalM}
                onChange={(e) => setGoalM(parseInt(e.target.value) || 0)}
                className="px-3 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
                placeholder="m"
              />
              <input
                type="number"
                min={0}
                max={59}
                value={goalS}
                onChange={(e) => setGoalS(parseInt(e.target.value) || 0)}
                className="px-3 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base text-center focus:outline-none focus:ring-2 focus:ring-emerald-500"
                placeholder="s"
              />
            </div>
            <p className="text-xs text-zinc-500 mt-1.5">
              Goal pace: <span className="font-mono text-emerald-400">{goalPaceDisplay}</span> per {unit}
            </p>
          </div>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
          <div>
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Current weekly mileage</span>
            <div className="flex gap-2">
              <input
                type="number"
                min={0}
                value={currentMileage}
                onChange={(e) => setCurrentMileage(parseFloat(e.target.value) || 0)}
                className="flex-1 px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
              />
              <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
                {(['mi', 'km'] as Unit[]).map((u) => (
                  <button
                    key={u}
                    onClick={() => setUnit(u)}
                    className={`px-3 py-1 text-xs font-medium rounded-md transition ${
                      unit === u ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                    }`}
                  >
                    {u}
                  </button>
                ))}
              </div>
            </div>
          </div>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Days per week available</span>
            <div className="grid grid-cols-4 gap-2">
              {[3, 4, 5, 6].map((d) => (
                <button
                  key={d}
                  onClick={() => setDaysPerWeek(d)}
                  className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${
                    daysPerWeek === d
                      ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                      : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                  }`}
                >
                  {d}
                </button>
              ))}
            </div>
          </label>
        </div>

        <div>
          <span className="block text-sm font-medium text-zinc-300 mb-1.5">Experience</span>
          <div className="grid grid-cols-3 gap-2">
            {([
              { v: 'first' as Experience, label: 'First marathon' },
              { v: 'some' as Experience, label: 'Done 1-2' },
              { v: 'experienced' as Experience, label: 'Experienced' },
            ]).map((opt) => (
              <button
                key={opt.v}
                onClick={() => setExperience(opt.v)}
                className={`px-3 py-2 rounded-lg text-sm font-medium border transition ${
                  experience === opt.v
                    ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                    : 'bg-zinc-950 border-zinc-700 text-zinc-300 hover:border-zinc-500'
                }`}
              >
                {opt.label}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Your plan</h2>
        <p className="text-sm text-zinc-400 mb-4">
          {weeks}-week build to a {goalH}:{String(goalM).padStart(2, '0')}:{String(goalS).padStart(2, '0')} marathon. Tap a week to expand.
        </p>
        <div className="space-y-2">
          {plan.map((week) => (
            <div key={week.weekNum} className="rounded-xl border border-zinc-800 bg-zinc-900 overflow-hidden">
              <button
                onClick={() => setExpandedWeek(expandedWeek === week.weekNum ? null : week.weekNum)}
                className="w-full px-4 py-3 flex items-center justify-between hover:bg-zinc-800/50 transition"
              >
                <div className="flex items-center gap-3">
                  <span className="text-sm font-bold text-white w-12 text-left">W{week.weekNum}</span>
                  <span
                    className={`text-[10px] uppercase tracking-wide px-2 py-0.5 rounded border font-semibold ${
                      phaseColors[week.phase]
                    }`}
                  >
                    {week.phase}
                  </span>
                  <span className="text-xs text-zinc-400 hidden sm:inline">
                    Long run {week.longRun.toFixed(1)} {unit}
                  </span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-sm font-mono font-semibold text-white">
                    {week.totalMileage.toFixed(1)} {unit}
                  </span>
                  <span className="text-emerald-500 text-lg">
                    {expandedWeek === week.weekNum ? '−' : '+'}
                  </span>
                </div>
              </button>
              {expandedWeek === week.weekNum && (
                <div className="border-t border-zinc-800 px-4 py-3 bg-zinc-950">
                  <table className="w-full text-sm">
                    <thead>
                      <tr className="text-xs text-zinc-500">
                        <th className="text-left py-1 font-medium">Day</th>
                        <th className="text-left py-1 font-medium">Type</th>
                        <th className="text-right py-1 font-medium">Distance</th>
                        <th className="text-right py-1 font-medium hidden sm:table-cell">Pace</th>
                      </tr>
                    </thead>
                    <tbody>
                      {week.days.map((d, i) => (
                        <tr key={i} className="border-t border-zinc-800/50">
                          <td className="py-2 text-zinc-400 font-medium">{d.day}</td>
                          <td className="py-2 text-white">
                            {d.type}
                            {d.note && <span className="block text-xs text-zinc-500">{d.note}</span>}
                          </td>
                          <td className="py-2 text-right font-mono text-zinc-300">
                            {d.distance > 0 ? `${d.distance.toFixed(1)} ${unit}` : '–'}
                          </td>
                          <td className="py-2 text-right font-mono text-zinc-500 hidden sm:table-cell">
                            {d.pace ?? '–'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          ))}
        </div>
      </section>

      <section className="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <h2 className="text-lg font-bold text-white mb-3">Pace zones for this goal</h2>
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 text-sm">
          <div>
            <p className="text-xs uppercase text-zinc-500 mb-1">Easy</p>
            <p className="font-mono font-semibold text-white">{secondsToPace(goalPaceSecPerMile + 90, unit)}</p>
          </div>
          <div>
            <p className="text-xs uppercase text-zinc-500 mb-1">Long</p>
            <p className="font-mono font-semibold text-white">{secondsToPace(goalPaceSecPerMile + 60, unit)}</p>
          </div>
          <div>
            <p className="text-xs uppercase text-zinc-500 mb-1">Tempo</p>
            <p className="font-mono font-semibold text-white">{secondsToPace(goalPaceSecPerMile + 10, unit)}</p>
          </div>
          <div>
            <p className="text-xs uppercase text-zinc-500 mb-1">Intervals</p>
            <p className="font-mono font-semibold text-emerald-400">{secondsToPace(goalPaceSecPerMile - 30, unit)}</p>
          </div>
        </div>
      </section>

      <InstallCta
        slug="marathon-plan-generator"
        result={{ weeks, goalSeconds, daysPerWeek, experience, currentMileage, unit }}
        primary="Run this plan in Zealova with auto-tracked pace and adaptive adjustments"
        secondary="Zealova syncs to your watch, adjusts the plan weekly based on actual paces, and re-paces every workout in real time."
      />

      <MethodologyFooter
        citations={[
          {
            text: "Daniels J, Gilbert J (2014). Daniels' Running Formula, 3rd edition. Human Kinetics. VDOT pace tables and training intensity zones.",
          },
          {
            text: 'Pfitzinger P, Douglas S (2008). Advanced Marathoning, 2nd edition. Human Kinetics. 18-week marathon training framework.',
          },
          {
            text: 'Karp JR (2007). Training characteristics of qualifiers for the US Olympic Marathon Trials. International Journal of Sports Physiology and Performance 2(1):72-92.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/19255456/',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
