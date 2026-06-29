"""Metric registry — the single catalog of per-set tracking metrics.

Every per-set metric (weight, reps, distance, time, box height, calories, …)
has a stable ``key``, a canonical storage unit, and a ``bag_key`` — the JSON
key it occupies in the canonical ``performance_logs.metrics`` JSONB bag. The
four first-class metrics additionally mirror to a typed ``performance_logs``
column so the existing analytics (PRs, strength score, volume, history) keep
reading them unchanged while the generic bag becomes the source of truth.

Mirrored on the Flutter side in
``mobile/flutter/lib/core/utils/exercise_tracking_metric.dart`` — keep the
``bag_key`` strings identical across both.

Pure + dependency-free so it can be imported anywhere (serializers, the log
endpoints, the classifier) with zero cost.
"""
from __future__ import annotations

from typing import Any, Dict, Optional


# Canonical bag_key -> typed performance_logs column (first-class metrics only).
FIRST_CLASS_COLUMN: Dict[str, str] = {
    "weight_kg": "weight_kg",
    "reps": "reps_completed",
    "distance_m": "distance_meters",
    "time_s": "set_duration_seconds",
}

# Built-in metric catalog: key -> definition. `first_class` metrics mirror to a
# typed column; the rest live only in the JSONB bag (unlimited, no migration).
BUILTIN_METRICS: Dict[str, Dict[str, Any]] = {
    "weight":     {"bag_key": "weight_kg",    "label": "Weight",     "short": "KG",   "canonical_unit": "kg",    "input": "number",   "first_class": True},
    "reps":       {"bag_key": "reps",         "label": "Reps",       "short": "REPS", "canonical_unit": "count", "input": "integer",  "first_class": True},
    "distance":   {"bag_key": "distance_m",   "label": "Distance",   "short": "DIST", "canonical_unit": "m",     "input": "number",   "first_class": True},
    "time":       {"bag_key": "time_s",       "label": "Time",       "short": "TIME", "canonical_unit": "s",     "input": "duration", "first_class": True},
    "box_height": {"bag_key": "box_height_cm","label": "Box Height", "short": "HT",   "canonical_unit": "cm",    "input": "number",   "first_class": False},
    "calories":   {"bag_key": "calories",     "label": "Calories",   "short": "CAL",  "canonical_unit": "kcal",  "input": "number",   "first_class": False},
    "incline":    {"bag_key": "incline_pct",  "label": "Incline",    "short": "INC",  "canonical_unit": "pct",   "input": "number",   "first_class": False},
    "speed":      {"bag_key": "speed_kmh",    "label": "Speed",      "short": "SPD",  "canonical_unit": "kmh",   "input": "number",   "first_class": False},
    "rpm":        {"bag_key": "rpm",          "label": "RPM",        "short": "RPM",  "canonical_unit": "rpm",   "input": "integer",  "first_class": False},
    "height":     {"bag_key": "height_cm",    "label": "Height",     "short": "HT",   "canonical_unit": "cm",    "input": "number",   "first_class": False},
}

# Convenience: metric key -> bag_key (e.g. 'distance' -> 'distance_m').
KEY_TO_BAG: Dict[str, str] = {k: v["bag_key"] for k, v in BUILTIN_METRICS.items()}


def build_metrics_bag(log: Any) -> Dict[str, Any]:
    """Return the complete canonical metrics bag for a PerformanceLogCreate.

    Merges any client-sent ``metrics`` with the first-class typed fields so the
    stored bag is always a complete superset (never loses a value, and drives
    the eventual read-migration off the typed columns). Client values win.
    """
    bag: Dict[str, Any] = dict(getattr(log, "metrics", None) or {})
    bag.setdefault("weight_kg", getattr(log, "weight_kg", None))
    bag.setdefault("reps", getattr(log, "reps_completed", None))
    if getattr(log, "distance_meters", None) is not None:
        bag.setdefault("distance_m", log.distance_meters)
    if getattr(log, "set_duration_seconds", None) is not None:
        bag.setdefault("time_s", log.set_duration_seconds)
    # Drop keys whose value is None so the bag stays clean.
    return {k: v for k, v in bag.items() if v is not None}


def mirror_first_class_to_columns(bag: Optional[Dict[str, Any]], log_data: Dict[str, Any]) -> None:
    """Backfill a typed column from the bag when only the bag carries it.

    Defensive: today's client sends both the typed fields AND the bag, so this
    is a no-op. It future-proofs a bag-only client without breaking the
    typed-column readers (PRs / strength / volume / history).
    """
    if not bag:
        return
    for bag_key, col in FIRST_CLASS_COLUMN.items():
        val = bag.get(bag_key)
        if val is not None and log_data.get(col) is None:
            log_data[col] = val
