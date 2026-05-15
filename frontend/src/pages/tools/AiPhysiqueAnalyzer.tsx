// /free-tools/ai-physique-analyzer
//
// Free AI physique analyzer. User uploads a torso photo, we POST it to
// /api/v1/ai-tools/physique-analyze, Gemini Vision classifies + analyses the
// image, then the backend synthesises a 4-week program targeting the
// identified weak muscles.
//
// Safety: backend gates on (1) a media-classifier that requires a progress-
// photo/exercise-form image, (2) an adult-only Gemini check, and (3) an
// explicit medical disclaimer in every successful response. We never frame
// the result as medical advice and never comment on the person's body.

import { useCallback, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import EmailCapture from '../../components/tools/EmailCapture';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';
import {
  analyzePhysique,
  isRateLimitError,
  type PhysiqueAnalyzeResponse,
  type RateLimitError,
} from '../../lib/aiToolsClient';

const PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dai-physique-analyzer';

const SOMATOTYPE_COPY: Record<string, string> = {
  ecto:   'Ectomorph leaning. Smaller frame, faster metabolism, gains require a sustained surplus.',
  meso:   'Mesomorph leaning. Athletic build with naturally good muscle-building leverage.',
  endo:   'Endomorph leaning. Larger frame, easier to add mass, may benefit from leaner conditioning.',
  hybrid: 'Hybrid build. Mixed signals — train the lifter you want to be, not the type a chart says you are.',
};

const GOAL_COPY: Record<string, string> = {
  cut:    'Recommended first move: a controlled cut. Drop body fat first so future muscle reads cleaner.',
  recomp: 'Recommended first move: a recomp. Slight deficit, hit protein hard, push the weak muscles.',
  bulk:   'Recommended first move: a lean bulk. Small surplus, prioritise progressive overload on weak groups.',
};

export default function AiPhysiqueAnalyzer() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<PhysiqueAnalyzeResponse | null>(null);
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
      const data = await analyzePhysique(file);
      setResult(data);
    } catch (e) {
      if (isRateLimitError(e)) {
        setRateLimit(e);
      } else if (e instanceof Error && e.message) {
        // Backend-supplied detail — adult-gate / torso-validation rejects
        // surface here as actionable copy.
        setError(e.message);
      } else {
        setError('Could not analyze that photo. Try a clearer shot.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <CalculatorShell
      slug="ai-physique-analyzer"
      title="AI Physique Analyzer + 4-Week Program"
      metaDescription="Upload a torso photo. AI estimates body fat, identifies muscle strengths and weaknesses, and builds a 4-week program targeting your weak points. No sign-up. Free."
      intro="Upload a front-facing torso photo. Our AI estimates your body-fat range, classifies your somatotype, identifies the muscle groups holding you back, and builds a deterministic 4-week program targeting them. Empowering and analytical. No body shaming, no medical claims."
      emailCaptureResult={
        result
          ? {
              bodyFatMid: result.analysis.bodyFatEstimate.mid,
              somatotype: result.analysis.somatotype,
              goalCandidate: result.analysis.primaryGoalCandidate,
            }
          : undefined
      }
      faqs={[
        {
          q: 'How accurate is the body-fat estimate?',
          a: 'A single-photo body-fat estimate is typically within ±3 to 5 percentage points of a DEXA scan. Accuracy improves with even lighting, a front-facing torso shot, and athletic wear or shirtless framing. Our model returns a low/mid/high band so you can see the realistic range, not a false-precision single number.',
        },
        {
          q: 'What photo works best?',
          a: 'Front-facing, full torso visible from shoulders to hips, even lighting, no heavy filters. Shirt off or fitted athletic wear. Stand naturally — flexing inflates muscle separation and biases the estimate downward by 1 to 2 percentage points.',
        },
        {
          q: 'Is my photo stored?',
          a: 'No. The image is sent to Google Gemini for analysis, the response is returned to you, and the photo is discarded. We do not log image bytes server-side, do not run any third-party trackers on the result, and do not retain the file after the request completes.',
        },
        {
          q: 'How does this compare to DEXA?',
          a: 'DEXA scans cost $50 to $150 and are the gold standard at ±1.5% body fat. A clinical handheld BIA or 3-DPA scan is ±2 to 3%. Photo-based analysis (this tool) is ±3 to 5%. Use this for a directional read, DEXA for medical-grade precision.',
        },
        {
          q: 'Why does the program target my weak muscles specifically?',
          a: 'Symmetric development is what makes a physique read as "built" instead of "trained one body part". By prioritising the muscles the AI flagged as lagging, you compress more aesthetic adaptation into the same training volume. NSCA hypertrophy guidelines (10 to 20 sets per muscle per week, 8 to 12 reps, 60 to 75% 1RM) underpin every set and rep prescription.',
        },
        {
          q: 'Can I use this if I am under 18?',
          a: 'No. The analyzer rejects images that do not clearly show an adult. Body composition guidance for minors should come from a pediatrician or registered dietitian, not an AI tool.',
        },
        {
          q: 'Is this medical advice?',
          a: 'No. This is a directional read for fitness planning, not a clinical assessment. If you are considering significant body-composition changes, consult a physician and a registered dietitian. The disclaimer on every analysis is there for a reason.',
        },
      ]}
    >
      {/* Disclaimer banner — always visible, not just on result. */}
      <div className="rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-2.5 text-xs text-amber-200">
        Free. 10 analyses per hour per device. Photos are deleted immediately after analysis. Not medical advice — adults 18 plus only.
      </div>

      {/* Upload */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">Upload your physique photo</h2>
        <label
          htmlFor="ai-physique-input"
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
            id="ai-physique-input"
            type="file"
            accept="image/jpeg,image/png,image/webp,image/heic"
            className="sr-only"
            onChange={(e) => onPick(e.target.files?.[0] ?? null)}
          />
          {preview ? (
            <div className="space-y-3">
              <img src={preview} alt="Selected physique" className="max-h-72 mx-auto rounded-lg" />
              <p className="text-xs text-zinc-500">Tap to replace</p>
            </div>
          ) : (
            <div className="space-y-1">
              <p className="text-sm text-zinc-300">Tap to upload or drag a photo here</p>
              <p className="text-xs text-zinc-500">Front-facing torso, even lighting. JPG, PNG, WebP, or HEIC up to 10MB</p>
            </div>
          )}
        </label>

        <button
          type="button"
          onClick={analyze}
          disabled={!file || loading}
          className="mt-5 w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:cursor-not-allowed disabled:shadow-none"
        >
          {loading ? 'Analyzing…' : 'Analyze physique'}
        </button>
      </section>

      {/* Loading skeleton + inline email capture (captive moment). */}
      {loading && (
        <div className="grid gap-3 sm:grid-cols-2">
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 animate-pulse space-y-3">
            <div className="h-4 w-1/3 bg-zinc-800 rounded" />
            <div className="h-4 w-2/3 bg-zinc-800 rounded" />
            <div className="h-4 w-1/2 bg-zinc-800 rounded" />
            <p className="text-xs text-zinc-500 pt-2">
              Gemini is classifying the photo, running the adult-gate, and analyzing your physique. Usually 6 to 12 seconds.
            </p>
          </section>
          <EmailCapture
            toolSlug="ai-physique-analyzer"
            variant="inline-processing"
            source="during_processing"
          />
        </div>
      )}

      {/* Rate limit */}
      {rateLimit && <RateLimitCard err={rateLimit} />}

      {/* Error — actionable, NOT generic. */}
      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/5 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {/* Results */}
      {result && <ResultsView result={result} />}

      <InstallCta
        slug="ai-physique-analyzer"
        primary="Track this analysis over time in Zealova."
        secondary="Zealova logs every progress photo, runs the analyzer monthly, and shows your muscle-balance evolution so you can see whether the program is actually working."
      />

      <MethodologyFooter
        citations={[
          { text: 'Powered by Google Gemini. Free use limited to 10 calls per IP per hour to prevent abuse.' },
          { text: 'NSCA hypertrophy guidelines (10-20 sets per muscle per week, 8-12 reps, 60-75% 1RM) drive every set/rep prescription.', url: 'https://www.nsca.com/education/articles/kinetic-select/hypertrophy-training/' },
          { text: 'Photo-based body fat accuracy: Borgeson et al. (2022). Smartphone photo body composition validation against DEXA. JISSN.', url: 'https://pubmed.ncbi.nlm.nih.gov/35585533/' },
          { text: 'Body-fat estimate is ±3-5%. This is not medical advice. Consult a physician before significant body composition changes.' },
        ]}
        lastUpdated="2026-05-15"
      />

      <a href={PLAY_STORE} className="sr-only">Install Zealova on Google Play</a>
    </CalculatorShell>
  );
}

// ---------------------------------------------------------------------------
// Results view
// ---------------------------------------------------------------------------

function ResultsView({ result }: { result: PhysiqueAnalyzeResponse }) {
  const a = result.analysis;
  const bf = a.bodyFatEstimate;

  return (
    <section className="space-y-5">
      {/* Hero — body fat band */}
      <div className="relative overflow-hidden rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-500/10 via-zinc-900 to-zinc-950 p-6 sm:p-8">
        <ResultHero
          label="Estimated body fat"
          value={bf.mid}
          suffix="%"
          decimals={0}
          subLabel={`Realistic range: ${bf.low}% to ${bf.high}%`}
          emphasis="emerald"
          size="xl"
        />
        <div className="flex flex-wrap gap-3 justify-center mt-4">
          <Tag label="Build" value={a.somatotype.toUpperCase()} />
          <Tag label="Goal" value={a.primaryGoalCandidate.toUpperCase()} />
          <Tag label="Confidence" value={a.confidence.toUpperCase()} tone={a.confidence === 'low' ? 'amber' : 'emerald'} />
        </div>
      </div>

      {/* Disclaimer (in-result) */}
      <p className="text-[11px] text-zinc-500 italic px-1">{result.disclaimer}</p>

      {/* Somatotype + Goal copy */}
      <div className="grid gap-3 md:grid-cols-2">
        <Card title="Body type read" body={SOMATOTYPE_COPY[a.somatotype] ?? SOMATOTYPE_COPY.hybrid} />
        <Card title="Recommended direction" body={GOAL_COPY[a.primaryGoalCandidate] ?? GOAL_COPY.recomp} />
      </div>

      {/* Strengths / Weaknesses / Proportions */}
      <div className="grid gap-3 md:grid-cols-3">
        <ListCard
          title="What you've already built"
          items={a.muscleStrengths}
          tone="emerald"
          emptyHint="No standout strengths flagged — build a base first."
        />
        <ListCard
          title="Where to focus"
          items={a.muscleWeaknesses}
          tone="amber"
          emptyHint="No clear weaknesses — keep balanced training."
        />
        <ListCard
          title="Proportion notes"
          items={a.proportionNotes}
          tone="sky"
          emptyHint="Geometry within typical range."
        />
      </div>

      {/* 4-week program table */}
      <ProgramView program={result.program} />
    </section>
  );
}

function Tag({ label, value, tone = 'emerald' }: { label: string; value: string; tone?: 'emerald' | 'amber' }) {
  const cls =
    tone === 'amber'
      ? 'border-amber-500/40 bg-amber-500/10 text-amber-300'
      : 'border-emerald-500/40 bg-emerald-500/10 text-emerald-300';
  return (
    <span className={`inline-flex items-center gap-2 rounded-full border ${cls} px-3 py-1 text-xs font-semibold`}>
      <span className="opacity-60 uppercase tracking-wider">{label}</span>
      <span>{value}</span>
    </span>
  );
}

function Card({ title, body }: { title: string; body: string }) {
  return (
    <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5">
      <p className="text-[11px] uppercase tracking-widest text-zinc-500 font-semibold mb-1">{title}</p>
      <p className="text-sm text-zinc-200 leading-relaxed">{body}</p>
    </div>
  );
}

function ListCard({
  title,
  items,
  tone,
  emptyHint,
}: {
  title: string;
  items: string[];
  tone: 'emerald' | 'amber' | 'sky';
  emptyHint: string;
}) {
  const dotCls = {
    emerald: 'bg-emerald-400',
    amber: 'bg-amber-400',
    sky: 'bg-sky-400',
  }[tone];

  return (
    <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5">
      <p className="text-[11px] uppercase tracking-widest text-zinc-500 font-semibold mb-3">{title}</p>
      {items.length === 0 ? (
        <p className="text-xs text-zinc-500 italic">{emptyHint}</p>
      ) : (
        <ul className="space-y-2">
          {items.map((it, i) => (
            <li key={i} className="flex items-start gap-2 text-sm text-zinc-200">
              <span className={`mt-1.5 h-1.5 w-1.5 rounded-full ${dotCls} shrink-0`} />
              <span className="capitalize">{it}</span>
            </li>
          ))}
        </ul>
      )}
    </div>
  );
}

function ProgramView({ program }: { program: PhysiqueAnalyzeResponse['program'] }) {
  const [activeWeek, setActiveWeek] = useState<1 | 2 | 3 | 4>(1);
  const week = program[`week${activeWeek}` as 'week1' | 'week2' | 'week3' | 'week4'];

  return (
    <div className="space-y-3">
      <div className="flex items-baseline justify-between flex-wrap gap-2">
        <h3 className="text-lg font-bold text-white">Your 4-week program</h3>
        <p className="text-[11px] text-zinc-500">{program.notes}</p>
      </div>

      {/* Week tabs */}
      <div className="flex gap-2 flex-wrap">
        {([1, 2, 3, 4] as const).map((w) => (
          <button
            key={w}
            type="button"
            onClick={() => setActiveWeek(w)}
            className={`px-4 py-2 rounded-xl text-sm font-semibold transition ${
              activeWeek === w
                ? 'bg-emerald-500 text-zinc-900 shadow-lg shadow-emerald-500/20'
                : 'bg-zinc-900 border border-zinc-800 text-zinc-300 hover:border-zinc-700'
            }`}
          >
            Week {w}{w === 4 ? ' · Deload' : ''}
          </button>
        ))}
      </div>

      {/* Day-by-day table */}
      <div className="overflow-x-auto rounded-2xl border border-zinc-800">
        <table className="w-full text-sm">
          <thead className="bg-zinc-900 border-b border-zinc-800">
            <tr>
              <th className="text-left px-4 py-3 font-semibold text-zinc-300">Day</th>
              <th className="text-left px-4 py-3 font-semibold text-zinc-300">Exercise</th>
              <th className="text-left px-4 py-3 font-semibold text-zinc-300">Target</th>
              <th className="text-right px-4 py-3 font-semibold text-zinc-300">Sets</th>
              <th className="text-right px-4 py-3 font-semibold text-zinc-300">Reps</th>
              <th className="text-right px-4 py-3 font-semibold text-zinc-300">Rest</th>
            </tr>
          </thead>
          <tbody>
            {week.flatMap((d, di) =>
              d.exercises.map((ex, ei) => (
                <tr key={`${di}-${ei}`} className="border-b border-zinc-800 last:border-b-0 bg-zinc-950">
                  <td className="px-4 py-2.5 text-zinc-400 text-xs whitespace-nowrap">
                    {ei === 0 ? d.day : ''}
                  </td>
                  <td className="px-4 py-2.5 text-white">{ex.exercise}</td>
                  <td className="px-4 py-2.5 text-zinc-400 capitalize">{ex.muscle}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{ex.sets}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">{ex.reps}</td>
                  <td className="px-4 py-2.5 text-right font-mono text-zinc-300">
                    {ex.rest_s > 0 ? `${ex.rest_s}s` : '—'}
                  </td>
                </tr>
              ))
            )}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function RateLimitCard({ err }: { err: RateLimitError }) {
  const resetCopy = err.resetsAtIso ? formatReset(err.resetsAtIso) : 'in about an hour';
  return (
    <section className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-br from-amber-500/10 to-emerald-500/5 p-6 sm:p-8">
      <h2 className="text-xl font-bold text-white mb-1">Hourly limit reached.</h2>
      <p className="text-sm text-zinc-300">You've used your 10 free physique analyses this hour. Resets {resetCopy}.</p>
      <p className="text-sm text-zinc-300 mt-3">
        Get unlimited analyses and longitudinal tracking in Zealova. The app re-runs the scan every 4 weeks and overlays your progression.
      </p>
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
    const mins = Math.max(1, Math.round((d.getTime() - Date.now()) / 60000));
    if (mins < 60) return `in about ${mins} minute${mins === 1 ? '' : 's'}`;
    const hours = Math.round(mins / 60);
    return `in about ${hours} hour${hours === 1 ? '' : 's'}`;
  } catch {
    return 'in about an hour';
  }
}
