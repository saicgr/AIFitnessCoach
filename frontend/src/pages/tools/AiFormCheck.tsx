// /free-tools/ai-form-check
//
// The flagship "only Zealova can build this" free tool. User picks a lift
// (squat / bench / deadlift), uploads a short video of one set, and the
// backend extracts keyframes, runs Gemini Vision against real coaching
// standards (NSCA / Starting Strength), and returns rep-by-rep form analysis:
// an overall score, per-fault detection with severity, rep count, and 2-3
// concrete fix cues.
//
// Safety: the backend rejects clips where no clear lift is visible with
// actionable filming guidance, and every successful result carries an
// explicit "not a substitute for an in-person coach" disclaimer.

import { useCallback, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import RateLimitModal from '../../components/tools/RateLimitModal';
import EmailCapture from '../../components/tools/EmailCapture';
import MethodologyFooter from '../../components/tools/MethodologyFooter';
import ResultHero from '../../components/tools/ResultHero';
import {
  analyzeFormCheck,
  isRateLimitError,
  type FormCheckExercise,
  type FormCheckResponse,
  type FormFault,
  type RateLimitError,
} from '../../lib/aiToolsClient';

const PLAY_STORE =
  'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dai-form-check';

const EXERCISES: { key: FormCheckExercise; label: string; emoji: string }[] = [
  { key: 'squat', label: 'Squat', emoji: '🦵' },
  { key: 'bench', label: 'Bench Press', emoji: '🛋️' },
  { key: 'deadlift', label: 'Deadlift', emoji: '🏋️' },
];

// Score -> color band. red <50, amber 50-75, green >75.
function scoreBand(score: number): { emphasis: 'rose' | 'amber' | 'emerald'; label: string } {
  if (score < 50) return { emphasis: 'rose', label: 'Needs work — a major fault to fix' };
  if (score <= 75) return { emphasis: 'amber', label: 'Solid base — moderate tweaks to make' };
  return { emphasis: 'emerald', label: 'Strong form — keep it dialed in' };
}

const SEVERITY_STYLE: Record<FormFault['severity'], string> = {
  minor: 'border-sky-500/40 bg-sky-500/10 text-sky-300',
  moderate: 'border-amber-500/40 bg-amber-500/10 text-amber-300',
  major: 'border-rose-500/40 bg-rose-500/10 text-rose-300',
};

export default function AiFormCheck() {
  const [exercise, setExercise] = useState<FormCheckExercise>('squat');
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);
  const [result, setResult] = useState<FormCheckResponse | null>(null);
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
      const data = await analyzeFormCheck(file, exercise);
      setResult(data);
    } catch (e) {
      if (isRateLimitError(e)) {
        setRateLimit(e);
      } else if (e instanceof Error && e.message) {
        // Backend-supplied detail — "we couldn't see a clear lift" filming
        // guidance surfaces here as actionable copy.
        setError(e.message);
      } else {
        setError('Could not analyze that video. Try a clearer clip.');
      }
    } finally {
      setLoading(false);
    }
  };

  return (
    <CalculatorShell
      slug="ai-form-check"
      title="AI Form Check — Squat, Bench, Deadlift Video Analysis"
      metaDescription="Upload a video of your squat, bench, or deadlift. AI extracts keyframes and returns rep-by-rep form analysis: overall score, fault detection, rep count, and concrete fix cues. No sign-up. Free."
      intro="Film one set of your squat, bench press, or deadlift. Our AI extracts keyframes across the lift and analyzes your technique against established coaching standards (NSCA, Starting Strength). You get an overall form score, every fault we can see with a severity rating, a rep count, and 2-3 concrete cues to fix what matters most. No sign-up."
      installPrimary="Get unlimited form checks in Zealova."
      installSecondary="Zealova scores every set you film, tracks your form trend per lift over time, and flags regressions before they cause injury."
      emailCaptureResult={
        result
          ? {
              exercise: result.analysis.exercise,
              overallScore: result.analysis.overall_score,
              repCount: result.analysis.rep_count,
              faultCount: result.analysis.faults.length,
            }
          : undefined
      }
      faqs={[
        {
          q: 'How accurate is the AI form analysis?',
          a: 'The AI reads keyframes sampled across your set and scores them against documented coaching faults (NSCA Essentials of Strength Training, Mark Rippetoe\'s Starting Strength). It is reliable at catching the big, visible faults: knee cave, butt wink, bar path drift, lumbar rounding, elbow flare. It is not a motion-capture system and cannot feel load or measure joint angles to the degree. Treat the score as a directional read, not a verdict.',
        },
        {
          q: 'What kind of video should I record?',
          a: 'Film from the side so the AI can see your full range of motion, with your whole body in frame from head to feet. Good, even lighting. Capture one full set, ideally 3-8 reps. Keep it under 30 seconds and under 50MB. MP4, MOV, or WebM. A front-on or behind angle hides depth and bar path, so the side view matters most.',
        },
        {
          q: 'Is my video stored or kept?',
          a: 'No. The video is processed in memory, keyframes are extracted, those frames are sent to Google Gemini for analysis, and the result is returned to you. The video file is deleted immediately after the request completes. We do not retain the file, do not log video bytes, and do not run third-party trackers on the result.',
        },
        {
          q: 'Which lifts are supported?',
          a: 'The three powerlifting barbell lifts: back squat, bench press, and conventional deadlift. These have the most documented, agreed-upon technical standards, which is what makes reliable AI scoring possible. Accessory and machine lifts are not supported here. The full Zealova app covers far more movements.',
        },
        {
          q: 'How does this compare to a real coach?',
          a: 'An in-person coach watches every rep in real time, feels your load through cues, can adjust your setup hands-on, and knows your injury history. This tool sees a handful of frames. It is excellent for a fast second opinion and for catching faults you cannot see yourself, but it does not replace a coach for a heavy meet prep or a returning injury. A single coaching session runs $50-100; this is free.',
        },
        {
          q: 'Why only 3 checks per day?',
          a: 'Video analysis is the most computationally expensive AI call we run. Each check extracts keyframes and sends multiple images to Gemini Vision. The 3-per-day limit keeps the tool free and fast for everyone. In the Zealova app, form checks are unlimited and your form trend is tracked per lift over time.',
        },
        {
          q: 'Is this medical or injury advice?',
          a: 'No. AI form analysis is a guide, not a substitute for an in-person coach or a medical professional. If you have pain, a current injury, or are returning from one, work with a coach or physical therapist. The disclaimer on every result is there for a reason.',
        },
      ]}
    >
      {/* Disclaimer banner — always visible, not just on result. */}
      <div className="rounded-xl border border-amber-500/30 bg-amber-500/5 px-4 py-2.5 text-xs text-amber-200">
        Free. 3 form checks per day per device. Videos are processed in memory and deleted immediately after analysis. A guide, not a substitute for an in-person coach.
      </div>

      {/* Exercise picker */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">1. Pick your lift</h2>
        <div className="grid grid-cols-3 gap-3">
          {EXERCISES.map((ex) => (
            <button
              key={ex.key}
              type="button"
              onClick={() => setExercise(ex.key)}
              className={`flex flex-col items-center gap-1.5 rounded-xl border-2 py-4 px-2 transition ${
                exercise === ex.key
                  ? 'border-emerald-500 bg-emerald-500/10 text-emerald-200 shadow-lg shadow-emerald-500/10'
                  : 'border-zinc-800 bg-zinc-950 text-zinc-400 hover:border-zinc-700 hover:text-zinc-200'
              }`}
            >
              <span className="text-2xl" aria-hidden>{ex.emoji}</span>
              <span className="text-sm font-semibold">{ex.label}</span>
            </button>
          ))}
        </div>

        {/* Recording tips callout */}
        <div className="mt-5 rounded-xl border border-sky-500/25 bg-sky-500/5 px-4 py-3">
          <p className="text-xs font-semibold uppercase tracking-widest text-sky-300 mb-1.5">
            Recording tips
          </p>
          <ul className="text-xs text-zinc-300 space-y-1">
            <li>• Film from the <strong className="text-white">side</strong>, full body in frame from head to feet.</li>
            <li>• Good, even lighting — avoid backlight and heavy shadows.</li>
            <li>• Capture <strong className="text-white">one full set</strong>, 3-8 reps, under 30 seconds.</li>
            <li>• MP4, MOV, or WebM. Under 50MB.</li>
          </ul>
        </div>
      </section>

      {/* Upload */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 sm:p-8">
        <h2 className="text-lg font-bold text-white mb-4">2. Upload your set</h2>
        <label
          htmlFor="ai-form-check-input"
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
            id="ai-form-check-input"
            type="file"
            accept="video/mp4,video/quicktime,video/webm"
            className="sr-only"
            onChange={(e) => onPick(e.target.files?.[0] ?? null)}
          />
          {preview ? (
            <div className="space-y-3">
              <video
                src={preview}
                controls
                className="max-h-72 mx-auto rounded-lg"
              />
              <p className="text-xs text-zinc-500">Tap to replace</p>
            </div>
          ) : (
            <div className="space-y-1">
              <p className="text-sm text-zinc-300">Tap to upload or drag a video here</p>
              <p className="text-xs text-zinc-500">Side angle, full body, one set. MP4, MOV, or WebM up to 50MB</p>
            </div>
          )}
        </label>

        <button
          type="button"
          onClick={analyze}
          disabled={!file || loading}
          className="mt-5 w-full sm:w-auto px-6 py-3 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20 disabled:bg-zinc-700 disabled:text-zinc-500 disabled:cursor-not-allowed disabled:shadow-none"
        >
          {loading ? 'Analyzing…' : 'Check my form'}
        </button>
      </section>

      {/* Loading skeleton + inline email capture (captive moment — videos take longer). */}
      {loading && (
        <div className="grid gap-3 sm:grid-cols-2">
          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-6 animate-pulse space-y-3">
            <div className="h-4 w-1/3 bg-zinc-800 rounded" />
            <div className="h-4 w-2/3 bg-zinc-800 rounded" />
            <div className="h-4 w-1/2 bg-zinc-800 rounded" />
            <p className="text-xs text-zinc-500 pt-2">
              Extracting keyframes and running Gemini Vision against your reps. Video analysis usually takes 15 to 40 seconds.
            </p>
          </section>
          <EmailCapture
            toolSlug="ai-form-check"
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
        slug="ai-form-check"
        toolName="form check"
        resetWindow="24 hours"
      />

      {/* Error — actionable, NOT generic. */}
      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/5 px-4 py-3 text-sm text-red-300">
          {error}
        </div>
      )}

      {/* Results */}
      {result && <ResultsView result={result} />}

      <MethodologyFooter
        citations={[
          { text: 'Powered by Google Gemini Vision. Free use limited to 3 video checks per IP per 24 hours — video analysis is the most expensive AI call.' },
          { text: 'Form faults and corrective cues scored against NSCA Essentials of Strength Training and Conditioning (4th ed.).', url: 'https://www.nsca.com/store/product-detail/INV/9781492501626/9781492501626' },
          { text: 'Squat, bench, and deadlift technical standards and cues per Mark Rippetoe, Starting Strength (3rd ed.).', url: 'https://startingstrength.com/' },
          { text: 'AI form analysis is a guide, not a substitute for an in-person coach. Confirm with a qualified coach before heavy maxes or when returning from injury.' },
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

function ResultsView({ result }: { result: FormCheckResponse }) {
  const a = result.analysis;
  const band = scoreBand(a.overall_score);

  return (
    <section className="space-y-5">
      {/* Hero — overall score */}
      <div
        className={`relative overflow-hidden rounded-2xl border p-6 sm:p-8 ${
          band.emphasis === 'rose'
            ? 'border-rose-500/30 bg-gradient-to-br from-rose-500/10 via-zinc-900 to-zinc-950'
            : band.emphasis === 'amber'
            ? 'border-amber-500/30 bg-gradient-to-br from-amber-500/10 via-zinc-900 to-zinc-950'
            : 'border-emerald-500/30 bg-gradient-to-br from-emerald-500/10 via-zinc-900 to-zinc-950'
        }`}
      >
        <ResultHero
          label="Overall form score"
          value={a.overall_score}
          suffix="/100"
          decimals={0}
          subLabel={band.label}
          emphasis={band.emphasis}
          size="xl"
        />
        <div className="flex flex-wrap gap-3 justify-center mt-4">
          <Tag label="Lift" value={a.exercise.toUpperCase()} />
          <Tag label="Reps detected" value={String(a.rep_count)} />
          <Tag
            label="Confidence"
            value={a.confidence.toUpperCase()}
            tone={a.confidence === 'low' ? 'amber' : 'emerald'}
          />
        </div>
      </div>

      {/* Disclaimer (in-result) */}
      <p className="text-[11px] text-zinc-500 italic px-1">{result.disclaimer}</p>

      {/* Detected faults */}
      <div className="rounded-2xl border border-zinc-800 bg-zinc-900 p-5 sm:p-6">
        <p className="text-[11px] uppercase tracking-widest text-zinc-500 font-semibold mb-3">
          {a.faults.length === 0 ? 'Form faults' : `Detected faults (${a.faults.length})`}
        </p>
        {a.faults.length === 0 ? (
          <p className="text-sm text-emerald-300">
            No clear faults flagged in these frames. Solid set — film another angle or a heavier load to keep checking.
          </p>
        ) : (
          <ul className="space-y-3">
            {a.faults.map((f, i) => (
              <li
                key={i}
                className="rounded-xl border border-zinc-800 bg-zinc-950 p-4"
              >
                <div className="flex items-center justify-between gap-3 flex-wrap">
                  <span className="text-sm font-bold text-white">{f.name}</span>
                  <span
                    className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-[11px] font-semibold uppercase tracking-wide ${SEVERITY_STYLE[f.severity]}`}
                  >
                    {f.severity}
                  </span>
                </div>
                <p className="text-[11px] uppercase tracking-wider text-zinc-500 mt-1">
                  {f.detected_at}
                </p>
                <p className="text-sm text-zinc-300 mt-1.5 leading-relaxed">
                  {f.explanation}
                </p>
              </li>
            ))}
          </ul>
        )}
      </div>

      {/* Top cues — highlighted box */}
      {a.top_cues.length > 0 && (
        <div className="rounded-2xl border-2 border-emerald-500/40 bg-gradient-to-br from-emerald-500/10 to-zinc-950 p-5 sm:p-6">
          <p className="text-[11px] uppercase tracking-widest text-emerald-300 font-semibold mb-3">
            Fix these first — your top cues
          </p>
          <ul className="space-y-2.5">
            {a.top_cues.map((cue, i) => (
              <li key={i} className="flex items-start gap-3">
                <span className="mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full bg-emerald-500 text-xs font-bold text-zinc-900">
                  {i + 1}
                </span>
                <span className="text-sm text-zinc-100 leading-relaxed">{cue}</span>
              </li>
            ))}
          </ul>
        </div>
      )}
    </section>
  );
}

function Tag({
  label,
  value,
  tone = 'emerald',
}: {
  label: string;
  value: string;
  tone?: 'emerald' | 'amber';
}) {
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

function RateLimitCard({ err }: { err: RateLimitError }) {
  const resetCopy = err.resetsAtIso ? formatReset(err.resetsAtIso) : 'in about a day';
  return (
    <section className="rounded-2xl border-2 border-amber-500/40 bg-gradient-to-br from-amber-500/10 to-emerald-500/5 p-6 sm:p-8">
      <h2 className="text-xl font-bold text-white mb-1">Daily limit reached.</h2>
      <p className="text-sm text-zinc-300">
        You've used your 3 free form checks today. Resets {resetCopy}.
      </p>
      <p className="text-sm text-zinc-300 mt-3">
        Get unlimited form checks in Zealova. The app scores every set you film, tracks your form trend per lift over time, and flags regressions before they cause injury.
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
    if (hours < 24) return `in about ${hours} hour${hours === 1 ? '' : 's'}`;
    return 'in about a day';
  } catch {
    return 'in about a day';
  }
}
