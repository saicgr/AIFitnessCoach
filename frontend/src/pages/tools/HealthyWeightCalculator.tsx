// /tools/healthy-weight-calculator
//
// Returns a RANGE, not a point. Adjusts up for older adults (BMI 23 to 28 is
// associated with lower mortality past 65) and ±5% for frame size. The single
// most defensible "weight goal" tool on the site.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  healthyWeightRange,
  rangePosition,
  type Frame,
  type Sex,
} from '../../lib/calc/healthyWeight';
import type { WeightUnit, HeightUnit } from '../../lib/calc/units';
import { ftInToCm, kgToLb, lbToKg, round } from '../../lib/calc/units';

export default function HealthyWeightCalculator() {
  const [sex, setSex] = useState<Sex>('male');
  const [age, setAge] = useState<number | ''>(35);
  const [frame, setFrame] = useState<Frame>('medium');
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [weightUnit, setWeightUnit] = useState<WeightUnit>('lb');
  const [heightCm, setHeightCm] = useState<number | ''>(178);
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);
  const [currentWeight, setCurrentWeight] = useState<number | ''>(180);

  const heightInCm = useMemo(() => {
    if (heightUnit === 'cm') return typeof heightCm === 'number' ? heightCm : 0;
    const f = typeof feet === 'number' ? feet : 0;
    const i = typeof inches === 'number' ? inches : 0;
    return ftInToCm(f, i);
  }, [heightUnit, heightCm, feet, inches]);

  const range = useMemo(() => {
    if (heightInCm <= 0 || typeof age !== 'number') return null;
    return healthyWeightRange({ heightCm: heightInCm, age, sex, frame });
  }, [heightInCm, age, sex, frame]);

  const currentKg = useMemo(() => {
    if (typeof currentWeight !== 'number') return 0;
    return weightUnit === 'lb' ? lbToKg(currentWeight) : currentWeight;
  }, [currentWeight, weightUnit]);

  const position = range && currentKg > 0 ? rangePosition(currentKg, range) : null;

  const formatKg = (kg: number) =>
    weightUnit === 'lb' ? `${round(kgToLb(kg), 0)} lb` : `${round(kg, 1)} kg`;

  return (
    <CalculatorShell
      slug="healthy-weight-calculator"
      title="Healthy Weight Range"
      metaDescription="Find your healthy weight range based on BMI, age, and frame size. Returns a range, not a single number. Age-adjusted for adults 65 and older."
      intro="Healthy weight is a range, not a single number. Enter your height, age, sex, and frame size to see your range, with adjustments for older adults built in."
      faqs={[
        {
          q: 'Why is healthy weight a range, not a number?',
          a: 'Two people at the same height can carry very different amounts of muscle, bone, and organ tissue. The healthy BMI band (18.5 to 24.9) reflects this spread. A specific number inside that range is a personal choice based on your goals and how you feel.',
        },
        {
          q: 'Does this apply to older adults?',
          a: 'Yes, and the range shifts. Large meta-analyses (Winter et al. 2014, Janssen et al. 2007) consistently find that adults 65 and older have the lowest all-cause mortality between BMI 23 and 28. This calculator automatically widens the range when you enter age 65 or higher.',
        },
        {
          q: 'How do I know my frame size?',
          a: 'A common rule uses wrist circumference. For a man under 5\'5", small is under 5.5", medium 5.5 to 6.5", large above 6.5". For taller men and for women, the cutoffs shift. Or simply ask a doctor or trainer. The frame adjustment here is ±5 percent, so getting it slightly wrong does not move the range much.',
        },
        {
          q: 'I lift weights. Should I trust this range?',
          a: 'Probably not as a hard ceiling. Trained athletes often sit several kilograms above BMI 24.9 with healthy body fat. Use body fat percent or waist-to-height ratio as your primary target, and treat this range as a sanity check.',
        },
      ]}
    >
      {/* Inputs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <div className="flex justify-between items-center mb-6 flex-wrap gap-3">
          <h2 className="text-lg font-bold text-white">Your inputs</h2>
          <div className="flex gap-2 flex-wrap">
            <UnitToggle
              value={sex}
              options={[
                { value: 'male', label: 'Male' },
                { value: 'female', label: 'Female' },
              ]}
              onChange={setSex}
            />
            <UnitToggle
              value={heightUnit}
              options={[
                { value: 'ft', label: 'ft / in' },
                { value: 'cm', label: 'cm' },
              ]}
              onChange={setHeightUnit}
            />
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

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {heightUnit === 'cm' ? (
            <NumberInput
              label="Height"
              value={heightCm}
              onChange={setHeightCm}
              unit="cm"
              min={50}
              max={250}
              step={0.5}
              placeholder="178"
            />
          ) : (
            <div className="grid grid-cols-2 gap-3">
              <NumberInput
                label="Height (feet)"
                value={feet}
                onChange={setFeet}
                unit="ft"
                min={3}
                max={8}
                step={1}
                placeholder="5"
              />
              <NumberInput
                label="Inches"
                value={inches}
                onChange={setInches}
                unit="in"
                min={0}
                max={11}
                step={0.5}
                placeholder="10"
              />
            </div>
          )}
          <NumberInput
            label="Age"
            value={age}
            onChange={setAge}
            unit="years"
            min={18}
            max={110}
            step={1}
            placeholder="35"
            help="Range shifts up at age 65 and older."
          />
          <NumberInput
            label="Current weight (optional)"
            value={currentWeight}
            onChange={setCurrentWeight}
            unit={weightUnit}
            min={0}
            step={0.5}
            placeholder={weightUnit === 'lb' ? '180' : '82'}
          />
        </div>

        {/* Frame size */}
        <div className="mt-5">
          <p className="text-sm font-medium text-zinc-300 mb-2">Frame size</p>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-900 p-0.5">
            {(['small', 'medium', 'large'] as Frame[]).map((f) => (
              <button
                key={f}
                type="button"
                onClick={() => setFrame(f)}
                className={`px-3 py-1.5 text-xs font-medium rounded-md transition capitalize ${
                  frame === f ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'
                }`}
              >
                {f}
              </button>
            ))}
          </div>
          <p className="text-xs text-zinc-500 mt-1.5">
            Small trims the range by 5 percent, large adds 5 percent.
          </p>
        </div>
      </section>

      {/* Range result */}
      {range && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
          <p className="text-sm text-zinc-400 mb-1">Your healthy weight range</p>
          <p className="text-4xl font-bold text-white tabular-nums">
            {formatKg(range.lowKg)} to {formatKg(range.highKg)}
          </p>
          <p className="text-sm text-zinc-400 mt-2">
            Corresponds to BMI {range.bmiLow} to {range.bmiHigh}
            {range.ageAdjusted ? ' (age-adjusted)' : ''}.
          </p>

          {position && (
            <div className="mt-5 pt-5 border-t border-zinc-800">
              {position === 'in-range' && (
                <p className="text-emerald-400 font-semibold">
                  You are inside your healthy range.
                </p>
              )}
              {position === 'below' && (
                <p className="text-sky-400 font-semibold">
                  You are below your healthy range by {formatKg(range.lowKg - currentKg)}.
                </p>
              )}
              {position === 'above' && (
                <p className="text-amber-400 font-semibold">
                  You are above your healthy range by {formatKg(currentKg - range.highKg)}.
                </p>
              )}
            </div>
          )}

          {range.notes.length > 0 && (
            <ul className="mt-5 space-y-2 text-sm text-zinc-400 leading-relaxed">
              {range.notes.map((n, i) => (
                <li key={i} className="flex gap-2">
                  <span className="text-emerald-500 mt-0.5">•</span>
                  <span>{n}</span>
                </li>
              ))}
            </ul>
          )}
        </section>
      )}

      <InstallCta
        slug="healthy-weight-calculator"
        result={{
          heightCm: heightInCm,
          age,
          sex,
          frame,
          rangeLowKg: range?.lowKg,
          rangeHighKg: range?.highKg,
        }}
        primary="Track your weight trend against your healthy range in Zealova"
        secondary="Daily weigh-ins, a smoothed trend line, and progress against the range you just calculated, all in one place."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'WHO (2000). Obesity: Preventing and Managing the Global Epidemic. WHO Technical Report Series 894.',
            url: 'https://www.who.int/publications/i/item/WHO-TRS-894',
          },
          {
            text: 'Winter JE, MacInnis RJ, Wattanapenpaiboon N, Nowson CA (2014). BMI and all-cause mortality in older adults: a meta-analysis. Am J Clin Nutr 99(4).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24452240/',
          },
          {
            text: 'Janssen I, Mark AE (2007). Elevated body mass index and mortality risk in the elderly. Obes Rev 8(1).',
            url: 'https://pubmed.ncbi.nlm.nih.gov/17212795/',
          },
          {
            text: 'Metropolitan Life Insurance Co (1983). Height and weight tables.',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
