// /tools/body-fat-calculator

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import NumberInput from '../../components/tools/NumberInput';
import UnitToggle from '../../components/tools/UnitToggle';
import ResultsTable, { type ResultRow } from '../../components/tools/ResultsTable';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import {
  calculateAllBodyFat,
  recommendedBodyFatMethod,
  bodyFatCategory,
} from '../../lib/calc/bodyFat';
import {
  inToCm,
  ftInToCm,
  type Sex,
  type LengthUnit,
  type HeightUnit,
} from '../../lib/calc/units';

type MethodTab = 'tape' | 'skinfold3' | 'skinfold7';

export default function BodyFatCalculator() {
  const [methodTab, setMethodTab] = useState<MethodTab>('tape');
  const [sex, setSex] = useState<Sex>('male');
  const [age, setAge] = useState<number | ''>(30);

  // Height
  const [heightUnit, setHeightUnit] = useState<HeightUnit>('ft');
  const [feet, setFeet] = useState<number | ''>(5);
  const [inches, setInches] = useState<number | ''>(10);
  const [heightCm, setHeightCm] = useState<number | ''>(178);

  // Circumferences
  const [tapeUnit, setTapeUnit] = useState<LengthUnit>('in');
  const [neck, setNeck] = useState<number | ''>(15);
  const [waist, setWaist] = useState<number | ''>(34);
  const [hip, setHip] = useState<number | ''>(38);

  // Skinfolds (mm)
  const [chest, setChest] = useState<number | ''>(10);
  const [abdomen, setAbdomen] = useState<number | ''>(20);
  const [thigh, setThigh] = useState<number | ''>(15);
  const [triceps, setTriceps] = useState<number | ''>(12);
  const [suprailiac, setSuprailiac] = useState<number | ''>(15);
  const [midaxillary, setMidaxillary] = useState<number | ''>(10);
  const [subscapular, setSubscapular] = useState<number | ''>(12);

  const cmH = useMemo(() => {
    if (heightUnit === 'ft') {
      if (typeof feet !== 'number' || typeof inches !== 'number') return undefined;
      return ftInToCm(feet, inches);
    }
    return typeof heightCm === 'number' ? heightCm : undefined;
  }, [heightUnit, feet, inches, heightCm]);

  const cmCirc = (val: number | '') => {
    if (typeof val !== 'number') return undefined;
    return tapeUnit === 'in' ? inToCm(val) : val;
  };

  const { results, recommended, headline } = useMemo(() => {
    if (typeof age !== 'number') {
      return { results: [], recommended: null, headline: 0 };
    }
    const inputs = {
      sex,
      age,
      heightCm: cmH,
      neckCm: cmCirc(neck),
      waistCm: cmCirc(waist),
      hipCm: sex === 'female' ? cmCirc(hip) : undefined,
      chest: methodTab !== 'tape' ? (typeof chest === 'number' ? chest : undefined) : undefined,
      abdomen: methodTab !== 'tape' ? (typeof abdomen === 'number' ? abdomen : undefined) : undefined,
      thigh: methodTab !== 'tape' ? (typeof thigh === 'number' ? thigh : undefined) : undefined,
      triceps: methodTab !== 'tape' ? (typeof triceps === 'number' ? triceps : undefined) : undefined,
      suprailiac: methodTab !== 'tape' ? (typeof suprailiac === 'number' ? suprailiac : undefined) : undefined,
      midaxillary: methodTab === 'skinfold7' ? (typeof midaxillary === 'number' ? midaxillary : undefined) : undefined,
      subscapular: methodTab === 'skinfold7' ? (typeof subscapular === 'number' ? subscapular : undefined) : undefined,
    };
    const res = calculateAllBodyFat(inputs);
    const rec = recommendedBodyFatMethod(inputs);
    const recVal = res.find((r) => r.method === rec)?.value ?? 0;
    return { results: res, recommended: rec, headline: recVal };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [
    sex, age, cmH, neck, waist, hip, tapeUnit,
    methodTab, chest, abdomen, thigh, triceps, suprailiac, midaxillary, subscapular,
  ]);

  const tableRows: ResultRow[] = results.map((r) => ({
    name: r.name,
    value: r.available ? `${r.value}%` : 'Needs more inputs',
    note: r.bestFor,
    recommended: r.method === recommended && r.available,
    citation: r.citation,
  }));

  return (
    <CalculatorShell
      slug="body-fat-calculator"
      title="Body Fat % Calculator"
      metaDescription="Estimate body fat percentage with 5 methods: US Navy, Jackson-Pollock 3 and 7-site skinfold, Covert Bailey, and RFM. Free, side-by-side comparison."
      intro="Pick the method that matches the tools you have. Tape measure only? Use Navy or RFM. Skinfold calipers? Use Jackson-Pollock for the most accurate field estimate. We compute every method that has enough data."
      faqs={[
        {
          q: 'Which method is most accurate?',
          a: 'For field methods, Jackson-Pollock 7-site skinfold is the most accurate, with a standard error around 3 percent. The 3-site shortcut is nearly as good at around 3 to 4 percent. Navy circumference is around 3 to 4 percent for trained users but loses accuracy at the extremes. RFM is the newest and correlates well with DEXA for general populations.',
        },
        {
          q: 'Do I need calipers?',
          a: 'For Navy and RFM, no. A flexible tape measure is enough. For Jackson-Pollock methods, yes, you need skinfold calipers and ideally another person to take the measurement. Calipers cost around 10 to 30 dollars on Amazon.',
        },
        {
          q: 'How often should I measure?',
          a: 'Every 2 to 4 weeks. Body fat changes slowly. Daily or weekly measurements are dominated by measurement noise and hydration shifts, not real change. Take 3 readings per site and average them.',
        },
        {
          q: 'Why do the methods disagree by 3 to 6 percent?',
          a: 'Each was fit on a different study population and a different gold standard reference (hydrostatic weighing or DEXA). The disagreement is your real measurement uncertainty. Track trends from one method, not absolute values across methods.',
        },
        {
          q: 'How does this compare to DEXA?',
          a: 'DEXA is around 1 to 2 percent accurate, the clinical gold standard, but costs 50 to 150 dollars per scan. Skinfold methods correlate well with DEXA at typical body fat ranges. They lose accuracy below 6 percent or above 35 percent.',
        },
      ]}
    >
      {/* Method tabs */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">What tools do you have?</h2>
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 mb-6">
          <MethodTabButton
            active={methodTab === 'tape'}
            label="Tape measure"
            sub="Navy + RFM + Bailey"
            onClick={() => setMethodTab('tape')}
          />
          <MethodTabButton
            active={methodTab === 'skinfold3'}
            label="Calipers (3 sites)"
            sub="JP3 + all tape methods"
            onClick={() => setMethodTab('skinfold3')}
          />
          <MethodTabButton
            active={methodTab === 'skinfold7'}
            label="Calipers (7 sites)"
            sub="JP7, most accurate"
            onClick={() => setMethodTab('skinfold7')}
          />
        </div>

        <div className="flex gap-2 flex-wrap mb-6">
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
              { value: 'ft', label: 'ft/in' },
              { value: 'cm', label: 'cm' },
            ]}
            onChange={setHeightUnit}
          />
          <UnitToggle
            value={tapeUnit}
            options={[
              { value: 'in', label: 'in' },
              { value: 'cm', label: 'cm' },
            ]}
            onChange={setTapeUnit}
            label="Tape"
          />
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {heightUnit === 'ft' ? (
            <div className="grid grid-cols-2 gap-2">
              <NumberInput label="Height (ft)" value={feet} onChange={setFeet} unit="ft" min={3} max={8} step={1} />
              <NumberInput label="Height (in)" value={inches} onChange={setInches} unit="in" min={0} max={11.9} step={0.5} />
            </div>
          ) : (
            <NumberInput label="Height" value={heightCm} onChange={setHeightCm} unit="cm" min={100} max={250} step={0.5} />
          )}
          <NumberInput label="Age" value={age} onChange={setAge} unit="yrs" min={10} max={100} step={1} />
          <NumberInput label="Neck" value={neck} onChange={setNeck} unit={tapeUnit} min={5} step={0.25} />
          <NumberInput label="Waist (at navel)" value={waist} onChange={setWaist} unit={tapeUnit} min={15} step={0.25} />
          {sex === 'female' && (
            <NumberInput label="Hip (widest)" value={hip} onChange={setHip} unit={tapeUnit} min={20} step={0.25} />
          )}
        </div>

        {(methodTab === 'skinfold3' || methodTab === 'skinfold7') && (
          <div className="mt-6 pt-6 border-t border-zinc-800">
            <h3 className="text-sm font-semibold text-zinc-300 mb-3">
              Skinfold sites (mm)
            </h3>
            <p className="text-xs text-zinc-500 mb-4">
              Take 3 readings per site, on the right side of the body, and average them. Wait 1 to 2 seconds before reading the caliper.
            </p>
            <div className="grid grid-cols-2 sm:grid-cols-3 gap-3">
              {sex === 'male' && <NumberInput label="Chest" value={chest} onChange={setChest} unit="mm" min={1} step={0.5} />}
              {sex === 'female' && <NumberInput label="Triceps" value={triceps} onChange={setTriceps} unit="mm" min={1} step={0.5} />}
              {sex === 'female' && <NumberInput label="Suprailiac" value={suprailiac} onChange={setSuprailiac} unit="mm" min={1} step={0.5} />}
              <NumberInput label={sex === 'male' ? 'Abdomen' : 'Thigh'} value={sex === 'male' ? abdomen : thigh} onChange={sex === 'male' ? setAbdomen : setThigh} unit="mm" min={1} step={0.5} />
              {sex === 'male' && <NumberInput label="Thigh" value={thigh} onChange={setThigh} unit="mm" min={1} step={0.5} />}

              {methodTab === 'skinfold7' && (
                <>
                  {sex === 'female' && <NumberInput label="Chest" value={chest} onChange={setChest} unit="mm" min={1} step={0.5} />}
                  {sex === 'female' && <NumberInput label="Abdomen" value={abdomen} onChange={setAbdomen} unit="mm" min={1} step={0.5} />}
                  {sex === 'male' && <NumberInput label="Triceps" value={triceps} onChange={setTriceps} unit="mm" min={1} step={0.5} />}
                  {sex === 'male' && <NumberInput label="Suprailiac" value={suprailiac} onChange={setSuprailiac} unit="mm" min={1} step={0.5} />}
                  <NumberInput label="Midaxillary" value={midaxillary} onChange={setMidaxillary} unit="mm" min={1} step={0.5} />
                  <NumberInput label="Subscapular" value={subscapular} onChange={setSubscapular} unit="mm" min={1} step={0.5} />
                </>
              )}
            </div>
          </div>
        )}
      </section>

      {/* Headline */}
      {headline > 0 && (
        <section className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-950/60 to-zinc-900 p-6">
          <p className="text-xs uppercase tracking-wide text-emerald-400 font-semibold">
            Recommended estimate
          </p>
          <div className="flex items-baseline gap-3 mt-1">
            <p className="text-4xl font-bold text-white font-mono">{headline}%</p>
            <p className="text-sm text-zinc-400">body fat</p>
          </div>
          <p className="text-sm text-zinc-300 mt-2">
            Category: <span className="font-semibold text-white">{bodyFatCategory(headline, sex)}</span>
          </p>
        </section>
      )}

      {/* Results */}
      {results.length > 0 && (
        <section>
          <h2 className="text-lg font-bold text-white mb-1">All methods compared</h2>
          <p className="text-sm text-zinc-400 mb-4">
            Methods that need more inputs are still listed for reference. The most accurate method available is highlighted.
          </p>
          <ResultsTable rows={tableRows} valueLabel="Body Fat" />
        </section>
      )}

      {/* Install CTA */}
      <InstallCta
        slug="body-fat-calculator"
        result={{ bodyFatPct: headline, sex, method: recommended }}
        primary="Track body fat changes over months in Zealova"
        secondary="Log measurements once and we chart the trend, compare against your strength gains, and surface when your cut has gone too far."
      />

      {/* Methodology */}
      <MethodologyFooter
        citations={[
          { text: 'Hodgdon JA, Beckett MB (1984). Prediction of percent body fat for U.S. Navy men and women from body circumferences and height. Naval Health Research Center.' },
          {
            text: 'Jackson AS, Pollock ML (1978). Generalized equations for predicting body density of men. Br J Nutr 40(3):497-504.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/718832/',
          },
          {
            text: 'Jackson AS, Pollock ML, Ward A (1980). Generalized equations for predicting body density of women. Med Sci Sports Exerc 12(3):175-81.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/7402053/',
          },
          { text: 'Siri WE (1961). Body composition from fluid spaces and density. UC Berkeley Donner Lab Report.' },
          {
            text: 'Woolcott OO, Bergman RN (2018). Relative Fat Mass (RFM) as a new estimator of whole-body fat percentage. Sci Rep 8:10980.',
            url: 'https://www.nature.com/articles/s41598-018-29362-1',
          },
          { text: 'Bailey C (1991). The New Fit or Fat.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function MethodTabButton({
  active,
  label,
  sub,
  onClick,
}: {
  active: boolean;
  label: string;
  sub: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={`text-left px-4 py-3 rounded-xl border transition ${
        active
          ? 'border-emerald-500 bg-emerald-500/10'
          : 'border-zinc-700 bg-zinc-950 hover:border-zinc-600'
      }`}
    >
      <span className="block font-semibold text-white text-sm">{label}</span>
      <span className="block text-xs text-zinc-400 mt-0.5">{sub}</span>
    </button>
  );
}
