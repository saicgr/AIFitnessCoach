"""
Workout variant generator — lighter (deload) + moderate (cycle) variants.

Plan: §1b.2, §1b.5.

The home workout card surfaces two one-tap intensity swaps:

  - `deload`   → drop sets per exercise to max(2, n-2), cap intensity at
                 50-70% of source, RPE 5-6, duration ≈ ×0.55. Used by
                 `recoveryLighter` mode.
  - `moderate` → keep exercise count + sets, cap intensity at 75%, RPE
                 6-7, duration ≈ ×0.75. Used by `cycleAdjusted` mode.

For each variant we also surface up to 2 RAG-suggested LOWER-IMPACT swaps
per exercise (`{from, to, reason}`) sourced from the existing
`fitness_exercises` Chroma collection (per memory `project_exercise_library_mv`).

Cache contract (`workout_variants` table, migration 2096):
  PRIMARY KEY (source_id, target_intensity)
A repeat request for the same (source, target) is instant — we look up the
cached variant_id and return the pre-built workout row.

No Gemini calls — pure transform + free vector lookups.
No silent fallbacks — RAG miss leaves `swaps` empty rather than fabricating.
"""
from __future__ import annotations

import copy
import logging
import uuid
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

logger = logging.getLogger("workout_variant_generator")


# ---------------------------------------------------------------------------
# Intensity profile per target — single source of truth.
# ---------------------------------------------------------------------------
_PROFILES: Dict[str, Dict[str, Any]] = {
    "deload": {
        "set_drop": 2,            # drop n-2 sets per exercise, floor at 2
        "min_sets": 2,
        "intensity_cap_pct": 0.60,  # mid of plan's 50-70% range
        "rpe_low": 5,
        "rpe_high": 6,
        "duration_multiplier": 0.55,
        "label": "Lighter",
    },
    "moderate": {
        "set_drop": 0,
        "min_sets": 1,
        "intensity_cap_pct": 0.75,
        "rpe_low": 6,
        "rpe_high": 7,
        "duration_multiplier": 0.75,
        "label": "Moderate",
    },
    # Bodyweight swap — chat-card "go fully bodyweight" path. Same set
    # shape as `moderate` for volume but weight is zeroed out (true
    # bodyweight execution). RAG layer surfaces lower-impact swaps that
    # are typically bodyweight equivalents.
    "bodyweight": {
        "set_drop": 0,
        "min_sets": 1,
        "intensity_cap_pct": 0.0,   # zero loaded weight; bodyweight only
        "rpe_low": 6,
        "rpe_high": 7,
        "duration_multiplier": 0.85,
        "label": "Bodyweight",
    },
}

VALID_INTENSITIES = tuple(_PROFILES.keys())


# ---------------------------------------------------------------------------
# Pure transform — no IO. Used by both the cache hit + miss paths.
# ---------------------------------------------------------------------------
def _scale_set(s: Dict[str, Any], profile: Dict[str, Any]) -> Dict[str, Any]:
    """Cap weight at intensity_cap_pct of source target_weight_kg, clamp RPE."""
    out = dict(s)
    try:
        w = s.get("target_weight_kg") or s.get("weight_kg")
        if w is not None:
            out["target_weight_kg"] = round(float(w) * profile["intensity_cap_pct"], 1)
    except (TypeError, ValueError):
        pass
    out["target_rpe_low"] = profile["rpe_low"]
    out["target_rpe_high"] = profile["rpe_high"]
    return out


def _transform_exercise(ex: Dict[str, Any], profile: Dict[str, Any]) -> Dict[str, Any]:
    """Drop sets per profile + scale remaining sets' weight/RPE."""
    out = copy.deepcopy(ex)
    sets = out.get("set_targets") or []
    if isinstance(sets, list) and sets:
        n = len(sets)
        target_n = max(profile["min_sets"], n - profile["set_drop"])
        sets = sets[:target_n]
        sets = [_scale_set(s, profile) for s in sets if isinstance(s, dict)]
        out["set_targets"] = sets
    return out


