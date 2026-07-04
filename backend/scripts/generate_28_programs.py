#!/usr/bin/env python3
"""
generate_28_programs.py — 2026-07 catalog expansion (22 -> 50 programs).

Gemini 3.1 Flash-Lite authors ONLY each program's PRIMARY variant, week by
week, with a checkpoint after EVERY week: each generated week is validated,
topped-up, media-resolved and ingested into program_variant_weeks BEFORE the
next Gemini call. On any re-run, existing (variant_id, week_number) rows are
skipped BEFORE spending tokens — a crash never re-buys paid work. The full
weeks × sessions × intensity matrix is then DERIVED deterministically (free)
via program_build.py's map_weeks/map_sessions/scale_intensity, with per-cell
resume (complete cells are skipped).

Deterministic programs (fixed protocols) and daily-blob challenges cost $0 —
see deterministic_program_weeks.py.

NOTE on ingest conflict handling: ingest_week_to_supabase catches duplicates
by exception-message string matching. That path is COLD here because we
pre-check get_existing_weeks before generating; it only fires during derive
re-runs, where the update-on-conflict behavior is what we want. Left as-is
deliberately (shared by two shipped pipelines).

Usage (from backend/):
  python3 scripts/generate_28_programs.py --dry-run
  python3 scripts/generate_28_programs.py --program kb-foundations
  python3 scripts/generate_28_programs.py --batch 1
  python3 scripts/generate_28_programs.py --publish-batch 1
  python3 scripts/generate_28_programs.py --report
"""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path
from typing import Any, Dict, List, Optional

BACKEND_DIR = Path(__file__).parent.parent
sys.path.insert(0, str(BACKEND_DIR))
sys.path.insert(0, str(Path(__file__).parent))
from dotenv import load_dotenv  # noqa: E402
load_dotenv(BACKEND_DIR / ".env")

import generate_programs as gp  # noqa: E402
import program_build as pb  # noqa: E402
from generate_curated_variants import backfill_programs_columns  # noqa: E402
from deterministic_program_weeks import (  # noqa: E402
    WEEKLY_BUILDERS, DAILY_BLOB_BUILDERS,
)

GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
GEMINI_MODEL = os.getenv("GEMINI_MODEL", "gemini-3.1-flash-lite")
REQUEST_DELAY = 4  # 15 rpm

MANIFEST_PATH = Path(__file__).parent / "specs" / "programs_28_manifest.json"

# Slugs whose sessions are exempt-style (mobility/LISS) — no volume clause.
NO_VOLUME_CLAUSE = {"pilates-foundations", "feel-good-cardio"}


def _sb():
    from supabase import create_client
    return create_client(SUPABASE_URL, SUPABASE_KEY)


# ---------------------------------------------------------------------------
# Session top-up on ONE persistent event loop.
# pb._topup_week calls asyncio.run() per invocation — a NEW loop every time —
# but the RAG service's asyncpg pool binds to the FIRST loop, so every later
# fill dies with "attached to a different loop" and silently no-ops (observed
# on kb-hard). One long-lived loop for the whole process fixes it.
# ---------------------------------------------------------------------------
import asyncio as _aio  # noqa: E402
import re as _re  # noqa: E402

_LOOP = _aio.new_event_loop()


def topup_week(workouts, minutes):
    from services.program_session_filler import fill_thin_sessions
    eq = set()
    for s in workouts or []:
        for e in (s.get("exercises") or []):
            val = (e.get("equipment") or "").strip().lower()
            if val:
                eq.update(p.strip() for p in _re.split(r"[/,]| or | and ", val))
    eq = sorted({x for x in eq if x} | {"bodyweight", "none"})
    try:
        res = _LOOP.run_until_complete(fill_thin_sessions(
            workouts, equipment=eq, difficulty_ceiling="intermediate"))
        if res.get("added"):
            print(f"      🔧 top-up: +{len(res['added'])} accessories")
        return res["workouts"]
    except Exception as e:
        print(f"      ⚠️ top-up failed (continuing unfilled): {e}")
        return workouts


