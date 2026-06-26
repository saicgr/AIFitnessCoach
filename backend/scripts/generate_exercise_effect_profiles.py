#!/usr/bin/env python3
"""Dr-Yaad audit #5 — LLM refiner for exercise effect-profiles.

Migration 2290 already SEEDED every exercise with a deterministic, per-family
effect profile (recoverability / tissue_stress / time_cost_seconds / is_prehab /
systemic_load). That baseline is complete and correct at the family level.

This script SHARPENS it per-exercise with Gemini — e.g. distinguishing a
behind-the-neck press (high shoulder tissue stress) from a neutral-grip landmine
press (low), which a family bucket can't. It is deterministic-baseline-first by
design: it only OVERWRITES the seeded values, never invents missing rows.

Safe by default (`--dry-run`). Batched ≤200/call (per feedback_country_food_agents)
to keep prompts bounded. Usage:

    python scripts/generate_exercise_effect_profiles.py --dry-run --sample 20
    python scripts/generate_exercise_effect_profiles.py --emit-sql --out migrations/2293_effect_profiles_llm.sql
    python scripts/generate_exercise_effect_profiles.py --apply            # writes to DB

Tissue keys (0–5): shoulder, elbow, wrist, knee, hip, lumbar, ankle, achilles,
neck. recoverability/systemic_load are 1–5. After --apply, REFRESH the
exercise_library_cleaned MV if any downstream consumer reads profiles from it
(the tissue ledger reads the base table, so a refresh is optional).
"""
import argparse
import json
import os

import psycopg2
import psycopg2.extras

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

TISSUES = ["shoulder", "elbow", "wrist", "knee", "hip", "lumbar", "ankle",
           "achilles", "neck"]
BATCH = 200
MODEL = "gemini-3-flash-preview"

_SYSTEM = (
    "You are a sports-medicine + S&C expert refining exercise EFFECT PROFILES. "
    "For each exercise return per-joint/tendon TISSUE STRESS (0=none .. 5=very high) "
    "for these tissues only: " + ", ".join(TISSUES) + ". Also rate recoverability "
    "(1=slow, recovers over days .. 5=fast, recovers same day) and systemic_load "
    "(1=trivial .. 5=whole-body/CNS taxing). Be precise and conservative; most "
    "exercises stress only 1–3 tissues. Omit a tissue if its stress is 0. "
    "Return STRICT JSON: a list of {name, tissue_stress:{tissue:int}, "
    "recoverability:int, systemic_load:int}."
)


def _db_url():
    for line in open(os.path.join(ROOT, "backend", ".env")):
        if line.startswith("DATABASE_URL="):
            return line.split("=", 1)[1].strip().replace(
                "postgresql+asyncpg://", "postgresql://")
    raise SystemExit("DATABASE_URL not found in backend/.env")


def fetch_rows(conn, sample):
    cur = conn.cursor(cursor_factory=psycopg2.extras.RealDictCursor)
    cur.execute(
        "SELECT id, name, movement_pattern, primary_muscle, equipment, "
        "tissue_stress, recoverability, systemic_load "
        "FROM exercise_library ORDER BY name"
        + (" LIMIT %s" if sample else ""),
        (sample,) if sample else None,
    )
    return cur.fetchall()


