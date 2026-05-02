import { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import { BRANDING } from '../lib/branding';

const API_BASE = (import.meta.env.VITE_API_URL as string | undefined) ?? '/api/v1';

type SetEntry = {
  weight_kg?: number | null;
  weight?: number | null;
  reps?: number | null;
  rpe?: number | null;
  is_completed?: boolean;
};

type ExerciseEntry = {
  name?: string;
  exercise_name?: string;
  sets?: number | null;
  reps?: number | null;
  weight?: number | null;
  weight_kg?: number | null;
  sets_data?: SetEntry[];
};

type PublicWorkout = {
  id?: string;
  share_token: string;
  name?: string;
  workout_name?: string;
  duration_minutes?: number | null;
  duration_seconds?: number | null;
  estimated_duration_minutes?: number | null;
  total_volume_kg?: number | null;
  total_sets?: number | null;
  total_reps?: number | null;
  calories?: number | null;
  calories_burned?: number | null;
  completed_at?: string | null;
  exercises?: ExerciseEntry[];
  user_display_name?: string | null;
  metadata?: { sets_json?: unknown } | null;
};

const STORE_LINKS = {
  ios: 'https://apps.apple.com/app/id6753107983',
  android: 'https://play.google.com/store/apps/details?id=com.aifitnesscoach.app',
};

function fmtMinutes(w: PublicWorkout): string | null {
  const m =
    w.duration_minutes ??
    w.estimated_duration_minutes ??
    (w.duration_seconds ? Math.round(w.duration_seconds / 60) : null);
  return m != null ? `${m} min` : null;
}

function fmtVolume(w: PublicWorkout): string | null {
  if (w.total_volume_kg == null) return null;
  const lbs = Math.round(w.total_volume_kg * 2.20462);
  return `${lbs.toLocaleString()} lbs`;
}

function fmtDate(iso?: string | null): string | null {
  if (!iso) return null;
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return null;
  return d.toLocaleDateString(undefined, {
    weekday: 'long',
    month: 'short',
    day: 'numeric',
    year: 'numeric',
  });
}

function exerciseLabel(ex: ExerciseEntry): string {
  return (ex.name ?? ex.exercise_name ?? 'Exercise').toString();
}

function setSummary(ex: ExerciseEntry): string {
  const setsData = ex.sets_data ?? [];
  if (setsData.length > 0) {
    const completed = setsData.filter((s) => s.is_completed !== false);
    const totalReps = completed.reduce((a, s) => a + (s.reps ?? 0), 0);
    const w = completed.find((s) => (s.weight_kg ?? s.weight ?? 0) > 0);
    const weightKg = w?.weight_kg ?? w?.weight ?? null;
    const weightLbs = weightKg != null ? Math.round(weightKg * 2.20462) : null;
    return [
      `${completed.length} sets`,
      totalReps > 0 ? `${totalReps} reps` : null,
      weightLbs ? `@ ${weightLbs} lbs` : null,
    ]
      .filter(Boolean)
      .join(' · ');
  }
  const sets = ex.sets ?? 0;
  const reps = ex.reps ?? 0;
  if (sets > 0 && reps > 0) return `${sets} × ${reps}`;
  if (sets > 0) return `${sets} sets`;
  return '';
}

export default function PublicWorkout() {
  const { token } = useParams<{ token: string }>();
  const [data, setData] = useState<PublicWorkout | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token) return;
    let cancelled = false;
    (async () => {
      try {
        const res = await fetch(`${API_BASE}/workouts/public/${token}`);
        if (!res.ok) {
          if (!cancelled) setError(res.status === 404 ? 'Workout not found' : 'Could not load workout');
          return;
        }
        const json = (await res.json()) as PublicWorkout;
        if (!cancelled) setData(json);
      } catch (e) {
        if (!cancelled) setError('Network error — please try again');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => {
      cancelled = true;
    };
  }, [token]);

  useEffect(() => {
    if (!data) return;
    const name = data.name ?? data.workout_name ?? 'Workout';
    document.title = `${name} — ${BRANDING.appName}`;
  }, [data]);

  if (loading) {
    return (
      <Shell>
        <div className="text-center py-24 text-zinc-400">Loading workout…</div>
      </Shell>
    );
  }

  if (error || !data) {
    return (
      <Shell>
        <div className="max-w-md mx-auto py-24 text-center">
          <h1 className="text-2xl font-semibold text-white mb-2">
            {error ?? 'Workout not found'}
          </h1>
          <p className="text-zinc-400 mb-6">
            This share link may have been revoked or never existed.
          </p>
          <Link
            to="/"
            className="inline-block px-5 py-3 rounded-full bg-orange-500 hover:bg-orange-600 text-white font-medium"
          >
            Try {BRANDING.appName}
          </Link>
        </div>
      </Shell>
    );
  }

  const name = data.name ?? data.workout_name ?? 'Workout';
  const duration = fmtMinutes(data);
  const volume = fmtVolume(data);
  const totalSets = data.total_sets ?? null;
  const totalReps = data.total_reps ?? null;
  const calories = data.calories ?? data.calories_burned ?? null;
  const exercises = data.exercises ?? [];
  const dateLabel = fmtDate(data.completed_at);

  return (
    <Shell>
      <div className="max-w-2xl mx-auto px-4 py-10">
        {/* Header card */}
        <div className="rounded-3xl bg-gradient-to-br from-orange-500/20 via-zinc-900 to-zinc-900 border border-zinc-800 p-6 sm:p-8 shadow-xl">
          <div className="flex items-center gap-2 text-xs uppercase tracking-widest text-orange-400 mb-3">
            <span>✓ Workout complete</span>
            {dateLabel && <span className="text-zinc-500">· {dateLabel}</span>}
          </div>
          <h1 className="text-3xl sm:text-4xl font-bold text-white">{name}</h1>
          {data.user_display_name && (
            <p className="mt-1 text-zinc-400">by {data.user_display_name}</p>
          )}

          {/* Highlight metrics */}
          <div className="mt-6 grid grid-cols-2 sm:grid-cols-4 gap-3">
            {duration && <Metric label="Duration" value={duration} />}
            {volume && <Metric label="Volume" value={volume} />}
            {totalSets != null && <Metric label="Sets" value={String(totalSets)} />}
            {totalReps != null && totalReps > 0 && (
              <Metric label="Reps" value={String(totalReps)} />
            )}
            {calories != null && calories > 0 && (
              <Metric label="Calories" value={`${calories} kcal`} />
            )}
            <Metric label="Exercises" value={String(exercises.length)} />
          </div>
        </div>

        {/* Exercise list */}
        {exercises.length > 0 && (
          <div className="mt-6 rounded-3xl bg-zinc-900 border border-zinc-800 overflow-hidden">
            <div className="px-5 sm:px-6 py-4 border-b border-zinc-800">
              <h2 className="text-lg font-semibold text-white">Exercises</h2>
            </div>
            <ul className="divide-y divide-zinc-800">
              {exercises.map((ex, i) => (
                <li key={i} className="px-5 sm:px-6 py-4 flex items-center justify-between">
                  <div className="min-w-0">
                    <p className="text-white font-medium truncate">
                      {exerciseLabel(ex)}
                    </p>
                    <p className="text-sm text-zinc-400">{setSummary(ex)}</p>
                  </div>
                  <span className="text-zinc-600 text-sm flex-shrink-0 ml-3">
                    #{i + 1}
                  </span>
                </li>
              ))}
            </ul>
          </div>
        )}

        {/* CTA */}
        <div className="mt-8 rounded-3xl bg-zinc-900 border border-zinc-800 p-6 sm:p-8 text-center">
          <p className="text-zinc-300 text-base mb-1">
            Train smarter with <span className="text-white font-semibold">{BRANDING.appName}</span>
          </p>
          <p className="text-zinc-500 text-sm mb-5">
            AI-built workouts, real-time form coaching, and progress tracking.
          </p>
          <div className="flex flex-col sm:flex-row gap-3 justify-center">
            <a
              href={STORE_LINKS.ios}
              target="_blank"
              rel="noopener noreferrer"
              className="px-5 py-3 rounded-full bg-orange-500 hover:bg-orange-600 text-white font-medium"
            >
              Download for iOS
            </a>
            <a
              href={STORE_LINKS.android}
              target="_blank"
              rel="noopener noreferrer"
              className="px-5 py-3 rounded-full bg-zinc-800 hover:bg-zinc-700 text-white font-medium border border-zinc-700"
            >
              Download for Android
            </a>
          </div>
        </div>

        <p className="mt-6 text-center text-xs text-zinc-600">
          This workout was shared from {BRANDING.appName}. Anyone with this link
          can view it. The owner can revoke the link from the app at any time.
        </p>
      </div>
    </Shell>
  );
}

function Shell({ children }: { children: React.ReactNode }) {
  return (
    <div className="min-h-screen bg-zinc-950 text-white">
      <header className="border-b border-zinc-900">
        <div className="max-w-2xl mx-auto px-4 py-4 flex items-center justify-between">
          <Link to="/" className="text-white font-bold tracking-tight text-lg">
            {BRANDING.appName}
          </Link>
          <Link
            to="/"
            className="text-sm text-zinc-400 hover:text-white"
          >
            Get the app →
          </Link>
        </div>
      </header>
      {children}
    </div>
  );
}

function Metric({ label, value }: { label: string; value: string }) {
  return (
    <div className="rounded-2xl bg-black/30 border border-zinc-800 px-4 py-3">
      <p className="text-[10px] uppercase tracking-widest text-zinc-500">
        {label}
      </p>
      <p className="text-lg font-semibold text-white mt-0.5">{value}</p>
    </div>
  );
}
