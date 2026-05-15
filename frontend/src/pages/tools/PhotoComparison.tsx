// /free-tools/photo-comparison
//
// Side-by-side progress photo composer with Zealova watermark.
// Pure client-side: <input type="file"> → HTMLImageElement → composite on
// <canvas> → download via canvas.toBlob(). Nothing leaves the device.
//
// Strategic purpose: every photo shared with the Zealova watermark in the
// bottom-right becomes a free distribution channel. Same play as the Cal AI
// food-photo watermark that drove millions of downloads.

import { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import TagUsNudge from '../../components/tools/TagUsNudge';
import InstallCta from '../../components/tools/InstallCta';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

type ImageSlot = {
  file: File | null;
  bitmap: HTMLImageElement | null;
  label: string;
  date: string;
  weight: string;
};

type Layout = 'side-by-side' | 'stacked';
type DownloadFormat = 'png' | 'jpeg' | 'webp';

const EMPTY_SLOT: Omit<ImageSlot, 'label'> = {
  file: null,
  bitmap: null,
  date: '',
  weight: '',
};

const FORMAT_INFO: Record<DownloadFormat, { mime: string; ext: string; label: string }> = {
  png: { mime: 'image/png', ext: 'png', label: 'PNG (lossless, larger file)' },
  jpeg: { mime: 'image/jpeg', ext: 'jpg', label: 'JPG (smaller, social-friendly)' },
  webp: { mime: 'image/webp', ext: 'webp', label: 'WebP (smallest, modern browsers)' },
};

const OUTPUT_WIDTH = 1080;       // matches Instagram portrait posts
const WATERMARK_HEIGHT_PCT = 0.05;
const WATERMARK_PADDING_PCT = 0.02;

function loadImage(file: File): Promise<HTMLImageElement> {
  return new Promise((resolve, reject) => {
    const url = URL.createObjectURL(file);
    const img = new Image();
    img.onload = () => {
      URL.revokeObjectURL(url);
      resolve(img);
    };
    img.onerror = () => {
      URL.revokeObjectURL(url);
      reject(new Error('Could not load image'));
    };
    img.src = url;
  });
}

export default function PhotoComparison() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const logoRef = useRef<HTMLImageElement | null>(null);

  const [slots, setSlots] = useState<ImageSlot[]>([
    { ...EMPTY_SLOT, label: 'Before' },
    { ...EMPTY_SLOT, label: 'After' },
  ]);
  const [layout, setLayout] = useState<Layout>('side-by-side');
  const [showLabels, setShowLabels] = useState(true);
  const [showStats, setShowStats] = useState(true);
  const [downloadFormat, setDownloadFormat] = useState<DownloadFormat>('jpeg');

  // Preload watermark logo once.
  useEffect(() => {
    const img = new Image();
    img.crossOrigin = 'anonymous';
    img.src = '/zealova-logo.png';
    img.onload = () => {
      logoRef.current = img;
      // Trigger a re-render so the canvas redraws with the logo.
      setSlots((s) => [...s]);
    };
  }, []);

  const handleFile = useCallback(async (index: number, file: File | null) => {
    if (!file) {
      setSlots((s) =>
        s.map((slot, i) => (i === index ? { ...slot, file: null, bitmap: null } : slot)),
      );
      return;
    }
    try {
      const bitmap = await loadImage(file);
      setSlots((s) => s.map((slot, i) => (i === index ? { ...slot, file, bitmap } : slot)));
    } catch (err) {
      console.error('Image load failed', err);
      alert('Could not load that image. Try a JPG or PNG.');
    }
  }, []);

  const updateSlot = useCallback(
    <K extends keyof ImageSlot>(index: number, key: K, value: ImageSlot[K]) => {
      setSlots((s) => s.map((slot, i) => (i === index ? { ...slot, [key]: value } : slot)));
    },
    [],
  );

  const filledSlots = useMemo(() => slots.filter((s) => s.bitmap !== null), [slots]);
  const canDownload = filledSlots.length >= 2;

  // Compose canvas whenever inputs change.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    // Compute canvas size based on layout + filled slots.
    const slotCount = Math.max(filledSlots.length, 2);
    const pairWidth = OUTPUT_WIDTH;
    // Standard 4:5 portrait per slot (Instagram-safe).
    const slotW = layout === 'side-by-side' ? pairWidth / slotCount : pairWidth;
    const slotH = slotW * 1.25;
    canvas.width = layout === 'side-by-side' ? pairWidth : slotW;
    canvas.height = layout === 'side-by-side' ? slotH : slotH * slotCount;

    // Fill background.
    ctx.fillStyle = '#0a0a0a';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    filledSlots.forEach((slot, i) => {
      const x = layout === 'side-by-side' ? i * slotW : 0;
      const y = layout === 'side-by-side' ? 0 : i * slotH;
      drawSlotIntoBox(ctx, slot, x, y, slotW, slotH, showLabels, showStats);
    });

    // Watermark — bottom right corner.
    drawWatermark(ctx, canvas.width, canvas.height, logoRef.current);
  }, [filledSlots, layout, showLabels, showStats]);

  const handleDownload = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const fmt = FORMAT_INFO[downloadFormat];
    canvas.toBlob(
      (blob) => {
        if (!blob) return;
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `zealova-progress-${Date.now()}.${fmt.ext}`;
        a.click();
        URL.revokeObjectURL(url);
      },
      fmt.mime,
      0.92,
    );
  };

  const addSlot = () => {
    if (slots.length >= 4) return;
    const label = slots.length === 2 ? 'Now' : `Photo ${slots.length + 1}`;
    setSlots((s) => [...s, { ...EMPTY_SLOT, label }]);
  };

  const removeSlot = (index: number) => {
    if (slots.length <= 2) return;
    setSlots((s) => s.filter((_, i) => i !== index));
  };

  return (
    <CalculatorShell
      slug="photo-comparison"
      title="Progress Photo Comparison Tool"
      metaDescription="Free side-by-side progress photo comparison tool. Drop your before/after photos, add date and weight, download as JPG or PNG. Watermarked with Zealova. No sign-up."
      intro="Drop in 2 to 4 progress photos. We'll compose them side-by-side or stacked, add your labels and stats, and let you download as JPG, PNG, or WebP. Nothing is uploaded. Everything runs on your device."
      faqs={[
        {
          q: 'Are my photos uploaded anywhere?',
          a: 'No. Every part of this tool runs in your browser. Your photos never leave your device. The composite is generated locally on a canvas element and downloaded directly.',
        },
        {
          q: 'Can I add more than 2 photos?',
          a: 'Yes, up to 4. Useful for multi-month progress timelines (week 0, week 4, week 8, week 12). Side-by-side layout works best for 2, stacked layout works better for 3 or 4 photos.',
        },
        {
          q: 'What file formats can I download?',
          a: 'JPG (smaller, best for sharing on Instagram or Reddit), PNG (lossless, larger), and WebP (smallest file size, supported by all modern browsers).',
        },
        {
          q: 'What is the output resolution?',
          a: 'Output is 1080 pixels wide for side-by-side and 1080 pixels per slot for stacked. This matches Instagram and Reddit upload sizes without forcing them to compress your photos.',
        },
        {
          q: 'Why is the Zealova watermark in the corner?',
          a: 'We built this tool free for the fitness community. The small watermark helps other people find Zealova when you share your progress. You can crop it out, but please leave it on if you can. It is how we sustain free tools without a paywall.',
        },
      ]}
    >
      {/* Photo slots */}
      <section className="space-y-4">
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <h2 className="text-lg font-bold text-white">Your photos</h2>
          {slots.length < 4 && (
            <button
              type="button"
              onClick={addSlot}
              className="text-xs px-3 py-1.5 rounded-lg border border-zinc-700 text-zinc-300 hover:bg-zinc-800 transition"
            >
              + Add photo
            </button>
          )}
        </div>
        <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
          {slots.map((slot, i) => (
            <SlotEditor
              key={i}
              index={i}
              slot={slot}
              canRemove={slots.length > 2}
              onFile={(f) => handleFile(i, f)}
              onLabel={(v) => updateSlot(i, 'label', v)}
              onDate={(v) => updateSlot(i, 'date', v)}
              onWeight={(v) => updateSlot(i, 'weight', v)}
              onRemove={() => removeSlot(i)}
            />
          ))}
        </div>
      </section>

      {/* Layout + display options */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
        <h2 className="text-base font-bold text-white mb-4">Layout</h2>
        <div className="flex flex-wrap items-center gap-3">
          <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
            <button
              type="button"
              onClick={() => setLayout('side-by-side')}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${
                layout === 'side-by-side'
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'text-zinc-400 hover:text-white'
              }`}
            >
              Side by side
            </button>
            <button
              type="button"
              onClick={() => setLayout('stacked')}
              className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${
                layout === 'stacked'
                  ? 'bg-emerald-500 text-zinc-900'
                  : 'text-zinc-400 hover:text-white'
              }`}
            >
              Stacked
            </button>
          </div>
          <label className="inline-flex items-center gap-2 text-sm text-zinc-300 cursor-pointer">
            <input
              type="checkbox"
              checked={showLabels}
              onChange={(e) => setShowLabels(e.target.checked)}
              className="w-4 h-4 accent-emerald-500"
            />
            Show labels
          </label>
          <label className="inline-flex items-center gap-2 text-sm text-zinc-300 cursor-pointer">
            <input
              type="checkbox"
              checked={showStats}
              onChange={(e) => setShowStats(e.target.checked)}
              className="w-4 h-4 accent-emerald-500"
            />
            Show date and weight
          </label>
        </div>
      </section>

      {/* Preview canvas */}
      <section>
        <h2 className="text-lg font-bold text-white mb-3">Preview</h2>
        <div className="rounded-2xl border border-zinc-800 bg-zinc-950 p-4 overflow-x-auto">
          {filledSlots.length === 0 ? (
            <p className="text-sm text-zinc-500 py-12 text-center">
              Add at least one photo to see the preview.
            </p>
          ) : (
            <canvas
              ref={canvasRef}
              className="w-full max-w-full h-auto rounded-xl mx-auto block"
              style={{ maxHeight: '70vh' }}
            />
          )}
        </div>
      </section>

      {/* Download */}
      {canDownload && (
        <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-6">
          <h2 className="text-base font-bold text-white mb-3">Download</h2>
          <div className="flex flex-wrap items-center gap-3">
            <div className="inline-flex rounded-lg border border-zinc-700 bg-zinc-950 p-0.5">
              {(Object.keys(FORMAT_INFO) as DownloadFormat[]).map((fmt) => (
                <button
                  key={fmt}
                  type="button"
                  onClick={() => setDownloadFormat(fmt)}
                  className={`px-3 py-1.5 text-xs font-medium rounded-md transition ${
                    downloadFormat === fmt
                      ? 'bg-emerald-500 text-zinc-900'
                      : 'text-zinc-400 hover:text-white'
                  }`}
                >
                  {FORMAT_INFO[fmt].ext.toUpperCase()}
                </button>
              ))}
            </div>
            <button
              type="button"
              onClick={handleDownload}
              className="px-5 py-2.5 rounded-xl bg-emerald-500 text-zinc-900 font-semibold hover:bg-emerald-400 transition shadow-lg shadow-emerald-500/20"
            >
              Download
            </button>
          </div>
          <p className="text-xs text-zinc-500 mt-3">{FORMAT_INFO[downloadFormat].label}</p>
        </section>
      )}

      <InstallCta
        slug="photo-comparison"
        primary="Track every progress photo in one timeline"
        secondary="Zealova auto-saves your progress photos, tags each with weight and body fat, and shows side-by-side comparisons for any two dates in one tap."
      />

      <MethodologyFooter
        citations={[
          { text: 'Resolution choice (1080px wide): matches Instagram, Reddit, and TikTok native upload sizes to avoid platform recompression.' },
          { text: 'Watermark placement (bottom right, 5% height): follows app-watermarking convention seen in Cal AI, Snapchat, and similar viral photo tools.' },
        ]}
        lastUpdated="2026-05-14"
      />
    <TagUsNudge />
    </CalculatorShell>
  );
}

