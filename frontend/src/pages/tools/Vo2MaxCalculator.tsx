// /tools/vo2-max-calculator
//
// VO2 max estimator. Picks one of 5 field-test protocols, shows only the inputs
// relevant to that protocol, and returns mL/kg/min plus ACSM age/sex
// classification.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  bruceTreadmill,
  buildResult,
  cooper12Run,
  mileAndHalfRun,
  queensCollegeStep,
  type Vo2Method,
  type Vo2Result,
} from '../../lib/calc/vo2Max';
import type { Sex, WeightUnit } from '../../lib/calc/units';
import { lbToKg } from '../../lib/calc/units';

type DistUnit = 'm' | 'mi';

const METHOD_OPTIONS: { value: Vo2Method; label: string }[] = [
  { value: 'cooper12run', label: 'Cooper 12-min' },
  { value: 'milesAndHalf', label: '1.5-mile run' },
  { value: 'cooper12alt', label: '12-min run (alt)' },
  { value: 'bruce', label: 'Bruce treadmill' },
  { value: 'queens', label: 'Queens step' },
];

export default function Vo2MaxCalculator() {
  const [method, setMethod] = useState<Vo2Method>('cooper12run');
  const [age, setAge] = useState<number | ''>(30);
  const [sex, setSex] = useState<Sex>('male');

  // Cooper / 12-min alt inputs
  const [cooperDist, setCooperDist] = useState<number | ''>(2400);
  const [cooperUnit, setCooperUnit] = useState<DistUnit>('m');

  // 1.5-mile run inputs
  const [mileMin, setMileMin] = useState<number | ''>(12);
  const [mileSec, setMileSec] = useState<number | ''>(30);
  const [bodyWeight, setBodyWeight] = useState<number | ''>(170);
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');

  // Bruce inputs
  const [bruceMin, setBruceMin] = useState<number | ''>(12);
  const [bruceSec, setBruceSec] = useState<number | ''>(0);

  // Queens step inputs
  const [recoveryHr, setRecoveryHr] = useState<number | ''>(140);

  const result: Vo2Result | null = useMemo(() => {
    if (typeof age !== 'number' || age <= 0) return null;

    if (method === 'cooper12run' || method === 'cooper12alt') {
      if (typeof cooperDist !== 'number') return null;
      const meters = cooperUnit === 'mi' ? cooperDist * 1609.34 : cooperDist;
      const vo2 = cooper12Run(meters);
      return buildResult(method, vo2, age, sex);
    }

    if (method === 'milesAndHalf') {
      if (
        typeof mileMin !== 'number' ||
        typeof mileSec !== 'number' ||
        typeof bodyWeight !== 'number'
      ) {
        return null;
      }
      const totalMin = mileMin + mileSec / 60;
      const wKg = weightUnit === 'lb' ? lbToKg(bodyWeight) : bodyWeight;
      const vo2 = mileAndHalfRun(totalMin, wKg, sex);
      return buildResult(method, vo2, age, sex);
    }

    if (method === 'bruce') {
      if (typeof bruceMin !== 'number' || typeof bruceSec !== 'number') return null;
      const totalMin = bruceMin + bruceSec / 60;
      const vo2 = bruceTreadmill(totalMin, sex);
      return buildResult(method, vo2, age, sex);
    }

    if (method === 'queens') {
      if (typeof recoveryHr !== 'number') return null;
      const vo2 = queensCollegeStep(recoveryHr, sex);
      return buildResult(method, vo2, age, sex);
    }

    return null;
  }, [
    method,
    age,
    sex,
    cooperDist,
    cooperUnit,
    mileMin,
    mileSec,
    bodyWeight,
    weightUnit,
    bruceMin,
    bruceSec,
    recoveryHr,
  ]);

  const tableRows: ResultRow[] = result
    ? [
        {
          name: result.name,
          value: `${result.vo2max} mL/kg/min`,
          note: result.classification,
          citation: result.citation,
          recommended: true,
        },
      ]
    : [];

  return (
    <CalculatorShell
      slug="vo2-max-calculator"
      title="VO2 Max Calculator"
      metaDescription="Estimate VO2 max with 5 validated field tests (Cooper, 1.5-mile run, 12-min run, Bruce treadmill, Queens College step). Free VO2 max calculator with ACSM age and sex classification."
      intro="Pick the test you ran. We compute your VO2 max in mL/kg/min and tell you where you land on the ACSM normative bands for your age and sex."
      faqs={[
        {
          q: 'Which test is most accurate?',
          a: 'For trained runners, the Bruce treadmill protocol is closest to lab-measured VO2 max because it goes to true exhaustion. The 1.5-mile run is the second most accurate field test and only takes 10-15 minutes. The Queens College step test is the easiest to administer but has the widest error margin.',
        },
        {
          q: 'How does Garmin estimate this?',
          a: 'Garmin and other wrist wearables use a Firstbeat algorithm that combines heart rate response, GPS pace, and HR variability during runs. It is a moving estimate updated across multiple sessions, not a single field test. Treat it as a relative trend indicator, not a clinical VO2 max.',
        },
        {
          q: 'Is VO2 max trainable?',
          a: 'Yes. Most adults can lift VO2 max by 15-25% with structured aerobic training over 6-12 months. Untrained individuals see the biggest gains. Past age 30, the rate of gain slows but the ceiling stays trainable into your 60s and 70s.',
        },
      ]}
    >
      {/* Method picker */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">Test protocol</h2>
        <div className="flex flex-wrap gap-2 mb-6">
          {METHOD_OPTIONS.map((opt) => (
            <button
              key={opt.value}
              type="button"
              onClick={() => setMethod(opt.value)}
              className={`px-3 py-2 rounded-lg text-sm font-medium transition ${
                method === opt.value
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'bg-zinc-800 text-zinc-300 hover:bg-zinc-700'
              }`}
            >
              {opt.label}
            </button>
          ))}
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          <NumberInput
            label="Age"
            value={age}
            onChange={setAge}
            min={10}
            max={100}
            step={1}
            placeholder="30"
          />
          <div>
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Sex</span>
            <UnitToggle
              value={sex}
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
              onChange={setSex}
            />
          </div>
        </div>

        <div className="mt-6 pt-6 border-t border-zinc-800">
          {(method === 'cooper12run' || method === 'cooper12alt') && (
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <NumberInput
                label="Distance covered in 12 minutes"
                value={cooperDist}
                onChange={setCooperDist}
                unit={cooperUnit}
                min={0}
                step={cooperUnit === 'mi' ? 0.01 : 10}
                placeholder={cooperUnit === 'mi' ? '1.5' : '2400'}
              />
              <div>
                <span className="block text-sm font-medium text-zinc-300 mb-1.5">Distance unit</span>
                <UnitToggle
                  value={cooperUnit}
                  options={[
                    { value: 'm', label: 'meters' },
                    { value: 'mi', label: 'miles' },
                  ]}
                  onChange={setCooperUnit}
                />
              </div>
            </div>
          )}

          {method === 'milesAndHalf' && (
            <div className="space-y-4">
              <div className="grid grid-cols-2 gap-4">
                <NumberInput
                  label="Minutes"
                  value={mileMin}
                  onChange={setMileMin}
                  min={0}
                  step={1}
                  placeholder="12"
                />
                <NumberInput
                  label="Seconds"
                  value={mileSec}
                  onChange={setMileSec}
                  min={0}
                  max={59}
                  step={1}
                  placeholder="30"
                />
              </div>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <NumberInput
                  label="Body weight"
                  value={bodyWeight}
                  onChange={setBodyWeight}
                  unit={weightUnit}
                  min={20}
                  step={1}
                  placeholder="170"
                />
                <div>
                  <span className="block text-sm font-medium text-zinc-300 mb-1.5">Weight unit</span>
                  <UnitToggle
                    value={weightUnit}
                    options={[
                      { value: 'lb', label: 'lb' },
                      { value: 'kg', label: 'kg' },
                    ]}
                    onChange={setWeightUnit}
                  />
                </div>
              </div>
            </div>
          )}

          {method === 'bruce' && (
            <div className="grid grid-cols-2 gap-4">
              <NumberInput
                label="Minutes to exhaustion"
                value={bruceMin}
                onChange={setBruceMin}
                min={0}
                step={1}
                placeholder="12"
              />
              <NumberInput
                label="Seconds"
                value={bruceSec}
                onChange={setBruceSec}
                min={0}
                max={59}
                step={1}
                placeholder="0"
              />
            </div>
          )}

          {method === 'queens' && (
            <NumberInput
              label="Recovery heart rate (5-20s post-test)"
              value={recoveryHr}
              onChange={setRecoveryHr}
              unit="bpm"
              min={40}
              max={220}
              step={1}
              placeholder="140"
              help={`Step rate is ${sex === 'male' ? '24' : '22'} steps per minute on a 16.25-inch step for 3 minutes.`}
            />
          )}
        </div>
      </section>

      {/* Result */}
      {result && result.vo2max > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">Estimated VO2 max</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Your classification on the ACSM normative bands for your age and sex.
          </p>
          <ResultsTable rows={tableRows} valueLabel="VO2 max" />
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="vo2-max-calculator"
        result={result ? { method: result.method, vo2max: result.vo2max, age, sex } : undefined}
        primary="Track VO2 max changes over time in Zealova"
        secondary="Log every cardio session and watch your VO2 max trend month over month."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          { text: 'Cooper KH (1968). A means of assessing maximal oxygen intake. JAMA 203(3):201-204.' },
          { text: 'ACSM (2017). ACSM’s Guidelines for Exercise Testing and Prescription, 10th edition.' },
          { text: 'Bruce RA, Kusumi F, Hosmer D (1973). Maximal oxygen intake and nomographic assessment of functional aerobic impairment in cardiovascular disease. American Heart Journal 85(4):546-562.' },
          { text: 'McArdle WD, Katch FI, Pechar GS, Jacobson L, Ruck S (1972). Reliability and interrelationships between maximal oxygen intake, physical work capacity and step-test scores in college women. Medicine and Science in Sports 4(4):182-186.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
