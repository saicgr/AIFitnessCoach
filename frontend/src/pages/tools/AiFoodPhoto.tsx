// /free-tools/ai-food-photo
//
// Free AI food-photo analyzer. User drops an image, we POST it to
// /api/v1/free-tools/ai-food-photo (Gemini Vision), and render rich
// nutrition data (macros, micros, glycemic load, health grade, AI
// commentary). Rate-limited to 2 calls per IP per day on the backend.
//
// Strategic purpose: prove out the Zealova food-scan flow to people who
// haven't installed yet. The InstallCta is always visible because the goal
// is install conversion, not tool retention.

import { useCallback, useEffect, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import RateLimitModal from '../../components/tools/RateLimitModal';
import EmailCapture from '../../components/tools/EmailCapture';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import { callAiTool, isRateLimitError, type RateLimitError } from '../../lib/aiToolsClient';

interface FoodItem {
  name: string;
  grams: number;
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g?: number;
  glycemic_load?: number | null;
  confidence: 'high' | 'medium' | 'low' | number;
}

interface FoodTotals {
  calories: number;
  protein_g: number;
  carbs_g: number;
  fat_g: number;
  fiber_g: number;
}

interface FoodMicros {
  iron_mg?: number;
  calcium_mg?: number;
  magnesium_mg?: number;
  zinc_mg?: number;
  potassium_mg?: number;
  sodium_mg?: number;
  vitamin_a_ug?: number;
  vitamin_c_mg?: number;
  vitamin_d_ug?: number;
  vitamin_b12_ug?: number;
  omega_3_g?: number;
  [key: string]: number | undefined;
}

interface FoodPhotoResponse {
  items: FoodItem[];
  totals: FoodTotals;
  micros?: FoodMicros | null;
  health_score?: string | null;
  commentary?: string | null;
  uses_remaining_today: number;
}

const PLAY_STORE = 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dai-food-photo';

// FDA Daily Values for an adult 2,000 kcal reference diet. Used to render
// the "% of daily value" bars under the micronutrient grid. Sodium is the
// only "upper limit" entry; we flag rather than reward fullness.
const DAILY_VALUES = {
  fiber_g: 25,
  iron_mg: 18,
  calcium_mg: 1000,
  magnesium_mg: 400,
  sodium_mg: 2300,
  potassium_mg: 3500,
  vitamin_c_mg: 90,
  vitamin_d_ug: 20,
  vitamin_b12_ug: 2.4,
  zinc_mg: 11,
  vitamin_a_ug: 900,
  omega_3_g: 1.6,
} as const;

// Priority ordering for the micro grid. Show first 8 that have a value.
const MICRO_PRIORITY: Array<{
  key: keyof typeof DAILY_VALUES;
  label: string;
  unit: string;
}> = [
  { key: 'fiber_g',        label: 'Fiber',       unit: 'g'  },
  { key: 'iron_mg',        label: 'Iron',        unit: 'mg' },
  { key: 'calcium_mg',     label: 'Calcium',     unit: 'mg' },
  { key: 'magnesium_mg',   label: 'Magnesium',   unit: 'mg' },
  { key: 'potassium_mg',   label: 'Potassium',   unit: 'mg' },
  { key: 'sodium_mg',      label: 'Sodium',      unit: 'mg' },
  { key: 'vitamin_c_mg',   label: 'Vitamin C',   unit: 'mg' },
  { key: 'vitamin_d_ug',   label: 'Vitamin D',   unit: 'µg' },
  { key: 'vitamin_b12_ug', label: 'Vitamin B12', unit: 'µg' },
  { key: 'zinc_mg',        label: 'Zinc',        unit: 'mg' },
  { key: 'vitamin_a_ug',   label: 'Vitamin A',   unit: 'µg' },
  { key: 'omega_3_g',      label: 'Omega-3',     unit: 'g'  },
];

export default function AiFoodPhoto() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<FoodPhotoResponse | null>(null);
  const [rateLimit, setRateLimit] = useState<RateLimitError | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);

  const onPick = useCallback((f: File | null) => {
    if (!f) return;
    setFile(f);
    setResult(null);
    setRateLimit(null);
    setError(null);
    const url = URL.createObjectURL(f);
    setPreview((prev) => {
      if (prev) URL.revokeObjectURL(prev);
      return url;
    });
  }, []);

  const onDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setDragging(false);
    const f = e.dataTransfer.files?.[0];
    if (f) onPick(f);
  };

  const analyze = async () => {
    if (!file) return;
    setLoading(true);
    setError(null);
    setRateLimit(null);
    try {
      const form = new FormData();
      form.append('image', file);
      const data = await callAiTool<FoodPhotoResponse>('/ai-food-photo', form);
      setResult(data);
    } catch (e) {
      if (isRateLimitError(e)) {
        setRateLimit(e);
      } else {
        setError('Could not analyze that photo. Try a clearer shot.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <CalculatorShell
      slug="ai-food-photo"
      title="AI Food Photo Analyzer"
      metaDescription="Free AI food photo analyzer. Snap any meal, get calories, macros, micros, glycemic load, and a health grade in seconds. Powered by Google Gemini. No sign-up. 2 free scans per day."
      intro="Snap a photo of any meal. Our AI identifies the foods, estimates portions, and breaks down calories, macros, micros, glycemic load, and a health grade. No sign-up, no email. Just answers."
      installPrimary="This is your daily Zealova. Photo every meal."
      installSecondary="Zealova logs every scan to your nutrition history, learns your portion patterns, and adjusts your daily targets automatically."
      emailCaptureResult={
        result
          ? {
              items: result.items.length,
              calories: Math.round(result.totals.calories),
              protein_g: Math.round(result.totals.protein_g),
              carbs_g: Math.round(result.totals.carbs_g),
              fat_g: Math.round(result.totals.fat_g),
            }
          : undefined
      }
      faqs={[
        {
          q: 'How accurate is the analysis?',
          a: 'Calorie estimates from a single photo are typically within 15 to 25 percent of the true value. Accuracy improves with a top-down angle, good lighting, and a reference object like a fork. For exact tracking, weigh ingredients on a kitchen scale.',
        },
        {
          q: 'Why only 2 scans per day?',
          a: 'Each scan calls Google Gemini, which costs us per call. The 2-per-day cap on the free tier keeps the tool free for everyone without a paywall. Zealova users get unlimited scans on the app.',
        },
        {
          q: 'Are my photos stored?',
          a: 'No. The image is sent to Google Gemini, the response is returned to you, and the photo is discarded. We do not log image bytes server-side.',
        },
        {
          q: 'What works best?',
          a: 'Top-down shots, full plate in frame, even lighting. Avoid heavy filters. Single dishes work better than buffet trays.',
        },
      ]}
    >
      {/* Daily-limit banner */}
      <div className="rounded-xl border border-emerald-500/20 bg-emerald-500/5 px-4 py-2.5 text-xs text-emerald-300 flex items-center justify-between flex-wrap gap-2">
        <span>Free, 2 uses per day per device. No sign-up.</span>
        {result && (
          <span className="font-semibold">{result.uses_remaining_today} use{result.uses_remaining_today === 1 ? '' : 's'} left today</span>
        )}
      </div>

      {/* Upload */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">Upload your meal photo</h2>
        <label
          htmlFor="ai-food-input"
          onDragOver={(e) => {
            e.preventDefault();
            setDragging(true);
          }}
          onDragLeave={() => setDragging(false)}
          onDrop={onDrop}
          className={`block cursor-pointer rounded-xl border-2 border-dashed text-center transition py-10 px-4 ${
            preview
              ? 'border-emerald-500/40 bg-emerald-500/5'
              : dragging
              ? 'border-emerald-500 bg-emerald-500/10 text-emerald-200'
              : 'border-zinc-700 bg-zinc-950 text-zinc-500 hover:border-zinc-600 hover:text-zinc-300'
          }`}
        >
          <input
            id="ai-food-input"
            type="file"
            accept="image/jpeg,image/png,image/webp,image/heic"
            className="sr-only"
            onChange={(e) => onPick(e.target.files?.[0] ?? null)}
          />
          {preview ? (
            <div className="space-y-3">
              <img src={preview} alt="Selected meal" className="max-h-56 mx-auto rounded-lg" />
              <p className="text-xs text-zinc-500">Tap to replace</p>
            </div>
          ) : (
            <div className="space-y-1">
              <p className="text-sm text-zinc-300">Tap to upload or drag a photo here</p>
              <p className="text-xs text-zinc-500">JPG, PNG, WebP, or HEIC up to 10MB</p>
            </div>
          )}
        </label>

        <button
          type="button"
          onClick={analyze}
          disabled={!file || loading}
          className="mt-5 w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:cursor-not-allowed disabled:shadow-none"
        >
          {loading ? 'Analyzing…' : 'Analyze photo (1 of 2 free today)'}
        </button>
      </section>

      {/* Loading skeleton with inline email capture (captive audience). */}
      {loading && (
        <div className="grid gap-3 sm:grid-cols-2">
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 animate-pulse space-y-3">
            <div className="h-4 w-1/3 bg-zinc-800 rounded" />
            <div className="h-4 w-2/3 bg-zinc-800 rounded" />
            <div className="h-4 w-1/2 bg-zinc-800 rounded" />
            <p className="text-xs text-zinc-500 pt-2">Gemini is reading your plate. Usually 3 to 8 seconds.</p>
          </section>
          <EmailCapture
            toolSlug="ai-food-photo"
            variant="inline-processing"
            source="during_processing"
          />
        </div>
      )}

      {/* Rate limit */}
      {rateLimit && <RateLimitCard err={rateLimit} />}
      <RateLimitModal
        open={!!rateLimit}
        onClose={() => setRateLimit(null)}
        slug="ai-food-photo"
        toolName="food photo"
        resetWindow="24 hours"
      />

      {/* Error */}
      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/5 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {/* Results */}
      {result && <ResultsView result={result} preview={preview} />}

      <MethodologyFooter
        citations={[
          { text: 'Powered by Google Gemini. Free use limited to 2 calls per IP per 24 hours to prevent abuse. Get unlimited in the Zealova app.' },
          { text: 'Portion estimation accuracy: Lu et al. (2020). Computer-vision-based food portion estimation: a systematic review. Nutrients 12(4).', url: 'https://pubmed.ncbi.nlm.nih.gov/32340367/' },
          { text: 'Daily Values reference: FDA Daily Value reference for adults and children 4+. Used for the % DV bars on the micronutrient grid.', url: 'https://www.fda.gov/food/nutrition-facts-label/daily-value-nutrition-and-supplement-facts-labels' },
        ]}
        lastUpdated="2026-05-15"
      />

      {/* Hidden Play Store link to make the CTA copy actionable even when JS deep-link fails. */}
      <a href={PLAY_STORE} className="sr-only">Install Zealova on Google Play</a>
    </CalculatorShell>
  );
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

function ResultsView({ result, preview }: { result: FoodPhotoResponse; preview: string | null }) {
  const totals = result.totals;
  const cals = Math.round(totals.calories);
  const p = Math.max(0, totals.protein_g);
  const c = Math.max(0, totals.carbs_g);
  const f = Math.max(0, totals.fat_g);

  // Kcal per gram for macro share: P=4, C=4, F=9.
  const pKcal = p * 4;
  const cKcal = c * 4;
  const fKcal = f * 9;
  const totalKcal = Math.max(1, pKcal + cKcal + fKcal);
  const pPct = Math.round((pKcal / totalKcal) * 100);
  const cPct = Math.round((cKcal / totalKcal) * 100);
  const fPct = Math.max(0, 100 - pPct - cPct);

  const visibleMicros = MICRO_PRIORITY.filter((m) => {
    const v = result.micros?.[m.key];
    return typeof v === 'number' && v > 0;
  }).slice(0, 8);

  return (
    <section className="space-y-4">
      {/* Hero card */}
      <div className="relative overflow-hidden rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-500/10 via-zinc-900 to-zinc-950 p-6 sm:p-8">
        <div className="flex items-start justify-between gap-4 flex-wrap">
          <div className="min-w-[200px]">
            <p className="text-xs uppercase tracking-widest text-emerald-300/80">Total calories</p>
            <p className="text-5xl sm:text-6xl font-extrabold text-white leading-none mt-1 tabular-nums">{cals}</p>
            <p className="text-xs text-zinc-500 mt-1">kcal across {result.items.length} item{result.items.length === 1 ? '' : 's'}</p>
          </div>
          <div className="flex items-start gap-3">
            {result.health_score && <HealthBadge grade={result.health_score} />}
            {preview && (
              <img
                src={preview}
                alt="Analyzed meal"
                className="h-20 w-20 sm:h-24 sm:w-24 rounded-xl object-cover border border-zinc-800 shadow-lg"
              />
            )}
          </div>
        </div>
      </div>

      {/* AI commentary */}
      {result.commentary && (
        <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5">
          <div className="flex items-start gap-3">
            <span className="shrink-0 inline-flex items-center justify-center h-6 px-2 rounded-md bg-emerald-500/15 text-emerald-300 text-[10px] font-bold uppercase tracking-wider border border-emerald-500/30">AI</span>
            <p className="italic text-zinc-200 text-sm sm:text-base leading-relaxed">{result.commentary}</p>
          </div>
        </div>
      )}

      {/* Macro split: stat cards + donut */}
      <div className="grid gap-3 lg:grid-cols-[1fr_220px]">
        <div className="grid grid-cols-3 gap-3">
          <MacroCard label="Protein" grams={p} pct={pPct} color="emerald" />
          <MacroCard label="Carbs"   grams={c} pct={cPct} color="amber" />
          <MacroCard label="Fat"     grams={f} pct={fPct} color="rose" />
        </div>
        <MacroDonut pPct={pPct} cPct={cPct} fPct={fPct} />
      </div>

      {/* Micronutrient grid */}
      {visibleMicros.length > 0 && (
        <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5">
          <div className="flex items-baseline justify-between mb-4">
            <h3 className="text-sm font-bold text-white uppercase tracking-wide">Micronutrients</h3>
            <p className="text-[11px] text-zinc-500">% of daily value</p>
          </div>
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-3">
            {visibleMicros.map((m) => {
              const value = result.micros![m.key]!;
              const dv = DAILY_VALUES[m.key];
              const isUpperLimit = m.key === 'sodium_mg';
              const pctRaw = (value / dv) * 100;
              const pct = Math.max(0, Math.min(100, pctRaw));
              return (
                <MicroBar
                  key={m.key}
                  label={m.label}
                  value={value}
                  unit={m.unit}
                  pct={pct}
                  pctRaw={pctRaw}
                  upperLimit={isUpperLimit}
                />
              );
            })}
          </div>
        </div>
      )}

      {/* Items table */}
      <div>
        <h3 className="text-sm font-bold text-white uppercase tracking-wide mb-2">Per-item breakdown</h3>
        <div className="overflow-x-auto rounded-2xl border border-zinc-800">
          <table className="w-full text-sm">
            <thead className="bg-zinc-900 border-b border-zinc-800">
              <tr>
                <th className="text-left px-4 py-3 font-semibold text-zinc-300">Item</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">Grams</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">kcal</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">P</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">C</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">F</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">Fiber</th>
                <th className="text-center px-4 py-3 font-semibold text-zinc-300">GL</th>
                <th className="text-right px-4 py-3 font-semibold text-zinc-300">Conf.</th>
              </tr>
            </thead>
            <tbody>
              {result.items.map((it, i) => (
                <tr key={i} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-white">{it.name}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{Math.round(it.grams)}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{Math.round(it.calories)}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{Math.round(it.protein_g)}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{Math.round(it.carbs_g)}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{Math.round(it.fat_g)}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{it.fiber_g != null ? Math.round(it.fiber_g) : '—'}</td>
                  <td className="px-4 py-2.5 text-center"><GlBadge value={it.glycemic_load ?? null} /></td>
                  <td className="px-4 py-2.5 text-right font-mono text-emerald-400">{formatConfidence(it.confidence)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <p className="text-xs text-zinc-500">
        {result.uses_remaining_today} free scan{result.uses_remaining_today === 1 ? '' : 's'} left today. Resets at midnight local.
      </p>
    </section>
  );
}

// ---------------------------------------------------------------------------
// Sub-components
// ---------------------------------------------------------------------------

function HealthBadge({ grade }: { grade: string }) {
  const g = grade.trim().toUpperCase();
  const head = g[0] || '?';
  // Letter-grade → tone. + and - share the base letter's tone.
  const tone = {
    A: { bg: 'bg-emerald-500/20', text: 'text-emerald-300', border: 'border-emerald-500/40', label: 'Excellent' },
    B: { bg: 'bg-lime-500/20',    text: 'text-lime-300',    border: 'border-lime-500/40',    label: 'Good' },
    C: { bg: 'bg-amber-500/20',   text: 'text-amber-300',   border: 'border-amber-500/40',   label: 'Average' },
    D: { bg: 'bg-orange-500/20',  text: 'text-orange-300',  border: 'border-orange-500/40',  label: 'Below average' },
    F: { bg: 'bg-red-500/20',     text: 'text-red-300',     border: 'border-red-500/40',     label: 'Poor' },
  }[head] || { bg: 'bg-zinc-500/20', text: 'text-zinc-300', border: 'border-zinc-500/40', label: 'Ungraded' };

  return (
    <div
      className={`flex flex-col items-center justify-center rounded-xl border ${tone.bg} ${tone.border} px-3 py-2 min-w-[68px]`}
      title={`Health grade ${g}. ${tone.label}.`}
    >
      <p className={`text-[10px] uppercase tracking-widest ${tone.text} opacity-80`}>Grade</p>
      <p className={`text-2xl font-extrabold leading-none ${tone.text}`}>{g}</p>
    </div>
  );
}

function MacroCard({
  label,
  grams,
  pct,
  color,
}: {
  label: string;
  grams: number;
  pct: number;
  color: 'emerald' | 'amber' | 'rose';
}) {
  const colors = {
    emerald: { dot: 'bg-emerald-400', text: 'text-emerald-300' },
    amber:   { dot: 'bg-amber-400',   text: 'text-amber-300' },
    rose:    { dot: 'bg-rose-400',    text: 'text-rose-300' },
  }[color];
  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-4">
      <div className="flex items-center gap-2 mb-1">
        <span className={`inline-block h-2 w-2 rounded-full ${colors.dot}`} />
        <p className="text-xs uppercase tracking-wide text-zinc-500">{label}</p>
      </div>
      <p className="text-2xl font-bold text-white tabular-nums">
        {Math.round(grams)}
        <span className="text-sm text-zinc-500 font-normal ml-1">g</span>
      </p>
      <p className={`text-xs ${colors.text} mt-0.5`}>{pct}% of calories</p>
    </div>
  );
}

function MacroDonut({ pPct, cPct, fPct }: { pPct: number; cPct: number; fPct: number }) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [hover, setHover] = useState<string | null>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    const dpr = window.devicePixelRatio || 1;
    const size = 200;
    canvas.width = size * dpr;
    canvas.height = size * dpr;
    canvas.style.width = `${size}px`;
    canvas.style.height = `${size}px`;
    ctx.scale(dpr, dpr);

    const cx = size / 2;
    const cy = size / 2;
    const r = 80;
    const innerR = 50;

    ctx.clearRect(0, 0, size, size);
    let start = -Math.PI / 2;
    const slices = [
      { pct: pPct, color: '#34d399' }, // emerald-400
      { pct: cPct, color: '#fbbf24' }, // amber-400
      { pct: fPct, color: '#fb7185' }, // rose-400
    ];
    for (const s of slices) {
      if (s.pct <= 0) continue;
      const end = start + (s.pct / 100) * Math.PI * 2;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, r, start, end);
      ctx.closePath();
      ctx.fillStyle = s.color;
      ctx.fill();
      start = end;
    }
    // Punch out the centre to form a donut.
    ctx.globalCompositeOperation = 'destination-out';
    ctx.beginPath();
    ctx.arc(cx, cy, innerR, 0, Math.PI * 2);
    ctx.fill();
    ctx.globalCompositeOperation = 'source-over';

    // Centre label.
    ctx.fillStyle = '#a1a1aa';
    ctx.font = '600 10px ui-sans-serif, system-ui';
    ctx.textAlign = 'center';
    ctx.fillText('MACROS', cx, cy + 3);
  }, [pPct, cPct, fPct]);

  return (
    <div className="rounded-xl border border-zinc-800 bg-zinc-950 p-3 flex flex-col items-center justify-center">
      <canvas ref={canvasRef} className="block" />
      <div
        className="mt-2 flex items-center gap-3 text-[11px]"
        onMouseLeave={() => setHover(null)}
      >
        <span
          className="flex items-center gap-1 cursor-help"
          onMouseEnter={() => setHover(`Protein ${pPct}%`)}
        >
          <span className="h-2 w-2 rounded-full bg-emerald-400" /> <span className="text-zinc-400">P</span>
        </span>
        <span
          className="flex items-center gap-1 cursor-help"
          onMouseEnter={() => setHover(`Carbs ${cPct}%`)}
        >
          <span className="h-2 w-2 rounded-full bg-amber-400" /> <span className="text-zinc-400">C</span>
        </span>
        <span
          className="flex items-center gap-1 cursor-help"
          onMouseEnter={() => setHover(`Fat ${fPct}%`)}
        >
          <span className="h-2 w-2 rounded-full bg-rose-400" /> <span className="text-zinc-400">F</span>
        </span>
      </div>
      <p className="text-[10px] text-zinc-500 mt-1 h-3">{hover || ''}</p>
    </div>
  );
}

function MicroBar({
  label,
  value,
  unit,
  pct,
  pctRaw,
  upperLimit,
}: {
  label: string;
  value: number;
  unit: string;
  pct: number;
  pctRaw: number;
  upperLimit?: boolean;
}) {
  // For an upper-limit nutrient (sodium), high fill = bad. Otherwise high
  // fill = good.
  let barColor = 'bg-emerald-500';
  let textColor = 'text-emerald-300';
  if (upperLimit) {
    if (pctRaw >= 50) {
      barColor = 'bg-red-500';
      textColor = 'text-red-300';
    } else if (pctRaw >= 25) {
      barColor = 'bg-amber-500';
      textColor = 'text-amber-300';
    } else {
      barColor = 'bg-zinc-600';
      textColor = 'text-zinc-300';
    }
  } else if (pctRaw < 15) {
    barColor = 'bg-zinc-600';
    textColor = 'text-zinc-400';
  }
  const displayed = formatMicroValue(value, unit);
  const label2 = upperLimit ? 'of upper limit' : 'of daily value';
  return (
    <div className="rounded-lg border border-zinc-800 bg-zinc-950 p-3" title={`${displayed} ${unit}. ${Math.round(pctRaw)}% ${label2}.`}>
      <div className="flex items-baseline justify-between gap-2">
        <p className="text-xs text-zinc-300 truncate">{label}</p>
        <p className="text-[11px] font-mono text-zinc-500 tabular-nums">
          {displayed}
          <span className="ml-0.5">{unit}</span>
        </p>
      </div>
      <div className="mt-1.5 h-1.5 rounded-full bg-zinc-800 overflow-hidden">
        <div className={`h-full ${barColor} transition-all`} style={{ width: `${pct}%` }} />
      </div>
      <p className={`text-[10px] mt-1 ${textColor} tabular-nums`}>
        {Math.round(pctRaw)}% {label2}
      </p>
    </div>
  );
}

function GlBadge({ value }: { value: number | null }) {
  if (value === null || value === undefined) {
    return <span className="text-xs text-zinc-600">—</span>;
  }
  const tone =
    value < 10
      ? 'bg-emerald-500/15 text-emerald-300 border-emerald-500/30'
      : value < 20
      ? 'bg-amber-500/15 text-amber-300 border-amber-500/30'
      : 'bg-red-500/15 text-red-300 border-red-500/30';
  const label = value < 10 ? 'Low GL' : value < 20 ? 'Med GL' : 'High GL';
  return (
    <span
      className={`inline-flex items-center justify-center rounded-md border px-1.5 py-0.5 text-[10px] font-bold ${tone}`}
      title={`${label}. Glycemic load ${value}.`}
    >
      {value}
    </span>
  );
}

function formatConfidence(c: FoodItem['confidence']): string {
  if (typeof c === 'number') return `${Math.round(c * 100)}%`;
  return c.charAt(0).toUpperCase() + c.slice(1);
}

function formatMicroValue(value: number, unit: string): string {
  // Show 1 decimal for grams and very small numbers; integer otherwise.
  if (unit === 'g' || value < 10) {
    return value.toFixed(1);
  }
  return Math.round(value).toString();
}

function RateLimitCard({ err }: { err: RateLimitError }) {
  const resetCopy = err.resetsAtIso ? formatReset(err.resetsAtIso) : 'tomorrow';
  return (
    <section className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-br from-amber-500/10 to-emerald-500/5 p-6 sm:p-8">
      <div className="flex flex-wrap items-start gap-4">
        <div className="flex-1 min-w-[220px]">
          <h2 className="text-xl font-bold text-white mb-1">Daily limit reached.</h2>
          <p className="text-sm text-zinc-300">
            You've used both free scans today. Resets {resetCopy}.
          </p>
          <p className="text-sm text-zinc-300 mt-3">
            Get unlimited food scans in Zealova. Plus history, macros to your daily target, and AI feedback on every meal.
          </p>
        </div>
      </div>
      <a
        href={PLAY_STORE}
        className="mt-5 inline-flex items-center gap-2 px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-bold hover:bg-emerald-400 transition shadow-xl shadow-emerald-500/30"
      >
        Get Zealova on Google Play
      </a>
    </section>
  );
}

function formatReset(iso: string): string {
  try {
    const d = new Date(iso);
    const hours = Math.max(1, Math.round((d.getTime() - Date.now()) / 3600000));
    return `in about ${hours} hour${hours === 1 ? '' : 's'}`;
  } catch {
    return 'tomorrow';
  }
}
