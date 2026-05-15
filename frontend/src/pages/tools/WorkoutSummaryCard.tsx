// /free-tools/workout-summary-card
//
// 1080×1920 vertical share card summarizing a single workout.
// Hero volume number + 3 top lifts + duration + notes.

import { useEffect, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import TagUsNudge from '../../components/tools/TagUsNudge';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type DownloadFormat = 'png' | 'jpeg' | 'webp';
type Unit = 'lb' | 'kg';

const FORMAT_INFO: Record<DownloadFormat, { mime: string; ext: string; label: string }> = {
  png: { mime: 'image/png', ext: 'png', label: 'PNG (lossless, larger file)' },
  jpeg: { mime: 'image/jpeg', ext: 'jpg', label: 'JPG (smaller, social-friendly)' },
  webp: { mime: 'image/webp', ext: 'webp', label: 'WebP (smallest, modern browsers)' },
};

interface Lift { name: string; weight: string; reps: string; }

export default function WorkoutSummaryCard() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const [date, setDate] = useState(() => new Date().toISOString().slice(0, 10));
  const [duration, setDuration] = useState('62');
  const [volume, setVolume] = useState('18450');
  const [unit, setUnit] = useState<Unit>('lb');
  const [lifts, setLifts] = useState<Lift[]>([
    { name: 'Squat', weight: '315', reps: '5' },
    { name: 'Bench Press', weight: '225', reps: '5' },
    { name: 'Barbell Row', weight: '185', reps: '8' },
  ]);
  const [notes, setNotes] = useState('');
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('jpeg');

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => { logoRef.current = img; setNotes((n) => n); };
  }, []);

  const updateLift = (i: number, key: keyof Lift, value: string) => {
    setLifts((ls) => ls.map((l, idx) => idx === i ? { ...l, [key]: value } : l));
  };

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const W = 1080;
    const H = 1920;
    canvas.width = W;
    canvas.height = H;

    // Background gradient
    const grad = ctx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, '#064e3b');
    grad.addColorStop(0.4, '#0a0a0a');
    grad.addColorStop(1, '#0a0a0a');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Subtle grid pattern
    ctx.strokeStyle = 'rgba(255,255,255,0.03)';
    ctx.lineWidth = 1;
    for (let i = 0; i < W; i += 60) {
      ctx.beginPath();
      ctx.moveTo(i, 0);
      ctx.lineTo(i, H);
      ctx.stroke();
    }
    for (let i = 0; i < H; i += 60) {
      ctx.beginPath();
      ctx.moveTo(0, i);
      ctx.lineTo(W, i);
      ctx.stroke();
    }

    // Header
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillStyle = 'rgba(16,185,129,0.9)';
    ctx.font = `700 32px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('WORKOUT SUMMARY', W / 2, 140);

    // Date
    const dateDisplay = date ? new Date(date).toLocaleDateString('en-US', { weekday: 'long', month: 'long', day: 'numeric' }) : '';
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.font = `500 28px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText(dateDisplay, W / 2, 195);

    // Hero — total volume
    const volNum = parseFloat(volume) || 0;
    ctx.fillStyle = '#ffffff';
    ctx.font = `900 180px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText(formatNumber(volNum), W / 2, 320);

    ctx.fillStyle = '#10b981';
    ctx.font = `700 44px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText(`${unit} TOTAL VOLUME`, W / 2, 530);

    // Duration row
    const durNum = parseInt(duration) || 0;
    const statRowY = 660;
    drawStatBlock(ctx, W / 2, statRowY, `${durNum}`, 'MINUTES');

    // Top lifts label
    ctx.fillStyle = 'rgba(16,185,129,0.9)';
    ctx.font = `700 30px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('TOP LIFTS', W / 2, 880);

    // Lifts grid
    let liftY = 950;
    lifts.forEach((lift, i) => {
      if (!lift.name && !lift.weight) return;
      const bgY = liftY;
      const bgH = 150;
      ctx.fillStyle = 'rgba(16,185,129,0.08)';
      roundedRect(ctx, 80, bgY, W - 160, bgH, 24);
      ctx.fill();
      ctx.strokeStyle = 'rgba(16,185,129,0.2)';
      ctx.lineWidth = 1;
      ctx.stroke();

      // Number badge
      ctx.fillStyle = '#10b981';
      ctx.beginPath();
      ctx.arc(140, bgY + bgH / 2, 32, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = '#0a0a0a';
      ctx.font = `900 36px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.textBaseline = 'middle';
      ctx.fillText(`${i + 1}`, 140, bgY + bgH / 2 + 2);

      // Lift name
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      ctx.fillStyle = '#ffffff';
      ctx.font = `700 42px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(lift.name || 'Lift', 200, bgY + bgH / 2 - 18);

      ctx.fillStyle = 'rgba(255,255,255,0.65)';
      ctx.font = `600 30px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(`${lift.weight || '0'}${unit} × ${lift.reps || '0'}`, 200, bgY + bgH / 2 + 28);

      ctx.textAlign = 'center';
      liftY += bgH + 24;
    });

    // Notes
    if (notes.trim()) {
      const noteY = Math.max(liftY + 40, 1500);
      ctx.fillStyle = 'rgba(255,255,255,0.85)';
      ctx.font = `italic 500 32px Georgia, serif`;
      ctx.textBaseline = 'top';
      wrapText(ctx, `"${notes.trim()}"`, W / 2, noteY, W - 160, 44);
    }

    drawWatermark(ctx, W, H, logoRef.current);
    ctx.textAlign = 'left';
  }, [date, duration, volume, unit, lifts, notes]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `zealova-workout-summary-${Date.now()}.${fmt.ext}`;
      a.click();
      URL.revokeObjectURL(url);
    }, fmt.mime, 0.92);
  };

  return (
    <CalculatorShell
      slug="workout-summary-card"
      title="Workout Summary Card Generator"
      metaDescription="Free workout summary card generator. 1080×1920 vertical share card with total volume, top 3 lifts, and duration. JPG, PNG, WebP. No sign-up."
      intro="Fill in the workout. Get a TikTok and Reels ready 9:16 card with your total volume as the hero number, your top 3 lifts, and your duration. Made for the post-workout flex."
      faqs={[
        { q: 'What is total volume?', a: 'Sets × reps × weight summed across the whole workout. It is the most-shared single-number summary of training load.' },
        { q: 'Why 9:16 vertical?', a: 'Matches Instagram Reels, TikTok, YouTube Shorts, and IG Stories. Posts there get more views than feed photos in 2026.' },
        { q: 'Can I share more than 3 lifts?', a: 'Three keeps the card readable on a phone. If your top 3 lifts represent the workout, you have a strong card.' },
        { q: 'Is anything uploaded?', a: 'No. The card renders in your browser. Nothing leaves your device.' },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
        <h2 className="text-base font-bold text-white">Workout details</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="block">
            <span className="text-xs text-zinc-400">Date</span>
            <input type="date" value={date} onChange={(e) => setDate(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Duration (minutes)</span>
            <input type="number" value={duration} onChange={(e) => setDuration(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Total volume</span>
            <div className="mt-1 flex gap-2">
              <input type="number" value={volume} onChange={(e) => setVolume(e.target.value)}
                className="flex-1 px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
                {(['lb', 'kg'] as Unit[]).map((u) => (
                  <button key={u} type="button" onClick={() => setUnit(u)}
                    className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${unit === u ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'}`}>{u}</button>
                ))}
              </div>
            </div>
          </label>
        </div>

        <h3 className="text-sm font-semibold text-white pt-2">Top 3 lifts</h3>
        <div className="space-y-2">
          {lifts.map((l, i) => (
            <div key={i} className="grid grid-cols-3 gap-2">
              <input value={l.name} onChange={(e) => updateLift(i, 'name', e.target.value)} placeholder={`Lift ${i + 1}`}
                className="px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <input value={l.weight} onChange={(e) => updateLift(i, 'weight', e.target.value)} placeholder="Weight" type="number"
                className="px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <input value={l.reps} onChange={(e) => updateLift(i, 'reps', e.target.value)} placeholder="Reps" type="number"
                className="px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            </div>
          ))}
        </div>

        <label className="block">
          <span className="text-xs text-zinc-400">Notes (optional, italicized)</span>
          <input value={notes} onChange={(e) => setNotes(e.target.value)} placeholder="e.g. Felt smooth, RPE 7 across"
            className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
        </label>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-3">Preview</h2>
        <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-4 overflow-x-auto">
          <canvas ref={canvasRef} className="w-full max-w-sm h-auto rounded-xl mx-auto block" style={{ maxHeight: '80vh' }} />
        </div>
      </section>

      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-6">
        <h2 className="text-base font-bold text-white mb-3">Download</h2>
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
        <p className="text-xs text-zinc-500 mt-3">{FORMAT_INFO[downloadFormat].label} at 1080×1920</p>
      </section>

      <InstallCta
        slug="workout-summary-card"
        primary="Get this auto-generated after every workout in Zealova"
        secondary="Zealova totals your volume, picks your top lifts, and produces this card the moment you finish. No filling in numbers."
      />

      <MethodologyFooter
        citations={[
          { text: '1080×1920 (9:16) is the native upload size for Instagram Reels, TikTok, and YouTube Shorts.' },
          { text: 'Volume (sets × reps × weight) is the standard training-load summary used across the strength and hypertrophy literature.' },
        ]}
        lastUpdated="2026-05-14"
      />
    <TagUsNudge />
    </CalculatorShell>
  );
}

function drawStatBlock(ctx: CanvasRenderingContext2D, cx: number, y: number, value: string, label: string) {
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillStyle = '#ffffff';
  ctx.font = `900 96px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.fillText(value, cx, y);
  ctx.fillStyle = 'rgba(255,255,255,0.6)';
  ctx.font = `700 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.fillText(label, cx, y + 120);
}

function formatNumber(n: number): string {
  if (n >= 1000) return n.toLocaleString('en-US');
  return `${n}`;
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
  const wmHeight = canvasH * 0.03;
  const wmFontSize = wmHeight * 0.55;
  ctx.font = `700 ${wmFontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.textAlign = 'left';
  ctx.textBaseline = 'alphabetic';
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
