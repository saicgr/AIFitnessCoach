// /free-tools/workout-plan-builder
//
// 5-step wizard producing a deterministic 4-week training plan. No LLM.
// Exercise selection is matched to user equipment. Volume targets are
// per Schoenfeld 2017 hypertrophy dose-response (10-20 sets/muscle/wk).

import { useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type Goal = 'muscle' | 'fat' | 'stronger' | 'general';
type Experience = '<6mo' | '6-12mo' | '1-3yr' | '3yr+';
type Equipment = 'barbell' | 'dumbbells' | 'machines' | 'cables' | 'bodyweight' | 'bands';

interface Exercise {
  name: string;
  muscle: string;
  equipment: Equipment[];
  setsRange: [number, number];
}

interface DayPlan {
  name: string;
  exercises: Array<{
    name: string;
    muscle: string;
    sets: number;
    reps: string;
    note?: string;
  }>;
}

// ─── Exercise library (curated, equipment-tagged) ───
const LIBRARY: Exercise[] = [
  // Chest
  { name: 'Barbell Bench Press', muscle: 'Chest', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Dumbbell Bench Press', muscle: 'Chest', equipment: ['dumbbells'], setsRange: [3, 4] },
  { name: 'Incline Dumbbell Press', muscle: 'Chest', equipment: ['dumbbells'], setsRange: [3, 4] },
  { name: 'Machine Chest Press', muscle: 'Chest', equipment: ['machines'], setsRange: [3, 4] },
  { name: 'Cable Crossover', muscle: 'Chest', equipment: ['cables'], setsRange: [3, 3] },
  { name: 'Push-Up', muscle: 'Chest', equipment: ['bodyweight'], setsRange: [3, 4] },
  { name: 'Band Chest Press', muscle: 'Chest', equipment: ['bands'], setsRange: [3, 4] },
  // Back
  { name: 'Barbell Row', muscle: 'Back', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Deadlift', muscle: 'Back', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Dumbbell Row', muscle: 'Back', equipment: ['dumbbells'], setsRange: [3, 4] },
  { name: 'Lat Pulldown', muscle: 'Back', equipment: ['machines', 'cables'], setsRange: [3, 4] },
  { name: 'Seated Cable Row', muscle: 'Back', equipment: ['cables', 'machines'], setsRange: [3, 4] },
  { name: 'Pull-Up', muscle: 'Back', equipment: ['bodyweight'], setsRange: [3, 4] },
  { name: 'Band Pull-Apart', muscle: 'Back', equipment: ['bands'], setsRange: [3, 4] },
  // Quads
  { name: 'Back Squat', muscle: 'Quads', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Front Squat', muscle: 'Quads', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Goblet Squat', muscle: 'Quads', equipment: ['dumbbells'], setsRange: [3, 4] },
  { name: 'Leg Press', muscle: 'Quads', equipment: ['machines'], setsRange: [3, 4] },
  { name: 'Leg Extension', muscle: 'Quads', equipment: ['machines'], setsRange: [3, 4] },
  { name: 'Bulgarian Split Squat', muscle: 'Quads', equipment: ['dumbbells', 'bodyweight'], setsRange: [3, 4] },
  { name: 'Bodyweight Squat', muscle: 'Quads', equipment: ['bodyweight'], setsRange: [3, 4] },
  // Hamstrings + glutes
  { name: 'Romanian Deadlift', muscle: 'Hamstrings', equipment: ['barbell', 'dumbbells'], setsRange: [3, 4] },
  { name: 'Leg Curl', muscle: 'Hamstrings', equipment: ['machines'], setsRange: [3, 4] },
  { name: 'Hip Thrust', muscle: 'Glutes', equipment: ['barbell', 'dumbbells'], setsRange: [3, 4] },
  { name: 'Cable Pull-Through', muscle: 'Glutes', equipment: ['cables'], setsRange: [3, 4] },
  { name: 'Glute Bridge', muscle: 'Glutes', equipment: ['bodyweight'], setsRange: [3, 4] },
  // Shoulders
  { name: 'Overhead Press', muscle: 'Shoulders', equipment: ['barbell'], setsRange: [3, 4] },
  { name: 'Dumbbell Shoulder Press', muscle: 'Shoulders', equipment: ['dumbbells'], setsRange: [3, 4] },
  { name: 'Lateral Raise', muscle: 'Shoulders', equipment: ['dumbbells', 'cables', 'bands'], setsRange: [3, 4] },
  { name: 'Machine Shoulder Press', muscle: 'Shoulders', equipment: ['machines'], setsRange: [3, 4] },
  { name: 'Pike Push-Up', muscle: 'Shoulders', equipment: ['bodyweight'], setsRange: [3, 3] },
  // Arms
  { name: 'Barbell Curl', muscle: 'Biceps', equipment: ['barbell'], setsRange: [2, 3] },
  { name: 'Dumbbell Curl', muscle: 'Biceps', equipment: ['dumbbells'], setsRange: [2, 3] },
  { name: 'Cable Curl', muscle: 'Biceps', equipment: ['cables'], setsRange: [2, 3] },
  { name: 'Chin-Up', muscle: 'Biceps', equipment: ['bodyweight'], setsRange: [2, 3] },
  { name: 'Close-Grip Bench', muscle: 'Triceps', equipment: ['barbell'], setsRange: [2, 3] },
  { name: 'Skull Crusher', muscle: 'Triceps', equipment: ['barbell', 'dumbbells'], setsRange: [2, 3] },
  { name: 'Cable Tricep Pushdown', muscle: 'Triceps', equipment: ['cables'], setsRange: [2, 3] },
  { name: 'Dips', muscle: 'Triceps', equipment: ['bodyweight'], setsRange: [2, 3] },
  // Core
  { name: 'Hanging Knee Raise', muscle: 'Core', equipment: ['bodyweight'], setsRange: [3, 3] },
  { name: 'Cable Crunch', muscle: 'Core', equipment: ['cables'], setsRange: [3, 3] },
  { name: 'Plank', muscle: 'Core', equipment: ['bodyweight'], setsRange: [3, 3] },
];

// ─── Split selection ───
function pickSplit(goal: Goal, days: number): string[] {
  if (goal === 'muscle' && days >= 4) {
    return ['Upper A', 'Lower A', 'Upper B', 'Lower B', 'Full Body', 'Pull/Push'].slice(0, days);
  }
  if (goal === 'stronger') {
    if (days <= 3) return ['Push', 'Pull', 'Legs'].slice(0, days);
    return ['Push A', 'Pull A', 'Legs A', 'Push B', 'Pull B', 'Legs B'].slice(0, days);
  }
  if (goal === 'fat' || goal === 'general') {
    const all = ['Full Body A', 'Full Body B', 'Full Body C', 'Full Body D', 'Full Body E', 'Full Body F'];
    return all.slice(0, days);
  }
  // muscle <4 days fallback
  return ['Full Body A', 'Full Body B', 'Full Body C', 'Full Body D'].slice(0, days);
}

function pickRepRange(goal: Goal, muscle: string): string {
  if (goal === 'stronger' && ['Chest', 'Back', 'Quads', 'Hamstrings', 'Shoulders'].includes(muscle)) {
    return '4-6';
  }
  if (goal === 'fat') return '10-15';
  if (goal === 'general') return '8-12';
  return '8-12';
}

function templateForDay(dayName: string): string[] {
  // Returns the ordered list of muscles to train that day
  if (dayName.startsWith('Upper')) {
    return ['Chest', 'Back', 'Shoulders', 'Biceps', 'Triceps'];
  }
  if (dayName.startsWith('Lower')) {
    return ['Quads', 'Hamstrings', 'Glutes', 'Core'];
  }
  if (dayName.startsWith('Push')) {
    return ['Chest', 'Shoulders', 'Triceps'];
  }
  if (dayName.startsWith('Pull')) {
    return ['Back', 'Biceps', 'Core'];
  }
  if (dayName.startsWith('Legs')) {
    return ['Quads', 'Hamstrings', 'Glutes', 'Core'];
  }
  // Full body
  return ['Quads', 'Chest', 'Back', 'Shoulders', 'Hamstrings', 'Core'];
}

function buildPlan(
  goal: Goal,
  experience: Experience,
  equipment: Equipment[],
  days: number,
): DayPlan[] {
  if (equipment.length === 0) return [];
  const split = pickSplit(goal, days);
  // Experience scales total sets per muscle/exercise
  const expScale: Record<Experience, number> = {
    '<6mo': 0.8,
    '6-12mo': 1.0,
    '1-3yr': 1.1,
    '3yr+': 1.2,
  };

  // Track which exercise we last used per muscle so we vary across days.
  const lastUsedIdx: Record<string, number> = {};

  return split.map((dayName) => {
    const muscles = templateForDay(dayName);
    const exercises: DayPlan['exercises'] = [];
    muscles.forEach((muscle) => {
      const candidates = LIBRARY.filter(
        (ex) => ex.muscle === muscle && ex.equipment.some((eq) => equipment.includes(eq)),
      );
      if (candidates.length === 0) return;
      const lastIdx = lastUsedIdx[muscle] ?? -1;
      const next = candidates[(lastIdx + 1) % candidates.length];
      lastUsedIdx[muscle] = (lastIdx + 1) % candidates.length;
      const baseSets = Math.round((next.setsRange[0] + next.setsRange[1]) / 2);
      const sets = Math.max(2, Math.round(baseSets * expScale[experience]));
      exercises.push({
        name: next.name,
        muscle: next.muscle,
        sets,
        reps: pickRepRange(goal, muscle),
      });
    });
    return { name: dayName, exercises };
  });
}

const EQUIPMENT_OPTIONS: { value: Equipment; label: string }[] = [
  { value: 'barbell', label: 'Barbell + plates' },
  { value: 'dumbbells', label: 'Dumbbells' },
  { value: 'machines', label: 'Machines' },
  { value: 'cables', label: 'Cables' },
  { value: 'bodyweight', label: 'Bodyweight only' },
  { value: 'bands', label: 'Resistance bands' },
];

const GOAL_LABELS: Record<Goal, string> = {
  muscle: 'Build muscle',
  fat: 'Lose fat',
  stronger: 'Get stronger',
  general: 'General fitness',
};

const EXPERIENCE_LABELS: Record<Experience, string> = {
  '<6mo': 'Less than 6 months',
  '6-12mo': '6 to 12 months',
  '1-3yr': '1 to 3 years',
  '3yr+': '3+ years',
};

export default function WorkoutPlanBuilder() {
  const [step, setStep] = useState<number>(1);
  const [goal, setGoal] = useState<Goal>('muscle');
  const [experience, setExperience] = useState<Experience>('6-12mo');
  const [equipment, setEquipment] = useState<Equipment[]>(['barbell', 'dumbbells']);
  const [daysPerWeek, setDaysPerWeek] = useState<number>(4);
  const [constraints, setConstraints] = useState<string>('');
  const wizardRef = useRef<HTMLDivElement | null>(null);

  // Avoid stranding the user mid-scroll when stepping forward/back.
  useEffect(() => {
    if (!wizardRef.current) return;
    const top = wizardRef.current.getBoundingClientRect().top + window.scrollY - 80;
    if (Math.abs(window.scrollY - top) > 60) {
      window.scrollTo({ top, behavior: 'smooth' });
    }
  }, [step]);

  const plan = useMemo(
    () => buildPlan(goal, experience, equipment, daysPerWeek),
    [goal, experience, equipment, daysPerWeek],
  );

  const totalWeeklyVolume = useMemo(
    () => plan.reduce((acc, d) => acc + d.exercises.reduce((s, e) => s + e.sets, 0), 0),
    [plan],
  );

  const toggleEquipment = (eq: Equipment) => {
    setEquipment((prev) =>
      prev.includes(eq) ? prev.filter((e) => e !== eq) : [...prev, eq],
    );
  };

  const canNext = () => {
    if (step === 3 && equipment.length === 0) return false;
    return true;
  };

  return (
    <CalculatorShell
      slug="workout-plan-builder"
      title="Workout Plan Builder"
      metaDescription="Free 4-week training plan generator. 5-step wizard picks an evidence-based split, exercise selection per your equipment, and weekly volume per Schoenfeld hypertrophy research. No sign-up, no email gate."
      intro="Five questions, one 4-week plan. Goal, experience, equipment, days, constraints. The output respects the 10 to 20 sets per muscle per week hypertrophy range from Schoenfeld 2017 and only picks exercises you can actually do with your gear."
      emailCaptureResult={
        step === 5 && plan.length > 0
          ? {
              goal,
              experience,
              equipment,
              daysPerWeek,
              weeklySets: totalWeeklyVolume,
            }
          : undefined
      }
      installPrimary="Take this plan into the app. Zealova auto-adjusts the weights."
      installSecondary="Zealova learns from every set you log, progresses the weight automatically, and rotates exercises every mesocycle so you never plateau."
      faqs={[
        {
          q: 'Why 4 weeks?',
          a: '4 weeks is one standard mesocycle. Long enough for progressive overload to manifest, short enough to deload before fatigue dominates per the MEV/MAV/MRV model. After 4 weeks you should deload for a week and either repeat or rotate exercises.',
        },
        {
          q: 'How does it pick exercises for my equipment?',
          a: 'Every exercise in the library is tagged with the equipment it requires (barbell, dumbbells, machines, cables, bodyweight, bands). The builder only picks from exercises that match at least one piece of gear you selected. Pick more equipment, get more variety.',
        },
        {
          q: 'Where does the rep range come from?',
          a: 'For Build Muscle and General Fitness, 8-12 reps which is the canonical hypertrophy range. For Get Stronger, compound lifts move to 4-6 reps where strength adapts fastest per Schoenfeld & Grgic 2018. For Lose Fat we bump to 10-15 reps to increase total work and metabolic cost.',
        },
        {
          q: 'How is volume calibrated to experience?',
          a: 'Beginners (<6 months) train at 0.8x base sets, intermediate (6-12 months) at 1.0x, advanced (1-3 years) at 1.1x, very advanced (3+ years) at 1.2x. The base sits in the middle of each exercise\'s recommended range. The total weekly volume per muscle lands in the 10-20 set hypertrophy zone for most users.',
        },
        {
          q: 'What about cardio?',
          a: 'This builder focuses on resistance training only because that is where exercise selection and equipment matching matter most. Add 2 to 3 zone-2 cardio sessions per week, 25-40 minutes, on non-lifting days for fat loss or general health.',
        },
        {
          q: 'Why no progression scheme in the output?',
          a: 'Progression is week-by-week, set-by-set, RIR-based, and depends on how each set actually went. A static print-out cannot do that. This is the exact reason Zealova exists: log a set, the app sets the next one for you using RPE/RIR feedback. The free plan is a template; the app is the engine.',
        },
        {
          q: 'Can I print this and bring it to the gym?',
          a: 'Yes, use Cmd+P or Ctrl+P after generating to print or save as PDF. For a logged version with weights and rest timers, that lives inside the app.',
        },
      ]}
    >
      {/* Step indicator */}
      <section ref={wizardRef}>
        <div className="flex items-center justify-between mb-3">
          <p className="text-xs font-semibold uppercase tracking-wider text-emerald-400">
            Step {step} of 5
          </p>
          {step > 1 && step < 5 && (
            <button
              type="button"
              onClick={() => setStep(1)}
              className="text-xs text-zinc-500 hover:text-zinc-300"
            >
              Start over
            </button>
          )}
        </div>
        <div className="flex gap-1.5">
          {[1, 2, 3, 4, 5].map((s) => (
            <div
              key={s}
              className={`h-1.5 flex-1 rounded-full transition ${
                s <= step ? 'bg-emerald-500' : 'bg-zinc-800'
              }`}
            />
          ))}
        </div>
      </section>

      {/* Step content */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        {step === 1 && (
          <div>
            <h2 className="text-lg font-bold text-white mb-1">What is your primary goal?</h2>
            <p className="text-sm text-zinc-400 mb-5">
              Pick the one that matters most. We optimize the split, reps, and volume around it.
            </p>
            <div className="space-y-2">
              {(Object.keys(GOAL_LABELS) as Goal[]).map((g) => (
                <label
                  key={g}
                  className={`flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition ${
                    goal === g
                      ? 'border-emerald-500/50 bg-emerald-500/10'
                      : 'border-zinc-800 bg-zinc-950 hover:border-zinc-700'
                  }`}
                >
                  <input
                    type="radio"
                    name="goal"
                    value={g}
                    checked={goal === g}
                    onChange={() => setGoal(g)}
                    className="accent-emerald-500"
                  />
                  <span className="text-sm text-white font-medium">{GOAL_LABELS[g]}</span>
                </label>
              ))}
            </div>
          </div>
        )}

        {step === 2 && (
          <div>
            <h2 className="text-lg font-bold text-white mb-1">How long have you been training?</h2>
            <p className="text-sm text-zinc-400 mb-5">
              Consistent training, not on-and-off. We scale weekly volume to your training age.
            </p>
            <div className="space-y-2">
              {(Object.keys(EXPERIENCE_LABELS) as Experience[]).map((e) => (
                <label
                  key={e}
                  className={`flex items-center gap-3 p-3.5 rounded-xl border cursor-pointer transition ${
                    experience === e
                      ? 'border-emerald-500/50 bg-emerald-500/10'
                      : 'border-zinc-800 bg-zinc-950 hover:border-zinc-700'
                  }`}
                >
                  <input
                    type="radio"
                    name="exp"
                    value={e}
                    checked={experience === e}
                    onChange={() => setExperience(e)}
                    className="accent-emerald-500"
                  />
                  <span className="text-sm text-white font-medium">{EXPERIENCE_LABELS[e]}</span>
                </label>
              ))}
            </div>
          </div>
        )}

        {step === 3 && (
          <div>
            <h2 className="text-lg font-bold text-white mb-1">What equipment do you have?</h2>
            <p className="text-sm text-zinc-400 mb-5">
              Select everything you have access to. The builder will only pick exercises you can actually do.
            </p>
            <div className="flex flex-wrap gap-2">
              {EQUIPMENT_OPTIONS.map((opt) => {
                const active = equipment.includes(opt.value);
                return (
                  <button
                    key={opt.value}
                    type="button"
                    onClick={() => toggleEquipment(opt.value)}
                    className={`px-4 py-2 rounded-full text-sm font-medium border transition ${
                      active
                        ? 'bg-emerald-500 text-zinc-900 border-emerald-500'
                        : 'bg-zinc-950 text-zinc-300 border-zinc-700 hover:border-zinc-600'
                    }`}
                  >
                    {opt.label}
                  </button>
                );
              })}
            </div>
            {equipment.length === 0 && (
              <p className="text-xs text-rose-400 mt-3">Select at least one option to continue.</p>
            )}
          </div>
        )}

        {step === 4 && (
          <div>
            <h2 className="text-lg font-bold text-white mb-1">How many days per week?</h2>
            <p className="text-sm text-zinc-400 mb-5">
              Be honest. A 3-day plan you stick to beats a 6-day plan you abandon.
            </p>
            <div className="flex items-baseline justify-between mb-3">
              <span className="text-sm text-zinc-300">Training days</span>
              <span className="text-3xl font-bold text-emerald-400 tabular-nums">
                {daysPerWeek}
              </span>
            </div>
            <input
              type="range"
              min={2}
              max={6}
              step={1}
              value={daysPerWeek}
              onChange={(e) => setDaysPerWeek(parseInt(e.target.value, 10))}
              className="w-full accent-emerald-500 h-2"
            />
            <div className="flex justify-between text-xs text-zinc-500 mt-2">
              <span>2</span>
              <span>3</span>
              <span>4</span>
              <span>5</span>
              <span>6</span>
            </div>
          </div>
        )}

        {step === 5 && (
          <div>
            <h2 className="text-lg font-bold text-white mb-1">Any constraints?</h2>
            <p className="text-sm text-zinc-400 mb-4">
              Injuries, time limits, exercises you hate. Optional. This is a note for you to see beside your plan.
            </p>
            <textarea
              value={constraints}
              onChange={(e) => setConstraints(e.target.value)}
              rows={3}
              placeholder="e.g. Sore left shoulder, avoid overhead press. 45 minutes max per session."
              className="w-full px-3 py-2.5 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </div>
        )}

        {/* Nav buttons */}
        <div className="flex justify-between items-center mt-6 pt-5 border-t border-zinc-800">
          <button
            type="button"
            onClick={() => setStep((s) => Math.max(1, s - 1))}
            disabled={step === 1}
            className="px-4 py-2 rounded-lg text-sm font-semibold text-zinc-400 hover:text-white disabled:opacity-30 disabled:cursor-not-allowed"
          >
            ← Back
          </button>
          {step < 5 ? (
            <button
              type="button"
              onClick={() => canNext() && setStep((s) => Math.min(5, s + 1))}
              disabled={!canNext()}
              className="px-5 py-2 rounded-lg bg-emerald-500 text-zinc-900 text-sm font-semibold hover:bg-emerald-400 transition disabled:opacity-40 disabled:cursor-not-allowed"
            >
              Next →
            </button>
          ) : (
            <span className="text-xs text-emerald-400 font-semibold">
              Plan generated below ↓
            </span>
          )}
        </div>
      </section>

      {/* Plan output (step 5) */}
      {step === 5 && plan.length > 0 && (
        <section className="space-y-5">
          <div className="bg-gradient-to-br from-emerald-900/40 via-zinc-900 to-zinc-950 border border-emerald-500/30 rounded-2xl p-6">
            <p className="text-xs font-semibold uppercase tracking-wider text-emerald-400 mb-1">
              Your 4-week plan
            </p>
            <h2 className="text-2xl font-bold text-white">
              {GOAL_LABELS[goal]} · {daysPerWeek} day{daysPerWeek > 1 ? 's' : ''}/week ·{' '}
              {totalWeeklyVolume} sets/week
            </h2>
            <p className="text-sm text-zinc-400 mt-2">
              Run this for 4 weeks. Add 1-2 reps or 2.5-5 lb each week per exercise. Deload week 5 (50% volume, 80% load). Then repeat or rotate.
            </p>
            {constraints && (
              <div className="mt-4 rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-3">
                <p className="text-xs font-semibold text-amber-400 uppercase tracking-wider mb-1">
                  Your constraints
                </p>
                <p className="text-sm text-zinc-300">{constraints}</p>
              </div>
            )}
          </div>

          {plan.map((day, dayIdx) => (
            <div
              key={day.name}
              className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5"
            >
              <div className="flex items-baseline justify-between mb-4">
                <h3 className="text-lg font-bold text-white">
                  Day {dayIdx + 1}: <span className="text-emerald-400">{day.name}</span>
                </h3>
                <span className="text-xs text-zinc-500">
                  {day.exercises.reduce((s, e) => s + e.sets, 0)} sets
                </span>
              </div>
              <div className="divide-y divide-zinc-800">
                {day.exercises.map((ex, i) => (
                  <div
                    key={i}
                    className="grid grid-cols-[1fr_auto_auto] items-center gap-3 py-2.5"
                  >
                    <div>
                      <p className="text-sm text-white font-medium">{ex.name}</p>
                      <p className="text-xs text-zinc-500">{ex.muscle}</p>
                    </div>
                    <span className="text-sm font-semibold text-white tabular-nums">
                      {ex.sets} sets
                    </span>
                    <span className="text-sm text-emerald-400 tabular-nums">
                      {ex.reps} reps
                    </span>
                  </div>
                ))}
              </div>
            </div>
          ))}
        </section>
      )}

      {step === 5 && plan.length === 0 && (
        <div className="rounded-xl border border-rose-500/30 bg-rose-500/5 p-4">
          <p className="text-sm text-rose-300">
            No exercises matched your equipment. Go back to step 3 and pick at least one option (bodyweight covers everyone).
          </p>
        </div>
      )}

      <MethodologyFooter
        citations={[
          {
            text: 'Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass. JSS 35(11):1073-1082.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27433992/',
          },
          {
            text: 'Schoenfeld BJ, Grgic J (2018). Evidence-based guidelines for resistance training volume to maximize muscle hypertrophy. Strength Cond J 40(4):107-112.',
            url: 'https://journals.lww.com/nsca-scj/Fulltext/2018/08000/Evidence_Based_Guidelines_for_Resistance_Training.13.aspx',
          },
          {
            text: 'Helms ER et al. (2014). Recommendations for natural bodybuilding contest preparation. JISSN 11:20.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/',
          },
          {
            text: 'NSCA Essentials of Strength Training and Conditioning, 4th ed. — periodization and exercise selection.',
            url: 'https://www.nsca.com/store/product-detail/INV/9781492501626/9781492501626',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}
