// /free-tools/aesthetic-body-type-matcher
//
// Aesthetic-first programming guide. Pick the look you want, get the training
// principles, sample split, nutrition framing, and a realistic timeline.
// All hardcoded from training literature. Zero API calls.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface SplitDay {
  day: string;
  focus: string;
}

interface Aesthetic {
  id: string;
  emoji: string;
  name: string;
  blurb: string;
  trainingPrinciples: string[];
  split: SplitDay[];
  nutrition: string[];
  timeline: string;
  zealovaPreset: string;
}

const AESTHETICS: Aesthetic[] = [
  {
    id: 'y2k-athleisure',
    emoji: '👟',
    name: 'Y2K Athleisure',
    blurb: 'Lean, athletic, defined shoulders. The look reads sport, not bodybuilder.',
    trainingPrinciples: [
      'Athletic conditioning paired with moderate strength. Three lifting days plus two conditioning days.',
      'Compound lifts in the 5 to 8 rep range. Heavy enough to look strong, light enough to recover for cardio.',
      'Targeted shoulder + glute volume. These two areas define the silhouette.',
    ],
    split: [
      { day: 'Mon', focus: 'Lower strength + glutes' },
      { day: 'Tue', focus: 'Conditioning (intervals or run)' },
      { day: 'Wed', focus: 'Upper push + shoulders' },
      { day: 'Thu', focus: 'Conditioning (Zone 2)' },
      { day: 'Fri', focus: 'Lower hypertrophy + posterior chain' },
      { day: 'Sat', focus: 'Upper pull + arms' },
      { day: 'Sun', focus: 'Rest or walk' },
    ],
    nutrition: [
      'Slight calorie deficit when leaning out, maintenance when building. Avoid bulking phases.',
      'Protein at 0.8 to 1.0 g per lb of body weight to preserve muscle on the conditioning days.',
      'Carbs around training, especially before the conditioning sessions.',
    ],
    timeline: '12 to 16 weeks for a visible transformation from average starting point.',
    zealovaPreset: 'Hybrid Athletic (3 lift / 2 cardio)',
  },
  {
    id: 'old-money-muscle',
    emoji: '🏛️',
    name: 'Old Money Muscle',
    blurb: 'Classical proportions. Capped shoulders, narrow waist, full chest. Greek statue energy.',
    trainingPrinciples: [
      'Classic bodybuilding split. Push, pull, legs, repeat. Five to six sessions per week.',
      'Rep range mostly 8 to 12 for hypertrophy. Compound lifts in 5 to 8 once per week per pattern.',
      'Symmetry matters more than max weight. Train weak points twice per week, strong points once.',
    ],
    split: [
      { day: 'Mon', focus: 'Push A (chest emphasis)' },
      { day: 'Tue', focus: 'Pull A (back width)' },
      { day: 'Wed', focus: 'Legs A (quads)' },
      { day: 'Thu', focus: 'Push B (shoulders emphasis)' },
      { day: 'Fri', focus: 'Pull B (back thickness)' },
      { day: 'Sat', focus: 'Legs B (posterior chain)' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Lean bulk at 200 to 300 calorie surplus during muscle-building blocks. Cut to 12 percent body fat between.',
      'Protein 1.0 g per lb body weight. Three to five meals per day.',
      'Carbs are not the enemy. They power the volume this look requires.',
    ],
    timeline: '18 to 36 months for a classic developed physique, faster if starting with a training base.',
    zealovaPreset: 'Classic Bodybuilding PPL',
  },
  {
    id: 'soft-girl-strength',
    emoji: '🌸',
    name: 'Soft Girl Strength',
    blurb: 'Toned, mobile, functional. Strong without looking bulky. Pilates meets the squat rack.',
    trainingPrinciples: [
      'Lower-body strength focus, especially glutes. Three strength days, two pilates or mobility days.',
      'Controlled tempo. Most lifts use 3-1-1 tempo or slower. Time under tension over max load.',
      'Mobility woven into every session. No skipping the warm-up.',
    ],
    split: [
      { day: 'Mon', focus: 'Glutes + hamstrings' },
      { day: 'Tue', focus: 'Pilates or yoga flow' },
      { day: 'Wed', focus: 'Upper body + core' },
      { day: 'Thu', focus: 'Mobility + Zone 2 walk' },
      { day: 'Fri', focus: 'Quads + glutes' },
      { day: 'Sat', focus: 'Full-body flow + light strength' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Maintenance calories most of the year. Brief 4 to 6 week cuts if needed.',
      'Protein 0.7 to 0.8 g per lb body weight. Higher than typical recommendations for women.',
      'Carbs unrestricted. Whole-food sources, fiber every meal.',
    ],
    timeline: '6 to 12 months for noticeable glute development and visible muscle definition.',
    zealovaPreset: 'Glute-Focused Strength + Mobility',
  },
  {
    id: 'powerlifter-brutalism',
    emoji: '🔨',
    name: 'Powerlifter Brutalism',
    blurb: 'Thick, dense, strong. Form follows function. Numbers on the bar are the aesthetic.',
    trainingPrinciples: [
      'Squat, bench, deadlift trained twice per week each. Most working sets in the 1 to 5 rep range.',
      'Accessory work serves the main lifts. Rows for bench. Good mornings for squat. Romanian deadlifts for deadlift.',
      'Recovery infrastructure matters. Sleep, calories, stress management. Programming alone will not do it.',
    ],
    split: [
      { day: 'Mon', focus: 'Squat (heavy) + accessories' },
      { day: 'Tue', focus: 'Bench (heavy) + back' },
      { day: 'Wed', focus: 'Rest or light cardio' },
      { day: 'Thu', focus: 'Deadlift (heavy) + posterior chain' },
      { day: 'Fri', focus: 'Bench (volume) + arms' },
      { day: 'Sat', focus: 'Squat (volume) + core' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Surplus during strength blocks. Plenty of carbs to fuel heavy work.',
      'Protein 1.0 g per lb body weight minimum.',
      'Body fat 15 to 20 percent for men is fine. Performance over leanness.',
    ],
    timeline: '24 to 60 months to compete at a respectable level. Strength is the slowest sport.',
    zealovaPreset: 'Powerlifting Periodized (4 day)',
  },
  {
    id: 'hybrid-athlete',
    emoji: '🏃',
    name: 'Hybrid Athlete',
    blurb: 'Runner meets lifter. Lean, strong, endurance. Can deadlift triple bodyweight and finish a half marathon.',
    trainingPrinciples: [
      'Three strength days, three to four cardio days. The cardio days are programmed, not just filler.',
      'Strength work focuses on compounds in the 3 to 6 rep range. Low volume, high intensity, fast recovery.',
      'Cardio includes Zone 2 (most of it), threshold work (once per week), and VO2 max intervals (once per week).',
    ],
    split: [
      { day: 'Mon', focus: 'Lower strength (heavy)' },
      { day: 'Tue', focus: 'Zone 2 run (45 to 60 min)' },
      { day: 'Wed', focus: 'Upper strength' },
      { day: 'Thu', focus: 'Threshold or interval run' },
      { day: 'Fri', focus: 'Full-body strength' },
      { day: 'Sat', focus: 'Long Zone 2 (60 to 90 min)' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Maintenance or slight surplus. Hybrid training burns more than people think.',
      'Carbs are non-negotiable. 3 to 5 g per kg body weight on training days.',
      'Protein 0.8 to 1.0 g per lb body weight to recover from both modalities.',
    ],
    timeline: '12 to 18 months to balance both. The first 6 months one side will lag.',
    zealovaPreset: 'Hybrid Athlete (3 lift / 3 run)',
  },
  {
    id: 'functional-fortress',
    emoji: '🧱',
    name: 'Functional Fortress',
    blurb: 'CrossFit-style mixed modality. Strong, conditioned, can do everything. Jack of all trades.',
    trainingPrinciples: [
      'Five days per week of mixed modal training. Olympic lifts, gymnastics, monostructural cardio, strength.',
      'Vary stimulus daily. No two consecutive days hit the same energy system.',
      'Skill work before conditioning. Master the movement before chasing the clock.',
    ],
    split: [
      { day: 'Mon', focus: 'Strength + short WOD' },
      { day: 'Tue', focus: 'Olympic lifting + long WOD' },
      { day: 'Wed', focus: 'Gymnastics skill + monostructural' },
      { day: 'Thu', focus: 'Rest or active recovery' },
      { day: 'Fri', focus: 'Heavy strength + couplet' },
      { day: 'Sat', focus: 'Long mixed WOD' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Maintenance to slight surplus. Output is high, intake should match.',
      'Protein 1.0 g per lb body weight.',
      'Carb intake scales with training volume. Add carbs on heavy days.',
    ],
    timeline: '12 to 24 months for general competence across the modalities.',
    zealovaPreset: 'Mixed Modal (5 day)',
  },
  {
    id: 'calisthenics-aesthetic',
    emoji: '🤸',
    name: 'Calisthenics Aesthetic',
    blurb: 'Relative strength. Gymnast-lean. Front lever, planche, muscle-up energy.',
    trainingPrinciples: [
      'Progressive skill work. Each session has a pull skill, a push skill, and a leg or core element.',
      'Frequency over volume. Four to six sessions per week, each shorter than a typical gym session.',
      'Stay light. Lower body fat helps relative strength. Carrying extra mass kills the skills.',
    ],
    split: [
      { day: 'Mon', focus: 'Pull skills (lever, pull-up variations)' },
      { day: 'Tue', focus: 'Push skills (handstand, planche)' },
      { day: 'Wed', focus: 'Legs + core' },
      { day: 'Thu', focus: 'Pull volume + endurance' },
      { day: 'Fri', focus: 'Push volume + endurance' },
      { day: 'Sat', focus: 'Skill practice + mobility' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Maintenance or slight deficit most of the year. Lean is the goal.',
      'Protein 0.8 g per lb body weight. Enough to recover, not so much it bloats.',
      'Whole foods. Calisthenics rewards consistent low-inflammation eating.',
    ],
    timeline: '18 to 36 months to a front lever and a clean muscle-up from a beginner base.',
    zealovaPreset: 'Calisthenics Progression',
  },
  {
    id: 'pump-cover-aesthetic',
    emoji: '🎯',
    name: 'Pump Cover Aesthetic',
    blurb: 'Capped delts. Sleeve-filling arms. Full chest. Bodybuilder isolation work.',
    trainingPrinciples: [
      'High volume isolation work. Cables, dumbbells, machines. Free-weight compounds play a supporting role.',
      'Five to six sessions per week. Each muscle hit twice. Volume is the main driver.',
      'Stretch and squeeze. Full range of motion under load. Reps to within 1 or 2 of failure.',
    ],
    split: [
      { day: 'Mon', focus: 'Chest + biceps' },
      { day: 'Tue', focus: 'Back + triceps' },
      { day: 'Wed', focus: 'Legs (quad emphasis)' },
      { day: 'Thu', focus: 'Shoulders + arms' },
      { day: 'Fri', focus: 'Back width + chest' },
      { day: 'Sat', focus: 'Legs (posterior chain)' },
      { day: 'Sun', focus: 'Rest' },
    ],
    nutrition: [
      'Lean bulk most of the year. 200 to 400 calorie surplus.',
      'Protein 1.0 to 1.2 g per lb body weight during growth phases.',
      'Pre and intra-workout carbs to fuel the volume.',
    ],
    timeline: '24 to 48 months for the classic capped delt and full chest look from an untrained base.',
    zealovaPreset: 'Bodybuilding Isolation (6 day)',
  },
];

export default function AestheticBodyTypeMatcher() {
  const [activeId, setActiveId] = useState<string | null>(null);
  const active = useMemo(() => AESTHETICS.find((a) => a.id === activeId), [activeId]);

  return (
    <CalculatorShell
      slug="aesthetic-body-type-matcher"
      title="Aesthetic Body Type Matcher"
      metaDescription="Pick the physique you want, get the training principles, sample split, nutrition framing, and realistic timeline. Free aesthetic-first programming guide from Zealova."
      intro="Pick the look you want, see how to actually train for it. Eight aesthetics, each with training principles, a sample weekly split, nutrition framing, and a realistic timeline."
      faqs={[
        {
          q: 'Why aesthetics instead of goals like "build muscle"?',
          a: 'Most people do not actually want generic muscle. They want a specific look. Hybrid athlete training is different from old-money bodybuilding which is different from soft-girl strength. Picking the aesthetic first lets you reverse-engineer the right training, not the average.',
        },
        {
          q: 'Are these timelines realistic?',
          a: 'Yes, with caveats. Timelines assume consistent training, decent nutrition, adequate sleep. Genetics shift the range but rarely break it. Steroid-using influencers shorten the timeline, which is why their results look unreachable.',
        },
        {
          q: 'Can I mix aesthetics?',
          a: 'Within reason. Hybrid Athlete + Soft Girl Strength is feasible. Powerlifter Brutalism + Calisthenics Aesthetic is contradictory because the body composition requirements conflict. Pick the dominant aesthetic, borrow accents.',
        },
        {
          q: 'How does Zealova map to these?',
          a: 'Each aesthetic above has a recommended Zealova program preset. The preset includes the split, the rep schemes, the progression model. Pick the aesthetic, the app builds the rest of the year of training.',
        },
      ]}
    >
      {/* Aesthetic gallery */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Pick your aesthetic</h2>
        <p className="text-sm text-zinc-400 mb-5">
          Honesty test: which one do you actually want? Pick that one, not the one you think you should pick.
        </p>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-3">
          {AESTHETICS.map((a) => {
            const isActive = activeId === a.id;
            return (
              <button
                key={a.id}
                onClick={() => setActiveId(a.id)}
                className={`text-left p-4 rounded-2xl border transition ${
                  isActive
                    ? 'border-emerald-500 bg-emerald-500/10 ring-2 ring-emerald-500/30'
                    : 'border-zinc-800 bg-zinc-900 hover:border-zinc-700 hover:bg-zinc-800'
                }`}
              >
                <div className="text-2xl mb-2">{a.emoji}</div>
                <div className="text-sm font-semibold text-white leading-tight mb-1">{a.name}</div>
                <div className="text-xs text-zinc-500 leading-snug line-clamp-2">{a.blurb}</div>
              </button>
            );
          })}
        </div>
      </section>

      {/* Active detail */}
      {active && (
        <section className="space-y-6">
          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
            <div className="text-3xl mb-1">{active.emoji}</div>
            <h2 className="text-2xl font-bold text-white">{active.name}</h2>
            <p className="text-sm text-zinc-400 mt-1 leading-relaxed">{active.blurb}</p>
          </div>

          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="text-xs uppercase tracking-wide text-emerald-400 font-semibold mb-3">
                Training principles
              </h3>
              <ol className="space-y-3">
                {active.trainingPrinciples.map((p, i) => (
                  <li key={i} className="text-sm text-zinc-300 leading-relaxed flex gap-3">
                    <span className="text-emerald-500 font-mono shrink-0">{i + 1}.</span>
                    <span>{p}</span>
                  </li>
                ))}
              </ol>
            </div>

            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
              <h3 className="text-xs uppercase tracking-wide text-emerald-400 font-semibold mb-3">
                Sample week
              </h3>
              <ul className="space-y-2">
                {active.split.map((d) => (
                  <li
                    key={d.day}
                    className="flex items-baseline gap-3 text-sm border-b border-zinc-800 pb-2 last:border-b-0 last:pb-0"
                  >
                    <span className="w-10 font-mono font-semibold text-white shrink-0">{d.day}</span>
                    <span className="text-zinc-300">{d.focus}</span>
                  </li>
                ))}
              </ul>
            </div>
          </div>

          <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6">
            <h3 className="text-xs uppercase tracking-wide text-emerald-400 font-semibold mb-3">
              Nutrition principles
            </h3>
            <ol className="space-y-3">
              {active.nutrition.map((n, i) => (
                <li key={i} className="text-sm text-zinc-300 leading-relaxed flex gap-3">
                  <span className="text-emerald-500 font-mono shrink-0">{i + 1}.</span>
                  <span>{n}</span>
                </li>
              ))}
            </ol>
          </div>

          <div className="grid md:grid-cols-2 gap-4">
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
              <p className="text-xs uppercase tracking-wide text-zinc-500 font-semibold mb-2">
                Realistic timeline
              </p>
              <p className="text-sm text-white leading-relaxed">{active.timeline}</p>
            </div>
            <div className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
              <p className="text-xs uppercase tracking-wide text-zinc-500 font-semibold mb-2">
                Zealova program preset
              </p>
              <p className="text-sm text-white font-semibold leading-relaxed">{active.zealovaPreset}</p>
            </div>
          </div>
        </section>
      )}

      {active && (
        <InstallCta
          slug="aesthetic-body-type-matcher"
          result={{ aestheticId: active.id, preset: active.zealovaPreset }}
          primary="Get a full plan matched to your aesthetic in Zealova"
          secondary={`Loads the ${active.zealovaPreset} preset into the app with exercise selection, weekly progression, and nutrition targets dialed for ${active.name}.`}
        />
      )}

      {!active && (
        <div className="rounded-2xl border border-dashed border-zinc-800 p-10 text-center text-sm text-zinc-500">
          Pick an aesthetic above to see the full programming guide.
        </div>
      )}

      <MethodologyFooter
        citations={[
          { text: 'Schoenfeld BJ, Grgic J, Krieger J (2019). How many times per week should a muscle be trained to maximize muscle hypertrophy? JSS 37(11).', url: 'https://pubmed.ncbi.nlm.nih.gov/30558493/' },
          { text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation. JISSN 11(20).', url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/' },
          { text: 'Coffey VG, Hawley JA (2017). Concurrent exercise training: do opposites distract? J Physiol 595(9).', url: 'https://pubmed.ncbi.nlm.nih.gov/27988971/' },
          { text: 'Aragon AA, Schoenfeld BJ (2020). Magnitude and composition of the energy surplus for maximizing muscle hypertrophy. Strength Cond J 42(5).', url: 'https://journals.lww.com/nsca-scj/Fulltext/2020/10000/Magnitude_and_Composition_of_the_Energy_Surplus.5.aspx' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