def load_manifest() -> List[Dict[str, Any]]:
    return json.loads(MANIFEST_PATH.read_text())["programs"]


# ---------------------------------------------------------------------------
# Media resolution (STRICT — same standard as program_build.assert_all_resolve)
# ---------------------------------------------------------------------------
_resolve_cache: Dict[str, bool] = {}


def name_resolves(sb, name: str) -> bool:
    key = (name or "").strip().lower()
    if not key:
        return False
    if key in _resolve_cache:
        return _resolve_cache[key]
    try:
        r = sb.rpc("resolve_exercise_demo_media", {"p_name": name}).execute().data
        rows = r if isinstance(r, list) else ([r] if r else [])
        ok = any((row.get("image_s3_path") or row.get("video_s3_path")
                  or row.get("image_url") or row.get("gif_url")) for row in rows)
    except Exception as e:
        print(f"      ⚠️ resolve RPC failed for '{name}': {e}")
        ok = False
    _resolve_cache[key] = ok
    return ok


def unresolved_in_week(sb, week_data: dict) -> List[str]:
    names = sorted({(e.get("name") or "").strip()
                    for w in week_data.get("workouts", [])
                    for e in (w.get("exercises") or [])
                    if (e.get("name") or "").strip()})
    return [n for n in names if not name_resolves(sb, n)]


def build_allowed_names(sb, patterns: List[str], cap: int = 60) -> List[str]:
    """Candidate names from exercise_canonical by ILIKE patterns, verified
    against the media RPC. Cached per pattern-set per process."""
    if not patterns:
        return []
    candidates: List[str] = []
    seen = set()
    for pat in patterns:
        try:
            rows = (sb.table("exercise_canonical").select("canonical_name")
                    .ilike("canonical_name", pat).limit(80).execute().data) or []
        except Exception as e:
            print(f"      ⚠️ canonical query failed for {pat}: {e}")
            rows = []
        for r in rows:
            n = r["canonical_name"]
            if n.lower() not in seen:
                seen.add(n.lower())
                candidates.append(n)
    verified = [n for n in candidates if name_resolves(sb, n)]
    return verified[:cap]


# ---------------------------------------------------------------------------
# Gemini week generation (prompt = gp prompts + extras + names hint + volume)
# ---------------------------------------------------------------------------
def _volume_clause(spw: int, minutes: int) -> str:
    floor = 4 if minutes <= 30 else (5 if minutes <= 50 else 6)
    return (
        "\n\n## NON-NEGOTIABLE VOLUME REQUIREMENT\n"
        f"Each of the {spw} workouts MUST contain AT LEAST {floor} main "
        "exercises in its \"exercises\" array (warmup/cooldown do NOT count). "
        "The floor scales with the workout's duration_minutes: <=30 min needs "
        "4+, 31-50 min needs 5+, 51-65 min needs 6+, longer needs 7+. A "
        "sparser workout is INVALID and will be REJECTED — add appropriate "
        "accessory/core work to meet the minimum for the duration you set."
    )


def _names_hint(allowed: List[str]) -> str:
    if not allowed:
        return ""
    return (
        "\n\n## EXERCISE LIBRARY (use these EXACT names)\n"
        "Choose exercises ONLY from this list, using the exact spelling shown. "
        "Generic bodyweight basics (Plank, Push-Up, Walking, Jogging, Running, "
        "Brisk walking) are also acceptable:\n- " + "\n- ".join(allowed)
    )


