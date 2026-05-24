"""
User-history RAG collections.

Plan: §1b.9.

Three per-user Chroma Cloud collections power the coach's long-term
semantic recall ("last time you trained chest after a low-sleep night,
you cut 2 sets — try the same today"):

  user_workout_history    one doc per completed workout
  user_nutrition_history  one doc per logged day
  user_sleep_history      one doc per night

Document text + metadata are defined exactly as the §1b.9 spec so the
backfill script + the incremental hooks + the retriever all see the same
shape.

Why these helpers are isolated from `core/chroma_cloud.py`: the existing
client lists fixed exercise/menu/saved-food/cardio collections. These
three are user-history-scoped — kept here so future migrations don't
have to touch the core client. All three share the SAME Chroma Cloud
HTTP client instance (`get_chroma_cloud_client()`), so this does NOT
open a new connection.

Idempotency: each helper uses `upsert` (Chroma's `add` + a stable id).
The id includes the user_id and the source row id so re-indexing the
same event is a no-op.
"""
from __future__ import annotations

import logging
from typing import Any, Dict, List, Optional, Tuple

from core.chroma_cloud import get_chroma_cloud_client

logger = logging.getLogger("user_history_collection")


def _embed(text: str) -> Optional[List[float]]:
    """Sync embedding helper. Reuses GeminiService.get_embedding (which
    has its own local cache). Returns None on failure so the caller can
    skip insert rather than insert without an embedding (Chroma Cloud's
    REST API requires an embedding when no collection-level embedding
    function is configured)."""
    try:
        from services.gemini_service import GeminiService
        svc = GeminiService()
        return svc.get_embedding(text)
    except Exception as e:
        logger.warning(f"[user_history_collection] embed failed: {e}")
        return None


WORKOUT_COLLECTION = "user_workout_history"
NUTRITION_COLLECTION = "user_nutrition_history"
SLEEP_COLLECTION = "user_sleep_history"

ALL_COLLECTIONS = (WORKOUT_COLLECTION, NUTRITION_COLLECTION, SLEEP_COLLECTION)


# ---------------------------------------------------------------------------
# Init — call once at boot / migration time. Idempotent.
# ---------------------------------------------------------------------------
def ensure_collections() -> Dict[str, bool]:
    """Create the three collections if they don't already exist.

    Returns `{collection_name: ok_bool}`. Best-effort — a transient
    Chroma Cloud failure on one collection doesn't prevent the others
    from initialising.
    """
    out: Dict[str, bool] = {}
    client = get_chroma_cloud_client()
    for name in ALL_COLLECTIONS:
        try:
            client.get_or_create_collection(name)
            out[name] = True
        except Exception as e:
            logger.error(f"[user_history_collection] init {name} failed: {e}")
            out[name] = False
    return out


# ---------------------------------------------------------------------------
# Internal helpers — defensive formatting so docs never crash on missing
# fields (per CLAUDE.md no-silent-fallback: a None field is rendered as
# the literal '—' not a fake number).
# ---------------------------------------------------------------------------
def _fmt_n(v: Any, suffix: str = "") -> str:
    if v is None:
        return "—"
    try:
        return f"{int(v)}{suffix}" if float(v).is_integer() else f"{round(float(v), 1)}{suffix}"
    except Exception:
        return str(v)


def _exercises_top_sets_summary(exercises_json: Any, cap: int = 4) -> str:
    """Compact one-liner of the heaviest set per exercise (up to `cap`)."""
    if not isinstance(exercises_json, list):
        return ""
    parts: List[str] = []
    for ex in exercises_json[:cap]:
        if not isinstance(ex, dict):
            continue
        sets = ex.get("set_targets") or []
        top: Optional[Tuple[float, int]] = None
        for s in sets:
            if not isinstance(s, dict):
                continue
            try:
                w = float(s.get("target_weight_kg") or s.get("weight_kg") or 0)
                r = int(s.get("target_reps") or s.get("reps") or 0)
            except (TypeError, ValueError):
                continue
            if w > 0 and r > 0 and (top is None or w * (1 + r / 30.0) > top[0] * (1 + top[1] / 30.0)):
                top = (w, r)
        name = ex.get("name") or "exercise"
        if top:
            parts.append(f"{name} {_fmt_n(top[0])}kg×{top[1]}")
        else:
            parts.append(name)
    return ", ".join(parts)


