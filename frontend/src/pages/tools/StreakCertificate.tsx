// /free-tools/streak-certificate
//
// Diploma-style certificate for a fitness streak. 1200x900 landscape.
// Dark zinc + emerald accent + serif font for the cert body.

import { useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import TagUsNudge from '../../components/tools/TagUsNudge';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type DownloadFormat = 'png' | 'jpeg' | 'webp';

const STREAK_TYPES = ['Workouts', 'Cutting', 'Bulking', 'Cardio', 'Custom'] as const;

const FORMAT_INFO: Record<DownloadFormat, { mime: string; ext: string; label: string }> = {
  png: { mime: 'image/png', ext: 'png', label: 'PNG (lossless, larger file)' },
  jpeg: { mime: 'image/jpeg', ext: 'jpg', label: 'JPG (smaller, social-friendly)' },
  webp: { mime: 'image/webp', ext: 'webp', label: 'WebP (smallest, modern browsers)' },
};

export default function StreakCertificate() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const [name, setName] = useState('');
  const [count, setCount] = useState('60');
  const [type, setType] = useState<string>('Workouts');
  const [customType, setCustomType] = useState('');
  const [startDate, setStartDate] = useState('');
  const [message, setMessage] = useState('');
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('png');

  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => {
      logoRef.current = img;
      setName((n) => n);
    };
  }, []);

  const today = useMemo(() => new Date().toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' }), []);
  const startDisplay = useMemo(() => {
    if (!startDate) return '';
    const d = new Date(startDate);
    if (isNaN(d.getTime())) return startDate;
    return d.toLocaleDateString('en-US', { month: 'long', day: 'numeric', year: 'numeric' });
  }, [startDate]);

  const typeName = type === 'Custom' ? (customType.trim() || 'Custom') : type;
  const countNum = parseInt(count) || 0;
  const safeName = name.trim() || 'YOUR NAME';

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const W = 1200;
    const H = 900;
    canvas.width = W;
    canvas.height = H;

    // Background
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, W, H);

    // Decorative border
    const borderInset = 40;
    ctx.strokeStyle = '#10b981';
    ctx.lineWidth = 4;
    ctx.strokeRect(borderInset, borderInset, W - borderInset * 2, H - borderInset * 2);
    ctx.strokeStyle = 'rgba(16,185,129,0.4)';
    ctx.lineWidth = 1;
    ctx.strokeRect(borderInset + 14, borderInset + 14, W - (borderInset + 14) * 2, H - (borderInset + 14) * 2);

    // Corner ornaments
    drawCornerOrnament(ctx, borderInset + 30, borderInset + 30, 1, 1);
    drawCornerOrnament(ctx, W - borderInset - 30, borderInset + 30, -1, 1);
    drawCornerOrnament(ctx, borderInset + 30, H - borderInset - 30, 1, -1);
    drawCornerOrnament(ctx, W - borderInset - 30, H - borderInset - 30, -1, -1);

    // Header
    ctx.textAlign = 'center';
    ctx.textBaseline = 'top';
    ctx.fillStyle = 'rgba(16,185,129,0.85)';
    ctx.font = `600 22px "Helvetica Neue", Arial, sans-serif`;
    ctx.fillText('CERTIFICATE OF CONSISTENCY', W / 2, 130);

    // Title serif
    ctx.fillStyle = '#ffffff';
    ctx.font = `400 64px Georgia, "Times New Roman", serif`;
    ctx.fillText('This certifies that', W / 2, 175);

    // Name
    ctx.fillStyle = '#10b981';
    ctx.font = `700 78px Georgia, "Times New Roman", serif`;
    ctx.fillText(safeName.toUpperCase(), W / 2, 255);

    // Underline under name
    const nameW = ctx.measureText(safeName.toUpperCase()).width;
    ctx.strokeStyle = 'rgba(16,185,129,0.5)';
    ctx.lineWidth = 2;
    ctx.beginPath();
    ctx.moveTo(W / 2 - Math.min(nameW, W - 200) / 2, 350);
    ctx.lineTo(W / 2 + Math.min(nameW, W - 200) / 2, 350);
    ctx.stroke();

    // Body text
    ctx.fillStyle = '#e5e5e5';
    ctx.font = `400 30px Georgia, "Times New Roman", serif`;
    ctx.fillText('has completed', W / 2, 380);

    // Big number
    ctx.fillStyle = '#ffffff';
    ctx.font = `900 140px Georgia, "Times New Roman", serif`;
    ctx.fillText(`${countNum}`, W / 2, 420);

    ctx.fillStyle = '#e5e5e5';
    ctx.font = `400 30px Georgia, "Times New Roman", serif`;
    const consecutiveLine = `consecutive ${typeName.toLowerCase()} days`;
    ctx.fillText(consecutiveLine, W / 2, 580);

    // Date range
    ctx.fillStyle = 'rgba(255,255,255,0.7)';
    ctx.font = `400 22px Georgia, "Times New Roman", serif`;
    const rangeText = startDisplay
      ? `from ${startDisplay} through ${today}`
      : `through ${today}`;
    ctx.fillText(rangeText, W / 2, 630);

    // Optional message
    if (message.trim()) {
      ctx.fillStyle = 'rgba(16,185,129,0.85)';
      ctx.font = `italic 400 20px Georgia, "Times New Roman", serif`;
      ctx.fillText(`"${message.trim()}"`, W / 2, 685);
    }

    // Seal — bottom center
    const sealCx = W / 2;
    const sealCy = 780;
    const sealR = 55;
    ctx.beginPath();
    ctx.arc(sealCx, sealCy, sealR, 0, Math.PI * 2);
    ctx.fillStyle = '#10b981';
    ctx.fill();
    ctx.beginPath();
    ctx.arc(sealCx, sealCy, sealR - 6, 0, Math.PI * 2);
    ctx.strokeStyle = 'rgba(255,255,255,0.6)';
    ctx.lineWidth = 1.5;
    ctx.stroke();
    if (logoRef.current) {
      const logoSize = sealR * 1.1;
      ctx.drawImage(logoRef.current, sealCx - logoSize / 2, sealCy - logoSize / 2, logoSize, logoSize);
    } else {
      ctx.fillStyle = '#0a0a0a';
      ctx.font = `900 22px Georgia, serif`;
      ctx.textBaseline = 'middle';
      ctx.fillText('Z', sealCx, sealCy);
    }

    // Footer label
    ctx.textBaseline = 'top';
    ctx.fillStyle = 'rgba(255,255,255,0.5)';
    ctx.font = `600 13px "Helvetica Neue", Arial, sans-serif`;
    ctx.fillText('ISSUED BY ZEALOVA', W / 2, sealCy + sealR + 12);

    ctx.textAlign = 'left';
  }, [safeName, countNum, typeName, startDisplay, today, message]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob((blob) => {
      if (!blob) return;
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `zealova-streak-certificate-${Date.now()}.${fmt.ext}`;
      a.click();
      URL.revokeObjectURL(url);
    }, fmt.mime, 0.92);
  };

  return (
    <CalculatorShell
      slug="streak-certificate"
      title="Streak Certificate Generator"
      metaDescription="Free streak certificate generator. Diploma-style download for any fitness streak. Workouts, cutting, bulking, cardio. JPG, PNG, WebP. No sign-up."
      intro="Did you stack 60, 100, or 365 days in a row? Generate a diploma-style certificate to print or post. Dark zinc background, emerald seal, your name front and center."
      faqs={[
        { q: 'What streaks does this work for?', a: 'Any. Workouts, cutting days, bulking days, cardio sessions, water intake, sleep, anything you can count consecutive days of.' },
        { q: 'Why a certificate format?', a: 'A diploma frames a streak as something earned. It is more shareable than a stat screenshot, and the format reads as effort, not algorithm.' },
        { q: 'Can I print this?', a: 'Yes. PNG at 1200×900 prints cleanly at 8×6 inches at 150 DPI. Many users hang theirs in the gym corner of their home.' },
        { q: 'Is anything uploaded?', a: 'No. The certificate renders in your browser. Nothing is sent to a server.' },
      ]}
    >
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4">
        <h2 className="text-base font-bold text-white">Your streak</h2>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
          <label className="block">
            <span className="text-xs text-zinc-400">Your name</span>
            <input value={name} onChange={(e) => setName(e.target.value)} placeholder="e.g. Alex Rivera"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Streak count (days)</span>
            <input value={count} onChange={(e) => setCount(e.target.value)} type="number"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block">
            <span className="text-xs text-zinc-400">Streak type</span>
            <select value={type} onChange={(e) => setType(e.target.value)}
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500">
              {STREAK_TYPES.map((t) => <option key={t} value={t}>{t}</option>)}
            </select>
          </label>
          {type === 'Custom' && (
            <label className="block">
              <span className="text-xs text-zinc-400">Custom streak name</span>
              <input value={customType} onChange={(e) => setCustomType(e.target.value)} placeholder="e.g. 10k steps"
                className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
            </label>
          )}
          <label className="block">
            <span className="text-xs text-zinc-400">Start date</span>
            <input value={startDate} onChange={(e) => setStartDate(e.target.value)} type="date"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
          <label className="block sm:col-span-2">
            <span className="text-xs text-zinc-400">Optional message (italic, on cert)</span>
            <input value={message} onChange={(e) => setMessage(e.target.value)} placeholder="e.g. Consistency over intensity"
              className="mt-1 w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500" />
          </label>
        </div>
      </section>

      <section>
        <h2 className="text-lg font-bold text-white mb-3">Preview</h2>
        <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-4 overflow-x-auto">
          <canvas ref={canvasRef} className="w-full max-w-3xl h-auto rounded-xl mx-auto block" style={{ maxHeight: '70vh' }} />
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
        <p className="text-xs text-zinc-500 mt-3">{FORMAT_INFO[downloadFormat].label} at 1200×900</p>
      </section>

      <InstallCta
        slug="streak-certificate"
        primary="Track your real streak automatically in Zealova"
        secondary="Zealova tracks workout streaks, calorie streaks, cardio streaks, and sleep streaks. The certificate auto-generates when you hit a milestone."
      />

      <MethodologyFooter
        citations={[
          { text: '1200×900 landscape was chosen for print compatibility (8×6 inches at 150 DPI) and clean preview on Twitter and LinkedIn.' },
          { text: 'Serif body type and emerald seal mimic traditional certificate conventions to signal earned status, not algorithmic noise.' },
        ]}
        lastUpdated="2026-05-14"
      />
    <TagUsNudge />
    </CalculatorShell>
  );
}

function drawCornerOrnament(ctx: CanvasRenderingContext2D, x: number, y: number, dirX: number, dirY: number) {
  ctx.strokeStyle = 'rgba(16,185,129,0.7)';
  ctx.lineWidth = 2;
  ctx.beginPath();
  ctx.moveTo(x, y);
  ctx.lineTo(x + 28 * dirX, y);
  ctx.moveTo(x, y);
  ctx.lineTo(x, y + 28 * dirY);
  ctx.stroke();
  ctx.beginPath();
  ctx.arc(x + 8 * dirX, y + 8 * dirY, 4, 0, Math.PI * 2);
  ctx.fillStyle = '#10b981';
  ctx.fill();
}
