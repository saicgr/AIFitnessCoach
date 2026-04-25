/**
 * Public plan / period share view.
 *
 * Consumed at https://fitwiz.us/p/[token]. Renders one of three layouts
 * depending on the share's `period`:
 *   - day           → single-workout card (mirrors /w/[token])
 *   - week          → Mon–Sun grid (3-col desktop, stacked on mobile)
 *   - month/ytd     → calendar-style grid keyed by scheduled_date
 *   - custom        → date-ordered list
 *
 * Snapshot is frozen at share-creation time (see backend/api/v1/plan_share_link.py),
 * so the public URL is permanent even if the user's plan changes after sharing.
 */
import type { Metadata } from "next";
import { notFound } from "next/navigation";

export const revalidate = 60;

const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.fitwiz.us";

type ExerciseSet = {
  set_number?: number;
  weight_kg?: number | null;
  reps_completed?: number;
  reps?: number;
};

type Exercise = {
  name: string;
  image_url?: string | null;
  gif_url?: string | null;
  illustration_url?: string | null;
  sets?: ExerciseSet[];
  default_sets?: number;
  default_reps?: number;
};

type SnapshotWorkout = {
  id: string;
  name: string;
  type?: string | null;
  scheduled_date: string;
  is_completed: boolean;
  duration_minutes?: number | null;
  estimated_calories?: number | null;
  exercises: Exercise[];
};

type Snapshot = {
  workouts: SnapshotWorkout[];
  summary: {
    total_workouts: number;
    completed_workouts: number;
    total_duration_minutes: number;
    date_range: { start: string; end: string };
  };
};

type PublicPlan = {
  share_token: string;
  scope: "plan" | "prs" | "one_rm" | "summary";
  period: "day" | "week" | "month" | "ytd" | "custom";
  start_date: string;
  end_date: string;
  snapshot: Snapshot;
  display_name: string | null;
  username: string | null;
  avatar_url: string | null;
};

async function fetchPlan(token: string): Promise<PublicPlan | null> {
  const res = await fetch(`${API_BASE}/api/v1/plans/public/${token}`, {
    next: { revalidate: 60 },
  });
  if (!res.ok) return null;
  return (await res.json()) as PublicPlan;
}

export async function generateMetadata({
  params,
}: {
  params: { token: string };
}): Promise<Metadata> {
  const p = await fetchPlan(params.token);
  if (!p) return { title: "FitWiz — Plan" };
  const periodLabel = labelForPeriod(p.period, p.start_date, p.end_date);
  const title = `${periodLabel} — FitWiz`;
  const n = p.snapshot?.workouts?.length ?? 0;
  const description = `${n} ${n === 1 ? "workout" : "workouts"} · shared by ${p.display_name ?? "FitWiz lifter"}`;
  return {
    title,
    description,
    openGraph: { title, description, type: "article" },
    twitter: { card: "summary_large_image", title, description },
  };
}

function labelForPeriod(
  period: PublicPlan["period"],
  start: string,
  end: string,
) {
  const startDate = new Date(start + "T00:00:00");
  const endDate = new Date(end + "T00:00:00");
  const fmtMonth = startDate.toLocaleDateString("en-US", {
    month: "long",
    year: "numeric",
  });
  switch (period) {
    case "day":
      return startDate.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    case "week":
      return `Week of ${startDate.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      })}`;
    case "month":
      return `${fmtMonth} Program`;
    case "ytd":
      return `${startDate.getFullYear()} Year to Date`;
    case "custom":
      return `${startDate.toLocaleDateString()} – ${endDate.toLocaleDateString()}`;
  }
}

function fmtDuration(min: number | null | undefined) {
  if (!min) return "—";
  if (min < 60) return `${min}m`;
  return `${Math.floor(min / 60)}h ${min % 60}m`;
}

function exerciseImage(ex: Exercise): string | null {
  return ex.image_url ?? ex.gif_url ?? ex.illustration_url ?? null;
}

function setLabel(s: ExerciseSet) {
  const reps = s.reps_completed ?? s.reps ?? 0;
  if (s.weight_kg) return `${Math.round(s.weight_kg)} kg × ${reps} reps`;
  return `${reps} reps`;
}

function StoreCTAs() {
  return (
    <div className="mt-10 rounded-2xl bg-gradient-to-br from-cyan-500/10 via-fuchsia-500/10 to-amber-500/10 p-5 text-center">
      <h2 className="text-lg font-bold">Get FitWiz</h2>
      <p className="mt-1 text-sm text-neutral-300">
        Build, log, and share workouts like this one.
      </p>
      <div className="mt-4 flex justify-center gap-3">
        <a
          href="https://apps.apple.com/app/fitwiz/id6738049122"
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
  );
}

