// /free-tools/recipe-scaler
//
// Parses a free-text ingredient list, extracts the leading quantity from each
// line (supports decimals, fractions, ranges, and unicode vulgar fractions),
// then scales just the quantity by target/current servings.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

const VULGAR: Record<string, number> = {
  '½': 0.5, '⅓': 1 / 3, '⅔': 2 / 3, '¼': 0.25, '¾': 0.75,
  '⅕': 0.2, '⅖': 0.4, '⅗': 0.6, '⅘': 0.8,
  '⅙': 1 / 6, '⅚': 5 / 6, '⅛': 0.125, '⅜': 0.375, '⅝': 0.625, '⅞': 0.875,
};

function parseFractionToken(token: string): number | null {
  if (token in VULGAR) return VULGAR[token];
  if (token.includes('/')) {
    const [n, d] = token.split('/').map((x) => parseFloat(x));
    if (Number.isFinite(n) && Number.isFinite(d) && d !== 0) return n / d;
    return null;
  }
  const n = parseFloat(token);
  return Number.isFinite(n) ? n : null;
}

function parseLeadingQuantity(line: string): { value: number; original: string; rest: string } | null {
  const trimmed = line.trimStart();
  if (!trimmed) return null;
  // Match either: range like "2-3" or "2 to 3", mixed "1 1/2", fraction "1/2",
  // vulgar fraction "½", or plain number "2.5".
  // Try in order, greedy.
  const rangeRe = /^([\d./⅛⅜⅝⅞⅙⅚½⅓⅔¼¾⅕⅖⅗⅘]+)\s*(?:-|to|–)\s*([\d./⅛⅜⅝⅞⅙⅚½⅓⅔¼¾⅕⅖⅗⅘]+)/i;
  const mixedRe = /^(\d+)\s+([\d/⅛⅜⅝⅞⅙⅚½⅓⅔¼¾⅕⅖⅗⅘]+)/;
  const singleRe = /^([\d./⅛⅜⅝⅞⅙⅚½⅓⅔¼¾⅕⅖⅗⅘]+)/;

  let match = trimmed.match(rangeRe);
  if (match) {
    const a = parseFractionToken(match[1]);
    const b = parseFractionToken(match[2]);
    if (a !== null && b !== null) {
      return {
        value: (a + b) / 2,
        original: match[0],
        rest: trimmed.slice(match[0].length),
      };
    }
  }
  match = trimmed.match(mixedRe);
  if (match) {
    const whole = parseFloat(match[1]);
    const frac = parseFractionToken(match[2]);
    if (frac !== null) {
      return {
        value: whole + frac,
        original: match[0],
        rest: trimmed.slice(match[0].length),
      };
    }
  }
  match = trimmed.match(singleRe);
  if (match) {
    const v = parseFractionToken(match[1]);
    if (v !== null) {
      return {
        value: v,
        original: match[1],
        rest: trimmed.slice(match[1].length),
      };
    }
  }
  return null;
}

function formatScaled(n: number): string {
  if (!Number.isFinite(n)) return '';
  if (n === 0) return '0';
  // Try to express common fractions
  const whole = Math.floor(n);
  const remainder = n - whole;
  const fracMap: { value: number; symbol: string }[] = [
    { value: 0.125, symbol: '1/8' },
    { value: 0.25, symbol: '1/4' },
    { value: 1 / 3, symbol: '1/3' },
    { value: 0.375, symbol: '3/8' },
    { value: 0.5, symbol: '1/2' },
    { value: 0.625, symbol: '5/8' },
    { value: 2 / 3, symbol: '2/3' },
    { value: 0.75, symbol: '3/4' },
    { value: 0.875, symbol: '7/8' },
  ];
  const near = fracMap.find((f) => Math.abs(remainder - f.value) < 0.04);
  if (near) {
    if (whole === 0) return near.symbol;
    return `${whole} ${near.symbol}`;
  }
  if (remainder < 0.04) return String(whole);
  if (remainder > 0.96) return String(whole + 1);
  return n.toFixed(2).replace(/\.?0+$/, '');
}

