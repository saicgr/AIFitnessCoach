// /free-tools/year-in-fitness-wrapped
//
// Spotify-Wrapped-style annual card. 1080×1920. Multi-section, bold gradient.

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

export default function YearInFitnessWrapped() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const year = new Date().getFullYear();
  const [name, setName] = useState('');
  const [totalWorkouts, setTotalWorkouts] = useState('142');
  const [totalMinutes, setTotalMinutes] = useState('8520');
  const [totalVolume, setTotalVolume] = useState('1245000');
  const [unit, setUnit] = useState<Unit>('lb');
  const [weightChange, setWeightChange] = useState('-12');
  const [lifts, setLifts] = useState<Lift[]>([
    { name: 'Squat', weight: '405', reps: '3' },
    { name: 'Deadlift', weight: '495', reps: '1' },
    { name: 'Bench Press', weight: '275', reps: '5' },
  ]);
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('jpeg');

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => { logoRef.current = img; setName((n) => n); };
  }, []);

  const updateLift = (i: number, key: keyof Lift, value: string) =>
    setLifts((ls) => ls.map((l, idx) => idx === i ? { ...l, [key]: value } : l));

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const W = 1080;
    const H = 1920;
    canvas.width = W;
    canvas.height = H;

    // Diagonal multi-band gradient — Wrapped style
    const grad = ctx.createLinearGradient(0, 0, W, H);
    grad.addColorStop(0, '#10b981');
    grad.addColorStop(0.35, '#065f46');
    grad.addColorStop(0.7, '#0a0a0a');
    grad.addColorStop(1, '#000000');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Concentric glow
    const radGrad = ctx.createRadialGradient(W / 2, H * 0.18, 50, W / 2, H * 0.18, W * 0.7);
    radGrad.addColorStop(0, 'rgba(251, 191, 36, 0.35)');
    radGrad.addColorStop(1, 'rgba(251, 191, 36, 0)');
    ctx.fillStyle = radGrad;
    ctx.fillRect(0, 0, W, H);

    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';

    // Header
    ctx.fillStyle = '#ffffff';
    ctx.font = `700 28px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('ZEALOVA WRAPPED', W / 2, 120);

    // Year hero
    ctx.fillStyle = '#fbbf24';
    ctx.font = `900 220px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText(`${year}`, W / 2, 170);

    // Name
    if (name.trim()) {
      ctx.fillStyle = 'rgba(255,255,255,0.85)';
      ctx.font = `600 40px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(name.trim().toUpperCase(), W / 2, 410);
    }

    // Stat block 1 — Workouts
    drawWrappedStat(ctx, W / 2, 510, `${parseInt(totalWorkouts) || 0}`, 'WORKOUTS');

    // Stat block 2 — Minutes
    const mins = parseInt(totalMinutes) || 0;
    const hours = Math.floor(mins / 60);
    drawWrappedStat(ctx, W / 2, 720, `${hours.toLocaleString('en-US')}`, 'HOURS UNDER TENSION');

    // Stat block 3 — Volume
    const volNum = parseInt(totalVolume) || 0;
    const volStr = volNum >= 1000000 ? `${(volNum / 1000000).toFixed(1)}M` : volNum >= 1000 ? `${(volNum / 1000).toFixed(0)}K` : `${volNum}`;
    drawWrappedStat(ctx, W / 2, 930, volStr, `${unit.toUpperCase()} TOTAL VOLUME`);

    // Top lifts section
    ctx.fillStyle = '#fbbf24';
    ctx.font = `700 30px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillText('YOUR HEAVIEST HITS', W / 2, 1170);

    let liftY = 1230;
    lifts.forEach((lift, i) => {
      if (!lift.name && !lift.weight) return;
      ctx.textAlign = 'left';
      ctx.textBaseline = 'middle';
      const rowH = 90;
      ctx.fillStyle = 'rgba(255,255,255,0.08)';
      roundedRect(ctx, 90, liftY, W - 180, rowH, 18);
      ctx.fill();
      ctx.fillStyle = '#fbbf24';
      ctx.font = `900 40px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(`#${i + 1}`, 120, liftY + rowH / 2);
      ctx.fillStyle = '#ffffff';
      ctx.font = `700 38px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(lift.name || 'Lift', 220, liftY + rowH / 2 - 14);
      ctx.fillStyle = 'rgba(255,255,255,0.7)';
      ctx.font = `600 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText(`${lift.weight || '0'}${unit} × ${lift.reps || '0'}`, 220, liftY + rowH / 2 + 22);
      liftY += rowH + 16;
    });

    // Body weight change
    const wc = parseFloat(weightChange);
    if (!isNaN(wc) && wc !== 0) {
      const wcY = 1620;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'top';
      ctx.fillStyle = '#fbbf24';
      ctx.font = `700 28px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      ctx.fillText('BODY WEIGHT', W / 2, wcY);
      ctx.fillStyle = '#ffffff';
      ctx.font = `900 90px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      const sign = wc > 0 ? '+' : '';
      ctx.fillText(`${sign}${wc}${unit}`, W / 2, wcY + 40);
    }

    // Bottom tagline
    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.font = `600 22px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillText('THE ONLY YEAR-IN-REVIEW THAT LIFTS BACK', W / 2, 1810);

    drawWatermark(ctx, W, H, logoRef.current);
    ctx.textAlign = 'left';
  }, [name, totalWorkouts, totalMinutes, totalVolume, unit, weightChange, lifts, year]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `zealova-wrapped-${year}-${Date.now()}.${fmt.ext}`;
      a.click();
      URL.revokeObjectURL(url);
    }, fmt.mime, 0.92);
  };

  return (
    <CalculatorShell
      slug="year-in-fitness-wrapped"
      title="Year in Fitness Wrapped Preview"
      metaDescription="Free year-in-fitness Wrapped card generator. Spotify-Wrapped style annual stats with top lifts, total volume, and body weight change. JPG, PNG, WebP. No sign-up."
      intro="Your fitness year, condensed into one shareable card. Spotify-Wrapped style. Total workouts, hours, volume, top 3 lifts, body weight change. Drop the numbers, get the card."
      faqs={[
        { q: 'Where do I get my year stats?', a: 'If you train inside Zealova, your real Wrapped is auto-generated. This page is a manual version anyone can use, even from another tracker.' },
        { q: 'What if I do not lift weights?', a: 'Set total volume to 0 and put your top cardio sessions or class names in the lift slots. It still works.' },
        { q: 'Is anything uploaded?', a: 'No. Numbers stay in your browser. The card is rendered locally and downloaded directly.' },
        { q: 'When should I share this?', a: 'Late December through early January is peak Wrapped season. Posts perform 3-4× better that window.' },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
        <h2 className="text-base font-bold text-white">Your year</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="block sm:col-span-2">
            <span className="text-xs text-zinc-400">Your name (optional)</span>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Alex"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Total workouts</span>
            <input type="number" value={totalWorkouts} onChange={(e) => setTotalWorkouts(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Total minutes trained</span>
            <input type="number" value={totalMinutes} onChange={(e) => setTotalMinutes(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Total volume</span>
            <div className="mt-1 flex gap-2">
              <input type="number" value={totalVolume} onChange={(e) => setTotalVolume(e.target.value)}
                className="flex-1 px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
              <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
                {(['lb', 'kg'] as Unit[]).map((u) => (
                  <button key={u} type="button" onClick={() => setUnit(u)}
                    className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${unit === u ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'}`}>{u}</button>
                ))}
              </div>
            </div>
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Body weight change ({unit}, +/-)</span>
            <input type="number" value={weightChange} onChange={(e) => setWeightChange(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
        </div>

        <h3 className="text-sm font-semibold text-white pt-2">Top 3 lifts of the year</h3>
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
        slug="year-in-fitness-wrapped"
        primary="Your real Wrapped is auto-generated in Zealova"
        secondary="Train inside Zealova and your year-end card writes itself, with month-by-month rankings, your top day of the year, and shareable per-month cards."
      />

      <MethodologyFooter
        citations={[
          { text: 'Card composition follows the Spotify Wrapped pattern: vertical 9:16, gradient hero, stacked stat blocks, single accent color (gold) over a brand gradient.' },
          { text: '1080×1920 is the native upload size for Instagram Stories, Reels, TikTok, and YouTube Shorts.' },
        ]}
        lastUpdated="2026-05-14"
      />
    <TagUsNudge />
    </CalculatorShell>
  );
}

function drawWrappedStat(ctx: CanvasRenderingContext2D, cx: number, y: number, value: string, label: string) {
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.fillStyle = '#ffffff';
  ctx.font = `900 130px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.fillText(value, cx, y);
  ctx.fillStyle = '#fbbf24';
  ctx.font = `700 26px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  ctx.fillText(label, cx, y + 145);
}

function drawWatermark(ctx: CanvasRenderingContext2D, canvasW: number, canvasH: number, logo: HTMLImageElement | null) {
  const padding = canvasW * 0.025;
  const wmHeight = canvasH * 0.03;
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