function ProfileLink({
  displayName,
  username,
  avatarUrl,
}: {
  displayName: string | null;
  username: string | null;
  avatarUrl: string | null;
}) {
  const inner = (
    <>
      {avatarUrl ? (
        // eslint-disable-next-line @next/next/no-img-element
        <img
          src={avatarUrl}
          alt=""
          className="w-6 h-6 rounded-full object-cover"
        />
      ) : (
        <div className="w-6 h-6 rounded-full bg-gradient-to-br from-cyan-400 to-fuchsia-500" />
      )}
      <span>{displayName ?? "FitWiz lifter"}</span>
    </>
  );
  if (!username) {
    return (
      <span className="flex items-center gap-2 text-xs text-neutral-400">
        {inner}
      </span>
    );
  }
  return (
    <a
      href={`/u/${username}`}
      className="flex items-center gap-2 text-xs text-neutral-300 hover:text-white"
    >
      {inner}
    </a>
  );
}

function ExerciseRow({ ex }: { ex: Exercise }) {
  const img = exerciseImage(ex);
  return (
    <li className="py-3 flex gap-3">
      <div className="w-9 h-9 shrink-0 rounded-md bg-neutral-800 flex items-center justify-center text-xs">
        {img ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={img}
            alt=""
            loading="lazy"
            className="w-full h-full object-cover rounded-md"
          />
        ) : (
          "🏋️"
        )}
      </div>
      <div className="flex-1 min-w-0">
        <div className="font-semibold truncate text-sm">{ex.name}</div>
        {ex.sets && ex.sets.length > 0 ? (
          <div className="mt-0.5 text-xs text-neutral-400">
            {ex.sets.length} sets · {setLabel(ex.sets[0])}
          </div>
        ) : ex.default_sets || ex.default_reps ? (
          <div className="mt-0.5 text-xs text-neutral-400">
            {ex.default_sets ?? "?"} sets · {ex.default_reps ?? "?"} reps
          </div>
        ) : null}
      </div>
    </li>
  );
}

function SingleWorkoutCard({ w }: { w: SnapshotWorkout }) {
  return (
    <article className="rounded-2xl bg-neutral-900 p-5">
      <header className="flex items-baseline justify-between gap-3">
        <h3 className="text-lg font-bold truncate">{w.name}</h3>
        <span className="text-xs text-neutral-400 shrink-0">
          {new Date(w.scheduled_date + "T00:00:00").toLocaleDateString("en-US", {
            weekday: "short",
            month: "short",
            day: "numeric",
          })}
        </span>
      </header>
      <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-neutral-400">
        <span>{w.exercises?.length ?? 0} exercises</span>
        {w.duration_minutes ? <span>{fmtDuration(w.duration_minutes)}</span> : null}
        {w.estimated_calories ? <span>{w.estimated_calories} kcal</span> : null}
        {w.is_completed ? (
          <span className="text-emerald-400">✓ completed</span>
        ) : (
          <span className="text-neutral-500">scheduled</span>
        )}
      </div>
      <ul className="mt-3 divide-y divide-neutral-800">
        {(w.exercises ?? []).map((ex, i) => (
          <ExerciseRow key={i} ex={ex} />
        ))}
      </ul>
    </article>
  );
}

function DAYS_OF_WEEK_FROM(start: Date): Date[] {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    return d;
  });
}

function WeekGrid({ plan }: { plan: PublicPlan }) {
  const start = new Date(plan.start_date + "T00:00:00");
  const days = DAYS_OF_WEEK_FROM(start);
  const byDate = new Map<string, SnapshotWorkout>();
  for (const w of plan.snapshot.workouts) {
    if (w.scheduled_date) byDate.set(w.scheduled_date.slice(0, 10), w);
  }
  return (
    <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
      {days.map((d) => {
        const iso = d.toISOString().slice(0, 10);
        const w = byDate.get(iso);
        const dayLabel = d.toLocaleDateString("en-US", {
          weekday: "short",
          month: "short",
          day: "numeric",
        });
        return (
          <article key={iso} className="rounded-xl bg-neutral-900 p-4">
            <header className="text-xs uppercase tracking-wider text-neutral-500">
              {dayLabel}
            </header>
            {w ? (
              <>
                <div className="mt-2 font-bold truncate">{w.name}</div>
                <ul className="mt-2 space-y-1 text-xs text-neutral-300">
                  {(w.exercises ?? []).slice(0, 8).map((ex, i) => (
                    <li key={i} className="flex items-center gap-2">
                      {(() => {
                        const img = exerciseImage(ex);
                        return img ? (
                          // eslint-disable-next-line @next/next/no-img-element
                          <img
                            src={img}
                            alt=""
                            loading="lazy"
                            className="w-5 h-5 rounded object-cover"
                          />
                        ) : (
                          <div className="w-5 h-5 rounded bg-neutral-800" />
                        );
                      })()}
                      <span className="truncate">
                        {ex.name}
                        {ex.sets?.length
                          ? ` · ${ex.sets.length}×${
                              ex.sets[0].reps_completed ?? ex.sets[0].reps ?? "?"
                            }`
                          : ex.default_sets || ex.default_reps
                            ? ` · ${ex.default_sets ?? "?"}×${ex.default_reps ?? "?"}`
                            : ""}
                      </span>
                    </li>
                  ))}
                  {w.exercises && w.exercises.length > 8 ? (
                    <li className="text-neutral-500">
                      +{w.exercises.length - 8} more
                    </li>
                  ) : null}
                </ul>
              </>
            ) : (
              <div className="mt-3 text-xs text-neutral-600 italic">Rest day</div>
            )}
          </article>
        );
      })}
    </div>
  );
}

