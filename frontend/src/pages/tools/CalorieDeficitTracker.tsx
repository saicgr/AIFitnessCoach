// /free-tools/calorie-deficit-tracker
//
// 7-day deficit tracker with localStorage persistence. User enters TDEE
// once, then logs daily kcal eaten + optional body weight. Auto-computes
// daily deficit, weekly totals, projected fat loss.

import { useEffect, useMemo, useState } from 'react';
import CalculatorShell from '../../components/tools/CalculatorShell';
import MethodologyFooter from '../../components/tools/MethodologyFooter';

const STORAGE_KEY = 'zealova-deficit-tracker-v1';

interface DayEntry {
  date: string;       // YYYY-MM-DD
  kcal: number | null;
  weightLb: number | null;
}

interface StoredState {
  tdee: number;
  days: DayEntry[];
}

function todayISO(offset = 0): string {
  const d = new Date();
  d.setDate(d.getDate() + offset);
  const yyyy = d.getFullYear();
  const mm = String(d.getMonth() + 1).padStart(2, '0');
  const dd = String(d.getDate()).padStart(2, '0');
  return `${yyyy}-${mm}-${dd}`;
}

function defaultDays(): DayEntry[] {
  const out: DayEntry[] = [];
  for (let i = 0; i < 7; i++) {
    out.push({ date: todayISO(i), kcal: null, weightLb: null });
  }
  return out;
}

function loadState(): StoredState {
  if (typeof window === 'undefined') return { tdee: 2200, days: defaultDays() };
  try {
    const raw = window.localStorage.getItem(STORAGE_KEY);
    if (!raw) return { tdee: 2200, days: defaultDays() };
    const parsed = JSON.parse(raw) as StoredState;
    if (!parsed.days || parsed.days.length !== 7 || !parsed.tdee) {
      return { tdee: parsed.tdee ?? 2200, days: defaultDays() };
    }
    return parsed;
  } catch {
    return { tdee: 2200, days: defaultDays() };
  }
}