def _gemini_refine(batch):
    """Return {name_lower: {tissue_stress, recoverability, systemic_load}}.

    Uses the google-genai SDK with GEMINI_API_KEY. On any error returns {} so
    the caller falls back to the deterministic seed (no silent corruption)."""
    try:
        from google import genai  # type: ignore
    except Exception as e:  # pragma: no cover
        print(f"  [warn] google-genai not importable ({e}); skipping LLM")
        return {}
    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    if not api_key:
        print("  [warn] GEMINI_API_KEY unset; skipping LLM refine")
        return {}
    client = genai.Client(api_key=api_key)
    payload = [
        {"name": r["name"], "movement_pattern": r["movement_pattern"],
         "primary_muscle": r.get("primary_muscle"), "equipment": r.get("equipment")}
        for r in batch
    ]
    prompt = _SYSTEM + "\n\nExercises:\n" + json.dumps(payload)
    try:
        resp = client.models.generate_content(model=MODEL, contents=prompt)
        text = resp.text.strip()
        if text.startswith("```"):
            text = text.split("```", 2)[1].lstrip("json").strip()
        items = json.loads(text)
    except Exception as e:  # pragma: no cover
        print(f"  [warn] LLM batch failed ({e}); keeping seed for this batch")
        return {}
    out = {}
    for it in items:
        nm = (it.get("name") or "").strip().lower()
        ts = {k: int(v) for k, v in (it.get("tissue_stress") or {}).items()
              if k in TISSUES and isinstance(v, (int, float)) and 0 < int(v) <= 5}
        rec = it.get("recoverability")
        sys = it.get("systemic_load")
        if nm:
            out[nm] = {
                "tissue_stress": ts,
                "recoverability": int(rec) if rec else None,
                "systemic_load": int(sys) if sys else None,
            }
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--emit-sql", action="store_true")
    ap.add_argument("--sample", type=int, default=0)
    ap.add_argument("--out", default=os.path.join(
        ROOT, "backend", "migrations", "2293_effect_profiles_llm.sql"))
    args = ap.parse_args()
    if not args.apply and not args.emit_sql:
        args.dry_run = True

    conn = psycopg2.connect(_db_url())
    rows = fetch_rows(conn, args.sample)
    print(f"Exercises in scope: {len(rows)}")

    refined = {}
    for i in range(0, len(rows), BATCH):
        chunk = rows[i:i + BATCH]
        print(f"  refining {i}..{i + len(chunk)} ...")
        refined.update(_gemini_refine(chunk))

    updates = []  # (id, tissue_stress_json, recover, systemic)
    for r in rows:
        ref = refined.get((r["name"] or "").strip().lower())
        if not ref:
            continue
        ts = ref["tissue_stress"]
        rec = ref["recoverability"] or r["recoverability"]
        sys = ref["systemic_load"] or r["systemic_load"]
        # Only record a change if something actually differs from the seed.
        if (ts and ts != (r["tissue_stress"] or {})) or rec != r["recoverability"] \
                or sys != r["systemic_load"]:
            updates.append((r["id"], json.dumps(ts), rec, sys))

    print(f"LLM-refined rows differing from seed: {len(updates)}")

    if args.dry_run:
        for r in rows[:10]:
            ref = refined.get((r["name"] or "").strip().lower())
            print(f"\n{r['name']}\n  seed : {r['tissue_stress']}\n  llm  : "
                  f"{ref['tissue_stress'] if ref else '(none)'}")
        print(f"\n(dry run — {len(updates)} would update)")
        conn.close()
        return

    if args.emit_sql:
        with open(args.out, "w") as f:
            f.write("-- LLM-refined exercise effect profiles (Dr-Yaad #5)\n")
            for _id, ts, rec, sys in updates:
                f.write(
                    "UPDATE exercise_library SET tissue_stress="
                    f"'{ts}'::jsonb, recoverability={rec or 'NULL'}, "
                    f"systemic_load={sys or 'NULL'} WHERE id='{_id}';\n")
        print(f"Wrote {len(updates)} statements -> {args.out}")
        conn.close()
        return

    if args.apply:
        cur = conn.cursor()
        for _id, ts, rec, sys in updates:
            cur.execute(
                "UPDATE exercise_library SET tissue_stress=%s::jsonb, "
                "recoverability=%s, systemic_load=%s WHERE id=%s",
                (ts, rec, sys, _id))
        conn.commit()
        print(f"Applied {len(updates)} updates.")
        conn.close()


if __name__ == "__main__":
    main()
