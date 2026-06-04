"""
Personal Records Service - PR detection, tracking, and celebration.

Handles:
- Detecting new personal records from workout logs
- Tracking PR history per exercise
- Calculating improvement metrics
- Generating celebration messages
"""
from typing import Dict, List, Optional, Tuple
from datetime import datetime, date, timedelta, timezone
from dataclasses import dataclass, field
from decimal import Decimal
import logging

from services.strength_calculator_service import StrengthCalculatorService
from services.equipment_scope import default_scope, SCOPE_PER_GYM

logger = logging.getLogger(__name__)


@dataclass
class PersonalRecord:
    """A personal record achievement."""
    exercise_name: str
    exercise_id: Optional[str]
    muscle_group: Optional[str]
    weight_kg: float
    reps: int
    estimated_1rm_kg: float
    set_type: str  # 'working', 'amrap', 'failure'
    rpe: Optional[float]
    achieved_at: datetime
    workout_id: Optional[str]
    previous_weight_kg: Optional[float]
    previous_1rm_kg: Optional[float]
    improvement_kg: Optional[float]
    improvement_percent: Optional[float]
    is_all_time_pr: bool
    celebration_message: Optional[str]
    # Per-gym progress (Gravl B-series). For machine/cable exercises a PR is
    # scoped to the gym it was set at, so a home cable can PR even when a gym
    # machine's incomparable record is higher. These tag the celebration.
    gym_profile_id: Optional[str] = None
    is_gym_pr: bool = False          # beats this gym's prior best (per-gym PR)
    is_first_at_gym: bool = False    # first-ever logged set at this gym


@dataclass
class PRComparison:
    """Comparison between current lift and existing PR."""
    is_pr: bool
    is_all_time_pr: bool
    current_1rm: float
    previous_1rm: Optional[float]
    improvement_kg: Optional[float]
    improvement_percent: Optional[float]
    time_since_last_pr: Optional[int]  # days
    # Per-gym fields (populated when a gym_profile_id is in play).
    is_gym_pr: bool = False
    is_first_at_gym: bool = False


