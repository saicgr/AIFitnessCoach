"""
Strain Prevention Service - Monitors training volume and prevents overuse injuries.

Key features:
1. Track weekly volume per muscle group
2. Detect dangerous volume increases (>10% weekly increase is risky)
3. Alert users when approaching strain risk
4. Learn from user's strain history to personalize caps
5. Auto-adjust workout volume when risk is high

The 10% Rule: Research suggests that increasing training volume by more than 10%
per week significantly increases injury risk. This service enforces this principle.

Log prefixes used:
- 🛡️ = Prevention/safety action
- ⚠️ = Warning/risk detected
"""
from dataclasses import dataclass
from datetime import datetime, date, timedelta
from typing import Optional, List, Dict, Any
from decimal import Decimal
from core.logger import get_logger
from core.supabase_db import get_supabase_db

logger = get_logger(__name__)


# Default volume caps (can be personalized)
DEFAULT_WEEKLY_SET_CAPS = {
    "chest": 16,
    "back": 20,
    "shoulders": 16,
    "biceps": 14,
    "triceps": 14,
    "quadriceps": 16,
    "hamstrings": 14,
    "glutes": 16,
    "calves": 12,
    "core": 18,
    "forearms": 10,
}

# Risk thresholds based on the 10% rule
VOLUME_INCREASE_WARNING = 0.10  # 10% increase - warning
VOLUME_INCREASE_DANGER = 0.15  # 15% increase - danger
VOLUME_INCREASE_CRITICAL = 0.20  # 20%+ increase - critical risk


@dataclass
class StrainRiskAssessment:
    """Assessment of strain risk for a muscle group."""
    muscle_group: str
    current_volume: float
    previous_volume: float
    increase_percent: float
    risk_level: str  # 'safe', 'warning', 'danger', 'critical'
    recommendation: str
    should_reduce_volume: bool
    suggested_reduction_percent: float


@dataclass
class VolumeTrackingResult:
    """Result of tracking workout volume."""
    muscle_volumes: Dict[str, Dict[str, Any]]
    total_sets: int
    total_reps: int
    total_volume_kg: float


