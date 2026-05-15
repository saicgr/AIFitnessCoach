// /tools/pace-calculator
//
// Pace / time / distance solver with Riegel race-time prediction across
// 5K, 10K, half marathon, marathon.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  RACE_PRESETS,
  distanceToKm,
  hmsToSeconds,
  kmToDistance,
  paceFromTime,
  paceToString,
  predictAllRaces,
  secondsToHms,
  speedFromTime,
  timeFromPaceDistance,
  type DistanceUnit,
} from '../../lib/calc/pace';
import { round } from '../../lib/calc/units';

type Mode = 'pace' | 'time' | 'distance' | 'race';

const MODE_OPTIONS: { value: Mode; label: string }[] = [
  { value: 'pace', label: 'Calculate pace' },
  { value: 'time', label: 'Calculate time' },
  { value: 'distance', label: 'Calculate distance' },
  { value: 'race', label: 'Race predictor' },
];

export default function PaceCalculator() {
  const [mode, setMode] = useState<Mode>('pace');
  const [distUnit, setDistUnit] = useState<DistanceUnit>('mi');

  // Distance + time (used in pace, time, distance modes)
  const [distance, setDistance] = useState<number | ''>(3.1);
  const [hours, setHours] = useState<number | ''>(0);
  const [minutes, setMinutes] = useState<number | ''>(25);
  const [seconds, setSeconds] = useState<number | ''>(0);

  // Pace input (used when computing time or distance from pace)
  const [paceMin, setPaceMin] = useState<number | ''>(8);
  const [paceSec, setPaceSec] = useState<number | ''>(0);

  // Race predictor: known time at a known race distance
  const [knownPresetIdx, setKnownPresetIdx] = useState<number>(1); // 5K default
  const [knownHours, setKnownHours] = useState<number | ''>(0);
  const [knownMinutes, setKnownMinutes] = useState<number | ''>(22);
  const [knownSeconds, setKnownSeconds] = useState<number | ''>(0);

  const totalSec = useMemo(() => {
    const h = typeof hours === 'number' ? hours : 0;
    const m = typeof minutes === 'number' ? minutes : 0;
    const s = typeof seconds === 'number' ? seconds : 0;
    return hmsToSeconds(h, m, s);
  }, [hours, minutes, seconds]);

  const paceSecPerUnit = useMemo(() => {
    const m = typeof paceMin === 'number' ? paceMin : 0;
    const s = typeof paceSec === 'number' ? paceSec : 0;
    return m * 60 + s;
  }, [paceMin, paceSec]);

  // Solo (non-race) mode result
  const soloRows: ResultRow[] = useMemo(() => {
    if (mode === 'pace') {
      if (typeof distance !== 'number' || distance <= 0 || totalSec <= 0) return [];
      const pace = paceFromTime(totalSec, distance);
      const speed = speedFromTime(totalSec, distance);
      return [
        {
          name: 'Pace',
          value: `${paceToString(pace)} / ${distUnit}`,
          note: 'Time per distance unit at this effort.',
          recommended: true,
        },
        {
          name: 'Speed',
          value: `${round(speed, 2)} ${distUnit}/hr`,
          note: 'Average speed across the run.',
        },
      ];
    }
    if (mode === 'time') {
      if (typeof distance !== 'number' || distance <= 0 || paceSecPerUnit <= 0) return [];
      const t = timeFromPaceDistance(paceSecPerUnit, distance);
      return [
        {
          name: 'Total time',
          value: secondsToHms(t),
          note: `At ${paceToString(paceSecPerUnit)} per ${distUnit}.`,
          recommended: true,
        },
      ];
    }
    if (mode === 'distance') {
      if (totalSec <= 0 || paceSecPerUnit <= 0) return [];
      const d = totalSec / paceSecPerUnit;
      return [
        {
          name: 'Distance',
          value: `${round(d, 2)} ${distUnit}`,
          note: `Covered in ${secondsToHms(totalSec)} at ${paceToString(paceSecPerUnit)} per ${distUnit}.`,
          recommended: true,
        },
      ];
    }
    return [];
  }, [mode, distance, totalSec, paceSecPerUnit, distUnit]);

  // Race predictor rows
  const raceRows: ResultRow[] = useMemo(() => {
    if (mode !== 'race') return [];
    const known = RACE_PRESETS[knownPresetIdx];
    const knownTime = hmsToSeconds(
      typeof knownHours === 'number' ? knownHours : 0,
      typeof knownMinutes === 'number' ? knownMinutes : 0,
      typeof knownSeconds === 'number' ? knownSeconds : 0,
    );
    if (knownTime <= 0) return [];
    const preds = predictAllRaces(knownTime, known.km);
    return preds.map((p) => ({
      name: p.label,
      value: secondsToHms(p.timeSec),
      note: `Pace: ${paceToString(distUnit === 'mi' ? p.paceSecPerMi : p.paceSecPerKm)} per ${distUnit}`,
      recommended: Math.abs(p.distKm - known.km) < 0.001,
    }));
  }, [mode, knownPresetIdx, knownHours, knownMinutes, knownSeconds, distUnit]);

  const installPayload = useMemo(() => {
    if (mode === 'race' && raceRows.length > 0) {
      return { mode, knownDistKm: RACE_PRESETS[knownPresetIdx].km };
    }
    return { mode, distance, distUnit, totalSec, paceSecPerUnit };
  }, [mode, knownPresetIdx, raceRows.length, distance, distUnit, totalSec, paceSecPerUnit]);

  // When user toggles unit while in pace/time/distance modes, convert distance.
  const onDistUnitChange = (next: DistanceUnit) => {
    if (typeof distance === 'number' && distance > 0 && next !== distUnit) {
      const km = distanceToKm(distance, distUnit);
      setDistance(round(kmToDistance(km, next), 2));
    }
    setDistUnit(next);
  };

  return (
    <CalculatorShell
      slug="pace-calculator"
      title="Pace Calculator"
      metaDescription="Free running pace calculator. Solve for pace, time, or distance. Predict 5K, 10K, half marathon, and marathon times using the Riegel formula."
      intro="Solve for pace, time, or distance. Or enter one race result and we project the other three using the Riegel formula."
      faqs={[
        {
          q: 'How accurate is the Riegel formula?',
          a: 'The Riegel exponent of 1.06 is calibrated for trained runners across distances from 1 mile to marathon. It tends to overpredict marathon times for runners who have not built marathon-specific endurance, and underpredict for ultra distances. For races within 2-3x of your known distance, expect predictions within 3-5%.',
        },
        {
          q: 'What is a good marathon pace?',
          a: 'It depends on your sex, age, and training history. As a rough field guide for healthy adult runners with at least a year of consistent training, 10:00/mi is a solid recreational marathon pace, 8:00/mi is competitive amateur, and sub-7:00/mi puts you in the local elite range. Boston qualifying times range from 7:00/mi to 9:00/mi depending on age group.',
        },
        {
          q: 'Should I convert km to miles in training?',
          a: 'Pick one and stick with it. Your perceived effort, your watch, and your route signage should all match. American runners default to miles, most of Europe and Asia uses km. Switching mid-cycle introduces small math errors in pace targets that compound across a training block.',
        },
      ]}
    >
      {/* Mode picker */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex flex-wrap justify-between items-center gap-3 mb-6">
          <h2 className="text-lg font-bold text-white">What are you solving for?</h2>
          <UnitToggle
            value={distUnit}
            options={[
              { value: 'mi', label: 'miles' },
              { value: 'km', label: 'km' },
            ]}
            onChange={onDistUnitChange}
          />
        </div>
        <div className="flex flex-wrap gap-2 mb-6">
          {MODE_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => setMode(opt.value)}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                mode === opt.value
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        {mode === 'pace' && (
          <div className="space-y-4">
            <NumberInput
              label="Distance"
              value={distance}
              onChange={setDistance}
              unit={distUnit}
              min={0}
              step={0.01}
              placeholder={distUnit === 'mi' ? '3.1' : '5'}
            />
            <div className="grid grid-cols-3 gap-3">
              <NumberInput label="Hours" value={hours} onChange={setHours} min={0} step={1} placeholder="0" />
              <NumberInput label="Minutes" value={minutes} onChange={setMinutes} min={0} max={59} step={1} placeholder="25" />
              <NumberInput label="Seconds" value={seconds} onChange={setSeconds} min={0} max={59} step={1} placeholder="0" />
            </div>
          </div>
        )}

        {mode === 'time' && (
          <div className="space-y-4">
            <NumberInput
              label="Distance"
              value={distance}
              onChange={setDistance}
              unit={distUnit}
              min={0}
              step={0.01}
              placeholder={distUnit === 'mi' ? '6.2' : '10'}
            />
            <div>
              <span className="block text-sm font-medium text-zinc-300 mb-1.5">
                Pace per {distUnit}
              </span>
              <div className="grid grid-cols-2 gap-3">
                <NumberInput label="Minutes" value={paceMin} onChange={setPaceMin} min={0} step={1} placeholder="8" />
                <NumberInput label="Seconds" value={paceSec} onChange={setPaceSec} min={0} max={59} step={1} placeholder="0" />
              </div>
            </div>
          </div>
        )}

        {mode === 'distance' && (
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-3">
              <NumberInput label="Hours" value={hours} onChange={setHours} min={0} step={1} placeholder="1" />
              <NumberInput label="Minutes" value={minutes} onChange={setMinutes} min={0} max={59} step={1} placeholder="30" />
              <NumberInput label="Seconds" value={seconds} onChange={setSeconds} min={0} max={59} step={1} placeholder="0" />
            </div>
            <div>
              <span className="block text-sm font-medium text-zinc-300 mb-1.5">
                Pace per {distUnit}
              </span>
              <div className="grid grid-cols-2 gap-3">
                <NumberInput label="Minutes" value={paceMin} onChange={setPaceMin} min={0} step={1} placeholder="8" />
                <NumberInput label="Seconds" value={paceSec} onChange={setPaceSec} min={0} max={59} step={1} placeholder="0" />
              </div>
            </div>
          </div>
        )}

        {mode === 'race' && (
          <div className="space-y-4">
            <div>
              <span className="block text-sm font-medium text-zinc-300 mb-1.5">Your known race</span>
              <div className="flex flex-wrap gap-2">
                {RACE_PRESETS.map((p, i) => (
                  <button
                    key={p.label}
                    type="button"
                    onClick={() => setKnownPresetIdx(i)}
                    className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                      knownPresetIdx === i
                        ? 'bg-emerald-500 text-zinc-900'
                        : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
                    }`}
                  >
                    {p.label}
                  </button>
                ))}
              </div>
            </div>
            <div>
              <span className="block text-sm font-medium text-zinc-300 mb-1.5">
                Your time in the {RACE_PRESETS[knownPresetIdx].label}
              </span>
              <div className="grid grid-cols-3 gap-3">
                <NumberInput label="Hours" value={knownHours} onChange={setKnownHours} min={0} step={1} placeholder="0" />
                <NumberInput label="Minutes" value={knownMinutes} onChange={setKnownMinutes} min={0} max={59} step={1} placeholder="22" />
                <NumberInput label="Seconds" value={knownSeconds} onChange={setKnownSeconds} min={0} max={59} step={1} placeholder="0" />
              </div>
            </div>
          </div>
        )}
      </section>

      {/* Results */}
      {mode !== 'race' && soloRows.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-4">Result</h2>
          <ResultsTable rows={soloRows} valueLabel="Value" />
        </section>
      )}

      {mode === 'race' && raceRows.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Projected race times</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Riegel formula: T2 = T1 × (D2 / D1)^1.06. Your known race is highlighted.
          </p>
          <ResultsTable rows={raceRows} valueLabel="Predicted time" />
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="pace-calculator"
        result={installPayload}
        primary="Track every run pace + projected race time in Zealova"
        secondary="Zealova logs every run, recomputes your Riegel projections after each PR, and adjusts your training paces automatically."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          {
            text: 'Riegel PS (1981). Athletic records and human endurance. American Scientist 69(3):285-290.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
