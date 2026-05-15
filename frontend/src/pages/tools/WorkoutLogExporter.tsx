// /free-tools/workout-log-exporter
//
// Multi-row workout log entry with CSV + PDF (print) export. Local state
// only, no API. emailCaptureResult triggers once user has logged at least
// one exercise with one set.

import { useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

interface SetRow {
  id: string;
  weight: number;
  reps: number;
}

interface ExerciseRow {
  id: string;
  date: string;            // YYYY-MM-DD
  name: string;
  sets: SetRow[];
}

function uid(): string {
  return Math.random().toString(36).slice(2, 10);
}

function todayISO(): string {
  const d = new Date();
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function makeEmptyExercise(): ExerciseRow {
  return {
    id: uid(),
    date: todayISO(),
    name: '',
    sets: [
      { id: uid(), weight: 0, reps: 0 },
      { id: uid(), weight: 0, reps: 0 },
      { id: uid(), weight: 0, reps: 0 },
    ],
  };
}

export default function WorkoutLogExporter() {
  const [exercises, setExercises] = useState<ExerciseRow[]>([makeEmptyExercise()]);

  // Derived: do we have at least one exercise with a name + one valid set?
  const hasValidEntry = useMemo(() => {
    return exercises.some(
      (ex) =>
        ex.name.trim().length > 0 &&
        ex.sets.some((s) => s.weight > 0 || s.reps > 0),
    );
  }, [exercises]);

  const totalSets = useMemo(
    () => exercises.reduce((acc, ex) => acc + ex.sets.length, 0),
    [exercises],
  );

  const totalVolume = useMemo(() => {
    return exercises.reduce((acc, ex) => {
      return (
        acc + ex.sets.reduce((s, set) => s + (set.weight || 0) * (set.reps || 0), 0)
      );
    }, 0);
  }, [exercises]);

  const updateExercise = (id: string, patch: Partial<ExerciseRow>) => {
    setExercises((prev) => prev.map((ex) => (ex.id === id ? { ...ex, ...patch } : ex)));
  };

  const updateSet = (exId: string, setId: string, patch: Partial<SetRow>) => {
    setExercises((prev) =>
      prev.map((ex) =>
        ex.id === exId
          ? {
              ...ex,
              sets: ex.sets.map((s) => (s.id === setId ? { ...s, ...patch } : s)),
            }
          : ex,
      ),
    );
  };

  const addExercise = () => setExercises((prev) => [...prev, makeEmptyExercise()]);

  const removeExercise = (id: string) =>
    setExercises((prev) => (prev.length === 1 ? prev : prev.filter((ex) => ex.id !== id)));

  const addSet = (exId: string) =>
    setExercises((prev) =>
      prev.map((ex) =>
        ex.id === exId
          ? { ...ex, sets: [...ex.sets, { id: uid(), weight: 0, reps: 0 }] }
          : ex,
      ),
    );

  const removeSet = (exId: string, setId: string) =>
    setExercises((prev) =>
      prev.map((ex) =>
        ex.id === exId
          ? {
              ...ex,
              sets: ex.sets.length === 1 ? ex.sets : ex.sets.filter((s) => s.id !== setId),
            }
          : ex,
      ),
    );

  // ─── CSV export ───
  const exportCsv = () => {
    const rows: string[][] = [
      ['Date', 'Exercise', 'Set', 'Weight (lb)', 'Reps', 'Volume'],
    ];
    exercises.forEach((ex) => {
      if (!ex.name.trim()) return;
      ex.sets.forEach((s, i) => {
        const vol = (s.weight || 0) * (s.reps || 0);
        rows.push([
          ex.date,
          ex.name.trim(),
          String(i + 1),
          String(s.weight || 0),
          String(s.reps || 0),
          String(vol),
        ]);
      });
    });
    const csv = rows
      .map((r) =>
        r
          .map((cell) => {
            const needsQuote = /[",\n]/.test(cell);
            const escaped = cell.replace(/"/g, '""');
            return needsQuote ? `"${escaped}"` : escaped;
          })
          .join(','),
      )
      .join('\n');
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `zealova-workout-log-${todayISO()}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  // ─── PDF export via print ───
  const exportPdf = () => {
    window.print();
  };

  return (
    <CalculatorShell
      slug="workout-log-exporter"
      title="Workout Log Exporter"
      metaDescription="Log workouts row by row in your browser. Export a clean CSV or print-friendly PDF in one click. No sign-up, no upload, everything stays local. Built for lifters who want their data, not another subscription."
      intro="Type your workout, drop it into a spreadsheet or a coach. Fully local: nothing leaves your browser. CSV for tracking, PDF for sharing or printing."
      emailCaptureResult={
        hasValidEntry
          ? {
              exerciseCount: exercises.filter((ex) => ex.name.trim()).length,
              totalSets,
              totalVolumeLb: totalVolume,
            }
          : undefined
      }
      installPrimary="Want this logged automatically after every set? Get Zealova."
      installSecondary="Zealova logs every rep in real time, tracks 1RM progression per exercise, and exports your full history as CSV/PDF in one tap."
      faqs={[
        {
          q: 'Does the CSV open in Excel and Google Sheets?',
          a: 'Yes. The CSV uses standard comma separators with proper quote escaping per RFC 4180, so Excel, Google Sheets, Numbers, and any spreadsheet tool will import it cleanly. Column headers: Date, Exercise, Set, Weight (lb), Reps, Volume.',
        },
        {
          q: 'How does the PDF export work?',
          a: 'It uses your browser\'s built-in print-to-PDF. Click Export as PDF, then in the print dialog choose Save as PDF as the destination. Works on every modern browser without installing anything.',
        },
        {
          q: 'Is anything uploaded to a server?',
          a: 'No. All entries live in your browser tab memory only. If you close the tab without exporting, the log is gone. This is by design so the tool is safe to use without an account.',
        },
        {
          q: 'What is volume and why is it on the CSV?',
          a: 'Volume = weight x reps for each set. It is the single best proxy for training stimulus per Schoenfeld 2017 and the metric most coaches track week over week. Total volume on the page shows your session sum.',
        },
        {
          q: 'Can I log multiple workouts on different dates?',
          a: 'Yes. Each exercise row has its own date field. Use it to back-fill a week of training or to log a few sessions before exporting. The CSV preserves the date column for sorting.',
        },
        {
          q: 'Does this support kg?',
          a: 'The form and CSV are lb-default because the majority of US lifters and most strength-standards databases use pounds. If you train in kg, type kg values into the weight box and rename the CSV header in your spreadsheet. Zealova natively supports separate workout-unit, body-weight-unit, and increment-unit settings.',
        },
        {
          q: 'Can I edit the CSV after exporting?',
          a: 'Of course. Open it in any spreadsheet, edit, save. The CSV is a one-way export, not a sync. For continuous logging with auto-progressing weights, that is what Zealova handles inside the app.',
        },
      ]}
    >
      {/* Print-only styles. When the user triggers Export as PDF we want a
          clean, printable view: hide nav, footer, CTAs and show only the
          log table. */}
      <style>
        {`@media print {
          body * { visibility: hidden; }
          #print-area, #print-area * { visibility: visible; }
          #print-area { position: absolute; left: 0; top: 0; width: 100%; padding: 24px; color: #000; background: #fff; }
          #print-area .print-title { font-size: 22px; font-weight: 700; margin-bottom: 8px; color: #000; }
          #print-area table { width: 100%; border-collapse: collapse; margin-top: 12px; font-size: 12px; }
          #print-area th, #print-area td { border: 1px solid #444; padding: 6px 8px; text-align: left; color: #000; }
          #print-area th { background: #eee; font-weight: 600; }
        }`}
      </style>

      {/* Action buttons */}
      <section className="flex flex-wrap items-center justify-between gap-3 bg-zinc-900 border border-zinc-800 rounded-2xl p-5">
        <div>
          <p className="text-sm text-zinc-400">
            <span className="text-white font-semibold">{exercises.length}</span>{' '}
            exercise{exercises.length === 1 ? '' : 's'}{' '}
            <span className="mx-2 text-zinc-700">|</span>{' '}
            <span className="text-white font-semibold">{totalSets}</span> total sets{' '}
            <span className="mx-2 text-zinc-700">|</span>{' '}
            <span className="text-emerald-400 font-semibold tabular-nums">
              {totalVolume.toLocaleString()}
            </span>{' '}
            lb volume
          </p>
        </div>
        <div className="flex gap-2">
          <button
            type="button"
            onClick={exportCsv}
            disabled={!hasValidEntry}
            className="px-4 py-2 rounded-lg bg-emerald-500 text-zinc-900 text-sm font-semibold hover:bg-emerald-400 transition disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Export as CSV
          </button>
          <button
            type="button"
            onClick={exportPdf}
            disabled={!hasValidEntry}
            className="px-4 py-2 rounded-lg bg-zinc-800 border border-zinc-700 text-white text-sm font-semibold hover:bg-zinc-700 transition disabled:opacity-40 disabled:cursor-not-allowed"
          >
            Export as PDF
          </button>
        </div>
      </section>

      {/* Editable log */}
      <section className="space-y-4">
        {exercises.map((ex, exIdx) => (
          <div
            key={ex.id}
            className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 space-y-4"
          >
            <div className="flex flex-wrap items-start justify-between gap-3">
              <div className="flex-1 min-w-0 grid grid-cols-1 sm:grid-cols-[180px_1fr] gap-3">
                <label className="block">
                  <span className="block text-[11px] font-semibold uppercase tracking-wider text-zinc-500 mb-1.5">
                    Date
                  </span>
                  <input
                    type="date"
                    value={ex.date}
                    onChange={(e) => updateExercise(ex.id, { date: e.target.value })}
                    className="w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </label>
                <label className="block">
                  <span className="block text-[11px] font-semibold uppercase tracking-wider text-zinc-500 mb-1.5">
                    Exercise {exIdx + 1}
                  </span>
                  <input
                    type="text"
                    placeholder="e.g. Barbell Back Squat"
                    value={ex.name}
                    onChange={(e) => updateExercise(ex.id, { name: e.target.value })}
                    className="w-full px-3 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm focus:outline-none focus:ring-2 focus:ring-emerald-500"
                  />
                </label>
              </div>
              {exercises.length > 1 && (
                <button
                  type="button"
                  onClick={() => removeExercise(ex.id)}
                  className="px-3 py-1.5 text-xs text-zinc-400 hover:text-rose-400 border border-zinc-800 rounded-md hover:border-rose-500/30 transition"
                  aria-label={`Remove exercise ${exIdx + 1}`}
                >
                  Remove
                </button>
              )}
            </div>

            {/* Sets table */}
            <div>
              <div className="grid grid-cols-[40px_1fr_1fr_90px_40px] gap-2 px-1 mb-1.5">
                <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
                  Set
                </span>
                <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
                  Weight (lb)
                </span>
                <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
                  Reps
                </span>
                <span className="text-[10px] font-semibold uppercase tracking-wider text-zinc-500 text-right">
                  Volume
                </span>
                <span />
              </div>
              <div className="space-y-1.5">
                {ex.sets.map((s, sIdx) => {
                  const vol = (s.weight || 0) * (s.reps || 0);
                  return (
                    <div
                      key={s.id}
                      className="grid grid-cols-[40px_1fr_1fr_90px_40px] gap-2 items-center"
                    >
                      <span className="text-sm text-zinc-500 tabular-nums text-center">
                        {sIdx + 1}
                      </span>
                      <input
                        type="number"
                        inputMode="decimal"
                        min={0}
                        step={2.5}
                        value={s.weight || ''}
                        onChange={(e) =>
                          updateSet(ex.id, s.id, {
                            weight: parseFloat(e.target.value) || 0,
                          })
                        }
                        placeholder="0"
                        className="w-full px-2.5 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm tabular-nums focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      />
                      <input
                        type="number"
                        inputMode="numeric"
                        min={0}
                        step={1}
                        value={s.reps || ''}
                        onChange={(e) =>
                          updateSet(ex.id, s.id, {
                            reps: parseInt(e.target.value, 10) || 0,
                          })
                        }
                        placeholder="0"
                        className="w-full px-2.5 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm tabular-nums focus:outline-none focus:ring-2 focus:ring-emerald-500"
                      />
                      <span className="text-sm font-medium text-zinc-300 tabular-nums text-right">
                        {vol > 0 ? vol.toLocaleString() : '—'}
                      </span>
                      <button
                        type="button"
                        onClick={() => removeSet(ex.id, s.id)}
                        disabled={ex.sets.length === 1}
                        className="text-zinc-600 hover:text-rose-400 text-lg leading-none disabled:opacity-30 disabled:cursor-not-allowed"
                        aria-label={`Remove set ${sIdx + 1}`}
                        title="Remove set"
                      >
                        ×
                      </button>
                    </div>
                  );
                })}
              </div>
              <button
                type="button"
                onClick={() => addSet(ex.id)}
                className="mt-2 text-xs text-emerald-400 hover:text-emerald-300 font-semibold"
              >
                + Add set
              </button>
            </div>
          </div>
        ))}

        <button
          type="button"
          onClick={addExercise}
          className="w-full px-4 py-3 rounded-xl bg-zinc-900 border border-dashed border-zinc-700 text-zinc-300 text-sm font-semibold hover:border-emerald-500/50 hover:text-emerald-400 transition"
        >
          + Add exercise
        </button>
      </section>

      {/* Print-only render target — keeps clean, monochrome view for PDF */}
      <div id="print-area" className="hidden print:block">
        <p className="print-title">Zealova Workout Log — {todayISO()}</p>
        <table>
          <thead>
            <tr>
              <th>Date</th>
              <th>Exercise</th>
              <th>Set</th>
              <th>Weight (lb)</th>
              <th>Reps</th>
              <th>Volume</th>
            </tr>
          </thead>
          <tbody>
            {exercises.flatMap((ex) =>
              ex.name.trim()
                ? ex.sets.map((s, i) => (
                    <tr key={`${ex.id}-${s.id}`}>
                      <td>{ex.date}</td>
                      <td>{ex.name}</td>
                      <td>{i + 1}</td>
                      <td>{s.weight || 0}</td>
                      <td>{s.reps || 0}</td>
                      <td>{(s.weight || 0) * (s.reps || 0)}</td>
                    </tr>
                  ))
                : [],
            )}
          </tbody>
        </table>
      </div>

      <MethodologyFooter
        citations={[
          {
            text: 'Schoenfeld BJ, Ogborn D, Krieger JW (2017). Dose-response relationship between weekly resistance training volume and increases in muscle mass: A systematic review and meta-analysis. JSS 35(11):1073-1082.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/27433992/',
          },
          {
            text: 'RFC 4180 — Common Format and MIME Type for CSV Files (IETF, 2005).',
            url: 'https://datatracker.ietf.org/doc/html/rfc4180',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}