# ---------------------------------------------------------------------------
# Insert helpers — one per event type. All idempotent via stable id.
# ---------------------------------------------------------------------------
def index_workout(user_id: str, workout: Dict[str, Any]) -> bool:
    """Index a completed workout.

    Document shape (§1b.9):
        "{date} · {workout_name} · {exercises_top_sets} · {duration}m · vol {volume_kg}kg · RPE {avg_rpe}"
    """
    workout_id = workout.get("id")
    if not (user_id and workout_id):
        return False
    try:
        sched = workout.get("scheduled_date") or workout.get("completed_at") or ""
        d = (sched or "")[:10] or "—"
        name = workout.get("name") or "Workout"
        exs = workout.get("exercises_json") or []
        top_sets = _exercises_top_sets_summary(exs)
        duration = workout.get("duration_minutes")
        meta = workout.get("generation_metadata") or {}
        volume = meta.get("volume_kg")
        avg_rpe = meta.get("avg_rpe")
        muscle_groups: List[str] = []
        if isinstance(exs, list):
            for ex in exs:
                if isinstance(ex, dict):
                    mg = ex.get("muscle_group") or ex.get("body_part")
                    if mg and isinstance(mg, str):
                        muscle_groups.append(mg.lower())
        muscle_groups = sorted(set(muscle_groups))[:8]

        doc = (
            f"{d} · {name} · {top_sets or 'no sets'} · "
            f"{_fmt_n(duration, 'm')} · vol {_fmt_n(volume, 'kg')} · "
            f"RPE {_fmt_n(avg_rpe)}"
        )
        metadata = {
            "user_id": user_id,
            "date": d,
            "workout_id": workout_id,
            "muscle_groups": ",".join(muscle_groups) if muscle_groups else "",
        }
        emb = _embed(doc)
        if emb is None:
            return False
        client = get_chroma_cloud_client()
        client.add_documents(
            collection_name=WORKOUT_COLLECTION,
            documents=[doc],
            metadatas=[metadata],
            ids=[f"{user_id}:{workout_id}"],
            embeddings=[emb],
        )
        return True
    except Exception as e:
        logger.warning(f"[user_history_collection] index_workout failed: {e}")
        return False


def index_nutrition_day(user_id: str, date_iso: str,
                        kcal: Optional[int], protein_g: Optional[float],
                        meals: List[str],
                        calorie_target: Optional[int] = None,
                        protein_target: Optional[float] = None,
                        flags: Optional[List[str]] = None) -> bool:
    """Index one day of nutrition logs.

    Document shape (§1b.9):
        "{date} · {kcal} kcal · {protein}g protein · meals: {meal_names_joined} · notable: {flags}"
    """
    if not (user_id and date_iso):
        return False
    try:
        notable = ", ".join(flags) if flags else "—"
        doc = (
            f"{date_iso} · {_fmt_n(kcal, ' kcal')} · "
            f"{_fmt_n(protein_g, 'g protein')} · "
            f"meals: {', '.join(meals) if meals else '—'} · "
            f"notable: {notable}"
        )
        cal_hit = (kcal is not None and calorie_target and
                   abs(int(kcal) - int(calorie_target)) <= int(calorie_target) * 0.1)
        protein_hit = (protein_g is not None and protein_target and
                       float(protein_g) >= float(protein_target) * 0.95)
        metadata = {
            "user_id": user_id,
            "date": date_iso,
            "calorie_hit": bool(cal_hit),
            "protein_hit": bool(protein_hit),
        }
        emb = _embed(doc)
        if emb is None:
            return False
        client = get_chroma_cloud_client()
        client.add_documents(
            collection_name=NUTRITION_COLLECTION,
            documents=[doc],
            metadatas=[metadata],
            ids=[f"{user_id}:{date_iso}"],
            embeddings=[emb],
        )
        return True
    except Exception as e:
        logger.warning(f"[user_history_collection] index_nutrition_day failed: {e}")
        return False


