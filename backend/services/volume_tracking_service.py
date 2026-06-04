"""
Volume Tracking Service - Weekly muscle group volume tracking.

Handles:
- Calculating weekly volume per muscle group
- Determining recovery status
- Identifying undertrained/overtrained muscles
- Computing per-muscle "freshness priority" used by the Exercise RAG soft
  bias (B7) so selected exercises naturally refresh stale strength scores.
"""
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from models.performance import WorkoutPerformance, MuscleGroupVolume
from core import get_muscle_groups, get_target_sets, get_recovery_status


class VolumeTrackingService:
    """Tracks weekly volume per muscle group."""

    def calculate_weekly_volume(
        self,
        workouts: List[WorkoutPerformance],
    ) -> List[MuscleGroupVolume]:
        """Calculate weekly volume per muscle group."""
        muscle_volumes: Dict[str, Dict] = {}

        for workout in workouts:
            for exercise in workout.exercises:
                muscles = get_muscle_groups(exercise.exercise_name)

                for muscle in muscles:
                    if muscle not in muscle_volumes:
                        muscle_volumes[muscle] = {
                            "total_sets": 0,
                            "total_reps": 0,
                            "total_volume_kg": 0,
                            "days_trained": set(),
                        }

                    muscle_volumes[muscle]["total_sets"] += len(exercise.sets)
                    muscle_volumes[muscle]["total_reps"] += exercise.total_reps
                    muscle_volumes[muscle]["total_volume_kg"] += exercise.total_volume
                    muscle_volumes[muscle]["days_trained"].add(
                        workout.scheduled_date.date()
                    )

        # Convert to MuscleGroupVolume objects
        result = []
        for muscle, data in muscle_volumes.items():
            recovery_status = get_recovery_status(muscle, data["total_sets"])

            result.append(MuscleGroupVolume(
                muscle_group=muscle,
                total_sets=data["total_sets"],
                total_reps=data["total_reps"],
                total_volume_kg=data["total_volume_kg"],
                frequency=len(data["days_trained"]),
                target_sets=get_target_sets(muscle),
                recovery_status=recovery_status,
            ))

        return result

    def get_undertrained_muscles(
        self,
        volumes: List[MuscleGroupVolume],
    ) -> List[MuscleGroupVolume]:
        """Get muscles that need more volume."""
        return [v for v in volumes if v.recovery_status == "undertrained"]

    def get_overtrained_muscles(
        self,
        volumes: List[MuscleGroupVolume],
    ) -> List[MuscleGroupVolume]:
        """Get muscles that are overtrained."""
        return [v for v in volumes if v.recovery_status == "overtrained"]

    # -------------------------------------------------------------------------
    # B7 — Score-freshness priority (soft RAG bias input)
    # -------------------------------------------------------------------------

    @staticmethod
    def compute_muscle_freshness_priority(
        strength_score_rows: List[Dict[str, Any]],
        *,
        stale_days: int = 10,
        now: Optional[datetime] = None,
        excluded_muscles: Optional[List[str]] = None,
    ) -> Dict[str, float]:
        """Return a {muscle_group: priority_weight} map biasing exercise
        selection toward muscles whose strength score is STALE (>stale_days) or
        UNDERTRAINED (low weekly sets relative to target).

        Pure/deterministic — no LLM, no network. Reads only the latest
        strength_scores rows already fetched by the caller.

        Priority weight semantics (1.0 = neutral):
          - 1.0  neutral / fresh & adequately trained
          - up to ~1.6 for very stale muscles (older = higher)
          - +0.15 extra when weekly_sets fall below the muscle's set target

        Excluded muscles (preferences.excluded_muscles) get 0.0 so the RAG
        layer can hard-skip them — the user opted out of training them.
        """
        ref = now or datetime.now(timezone.utc)
        excluded = {(m or "").strip().lower() for m in (excluded_muscles or [])}
        out: Dict[str, float] = {}
        seen: set = set()
        for row in strength_score_rows or []:
            mg = (row.get("muscle_group") or "").strip().lower()
            if not mg or mg in seen:
                continue
            seen.add(mg)
            if mg in excluded:
                out[mg] = 0.0
                continue

            weight = 1.0

            # ── Staleness component ──
            calc = row.get("calculated_at")
            days_since = None
            if calc:
                try:
                    dt = (
                        calc if isinstance(calc, datetime)
                        else datetime.fromisoformat(str(calc).replace("Z", "+00:00"))
                    )
                    if dt.tzinfo is None:
                        dt = dt.replace(tzinfo=timezone.utc)
                    days_since = (ref - dt).days
                except (ValueError, TypeError):
                    days_since = None
            if days_since is None or days_since >= stale_days:
                # Scale 1.0 → ~1.6 between stale_days and 4× stale_days.
                if days_since is None:
                    weight = 1.6
                else:
                    over = days_since - stale_days
                    weight = 1.0 + min(0.6, 0.6 * (over / (3.0 * stale_days)) + 0.2)

            # ── Undertrained component ──
            try:
                weekly_sets = int(row.get("weekly_sets") or 0)
            except (ValueError, TypeError):
                weekly_sets = 0
            target = get_target_sets(mg)
            if target > 0 and weekly_sets < target * 0.8:
                weight += 0.15

            out[mg] = round(weight, 3)

        return out