def gemini_week(client, sb, m: dict, prog_dict: dict, week_num: int,
                summaries: list, allowed: List[str],
                extra_instruction: str = "") -> dict:
    from google.genai import types
    prompt = gp.get_week_prompt(prog_dict, week_num, m["duration_weeks"],
                                m["sessions_per_week"], summaries)
    if m["slug"] not in NO_VOLUME_CLAUSE:
        prompt += _volume_clause(m["sessions_per_week"],
                                 m["session_duration_minutes"])
    prompt += _names_hint(allowed)
    if m.get("prompt_extras"):
        prompt += "\n\n## PROGRAM-SPECIFIC REQUIREMENTS\n" + m["prompt_extras"]
    if extra_instruction:
        prompt += "\n\n## CORRECTION (previous attempt rejected)\n" + extra_instruction

    response = client.models.generate_content(
        model=GEMINI_MODEL,
        contents=prompt,
        config=types.GenerateContentConfig(
            system_instruction=gp.get_system_prompt(prog_dict),
            temperature=0.7,
            max_output_tokens=65536,
        ),
    )
    text = (response.text or "").strip()
    for fence in ("```json", "```"):
        if text.startswith(fence):
            text = text[len(fence):]
    if text.endswith("```"):
        text = text[:-3]
    data = json.loads(text.strip())
    usage = response.usage_metadata
    in_tok = usage.prompt_token_count or 0 if usage else 0
    out_tok = usage.candidates_token_count or 0 if usage else 0
    cost = (in_tok * gp.PRICE_IN_PER_M + out_tok * gp.PRICE_OUT_PER_M) / 1e6
    return {"data": data, "cost": cost, "in": in_tok, "out": out_tok}


# ---------------------------------------------------------------------------
# Variant helpers (intensity-aware — unlike gp.create_variant_record's fallback)
# ---------------------------------------------------------------------------
def ensure_variant(sb, base_id: str, vname: str, dur: int, spw: int,
                   intensity: str, minutes: int, category: str) -> Optional[str]:
    existing = (sb.table("program_variants").select("id")
                .eq("base_program_id", base_id).eq("duration_weeks", dur)
                .eq("sessions_per_week", spw).eq("intensity_level", intensity)
                .limit(1).execute().data)
    if existing:
        return existing[0]["id"]
    try:
        row = sb.table("program_variants").insert({
            "base_program_id": base_id,
            "variant_name": vname,
            "intensity_level": intensity,
            "duration_weeks": dur,
            "sessions_per_week": spw,
            "session_duration_minutes": minutes,
            "program_category": category,
            "tags": [], "goals": [], "workouts": {},
            "generation_model": GEMINI_MODEL,
            "generation_cost_usd": 0,
        }).execute().data
        return row[0]["id"] if row else None
    except Exception as e:
        if "duplicate" in str(e).lower() or "unique" in str(e).lower():
            again = (sb.table("program_variants").select("id")
                     .eq("base_program_id", base_id).eq("duration_weeks", dur)
                     .eq("sessions_per_week", spw)
                     .eq("intensity_level", intensity).limit(1).execute().data)
            if again:
                return again[0]["id"]
        print(f"      ⚠️ variant create failed ({vname}): {e}")
        return None


def week_counts_for_base(sb, base_id: str) -> Dict[str, set]:
    """variant_id -> set(week_numbers) for every variant under a base."""
    variants = (sb.table("program_variants").select("id")
                .eq("base_program_id", base_id).execute().data) or []
    vids = [v["id"] for v in variants]
    out: Dict[str, set] = {vid: set() for vid in vids}
    for i in range(0, len(vids), 50):
        chunk = vids[i:i + 50]
        rows = (sb.table("program_variant_weeks").select("variant_id, week_number")
                .in_("variant_id", chunk).execute().data) or []
        for r in rows:
            out.setdefault(r["variant_id"], set()).add(r["week_number"])
    return out