def index_sleep_night(user_id: str, date_iso: str,
                      minutes: Optional[int], bedtime: Optional[str],
                      score: Optional[int] = None) -> bool:
    """Index one night of sleep.

    Document shape (§1b.9):
        "{date} · {hours}h · score {N} · {tier} · bedtime {time}"
    """
    if not (user_id and date_iso):
        return False
    try:
        hours_str = "—"
        if minutes:
            hours = round(int(minutes) / 60.0, 1)
            hours_str = f"{hours}h"
        # Tier from sleep_minutes when score is missing.
        if score is not None:
            tier = "great" if score >= 80 else "ok" if score >= 65 else "poor"
        elif minutes is not None:
            tier = "great" if minutes >= 450 else "ok" if minutes >= 390 else "poor"
        else:
            tier = "unknown"
        doc = (
            f"{date_iso} · {hours_str} · score {_fmt_n(score)} · "
            f"{tier} · bedtime {bedtime or '—'}"
        )
        metadata = {
            "user_id": user_id,
            "date": date_iso,
            "score": int(score) if score is not None else -1,
            "tier": tier,
        }
        emb = _embed(doc)
        if emb is None:
            return False
        client = get_chroma_cloud_client()
        client.add_documents(
            collection_name=SLEEP_COLLECTION,
            documents=[doc],
            metadatas=[metadata],
            ids=[f"{user_id}:{date_iso}"],
            embeddings=[emb],
        )
        return True
    except Exception as e:
        logger.warning(f"[user_history_collection] index_sleep_night failed: {e}")
        return False


def refresh_nutrition_day_from_db(user_id: str, date_iso: str) -> bool:
    """Incremental hook for /food-logs/* create endpoints.

    Re-aggregates the user's food_logs for `date_iso` and writes/overwrites
    the single nutrition doc for that day. Idempotent — the stable id
    `{user_id}:{date_iso}` causes Chroma to replace the existing doc.

    Best-effort: any DB or Chroma failure logs + returns False without
    raising — the caller is a fire-and-forget BackgroundTask.
    """
    try:
        from core.db import get_supabase_db
        sb = get_supabase_db()

        start_iso = f"{date_iso}T00:00:00+00:00"
        end_iso = f"{date_iso}T23:59:59+00:00"
        fl = sb.client.table("food_logs").select(
            "total_calories, protein_g, meal_type, food_name, logged_at, deleted_at"
        ).eq("user_id", user_id).gte("logged_at", start_iso).lte(
            "logged_at", end_iso
        ).is_("deleted_at", "null").execute()
        rows = fl.data or []
        if not rows:
            return False
        kcal = sum(int(r.get("total_calories") or 0) for r in rows)
        protein = sum(float(r.get("protein_g") or 0) for r in rows)
        meals: List[str] = []
        for r in rows:
            n = r.get("food_name") or r.get("meal_type")
            if n and isinstance(n, str):
                meals.append(n[:30])

        # Pull targets to set the `_hit` metadata fields.
        cal_target = None
        prot_target = None
        try:
            ur = sb.client.table("users").select(
                "daily_calorie_target, daily_protein_target_g"
            ).eq("id", user_id).maybe_single().execute()
            if ur and ur.data:
                cal_target = ur.data.get("daily_calorie_target")
                prot_target = ur.data.get("daily_protein_target_g")
        except Exception:
            pass

        return index_nutrition_day(
            user_id, date_iso,
            kcal=kcal or None,
            protein_g=round(protein, 1) or None,
            meals=meals[:6],
            calorie_target=cal_target,
            protein_target=float(prot_target) if prot_target else None,
        )
    except Exception as e:
        logger.warning(f"[user_history_collection] refresh_nutrition_day failed: {e}")
        return False


def refresh_sleep_night_from_da_row(user_id: str, da_row: Dict[str, Any]) -> bool:
    """Incremental hook for /activity/sync — accepts the daily_activity
    row dict directly. Returns False on missing sleep_minutes."""
    try:
        sm = da_row.get("sleep_minutes") or 0
        if sm <= 0:
            return False
        d = da_row.get("activity_date")
        if not d:
            return False
        if hasattr(d, "isoformat"):
            d = d.isoformat()
        bedtime = None
        bt = da_row.get("sleep_start")
        if bt:
            try:
                from datetime import datetime as _dt
                if isinstance(bt, str):
                    dt = _dt.fromisoformat(bt.replace("Z", "+00:00"))
                else:
                    dt = bt
                bedtime = dt.strftime("%H:%M")
            except Exception:
                bedtime = None
        return index_sleep_night(user_id, d, minutes=int(sm), bedtime=bedtime)
    except Exception as e:
        logger.warning(f"[user_history_collection] refresh_sleep_night failed: {e}")
        return False


def doc_exists(collection_name: str, doc_id: str) -> bool:
    """Idempotency check for the backfill script — returns True if a doc
    with this id is already present. Best-effort; on Chroma failure
    we return False so the caller proceeds with insert (which is itself
    idempotent via the stable id)."""
    try:
        client = get_chroma_cloud_client()
        collection = client.get_or_create_collection(collection_name)
        existing = collection.get(ids=[doc_id])
        ids = (existing or {}).get("ids") or []
        return bool(ids)
    except Exception:
        return False