interface ScaledLine {
  original: string;
  scaled: string;
}

function scaleRecipe(input: string, factor: number): ScaledLine[] {
  return input.split('\n').map((line) => {
    if (!line.trim()) return { original: line, scaled: line };
    const parsed = parseLeadingQuantity(line);
    if (!parsed) return { original: line, scaled: line };
    const scaled = parsed.value * factor;
    return {
      original: line,
      scaled: `${formatScaled(scaled)}${parsed.rest}`,
    };
  });
}

const DENSITIES: { name: string; cup: number; tbsp: number }[] = [
  { name: 'Water', cup: 240, tbsp: 15 },
  { name: 'All-purpose flour', cup: 125, tbsp: 8 },
  { name: 'Granulated sugar', cup: 200, tbsp: 12.5 },
  { name: 'Brown sugar (packed)', cup: 220, tbsp: 13.5 },
  { name: 'Butter', cup: 227, tbsp: 14 },
  { name: 'White rice (uncooked)', cup: 195, tbsp: 12 },
  { name: 'Rolled oats', cup: 80, tbsp: 5 },
  { name: 'Honey', cup: 340, tbsp: 21 },
  { name: 'Olive oil', cup: 218, tbsp: 13.5 },
  { name: 'Milk', cup: 245, tbsp: 15 },
  { name: 'Peanut butter', cup: 258, tbsp: 16 },
];

const SAMPLE = `2 cups flour
1 1/2 tsp baking powder
1/2 tsp salt
3/4 cup sugar
2 large eggs
1 cup milk
1/4 cup melted butter
1 tsp vanilla extract
salt to taste`;