// ───────────────────────────────────────────────────────────────────────
// Slot editor + canvas drawing helpers
// ───────────────────────────────────────────────────────────────────────

interface SlotEditorProps {
  index: number;
  slot: ImageSlot;
  canRemove: boolean;
  onFile: (f: File | null) => void;
  onLabel: (v: string) => void;
  onDate: (v: string) => void;
  onWeight: (v: string) => void;
  onRemove: () => void;
}

function SlotEditor({
  index,
  slot,
  canRemove,
  onFile,
  onLabel,
  onDate,
  onWeight,
  onRemove,
}: SlotEditorProps) {
  const inputId = `photo-input-${index}`;
  const fileRef = useRef<HTMLInputElement>(null);

  return (
    <div className="border border-zinc-800 rounded-2xl bg-zinc-900 p-4 space-y-3">
      <div className="flex items-center justify-between gap-2">
        <input
          type="text"
          value={slot.label}
          onChange={(e) => onLabel(e.target.value)}
          placeholder={`Photo ${index + 1}`}
          className="flex-1 px-3 py-1.5 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
        {canRemove && (
          <button
            type="button"
            onClick={onRemove}
            className="text-xs px-2 py-1 rounded-md text-zinc-500 hover:text-red-400 transition"
            aria-label="Remove this photo slot"
          >
            ×
          </button>
        )}
      </div>

      <div>
        <input
          ref={fileRef}
          id={inputId}
          type="file"
          accept="image/jpeg,image/png,image/webp,image/heic"
          onChange={(e) => onFile(e.target.files?.[0] ?? null)}
          className="sr-only"
        />
        <label
          htmlFor={inputId}
          className={`block cursor-pointer rounded-xl border-2 border-dashed text-center transition py-8 ${
            slot.bitmap
              ? 'border-emerald-500/40 bg-emerald-500/5 text-emerald-300'
              : 'border-zinc-700 bg-zinc-950 text-zinc-500 hover:border-zinc-600 hover:text-zinc-300'
          }`}
        >
          {slot.bitmap ? (
            <span className="text-sm">
              ✓ Loaded ({slot.bitmap.naturalWidth} × {slot.bitmap.naturalHeight})
              <br />
              <span className="text-xs text-zinc-500">Click to replace</span>
            </span>
          ) : (
            <span className="text-sm">Tap to upload a photo</span>
          )}
        </label>
      </div>

      <div className="grid grid-cols-2 gap-2">
        <input
          type="text"
          value={slot.date}
          onChange={(e) => onDate(e.target.value)}
          placeholder="Date (optional)"
          className="px-3 py-1.5 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
        <input
          type="text"
          value={slot.weight}
          onChange={(e) => onWeight(e.target.value)}
          placeholder="Weight (optional)"
          className="px-3 py-1.5 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-xs focus:outline-none focus:ring-2 focus:ring-emerald-500"
        />
      </div>
    </div>
  );
}

