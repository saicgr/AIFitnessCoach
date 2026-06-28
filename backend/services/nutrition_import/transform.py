"""Pure transforms for the importer (no DB) — groupable + unit-testable on any
Python. DB I/O lives in bulk.py, which re-uses these.
"""
from __future__ import annotations

import hashlib
from collections import OrderedDict
from typing import Iterable

from .normalize import local_noon_iso
from .parsers import NormalizedFoodRow

MICRO_COLUMNS = (
    "sugar_g", "sodium_mg", "saturated_fat_g", "cholesterol_mg",
    "potassium_mg", "calcium_mg", "iron_mg",
)


def make_key(*parts) -> str:
    return hashlib.sha256("|".join(str(p) for p in parts).encode()).hexdigest()[:48]


def group_food_logs(user_id: str, source: str, rows: Iterable[NormalizedFoodRow]) -> list:
    """Group normalized rows by (date, meal) into one food_log dict each with a
    food_items[] array. Deterministic idempotency_key = sha256(user|source|date|meal)
    so re-importing the same export is a no-op."""
    groups: "OrderedDict[tuple, dict]" = OrderedDict()
    for r in rows:
        gk = (r.date, r.meal)
        g = groups.get(gk)
        if g is None:
            g = {"items": [], "cal": 0.0, "p": 0.0, "c": 0.0, "f": 0.0, "fib": 0.0,
                 "micros": {m: 0.0 for m in MICRO_COLUMNS}}
            groups[gk] = g
        g["items"].append({
            "name": r.name,
            "calories": int(round(r.calories or 0)),
            "protein_g": round(r.protein_g or 0, 1),
            "carbs_g": round(r.carbs_g or 0, 1),
            "fat_g": round(r.fat_g or 0, 1),
            "fiber_g": round(r.fiber_g or 0, 1),
        })
        g["cal"] += r.calories or 0
        g["p"] += r.protein_g or 0
        g["c"] += r.carbs_g or 0
        g["f"] += r.fat_g or 0
        g["fib"] += r.fiber_g or 0
        for m in MICRO_COLUMNS:
            if r.micros.get(m) is not None:
                g["micros"][m] += r.micros[m]

    logs = []
    for (d, meal), g in groups.items():
        rec = {
            "user_id": user_id,
            "meal_type": meal,
            "logged_at": local_noon_iso(d),
            "food_items": g["items"],
            "total_calories": int(round(g["cal"])),
            "protein_g": round(g["p"], 2),
            "carbs_g": round(g["c"], 2),
            "fat_g": round(g["f"], 2),
            "fiber_g": round(g["fib"], 2),
            "source_type": "import",
            "input_type": source,
            "idempotency_key": make_key(user_id, source, d.isoformat(), meal),
            "_date": d.isoformat(),
        }
        for m in MICRO_COLUMNS:
            if g["micros"][m] > 0:
                rec[m] = round(g["micros"][m], 2)
        logs.append(rec)
    return logs
