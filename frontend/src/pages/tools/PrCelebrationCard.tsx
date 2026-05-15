// /free-tools/pr-celebration-card
//
// Visual share card for celebrating a PR. Pure client-side canvas render.
// Confetti pattern + gradient burst + bodyweight ratio + Zealova watermark.

import { useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import TagUsNudge from '../../components/tools/TagUsNudge';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type DownloadFormat = 'png' | 'jpeg' | 'webp';
type AspectRatio = 'portrait' | 'square';
type Unit = 'lb' | 'kg';

const LIFT_OPTIONS = ['Squat', 'Bench Press', 'Deadlift', 'Overhead Press', 'Pull-up', 'Custom'] as const;

const FORMAT_INFO: Record<DownloadFormat, { mime: string; ext: string; label: string }> = {
  png: { mime: 'image/png', ext: 'png', label: 'PNG (lossless, larger file)' },
  jpeg: { mime: 'image/jpeg', ext: 'jpg', label: 'JPG (smaller, social-friendly)' },
  webp: { mime: 'image/webp', ext: 'webp', label: 'WebP (smallest, modern browsers)' },
};

export default function PrCelebrationCard() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const [lift, setLift] = useState<string>('Squat');
  const [customLift, setCustomLift] = useState<string>('');
  const [weight, setWeight] = useState<string>('315');
  const [reps, setReps] = useState<string>('1');
  const [bodyweight, setBodyweight] = useState<string>('180');
  const [unit, setUnit] = useState<Unit>('lb');
  const [name, setName] = useState<string>('');
  const [aspect, setAspect] = useState<AspectRatio>('portrait');
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('jpeg');

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => {
      logoRef.current = img;
      setName((n) => n);
    };
  }, []);

  const liftName = lift === 'Custom' ? (customLift.trim() || 'Custom Lift') : lift;
  const weightNum = parseFloat(weight) || 0;
  const repsNum = parseInt(reps) || 0;
  const bwNum = parseFloat(bodyweight) || 0;
  const ratio = bwNum > 0 ? (weightNum / bwNum) : 0;

  const today = useMemo(() => new Date().toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' }), []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const W = 1080;
    const H = aspect === 'portrait' ? 1350 : 1080;
    canvas.width = W;
    canvas.height = H;

    // Background gradient burst
    const grad = ctx.createRadialGradient(W / 2, H * 0.35, 60, W / 2, H * 0.35, W);
    grad.addColorStop(0, '#10b981');
    grad.addColorStop(0.35, '#047857');
    grad.addColorStop(1, '#0a0a0a');
    ctx.fillStyle = grad;
    ctx.fillRect(0, 0, W, H);

    // Confetti
    drawConfetti(ctx, W, H, liftName + weight + reps);

    // "NEW PR" badge top
    const badgeY = H * 0.08;
    ctx.font = `900 ${Math.round(W * 0.07)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillStyle = '#ffffff';
    ctx.fillText('NEW PR', W / 2, badgeY);

    // Sub-label
    ctx.font = `600 ${Math.round(W * 0.028)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = 'rgba(255,255,255,0.75)';
    ctx.fillText(name ? name.toUpperCase() : 'PERSONAL RECORD', W / 2, badgeY + Math.round(W * 0.085));

    // Big PR badge circle
    const badgeCenterY = H * 0.27;
    ctx.beginPath();
    ctx.arc(W / 2, badgeCenterY, W * 0.09, 0, Math.PI * 2);
    ctx.fillStyle = '#fbbf24';
    ctx.fill();
    ctx.font = `900 ${Math.round(W * 0.075)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = '#0a0a0a';
    ctx.textBaseline = 'middle';
    ctx.fillText('PR', W / 2, badgeCenterY + 2);

    // Lift name
    ctx.textBaseline = 'top';
    ctx.font = `700 ${Math.round(W * 0.062)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = '#ffffff';
    ctx.fillText(liftName.toUpperCase(), W / 2, H * 0.41);

    // Weight × Reps hero
    const heroY = H * 0.52;
    ctx.font = `900 ${Math.round(W * 0.18)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = '#ffffff';
    const heroText = `${weightNum}${unit}`;
    ctx.fillText(heroText, W / 2, heroY);

    ctx.font = `600 ${Math.round(W * 0.045)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = 'rgba(255,255,255,0.9)';
    ctx.fillText(`× ${repsNum} ${repsNum === 1 ? 'rep' : 'reps'}`, W / 2, heroY + Math.round(W * 0.21));

    // Ratio pill
    if (ratio > 0) {
      const pillText = `${ratio.toFixed(2)}× bodyweight`;
      ctx.font = `700 ${Math.round(W * 0.034)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
      const metrics = ctx.measureText(pillText);
      const padX = W * 0.03;
      const padY = W * 0.018;
      const pillW = metrics.width + padX * 2;
      const pillH = Math.round(W * 0.034) + padY * 2;
      const pillX = W / 2 - pillW / 2;
      const pillY = heroY + Math.round(W * 0.31);
      ctx.fillStyle = 'rgba(0,0,0,0.5)';
      roundedRect(ctx, pillX, pillY, pillW, pillH, pillH / 2);
      ctx.fill();
      ctx.fillStyle = '#fbbf24';
      ctx.textBaseline = 'middle';
      ctx.fillText(pillText, W / 2, pillY + pillH / 2);
    }

    // Date footer
    ctx.font = `500 ${Math.round(W * 0.028)}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = 'rgba(255,255,255,0.6)';
    ctx.textBaseline = 'top';
    ctx.fillText(today, W / 2, H * 0.88);

    ctx.textAlign = 'left';
    drawWatermark(ctx, W, H, logoRef.current);
  }, [liftName, weightNum, repsNum, bwNum, unit, name, ratio, aspect, today]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `zealova-pr-${Date.now()}.${fmt.ext}`;
      a.click();
      URL.revokeObjectURL(url);
    }, fmt.mime, 0.92);
  };

  return (
    <CalculatorShell
      slug="pr-celebration-card"
      title="PR Celebration Card Generator"
      metaDescription="Free PR celebration card generator. Drop your lift, weight, reps, bodyweight, and download a share-ready card with confetti and bodyweight ratio. No sign-up."
      intro="Hit a PR. Fill in the numbers. Download a card you can post to Instagram, X, or Reddit in seconds. Bodyweight ratio is auto-computed. Watermarked with Zealova so your friends find the app."
      faqs={[
        { q: 'Is anything uploaded?', a: 'No. The card is composed on a canvas in your browser. Nothing leaves your device.' },
        { q: 'What sizes can I download?', a: 'Portrait 1080×1350 for Instagram feed and stories, or square 1080×1080 for older feeds and Twitter.' },
        { q: 'What does bodyweight ratio mean?', a: 'Your lift divided by your bodyweight. A 2× bodyweight squat means you squatted twice your bodyweight. It is the simplest cross-bodyweight strength comparison.' },
        { q: 'Why is the date today?', a: 'PRs are time-stamped. Today is auto-filled so the card reads as a fresh moment, which performs better on social.' },
        { q: 'Can I remove the watermark?', a: 'You can crop it. Please leave it if you can. It is how we keep this tool free.' },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
        <h2 className="text-base font-bold text-white">Your PR</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="block">
            <span className="text-xs text-zinc-400">Lift</span>
            <select value={lift} onChange={(e) => setLift(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500">
              {LIFT_OPTIONS.map((o) => <option key={o} value={o}>{o}</option>)}
            </select>
          </label>
          {lift === 'Custom' && (
            <label className="block">
              <span className="text-xs text-zinc-400">Custom lift name</span>
              <input value={customLift} onChange={(e) => setCustomLift(e.target.value)}
                placeholder="e.g. Trap Bar Deadlift"
                className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            </label>
          )}
          <label className="block">
            <span className="text-xs text-zinc-400">Weight</span>
            <div className="mt-1 flex gap-2">
              <input value={weight} onChange={(e) => setWeight(e.target.value)} type="number"
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
            <span className="text-xs text-zinc-400">Reps</span>
            <input value={reps} onChange={(e) => setReps(e.target.value)} type="number"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Your bodyweight ({unit})</span>
            <input value={bodyweight} onChange={(e) => setBodyweight(e.target.value)} type="number"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Your name (optional)</span>
            <input value={name} onChange={(e) => setName(e.target.value)}
              placeholder="Shown above the PR label"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs text-zinc-400">Aspect</span>
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            {(['portrait', 'square'] as AspectRatio[]).map((a) => (
              <button key={a} type="button" onClick={() => setAspect(a)}
                className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${aspect === a ? 'bg-emerald-500 text-zinc-900' : 'text-zinc-400 hover:text-white'}`}>
                {a === 'portrait' ? 'Portrait 1080×1350' : 'Square 1080×1080'}
              </button>
            ))}
          </div>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-3">Preview</h2>
        <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-4 overflow-x-auto">
          <canvas ref={canvasRef} className="w-full max-w-md h-auto rounded-xl mx-auto block" style={{ maxHeight: '70vh' }} />
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
        <p className="text-xs text-zinc-500 mt-3">{FORMAT_INFO[downloadFormat].label}</p>
      </section>

      <InstallCta
        slug="pr-celebration-card"
        primary="Track every PR automatically in Zealova"
        secondary="Zealova logs every lift, flags PRs the moment they happen, and generates this card for you the second you re-rack the bar."
      />

      <MethodologyFooter
        citations={[
          { text: 'Bodyweight ratio is a common cross-bodyweight strength benchmark used by Starting Strength, StrengthLevel, and most powerlifting federations.' },
          { text: 'Portrait 1080×1350 matches Instagram feed and stories. Square 1080×1080 matches Twitter and older feeds.' },
        ]}
        lastUpdated="2026-05-14"
      />
    <TagUsNudge />
    </CalculatorShell>
  );
}

function drawConfetti(ctx: CanvasRenderingContext2D, W: number, H: number, seedStr: string) {
  const colors = ['#fbbf24', '#10b981', '#ffffff', '#34d399', '#f59e0b'];
  let seed = 0;
  for (let i = 0; i < seedStr.length; i++) seed = (seed * 31 + seedStr.charCodeAt(i)) >>> 0;
  const rand = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return seed / 0xffffffff;
  };
  for (let i = 0; i < 80; i++) {
    const x = rand() * W;
    const y = rand() * H;
    const size = 6 + rand() * 14;
    const rot = rand() * Math.PI;
    ctx.save();
    ctx.translate(x, y);
    ctx.rotate(rot);
    ctx.fillStyle = colors[Math.floor(rand() * colors.length)];
    ctx.globalAlpha = 0.55 + rand() * 0.35;
    ctx.fillRect(-size / 2, -size / 4, size, size / 2);
    ctx.restore();
  }
  ctx.globalAlpha = 1;
}

function drawWatermark(ctx: CanvasRenderingContext2D, canvasW: number, canvasH: number, logo: HTMLImageElement | null) {
  const padding = canvasW * 0.025;
  const wmHeight = canvasH * 0.045;
  const wmFontSize = wmHeight * 0.55;
  ctx.font = `700 ${wmFontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  const text = 'Made with Zealova';
  const textW = ctx.measureText(text).width;
  const logoSize = wmHeight;
  const gap = wmHeight * 0.25;
  const totalW = (logo ? logoSize + gap : 0) + textW + wmHeight * 0.5 * 2;
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
  ctx.textAlign = 'left';
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