# ---------------------------------------------------------------------------
# programs row
# ---------------------------------------------------------------------------
def ensure_programs_row(sb, m: dict) -> str:
    fields = {
        "program_name": m["program_name"],
        "editorial_name": m["editorial_name"],
        "tagline": m["tagline"],
        "description": m["description"],
        "short_description": m["tagline"],
        "who_for": m["who_for"],
        "who_not_for": m["who_not_for"],
        "equipment_summary": m["equipment_summary"],
        "progression_note": m["progression_note"],
        "goals": m["goals"],
        "program_category": m["program_category"],
        "program_subcategory": m.get("program_subcategory"),
        "difficulty_level": m["difficulty_level"],
        "duration_weeks": m["duration_weeks"],
        "sessions_per_week": m["sessions_per_week"],
        "session_duration_minutes": m["session_duration_minutes"],
        "tags": [m["program_category"]] + m.get("goals", [])[:2],
    }
    existing = (sb.table("programs").select("id, is_published")
                .eq("program_name", m["program_name"]).limit(1).execute().data)
    if existing:
        pid = existing[0]["id"]
        sb.table("programs").update(fields).eq("id", pid).execute()
        return pid
    fields["is_published"] = False
    fields["has_workouts"] = False
    return sb.table("programs").insert(fields).execute().data[0]["id"]


