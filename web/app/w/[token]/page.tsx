/**
 * Public workout share view.
 *
 * Consumed at https://zealova.com/w/[token]. Renders the Hevy-style workout
 * card from the FastAPI public endpoint and offers App Store / Play Store
 * CTAs so anonymous viewers convert.
 */
import type { Metadata } from "next";
import { notFound } from "next/navigation";

export const revalidate = 60;

const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.zealova.com";

type Set = {
  set_number: number;
  weight_kg: number | null;
  reps_completed: number;
};

type Exercise = {
  name: string;
  image_url?: string | null;
  sets: Set[];
};

type PublicWorkout = {
  share_token: string;
  name: string;
  duration_minutes: number | null;
  calories_burned: number | null;
  completed_at: string | null;
  exercises: Exercise[];
  display_name: string | null;
};

async function fetchWorkout(token: string): Promise<PublicWorkout | null> {
  const res = await fetch(`${API_BASE}/api/v1/workouts/public/${token}`, {
    next: { revalidate: 60 },
  });
  if (!res.ok) return null;
  return (await res.json()) as PublicWorkout;
}

export async function generateMetadata({
  params,
}: {
  params: { token: string };
}): Promise<Metadata> {
  const w = await fetchWorkout(params.token);
  if (!w) return { title: "Zealova — Workout" };
  const title = `${w.name} — Zealova`;
  const description = `${w.exercises?.length ?? 0} exercises · ${
    w.duration_minutes ?? 0
  } min · shared from Zealova`;
  return {
    title,
    description,
    openGraph: { title, description, type: "article" },
    twitter: { card: "summary_large_image", title, description },
  };
}

function fmtDuration(min: number | null) {
  if (!min) return "—";
  if (min < 60) return `${min}m`;
  return `${Math.floor(min / 60)}h ${min % 60}m`;
}

function totalVolumeKg(ex: Exercise[]) {
  return ex.reduce(
    (sum, e) =>
      sum +
      e.sets.reduce(
        (s, st) => s + (st.weight_kg ?? 0) * (st.reps_completed ?? 0),
        0,
      ),
    0,
  );
}

export default async function PublicWorkoutPage({
  params,
}: {
  params: { token: string };
}) {
  const w = await fetchWorkout(params.token);
  if (!w) notFound();
  const volumeKg = totalVolumeKg(w.exercises ?? []);

  return (
    <main className="min-h-screen bg-neutral-950 text-neutral-100">
      <header className="flex items-center justify-between px-6 py-4 border-b border-neutral-800">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-md bg-gradient-to-br from-cyan-400 to-fuchsia-500" />
          <span className="font-bold tracking-tight">Zealova</span>
        </div>
        <span className="text-xs text-neutral-400">
          Created by {w.display_name ?? "Zealova lifter"}
        </span>
      </header>

      <section className="max-w-2xl mx-auto p-6">
        <h1 className="text-3xl font-black leading-tight">{w.name}</h1>
        <div className="mt-2 flex flex-wrap gap-x-5 gap-y-2 text-sm text-neutral-300">
          <span>
            <span className="text-neutral-500 mr-1">Duration</span>
            <strong>{fmtDuration(w.duration_minutes)}</strong>
          </span>
          {volumeKg > 0 && (
            <span>
              <span className="text-neutral-500 mr-1">Volume</span>
              <strong>{Math.round(volumeKg)} kg</strong>
            </span>
          )}
          <span>
            <span className="text-neutral-500 mr-1">Exercises</span>
            <strong>{w.exercises?.length ?? 0}</strong>
          </span>
          {w.calories_burned ? (
            <span>
              <span className="text-neutral-500 mr-1">Calories</span>
              <strong>{w.calories_burned} kcal</strong>
            </span>
          ) : null}
        </div>

        <ul className="mt-8 divide-y divide-neutral-800 rounded-2xl bg-neutral-900 px-5">
          {(w.exercises ?? []).map((ex, i) => (
            <li key={i} className="py-4 flex gap-3">
              <div className="w-11 h-11 shrink-0 rounded-lg bg-neutral-800 flex items-center justify-center text-neutral-500 text-xs">
                {ex.image_url ? (
                  // eslint-disable-next-line @next/next/no-img-element
                  <img
                    src={ex.image_url}
                    alt=""
                    className="w-full h-full object-cover rounded-lg"
                  />
                ) : (
                  "🏋️"
                )}
              </div>
              <div className="flex-1 min-w-0">
                <div className="font-bold truncate">{ex.name}</div>
                {ex.sets?.length > 0 && (
                  <div className="mt-1 grid grid-cols-[28px_1fr] gap-y-0.5 text-xs">
                    <span className="text-neutral-500 font-bold tracking-wider">
                      SET
                    </span>
                    <span className="text-neutral-500 font-bold tracking-wider">
                      WEIGHT &amp; REPS
                    </span>
                    {ex.sets.map((s, j) => (
                      <>
                        <span key={`n-${j}`} className="text-neutral-300">
                          {s.set_number ?? j + 1}
                        </span>
                        <span key={`v-${j}`} className="text-neutral-200">
                          {s.weight_kg
                            ? `${Math.round(s.weight_kg)} kg`
                            : "—"}{" "}
                          × {s.reps_completed ?? 0} reps
                        </span>
                      </>
                    ))}
                  </div>
                )}
              </div>
            </li>
          ))}
        </ul>

        <div className="mt-10 rounded-2xl bg-gradient-to-br from-cyan-500/10 via-fuchsia-500/10 to-amber-500/10 p-5 text-center">
          <h2 className="text-lg font-bold">Get Zealova</h2>
          <p className="mt-1 text-sm text-neutral-300">
            Build, log, and share workouts like this one.
          </p>
          <div className="mt-4 flex justify-center gap-3">
            <a
              href="https://apps.apple.com/app/zealova/id6738049122"
              className="px-4 py-2 rounded-lg bg-white text-black text-sm font-bold"
            >
              App Store
            </a>
            <a
              href="https://play.google.com/store/apps/details?id=com.aifitnesscoach.app"
              className="px-4 py-2 rounded-lg bg-white text-black text-sm font-bold"
            >
              Google Play
            </a>
          </div>
        </div>
      </section>
    </main>
  );
}
