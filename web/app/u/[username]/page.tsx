/**
 * Public profile page.
 *
 * Consumed at https://fitwiz.us/u/[username]. Renders profile header
 * (avatar, displayName, @username, Workouts/Followers/Following counts) and
 * a feed of the user's currently-public single workouts (`/w/<token>`) and
 * plan/period shares (`/p/<token>`).
 *
 * Followers/following render as static "0 · Coming soon" until social ships
 * (intentional — not a bug). Backend never exposes follow data here.
 */
import type { Metadata } from "next";
import { notFound } from "next/navigation";

export const revalidate = 60;

const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.fitwiz.us";

type FeedItem =
  | {
      kind: "workout";
      token: string;
      url_path: string;
      name: string | null;
      duration_minutes: number | null;
      estimated_calories: number | null;
      completed_at: string | null;
      scheduled_date: string | null;
    }
  | {
      kind: "plan";
      token: string;
      url_path: string;
      scope: string | null;
      period: string | null;
      start_date: string | null;
      end_date: string | null;
      created_at: string | null;
    };

type PublicProfile = {
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  bio: string | null;
  joined_at: string | null;
  public_workout_count: number;
  public_plan_count: number;
  followers: number;
  following: number;
  feed: FeedItem[];
};

async function fetchProfile(username: string): Promise<PublicProfile | null> {
  const res = await fetch(
    `${API_BASE}/api/v1/users/public/${encodeURIComponent(username)}`,
    { next: { revalidate: 60 } },
  );
  if (!res.ok) return null;
  return (await res.json()) as PublicProfile;
}

export async function generateMetadata({
  params,
}: {
  params: { username: string };
}): Promise<Metadata> {
  const p = await fetchProfile(params.username);
  if (!p) return { title: "FitWiz — Profile" };
  const title = `${p.display_name ?? p.username} (@${p.username}) — FitWiz`;
  const description = `${p.public_workout_count} workouts · ${p.public_plan_count} plans shared on FitWiz`;
  return {
    title,
    description,
    openGraph: { title, description, type: "profile" },
    twitter: { card: "summary_large_image", title, description },
  };
}

function fmtDate(iso: string | null) {
  if (!iso) return "";
  return new Date(iso).toLocaleDateString("en-US", {
    month: "short",
    day: "numeric",
    year: "numeric",
  });
}

function fmtDuration(min: number | null) {
  if (!min) return null;
  if (min < 60) return `${min}m`;
  return `${Math.floor(min / 60)}h ${min % 60}m`;
}

function FeedCard({ item }: { item: FeedItem }) {
  if (item.kind === "workout") {
    return (
      <a
        href={item.url_path}
        className="block rounded-xl bg-neutral-900 hover:bg-neutral-800 transition p-4"
      >
        <div className="flex items-baseline justify-between gap-3">
          <h3 className="font-bold truncate">{item.name ?? "Workout"}</h3>
          <span className="text-xs text-neutral-500 shrink-0">
            {fmtDate(item.completed_at ?? item.scheduled_date)}
          </span>
        </div>
        <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 text-xs text-neutral-400">
          {fmtDuration(item.duration_minutes) && (
            <span>{fmtDuration(item.duration_minutes)}</span>
          )}
          {item.estimated_calories ? (
            <span>{item.estimated_calories} kcal</span>
          ) : null}
          <span className="text-emerald-400">✓ workout</span>
        </div>
      </a>
    );
  }
  const periodLabel =
    item.period === "week"
      ? `Week of ${fmtDate(item.start_date)}`
      : item.period === "month"
        ? `${new Date((item.start_date ?? "") + "T00:00:00").toLocaleDateString(
            "en-US",
            { month: "long", year: "numeric" },
          )} program`
        : item.period === "ytd"
          ? `${item.start_date ?? ""} year to date`
          : `${fmtDate(item.start_date)} – ${fmtDate(item.end_date)}`;
  return (
    <a
      href={item.url_path}
      className="block rounded-xl bg-neutral-900 hover:bg-neutral-800 transition p-4"
    >
      <div className="flex items-baseline justify-between gap-3">
        <h3 className="font-bold truncate">{periodLabel}</h3>
        <span className="text-xs text-neutral-500 shrink-0">
          {fmtDate(item.created_at)}
        </span>
      </div>
      <div className="mt-1 text-xs text-neutral-400">
        <span className="text-cyan-400">📅 {item.scope ?? "plan"}</span>
      </div>
    </a>
  );
}