function saveState(state: StoredState) {
  if (typeof window === 'undefined') return;
  try {
    window.localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch {
    // ignore quota errors
  }
}

export default function CalorieDeficitTracker() {
  const [tdee, setTdee] = useState<number>(2200);
  const [days, setDays] = useState<DayEntry[]>(defaultDays());
  const [hydrated, setHydrated] = useState<boolean>(false);

  // Hydrate from localStorage once on mount.
  useEffect(() => {
    const s = loadState();
    setTdee(s.tdee);
    setDays(s.days);
    setHydrated(true);
  }, []);

  // Persist on every change after initial hydration.
  useEffect(() => {
    if (!hydrated) return;
    saveState({ tdee, days });
  }, [tdee, days, hydrated]);

  const updateDay = (idx: number, patch: Partial<DayEntry>) => {
    setDays((prev) => prev.map((d, i) => (i === idx ? { ...d, ...patch } : d)));
  };

  const resetWeek = () => {
    if (!window.confirm('Clear all 7 days of data? This cannot be undone.')) return;
    setDays(defaultDays());
  };

  // ─── Stats ───
  const stats = useMemo(() => {
    const filledDays = days.filter((d) => d.kcal !== null && d.kcal > 0);
    const totalDeficit = filledDays.reduce((acc, d) => acc + (tdee - (d.kcal || 0)), 0);
    const avgDeficit = filledDays.length > 0 ? totalDeficit / filledDays.length : 0;
    // 1 lb fat ≈ 3,500 kcal (textbook static rule). Project from total deficit so far.
    const projectedFatLossLb = totalDeficit / 3500;
    return {
      filled: filledDays.length,
      totalDeficit: Math.round(totalDeficit),
      avgDeficit: Math.round(avgDeficit),
      projectedFatLossLb: Math.round(projectedFatLossLb * 100) / 100,
    };
  }, [days, tdee]);

  const day1HasData = days[0].kcal !== null && days[0].kcal > 0;

  return (
    <CalculatorShell
      slug="calorie-deficit-tracker"
      title="Calorie Deficit Tracker (7-Day)"
      metaDescription="Track your calorie deficit across 7 days. Auto-saves to your browser. Enter daily intake, optional weight, see total deficit and projected fat loss. Free, no sign-up, no upload. Uses the textbook 3,500 kcal-per-pound static rule."
      intro="Log your week. The tracker saves to your browser so you can come back tomorrow without re-typing anything. Total deficit, average deficit, projected fat loss all update live."
      emailCaptureResult={
        day1HasData
          ? {
              tdee,
              filledDays: stats.filled,
              totalDeficit: stats.totalDeficit,
              avgDeficit: stats.avgDeficit,
              projectedFatLossLb: stats.projectedFatLossLb,
            }
          : undefined
      }
      installPrimary="Stop typing this into a web form every day."
      installSecondary="Zealova auto-logs calories from photo scans, weight from your daily check-in, and re-calculates your deficit weekly using metabolic adaptation modeling. Free 7-day trial."
      faqs={[
        {
          q: 'Where does the 3,500 kcal per pound number come from?',
          a: 'Classical static rule from Wishnofsky 1958 — 1 lb of body fat stores roughly 3,500 kcal. Modern research (Hall et al. 2011) shows fat loss adapts over time, so the rule is most accurate over the first 6 to 12 weeks. We use it for projection because it is the cleanest mental model for daily decisions.',
        },
        {
          q: 'How do I know my TDEE?',
          a: 'If you don\'t already know it, use our free TDEE calculator. The default 2,200 is a US-average ballpark. After 2 weeks of consistent tracking, you can back-calculate your real TDEE from intake and weight change.',
        },
        {
          q: 'Is the projected fat loss realistic?',
          a: 'The math is correct under the assumption you stay compliant. Real-world week 1 weight loss is often higher (glycogen + water flush) then settles to ~0.5 to 1 lb per week. If you see less, your TDEE is probably overestimated. If much more, possibly underestimated or you cut very aggressively.',
        },
        {
          q: 'Will my data sync across devices?',
          a: 'No — the data lives in this browser tab\'s localStorage only. Clearing browser data or using incognito will erase it. For real cross-device tracking with photo logging, Zealova does that in the app.',
        },
        {
          q: 'Why is my weight up even though I am in a deficit?',
          a: 'Day-to-day weight is dominated by water, sodium, glycogen, menstrual cycle, and bowel content. The signal is the 7-day rolling average, not the daily reading. Stay the course; the trend line is what matters.',
        },
        {
          q: 'Should I track every day or just weekdays?',
          a: 'Every day. Weekend overshoots are the #1 reason people don\'t lose weight on what looks like a clean week. The weekly average is what drives loss, and skipping weekend logging hides 30% of the data.',
        },
        {
          q: 'What if I went over TDEE on a day?',
          a: 'The tracker still records it — the deficit goes negative, which lowers your weekly total. That\'s how it should work. One day over does not break a week; consistent weekly average is what counts. Don\'t cut harder the next day to compensate, that compounds adherence problems.',
        },
      ]}
    >
      {/* TDEE input */}
      <section className="bg-zinc-900 border border-zinc-800 rounded-2xl p-5 sm:p-7">
        <div className="grid grid-cols-1 sm:grid-cols-[1fr_auto] gap-4 items-end">
          <label className="block">
            <span className="block text-sm font-medium text-zinc-300 mb-2">
              Your daily maintenance calories (TDEE)
            </span>
            <input
              type="number"
              inputMode="numeric"
              min={1000}
              max={6000}
              step={50}
              value={tdee}
              onChange={(e) => setTdee(parseInt(e.target.value, 10) || 0)}
              className="w-full px-4 py-3 rounded-xl bg-zinc-950 border border-zinc-700 text-white text-lg font-semibold tabular-nums focus:outline-none focus:ring-2 focus:ring-emerald-500"
            />
            <p className="text-xs text-zinc-500 mt-2">
              Not sure?{' '}
              <a
                href="/free-tools/tdee-calculator"
                className="text-emerald-400 hover:text-emerald-300 underline"
              >
                Calculate it
              </a>
              . Default 2,200 is a US-average ballpark.
            </p>
          </label>
          <button
            type="button"
            onClick={resetWeek}
            className="px-4 py-2.5 rounded-lg bg-zinc-800 border border-zinc-700 text-zinc-300 text-sm font-medium hover:bg-zinc-700 transition"
          >
            Reset week
          </button>
        </div>
      </section>

      {/* Day grid */}
      <section>
        <h2 className="text-lg font-bold text-white mb-1">Daily log</h2>
        <p className="text-sm text-zinc-400 mb-4">
          Tap a row to enter today's calories. Weight is optional.
        </p>
        <div className="space-y-2">
          <div className="grid grid-cols-[80px_1fr_1fr_110px] gap-2 px-2 text-[10px] font-semibold uppercase tracking-wider text-zinc-500">
            <span>Day</span>
            <span>Kcal eaten</span>
            <span>Weight (lb)</span>
            <span className="text-right">Deficit</span>
          </div>
          {days.map((d, idx) => {
            const deficit = d.kcal !== null && d.kcal > 0 ? tdee - d.kcal : null;
            const isToday = d.date === todayISO();
            return (
              <div
                key={d.date}
                className={`grid grid-cols-[80px_1fr_1fr_110px] gap-2 items-center px-2 py-1.5 rounded-lg ${
                  isToday ? 'bg-emerald-500/5 border border-emerald-500/20' : ''
                }`}
              >
                <div>
                  <p className="text-sm font-semibold text-white">Day {idx + 1}</p>
                  <p className="text-[10px] text-zinc-500">{d.date.slice(5)}</p>
                </div>
                <input
                  type="number"
                  inputMode="numeric"
                  min={0}
                  max={10000}
                  step={50}
                  value={d.kcal ?? ''}
                  onChange={(e) =>
                    updateDay(idx, {
                      kcal: e.target.value === '' ? null : parseInt(e.target.value, 10),
                    })
                  }
                  placeholder="—"
                  className="w-full px-2.5 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm tabular-nums focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
                <input
                  type="number"
                  inputMode="decimal"
                  min={0}
                  max={1000}
                  step={0.1}
                  value={d.weightLb ?? ''}
                  onChange={(e) =>
                    updateDay(idx, {
                      weightLb:
                        e.target.value === '' ? null : parseFloat(e.target.value),
                    })
                  }
                  placeholder="optional"
                  className="w-full px-2.5 py-2 rounded-lg bg-zinc-950 border border-zinc-700 text-white text-sm tabular-nums focus:outline-none focus:ring-2 focus:ring-emerald-500"
                />
                <span
                  className={`text-sm font-semibold tabular-nums text-right ${
                    deficit === null
                      ? 'text-zinc-600'
                      : deficit >= 0
                        ? 'text-emerald-400'
                        : 'text-rose-400'
                  }`}
                >
                  {deficit === null ? '—' : `${deficit > 0 ? '−' : '+'}${Math.abs(deficit)}`}
                </span>
              </div>
            );
          })}
        </div>
      </section>

      {/* Stats */}
      <section className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        <StatCard
          label="Days logged"
          value={`${stats.filled}`}
          unit="/ 7"
          emphasis={stats.filled >= 4}
        />
        <StatCard
          label="Total deficit"
          value={stats.totalDeficit.toLocaleString()}
          unit="kcal"
          emphasis
        />
        <StatCard
          label="Avg daily deficit"
          value={stats.avgDeficit.toLocaleString()}
          unit="kcal"
        />
        <StatCard
          label="Projected fat loss"
          value={`${stats.projectedFatLossLb}`}
          unit="lb"
          emphasis
        />
      </section>

      {/* Streak banner once user has 4+ days */}
      {stats.filled >= 4 && (
        <section className="rounded-2xl border border-emerald-500/30 bg-gradient-to-br from-emerald-900/40 to-zinc-900 p-5 sm:p-6">
          <p className="text-xs font-semibold uppercase tracking-wider text-emerald-400 mb-1">
            Consistency milestone
          </p>
          <p className="text-lg font-bold text-white mb-1">
            You've been consistent {stats.filled} days running.
          </p>
          <p className="text-sm text-zinc-400 mb-4">
            Zealova tracks this automatically and adjusts your targets based on weight trend.
          </p>
          <a
            href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app&referrer=utm_source%3Dtools%26utm_medium%3Dcalorie-deficit-tracker%26utm_content%3Dconsistency-banner"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-flex items-center gap-2 px-4 py-2.5 rounded-lg bg-emerald-500 text-zinc-900 text-sm font-semibold hover:bg-emerald-400 transition"
          >
            Start free trial →
          </a>
        </section>
      )}

      <MethodologyFooter
        citations={[
          {
            text: 'Wishnofsky M (1958). Caloric equivalents of gained or lost weight. Am J Clin Nutr 6:542-546.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/13594881/',
          },
          {
            text: 'Hall KD, Sacks G, Chandramohan D, et al. (2011). Quantification of the effect of energy imbalance on bodyweight. Lancet 378:826-37.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/21872751/',
          },
          {
            text: 'Helms ER, Aragon AA, Fitschen PJ (2014). Evidence-based recommendations for natural bodybuilding contest preparation: nutrition and supplementation. JISSN 11:20.',
            url: 'https://pubmed.ncbi.nlm.nih.gov/24864135/',
          },
        ]}
        lastUpdated="2026-05-15"
      />
    </CalculatorShell>
  );
}

function StatCard({
  label,
  value,
  unit,
  emphasis = false,
}: {
  label: string;
  value: string;
  unit: string;
  emphasis?: boolean;
}) {
  const border = emphasis
    ? 'border-emerald-500/30 bg-emerald-500/5'
    : 'border-zinc-800 bg-zinc-900';
  const valueClass = emphasis ? 'text-emerald-400' : 'text-white';
  return (
    <div className={`rounded-xl border ${border} px-4 py-3.5`}>
      <p className="text-[10px] text-zinc-500 uppercase tracking-wider font-semibold">
        {label}
      </p>
      <p className={`text-2xl font-bold mt-1 tabular-nums ${valueClass}`}>
        {value}
        {unit && <span className="text-sm text-zinc-500 ml-1 font-medium">{unit}</span>}
      </p>
    </div>
  );
}