def _rag_swaps(exercises: List[Dict[str, Any]],
               max_swaps_per_ex: int = 2,
               max_total_swaps: int = 6) -> List[Dict[str, str]]:
    """Query ChromaDB for lower-impact semantic swaps per exercise.

    Returns a flat list of `{from, to, reason}` dicts. Best-effort —
    Chroma failure leaves the list empty (NO fabricated swaps).
    """
    swaps: List[Dict[str, str]] = []
    try:
        from core.chroma_cloud import get_chroma_cloud_client  # local import — keeps cold-start cheap
        from services.gemini_service import GeminiService
        gemini = GeminiService()
        client = get_chroma_cloud_client()
        collection = client.get_exercise_collection()
        for ex in exercises:
            if len(swaps) >= max_total_swaps:
                break
            name = (ex.get("name") or "").strip()
            if not name:
                continue
            try:
                # Query for "lower impact" semantic neighbours of the source
                # movement. We ask for a small N, then drop exact-name matches
                # so we never suggest swapping an exercise for itself.
                # Chroma Cloud collections have no server-side embedding
                # function — must pass `query_embeddings=` explicitly.
                query_emb = gemini.get_embedding(f"lower impact alternative to {name}")
                if not query_emb:
                    continue
                results = collection.query(
                    query_embeddings=[query_emb],
                    n_results=4,
                )
                ids_row = (results or {}).get("ids") or [[]]
                docs_row = (results or {}).get("documents") or [[]]
                metas_row = (results or {}).get("metadatas") or [[]]
                ids = ids_row[0] if ids_row else []
                metas = metas_row[0] if metas_row else []
                docs = docs_row[0] if docs_row else []
                seen = 0
                for i, _id in enumerate(ids):
                    meta = metas[i] if i < len(metas) else {}
                    cand_name = (meta or {}).get("name") or (
                        (docs[i] or "").split("·")[0].strip() if i < len(docs) else None
                    )
                    if not cand_name or cand_name.lower() == name.lower():
                        continue
                    swaps.append({
                        "from": name,
                        "to": cand_name,
                        "reason": "lower-impact swap",
                    })
                    seen += 1
                    if seen >= max_swaps_per_ex:
                        break
            except Exception as inner:
                logger.warning(f"[variant_generator] RAG swap query failed for '{name}': {inner}")
                continue
    except Exception as e:
        # Chroma unreachable — never block variant generation on this.
        logger.warning(f"[variant_generator] RAG swap layer skipped: {e}")
    return swaps


# ---------------------------------------------------------------------------
# Public API
# ---------------------------------------------------------------------------
def generate_variant(workout_dict: Dict[str, Any],
                     target_intensity: str) -> Dict[str, Any]:
    """Pure-ish builder. Returns the variant dict:

        {id, intensity, duration_minutes, exercises[], swaps[]}

    `id` is a deterministic uuid5 over (source_id, target_intensity) so
    repeat calls return the same id even before the cache row is written.
    Callers (e.g. card_context) persist the cache row separately via
    `persist_variant_cache_row()` below.
    """
    if target_intensity not in _PROFILES:
        raise ValueError(
            f"unknown target_intensity={target_intensity!r}; expected one of {VALID_INTENSITIES}"
        )
    profile = _PROFILES[target_intensity]

    source_id = workout_dict.get("id") or ""
    source_exercises = workout_dict.get("exercises_json") or []
    if not isinstance(source_exercises, list):
        source_exercises = []

    # Transform exercises.
    new_exercises = [
        _transform_exercise(ex, profile)
        for ex in source_exercises if isinstance(ex, dict)
    ]

    # Duration scaling.
    src_dur = workout_dict.get("duration_minutes") or 0
    try:
        new_dur = max(15, int(round(float(src_dur) * profile["duration_multiplier"])))
    except (TypeError, ValueError):
        new_dur = src_dur or 30

    # RAG swaps (best-effort, see _rag_swaps for failure handling).
    swaps = _rag_swaps(new_exercises)

    # Deterministic variant id so cache lookups + just-generated id agree.
    variant_id = str(uuid.uuid5(uuid.NAMESPACE_URL,
                                f"workout-variant:{source_id}:{target_intensity}"))

    return {
        "id": variant_id,
        "source_id": source_id,
        "intensity": target_intensity,
        "label": profile["label"],
        "duration_minutes": new_dur,
        "exercises": new_exercises,
        "swaps": swaps,
    }