# ---------------------------------------------------------------------------
# Per-program pipeline
# ---------------------------------------------------------------------------
def run_program(sb, m: dict, dry_run: bool = False,
                skip_derive: bool = False) -> dict:
    slug = m["slug"]
    dur, spw = m["duration_weeks"], m["sessions_per_week"]
    minutes = m["session_duration_minutes"]
    print(f"\n{'=' * 62}\n▶ {m['editorial_name']}  [{slug}]  "
          f"{dur}w×{spw}d×{minutes}min  mode={m['gen_mode']}\n{'=' * 62}")

    if m["gen_mode"] == "daily_blob":
        return run_daily_blob(sb, m, dry_run)

    if dry_run:
        n_calls = dur if m["gen_mode"] == "gemini" else 0
        est = n_calls * (3000 * gp.PRICE_IN_PER_M + 4500 * gp.PRICE_OUT_PER_M) / 1e6
        wa, sa = pb.build_matrix(dur, spw, m["is_express"])
        print(f"   dry-run: {n_calls} Gemini week-calls (~${est:.3f}), "
              f"derive matrix {len(wa)}×{len(sa)}×3 = {len(wa) * len(sa) * 3} cells")
        return {"slug": slug, "dry_run": True, "est_cost": est}

    pid = ensure_programs_row(sb, m)
    prog_dict = {
        "name": m["editorial_name"],
        "category": m["program_category"],
        "description": m["description"],
        "goals": m["goals"],
        "has_supersets": False,
        "durations": [dur],
        "sessions": [spw],
    }
    branded_name = f"{m['editorial_name']} (Zealova Library)"
    base_id = gp.get_or_create_branded_program(sb, {**prog_dict, "name": branded_name})
    if not base_id:
        return {"slug": slug, "error": "branded base creation failed"}
    primary_vname = f"{m['editorial_name']} — {dur}w/{spw}d/Medium"
    primary_vid = ensure_variant(sb, base_id, primary_vname, dur, spw,
                                 "Medium", minutes, m["program_category"])
    if not primary_vid:
        return {"slug": slug, "error": "primary variant creation failed"}
    print(f"   program={pid}\n   base={base_id}\n   primary={primary_vid}")

    # ---- resume gate: existing weeks are NEVER regenerated -----------------
    existing = set(gp.get_existing_weeks(sb, primary_vid))
    summaries = []
    for w in sorted(existing):
        row = gp.get_last_week_data(sb, primary_vid, w)
        if row:
            summaries.append(gp.extract_week_summary(
                {"week": w, "phase": row.get("phase"),
                 "focus": row.get("focus"), "workouts": row.get("workouts", [])}))
    if existing:
        print(f"   resume: weeks {sorted(existing)} already persisted — skipping")

    client = None
    if m["gen_mode"] == "gemini":
        from google import genai
        from google.genai import types as gt
        client = genai.Client(api_key=GEMINI_API_KEY,
                              http_options=gt.HttpOptions(timeout=120_000))
        gp.GEMINI_MODEL = GEMINI_MODEL

    allowed = build_allowed_names(sb, m.get("allowed_name_patterns") or []) \
        if m["gen_mode"] == "gemini" else []
    if allowed:
        print(f"   allowed-names hint: {len(allowed)} library moves")

    total_cost = 0.0
    meta = {"name": branded_name, "variant_name": primary_vname,
            "category": m["program_category"], "description": m["tagline"],
            "has_supersets": False}

    for wk in range(1, dur + 1):
        if wk in existing:
            continue
        print(f"   week {wk}/{dur}...", flush=True)

        if m["gen_mode"] == "deterministic":
            week_data = WEEKLY_BUILDERS[slug](wk, dur, spw)
            week_data["workouts"] = topup_week(
                week_data.get("workouts", []), minutes)
        else:
            week_data, cost = _gemini_week_with_retries(
                client, sb, m, prog_dict, wk, summaries, allowed, minutes)
            total_cost += cost
            if week_data is None:
                gp.update_variant_cost(sb, primary_vid, total_cost)
                return {"slug": slug, "error": f"week {wk} failed after retries",
                        "cost": total_cost}

        # final resolution check post-topup (fillers carry exercise_id anyway)
        bad = unresolved_in_week(sb, week_data)
        if bad:
            print(f"      ❌ unresolved after retries: {bad[:8]} — aborting program")
            gp.update_variant_cost(sb, primary_vid, total_cost)
            return {"slug": slug, "error": f"unresolved names week {wk}: {bad[:8]}",
                    "cost": total_cost}

        ok = gp.ingest_week_to_supabase(sb, primary_vid, wk, week_data, meta)
        if not ok:
            gp.update_variant_cost(sb, primary_vid, total_cost)
            return {"slug": slug, "error": f"ingest failed week {wk}",
                    "cost": total_cost}
        print(f"      ✅ week {wk} persisted"
              + (f" (cost so far ${total_cost:.3f})" if total_cost else ""))
        summaries.append(gp.extract_week_summary(week_data))
        if m["gen_mode"] == "gemini":
            time.sleep(REQUEST_DELAY)

    gp.update_variant_cost(sb, primary_vid, total_cost)

    # ---- derive the matrix (free) with per-cell resume ----------------------
    if not skip_derive:
        n_new = derive_matrix(sb, m, base_id, primary_vid, prog_dict)
        print(f"   derived matrix: {n_new} cells ingested/completed")

    backfill_programs_columns(pid, base_id, dur, spw)

    # representative blob so has_workouts computes true
    week1 = gp.get_last_week_data(sb, primary_vid, 1)
    if week1:
        sb.table("programs").update({
            "workouts": {"workouts": week1.get("workouts", [])},
            "has_workouts": True,
        }).eq("id", pid).execute()

    print(f"   ✅ {slug} complete (${total_cost:.3f}) — still UNPUBLISHED")
    return {"slug": slug, "pid": pid, "base_id": base_id, "cost": total_cost}


def _validate_exempt_aware(data: dict, spw: int) -> dict:
    """gp.validate_week, but the WEEK-TOTAL 'Low exercise count' backstop is
    waived when every session is individually floor-exempt (mobility/LISS/
    express weeks — e.g. mat Pilates: 6 × 3 controlled moves is by design;
    the per-session floor + exemptions remain fully enforced)."""
    v = gp.validate_week(data, spw)
    if v["valid"]:
        return v
    only_low = all(i.startswith("Low exercise count") for i in v["issues"])
    if only_low and v.get("invalid_exercises", 0) == 0:
        workouts = data.get("workouts", [])
        if workouts and all(gp._session_exempt_from_floor(w) for w in workouts):
            return {**v, "valid": True, "issues": []}
    return v