function FollowDisabled({
  followers,
  following,
}: {
  followers: number;
  following: number;
}) {
  return (
    <div className="mt-4 flex flex-wrap items-center gap-3">
      <button
        disabled
        title="Coming soon"
        className="px-4 py-1.5 rounded-full text-sm font-bold bg-neutral-800 text-neutral-500 cursor-not-allowed"
      >
        Follow
      </button>
      <span
        title="Coming soon"
        className="text-xs text-neutral-500"
      >
        {followers} followers · {following} following · Coming soon
      </span>
    </div>
  );
}

export default async function PublicProfilePage({
  params,
}: {
  params: { username: string };
}) {
  const p = await fetchProfile(params.username);
  if (!p) notFound();

  return (
    <main className="min-h-screen bg-neutral-950 text-neutral-100">
      <header className="flex items-center justify-between px-6 py-4 border-b border-neutral-800">
        <a href="/" className="flex items-center gap-2">
          <div className="w-7 h-7 rounded-md bg-gradient-to-br from-cyan-400 to-fuchsia-500" />
          <span className="font-bold tracking-tight">FitWiz</span>
        </a>
      </header>

      <section className="max-w-3xl mx-auto p-6">
        <div className="flex items-center gap-4">
          {p.avatar_url ? (
            // eslint-disable-next-line @next/next/no-img-element
            <img
              src={p.avatar_url}
              alt=""
              className="w-20 h-20 rounded-full object-cover"
            />
          ) : (
            <div className="w-20 h-20 rounded-full bg-gradient-to-br from-cyan-400 to-fuchsia-500" />
          )}
          <div className="flex-1 min-w-0">
            <h1 className="text-2xl font-black leading-tight truncate">
              {p.display_name ?? p.username}
            </h1>
            <div className="text-neutral-400 text-sm">@{p.username}</div>
            {p.joined_at ? (
              <div className="text-xs text-neutral-500 mt-1">
                Joined {fmtDate(p.joined_at)}
              </div>
            ) : null}
          </div>
        </div>

        {p.bio ? (
          <p className="mt-4 text-sm text-neutral-300 whitespace-pre-line">
            {p.bio}
          </p>
        ) : null}

        <div className="mt-5 grid grid-cols-3 gap-3">
          <div className="rounded-xl bg-neutral-900 p-3 text-center">
            <div className="text-xl font-black">{p.public_workout_count}</div>
            <div className="text-[10px] uppercase tracking-wider text-neutral-500">
              Workouts
            </div>
          </div>
          <div className="rounded-xl bg-neutral-900 p-3 text-center">
            <div className="text-xl font-black">{p.public_plan_count}</div>
            <div className="text-[10px] uppercase tracking-wider text-neutral-500">
              Plans
            </div>
          </div>
          <div className="rounded-xl bg-neutral-900 p-3 text-center opacity-60">
            <div className="text-xl font-black">{p.followers}</div>
            <div
              className="text-[10px] uppercase tracking-wider text-neutral-500"
              title="Coming soon"
            >
              Followers
            </div>
          </div>
        </div>

        <FollowDisabled followers={p.followers} following={p.following} />

        <h2 className="mt-10 mb-4 text-sm uppercase tracking-wider text-neutral-500">
          Recent shares
        </h2>
        {p.feed.length === 0 ? (
          <div className="rounded-xl bg-neutral-900 p-5 text-sm text-neutral-500 text-center">
            No public shares yet.
          </div>
        ) : (
          <div className="space-y-3">
            {p.feed.map((item) => (
              <FeedCard key={`${item.kind}-${item.token}`} item={item} />
            ))}
          </div>
        )}

        <div className="mt-10 rounded-2xl bg-gradient-to-br from-cyan-500/10 via-fuchsia-500/10 to-amber-500/10 p-5 text-center">
          <h2 className="text-lg font-bold">Build your own profile</h2>
          <p className="mt-1 text-sm text-neutral-300">
            Track workouts, log meals, and share with friends.
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
      </section>
    </main>
  );
}