function MonthCalendar({ plan }: { plan: PublicPlan }) {
  const start = new Date(plan.start_date + "T00:00:00");
  const end = new Date(plan.end_date + "T00:00:00");
  const totalDays =
    Math.floor((end.getTime() - start.getTime()) / 86400000) + 1;
  const offset = (start.getDay() + 6) % 7; // shift so Monday is column 0
  const cells: (Date | null)[] = Array(offset).fill(null);
  for (let i = 0; i < totalDays; i++) {
    const d = new Date(start);
    d.setDate(d.getDate() + i);
    cells.push(d);
  }
  while (cells.length % 7 !== 0) cells.push(null);

  const byDate = new Map<string, SnapshotWorkout>();
  for (const w of plan.snapshot.workouts) {
    if (w.scheduled_date) byDate.set(w.scheduled_date.slice(0, 10), w);
  }

  return (
    <div>
      <div className="grid grid-cols-7 text-[10px] uppercase tracking-wider text-neutral-500 mb-2">
        {["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"].map((d) => (
          <div key={d} className="px-1">
            {d}
          </div>
        ))}
      </div>
      <div className="grid grid-cols-7 gap-1.5">
        {cells.map((d, i) => {
          if (!d) return <div key={i} className="aspect-square" />;
          const iso = d.toISOString().slice(0, 10);
          const w = byDate.get(iso);
          return (
            <div
              key={i}
              className={`aspect-square rounded-md p-1.5 text-[10px] ${
                w ? "bg-neutral-800" : "bg-neutral-900"
              }`}
            >
              <div className="text-neutral-500">{d.getDate()}</div>
              {w ? (
                <div
                  className={`mt-0.5 font-bold leading-tight line-clamp-2 ${
                    w.is_completed ? "text-emerald-400" : "text-neutral-200"
                  }`}
                >
                  {w.name}
                </div>
              ) : null}
            </div>
          );
        })}
      </div>
    </div>
  );
}

export default async function PublicPlanPage({
  params,
}: {
  params: { token: string };
}) {
  const plan = await fetchPlan(params.token);
  if (!plan) notFound();

  const periodLabel = labelForPeriod(
    plan.period,
    plan.start_date,
    plan.end_date,
  );
  const summary = plan.snapshot?.summary;

  return (
    <main className="min-h-screen bg-neutral-950 text-neutral-100">
      <header className="flex items-center justify-between px-6 py-4 border-b border-neutral-800">
        <div className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-md bg-gradient-to-br from-cyan-400 to-fuchsia-500" />
          <span className="font-bold tracking-tight">FitWiz</span>
        </div>
        <ProfileLink
          displayName={plan.display_name}
          username={plan.username}
          avatarUrl={plan.avatar_url}
        />
      </header>

      <section className="max-w-4xl mx-auto p-6">
        <h1 className="text-3xl font-black leading-tight">{periodLabel}</h1>
        {summary && (
          <div className="mt-2 flex flex-wrap gap-x-5 gap-y-2 text-sm text-neutral-300">
            <span>
              <span className="text-neutral-500 mr-1">Workouts</span>
              <strong>{summary.total_workouts}</strong>
            </span>
            <span>
              <span className="text-neutral-500 mr-1">Completed</span>
              <strong>{summary.completed_workouts}</strong>
            </span>
            {summary.total_duration_minutes > 0 && (
              <span>
                <span className="text-neutral-500 mr-1">Total time</span>
                <strong>{fmtDuration(summary.total_duration_minutes)}</strong>
              </span>
            )}
          </div>
        )}

        <div className="mt-8">
          {plan.period === "day" && plan.snapshot.workouts[0] && (
            <SingleWorkoutCard w={plan.snapshot.workouts[0]} />
          )}
          {plan.period === "week" && <WeekGrid plan={plan} />}
          {(plan.period === "month" ||
            plan.period === "ytd" ||
            plan.period === "custom") && <MonthCalendar plan={plan} />}
        </div>

        <StoreCTAs />
      </section>
    </main>
  );
}