function drawSlotIntoBox(
  ctx: CanvasRenderingContext2D,
  slot: ImageSlot,
  x: number,
  y: number,
  w: number,
  h: number,
  showLabels: boolean,
  showStats: boolean,
) {
  if (!slot.bitmap) return;

  // Cover-fit the image into the box.
  const img = slot.bitmap;
  const imgAspect = img.naturalWidth / img.naturalHeight;
  const boxAspect = w / h;
  let drawW = w;
  let drawH = h;
  let drawX = x;
  let drawY = y;
  if (imgAspect > boxAspect) {
    drawH = h;
    drawW = h * imgAspect;
    drawX = x - (drawW - w) / 2;
  } else {
    drawW = w;
    drawH = w / imgAspect;
    drawY = y - (drawH - h) / 2;
  }

  // Clip to box bounds so neighboring slots don't bleed.
  ctx.save();
  ctx.beginPath();
  ctx.rect(x, y, w, h);
  ctx.clip();
  ctx.drawImage(img, drawX, drawY, drawW, drawH);

  // Bottom-aligned gradient for text legibility.
  if ((showLabels && slot.label) || (showStats && (slot.date || slot.weight))) {
    const grad = ctx.createLinearGradient(0, y + h * 0.6, 0, y + h);
    grad.addColorStop(0, 'rgba(0,0,0,0)');
    grad.addColorStop(1, 'rgba(0,0,0,0.6)');
    ctx.fillStyle = grad;
    ctx.fillRect(x, y + h * 0.6, w, h * 0.4);
  }

  // Top-left label
  if (showLabels && slot.label) {
    const fontSize = Math.round(w * 0.055);
    ctx.font = `bold ${fontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.textBaseline = 'top';
    // Pill background
    const padX = fontSize * 0.4;
    const padY = fontSize * 0.25;
    const text = slot.label;
    const metrics = ctx.measureText(text);
    const pillW = metrics.width + padX * 2;
    const pillH = fontSize + padY * 2;
    const pillX = x + fontSize * 0.5;
    const pillY = y + fontSize * 0.5;
    ctx.fillStyle = 'rgba(16, 185, 129, 0.95)'; // emerald-500
    roundedRect(ctx, pillX, pillY, pillW, pillH, fontSize * 0.3);
    ctx.fill();
    ctx.fillStyle = '#0a0a0a';
    ctx.fillText(text, pillX + padX, pillY + padY);
  }

  // Bottom stats (date + weight)
  if (showStats && (slot.date || slot.weight)) {
    const fontSize = Math.round(w * 0.04);
    ctx.font = `600 ${fontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
    ctx.fillStyle = '#ffffff';
    ctx.textBaseline = 'bottom';
    const pad = fontSize * 0.6;
    if (slot.weight) {
      ctx.textAlign = 'right';
      ctx.fillText(slot.weight, x + w - pad, y + h - pad);
    }
    if (slot.date) {
      ctx.textAlign = 'left';
      ctx.fillText(slot.date, x + pad, y + h - pad);
    }
    ctx.textAlign = 'left';
  }

  ctx.restore();
}

function drawWatermark(
  ctx: CanvasRenderingContext2D,
  canvasW: number,
  canvasH: number,
  logo: HTMLImageElement | null,
) {
  const padding = canvasW * WATERMARK_PADDING_PCT;
  const wmHeight = canvasH * WATERMARK_HEIGHT_PCT;
  const wmFontSize = wmHeight * 0.55;
  ctx.font = `700 ${wmFontSize}px -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif`;
  const text = 'Made with Zealova';
  const textMetrics = ctx.measureText(text);
  const textW = textMetrics.width;
  const logoSize = wmHeight;
  const gap = wmHeight * 0.25;

  const totalW = (logo ? logoSize + gap : 0) + textW + wmHeight * 0.5 * 2;
  const wmX = canvasW - padding - totalW;
  const wmY = canvasH - padding - wmHeight;

  // Semi-transparent dark capsule background
  ctx.fillStyle = 'rgba(0, 0, 0, 0.55)';
  roundedRect(ctx, wmX, wmY, totalW, wmHeight, wmHeight * 0.3);
  ctx.fill();

  // Logo (if loaded)
  let xCursor = wmX + wmHeight * 0.5;
  if (logo) {
    ctx.drawImage(
      logo,
      xCursor,
      wmY + (wmHeight - logoSize * 0.85) / 2,
      logoSize * 0.85,
      logoSize * 0.85,
    );
    xCursor += logoSize * 0.85 + gap;
  }

  // Text
  ctx.fillStyle = '#ffffff';
  ctx.textBaseline = 'middle';
  ctx.textAlign = 'left';
  ctx.fillText(text, xCursor, wmY + wmHeight / 2);
}

function roundedRect(
  ctx: CanvasRenderingContext2D,
  x: number,
  y: number,
  w: number,
  h: number,
  r: number,
) {
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