# Universal fallback substitutes (all media-verified in pre-flight).
_FALLBACK_SUBS = [
    ("Plank", "waist", "Core"),
    ("Push-Up", "chest", "Chest"),
    ("Glute Bridge", "upper legs", "Glutes"),
    ("Bodyweight Squat", "upper legs", "Quadriceps"),
    ("Bird Dog", "full body", "Core"),
    ("Dead Bug", "waist", "Core"),
    ("Forward Lunge", "upper legs", "Quadriceps"),
    ("Standing Calf Raise", "lower legs", "Calves"),
]


def local_substitute(sb, week_data: dict, bad: List[str],
                     allowed: List[str]) -> List[str]:
    """Replace unresolved-name exercises in place with resolved moves —
    deterministic, free, always converges. Returns names still unresolved."""
    bad_set = {b.lower() for b in bad}
    pool = [n for n in allowed if name_resolves(sb, n)] + \
           [n for n, _, _ in _FALLBACK_SUBS]
    for w in week_data.get("workouts", []):
        in_session = {(e.get("name") or "").lower()
                      for e in (w.get("exercises") or [])}
        for e in (w.get("exercises") or []):
            nm = (e.get("name") or "").strip()
            if nm.lower() not in bad_set:
                continue
            bp = (e.get("body_part") or "").lower()
            pick = None
            for cand in pool:
                if cand.lower() in in_session:
                    continue
                if bp and bp.split()[0] in cand.lower():
                    pick = cand
                    break
            if pick is None:
                pick = next((c for c in pool
                             if c.lower() not in in_session), None)
            if pick is None:
                continue
            print(f"      🔁 substitute: '{nm}' → '{pick}'")
            e["name"] = pick
            e["exercise_name"] = pick
            e.pop("exercise_id", None)
            in_session.add(pick.lower())
    return unresolved_in_week(sb, week_data)


def _gemini_week_with_retries(client, sb, m, prog_dict, wk, summaries,
                              allowed, minutes):
    """top-up → validate → (retry w/ issues) → resolve-gate → (retry w/ subs).

    The deterministic top-up runs BEFORE validation so a 5/6 session gets
    filled to its floor instead of burning a retry (kb-hard week-1 lesson)."""
    total = 0.0
    extra = ""
    last_issues = None
    for attempt in range(3):
        try:
            res = gemini_week(client, sb, m, prog_dict, wk, summaries,
                              allowed, extra_instruction=extra)
        except Exception as e:
            print(f"      ⚠️ attempt {attempt + 1} error: {e}")
            time.sleep(REQUEST_DELAY)
            extra = "Return ONLY valid JSON for the week, exactly as specified."
            continue
        total += res["cost"]
        data = res["data"]
        data["workouts"] = topup_week(data.get("workouts", []), minutes)
        v = _validate_exempt_aware(data, m["sessions_per_week"])
        if not v["valid"]:
            last_issues = v["issues"][:5]
            print(f"      ⚠️ validation issues: {last_issues}")
            extra = ("Your previous week was REJECTED for these issues: "
                     + "; ".join(last_issues)
                     + ". Regenerate the ENTIRE week fixing every issue.")
            time.sleep(REQUEST_DELAY)
            continue
        bad = unresolved_in_week(sb, data)
        if bad and len(bad) <= 4:
            print(f"      ⚠️ unresolved names: {bad} — substituting locally")
            bad = local_substitute(sb, data, bad, allowed)
        if bad:
            print(f"      ⚠️ unresolved names: {bad[:8]}")
            extra = ("These exercise names are NOT in our library: "
                     + ", ".join(bad[:12])
                     + ". Regenerate the SAME week keeping everything else, "
                       "replacing ONLY those exercises with equivalents from "
                       "the EXERCISE LIBRARY list.")
            time.sleep(REQUEST_DELAY)
            continue
        return data, total
    print(f"      ❌ week {wk} failed after 3 attempts ({last_issues})")
    return None, total


