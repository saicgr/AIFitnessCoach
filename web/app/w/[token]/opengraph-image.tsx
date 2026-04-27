import { ImageResponse } from "next/og";
import {
  API_BASE,
  ByLine,
  BrandMark,
  StatPill,
  StoreFooter,
  fmtDuration,
  OG_SIZE,
  OG_CONTENT_TYPE,
  ogPalette,
} from "../../_og/shared";

export const runtime = "nodejs";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;
export const alt = "Zealova workout";

type Set = { weight_kg?: number | null; reps_completed?: number };
type Exercise = { name: string; sets?: Set[]; image_url?: string | null };
type PublicWorkout = {
  name: string;
  duration_minutes: number | null;
  calories_burned: number | null;
  exercises: Exercise[];
  display_name: string | null;
};

async function fetchWorkout(token: string): Promise<PublicWorkout | null> {
  try {
    const res = await fetch(`${API_BASE}/api/v1/workouts/public/${token}`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) return null;
    return (await res.json()) as PublicWorkout;
  } catch {
    return null;
  }
}

function totalVolumeKg(ex: Exercise[]) {
  return ex.reduce(
    (sum, e) =>
      sum +
      (e.sets ?? []).reduce(
        (s, st) => s + (st.weight_kg ?? 0) * (st.reps_completed ?? 0),
        0,
      ),
    0,
  );
}

export default async function WorkoutOg({
  params,
}: {
  params: { token: string };
}) {
  const w = await fetchWorkout(params.token);
  const p = ogPalette();
  const name = w?.name ?? "Shared workout";
  const exCount = w?.exercises?.length ?? 0;
  const volumeKg = w ? Math.round(totalVolumeKg(w.exercises ?? [])) : 0;
  const author = w?.display_name ?? "Zealova lifter";
  const previewExercises = (w?.exercises ?? []).slice(0, 4);

  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          flexDirection: "column",
          background: p.bg,
          color: p.text,
          padding: 56,
          fontFamily: "system-ui",
        }}
      >
        <div
          style={{
            display: "flex",
            justifyContent: "space-between",
            alignItems: "center",
          }}
        >
          <BrandMark />
          <ByLine name={author} />
        </div>

        <div
          style={{
            marginTop: 56,
            fontSize: 72,
            fontWeight: 900,
            lineHeight: 1.05,
            letterSpacing: -2,
          }}
        >
          {name}
        </div>

        <div style={{ marginTop: 24, display: "flex", gap: 16 }}>
          <StatPill label="Exercises" value={exCount} />
          <StatPill label="Duration" value={fmtDuration(w?.duration_minutes)} />
          {volumeKg > 0 ? (
            <StatPill label="Volume" value={`${volumeKg} kg`} />
          ) : null}
          {w?.calories_burned ? (
            <StatPill label="Calories" value={`${w.calories_burned}`} />
          ) : null}
        </div>

        <div
          style={{
            marginTop: 36,
            display: "flex",
            gap: 16,
            flex: 1,
            alignItems: "stretch",
          }}
        >
          {previewExercises.map((ex, i) => (
            <div
              key={i}
              style={{
                flex: 1,
                background: p.surface,
                borderRadius: 16,
                border: `1px solid ${p.border}`,
                padding: 20,
                display: "flex",
                flexDirection: "column",
                gap: 8,
              }}
            >
              <div
                style={{
                  width: "100%",
                  height: 90,
                  borderRadius: 8,
                  background: "#262626",
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                  fontSize: 40,
                }}
              >
                🏋️
              </div>
              <div
                style={{
                  fontWeight: 800,
                  fontSize: 20,
                  lineHeight: 1.2,
                  display: "flex",
                }}
              >
                {ex.name}
              </div>
              {ex.sets?.length ? (
                <div style={{ color: p.muted, fontSize: 16 }}>
                  {ex.sets.length} sets
                </div>
              ) : null}
            </div>
          ))}
        </div>

        <div style={{ marginTop: 32 }}>
          <StoreFooter />
        </div>
      </div>
    ),
    size,
  );
}
