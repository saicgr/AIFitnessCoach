// /free-tools/lifter-personality-quiz
//
// 10-question multiple-choice quiz. Maps answers to 8 archetypes by tallying
// per-archetype scores from each option. Renders a shareable result card.

import { useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type DownloadFormat = 'png' | 'jpeg' | 'webp';

const FORMAT_INFO: Record<DownloadFormat, { mime: string; ext: string; label: string }> = {
  png: { mime: 'image/png', ext: 'png', label: 'PNG (lossless, larger file)' },
  jpeg: { mime: 'image/jpeg', ext: 'jpg', label: 'JPG (smaller, social-friendly)' },
  webp: { mime: 'image/webp', ext: 'webp', label: 'WebP (smallest, modern browsers)' },
};

type Archetype =
  | 'PowerPrincess'
  | 'VolumeGoblin'
  | 'FormNerd'
  | 'CardioBunny'
  | 'Hybrid'
  | 'MobilityMonk'
  | 'Aesthetic'
  | 'Functional';

interface ArchetypeMeta {
  title: string;
  emoji: string;
  color: string;
  traits: string[];
  split: string;
  blurb: string;
}

const META: Record<Archetype, ArchetypeMeta> = {
  PowerPrincess: {
    title: 'The Power Princess',
    emoji: '👑',
    color: '#a855f7',
    traits: ['Lives for the heavy single', 'PR videos in the camera roll', 'Low reps, big intent'],
    split: 'Conjugate or 5/3/1 BBB. Squat, bench, deadlift, press, 4 days.',
    blurb: 'Strength is the metric. Everything else is accessory work.',
  },
  VolumeGoblin: {
    title: 'The Volume Goblin',
    emoji: '🔥',
    color: '#f97316',
    traits: ['Lives in the 8 to 15 rep range', 'Drop sets, rest-pause, myo-reps', 'The pump is the point'],
    split: 'Upper / Lower 4-day or Push / Pull / Legs 6-day. High volume, moderate intensity.',
    blurb: 'You measure workouts in sets, not singles. The pump tells the truth.',
  },
  FormNerd: {
    title: 'The Form Nerd',
    emoji: '🧠',
    color: '#3b82f6',
    traits: ['RPE-based, RIR-tracked', 'Owns a tempo app', 'Filmed your last 10 working sets'],
    split: 'Auto-regulated 4-day. 60-80% with RPE 7-8 caps. Deload every 5th week.',
    blurb: 'Technique is the program. Load is downstream of mechanics.',
  },
  CardioBunny: {
    title: 'The Cardio Bunny',
    emoji: '🏃',
    color: '#ec4899',
    traits: ['Zone 2 enjoyer', 'Half-marathon medal collection', 'Lifting is for injury prevention'],
    split: '4-5 cardio sessions plus 2 short full-body lift days. Sub-30-min sessions.',
    blurb: 'You measure the week in miles, not pounds. The lift is a supplement.',
  },
  Hybrid: {
    title: 'The Hybrid Athlete',
    emoji: '⚡',
    color: '#10b981',
    traits: ['405 deadlift and a sub-22 5k', 'Trains 6 days, never burns out', 'Owns a bike and a barbell'],
    split: 'Strength 4 days + Z2 cardio 3 days + 1 hard interval session. Modeled on Nick Bare protocols.',
    blurb: 'You refuse to pick. Strength and endurance, both compounded.',
  },
  MobilityMonk: {
    title: 'The Mobility Monk',
    emoji: '🧘',
    color: '#14b8a6',
    traits: ['Pancake stretch in the warm-up', 'Handstand-curious', 'Foam roller in the gym bag'],
    split: 'Calisthenics + GMB + yoga 5 days. Strength via gymnastic rings and weighted carries.',
    blurb: 'You train to move, not just to lift. The body is the apparatus.',
  },
  Aesthetic: {
    title: 'The Aesthetic Architect',
    emoji: '💎',
    color: '#fbbf24',
    traits: ['Bro split believer', 'Mirror is a tool, not a vice', 'Cuts and bulks on schedule'],
    split: 'Classic Bro split. Chest / Back / Legs / Shoulders / Arms. 5 days, hypertrophy rep ranges.',
    blurb: 'The mirror is the scoreboard. Symmetry, separation, balance.',
  },
  Functional: {
    title: 'The Functional Fitness Fanatic',
    emoji: '🏋️',
    color: '#ef4444',
    traits: ['Knows their Fran time', 'Owns a rope, rings, and a sled', 'Conditioning > everything'],
    split: 'CrossFit-style mixed modal. 5 days of WODs, 1 strength bias day, 1 active recovery.',
    blurb: 'Strength, speed, work capacity, all measured. AMRAP is a lifestyle.',
  },
};

interface QuizOption { label: string; weights: Partial<Record<Archetype, number>>; }
interface Question { id: number; q: string; options: QuizOption[]; }

const QUESTIONS: Question[] = [
  { id: 1, q: 'How do you feel about the 1-rep max?',
    options: [
      { label: 'My favorite part of the week.', weights: { PowerPrincess: 3, Aesthetic: 0 } },
      { label: 'Fun occasionally, not a goal.', weights: { FormNerd: 2, Hybrid: 2 } },
      { label: 'I avoid it. Tweaks happen.', weights: { VolumeGoblin: 2, MobilityMonk: 2 } },
      { label: 'What is a 1-rep max?', weights: { CardioBunny: 3, Functional: 1 } },
    ] },
  { id: 2, q: 'Pick your ideal rep range.',
    options: [
      { label: '1-3 reps, heavy intent.', weights: { PowerPrincess: 3 } },
      { label: '5-8 reps, controlled tempo.', weights: { FormNerd: 2, Hybrid: 1 } },
      { label: '10-15 reps, chase the pump.', weights: { VolumeGoblin: 3, Aesthetic: 2 } },
      { label: 'AMRAP, mixed modal.', weights: { Functional: 3, Hybrid: 1 } },
    ] },
  { id: 3, q: 'Your warm-up is mostly:',
    options: [
      { label: 'Bar work and ramp-up sets.', weights: { PowerPrincess: 2, FormNerd: 1 } },
      { label: '15 minutes of mobility flow.', weights: { MobilityMonk: 3 } },
      { label: 'Zone 2 jog.', weights: { CardioBunny: 2, Hybrid: 2 } },
      { label: 'Skipping rope and burgener.', weights: { Functional: 3 } },
    ] },
  { id: 4, q: 'How much cardio per week?',
    options: [
      { label: 'None. Cardio steals gains.', weights: { PowerPrincess: 2, Aesthetic: 2 } },
      { label: 'Daily Z2, plus intervals.', weights: { CardioBunny: 3, Hybrid: 2 } },
      { label: 'Built into WODs.', weights: { Functional: 3 } },
      { label: 'Long walks and yoga flows.', weights: { MobilityMonk: 2, FormNerd: 1 } },
    ] },
  { id: 5, q: 'When you log a set, what matters most?',
    options: [
      { label: 'The weight on the bar.', weights: { PowerPrincess: 3, Aesthetic: 1 } },
      { label: 'The RPE / RIR.', weights: { FormNerd: 3 } },
      { label: 'The pump felt.', weights: { VolumeGoblin: 3, Aesthetic: 1 } },
      { label: 'The time it took.', weights: { Functional: 2, CardioBunny: 1 } },
    ] },
  { id: 6, q: 'Pick a body part day you most enjoy.',
    options: [
      { label: 'Squat day, period.', weights: { PowerPrincess: 2, Aesthetic: 1 } },
      { label: 'Arms and shoulders.', weights: { Aesthetic: 3, VolumeGoblin: 2 } },
      { label: 'Mobility + skills.', weights: { MobilityMonk: 3 } },
      { label: 'Conditioning and metcon.', weights: { Functional: 3, Hybrid: 1 } },
    ] },
  { id: 7, q: 'Food philosophy?',
    options: [
      { label: 'High protein, count macros.', weights: { Aesthetic: 3, FormNerd: 1 } },
      { label: 'Carb-heavy, fuel the work.', weights: { CardioBunny: 2, Hybrid: 2, Functional: 2 } },
      { label: 'Whatever fits the day.', weights: { VolumeGoblin: 2, PowerPrincess: 2 } },
      { label: 'Intuitive eating, mostly whole.', weights: { MobilityMonk: 3 } },
    ] },
  { id: 8, q: 'How do you pick exercises?',
    options: [
      { label: 'Big 4. Squat, bench, DL, press.', weights: { PowerPrincess: 3 } },
      { label: 'Whatever isolates the muscle best.', weights: { VolumeGoblin: 2, Aesthetic: 3 } },
      { label: 'Programmed by a coach app.', weights: { FormNerd: 2, Hybrid: 2 } },
      { label: 'Functional, multi-joint movements.', weights: { Functional: 3, MobilityMonk: 1 } },
    ] },
  { id: 9, q: 'Pick your gym soundtrack.',
    options: [
      { label: 'Heavy metal or hardstyle.', weights: { PowerPrincess: 3 } },
      { label: 'Hip-hop bangers.', weights: { VolumeGoblin: 2, Aesthetic: 2 } },
      { label: 'Podcasts and lo-fi.', weights: { CardioBunny: 2, FormNerd: 2, MobilityMonk: 2 } },
      { label: 'WOD timer beep.', weights: { Functional: 3 } },
    ] },
  { id: 10, q: 'The reason you train.',
    options: [
      { label: 'To be undeniably strong.', weights: { PowerPrincess: 3, Functional: 1 } },
      { label: 'To look like the goal.', weights: { Aesthetic: 3, VolumeGoblin: 1 } },
      { label: 'To live longer, move better.', weights: { MobilityMonk: 2, CardioBunny: 2, Hybrid: 2 } },
      { label: 'To master my body.', weights: { FormNerd: 2, MobilityMonk: 2, Functional: 1 } },
    ] },
];

export default function LifterPersonalityQuiz() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const [answers, setAnswers] = useState<Record<number, number>>({});
  const [name, setName] = useState('');
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('jpeg');

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => { logoRef.current = img; setName((n) => n); };
  }, []);

  const allAnswered = QUESTIONS.every((q) => answers[q.id] !== undefined);

  const result: Archetype | null = useMemo(() => {
    if (!allAnswered) return null;
    const tally: Record<string, number> = {};
    for (const q of QUESTIONS) {
      const choice = q.options[answers[q.id]];
      if (!choice) continue;
      for (const [arch, weight] of Object.entries(choice.weights)) {
        tally[arch] = (tally[arch] || 0) + (weight || 0);
      }
    }
    let best: Archetype = 'Hybrid';
    let bestScore = -1;
    for (const [arch, score] of Object.entries(tally)) {
      if (score > bestScore) { bestScore = score; best = arch as Archetype; }
    }
    return best;
  }, [answers, allAnswered]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || !result) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const meta = META[result];
    const W = 1080;
    const H = 1350;
    canvas.width = W;
    canvas.height = H;

    // Background gradient using archetype color
    const grad = ctx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, meta.color);
    grad.addColorStop(0.45, hexWithAlpha(meta.color, 0.25));
    grad.addColorStop(1, '#0a0a0a');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Subtle noise overlay
    ctx.fillStyle = 'rgba(0,0,0,0.25)';
    ctx.fillRect(0, H * 0.5, W, H * 0.5);

    // Header
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillStyle = 'rgba(255,255,255,0.75)';
    ctx.font = `700 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('YOUR LIFTER PERSONALITY', W / 2, 100);

    // Emoji
    ctx.font = `160px Apple Color Emoji, "Segoe UI Emoji", sans-serif`;
    ctx.fillText(meta.emoji, W / 2, 150);

    // Title
    ctx.fillStyle = '#ffffff';
    ctx.font = `900 78px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText(meta.title, W / 2, 340);

    // Name pill
    if (name.trim()) {
      const nameText = name.trim().toUpperCase();
      ctx.font = `700 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      const m = ctx.measureText(nameText).width;
      const padX = 22, padY = 12;
      const pillW = m + padX * 2;
      const pillH = 26 + padY * 2;
      const pillX = W / 2 - pillW / 2;
      const pillY = 445;
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      roundedRect(ctx, pillX, pillY, pillW, pillH, pillH / 2);
      ctx.fill();
      ctx.fillStyle = '#ffffff';
      ctx.textBaseline = 'middle';
      ctx.fillText(nameText, W / 2, pillY + pillH / 2);
      ctx.textBaseline = 'top';
    }

    // Blurb
    ctx.fillStyle = 'rgba(255,255,255,0.95)';
    ctx.font = `italic 600 32px Georgia, serif`;
    wrapText(ctx, meta.blurb, W / 2, 540, W - 140, 44);

    // Traits header
    ctx.fillStyle = '#ffffff';
    ctx.font = `700 28px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('CORE TRAITS', W / 2, 730);

    // Traits list
    let traitY = 780;
    meta.traits.forEach((t) => {
      ctx.textAlign = 'left';
      ctx.fillStyle = 'rgba(255,255,255,0.06)';
      roundedRect(ctx, 90, traitY, W - 180, 76, 18);
      ctx.fill();
      // Dot
      ctx.fillStyle = meta.color;
      ctx.beginPath();
      ctx.arc(130, traitY + 38, 9, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#ffffff';
      ctx.font = `600 28px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.textBaseline = 'middle';
      ctx.fillText(t, 160, traitY + 38);
      ctx.textBaseline = 'top';
      ctx.textAlign = 'center';
      traitY += 88;
    });

    // Split
    ctx.fillStyle = meta.color;
    ctx.font = `700 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('RECOMMENDED SPLIT', W / 2, traitY + 30);
    ctx.fillStyle = 'rgba(255,255,255,0.9)';
    ctx.font = `500 24px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    wrapText(ctx, meta.split, W / 2, traitY + 75, W - 140, 34);

    drawWatermark(ctx, W, H, logoRef.current);
    ctx.textAlign = 'left';
  }, [result, name]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `zealova-lifter-personality-${Date.now()}.${fmt.ext}`;
      a.click();
      URL.revokeObjectURL(url);
    }, fmt.mime, 0.92);
  };

  const reset = () => setAnswers({});

  return (
    <CalculatorShell
      slug="lifter-personality-quiz"
      title="Lifter Personality Quiz"
      metaDescription="Free 10-question lifter personality quiz. Map your training style to 1 of 8 archetypes. Download a share card with your result, traits, and recommended split."
      intro="Ten questions. Eight archetypes. One share card with your training personality, three traits, and a recommended split. Built for the post-quiz screenshot."
      faqs={[
        { q: 'Is this scientific?', a: 'No. It is a typology, not a diagnosis. The mapping is calibrated to common training-style clusters seen in gym surveys and coaching practice.' },
        { q: 'Can I retake it?', a: 'Yes. Tap reset at the bottom. Your archetype updates as you change answers.' },
        { q: 'What if I am between two?', a: 'The Hybrid Athlete archetype exists for exactly that case. Many lifters fall there.' },
        { q: 'Is anything uploaded?', a: 'No. Quiz answers and the result card render in your browser.' },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
        <h2 className="text-base font-bold text-white">Your name (optional, shown on card)</h2>
        <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Alex"
          className="w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
      </section>

      <section className="space-y-4">
        {QUESTIONS.map((q, qIdx) => (
          <div key={q.id} className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
            <h3 className="text-sm font-semibold text-emerald-400 mb-1">Question {qIdx + 1} of {QUESTIONS.length}</h3>
            <p className="text-base font-bold text-white mb-3">{q.q}</p>
            <div className="space-y-2">
              {q.options.map((opt, optIdx) => {
                const selected = answers[q.id] === optIdx;
                return (
                  <button key={optIdx} type="button"
                    onClick={() => setAnswers({ ...answers, [q.id]: optIdx })}
                    className={`w-full text-left px-4 py-3 rounded-xl border text-sm transition ${selected
                      ? 'bg-emerald-500/10 border-emerald-500 text-white'
                      : 'bg-zinc-950 border-zinc-800 text-zinc-300 hover:border-zinc-700'}`}>
                    {opt.label}
                  </button>
                );
              })}
            </div>
          </div>
        ))}
        {Object.keys(answers).length > 0 && (
          <button type="button" onClick={reset}
            className="text-xs text-zinc-500 hover:text-zinc-300 transition">Reset answers</button>
        )}
      </section>

      {!allAnswered && (
        <section className="bg-zinc-900 border border-dashed border-zinc-800 rounded-2xl p-8 text-center">
          <p className="text-sm text-zinc-400">Answer all {QUESTIONS.length} questions to see your archetype.</p>
          <p className="text-xs text-zinc-600 mt-1">{Object.keys(answers).length} of {QUESTIONS.length} answered.</p>
        </section>
      )}

      {result && (
        <>
          <section>
            <h2 className="text-lg font-bold text-white mb-3">Your result</h2>
            <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-4 overflow-x-auto">
              <canvas ref={canvasRef} className="w-full max-w-md h-auto rounded-xl mx-auto block" style={{ maxHeight: '75vh' }} />
            </div>
          </section>

          <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-6">
            <h2 className="text-base font-bold text-white mb-3">Download share card</h2>
            <div className="flex flex-wrap items-center gap-3">
              <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
                {(Object.keys(FORMAT_INFO) as DownloadFormat[]).map((fmt) => (
                  <button key={fmt} type="button" onClick={() => setDownloadFormat(fmt)}
                    className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${downloadFormat === fmt ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'}`}>
                    {FORMAT_INFO[fmt].ext.toUpperCase()}
                  </button>
                ))}
              </div>
              <button type="button" onClick={handleDownload}
                className="px-5 py-2.5 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20">
                Download
              </button>
            </div>
            <p className="text-xs text-zinc-500 mt-3">{FORMAT_INFO[downloadFormat].label} at 1080×1350</p>
          </section>
        </>
      )}

      <InstallCta
        slug="lifter-personality-quiz"
        primary="Get a training plan matched to your archetype in Zealova"
        secondary="Zealova reads your archetype and generates a personalized split, with progressive overload tuned to your style. PRs included."
        result={result ? { archetype: result } : undefined}
      />

      <MethodologyFooter
        citations={[
          { text: 'Archetypes were calibrated against common training-style clusters in coaching practice, social-fitness surveys, and reddit r/Fitness wikis.' },
          { text: '10 questions chosen as the upper bound for completion in under 90 seconds, based on Typeform completion benchmarks.' },
        ]}
        lastUpdated="2026-05-14"
      />
    </CalculatorShell>
  );
}

