"""
RAG indexer for imported workout history.

Groups per-set rows into per-session documents (one doc per user × exercise ×
date) and upserts them into ChromaDB. Chat agents query this collection to
answer questions like "what's my bench PR?" / "how many times did I squat last
month?" using the same semantic-search primitive they already use for workout
plans.

Cardio rows go into a sibling user_cardio_history collection with the same
per-session granularity.

Deliberately per-session (not per-set) granularity: a lifter with 2 years of
history has ~3k exercise-sessions but 30k sets. 3k docs keeps the collection
cardinality sane while still giving the retriever enough signal to recall
specific PRs.
"""
from __future__ import annotations

import hashlib
from collections import defaultdict
from datetime import date
from typing import Iterable, Optional
from uuid import UUID

from core.chroma_cloud import get_chroma_cloud_client
from core.logger import get_logger

from .canonical import CanonicalCardioRow, CanonicalSetRow

logger = get_logger(__name__)


def _session_doc_id(user_id: UUID, canonical: str, d: date) -> str:
    """Stable per-session doc id; upsert-safe on re-import."""
    raw = f"{user_id}|{canonical}|{d.isoformat()}"
    return hashlib.sha256(raw.encode("utf-8")).hexdigest()


def _format_session_doc(
    *,
    user_first_name: str,
    canonical: str,
    d: date,
    sets: list[CanonicalSetRow],
    source_app: str,
) -> tuple[str, dict]:
    """Render a single session as a compact natural-language doc for embed +
    return the metadata dict. The doc mentions the user's first name so
    retrievals surface in chat with correct pronoun.
    """
    working = [s for s in sets if (s.set_type in ("working", "failure", "dropset", "amrap")
                                    or (isinstance(s.set_type, str) and s.set_type in (
                                        "working", "failure", "dropset", "amrap")))]
    if not working:
        working = sets

    def _line(s: CanonicalSetRow) -> str:
        parts: list[str] = []
        if s.weight_kg is not None:
            parts.append(f"{s.weight_kg:.1f}kg")
        if s.reps is not None:
            parts.append(f"× {s.reps}")
        if s.rpe is not None:
            parts.append(f"@RPE{s.rpe}")
        elif s.rir is not None:
            parts.append(f"@{s.rir}RIR")
        return " ".join(parts).strip() or "BW"

    # Compute top set by weight_kg (fallback: highest reps).
    top_set = max(
        working,
        key=lambda s: (s.weight_kg or -1, s.reps or -1),
    )
    top_weight = top_set.weight_kg
    top_reps = top_set.reps

    lines = ", ".join(_line(s) for s in working[:12])
    display_name = canonical.replace("_", " ").title()
    pronoun = user_first_name or "User"

    doc = (
        f"{pronoun} performed {display_name} on {d.isoformat()}: "
        f"{len(sets)} set{'s' if len(sets) != 1 else ''} — {lines}"
    )
    if top_weight is not None and top_reps is not None:
        doc += f". Top set: {top_weight:.1f}kg × {top_reps}."
    if source_app:
        doc += f" (source: {source_app})"

    total_volume_kg = sum(
        (s.weight_kg or 0) * (s.reps or 0)
        for s in sets
    )

    metadata: dict = {
        "user_id": str(sets[0].user_id),
        "exercise_name_canonical": canonical,
        "performed_date": d.isoformat(),
        "performed_epoch": int(
            __import__("datetime").datetime.combine(
                d, __import__("datetime").time()
            ).timestamp()
        ),
        "set_count": len(sets),
        "top_weight_kg": float(top_weight) if top_weight is not None else 0.0,
        "top_reps": int(top_reps) if top_reps is not None else 0,
        "total_volume_kg": float(total_volume_kg),
        "source_app": source_app,
    }
    # Only attach exercise_id if every row agrees.
    exercise_ids = {str(s.exercise_id) for s in sets if s.exercise_id is not None}
    if len(exercise_ids) == 1:
        metadata["exercise_id"] = exercise_ids.pop()
    return doc, metadata


def index_strength_sessions(
    rows: Iterable[CanonicalSetRow],
    *,
    user_first_name: str = "User",
) -> int:
    """Group rows by (user, canonical, date) and upsert one doc per group.
    Returns the count of docs indexed."""
    grouped: dict[tuple[str, str, date], list[CanonicalSetRow]] = defaultdict(list)
    for row in rows:
        canonical = row.exercise_name_canonical or row.exercise_name_raw
        key = (str(row.user_id), canonical, row.performed_at.date())
        grouped[key].append(row)

    if not grouped:
        return 0

    chroma = get_chroma_cloud_client()
    collection = chroma.get_user_exercise_history_collection()

    ids: list[str] = []
    docs: list[str] = []
    metas: list[dict] = []
    for (uid, canonical, d), session_rows in grouped.items():
        doc, meta = _format_session_doc(
            user_first_name=user_first_name,
            canonical=canonical,
            d=d,
            sets=session_rows,
            source_app=session_rows[0].source_app,
        )
        ids.append(_session_doc_id(UUID(uid), canonical, d))
        docs.append(doc)
        metas.append(meta)

    # Upsert: delete + add is the portable idempotent path across the HTTP
    # client. The collection.add path would collide on existing ids.
    try:
        collection.delete(ids=ids)
    except Exception as e:
        # Non-fatal — on first write the ids don't exist yet.
        logger.debug(f"[RAG] pre-delete miss (expected on first write): {e}")
    collection.add(ids=ids, documents=docs, metadatas=metas)
    logger.info(f"[RAG] Indexed {len(ids)} strength session docs")
    return len(ids)