class PersonalRecordsService:
    """
    Manages personal record detection and tracking.

    PRs are detected by comparing estimated 1RM values, not just
    weight lifted. This allows PRs across different rep ranges
    to be fairly compared.
    """

    def __init__(self):
        self.strength_calculator = StrengthCalculatorService()

    # -------------------------------------------------------------------------
    # PR Detection
    # -------------------------------------------------------------------------

    def check_for_pr(
        self,
        exercise_name: str,
        weight_kg: float,
        reps: int,
        existing_prs: List[Dict],
        rpe: Optional[float] = None,
        gym_profile_id: Optional[str] = None,
    ) -> PRComparison:
        """
        Check if a lift is a new personal record.

        Compares estimated 1RM to find PRs across all rep ranges.

        Per-gym semantics: when `gym_profile_id` is supplied, the "PR to beat"
        comparison that drives `is_gym_pr` is scoped to existing PRs from that
        SAME gym (so an incomparable other-gym machine record can't block a
        legit per-gym PR). The all-time cross-gym best is STILL computed and
        exposed as `is_all_time_pr`/`previous_1rm`. `is_pr` becomes true when the
        lift beats EITHER the gym best (per-gym) OR the all-time best, so a first
        set at a new gym registers as a PR ("first at this gym").

        Args:
            exercise_name: Name of the exercise
            weight_kg: Weight lifted
            reps: Number of reps completed
            existing_prs: List of existing PRs for this exercise (may span gyms;
                each row may carry `gym_profile_id`).
            rpe: Optional RPE rating
            gym_profile_id: When set, scope the per-gym PR comparison to this gym.

        Returns:
            PRComparison with PR status and details
        """
        # Calculate current estimated 1RM
        current_1rm = self.strength_calculator.calculate_1rm_average(weight_kg, reps)

        # ── All-time (cross-gym) best — unchanged semantics ──────────────────
        if not existing_prs:
            best_all_1rm = 0.0
            last_pr_date = None
        else:
            # `.get(k, 0)` returns the default only when the key is MISSING —
            # not when the value is explicitly NULL — so coalesce with `or 0`.
            best_all = max(existing_prs, key=lambda x: float(x.get("estimated_1rm_kg") or 0))
            best_all_1rm = float(best_all.get("estimated_1rm_kg") or 0)
            last_pr_date = best_all.get("achieved_at")

        is_all_time_pr = current_1rm > best_all_1rm

        # ── Per-gym best (only meaningful when a gym is in play) ──────────────
        is_gym_pr = False
        is_first_at_gym = False
        if gym_profile_id is not None:
            same_gym_prs = [
                p for p in existing_prs
                if p.get("gym_profile_id") == gym_profile_id
            ]
            if not same_gym_prs:
                # No prior record at THIS gym → first time here. Always a
                # per-gym PR (there's nothing to beat).
                is_gym_pr = True
                is_first_at_gym = True
                best_gym_1rm = 0.0
            else:
                best_gym = max(
                    same_gym_prs, key=lambda x: float(x.get("estimated_1rm_kg") or 0))
                best_gym_1rm = float(best_gym.get("estimated_1rm_kg") or 0)
                is_gym_pr = current_1rm > best_gym_1rm
            # For per-gym exercises the "PR to beat" baseline shown to the user
            # is the SAME gym's best, not the all-time (incomparable) record.
            comparison_baseline = best_gym_1rm
        else:
            comparison_baseline = best_all_1rm

        # `is_pr` fires on either an all-time PR or a per-gym PR so a fresh gym
        # never crushes a legit first-at-this-gym record.
        is_pr = is_all_time_pr or is_gym_pr

        # ── Improvement metrics (relative to the relevant baseline) ──────────
        improvement_kg = None
        improvement_percent = None
        time_since_last_pr = None

        if is_pr and comparison_baseline > 0:
            improvement_kg = round(current_1rm - comparison_baseline, 2)
            improvement_percent = round((improvement_kg / comparison_baseline) * 100, 2)

        if is_pr and last_pr_date:
            # _parse_date always returns an aware UTC datetime, so subtracting
            # from `datetime.now(timezone.utc)` is safe whether the stored value
            # was naive, ISO-Z, or datetime.
            parsed = self._parse_date(last_pr_date)
            time_since_last_pr = (datetime.now(timezone.utc) - parsed).days

        return PRComparison(
            is_pr=is_pr,
            is_all_time_pr=is_all_time_pr,
            current_1rm=round(current_1rm, 2),
            previous_1rm=round(comparison_baseline, 2) if comparison_baseline else None,
            improvement_kg=improvement_kg,
            improvement_percent=improvement_percent,
            time_since_last_pr=time_since_last_pr,
            is_gym_pr=is_gym_pr,
            is_first_at_gym=is_first_at_gym,
        )

    def detect_prs_in_workout(
        self,
        workout_exercises: List[Dict],
        existing_prs_by_exercise: Dict[str, List[Dict]],
        gym_profile_id: Optional[str] = None,
    ) -> List[PersonalRecord]:
        """
        Detect all PRs in a workout.

        Args:
            workout_exercises: List of exercises with sets/reps/weights. Each
                exercise may carry an optional `equipment` string used to decide
                whether PRs are scoped per-gym.
            existing_prs_by_exercise: Dict mapping exercise name to existing PRs
                (each PR row may carry `gym_profile_id`).
            gym_profile_id: The gym the workout was performed at (server-derived
                from the workout, per the source-of-truth rule). When set, PR
                detection for machine/cable exercises is scoped to this gym while
                still tracking the all-time cross-gym best.

        Returns:
            List of new PersonalRecord objects
        """
        new_prs = []

        for exercise in workout_exercises:
            exercise_name = exercise.get("exercise_name", "")
            sets = exercise.get("sets", [])

            # Handle case where sets is an integer count instead of a list
            if isinstance(sets, int):
                # Skip if sets is just a count, not actual set data
                continue

            if not sets:
                continue

            # Decide whether THIS exercise scopes PRs per gym. Free weights /
            # bodyweight stay global (gym arg ignored); machine/cable scope to
            # the workout's gym. Equipment may be absent → name-hint fallback.
            equipment = exercise.get("equipment")
            is_per_gym = (
                gym_profile_id is not None
                and default_scope(equipment, exercise_name) == SCOPE_PER_GYM
            )
            effective_gym_id = gym_profile_id if is_per_gym else None

            # Get existing PRs for this exercise
            existing_prs = existing_prs_by_exercise.get(
                self._normalize_exercise_name(exercise_name), []
            )

            # Check each set for PR
            for set_data in sets:
                if not set_data.get("completed", True):
                    continue

                weight_kg = float(set_data.get("weight_kg", 0))
                reps = int(set_data.get("reps", 0) or set_data.get("reps_completed", 0))

                if weight_kg <= 0 or reps <= 0:
                    continue

                comparison = self.check_for_pr(
                    exercise_name=exercise_name,
                    weight_kg=weight_kg,
                    reps=reps,
                    existing_prs=existing_prs,
                    rpe=set_data.get("rpe"),
                    gym_profile_id=effective_gym_id,
                )

                if comparison.is_pr:
                    # Get muscle group
                    muscle_groups = self.strength_calculator.get_exercise_muscle_groups(exercise_name)
                    muscle_group = muscle_groups[0] if muscle_groups else None

                    # Generate celebration message (gym-aware first-at-gym copy).
                    celebration = self._generate_celebration_message(
                        exercise_name=exercise_name,
                        improvement_kg=comparison.improvement_kg,
                        improvement_percent=comparison.improvement_percent,
                        is_all_time=comparison.is_all_time_pr,
                        is_first_at_gym=comparison.is_first_at_gym,
                    )

                    pr = PersonalRecord(
                        exercise_name=exercise_name,
                        exercise_id=exercise.get("exercise_id"),
                        muscle_group=muscle_group,
                        weight_kg=weight_kg,
                        reps=reps,
                        estimated_1rm_kg=comparison.current_1rm,
                        set_type=set_data.get("set_type", "working"),
                        rpe=set_data.get("rpe"),
                        achieved_at=datetime.now(),
                        workout_id=exercise.get("workout_id"),
                        previous_weight_kg=set_data.get("previous_weight_kg"),
                        previous_1rm_kg=comparison.previous_1rm,
                        improvement_kg=comparison.improvement_kg,
                        improvement_percent=comparison.improvement_percent,
                        is_all_time_pr=comparison.is_all_time_pr,
                        celebration_message=celebration,
                        gym_profile_id=effective_gym_id,
                        is_gym_pr=comparison.is_gym_pr,
                        is_first_at_gym=comparison.is_first_at_gym,
                    )
                    new_prs.append(pr)

                    # Update existing PRs for subsequent set comparisons (carry
                    # the gym so later sets compare against the right baseline).
                    existing_prs.append({
                        "estimated_1rm_kg": comparison.current_1rm,
                        "achieved_at": datetime.now(),
                        "gym_profile_id": effective_gym_id,
                    })

        return new_prs

    # -------------------------------------------------------------------------
    # PR Statistics
    # -------------------------------------------------------------------------

    def get_pr_statistics(
        self,
        all_prs: List[Dict],
        period_days: int = 30,
    ) -> Dict:
        """
        Calculate PR statistics for a user.

        Args:
            all_prs: All personal records for the user
            period_days: Period for recent PRs calculation

        Returns:
            Dict with PR statistics
        """
        if not all_prs:
            return {
                "total_prs": 0,
                "prs_this_period": 0,
                "exercises_with_prs": 0,
                "best_improvement_percent": None,
                "most_improved_exercise": None,
                "longest_pr_streak": 0,
                "current_pr_streak": 0,
            }

        now = datetime.now(timezone.utc)
        period_start = now - timedelta(days=period_days)

        # Count PRs in period
        prs_this_period = sum(
            1 for pr in all_prs
            if self._parse_date(pr.get("achieved_at")) > period_start
        )

        # Unique exercises
        exercises_with_prs = len(set(pr.get("exercise_name") for pr in all_prs))

        # Best improvement
        improvements = [
            (pr.get("exercise_name"), pr.get("improvement_percent"))
            for pr in all_prs
            if pr.get("improvement_percent")
        ]
        if improvements:
            best = max(improvements, key=lambda x: x[1])
            best_improvement_percent = best[1]
            most_improved_exercise = best[0]
        else:
            best_improvement_percent = None
            most_improved_exercise = None

        # PR streak calculation (consecutive workout days with at least 1 PR)
        dates_with_prs = sorted(set(
            self._parse_date(pr.get("achieved_at")).date()
            for pr in all_prs
            if pr.get("achieved_at")
        ))

        longest_streak = 0
        current_streak = 0

        if dates_with_prs:
            streak = 1
            for i in range(1, len(dates_with_prs)):
                if (dates_with_prs[i] - dates_with_prs[i-1]).days <= 3:  # Allow gaps for rest days
                    streak += 1
                else:
                    longest_streak = max(longest_streak, streak)
                    streak = 1
            longest_streak = max(longest_streak, streak)

            # Current streak
            if dates_with_prs[-1] >= (now.date() - timedelta(days=3)):
                current_streak = 1
                for i in range(len(dates_with_prs) - 2, -1, -1):
                    if (dates_with_prs[i+1] - dates_with_prs[i]).days <= 3:
                        current_streak += 1
                    else:
                        break

        return {
            "total_prs": len(all_prs),
            "prs_this_period": prs_this_period,
            "exercises_with_prs": exercises_with_prs,
            "best_improvement_percent": best_improvement_percent,
            "most_improved_exercise": most_improved_exercise,
            "longest_pr_streak": longest_streak,
            "current_pr_streak": current_streak,
        }

    def get_exercise_pr_history(
        self,
        exercise_name: str,
        all_prs: List[Dict],
    ) -> Dict:
        """
        Get PR history for a specific exercise.

        Args:
            exercise_name: Name of the exercise
            all_prs: All PRs for the user

        Returns:
            Dict with exercise PR history
        """
        normalized = self._normalize_exercise_name(exercise_name)
        exercise_prs = [
            pr for pr in all_prs
            if self._normalize_exercise_name(pr.get("exercise_name", "")) == normalized
        ]

        if not exercise_prs:
            return {
                "exercise_name": exercise_name,
                "total_prs": 0,
                "current_pr": None,
                "first_pr": None,
                "total_improvement_kg": None,
                "total_improvement_percent": None,
                "pr_timeline": [],
            }

        # Sort by date
        sorted_prs = sorted(
            exercise_prs,
            key=lambda x: self._parse_date(x.get("achieved_at"))
        )

        first_pr = sorted_prs[0]
        current_pr = sorted_prs[-1]

        # Calculate total improvement
        first_1rm = float(first_pr.get("estimated_1rm_kg") or 0)
        current_1rm = float(current_pr.get("estimated_1rm_kg") or 0)

        total_improvement_kg = round(current_1rm - first_1rm, 2) if first_1rm > 0 else None
        total_improvement_percent = round(
            (total_improvement_kg / first_1rm) * 100, 2
        ) if first_1rm > 0 and total_improvement_kg else None

        # PR timeline
        pr_timeline = [
            {
                "date": self._parse_date(pr.get("achieved_at")).isoformat(),
                "estimated_1rm_kg": float(pr.get("estimated_1rm_kg") or 0),
                "weight_kg": float(pr.get("weight_kg") or 0),
                "reps": int(pr.get("reps") or 0),
            }
            for pr in sorted_prs
        ]

        return {
            "exercise_name": exercise_name,
            "total_prs": len(exercise_prs),
            "current_pr": {
                "weight_kg": float(current_pr.get("weight_kg") or 0),
                "reps": int(current_pr.get("reps") or 0),
                "estimated_1rm_kg": current_1rm,
                "achieved_at": self._parse_date(current_pr.get("achieved_at")).isoformat(),
            },
            "first_pr": {
                "weight_kg": float(first_pr.get("weight_kg") or 0),
                "reps": int(first_pr.get("reps") or 0),
                "estimated_1rm_kg": first_1rm,
                "achieved_at": self._parse_date(first_pr.get("achieved_at")).isoformat(),
            },
            "total_improvement_kg": total_improvement_kg,
            "total_improvement_percent": total_improvement_percent,
            "pr_timeline": pr_timeline,
        }

    # -------------------------------------------------------------------------
    # Celebration Messages
    # -------------------------------------------------------------------------

    def _generate_celebration_message(
        self,
        exercise_name: str,
        improvement_kg: Optional[float],
        improvement_percent: Optional[float],
        is_all_time: bool,
        is_first_at_gym: bool = False,
    ) -> str:
        """
        Generate a celebration message for a new PR.

        Args:
            exercise_name: Name of the exercise
            improvement_kg: Improvement in kg
            improvement_percent: Improvement percentage
            is_all_time: Whether this is an all-time PR
            is_first_at_gym: Whether this is the first logged set at this gym
                (machine/cable per-gym PR with no prior gym history)

        Returns:
            Celebration message string
        """
        display_name = exercise_name.replace("_", " ").title()

        # First-ever set at this gym for a per-gym exercise — frame it as a
        # baseline, not a regression, even if another gym's record is higher.
        if is_first_at_gym:
            import random
            first_at_gym = [
                f"First time logging {display_name} here — baseline set!",
                f"New gym, fresh start! {display_name} logged for this gym.",
                f"Tracking {display_name} at this gym now — let's build it up!",
            ]
            return random.choice(first_at_gym)

        # Basic celebrations
        base_celebrations = [
            "New PR! ",
            "Personal best! ",
            "You crushed it! ",
            "Beast mode! ",
            "Stronger than ever! ",
        ]

        import random
        message = random.choice(base_celebrations)

        # Add exercise name
        message += f"{display_name}"

        # Add improvement details
        if improvement_kg and improvement_percent:
            if improvement_kg >= 5:
                message += f" - +{improvement_kg:.1f}kg ({improvement_percent:.1f}% stronger)!"
            else:
                message += f" - +{improvement_kg:.1f}kg improvement!"
        elif is_all_time:
            message += " - First PR recorded!"

        return message

    def generate_ai_celebration(
        self,
        pr: PersonalRecord,
        coach_style: str = "motivational",
    ) -> str:
        """
        Generate AI-enhanced celebration message.

        This is a placeholder - the actual AI service will provide more
        personalized messages based on coach persona and user history.

        Args:
            pr: The personal record
            coach_style: Coach communication style

        Returns:
            AI-generated celebration message
        """
        # Basic template - AI service will enhance
        if pr.improvement_percent and pr.improvement_percent > 10:
            return f"Incredible! You just set a new PR on {pr.exercise_name.replace('_', ' ').title()} with a {pr.improvement_percent:.1f}% improvement! Your hard work is paying off!"
        elif pr.is_all_time_pr:
            return f"New personal best on {pr.exercise_name.replace('_', ' ').title()}! {pr.weight_kg}kg x {pr.reps} reps. Keep pushing!"
        else:
            return pr.celebration_message or "PR achieved! Great work!"

    # -------------------------------------------------------------------------
    # Helper Methods
    # -------------------------------------------------------------------------

    @staticmethod
    def _normalize_exercise_name(name: str) -> str:
        """Normalize exercise name for matching."""
        if not name:
            return ""
        normalized = name.lower().strip()
        normalized = normalized.replace(" ", "_").replace("-", "_")
        return normalized

    @staticmethod
    def _parse_date(date_value) -> datetime:
        """Parse various date formats to an aware UTC datetime.

        Supabase returns timestamps as ISO strings with a trailing
        "Z" or "+00:00" — those are tz-aware once parsed. Naive
        inputs (plain date, naive datetime, bare date string) are
        attached to UTC so downstream arithmetic against
        ``datetime.now(timezone.utc)`` never throws
        "can't subtract offset-naive and offset-aware datetimes".
        """
        if isinstance(date_value, datetime):
            return date_value if date_value.tzinfo else date_value.replace(tzinfo=timezone.utc)
        if isinstance(date_value, date):
            return datetime.combine(date_value, datetime.min.time()).replace(tzinfo=timezone.utc)
        if isinstance(date_value, str):
            try:
                dt = datetime.fromisoformat(date_value.replace("Z", "+00:00"))
            except ValueError:
                return datetime.now(timezone.utc)
            return dt if dt.tzinfo else dt.replace(tzinfo=timezone.utc)
        return datetime.now(timezone.utc)


# Singleton instance
personal_records_service = PersonalRecordsService()