export default function RecipeScaler() {
  const [recipe, setRecipe] = useState(SAMPLE);
  const [current, setCurrent] = useState(4);
  const [target, setTarget] = useState(8);

  const factor = current > 0 ? target / current : 1;

  const scaled = useMemo(() => scaleRecipe(recipe, factor), [recipe, factor]);

  const applyQuick = (mult: number) => setTarget(Math.max(1, Math.round(current * mult * 100) / 100));

  return (
    <CalculatorShell
      slug="recipe-scaler"
      title="Recipe Scaler"
      metaDescription="Scale any recipe up or down by servings. Paste an ingredient list, set current and target servings, get scaled quantities. Handles fractions, ranges, and mixed numbers. Includes a cooking-measurement converter."
      intro="Paste your ingredient list. Set how many servings the recipe makes today and how many you want. We scale every quantity, keeping fractions readable and leaving the wording alone."
      faqs={[
        {
          q: 'Why are some ingredients not scaled?',
          a: 'Lines without a numeric quantity, like "salt to taste" or "a pinch of pepper", are left unchanged. Only the leading number on each line is scaled. If your ingredient amount is buried mid-line, move it to the start.',
        },
        {
          q: 'How are fractions handled?',
          a: 'We accept decimals (1.5), regular fractions (1/2), mixed numbers (1 1/2), and unicode vulgar fractions like ½. Scaled results are rounded to the nearest common kitchen fraction (1/8, 1/4, 1/3, 1/2, etc.) when close, otherwise shown as a decimal.',
        },
        {
          q: 'Can I scale baking recipes?',
          a: 'Yes, but scale with care. Doubling cookies works. Doubling a cake recipe sometimes does not, because baking time depends on pan size, not just quantity. For baking, prefer weighing ingredients in grams and adjusting bake time empirically.',
        },
        {
          q: 'Does the converter use US or metric measurements?',
          a: 'The density table uses US customary cups (240 ml) and tablespoons (15 ml). For UK and Australian cups (250 ml), multiply the gram values by 1.04 and 1.04 respectively. The metric ↔ imperial converter at the top handles unit translation directly.',
        },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-6">Your recipe</h2>
        <label className="block mb-4">
          <span className="block text-sm font-medium text-zinc-300 mb-1.5">Ingredient list</span>
          <textarea
            value={recipe}
            onChange={(e) => setRecipe(e.target.value)}
            rows={10}
            placeholder="2 cups flour&#10;1 tsp salt&#10;..."
            className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-sm font-mono focus:outline-none focus:ring-2 focus:ring-emerald-500"
          />
          <p className="text-xs text-zinc-500 mt-1.5">One ingredient per line. Quantity at the start of each line.</p>
        </label>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4 mb-4">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Current servings</span>
            <input
              type="number"
              value={current}
              onChange={(e) => setCurrent(parseFloat(e.target.value) || 1)}
              min={1}
              step={1}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </label>
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-1.5">Target servings</span>
            <input
              type="number"
              value={target}
              onChange={(e) => setTarget(parseFloat(e.target.value) || 1)}
              min={0.25}
              step={1}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-base focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
          </label>
        </div>

        <div className="flex flex-wrap gap-2">
          {[
            { label: '×2', mult: 2 },
            { label: '×3', mult: 3 },
            { label: '÷2', mult: 0.5 },
            { label: '÷4', mult: 0.25 },
          ].map((q) => (
            <button
              key={q.label}
              onClick={() => applyQuick(q.mult)}
              className="px-3 py-1.5 rounded-lg text-xs font-medium bg-zinc-950 border border-zinc-700 text-zinc-300 hover:border-emerald-500 hover:text-emerald-400 transition"
            >
              {q.label}
            </button>
          ))}
          <div className="ml-auto px-3 py-1.5 rounded-lg bg-emerald-500/10 text-emerald-400 text-xs font-mono font-semibold">
            Scale: ×{factor.toFixed(2)}
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Scaled recipe</h2>
        <p className="text-sm text-zinc-400 mb-4">
          {target} servings, scaled from {current}.
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Original</th>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Scaled</th>
              </tr>
            </thead>
            <tbody>
              {scaled.map((row, i) => (
                <tr key={i} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-zinc-500 font-mono">{row.original || ' '}</td>
                  <td className="px-4 py-2.5 font-mono font-semibold text-white">{row.scaled || ' '}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-1">Ingredient density reference</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Cup and tablespoon weights for common baking ingredients. US customary cup (240 ml).
        </p>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Ingredient</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">1 cup</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">1 tbsp</th>
              </tr>
            </thead>
            <tbody>
              {DENSITIES.map((d) => (
                <tr key={d.name} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-white">{d.name}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{d.cup} g</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{d.tbsp} g</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </section>

      <section className="rounded-2xl border border-zinc-800 bg-zinc-900 p-6">
        <h2 className="text-lg font-bold text-white mb-3">Quick conversions</h2>
        <ul className="text-sm text-zinc-300 space-y-1.5 font-mono">
          <li>1 tbsp = 3 tsp = 15 ml</li>
          <li>1 cup = 16 tbsp = 48 tsp = 240 ml (US)</li>
          <li>1 fl oz = 2 tbsp = 30 ml</li>
          <li>1 oz (weight) = 28.35 g</li>
          <li>1 lb = 16 oz = 453.6 g</li>
          <li>1 stick butter = 1/2 cup = 8 tbsp = 113 g</li>
        </ul>
      </section>

      <InstallCta
        slug="recipe-scaler"
        result={{ current, target, factor }}
        primary="Save your scaled recipes and macros in Zealova"
        secondary="Zealova logs scaled ingredient quantities into your daily macro target, no manual entry."
      />

      <MethodologyFooter
        citations={[
          {
            text: 'USDA FoodData Central. Ingredient densities derived from gram weights per cup for standard reference foods.',
            url: 'https://fdc.nal.usda.gov/',
          },
          {
            text: 'King Arthur Baking Company. Ingredient Weight Chart. Reference for baking ingredient densities.',
            url: 'https://www.kingarthurbaking.com/learn/ingredient-weight-chart',
          },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}