def derive_matrix(sb, m, base_id, primary_vid, prog_dict) -> int:
    dur, spw = m["duration_weeks"], m["sessions_per_week"]
    minutes = m["session_duration_minutes"]
    rows = (sb.table("program_variant_weeks")
            .select("week_number, phase, focus, workouts")
            .eq("variant_id", primary_vid).order("week_number").execute().data) or []
    primary = [{"week": r["week_number"], "phase": r.get("phase"),
                "focus": r.get("focus"), "workouts": r.get("workouts", [])}
               for r in rows]
    if len(primary) < dur:
        print(f"   ⚠️ primary incomplete ({len(primary)}/{dur}) — derive skipped")
        return 0

    weeks_axis, sessions_axis = pb.build_matrix(dur, spw, m["is_express"])
    counts = week_counts_for_base(sb, base_id)
    vmeta = (sb.table("program_variants")
             .select("id, duration_weeks, sessions_per_week, intensity_level")
             .eq("base_program_id", base_id).execute().data) or []
    by_cell = {(v["duration_weeks"], v["sessions_per_week"],
                v["intensity_level"]): v["id"] for v in vmeta}

    n_done = 0
    for weeks in weeks_axis:
        wk_mapped = None
        for sessions in sessions_axis:
            for intensity in pb.INTENSITIES:
                vid = by_cell.get((weeks, sessions, intensity))
                if vid and len(counts.get(vid, set())) >= weeks:
                    n_done += 1
                    continue  # cell complete — resume skip
                if wk_mapped is None:
                    wk_mapped = pb.map_weeks(primary, weeks)
                vname = f"{m['editorial_name']} — {weeks}w/{sessions}d/{intensity}"
                if not vid:
                    vid = ensure_variant(sb, base_id, vname, weeks, sessions,
                                         intensity, minutes,
                                         m["program_category"])
                    if not vid:
                        continue
                    by_cell[(weeks, sessions, intensity)] = vid
                have = counts.get(vid, set())
                for w in wk_mapped:
                    if w["week"] in have:
                        continue
                    cell_week = pb.map_sessions(
                        pb.scale_intensity(w, intensity), sessions)
                    workouts = topup_week(cell_week["workouts"], minutes)
                    gp.ingest_week_to_supabase(
                        sb, vid, w["week"],
                        {"week": w["week"], "phase": w.get("phase"),
                         "focus": w.get("focus"), "workouts": workouts},
                        {"name": f"{m['editorial_name']} (Zealova Library)",
                         "variant_name": vname,
                         "category": m["program_category"]})
                n_done += 1
    return n_done


def run_daily_blob(sb, m: dict, dry_run: bool) -> dict:
    blob = DAILY_BLOB_BUILDERS[m["slug"]]()
    names = sorted({e["name"] for d in blob["workouts"]
                    for e in d["exercises"]})
    if dry_run:
        print(f"   dry-run: {len(blob['workouts'])} days, names={names}")
        return {"slug": m["slug"], "dry_run": True, "est_cost": 0}
    bad = [n for n in names if not name_resolves(sb, n)]
    if bad:
        return {"slug": m["slug"], "error": f"unresolved names: {bad}"}
    pid = ensure_programs_row(sb, m)
    sb.table("programs").update({
        "workouts": blob,
        "has_workouts": True,
        "duration_weeks": m["duration_weeks"],
        "sessions_per_week": m["sessions_per_week"],
        "session_duration_minutes": m["session_duration_minutes"],
    }).eq("id", pid).execute()
    print(f"   ✅ daily blob written ({len(blob['workouts'])} days, "
          f"{len(names)} distinct moves, all resolved) — UNPUBLISHED")
    return {"slug": m["slug"], "pid": pid, "cost": 0.0}