def index_cardio_sessions(
    rows: Iterable[CanonicalCardioRow],
    *,
    user_first_name: str = "User",
) -> int:
    """One doc per cardio session. Smaller cardinality than strength — users
    don't split cardio sessions by sub-exercise so there is no grouping needed.
    """
    row_list = list(rows)
    if not row_list:
        return 0

    chroma = get_chroma_cloud_client()
    collection = chroma.get_user_cardio_history_collection()

    ids: list[str] = []
    docs: list[str] = []
    metas: list[dict] = []
    for r in row_list:
        verb = {
            "run": "ran", "trail_run": "ran", "treadmill": "ran on treadmill",
            "cycle": "cycled", "indoor_cycle": "cycled indoors",
            "row": "rowed", "swim": "swam", "walk": "walked",
            "hike": "hiked", "elliptical": "did elliptical",
        }.get(r.activity_type, r.activity_type.replace("_", " "))
        dist_part = f" {r.distance_m / 1000:.2f} km" if r.distance_m else ""
        mins = r.duration_seconds // 60
        secs = r.duration_seconds % 60
        dur_part = f" in {mins}:{secs:02d}"
        pace_part = ""
        if r.avg_pace_seconds_per_km:
            pm = int(r.avg_pace_seconds_per_km) // 60
            ps = int(r.avg_pace_seconds_per_km) % 60
            pace_part = f" (avg {pm}:{ps:02d}/km)"
        hr_part = f", {r.avg_heart_rate} bpm avg" if r.avg_heart_rate else ""
        name = user_first_name or "User"
        doc = f"{name} {verb}{dist_part}{dur_part}{pace_part}{hr_part} on {r.performed_at.date().isoformat()} via {r.source_app}"

        meta: dict = {
            "user_id": str(r.user_id),
            "activity_type": r.activity_type,
            "performed_date": r.performed_at.date().isoformat(),
            "performed_epoch": int(r.performed_at.timestamp()),
            "duration_seconds": r.duration_seconds,
            "distance_m": float(r.distance_m) if r.distance_m else 0.0,
            "avg_heart_rate": int(r.avg_heart_rate) if r.avg_heart_rate else 0,
            "source_app": r.source_app,
        }
        if r.source_external_id:
            meta["source_external_id"] = r.source_external_id

        ids.append(hashlib.sha256(
            f"{r.user_id}|{r.activity_type}|{r.performed_at.isoformat()}".encode()
        ).hexdigest())
        docs.append(doc)
        metas.append(meta)

    try:
        collection.delete(ids=ids)
    except Exception as e:
        logger.debug(f"[RAG] cardio pre-delete miss: {e}")
    collection.add(ids=ids, documents=docs, metadatas=metas)
    logger.info(f"[RAG] Indexed {len(ids)} cardio session docs")
    return len(ids)


def update_session_metadata_for_remap(
    *,
    user_id: UUID,
    old_canonical: str,
    new_canonical: str,
    new_exercise_id: Optional[UUID] = None,
) -> int:
    """When a user bulk-remaps 'flat bench press' → 'barbell_bench_press',
    the existing session docs need their canonical name + exercise_id updated
    without re-embedding. Chroma HTTP supports collection.update() with just
    metadata — we rely on that.

    Returns rows affected (best-effort — Chroma HTTP doesn't always return a
    count, so we compute from matched ids).
    """
    chroma = get_chroma_cloud_client()
    collection = chroma.get_user_exercise_history_collection()

    # Find all docs for this user+old_canonical.
    try:
        matching = collection.get(
            where={"$and": [
                {"user_id": str(user_id)},
                {"exercise_name_canonical": old_canonical},
            ]},
            include=["metadatas"],
        )
    except Exception as e:
        logger.warning(f"[RAG] remap lookup failed: {e}")
        return 0

    ids = matching.get("ids") or []
    if not ids:
        return 0

    new_meta: list[dict] = []
    for meta in matching.get("metadatas") or []:
        updated = {**(meta or {})}
        updated["exercise_name_canonical"] = new_canonical
        if new_exercise_id:
            updated["exercise_id"] = str(new_exercise_id)
        new_meta.append(updated)

    try:
        collection.update(ids=ids, metadatas=new_meta)
    except Exception as e:
        logger.warning(f"[RAG] remap update failed: {e}")
        return 0

    logger.info(f"[RAG] Remapped {len(ids)} session docs: {old_canonical} → {new_canonical}")
    return len(ids)
