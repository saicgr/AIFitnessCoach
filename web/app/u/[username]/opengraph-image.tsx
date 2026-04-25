import { ImageResponse } from "next/og";
import {
  API_BASE,
  FitWizMark,
  StatPill,
  StoreFooter,
  OG_SIZE,
  OG_CONTENT_TYPE,
  ogPalette,
} from "../../_og/shared";

export const runtime = "nodejs";
export const size = OG_SIZE;
export const contentType = OG_CONTENT_TYPE;
export const alt = "FitWiz profile";

type PublicProfile = {
  username: string;
  display_name: string | null;
  avatar_url: string | null;
  public_workout_count: number;
  public_plan_count: number;
};

async function fetchProfile(username: string): Promise<PublicProfile | null> {
  try {
    const res = await fetch(
      `${API_BASE}/api/v1/users/public/${encodeURIComponent(username)}`,
      { next: { revalidate: 300 } },
    );
    if (!res.ok) return null;
    return (await res.json()) as PublicProfile;
  } catch {
    return null;
  }
}

export default async function ProfileOg({
  params,
}: {
  params: { username: string };
}) {
  const profile = await fetchProfile(params.username);
  const p = ogPalette();
  const display = profile?.display_name ?? profile?.username ?? "FitWiz lifter";
  const handle = profile ? `@${profile.username}` : "@fitwiz";

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
          padding: 64,
          fontFamily: "system-ui",
        }}
      >
        <FitWizMark />

        <div
          style={{
            marginTop: 48,
            display: "flex",
            alignItems: "center",
            gap: 32,
          }}
        >
          {profile?.avatar_url ? (
            // eslint-disable-next-line jsx-a11y/alt-text, @next/next/no-img-element
            <img
              src={profile.avatar_url}
              width={160}
              height={160}
              style={{ borderRadius: 80, objectFit: "cover" }}
            />
          ) : (
            <div
              style={{
                width: 160,
                height: 160,
                borderRadius: 80,
                background: `linear-gradient(135deg, ${p.accentFrom}, ${p.accentTo})`,
              }}
            />
          )}
          <div style={{ display: "flex", flexDirection: "column", gap: 8 }}>
            <div
              style={{
                fontSize: 64,
                fontWeight: 900,
                letterSpacing: -2,
                lineHeight: 1,
              }}
            >
              {display}
            </div>
            <div style={{ fontSize: 28, color: p.muted }}>{handle}</div>
          </div>
        </div>

        <div style={{ marginTop: 56, display: "flex", gap: 16 }}>
          <StatPill
            label="Workouts"
            value={profile?.public_workout_count ?? 0}
          />
          <StatPill label="Plans" value={profile?.public_plan_count ?? 0} />
        </div>

        <div style={{ flex: 1 }} />

        <StoreFooter />
      </div>
    ),
    size,
  );
}