# ---------------------------------------------------------------------------
# publish / report
# ---------------------------------------------------------------------------
def publish_batch(sb, manifest, batch: int):
    slugs = [m for m in manifest if m["batch"] == batch]
    for m in slugs:
        row = (sb.table("programs").select("id, has_workouts")
               .eq("program_name", m["program_name"]).limit(1).execute().data)
        if not row:
            print(f"   ❌ {m['slug']}: no programs row — NOT publishing")
            continue
        if not row[0].get("has_workouts"):
            print(f"   ❌ {m['slug']}: has_workouts=false — NOT publishing")
            continue
        sb.table("programs").update({"is_published": True}).eq(
            "id", row[0]["id"]).execute()
        print(f"   ✅ published: {m['editorial_name']}")


def report(sb, manifest):
    grand = 0.0
    for m in manifest:
        row = (sb.table("programs")
               .select("id, is_published, has_workouts, variant_base_id, default_variant_id")
               .eq("program_name", m["program_name"]).limit(1).execute().data)
        if not row:
            print(f"   — {m['slug']:24s} NOT STARTED")
            continue
        r = row[0]
        if m["gen_mode"] == "daily_blob":
            print(f"   ✓ {m['slug']:24s} blob has_workouts={r['has_workouts']} "
                  f"published={r['is_published']}")
            continue
        base = r.get("variant_base_id")
        cells = weeks_n = cost = 0
        if base:
            vs = (sb.table("program_variants")
                  .select("id, generation_cost_usd")
                  .eq("base_program_id", base).execute().data) or []
            cells = len(vs)
            cost = sum(float(v.get("generation_cost_usd") or 0) for v in vs)
            counts = week_counts_for_base(sb, base)
            weeks_n = sum(len(s) for s in counts.values())
        grand += cost
        print(f"   {'✓' if r['is_published'] else '·'} {m['slug']:24s} "
              f"variants={cells:3d} weeks={weeks_n:4d} cost=${cost:.3f} "
              f"published={r['is_published']}")
    print(f"\n   TOTAL Gemini spend: ${grand:.3f}")


def main():
    ap = argparse.ArgumentParser()
    g = ap.add_mutually_exclusive_group(required=True)
    g.add_argument("--batch", type=int)
    g.add_argument("--program", type=str)
    g.add_argument("--publish-batch", type=int)
    g.add_argument("--report", action="store_true")
    g.add_argument("--all", action="store_true")
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--skip-derive", action="store_true")
    args = ap.parse_args()

    manifest = load_manifest()
    sb = _sb()
    print(f"generate_28_programs.py — model={GEMINI_MODEL} "
          f"(${gp.PRICE_IN_PER_M}/M in, ${gp.PRICE_OUT_PER_M}/M out)")

    if args.report:
        report(sb, manifest)
        return
    if args.publish_batch is not None:
        publish_batch(sb, manifest, args.publish_batch)
        return

    if args.program:
        targets = [m for m in manifest if m["slug"] == args.program]
        if not targets:
            sys.exit(f"unknown slug: {args.program}")
    elif args.batch is not None:
        targets = [m for m in manifest if m["batch"] == args.batch]
    else:
        targets = manifest

    results = []
    for m in targets:
        try:
            results.append(run_program(sb, m, dry_run=args.dry_run,
                                        skip_derive=args.skip_derive))
        except KeyboardInterrupt:
            print("\n⏹ interrupted — all persisted weeks are safe; re-run to resume")
            break
        except Exception as e:
            print(f"   ❌ {m['slug']} crashed: {e}")
            results.append({"slug": m["slug"], "error": str(e)})

    print(f"\n{'=' * 62}\nSUMMARY")
    total = 0.0
    for r in results:
        total += r.get("cost", 0) or 0
        status = "ERROR: " + r["error"] if r.get("error") else \
                 ("dry-run" if r.get("dry_run") else "ok")
        print(f"   {r['slug']:24s} {status}")
    print(f"   total cost this run: ${total:.3f}")


if __name__ == "__main__":
    main()
