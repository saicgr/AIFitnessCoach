/**
 * Shared helpers for OG / Twitter image generators.
 *
 * Underscored route segment so Next.js doesn't expose this as a route.
 * `next/og` only supports a subset of CSS — keep styles simple (flexbox,
 * colors, fonts). No grid, no advanced selectors.
 */
export const API_BASE =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "https://api.zealova.com";

export const OG_SIZE = { width: 1200, height: 630 } as const;
export const OG_CONTENT_TYPE = "image/png" as const;

const NEUTRAL_900 = "#171717";
const NEUTRAL_700 = "#404040";
const NEUTRAL_400 = "#a3a3a3";
const NEUTRAL_100 = "#f5f5f5";
const ACCENT_FROM = "#22d3ee"; // cyan-400
const ACCENT_TO = "#d946ef"; // fuchsia-500

export function ogPalette() {
  return {
    bg: "#0a0a0a",
    surface: NEUTRAL_900,
    border: NEUTRAL_700,
    muted: NEUTRAL_400,
    text: NEUTRAL_100,
    accentFrom: ACCENT_FROM,
    accentTo: ACCENT_TO,
  };
}

/** Zealova wordmark + logo block, rendered top-left. */
export function BrandMark() {
  const p = ogPalette();
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
      <div
        style={{
          width: 56,
          height: 56,
          borderRadius: 12,
          background: `linear-gradient(135deg, ${p.accentFrom}, ${p.accentTo})`,
        }}
      />
      <div
        style={{
          fontSize: 40,
          fontWeight: 900,
          color: p.text,
          letterSpacing: -1,
        }}
      >
        Zealova
      </div>
    </div>
  );
}

export function ByLine({ name }: { name: string }) {
  const p = ogPalette();
  return (
    <div style={{ fontSize: 24, color: p.muted }}>
      Created by <span style={{ color: p.text, fontWeight: 700 }}>{name}</span>
    </div>
  );
}

export function StoreFooter() {
  const p = ogPalette();
  return (
    <div
      style={{
        display: "flex",
        gap: 16,
        alignItems: "center",
        color: p.muted,
        fontSize: 22,
      }}
    >
      <div
        style={{
          padding: "10px 18px",
          borderRadius: 10,
          background: p.text,
          color: "#000",
          fontWeight: 800,
        }}
      >
        App Store
      </div>
      <div
        style={{
          padding: "10px 18px",
          borderRadius: 10,
          background: p.text,
          color: "#000",
          fontWeight: 800,
        }}
      >
        Google Play
      </div>
      <span style={{ marginLeft: 12 }}>zealova.com</span>
    </div>
  );
}

export function StatPill({
  label,
  value,
}: {
  label: string;
  value: string | number;
}) {
  const p = ogPalette();
  return (
    <div
      style={{
        display: "flex",
        flexDirection: "column",
        gap: 4,
        padding: "16px 24px",
        borderRadius: 16,
        background: p.surface,
        border: `1px solid ${p.border}`,
      }}
    >
      <span
        style={{
          fontSize: 16,
          color: p.muted,
          textTransform: "uppercase",
          letterSpacing: 1.5,
        }}
      >
        {label}
      </span>
      <span style={{ fontSize: 36, fontWeight: 900, color: p.text }}>
        {value}
      </span>
    </div>
  );
}

export function fmtDuration(min: number | null | undefined): string {
  if (!min) return "—";
  if (min < 60) return `${min}m`;
  return `${Math.floor(min / 60)}h ${min % 60}m`;
}
