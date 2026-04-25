import { ImageResponse } from "next/og";
import {
  API_BASE,
  ByLine,
  FitWizMark,
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
export const alt = "FitWiz plan";

type SnapWorkout = {
  name: string;
  scheduled_date: string;
  is_completed: boolean;
  duration_minutes?: number | null;
  exercises?: { name: string }[];
};

type PublicPlan = {
  scope: string;
  period: "day" | "week" | "month" | "ytd" | "custom";
  start_date: string;
  end_date: string;
  display_name: string | null;
  snapshot: {
    workouts: SnapWorkout[];
    summary?: {
      total_workouts: number;
      completed_workouts: number;
      total_duration_minutes: number;
    };
  };
};

async function fetchPlan(token: string): Promise<PublicPlan | null> {
  try {
    const res = await fetch(`${API_BASE}/api/v1/plans/public/${token}`, {
      next: { revalidate: 300 },
    });
    if (!res.ok) return null;
    return (await res.json()) as PublicPlan;
  } catch {
    return null;
  }
}

function periodLabel(p: PublicPlan): string {
  const start = new Date(p.start_date + "T00:00:00");
  const end = new Date(p.end_date + "T00:00:00");
  switch (p.period) {
    case "day":
      return start.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
        year: "numeric",
      });
    case "week":
      return `Week of ${start.toLocaleDateString("en-US", {
        month: "short",
        day: "numeric",
      })}`;
    case "month":
      return `${start.toLocaleDateString("en-US", {
        month: "long",
        year: "numeric",
      })} Program`;
    case "ytd":
      return `${start.getFullYear()} Year to Date`;
    default:
      return `${start.toLocaleDateString()} – ${end.toLocaleDateString()}`;
  }
}

export default async function PlanOg({
  params,
}: {
  params: { token: string };
}) {
  const plan = await fetchPlan(params.token);
  const p = ogPalette();
  const title = plan ? periodLabel(plan) : "Shared plan";
  const author = plan?.display_name ?? "FitWiz lifter";
  const summary = plan?.snapshot?.summary;
  const previewWorkouts = (plan?.snapshot?.workouts ?? []).slice(0, 4);

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
          <FitWizMark />
          <ByLine name={author} />
        </div>

        <div
          style={{
            marginTop: 48,
            fontSize: 64,
            fontWeight: 900,
            lineHeight: 1.05,
            letterSpacing: -2,
          }}
        >
          {title}
        </div>

        {summary ? (
          <div style={{ marginTop: 24, display: "flex", gap: 16 }}>
            <StatPill label="Workouts" value={summary.total_workouts} />
            <StatPill label="Completed" value={summary.completed_workouts} />
            {summary.total_duration_minutes > 0 ? (
              <StatPill
                label="Total time"
                value={fmtDuration(summary.total_duration_minutes)}
              />
            ) : null}
          </div>
        ) : null}

        <div
          style={{
            marginTop: 36,
            display: "flex",
            gap: 16,
            flex: 1,
            alignItems: "stretch",
          }}
        >
          {previewWorkouts.map((w, i) => (
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
                  fontSize: 14,
                  color: p.muted,
                  textTransform: "uppercase",
                  letterSpacing: 1,
                  display: "flex",
                }}
              >
                {new Date(w.scheduled_date + "T00:00:00").toLocaleDateString(
                  "en-US",
                  { weekday: "short" },
                )}
              </div>
              <div
                style={{
                  fontWeight: 800,
                  fontSize: 22,
                  lineHeight: 1.2,
                  display: "flex",
                }}
              >
                {w.name}
              </div>
              <div style={{ color: p.muted, fontSize: 14, display: "flex" }}>
                {w.exercises?.length ?? 0} ex
                {w.is_completed ? " · ✓" : ""}
              </div>
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
