"""
Strength Tracking Service - 1RM tracking and PR detection.

Handles:
- Recording strength performances
- Detecting personal records
- Calculating estimated 1RM
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime
from models.performance import StrengthRecord


class StrengthTrackingService:
    """Tracks strength records and detects PRs."""

    def __init__(self):
        self._strength_records: Dict[str, List[StrengthRecord]] = {}

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
        key = f"{user_id}:{exercise_id}"
        history = self._strength_records.get(key, [])

        is_pr = all(past.estimated_1rm < estimated_1rm for past in history)
        record.is_pr = is_pr

        # Store record
        if key not in self._strength_records:
            self._strength_records[key] = []
        self._strength_records[key].append(record)

        return record, is_pr

    def get_exercise_history(
        self,
        exercise_id: str,
        user_id: int,
        limit: int = 10,
    ) -> List[StrengthRecord]:
        """Get strength history for an exercise."""
        key = f"{user_id}:{exercise_id}"
        history = self._strength_records.get(key, [])
        return sorted(history, key=lambda r: r.date, reverse=True)[:limit]

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
        prs = []
        for key, records in self._strength_records.items():
            if key.startswith(f"{user_id}:"):
                pr_records = [r for r in records if r.is_pr]
                prs.extend(pr_records)

        return sorted(prs, key=lambda r: r.date, reverse=True)[:limit]
