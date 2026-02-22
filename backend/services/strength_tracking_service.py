"""
Strength Tracking Service - 1RM tracking and PR detection.

Handles:
- Recording strength performances
- Detecting personal records
- Calculating estimated 1RM

Now uses Supabase for persistence instead of in-memory dict.
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from models.performance import StrengthRecord
from core.supabase_client import get_supabase
from core.logger import get_logger

logger = get_logger(__name__)


class StrengthTrackingService:
    """Tracks strength records and detects PRs using Supabase persistence."""

    def __init__(self):
        # In-memory cache for hot-path reads (TTL managed externally)
        self._cache: Dict[str, List[StrengthRecord]] = {}

    def record_strength(
        self,
        exercise_id: str,
        exercise_name: str,
        user_id: int,
        weight: float,
        reps: int,
        rpe: Optional[float] = None,
    ) -> Tuple[StrengthRecord, bool]:
        """
        Record a strength performance and check for PR.

        Returns:
            Tuple of (record, is_pr)
        """
        estimated_1rm = StrengthRecord.calculate_1rm(weight, reps)

        record = StrengthRecord(
            exercise_id=exercise_id,
            exercise_name=exercise_name,
            user_id=user_id,
            date=datetime.now(),
            weight_kg=weight,
            reps=reps,
            estimated_1rm=estimated_1rm,
            rpe=rpe,
        )

        # Check if this is a PR
        history = self.get_exercise_history(exercise_id, user_id)
        is_pr = all(past.estimated_1rm < estimated_1rm for past in history)
        record.is_pr = is_pr

        # Persist to Supabase
        try:
            supabase = get_supabase()
            supabase.table("strength_records").upsert({
                "exercise_id": exercise_id,
                "exercise_name": exercise_name,
                "user_id": str(user_id),
                "weight_kg": weight,
                "reps": reps,
                "estimated_1rm": estimated_1rm,
                "rpe": rpe,
                "is_pr": is_pr,
                "recorded_at": datetime.now().isoformat(),
            }).execute()
        except Exception as e:
            logger.warning(f"Failed to persist strength record to Supabase: {e}")

        # Update local cache
        key = f"{user_id}:{exercise_id}"
        if key not in self._cache:
            self._cache[key] = []
        self._cache[key].append(record)

        return record, is_pr

    def get_exercise_history(
        self,
        exercise_id: str,
        user_id: int,
        limit: int = 10,
    ) -> List[StrengthRecord]:
        """Get strength history for an exercise."""
        key = f"{user_id}:{exercise_id}"

        # Check cache first
        if key in self._cache:
            history = self._cache[key]
            return sorted(history, key=lambda r: r.date, reverse=True)[:limit]

        # Load from Supabase
        try:
            supabase = get_supabase()
            response = supabase.table("strength_records").select("*").eq(
                "user_id", str(user_id)
            ).eq(
                "exercise_id", exercise_id
            ).order(
                "recorded_at", desc=True
            ).limit(limit).execute()

            records = []
            for row in (response.data or []):
                records.append(StrengthRecord(
                    exercise_id=row["exercise_id"],
                    exercise_name=row.get("exercise_name", ""),
                    user_id=int(row["user_id"]),
                    date=datetime.fromisoformat(row["recorded_at"]),
                    weight_kg=float(row["weight_kg"]),
                    reps=int(row["reps"]),
                    estimated_1rm=float(row["estimated_1rm"]),
                    rpe=float(row["rpe"]) if row.get("rpe") else None,
                    is_pr=row.get("is_pr", False),
                ))

            # Populate cache
            self._cache[key] = records
            return records

        except Exception as e:
            logger.warning(f"Failed to load strength history from Supabase: {e}")
            return self._cache.get(key, [])[:limit]

    def get_current_1rm(
        self,
        exercise_id: str,
        user_id: int,
    ) -> Optional[float]:
        """Get the best estimated 1RM for an exercise."""
        history = self.get_exercise_history(exercise_id, user_id)
        if not history:
            return None
        return max(r.estimated_1rm for r in history)

    def get_all_prs(
        self,
        user_id: int,
        limit: int = 10,
    ) -> List[StrengthRecord]:
        """Get all PRs for a user."""
        try:
            supabase = get_supabase()
            response = supabase.table("strength_records").select("*").eq(
                "user_id", str(user_id)
            ).eq(
                "is_pr", True
            ).order(
                "recorded_at", desc=True
            ).limit(limit).execute()

            records = []
            for row in (response.data or []):
                records.append(StrengthRecord(
                    exercise_id=row["exercise_id"],
                    exercise_name=row.get("exercise_name", ""),
                    user_id=int(row["user_id"]),
                    date=datetime.fromisoformat(row["recorded_at"]),
                    weight_kg=float(row["weight_kg"]),
                    reps=int(row["reps"]),
                    estimated_1rm=float(row["estimated_1rm"]),
                    rpe=float(row["rpe"]) if row.get("rpe") else None,
                    is_pr=True,
                ))
            return records

        except Exception as e:
            logger.warning(f"Failed to load PRs from Supabase: {e}")
            # Fallback to cache
            prs = []
            for key, records in self._cache.items():
                if key.startswith(f"{user_id}:"):
                    pr_records = [r for r in records if r.is_pr]
                    prs.extend(pr_records)
            return sorted(prs, key=lambda r: r.date, reverse=True)[:limit]
