// /tools/deload-week-calculator
//
// Asks for fatigue signals and returns a yes/no deload recommendation plus the
// suggested deload format.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { recommendDeload } from '../../lib/calc/deload';

export default function DeloadWeekCalculator() {
  const [weeksSinceDeload, setWeeksSinceDeload] = useState<number | ''>(5);
  const [rpe, setRpe] = useState<number | ''>(8.5);
  const [sleep, setSleep] = useState<number | ''>(7);
  const [motivation, setMotivation] = useState<number | ''>(6);
  const [joints, setJoints] = useState<number | ''>(0);

  const rec = useMemo(() => {
    if (
      typeof weeksSinceDeload !== 'number' ||
      typeof rpe !== 'number' ||
      typeof sleep !== 'number' ||
      typeof motivation !== 'number' ||
      typeof joints !== 'number'
    ) {
      return null;
    }
    return recommendDeload({
      weeksSinceDeload,
      averageRpeLast2Weeks: rpe,
      sleepQuality: sleep,
      motivation,
      jointsHurting: joints,
    });
  }, [weeksSinceDeload, rpe, sleep, motivation, joints]);

  const urgencyColor: Record<string, string> = {
    none: 'text-zinc-400 bg-zinc-800',
    low: 'text-amber-300 bg-amber-500/10 border border-amber-500/30',
    medium: 'text-orange-300 bg-orange-500/10 border border-orange-500/30',
    high: 'text-red-300 bg-red-500/10 border border-red-500/30',
  };

  return (
    <CalculatorShell
      slug="deload-week-calculator"
      title="Deload Week Calculator"
      metaDescription="Decide whether to deload based on weeks since your last deload, recent RPE, sleep, motivation, and joint pain. Free, evidence-based recommendation."
      intro="Honest answers in, clear recommendation out. We score five fatigue signals and tell you whether to deload, how urgently, and which deload format fits your situation."
      faqs={[
        {
          q: 'How often should I deload?',
          a: 'Most lifters benefit from a deload every 4-6 weeks of hard training. Advanced lifters running high volumes might need one every 3-4 weeks. Beginners with low absolute loads can often go 8+ weeks before requiring one. The calculator weights recency alongside other fatigue signals.',
        },
        {
          q: 'What does a deload look like?',
          a: 'Three formats work. Volume deload cuts sets in half at normal weight. Intensity deload keeps the sets and drops weight to around 70%. Active recovery does both. Joint pain or near-max RPE pushes you toward intensity or active recovery. Plain accumulated volume responds to a volume cut.',
        },
        {
          q: 'Will I lose strength during a deload?',
          a: 'No. A week at reduced load preserves neural patterns and detrains almost nothing. Most lifters come back stronger than the week before the deload. Detraining only becomes a factor after 2-3+ weeks of true rest.',
        },
        {
          q: 'Can I deload one muscle at a time?',
          a: 'Yes, this is common. If only your low back is barking but your upper body feels fine, deload squats and deadlifts while training bench and pulls normally. Whole-body deloads are simpler but selective deloads can keep more momentum.',
        },
        {
          q: 'What if my RPE is high but I feel fine?',
          a: 'Sustained RPE 9+ over multiple weeks is a leading indicator of overreaching even when subjective fatigue feels manageable. The calculator still flags it because waiting for systemic burnout usually means you waited too long.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">Your last 2 weeks</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Weeks since last deload"
            value={weeksSinceDeload}
            onChange={setWeeksSinceDeload}
            min={0}
            max={20}
            step={1}
          />
          <NumberInput
            label="Average RPE (last 2 weeks)"
            value={rpe}
            onChange={setRpe}
            min={1}
            max={10}
            step={0.5}
            help="0 = nothing, 10 = absolute max"
          />
          <NumberInput
            label="Sleep quality"
            value={sleep}
            onChange={setSleep}
            min={1}
            max={10}
            step={1}
            help="1 = wrecked, 10 = perfect"
          />
          <NumberInput
            label="Motivation"
            value={motivation}
            onChange={setMotivation}
            min={1}
            max={10}
            step={1}
            help="1 = dreading sessions, 10 = excited"
          />
          <NumberInput
            label="Joints with persistent pain"
            value={joints}
            onChange={setJoints}
            min={0}
            max={10}
            step={1}
            help="Count joints, not muscles"
          />
        </div>
      </section>

      {rec && (
        <section className="space-y-5">
          <div
            className={`rounded-2xl border p-6 ${
              rec.shouldDeload
                ? 'border-emerald-500/40 bg-emerald-500/5'
                : 'border-zinc-800 bg-zinc-900'
            }`}
          >
            <div className="flex items-center justify-between flex-wrap gap-3 mb-3">
              <p className={`text-2xl font-bold ${rec.shouldDeload ? 'text-emerald-400' : 'text-white'}`}>
                {rec.shouldDeload ? 'Deload this week' : 'Keep accumulating'}
              </p>
              <span className={`text-xs font-semibold uppercase tracking-wide px-3 py-1 rounded-full ${urgencyColor[rec.urgency]}`}>
                {rec.urgency === 'none' ? 'No flags' : `${rec.urgency} urgency`}
              </span>
            </div>
            <ul className="space-y-1.5 text-sm text-zinc-300">
              {rec.reasons.map((r, i) => (
                <li key={i} className="leading-relaxed">
                  <span className="text-emerald-500 mr-2">•</span>
                  {r}
                </li>
              ))}
            </ul>
          </div>

          {rec.shouldDeload && (
            <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-6">
              <p className="text-xs uppercase tracking-wide text-zinc-500 mb-2">Recommended format</p>
              <p className="text-lg font-bold text-white mb-1 capitalize">
                {rec.format.replace('-', ' ')} deload
              </p>
              <p className="text-sm text-zinc-400 leading-relaxed">{rec.formatDescription}</p>
            </div>
          )}
        </section>
      )}

      <InstallCta
        slug="deload-week-calculator"
        result={{ weeksSinceDeload, rpe, sleep, motivation, joints, shouldDeload: rec?.shouldDeload }}
        primary="Get auto-deload recommendations based on your actual training data"
        secondary="Zealova tracks RPE, sleep, and load week over week, then schedules deloads when the same signals trip without you having to think about it."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'Helms ER, Cronin J, Storey A, Zourdos MC (2014). Application of the Repetitions-in-Reserve-Based RPE scale for resistance training. Strength Cond J 38(4): 42-49.',
            url: 'https://journals.lww.com/nsca-scj/Fulltext/2016/08000/Application_of_the_Repetitions_in_Reserve_Based.4.aspx',
          },
          {
            text: 'Smith I et al. Training load monitoring: subjective wellness scores as early indicators of overreaching.',
          },
          {
            text: 'Israetel M, Hoffmann J, Smith CW (2017). Scientific Principles of Hypertrophy Training. Renaissance Periodization.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