class StrainPreventionService:
    """
    Service for preventing overuse injuries through volume monitoring.

    Implements the 10% rule: Weekly training volume should not increase
    by more than 10% to minimize injury risk.
    """

    def __init__(self):
        self.db = get_supabase_db()

    def _get_week_start(self, target_date: date = None) -> date:
        """Get the Monday of the week containing target_date."""
        if target_date is None:
            target_date = date.today()
        # weekday() returns 0 for Monday, 6 for Sunday
        return target_date - timedelta(days=target_date.weekday())

    async def track_workout_volume(
        self,
        user_id: str,
        exercises: List[dict],
        workout_date: date = None
    ) -> VolumeTrackingResult:
        """
        Track volume from a completed workout.

        Args:
            user_id: User identifier
            exercises: List of exercise dicts with sets_completed, reps_completed,
                      weight_kg, and primary_muscle
            workout_date: Date of the workout (defaults to today)

        Returns:
            VolumeTrackingResult with muscle volumes tracked
        """
        if workout_date is None:
            workout_date = date.today()

        week_start = self._get_week_start(workout_date)

        muscle_volumes: Dict[str, Dict[str, Any]] = {}
        total_sets = 0
        total_reps = 0
        total_volume = 0.0

        for exercise in exercises:
            muscle = exercise.get('primary_muscle', 'unknown').lower()
            sets = exercise.get('sets_completed', 0) or 0
            reps = exercise.get('reps_completed', 0) or 0
            weight = exercise.get('weight_kg', 0) or 0

            volume = sets * reps * weight

            if muscle not in muscle_volumes:
                muscle_volumes[muscle] = {'sets': 0, 'reps': 0, 'volume': 0.0}

            muscle_volumes[muscle]['sets'] += sets
            muscle_volumes[muscle]['reps'] += reps
            muscle_volumes[muscle]['volume'] += volume

            total_sets += sets
            total_reps += reps
            total_volume += volume

        # Update database
        try:
            for muscle, data in muscle_volumes.items():
                # Use upsert pattern
                existing = self.db.client.table("weekly_volume_tracking").select("id").eq(
                    "user_id", user_id
                ).eq("week_start", week_start.isoformat()).eq(
                    "muscle_group", muscle
                ).execute()

                if existing.data:
                    # Update existing record
                    self.db.client.table("weekly_volume_tracking").update({
                        "total_sets": self.db.client.rpc(
                            "increment_sets",
                            {"row_id": existing.data[0]["id"], "amount": data['sets']}
                        ) if hasattr(self.db.client, 'rpc') else data['sets'],
                        "total_reps": existing.data[0].get("total_reps", 0) + data['reps'],
                        "total_volume_kg": float(existing.data[0].get("total_volume_kg", 0)) + data['volume'],
                        "updated_at": datetime.utcnow().isoformat()
                    }).eq("id", existing.data[0]["id"]).execute()
                else:
                    # Insert new record
                    self.db.client.table("weekly_volume_tracking").insert({
                        "user_id": user_id,
                        "week_start": week_start.isoformat(),
                        "muscle_group": muscle,
                        "total_sets": data['sets'],
                        "total_reps": data['reps'],
                        "total_volume_kg": data['volume']
                    }).execute()

            logger.info(f"🛡️ Tracked volume for {len(muscle_volumes)} muscle groups, user={user_id}")

        except Exception as e:
            logger.error(f"Failed to track workout volume: {e}")
            raise

        return VolumeTrackingResult(
            muscle_volumes=muscle_volumes,
            total_sets=total_sets,
            total_reps=total_reps,
            total_volume_kg=total_volume
        )

    async def assess_strain_risk(self, user_id: str) -> List[StrainRiskAssessment]:
        """
        Assess current strain risk for all muscle groups.

        Compares current week's volume to previous week to detect
        dangerous volume increases based on the 10% rule.

        Args:
            user_id: User identifier

        Returns:
            List of StrainRiskAssessment for each muscle group
        """
        today = date.today()
        current_week = self._get_week_start(today)
        previous_week = current_week - timedelta(days=7)

        assessments = []

        try:
            # Get current week volumes
            current_result = self.db.client.table("weekly_volume_tracking").select(
                "muscle_group, total_sets, total_volume_kg"
            ).eq("user_id", user_id).eq(
                "week_start", current_week.isoformat()
            ).execute()

            # Get previous week volumes
            previous_result = self.db.client.table("weekly_volume_tracking").select(
                "muscle_group, total_sets, total_volume_kg"
            ).eq("user_id", user_id).eq(
                "week_start", previous_week.isoformat()
            ).execute()

            prev_map = {r['muscle_group']: r for r in (previous_result.data or [])}

            for curr in (current_result.data or []):
                muscle = curr['muscle_group']
                curr_vol = float(curr.get('total_volume_kg', 0) or 0)
                prev_data = prev_map.get(muscle, {})
                prev_vol = float(prev_data.get('total_volume_kg', 0) or 0)

                # Calculate increase percentage
                if prev_vol > 0:
                    increase = (curr_vol - prev_vol) / prev_vol
                else:
                    increase = 0  # No previous data, so no increase to measure

                # Determine risk level
                risk_level = 'safe'
                recommendation = "Volume is within safe limits. Keep up the good work!"
                should_reduce = False
                reduction = 0.0

                if increase >= VOLUME_INCREASE_CRITICAL:
                    risk_level = 'critical'
                    recommendation = (
                        f"DANGER: {muscle.capitalize()} volume increased {increase*100:.0f}%. "
                        f"Reduce volume immediately to prevent strain injury. "
                        f"Consider taking a deload week."
                    )
                    should_reduce = True
                    reduction = 30.0
                    logger.warning(
                        f"⚠️ Critical strain risk for {muscle}: {increase*100:.1f}% increase, user={user_id}"
                    )
                elif increase >= VOLUME_INCREASE_DANGER:
                    risk_level = 'danger'
                    recommendation = (
                        f"Warning: {muscle.capitalize()} volume increased {increase*100:.0f}%. "
                        f"Consider reducing sets this week to prevent overuse."
                    )
                    should_reduce = True
                    reduction = 20.0
                    logger.warning(
                        f"⚠️ Danger strain risk for {muscle}: {increase*100:.1f}% increase, user={user_id}"
                    )
                elif increase >= VOLUME_INCREASE_WARNING:
                    risk_level = 'warning'
                    recommendation = (
                        f"Caution: {muscle.capitalize()} volume increased {increase*100:.0f}%. "
                        f"Monitor for fatigue and soreness."
                    )
                    should_reduce = False
                    reduction = 0.0

                assessments.append(StrainRiskAssessment(
                    muscle_group=muscle,
                    current_volume=curr_vol,
                    previous_volume=prev_vol,
                    increase_percent=increase * 100,
                    risk_level=risk_level,
                    recommendation=recommendation,
                    should_reduce_volume=should_reduce,
                    suggested_reduction_percent=reduction
                ))

            # Create alerts for danger/critical risks
            await self._create_volume_alerts(user_id, assessments)

        except Exception as e:
            logger.error(f"Failed to assess strain risk: {e}")
            raise

        return assessments

    async def _create_volume_alerts(
        self,
        user_id: str,
        assessments: List[StrainRiskAssessment]
    ) -> None:
        """Create alerts in database for danger/critical risk levels."""
        try:
            for assessment in assessments:
                if assessment.risk_level in ('danger', 'critical'):
                    self.db.client.table("volume_increase_alerts").insert({
                        "user_id": user_id,
                        "muscle_group": assessment.muscle_group,
                        "previous_week_volume": assessment.previous_volume,
                        "current_week_volume": assessment.current_volume,
                        "increase_percentage": assessment.increase_percent,
                        "alert_level": assessment.risk_level,
                        "recommendation": assessment.recommendation,
                    }).execute()

                    logger.info(
                        f"🛡️ Created {assessment.risk_level} alert for {assessment.muscle_group}, "
                        f"user={user_id}"
                    )
        except Exception as e:
            logger.warning(f"Failed to create volume alerts: {e}")

    async def record_strain(
        self,
        user_id: str,
        body_part: str,
        severity: str,
        activity_type: str = None,
        notes: str = None
    ) -> dict:
        """
        Record a strain incident for learning.

        When a user reports a strain, this method:
        1. Records the strain history
        2. Captures volume at time of strain
        3. Auto-adjusts volume caps for that muscle group

        Args:
            user_id: User identifier
            body_part: Body part that was strained
            severity: 'mild', 'moderate', or 'severe'
            activity_type: 'strength', 'cardio', or 'both'
            notes: Optional notes about the strain

        Returns:
            Dict with recording status and any cap adjustments
        """
        today = date.today()
        week_start = self._get_week_start(today)

        try:
            # Get volume at time of strain
            volume_result = self.db.client.table("weekly_volume_tracking").select(
                "total_volume_kg"
            ).eq("user_id", user_id).eq(
                "week_start", week_start.isoformat()
            ).eq("muscle_group", body_part.lower()).execute()

            volume_at_time = 0.0
            if volume_result.data:
                volume_at_time = float(volume_result.data[0].get('total_volume_kg', 0) or 0)

            # Record the strain
            self.db.client.table("strain_history").insert({
                "user_id": user_id,
                "body_part": body_part.lower(),
                "strain_date": today.isoformat(),
                "severity": severity,
                "activity_type": activity_type,
                "volume_at_time": volume_at_time,
                "notes": notes,
            }).execute()

            logger.info(
                f"🛡️ Recorded strain: {body_part} ({severity}), volume={volume_at_time}kg, "
                f"user={user_id}"
            )

            # Auto-reduce volume cap for this muscle
            new_cap = None
            if volume_at_time > 0:
                # Set new cap at 80% of volume when strain occurred
                new_cap = volume_at_time * 0.8

                self.db.client.table("muscle_volume_caps").upsert({
                    "user_id": user_id,
                    "muscle_group": body_part.lower(),
                    "max_weekly_volume_kg": new_cap,
                    "auto_adjusted": True,
                    "adjustment_reason": f"Strain recorded on {today.isoformat()}",
                    "updated_at": datetime.utcnow().isoformat(),
                }, on_conflict="user_id,muscle_group").execute()

                logger.info(
                    f"🛡️ Auto-adjusted volume cap for {body_part}: {new_cap:.1f}kg, user={user_id}"
                )

            return {
                "recorded": True,
                "body_part": body_part,
                "severity": severity,
                "volume_cap_adjusted": new_cap is not None,
                "new_volume_cap": new_cap
            }

        except Exception as e:
            logger.error(f"Failed to record strain: {e}")
            raise

    async def get_safe_volume_for_workout(
        self,
        user_id: str,
        planned_exercises: List[dict]
    ) -> List[dict]:
        """
        Adjust workout to stay within safe volume limits.

        Reviews planned exercises against current strain risk and
        reduces volume where necessary.

        Args:
            user_id: User identifier
            planned_exercises: List of planned exercise dicts

        Returns:
            Adjusted exercises with volume modifications
        """
        assessments = await self.assess_strain_risk(user_id)
        risk_map = {a.muscle_group: a for a in assessments}

        adjusted_exercises = []

        for exercise in planned_exercises:
            muscle = exercise.get('primary_muscle', '').lower()
            risk = risk_map.get(muscle)

            adj_exercise = exercise.copy()

            if risk and risk.should_reduce_volume:
                original_sets = exercise.get('sets', 3)
                reduction = risk.suggested_reduction_percent / 100
                new_sets = max(1, int(original_sets * (1 - reduction)))

                adj_exercise['sets'] = new_sets
                adj_exercise['volume_adjusted'] = True
                adj_exercise['adjustment_reason'] = risk.recommendation
                adj_exercise['original_sets'] = original_sets

                logger.info(
                    f"🛡️ Adjusted {exercise.get('name')}: {original_sets} -> {new_sets} sets, "
                    f"user={user_id}"
                )

            adjusted_exercises.append(adj_exercise)

        return adjusted_exercises

    async def get_volume_history(
        self,
        user_id: str,
        weeks: int = 8
    ) -> List[dict]:
        """
        Get volume history for the past N weeks.

        Args:
            user_id: User identifier
            weeks: Number of weeks of history to retrieve

        Returns:
            List of weekly volume records
        """
        today = date.today()
        start_date = today - timedelta(weeks=weeks)

        try:
            result = self.db.client.table("weekly_volume_tracking").select(
                "*"
            ).eq("user_id", user_id).gte(
                "week_start", start_date.isoformat()
            ).order("week_start", desc=True).execute()

            return result.data or []

        except Exception as e:
            logger.error(f"Failed to get volume history: {e}")
            raise

    async def get_strain_patterns(self, user_id: str) -> dict:
        """
        Analyze strain history to identify patterns.

        Args:
            user_id: User identifier

        Returns:
            Dict with strain patterns and insights
        """
        try:
            result = self.db.client.table("strain_history").select(
                "*"
            ).eq("user_id", user_id).order("strain_date", desc=True).execute()

            strains = result.data or []

            if not strains:
                return {
                    "total_strains": 0,
                    "most_affected_body_part": None,
                    "average_volume_at_strain": None,
                    "patterns": [],
                    "recommendations": ["No strain history recorded. Keep monitoring your volume!"]
                }

            # Analyze patterns
            body_part_counts: Dict[str, int] = {}
            severity_counts: Dict[str, int] = {}
            volumes = []

            for strain in strains:
                bp = strain.get('body_part', 'unknown')
                body_part_counts[bp] = body_part_counts.get(bp, 0) + 1

                sev = strain.get('severity', 'unknown')
                severity_counts[sev] = severity_counts.get(sev, 0) + 1

                vol = strain.get('volume_at_time')
                if vol:
                    volumes.append(float(vol))

            most_affected = max(body_part_counts.items(), key=lambda x: x[1])[0] if body_part_counts else None
            avg_volume = sum(volumes) / len(volumes) if volumes else None

            # Generate recommendations
            recommendations = []
            if most_affected:
                recommendations.append(
                    f"Your {most_affected} has had the most strains. "
                    f"Consider reducing volume and focusing on mobility for this area."
                )

            if severity_counts.get('severe', 0) > 0:
                recommendations.append(
                    "You've had severe strains in the past. "
                    "Be extra cautious with volume increases and listen to your body."
                )

            return {
                "total_strains": len(strains),
                "most_affected_body_part": most_affected,
                "body_part_counts": body_part_counts,
                "severity_counts": severity_counts,
                "average_volume_at_strain": avg_volume,
                "recent_strains": strains[:5],
                "recommendations": recommendations if recommendations else [
                    "Monitor your volume and don't increase by more than 10% per week."
                ]
            }

        except Exception as e:
            logger.error(f"Failed to get strain patterns: {e}")
            raise

    async def get_unacknowledged_alerts(self, user_id: str) -> List[dict]:
        """
        Get unacknowledged volume increase alerts for a user.

        Args:
            user_id: User identifier

        Returns:
            List of unacknowledged alerts
        """
        try:
            result = self.db.client.table("volume_increase_alerts").select(
                "*"
            ).eq("user_id", user_id).eq(
                "acknowledged", False
            ).order("created_at", desc=True).execute()

            return result.data or []

        except Exception as e:
            logger.error(f"Failed to get unacknowledged alerts: {e}")
            raise

    async def acknowledge_alert(self, alert_id: str, user_id: str) -> bool:
        """
        Acknowledge a volume increase alert.

        Args:
            alert_id: Alert identifier
            user_id: User identifier

        Returns:
            True if acknowledged successfully
        """
        try:
            result = self.db.client.table("volume_increase_alerts").update({
                "acknowledged": True,
                "acknowledged_at": datetime.utcnow().isoformat()
            }).eq("id", alert_id).eq("user_id", user_id).execute()

            if result.data:
                logger.info(f"🛡️ Acknowledged alert {alert_id}, user={user_id}")
                return True
            return False

        except Exception as e:
            logger.error(f"Failed to acknowledge alert: {e}")
            raise

    async def get_muscle_volume_caps(self, user_id: str) -> Dict[str, dict]:
        """
        Get personalized volume caps for all muscle groups.

        Combines default caps with any user-specific adjustments.

        Args:
            user_id: User identifier

        Returns:
            Dict mapping muscle groups to their caps
        """
        # Start with defaults
        caps = {
            muscle: {
                "max_weekly_sets": sets,
                "max_volume_increase_percent": 10.0,
                "auto_adjusted": False
            }
            for muscle, sets in DEFAULT_WEEKLY_SET_CAPS.items()
        }

        try:
            # Override with user-specific caps
            result = self.db.client.table("muscle_volume_caps").select(
                "*"
            ).eq("user_id", user_id).execute()

            for cap in (result.data or []):
                muscle = cap.get('muscle_group', '').lower()
                if muscle:
                    caps[muscle] = {
                        "max_weekly_sets": cap.get('max_weekly_sets', 20),
                        "max_weekly_volume_kg": cap.get('max_weekly_volume_kg'),
                        "max_volume_increase_percent": cap.get('max_volume_increase_percent', 10.0),
                        "auto_adjusted": cap.get('auto_adjusted', False),
                        "adjustment_reason": cap.get('adjustment_reason')
                    }

            return caps

        except Exception as e:
            logger.error(f"Failed to get muscle volume caps: {e}")
            return caps  # Return defaults on error


# Singleton instance
_strain_prevention_service: Optional[StrainPreventionService] = None


def get_strain_prevention_service() -> StrainPreventionService:
    """Get the StrainPreventionService singleton instance."""
    global _strain_prevention_service
    if _strain_prevention_service is None:
        _strain_prevention_service = StrainPreventionService()
    return _strain_prevention_service
