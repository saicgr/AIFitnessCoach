"""
Milestone Service for Progress Milestones & ROI Communication.

This service handles:
- Retrieving milestone definitions
- Checking and awarding milestones
- Calculating ROI metrics
- Managing milestone celebrations and sharing
- Push notification triggers for milestone achievements
"""

import logging
from typing import List, Optional, Dict, Any
from datetime import datetime, timedelta

from core.db import get_supabase_db
from models.milestones import (
    MilestoneDefinition,
    MilestoneCategory,
    MilestoneTier,
    UserMilestone,
    MilestoneProgress,
    NewMilestoneAchieved,
    ROIMetrics,
    ROISummary,
    MilestonesResponse,
    MilestoneCheckResult,
)

logger = logging.getLogger(__name__)


class MilestoneService:
    """Service for managing milestones and ROI metrics."""

    def __init__(self):
        """Initialize the milestone service."""
        pass

    # =========================================================================
    # Milestone Definitions
    # =========================================================================

    async def get_all_milestone_definitions(
        self,
        category: Optional[MilestoneCategory] = None,
        active_only: bool = True,
    ) -> List[MilestoneDefinition]:
        """
        Get all milestone definitions, optionally filtered by category.

        Args:
            category: Optional category to filter by
            active_only: Whether to return only active milestones

        Returns:
            List of milestone definitions
        """
        try:
            db = get_supabase_db()
            query = db.client.table("milestone_definitions").select("*")

            if active_only:
                query = query.eq("is_active", True)

            if category:
                query = query.eq("category", category.value)

            query = query.order("sort_order").order("threshold")
            result = query.execute()

            return [
                MilestoneDefinition(
                    id=str(m["id"]),
                    name=m["name"],
                    description=m.get("description"),
                    category=m["category"],
                    threshold=m["threshold"],
                    icon=m.get("icon"),
                    badge_color=m.get("badge_color", "cyan"),
                    tier=m.get("tier", "bronze"),
                    points=m.get("points", 10),
                    share_message=m.get("share_message"),
                    is_active=m.get("is_active", True),
                    sort_order=m.get("sort_order", 0),
                    created_at=m.get("created_at"),
                )
                for m in result.data
            ]
        except Exception as e:
            logger.error(f"Error getting milestone definitions: {e}")
            return []

    # =========================================================================
    # User Milestones
    # =========================================================================

    async def get_user_milestones(
        self,
        user_id: str,
        include_definitions: bool = True,
    ) -> List[UserMilestone]:
        """
        Get all milestones achieved by a user.

        Args:
            user_id: User ID
            include_definitions: Whether to include milestone definitions

        Returns:
            List of user milestones
        """
        try:
            db = get_supabase_db()

            if include_definitions:
                result = db.client.table("user_milestones").select(
                    "*, milestone_definitions(*)"
                ).eq("user_id", user_id).order("achieved_at", desc=True).execute()
            else:
                result = db.client.table("user_milestones").select("*").eq(
                    "user_id", user_id
                ).order("achieved_at", desc=True).execute()

            milestones = []
            for um in result.data:
                milestone_def = None
                if include_definitions and um.get("milestone_definitions"):
                    md = um["milestone_definitions"]
                    milestone_def = MilestoneDefinition(
                        id=str(md["id"]),
                        name=md["name"],
                        description=md.get("description"),
                        category=md["category"],
                        threshold=md["threshold"],
                        icon=md.get("icon"),
                        badge_color=md.get("badge_color", "cyan"),
                        tier=md.get("tier", "bronze"),
                        points=md.get("points", 10),
                        share_message=md.get("share_message"),
                    )

                milestones.append(UserMilestone(
                    id=str(um["id"]),
                    user_id=um["user_id"],
                    milestone_id=str(um["milestone_id"]),
                    achieved_at=um["achieved_at"],
                    trigger_value=um.get("trigger_value"),
                    trigger_context=um.get("trigger_context"),
                    is_notified=um.get("is_notified", False),
                    is_celebrated=um.get("is_celebrated", False),
                    shared_at=um.get("shared_at"),
                    share_platform=um.get("share_platform"),
                    milestone=milestone_def,
                ))

            return milestones
        except Exception as e:
            logger.error(f"Error getting user milestones: {e}")
            return []

    async def get_milestone_progress(
        self,
        user_id: str,
    ) -> MilestonesResponse:
        """
        Get complete milestone progress for a user.

        Returns achieved milestones, upcoming milestones with progress,
        and milestones pending celebration.

        Args:
            user_id: User ID

        Returns:
            MilestonesResponse with all milestone data
        """
        try:
            db = get_supabase_db()

            # Get all milestone definitions
            all_definitions = await self.get_all_milestone_definitions()

            # Get user's achieved milestones
            user_milestones = await self.get_user_milestones(user_id)
            achieved_ids = {um.milestone_id for um in user_milestones}

            # Get current ROI metrics for progress calculation
            roi = await self.get_roi_metrics(user_id)

            achieved = []
            upcoming = []
            total_points = 0

            for definition in all_definitions:
                # Get current value for this category
                current_value = self._get_current_value_for_category(
                    roi, definition.category
                )

                if definition.id in achieved_ids:
                    # Find the user milestone
                    user_milestone = next(
                        (um for um in user_milestones if um.milestone_id == definition.id),
                        None
                    )
                    achieved.append(MilestoneProgress(
                        milestone=definition,
                        is_achieved=True,
                        achieved_at=user_milestone.achieved_at if user_milestone else None,
                        trigger_value=user_milestone.trigger_value if user_milestone else None,
                        is_celebrated=user_milestone.is_celebrated if user_milestone else False,
                        shared_at=user_milestone.shared_at if user_milestone else None,
                        current_value=current_value,
                        progress_percentage=100.0,
                    ))
                    total_points += definition.points
                else:
                    # Calculate progress percentage
                    progress_pct = min(100.0, (current_value / definition.threshold * 100)) if definition.threshold > 0 else 0

                    upcoming.append(MilestoneProgress(
                        milestone=definition,
                        is_achieved=False,
                        current_value=current_value,
                        progress_percentage=round(progress_pct, 1),
                    ))

            # Find uncelebrated milestones
            uncelebrated = [
                um for um in user_milestones
                if not um.is_celebrated
            ]

            # Sort upcoming by progress (closest to completion first)
            upcoming.sort(key=lambda x: x.progress_percentage or 0, reverse=True)

            # Get next milestone (closest to completion)
            next_milestone = upcoming[0] if upcoming else None

            return MilestonesResponse(
                achieved=achieved,
                upcoming=upcoming,
                total_points=total_points,
                total_achieved=len(achieved),
                next_milestone=next_milestone,
                uncelebrated=uncelebrated,
            )
        except Exception as e:
            logger.error(f"Error getting milestone progress: {e}")
            return MilestonesResponse(achieved=[], upcoming=[])

    async def get_uncelebrated_milestones(
        self,
        user_id: str,
    ) -> List[UserMilestone]:
        """
        Get milestones that haven't been celebrated yet.

        Args:
            user_id: User ID

        Returns:
            List of uncelebrated milestones
        """
        try:
            db = get_supabase_db()
            result = db.client.table("user_milestones").select(
                "*, milestone_definitions(*)"
            ).eq("user_id", user_id).eq("is_celebrated", False).execute()

            milestones = []
            for um in result.data:
                milestone_def = None
                if um.get("milestone_definitions"):
                    md = um["milestone_definitions"]
                    milestone_def = MilestoneDefinition(
                        id=str(md["id"]),
                        name=md["name"],
                        description=md.get("description"),
                        category=md["category"],
                        threshold=md["threshold"],
                        icon=md.get("icon"),
                        badge_color=md.get("badge_color", "cyan"),
                        tier=md.get("tier", "bronze"),
                        points=md.get("points", 10),
                        share_message=md.get("share_message"),
                    )

                milestones.append(UserMilestone(
                    id=str(um["id"]),
                    user_id=um["user_id"],
                    milestone_id=str(um["milestone_id"]),
                    achieved_at=um["achieved_at"],
                    trigger_value=um.get("trigger_value"),
                    is_celebrated=False,
                    milestone=milestone_def,
                ))

            return milestones
        except Exception as e:
            logger.error(f"Error getting uncelebrated milestones: {e}")
            return []

    async def mark_milestones_celebrated(
        self,
        user_id: str,
        milestone_ids: List[str],
    ) -> bool:
        """
        Mark milestones as celebrated (user has seen celebration dialog).

        Args:
            user_id: User ID
            milestone_ids: List of user_milestone IDs to mark

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            for mid in milestone_ids:
                db.client.table("user_milestones").update({
                    "is_celebrated": True,
                }).eq("id", mid).eq("user_id", user_id).execute()

            logger.info(f"Marked {len(milestone_ids)} milestones as celebrated for user {user_id}")
            return True
        except Exception as e:
            logger.error(f"Error marking milestones celebrated: {e}")
            return False

    async def record_milestone_share(
        self,
        user_id: str,
        milestone_id: str,
        platform: str,
    ) -> bool:
        """
        Record that a user shared a milestone.

        Args:
            user_id: User ID
            milestone_id: User milestone ID
            platform: Platform shared to (twitter, instagram, etc.)

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            db.client.table("user_milestones").update({
                "shared_at": datetime.utcnow().isoformat(),
                "share_platform": platform,
            }).eq("id", milestone_id).eq("user_id", user_id).execute()

            logger.info(f"User {user_id} shared milestone {milestone_id} on {platform}")
            return True
        except Exception as e:
            logger.error(f"Error recording milestone share: {e}")
            return False

    # =========================================================================
    # Milestone Checking and Awarding
    # =========================================================================

    async def check_and_award_milestones(
        self,
        user_id: str,
    ) -> MilestoneCheckResult:
        """
        Check for any new milestones and award them.

        This is called after workout completion, PR achievements, etc.

        Args:
            user_id: User ID

        Returns:
            MilestoneCheckResult with new milestones
        """
        try:
            db = get_supabase_db()

            # Call the database function to check milestones
            # This also updates ROI metrics
            result = db.client.rpc(
                "check_and_award_milestones",
                {"p_user_id": user_id}
            ).execute()

            new_milestones = []
            total_points = 0

            for row in result.data or []:
                milestone = NewMilestoneAchieved(
                    milestone_id=str(row["milestone_id"]),
                    milestone_name=row["milestone_name"],
                    milestone_icon=row.get("milestone_icon"),
                    milestone_tier=row.get("milestone_tier", "bronze"),
                    points=row.get("points", 0),
                )
                new_milestones.append(milestone)
                total_points += milestone.points

            if new_milestones:
                logger.info(
                    f"User {user_id} achieved {len(new_milestones)} new milestones! "
                    f"Total points: {total_points}"
                )

            return MilestoneCheckResult(
                new_milestones=new_milestones,
                total_new_points=total_points,
                roi_updated=True,
            )
        except Exception as e:
            logger.error(f"Error checking milestones: {e}")
            return MilestoneCheckResult(new_milestones=[], roi_updated=False)

    # =========================================================================
    # ROI Metrics
    # =========================================================================

    async def get_roi_metrics(
        self,
        user_id: str,
        recalculate: bool = False,
    ) -> ROIMetrics:
        """
        Get ROI metrics for a user.

        Args:
            user_id: User ID
            recalculate: Whether to force recalculation

        Returns:
            ROIMetrics for the user
        """
        try:
            db = get_supabase_db()

            if recalculate:
                # Force recalculation
                db.client.rpc("calculate_user_roi_metrics", {"p_user_id": user_id}).execute()

            result = db.client.table("user_roi_metrics").select("*").eq(
                "user_id", user_id
            ).execute()

            if not result.data:
                # No metrics yet, calculate them
                db.client.rpc("calculate_user_roi_metrics", {"p_user_id": user_id}).execute()
                result = db.client.table("user_roi_metrics").select("*").eq(
                    "user_id", user_id
                ).execute()

            if not result.data:
                # Still no data, return empty metrics
                return ROIMetrics(user_id=user_id).compute_derived_fields()

            data = result.data[0]

            roi = ROIMetrics(
                user_id=user_id,
                total_workouts_completed=data.get("total_workouts_completed", 0),
                total_exercises_completed=data.get("total_exercises_completed", 0),
                total_sets_completed=data.get("total_sets_completed", 0),
                total_reps_completed=data.get("total_reps_completed", 0),
                total_workout_time_seconds=data.get("total_workout_time_seconds", 0),
                total_active_time_seconds=data.get("total_active_time_seconds", 0),
                average_workout_duration_seconds=data.get("average_workout_duration_seconds", 0),
                total_weight_lifted_lbs=data.get("total_weight_lifted_lbs", 0),
                total_weight_lifted_kg=data.get("total_weight_lifted_kg", 0),
                estimated_calories_burned=data.get("estimated_calories_burned", 0),
                strength_increase_percentage=data.get("strength_increase_percentage", 0),
                prs_achieved_count=data.get("prs_achieved_count", 0),
                current_streak_days=data.get("current_streak_days", 0),
                longest_streak_days=data.get("longest_streak_days", 0),
                first_workout_date=data.get("first_workout_date"),
                last_workout_date=data.get("last_workout_date"),
                journey_days=data.get("journey_days", 0),
                workouts_this_week=data.get("workouts_this_week", 0),
                workouts_this_month=data.get("workouts_this_month", 0),
                average_workouts_per_week=data.get("average_workouts_per_week", 0),
                last_calculated_at=data.get("last_calculated_at"),
            )

            return roi.compute_derived_fields()
        except Exception as e:
            logger.error(f"Error getting ROI metrics: {e}")
            return ROIMetrics(user_id=user_id).compute_derived_fields()

    async def get_roi_summary(
        self,
        user_id: str,
    ) -> ROISummary:
        """
        Get a compact ROI summary for the home screen.

        Args:
            user_id: User ID

        Returns:
            ROISummary with key metrics
        """
        try:
            roi = await self.get_roi_metrics(user_id)

            # Format weight lifted
            if roi.total_weight_lifted_lbs >= 1000000:
                weight_str = f"{roi.total_weight_lifted_lbs / 1000000:.1f}M lbs"
            elif roi.total_weight_lifted_lbs >= 1000:
                weight_str = f"{roi.total_weight_lifted_lbs / 1000:.1f}K lbs"
            else:
                weight_str = f"{int(roi.total_weight_lifted_lbs):,} lbs"

            # Generate strength increase text
            if roi.strength_increase_percentage > 0:
                strength_text = f"{roi.strength_increase_percentage:.0f}% stronger"
            else:
                strength_text = ""

            # Generate motivational message based on progress
            motivational = self._generate_motivational_message(roi)

            # Generate headline
            if roi.total_workouts_completed == 0:
                headline = "Start Your Journey"
            elif roi.journey_days < 7:
                headline = "Great Start!"
            elif roi.journey_days < 30:
                headline = "Building Momentum"
            elif roi.journey_days < 90:
                headline = "Your Fitness Journey"
            else:
                headline = "Your Transformation"

            return ROISummary(
                total_workouts=roi.total_workouts_completed,
                total_hours_invested=roi.total_workout_time_hours,
                estimated_calories_burned=roi.estimated_calories_burned,
                total_weight_lifted=weight_str,
                strength_increase_text=strength_text,
                prs_count=roi.prs_achieved_count,
                current_streak=roi.current_streak_days,
                journey_days=roi.journey_days,
                headline=headline,
                motivational_message=motivational,
            )
        except Exception as e:
            logger.error(f"Error getting ROI summary: {e}")
            return ROISummary()

    def _generate_motivational_message(self, roi: ROIMetrics) -> str:
        """Generate a motivational message based on ROI metrics."""
        messages = []

        if roi.current_streak_days >= 7:
            messages.append(f"{roi.current_streak_days}-day streak! Keep it going!")
        elif roi.current_streak_days >= 3:
            messages.append("You're on fire!")

        if roi.prs_achieved_count > 0:
            messages.append(f"{roi.prs_achieved_count} personal records set!")

        if roi.strength_increase_percentage > 20:
            messages.append(f"{roi.strength_increase_percentage:.0f}% stronger than when you started!")
        elif roi.strength_increase_percentage > 10:
            messages.append("Significant strength gains!")
        elif roi.strength_increase_percentage > 0:
            messages.append("Getting stronger every day!")

        if roi.total_workout_time_hours >= 100:
            messages.append(f"{int(roi.total_workout_time_hours)} hours invested in yourself!")
        elif roi.total_workout_time_hours >= 50:
            messages.append("50+ hours of dedication!")

        if not messages:
            if roi.total_workouts_completed > 0:
                messages.append("Every workout counts!")
            else:
                messages.append("Your journey starts with one workout!")

        return messages[0] if messages else ""

    def _get_current_value_for_category(
        self,
        roi: ROIMetrics,
        category: str,
    ) -> float:
        """Get the current value for a milestone category."""
        if category == "workouts":
            return float(roi.total_workouts_completed)
        elif category == "streak":
            return float(roi.longest_streak_days)
        elif category == "strength" or category == "prs":
            return float(roi.prs_achieved_count)
        elif category == "time":
            return roi.total_workout_time_hours
        elif category == "volume":
            return roi.total_weight_lifted_lbs
        else:
            return 0.0

    # =========================================================================
    # Strength Increase Calculation
    # =========================================================================

    async def calculate_strength_increase(
        self,
        user_id: str,
    ) -> float:
        """
        Calculate the strength increase percentage since the user started.

        Compares average weight used in the first month vs current month.

        Args:
            user_id: User ID

        Returns:
            Percentage increase (e.g., 15.5 for 15.5% increase)
        """
        try:
            db = get_supabase_db()

            # Get first workout date
            first_workout = db.client.table("workout_logs").select(
                "created_at"
            ).eq("user_id", user_id).eq("status", "completed").order(
                "created_at"
            ).limit(1).execute()

            if not first_workout.data:
                return 0.0

            first_date = datetime.fromisoformat(
                first_workout.data[0]["created_at"].replace("Z", "+00:00")
            )
            first_month_end = first_date + timedelta(days=30)

            # Get average weight in first month
            first_month_avg = db.client.rpc(
                "get_average_weight_in_period",
                {
                    "p_user_id": user_id,
                    "p_start_date": first_date.isoformat(),
                    "p_end_date": first_month_end.isoformat(),
                }
            ).execute()

            # Get average weight in last 30 days
            now = datetime.utcnow()
            last_month_start = now - timedelta(days=30)

            current_avg = db.client.rpc(
                "get_average_weight_in_period",
                {
                    "p_user_id": user_id,
                    "p_start_date": last_month_start.isoformat(),
                    "p_end_date": now.isoformat(),
                }
            ).execute()

            first_avg = first_month_avg.data if first_month_avg.data else 0
            current_val = current_avg.data if current_avg.data else 0

            if first_avg and first_avg > 0:
                increase = ((current_val - first_avg) / first_avg) * 100
                return max(0, round(increase, 1))

            return 0.0
        except Exception as e:
            logger.error(f"Error calculating strength increase: {e}")
            return 0.0


# Singleton instance
milestone_service = MilestoneService()
