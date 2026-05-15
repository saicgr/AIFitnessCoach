// /free-tools/workout-vibe-generator
//
// Vibe-based workout picker. Tap a vibe → see a deterministic workout
// drawn from a curated bank. No randomness, no API calls. Pure client-side.
//
// All workouts are real training, not joke programming. The humor is in the
// vibe naming. The exercise prescription is honest.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface ExerciseBlock {
  name: string;
  prescription: string; // e.g. "4 × 5 @ RPE 8"
  note?: string;
}

interface Vibe {
  id: string;
  emoji: string;
  name: string;
  tagline: string;
  duration: number;          // minutes
  intensity: 1 | 2 | 3 | 4 | 5;
  goal: string;
  blocks: ExerciseBlock[];
}

const VIBES: Vibe[] = [
  {
    id: 'main-character',
    emoji: '⚡',
    name: 'Main Character Energy',
    tagline: 'Heavy compounds. Low reps. Walk out feeling like the protagonist.',
    duration: 55,
    intensity: 5,
    goal: 'Maximal strength + ego refill',
    blocks: [
      { name: 'Back squat', prescription: '5 × 3 @ RPE 8', note: '3 min rest. Beltless first set, belted after.' },
      { name: 'Bench press', prescription: '5 × 3 @ RPE 8', note: 'Pause every rep on the chest.' },
      { name: 'Weighted pull-up', prescription: '4 × 5', note: 'Add load, control the descent.' },
      { name: 'Romanian deadlift', prescription: '3 × 6', note: 'Heavy but clean. Hinge, do not squat it.' },
      { name: 'Standing overhead press', prescription: '3 × 5', note: 'Full lockout, glutes tight.' },
      { name: 'Farmer carry', prescription: '4 × 40m heavy', note: 'Pick a weight that makes the last 10m a fight.' },
    ],
  },
  {
    id: 'hungover',
    emoji: '🌫️',
    name: 'Hungover',
    tagline: 'Zone 2 + mobility. Productive recovery, not punishment.',
    duration: 45,
    intensity: 1,
    goal: 'Active recovery, blood flow, joint health',
    blocks: [
      { name: 'Incline treadmill walk', prescription: '30 min @ HR 110-130', note: 'Conversational pace. 8-12% incline.' },
      { name: '90/90 hip switches', prescription: '2 × 10/side', note: 'Slow and unloaded.' },
      { name: 'Cat-cow + thread-the-needle', prescription: '2 × 8 each', note: 'Breath drives the movement.' },
      { name: 'Wall slides', prescription: '2 × 12', note: 'Open up the shoulders without overhead loading.' },
      { name: 'Couch stretch', prescription: '2 × 60s/side', note: 'Hips will thank you.' },
    ],
  },
  {
    id: 'post-breakup-rage',
    emoji: '🔥',
    name: 'Post-Breakup Rage',
    tagline: 'High volume hypertrophy. Sprint finisher. Pour it into the bar.',
    duration: 65,
    intensity: 4,
    goal: 'Hypertrophy + emotional regulation via lactate',
    blocks: [
      { name: 'Goblet squat', prescription: '4 × 12', note: 'Tempo 3-0-1. Feel the quads.' },
      { name: 'Dumbbell bench press', prescription: '4 × 10', note: 'Pause 1s at the chest.' },
      { name: 'Chest-supported row', prescription: '4 × 12', note: 'Squeeze, do not yank.' },
      { name: 'Walking lunge', prescription: '3 × 20 steps', note: 'Long stride, knee tracks the toe.' },
      { name: 'Lateral raise drop set', prescription: '3 sets, 3 drops each', note: 'Start moderate, halve weight, halve again.' },
      { name: 'Assault bike sprints', prescription: '8 × 20s on / 40s off', note: 'Empty the tank. Walk out lighter.' },
    ],
  },
  {
    id: 'hotel-room',
    emoji: '🏨',
    name: 'Hotel Room, No Equipment',
    tagline: 'Bodyweight circuit. Twenty minutes. Quiet enough for neighbors.',
    duration: 20,
    intensity: 3,
    goal: 'Full-body conditioning with zero gear',
    blocks: [
      { name: 'Push-ups', prescription: '4 × max -2 reps', note: 'Elevate feet on a chair if too easy.' },
      { name: 'Bulgarian split squat (chair)', prescription: '4 × 10/side', note: 'Back foot on the bed or chair.' },
      { name: 'Inverted row (under desk or table)', prescription: '4 × 8-10', note: 'Sturdy table. Test it first.' },
      { name: 'Reverse lunge', prescription: '3 × 12/side', note: 'Slow on the way down.' },
      { name: 'Pike push-up', prescription: '3 × 8', note: 'Hips high, lower head toward the floor.' },
      { name: 'Hollow body hold', prescription: '3 × 30s', note: 'Lower back stays glued to the floor.' },
    ],
  },
  {
    id: 'feeling-cute',
    emoji: '💅',
    name: 'Feeling Cute, Might Lift Later',
    tagline: 'Upper body pump. Mirror lifts. Honest hypertrophy though.',
    duration: 50,
    intensity: 3,
    goal: 'Upper body hypertrophy, visible muscles',
    blocks: [
      { name: 'Cable lateral raise', prescription: '4 × 15', note: 'Start the set, end the set. No swinging.' },
      { name: 'Incline dumbbell curl', prescription: '4 × 12', note: 'Full stretch at the bottom.' },
      { name: 'Cable triceps pushdown', prescription: '4 × 12', note: 'Lock the elbows in place.' },
      { name: 'Incline dumbbell press', prescription: '3 × 10', note: 'Squeeze the chest at the top.' },
      { name: 'Face pull', prescription: '4 × 15', note: 'External rotation matters more than the load.' },
      { name: 'Hammer curl + spider curl superset', prescription: '3 × 10 + 10', note: 'Back-to-back. Forearms will scream.' },
    ],
  },
  {
    id: 'twenty-min',
    emoji: '⏱️',
    name: '20 Min Or Less',
    tagline: 'EMOM full body. Five rounds. In and out.',
    duration: 20,
    intensity: 4,
    goal: 'Time-efficient full-body conditioning',
    blocks: [
      { name: 'Min 1: Kettlebell swing', prescription: '15 reps', note: 'Hinge, not squat. Russian style.' },
      { name: 'Min 2: Goblet squat', prescription: '12 reps', note: 'Heels down, chest up.' },
      { name: 'Min 3: Push-ups', prescription: '15 reps', note: 'Drop to knees if form breaks.' },
      { name: 'Min 4: Dumbbell row (alternating)', prescription: '10/side', note: 'Pause at the top.' },
      { name: 'Min 5: Rest + breathe', prescription: '60s walk', note: 'Reset, then repeat for 4 more rounds.' },
    ],
  },
  {
    id: 'revenge-body',
    emoji: '🗡️',
    name: 'Revenge Body Mode',
    tagline: 'Strength plus conditioning. Sixty minutes. Hybrid athlete energy.',
    duration: 60,
    intensity: 5,
    goal: 'Strength, body comp, conditioning all at once',
    blocks: [
      { name: 'Trap bar deadlift', prescription: '5 × 5 @ RPE 8', note: 'Powerful concentric, controlled lowering.' },
      { name: 'Dumbbell incline press', prescription: '4 × 8', note: 'Heavy but clean.' },
      { name: 'Pendlay row', prescription: '4 × 6', note: 'Bar resets on the floor each rep.' },
      { name: 'Walking lunge', prescription: '3 × 16 steps loaded', note: 'Dumbbells at sides.' },
      { name: 'Rower intervals', prescription: '5 × 500m @ 2:00 rest', note: 'Hold each split within 5 seconds of the first.' },
      { name: 'Plank + side plank', prescription: '3 × 45s + 30s/side', note: 'Glutes squeezed the whole time.' },
    ],
  },
  {
    id: 'soft-girl',
    emoji: '🌸',
    name: 'Soft Girl Strength',
    tagline: 'Lighter loads. Slow tempo. Mobility woven through. Still hard.',
    duration: 45,
    intensity: 2,
    goal: 'Controlled strength + mobility',
    blocks: [
      { name: 'Goblet squat (tempo 4-1-1)', prescription: '4 × 10', note: 'Four seconds down. Pause at the bottom.' },
      { name: 'Single-leg glute bridge', prescription: '3 × 12/side', note: 'Squeeze the glute, do not arch the lower back.' },
      { name: 'Half-kneeling overhead press (light DB)', prescription: '3 × 10/side', note: 'Ribs stay down.' },
      { name: 'Suitcase carry', prescription: '4 × 30m/side', note: 'One dumbbell. Resist the lean.' },
      { name: 'Pigeon pose', prescription: '2 × 60s/side', note: 'Breath out the tightness.' },
      { name: 'Dead bug', prescription: '3 × 8/side', note: 'Slow. Lower back glued down.' },
    ],
  },
  {
    id: 'bro-split-sunday',
    emoji: '💪',
    name: 'Bro Split Sunday',
    tagline: 'Chest, triceps, ego. Yes, bro splits still build muscle.',
    duration: 60,
    intensity: 4,
    goal: 'Chest + triceps hypertrophy',
    blocks: [
      { name: 'Flat barbell bench press', prescription: '4 × 8', note: 'Pause 1s on the chest.' },
      { name: 'Incline dumbbell press', prescription: '4 × 10', note: '30-45 degree incline, not steeper.' },
      { name: 'Weighted dips', prescription: '3 × 8', note: 'Lean forward for chest emphasis.' },
      { name: 'Cable fly (high to low)', prescription: '3 × 12', note: 'Squeeze across the midline.' },
      { name: 'Close-grip bench press', prescription: '3 × 10', note: 'Elbows tucked. Hands shoulder-width.' },
      { name: 'Overhead triceps extension', prescription: '3 × 12', note: 'Full stretch overhead.' },
      { name: 'Triceps pushdown drop set', prescription: '2 sets, 2 drops each', note: 'Finish them off.' },
    ],
  },
  {
    id: 'y2k-cardio',
    emoji: '✨',
    name: 'Y2K Cardio',
    tagline: 'Dance-cardio inspired intervals. Tabata energy. Bring a playlist.',
    duration: 35,
    intensity: 4,
    goal: 'Conditioning, VO2, coordination',
    blocks: [
      { name: 'Warm-up jog or march', prescription: '5 min', note: 'Light. Get the joints moving.' },
      { name: 'Jumping jacks + high knees superset', prescription: '4 × 30s / 30s', note: 'No rest between the two.' },
      { name: 'Skater bounds', prescription: '5 × 40s on / 20s off', note: 'Land soft. Stick the landing.' },
      { name: 'Tabata mountain climbers', prescription: '8 × 20s / 10s', note: 'Hips stable. Fast feet.' },
      { name: 'Step-ups (bench or stair)', prescription: '4 × 30s/side', note: 'Drive through the heel.' },
      { name: 'Cooldown walk + stretch', prescription: '5 min', note: 'Hamstrings, hips, calves.' },
    ],
  },
];