function hexWithAlpha(hex: string, alpha: number): string {
  const h = hex.replace('#', '');
  const r = parseInt(h.slice(0, 2), 16);
  const g = parseInt(h.slice(2, 4), 16);
  const b = parseInt(h.slice(4, 6), 16);
  return `rgba(${r}, ${g}, ${b}, ${alpha})`;
}

function wrapText(ctx: CanvasRenderingContext2D, text: string, cx: number, y: number, maxW: number, lineH: number) {
  const words = text.split(' ');
  let line = '';
  let cursorY = y;
  for (const w of words) {
    const test = line ? `${line} ${w}` : w;
    if (ctx.measureText(test).width > maxW && line) {
      ctx.fillText(line, cx, cursorY);
      line = w;
      cursorY += lineH;
    } else {
      line = test;
    }
  }
  if (line) ctx.fillText(line, cx, cursorY);
}

function drawWatermark(ctx: CanvasRenderingContext2D, canvasW: number, canvasH: number, logo: HTMLImageElement | null) {
  const padding = canvasW * 0.025;
  const wmHeight = canvasH * 0.04;
  const wmFontSize = wmHeight * 0.55;
  ctx.font = `700 ${wmFontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.textAlign = 'left';
  const text = 'Made with Zealova';
  const textW = ctx.measureText(text).width;
  const logoSize = wmHeight;
  const gap = wmHeight * 0.25;
  const totalW = (logo ? logoSize + gap : 0) + textW + wmHeight;
  const wmX = canvasW - padding - totalW;
  const wmY = canvasH - padding - wmHeight;
  ctx.fillStyle = 'rgba(0,0,0,0.55)';
  roundedRect(ctx, wmX, wmY, totalW, wmHeight, wmHeight * 0.3);
  ctx.fill();
  let xCursor = wmX + wmHeight * 0.5;
  if (logo) {
    ctx.drawImage(logo, xCursor, wmY + (wmHeight - logoSize * 0.85) / 2, logoSize * 0.85, logoSize * 0.85);
    xCursor += logoSize * 0.85 + gap;
  }
  ctx.fillStyle = '#ffffff';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, xCursor, wmY + wmHeight / 2);
}

function roundedRect(ctx: CanvasRenderingContext2D, x: number, y: number, w: number, h: number, r: number) {
  ctx.beginPath();
  ctx.moveTo(x + r, y);
  ctx.lineTo(x + w - r, y);
  ctx.quadraticCurveTo(x + w, y, x + w, y + r);
  ctx.lineTo(x + w, y + h - r);
  ctx.quadraticCurveTo(x + w, y + h, x + w - r, y + h);
  ctx.lineTo(x + r, y + h);
  ctx.quadraticCurveTo(x, y + h, x, y + h - r);
  ctx.lineTo(x, y + r);
  ctx.quadraticCurveTo(x, y, x + r, y);
  ctx.closePath();
}