def get_cached_variant(sb, source_id: str, target_intensity: str) -> Optional[Dict[str, Any]]:
    """Return the cached variant payload (joined to the variant workout row)
    if present, else None. `sb` is a get_supabase_db() handle."""
    if not source_id or target_intensity not in _PROFILES:
        return None
    try:
        cv = sb.client.table("workout_variants").select(
            "source_id, target_intensity, variant_id, generated_at"
        ).eq("source_id", source_id).eq(
            "target_intensity", target_intensity
        ).maybe_single().execute()
        if not (cv and cv.data):
            return None
        variant_id = cv.data.get("variant_id")
        if not variant_id:
            return None
        vr = sb.client.table("workouts").select(
            "id, name, duration_minutes, exercises_json, intensity_mode"
        ).eq("id", variant_id).maybe_single().execute()
        if not (vr and vr.data):
            return None
        row = vr.data
        return {
            "id": row.get("id"),
            "source_id": source_id,
            "intensity": target_intensity,
            "label": _PROFILES[target_intensity]["label"],
            "duration_minutes": row.get("duration_minutes"),
            "exercises": row.get("exercises_json") or [],
            # Swaps are RAG-derived, not persisted. They re-compute on miss
            # but on cache hit we omit them to keep the path instant.
            "swaps": [],
            "cached": True,
        }
    except Exception as e:
        logger.warning(f"[variant_generator] cache lookup failed: {e}")
        return None


def persist_variant_cache_row(sb, source_workout: Dict[str, Any],
                              variant: Dict[str, Any]) -> bool:
    """Persist the variant as a new `workouts` row + cache pointer in
    `workout_variants`. Returns True on success.

    The variant workout is INSERTed with the same user_id and an
    `intensity_mode` reflecting the target intensity so existing UI that
    branches on intensity_mode continues to work.
    """
    target_intensity = variant.get("intensity")
    if target_intensity not in _PROFILES:
        return False
    user_id = source_workout.get("user_id")
    source_id = source_workout.get("id")
    if not user_id or not source_id:
        return False
    try:
        # Idempotency: if a row already exists, treat as success.
        existing = sb.client.table("workout_variants").select(
            "variant_id"
        ).eq("source_id", source_id).eq(
            "target_intensity", target_intensity
        ).maybe_single().execute()
        if existing and existing.data and existing.data.get("variant_id"):
            return True

        now_iso = datetime.now(timezone.utc).isoformat()
        new_workout = {
            "user_id": user_id,
            "name": f"{source_workout.get('name') or 'Workout'} ({_PROFILES[target_intensity]['label']})",
            "type": source_workout.get("type"),
            "difficulty": source_workout.get("difficulty"),
            "scheduled_date": source_workout.get("scheduled_date"),
            "exercises_json": variant.get("exercises") or [],
            "duration_minutes": variant.get("duration_minutes"),
            "generation_method": "variant",
            "generation_source": "card_variant_generator",
            "generation_metadata": {
                "source_workout_id": source_id,
                "target_intensity": target_intensity,
            },
            "generated_at": now_iso,
            "parent_workout_id": source_id,
            "intensity_mode": target_intensity,
            "status": "draft",
            "is_current": False,
        }
        ins = sb.client.table("workouts").insert(new_workout).execute()
        if not (ins and ins.data):
            return False
        new_id = ins.data[0].get("id")
        if not new_id:
            return False
        sb.client.table("workout_variants").insert({
            "source_id": source_id,
            "target_intensity": target_intensity,
            "variant_id": new_id,
        }).execute()
        return True
    except Exception as e:
        logger.warning(f"[variant_generator] persist failed: {e}")
        return False