function IntensityBar({ level }: { level: number }) {
  return (
    <div className="flex gap-1">
      {[1, 2, 3, 4, 5].map((i) => (
        <span
          key={i}
          className={`w-5 h-1.5 rounded-full ${i <= level ? 'bg-emerald-500' : 'bg-zinc-700'}`}
        />
      ))}
    </div>
  );
}

export default function WorkoutVibeGenerator() {
  const [activeId, setActiveId] = useState<string | null>(null);

  const active = useMemo(() => VIBES.find((v) => v.id === activeId), [activeId]);

  return (
    <CalculatorShell
      slug="workout-vibe-generator"
      title="Workout Vibe Generator"
      metaDescription="Pick a vibe, get a real workout. Ten vibes, ten complete training sessions, no signup, no app needed. Free workout generator from Zealova."
      intro="Pick the vibe that matches your mood right now. We hand you a complete workout matched to that energy. Every program is real training, the humor is just in the naming."
      faqs={[
        {
          q: 'Are these workouts actually programmed properly?',
          a: 'Yes. Every vibe maps to a real training stimulus. The hungover one is honest Zone 2 + mobility. The hotel one is a real bodyweight session. The bro split Sunday is real chest + triceps hypertrophy. Names are playful, exercise selection is not.',
        },
        {
          q: 'How do I pick a vibe?',
          a: 'Match it to your current mood, schedule, and equipment. Twenty minutes and stressed? 20 Min Or Less. Hungover and gym-adjacent? Hungover. Want to leave it all on the floor after a breakup? Post-Breakup Rage. Trust the vibe.',
        },
        {
          q: 'Can I run these in Zealova?',
          a: 'Yes. Tap "Open in Zealova" after picking a vibe and the app will load the same workout with a rest timer, form cues per exercise, and a tempo metronome for the tempo-based vibes.',
        },
        {
          q: 'Why do some vibes have RPE and others have straight reps?',
          a: 'Strength-focused vibes use RPE (Rate of Perceived Exertion) because load selection matters more than rep counts. Hypertrophy and circuit vibes use straight reps because consistency across sets matters more than chasing maximal load.',
        },
      ]}
    >
      {/* Vibe grid */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Pick your vibe</h2>
        <p className="text-sm text-zinc-400 mb-5">
          Tap one. Workout loads instantly below. Nothing sent anywhere.
        </p>
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
          {VIBES.map((v) => {
            const isActive = activeId === v.id;
            return (
              <button
                key={v.id}
                onClick={() => setActiveId(v.id)}
                className={`text-left p-4 rounded-2xl border transition ${
                  isActive
                    ? 'border-emerald-500 bg-emerald-500/10 ring-2 ring-emerald-500/30'
                    : 'border-zinc-800 bg-zinc-900 hover:border-zinc-700 hover:bg-zinc-800'
                }`}
              >
                <div className="text-2xl mb-2">{v.emoji}</div>
                <div className="text-sm font-semibold text-white leading-tight mb-1">{v.name}</div>
                <div className="text-xs text-zinc-500 leading-snug">{v.duration} min</div>
              </button>
            );
          })}
        </div>
      </section>

      {/* Active workout */}
      {active && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
          <div className="flex items-start justify-between gap-4 flex-wrap mb-2">
            <div>
              <div className="text-3xl mb-1">{active.emoji}</div>
              <h2 className="text-2xl font-bold text-white">{active.name}</h2>
              <p className="text-sm text-zinc-400 mt-1">{active.tagline}</p>
            </div>
            <div className="flex flex-col gap-2 items-end">
              <span className="text-xs px-3 py-1 rounded-full bg-zinc-800 text-zinc-300 font-medium">
                {active.duration} min
              </span>
              <div className="flex items-center gap-2">
                <span className="text-xs text-zinc-500">Intensity</span>
                <IntensityBar level={active.intensity} />
              </div>
            </div>
          </div>

          <div className="text-xs uppercase tracking-wide text-emerald-400 font-semibold mt-4 mb-3">
            Goal: {active.goal}
          </div>

          <ol className="space-y-3 mt-5">
            {active.blocks.map((b, i) => (
              <li key={i} className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
                <div className="flex items-baseline justify-between gap-3 flex-wrap">
                  <span className="text-base font-semibold text-white">
                    <span className="text-emerald-500 mr-2">{i + 1}.</span>
                    {b.name}
                  </span>
                  <span className="font-mono text-sm text-zinc-300">{b.prescription}</span>
                </div>
                {b.note && <p className="text-xs text-zinc-500 mt-2 leading-relaxed">{b.note}</p>}
              </li>
            ))}
          </ol>
        </section>
      )}

      {/* CTA */}
      {active && (
        <InstallCta
          slug="workout-vibe-generator"
          result={{ vibeId: active.id, name: active.name }}
          primary="Run this workout in Zealova with rest timer, form cues, and tempo metronome"
          secondary="Tap once and the same program loads in the app. Rest timer auto-starts after each set. Tempo lifts get a built-in metronome. Form cues show up on every exercise."
        />
      )}

      {!active && (
        <div className="rounded-2xl border border-dashed border-zinc-800 p-10 text-center text-sm text-zinc-500">
          Pick a vibe above to see the workout.
        </div>
      )}

      <MethodologyFooter
        citations={[
          { text: 'Schoenfeld BJ (2010). The mechanisms of muscle hypertrophy and their application to resistance training. JSCR 24(10).', url: 'https://pubmed.ncbi.nlm.nih.gov/20847704/' },
          { text: 'Seiler S (2010). What is best practice for training intensity and duration distribution in endurance athletes? IJSPP 5(3).', url: 'https://pubmed.ncbi.nlm.nih.gov/20861519/' },
          { text: 'Helms ER et al. (2016). Application of the Repetitions in Reserve-Based Rating of Perceived Exertion Scale for Resistance Training. Strength Cond J 38(4).', url: 'https://pubmed.ncbi.nlm.nih.gov/27531969/' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
