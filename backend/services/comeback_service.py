"""
Comeback Service - Break Detection and Comeback Workout System

Automatically provides reduced intensity workouts when users return after extended breaks.
Implements age-aware adjustments and gradual ramp-up protocols.

Break Thresholds:
- Short break (7-13 days): 10% volume reduction, 1 week comeback
- Medium break (14-27 days): 25% volume reduction, 2 weeks comeback
- Long break (28-41 days): 40% volume reduction, 3 weeks comeback
- Extended break (42+ days): 50% volume reduction, 4 weeks comeback

Special handling for seniors (age 50+):
- Additional volume reduction based on age
- Extended comeback duration
- Focus on joint mobility and gradual progression
"""

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional, Dict, List, Any, Tuple
from enum import Enum
import logging

from core.db import get_supabase_db

logger = logging.getLogger(__name__)


class BreakType(str, Enum):
    """Classification of training breaks."""
    ACTIVE = "active"           # 0-6 days - no break
    SHORT_BREAK = "short_break"      # 7-13 days
    MEDIUM_BREAK = "medium_break"    # 14-27 days
    LONG_BREAK = "long_break"        # 28-41 days
    EXTENDED_BREAK = "extended_break" # 42+ days


@dataclass
class ComebackAdjustments:
    """Workout parameter adjustments for comeback."""
    volume_multiplier: float       # 0.5 = 50% of normal volume
    intensity_multiplier: float    # 0.7 = 70% of normal intensity/weight
    extra_rest_seconds: int        # Additional rest between sets
    extra_warmup_minutes: int      # Additional warmup time
    max_exercise_count: int        # Maximum exercises per workout
    avoid_movements: List[str]     # Movement patterns to avoid
    focus_areas: List[str]         # Areas to emphasize
    notes: str                     # AI prompt notes


@dataclass
class BreakStatus:
    """Complete break detection status."""
    days_since_last_workout: int
    break_type: BreakType
    in_comeback_mode: bool
    comeback_week: int
    comeback_started_at: Optional[datetime]
    adjustments: ComebackAdjustments
    user_age: Optional[int]
    age_adjustment_applied: float
    recommended_comeback_weeks: int
    prompt_context: str  # For Gemini prompt


class ComebackService:
    """
    Service for detecting breaks and managing comeback workouts.

    Implements research-backed protocols for safe return to training
    after extended breaks, with special consideration for older adults.
    """

    # Break thresholds in days
    BREAK_THRESHOLDS = {
        BreakType.SHORT_BREAK: 7,      # 1 week - 10% volume reduction
        BreakType.MEDIUM_BREAK: 14,    # 2 weeks - 25% volume reduction
        BreakType.LONG_BREAK: 28,      # 4 weeks - 40% volume reduction
        BreakType.EXTENDED_BREAK: 42,  # 6+ weeks - 50% volume reduction
    }

    # Comeback duration in weeks
    COMEBACK_DURATION_WEEKS = {
        BreakType.SHORT_BREAK: 1,
        BreakType.MEDIUM_BREAK: 2,
        BreakType.LONG_BREAK: 3,
        BreakType.EXTENDED_BREAK: 4,
    }

    # Base volume reduction by break type
    BASE_VOLUME_REDUCTION = {
        BreakType.ACTIVE: 0.0,
        BreakType.SHORT_BREAK: 0.10,      # 10% reduction
        BreakType.MEDIUM_BREAK: 0.25,     # 25% reduction
        BreakType.LONG_BREAK: 0.40,       # 40% reduction
        BreakType.EXTENDED_BREAK: 0.50,   # 50% reduction
    }

    # Base intensity reduction (for weights/difficulty)
    BASE_INTENSITY_REDUCTION = {
        BreakType.ACTIVE: 0.0,
        BreakType.SHORT_BREAK: 0.10,      # 10% lighter weights
        BreakType.MEDIUM_BREAK: 0.20,     # 20% lighter weights
        BreakType.LONG_BREAK: 0.30,       # 30% lighter weights
        BreakType.EXTENDED_BREAK: 0.40,   # 40% lighter weights
    }

    # Age-based additional adjustments
    AGE_ADJUSTMENTS = {
        # (min_age, max_age): (additional_volume_reduction, additional_intensity_reduction, extra_rest_seconds)
        (0, 29): (0.0, 0.0, 0),
        (30, 39): (0.0, 0.0, 0),
        (40, 49): (0.05, 0.05, 10),      # 5% additional reduction, +10s rest
        (50, 59): (0.10, 0.10, 15),      # 10% additional reduction, +15s rest
        (60, 69): (0.15, 0.15, 20),      # 15% additional reduction, +20s rest
        (70, 79): (0.20, 0.20, 30),      # 20% additional reduction, +30s rest
        (80, 150): (0.25, 0.25, 45),     # 25% additional reduction, +45s rest
    }

    def __init__(self):
        pass

    # -------------------------------------------------------------------------
    # Break Detection
    # -------------------------------------------------------------------------

    async def get_days_since_last_workout(self, user_id: str) -> int:
        """
        Calculate days since user's last completed workout.

        Args:
            user_id: User ID

        Returns:
            Number of days since last completed workout (999 if never completed)
        """
        try:
            db = get_supabase_db()

            # Get the most recent completed workout
            result = db.client.table("workouts").select(
                "scheduled_date"
            ).eq("user_id", user_id).eq("is_completed", True).order(
                "scheduled_date", desc=True
            ).limit(1).execute()

            if not result.data:
                logger.info(f"No completed workouts found for user {user_id}")
                return 999

            last_workout_date = result.data[0]["scheduled_date"]

            # Parse the date
            if isinstance(last_workout_date, str):
                # Handle various date formats
                try:
                    last_dt = datetime.fromisoformat(last_workout_date.replace("Z", "+00:00"))
                except ValueError:
                    last_dt = datetime.strptime(last_workout_date[:10], "%Y-%m-%d")
            else:
                last_dt = last_workout_date

            # Calculate days
            now = datetime.now(last_dt.tzinfo) if last_dt.tzinfo else datetime.now()
            days_since = (now - last_dt).days

            logger.info(f"User {user_id} last workout: {last_workout_date}, days since: {days_since}")

            # Update cached value on user record
            try:
                db.client.table("users").update({
                    "days_since_last_workout": days_since,
                    "last_workout_date": last_workout_date
                }).eq("id", user_id).execute()
            except Exception as e:
                logger.warning(f"Failed to update cached days_since_last_workout: {e}")

            return max(0, days_since)

        except Exception as e:
            logger.error(f"Failed to get days since last workout: {e}")
            return 0  # Assume active on error to avoid false positives

    def classify_break_type(self, days_off: int) -> BreakType:
        """
        Classify the break type based on days off.

        Args:
            days_off: Number of days since last workout

        Returns:
            BreakType classification
        """
        if days_off >= self.BREAK_THRESHOLDS[BreakType.EXTENDED_BREAK]:
            return BreakType.EXTENDED_BREAK
        elif days_off >= self.BREAK_THRESHOLDS[BreakType.LONG_BREAK]:
            return BreakType.LONG_BREAK
        elif days_off >= self.BREAK_THRESHOLDS[BreakType.MEDIUM_BREAK]:
            return BreakType.MEDIUM_BREAK
        elif days_off >= self.BREAK_THRESHOLDS[BreakType.SHORT_BREAK]:
            return BreakType.SHORT_BREAK
        else:
            return BreakType.ACTIVE

    def _get_age_adjustment(self, age: Optional[int]) -> Tuple[float, float, int]:
        """
        Get age-based adjustment factors.

        Args:
            age: User's age (None if unknown)

        Returns:
            Tuple of (volume_reduction, intensity_reduction, extra_rest_seconds)
        """
        if age is None:
            return (0.0, 0.0, 0)

        for (min_age, max_age), (vol_adj, int_adj, rest_adj) in self.AGE_ADJUSTMENTS.items():
            if min_age <= age <= max_age:
                return (vol_adj, int_adj, rest_adj)

        # Default for very old (shouldn't happen with 80-150 range)
        return (0.25, 0.25, 45)

    # -------------------------------------------------------------------------
    # Comeback Adjustments Calculation
    # -------------------------------------------------------------------------

    def get_comeback_adjustments(
        self,
        days_off: int,
        age: Optional[int] = None,
        comeback_week: int = 1,
        fitness_level: str = "intermediate"
    ) -> ComebackAdjustments:
        """
        Calculate workout parameter adjustments for comeback.

        Args:
            days_off: Number of days since last workout
            age: User's age (for additional adjustments)
            comeback_week: Current week of comeback (1-4)
            fitness_level: User's fitness level

        Returns:
            ComebackAdjustments with all workout modifications
        """
        break_type = self.classify_break_type(days_off)

        if break_type == BreakType.ACTIVE:
            return ComebackAdjustments(
                volume_multiplier=1.0,
                intensity_multiplier=1.0,
                extra_rest_seconds=0,
                extra_warmup_minutes=0,
                max_exercise_count=8,
                avoid_movements=[],
                focus_areas=[],
                notes=""
            )

        # Get base reductions
        base_volume_reduction = self.BASE_VOLUME_REDUCTION[break_type]
        base_intensity_reduction = self.BASE_INTENSITY_REDUCTION[break_type]

        # Get age adjustments
        age_vol_adj, age_int_adj, age_rest_adj = self._get_age_adjustment(age)

        # Apply comeback week progression (reduce adjustments as weeks progress)
        # Week 1: full reduction, Week 2: 75%, Week 3: 50%, Week 4: 25%
        max_weeks = self.COMEBACK_DURATION_WEEKS.get(break_type, 2)
        week_factor = max(0, 1 - (comeback_week - 1) / max_weeks)

        # Calculate final multipliers
        total_volume_reduction = (base_volume_reduction + age_vol_adj) * week_factor
        total_intensity_reduction = (base_intensity_reduction + age_int_adj) * week_factor

        # Cap at 60% max reduction
        total_volume_reduction = min(0.60, total_volume_reduction)
        total_intensity_reduction = min(0.50, total_intensity_reduction)

        volume_multiplier = 1.0 - total_volume_reduction
        intensity_multiplier = 1.0 - total_intensity_reduction

        # Calculate extra rest
        base_extra_rest = {
            BreakType.SHORT_BREAK: 15,
            BreakType.MEDIUM_BREAK: 30,
            BreakType.LONG_BREAK: 45,
            BreakType.EXTENDED_BREAK: 60,
        }.get(break_type, 0)

        extra_rest = int((base_extra_rest + age_rest_adj) * week_factor)

        # Extra warmup time
        extra_warmup = {
            BreakType.SHORT_BREAK: 2,
            BreakType.MEDIUM_BREAK: 3,
            BreakType.LONG_BREAK: 5,
            BreakType.EXTENDED_BREAK: 7,
        }.get(break_type, 0)

        if age and age >= 60:
            extra_warmup += 3  # Additional warmup for seniors

        # Max exercises
        max_exercises = {
            BreakType.SHORT_BREAK: 6,
            BreakType.MEDIUM_BREAK: 5,
            BreakType.LONG_BREAK: 4,
            BreakType.EXTENDED_BREAK: 4,
        }.get(break_type, 6)

        # Movements to avoid during comeback
        avoid_movements = []
        focus_areas = ["mobility", "joint_health", "form"]

        if break_type in [BreakType.LONG_BREAK, BreakType.EXTENDED_BREAK]:
            avoid_movements = ["explosive", "plyometric", "heavy_compound"]
            focus_areas = ["mobility", "joint_health", "reactivation", "form"]

        if age and age >= 60:
            avoid_movements.extend(["high_impact", "jumping", "rapid_movements"])
            focus_areas.append("balance")

        # Generate notes for AI prompt
        notes = self._generate_comeback_notes(
            days_off, break_type, age, comeback_week, max_weeks
        )

        return ComebackAdjustments(
            volume_multiplier=round(volume_multiplier, 2),
            intensity_multiplier=round(intensity_multiplier, 2),
            extra_rest_seconds=extra_rest,
            extra_warmup_minutes=extra_warmup,
            max_exercise_count=max_exercises,
            avoid_movements=avoid_movements,
            focus_areas=focus_areas,
            notes=notes
        )

    def _generate_comeback_notes(
        self,
        days_off: int,
        break_type: BreakType,
        age: Optional[int],
        comeback_week: int,
        max_weeks: int
    ) -> str:
        """Generate detailed notes for the comeback workout."""
        notes_parts = []

        # Break info
        notes_parts.append(f"Returning after {days_off} days off ({break_type.value})")
        notes_parts.append(f"Comeback week {comeback_week} of {max_weeks}")

        # Age-specific notes
        if age:
            if age >= 70:
                notes_parts.append(f"SENIOR (age {age}): Extra caution needed. Focus on controlled movements, extended warmup, and joint mobility.")
            elif age >= 60:
                notes_parts.append(f"Age {age}: Include balance work and longer rest periods.")
            elif age >= 50:
                notes_parts.append(f"Age {age}: Prioritize joint-friendly exercises and proper warmup.")

        # Recovery focus
        if break_type in [BreakType.LONG_BREAK, BreakType.EXTENDED_BREAK]:
            notes_parts.append("Focus on reactivation and rebuilding movement patterns before intensity.")

        return " | ".join(notes_parts)

    # -------------------------------------------------------------------------
    # Full Break Status Detection
    # -------------------------------------------------------------------------

    async def detect_break_status(self, user_id: str) -> BreakStatus:
        """
        Detect complete break status and calculate comeback adjustments.

        Args:
            user_id: User ID

        Returns:
            Complete BreakStatus with all relevant information
        """
        try:
            db = get_supabase_db()

            # Get user info
            user = db.get_user(user_id)
            if not user:
                raise ValueError(f"User {user_id} not found")

            user_age = user.get("age")
            fitness_level = user.get("fitness_level", "intermediate")

            # Check account age - new accounts shouldn't trigger comeback mode
            created_at = user.get("created_at")
            if created_at:
                try:
                    if isinstance(created_at, str):
                        created = datetime.fromisoformat(created_at.replace("Z", "+00:00"))
                    else:
                        created = created_at
                    account_age_days = (datetime.now(created.tzinfo) - created).days
                    if account_age_days < 14:
                        logger.info(f"🔄 [Comeback] User {user_id} account only {account_age_days} days old, skipping comeback detection")
                        return BreakStatus(
                            days_since_last_workout=0,
                            break_type=BreakType.ACTIVE,
                            in_comeback_mode=False,
                            comeback_week=0,
                            comeback_started_at=None,
                            adjustments=ComebackAdjustments(
                                volume_multiplier=1.0,
                                intensity_multiplier=1.0,
                                extra_rest_seconds=0,
                                extra_warmup_minutes=0,
                                max_exercise_count=8,
                                avoid_movements=[],
                                focus_areas=[],
                                notes=""
                            ),
                            user_age=user_age,
                            age_adjustment_applied=0.0,
                            recommended_comeback_weeks=0,
                            prompt_context=""
                        )
                except Exception as e:
                    logger.warning(f"Failed to update break status: {e}")

            in_comeback_mode = user.get("in_comeback_mode", False)
            comeback_week = user.get("comeback_week", 0)
            comeback_started_at = user.get("comeback_started_at")

            # Get days since last workout
            days_since = await self.get_days_since_last_workout(user_id)

            # Classify break type
            break_type = self.classify_break_type(days_since)

            # Get adjustments
            adjustments = self.get_comeback_adjustments(
                days_off=days_since,
                age=user_age,
                comeback_week=max(1, comeback_week),
                fitness_level=fitness_level
            )

            # Calculate age adjustment that was applied
            age_vol_adj, _, _ = self._get_age_adjustment(user_age)

            # Recommended comeback duration
            recommended_weeks = self.COMEBACK_DURATION_WEEKS.get(break_type, 0)
            if user_age and user_age >= 60:
                recommended_weeks += 1  # Extra week for seniors

            # Generate prompt context
            prompt_context = self._generate_prompt_context(
                days_since, break_type, user_age, comeback_week, adjustments
            )

            return BreakStatus(
                days_since_last_workout=days_since,
                break_type=break_type,
                in_comeback_mode=in_comeback_mode or break_type != BreakType.ACTIVE,
                comeback_week=comeback_week,
                comeback_started_at=comeback_started_at,
                adjustments=adjustments,
                user_age=user_age,
                age_adjustment_applied=age_vol_adj,
                recommended_comeback_weeks=recommended_weeks,
                prompt_context=prompt_context
            )

        except Exception as e:
            logger.error(f"Failed to detect break status: {e}")
            # Return safe defaults
            return BreakStatus(
                days_since_last_workout=0,
                break_type=BreakType.ACTIVE,
                in_comeback_mode=False,
                comeback_week=0,
                comeback_started_at=None,
                adjustments=ComebackAdjustments(
                    volume_multiplier=1.0,
                    intensity_multiplier=1.0,
                    extra_rest_seconds=0,
                    extra_warmup_minutes=0,
                    max_exercise_count=8,
                    avoid_movements=[],
                    focus_areas=[],
                    notes=""
                ),
                user_age=None,
                age_adjustment_applied=0.0,
                recommended_comeback_weeks=0,
                prompt_context=""
            )

    def _generate_prompt_context(
        self,
        days_off: int,
        break_type: BreakType,
        age: Optional[int],
        comeback_week: int,
        adjustments: ComebackAdjustments
    ) -> str:
        """Generate context string for Gemini prompt."""
        if break_type == BreakType.ACTIVE:
            return ""

        context_parts = [
            "## Comeback/Return-to-Training Context",
            f"User is returning after {days_off} days off ({break_type.value})",
            f"Apply {int((1 - adjustments.volume_multiplier) * 100)}% volume reduction",
            f"Apply {int((1 - adjustments.intensity_multiplier) * 100)}% weight/intensity reduction",
            f"Add {adjustments.extra_rest_seconds} extra seconds rest between sets",
            f"Include {adjustments.extra_warmup_minutes} minutes extra warmup"
        ]

        if age and age >= 50:
            context_parts.append(f"AGE CONSIDERATION: User is {age} years old")

        if age and age >= 70:
            context_parts.extend([
                "SENIOR RETURN-TO-TRAINING PROTOCOL:",
                "- Prioritize joint mobility and controlled movements",
                "- Avoid explosive/plyometric exercises",
                "- Include balance work in every session",
                "- Extended rest periods are essential",
                "- Focus on quality over quantity",
                "- Shorter workouts with lower volume"
            ])
        elif age and age >= 60:
            context_parts.extend([
                "OLDER ADULT PROTOCOL:",
                "- Include balance and stability exercises",
                "- Avoid high-impact movements",
                "- Emphasize proper warmup and cooldown"
            ])

        if adjustments.avoid_movements:
            context_parts.append(f"AVOID: {', '.join(adjustments.avoid_movements)}")

        if adjustments.focus_areas:
            context_parts.append(f"FOCUS ON: {', '.join(adjustments.focus_areas)}")

        if comeback_week > 0:
            max_weeks = self.COMEBACK_DURATION_WEEKS.get(break_type, 2)
            context_parts.append(f"Comeback progress: Week {comeback_week} of {max_weeks}")

        return "\n".join(context_parts)

    # -------------------------------------------------------------------------
    # Comeback Mode Management
    # -------------------------------------------------------------------------

    async def start_comeback_mode(self, user_id: str) -> Optional[str]:
        """
        Start comeback mode for a user.

        Args:
            user_id: User ID

        Returns:
            Comeback history ID if created, None otherwise
        """
        try:
            db = get_supabase_db()

            # Get current break status
            status = await self.detect_break_status(user_id)

            if status.break_type == BreakType.ACTIVE:
                logger.info(f"User {user_id} is active, no comeback needed")
                return None

            # Check if already in comeback mode
            user = db.get_user(user_id)
            if user.get("in_comeback_mode"):
                logger.info(f"User {user_id} already in comeback mode")
                return None

            # Calculate adjustments
            adjustments = status.adjustments
            target_weeks = status.recommended_comeback_weeks

            # Use the database function if available, otherwise do it manually
            try:
                result = db.client.rpc("start_comeback_mode", {
                    "p_user_id": user_id,
                    "p_days_off": status.days_since_last_workout,
                    "p_break_type": status.break_type.value,
                    "p_target_weeks": target_weeks,
                    "p_volume_reduction": 1.0 - adjustments.volume_multiplier,
                    "p_intensity_reduction": 1.0 - adjustments.intensity_multiplier
                }).execute()

                if result.data:
                    logger.info(f"Started comeback mode for user {user_id}, history_id: {result.data}")
                    return result.data

            except Exception as rpc_error:
                logger.warning(f"RPC start_comeback_mode failed: {rpc_error}, using fallback")

            # Fallback: manual update
            db.client.table("users").update({
                "in_comeback_mode": True,
                "comeback_started_at": datetime.now().isoformat(),
                "comeback_week": 1
            }).eq("id", user_id).execute()

            # Create history record
            history_result = db.client.table("comeback_history").insert({
                "user_id": user_id,
                "break_start_date": (datetime.now() - timedelta(days=status.days_since_last_workout)).isoformat(),
                "break_end_date": datetime.now().isoformat(),
                "days_off": status.days_since_last_workout,
                "break_type": status.break_type.value,
                "comeback_started_at": datetime.now().isoformat(),
                "target_comeback_weeks": target_weeks,
                "initial_volume_reduction": 1.0 - adjustments.volume_multiplier,
                "initial_intensity_reduction": 1.0 - adjustments.intensity_multiplier,
                "user_age_at_comeback": status.user_age,
                "user_fitness_level": user.get("fitness_level")
            }).execute()

            if history_result.data:
                logger.info(f"Started comeback mode for user {user_id}")
                return history_result.data[0]["id"]

            return None

        except Exception as e:
            logger.error(f"Failed to start comeback mode: {e}")
            return None

    async def progress_comeback_week(self, user_id: str) -> int:
        """
        Progress to the next comeback week.

        Args:
            user_id: User ID

        Returns:
            New week number
        """
        try:
            db = get_supabase_db()

            # Get current status
            user = db.get_user(user_id)
            current_week = user.get("comeback_week", 0)

            # Get target weeks from history
            history = db.client.table("comeback_history").select(
                "target_comeback_weeks"
            ).eq("user_id", user_id).is_("comeback_completed_at", "null").order(
                "created_at", desc=True
            ).limit(1).execute()

            target_weeks = 4  # Default
            if history.data:
                target_weeks = history.data[0].get("target_comeback_weeks", 4)

            new_week = current_week + 1

            if new_week >= target_weeks:
                # Comeback complete
                await self.end_comeback_mode(user_id, successful=True)
                return new_week

            # Update week
            db.client.table("users").update({
                "comeback_week": new_week
            }).eq("id", user_id).execute()

            logger.info(f"User {user_id} progressed to comeback week {new_week}")
            return new_week

        except Exception as e:
            logger.error(f"Failed to progress comeback week: {e}")
            return 0

    async def end_comeback_mode(self, user_id: str, successful: bool = True) -> bool:
        """
        End comeback mode for a user.

        Args:
            user_id: User ID
            successful: Whether the comeback was completed successfully

        Returns:
            True if successful
        """
        try:
            db = get_supabase_db()

            # Update user
            db.client.table("users").update({
                "in_comeback_mode": False,
                "comeback_week": 0,
                "comeback_started_at": None
            }).eq("id", user_id).execute()

            # Update history
            user = db.get_user(user_id)
            comeback_week = user.get("comeback_week", 0) if user else 0

            db.client.table("comeback_history").update({
                "comeback_completed_at": datetime.now().isoformat(),
                "actual_comeback_weeks": comeback_week,
                "successfully_completed": successful
            }).eq("user_id", user_id).is_("comeback_completed_at", "null").execute()

            logger.info(f"Ended comeback mode for user {user_id}, successful: {successful}")
            return True

        except Exception as e:
            logger.error(f"Failed to end comeback mode: {e}")
            return False

    # -------------------------------------------------------------------------
    # Utility Methods
    # -------------------------------------------------------------------------

    async def should_trigger_comeback(self, user_id: str) -> bool:
        """
        Check if comeback mode should be triggered for a user.

        Args:
            user_id: User ID

        Returns:
            True if comeback mode should start
        """
        days_since = await self.get_days_since_last_workout(user_id)
        break_type = self.classify_break_type(days_since)
        return break_type != BreakType.ACTIVE

    def apply_adjustments_to_workout(
        self,
        exercises: List[Dict],
        adjustments: ComebackAdjustments
    ) -> List[Dict]:
        """
        Apply comeback adjustments to a list of exercises.

        Args:
            exercises: List of exercise dictionaries
            adjustments: ComebackAdjustments to apply

        Returns:
            Modified exercise list
        """
        if adjustments.volume_multiplier >= 1.0 and adjustments.intensity_multiplier >= 1.0:
            return exercises

        modified = []

        for ex in exercises[:adjustments.max_exercise_count]:
            mod_ex = ex.copy()

            # Reduce sets (volume)
            if "sets" in mod_ex:
                original_sets = mod_ex["sets"]
                new_sets = max(2, int(original_sets * adjustments.volume_multiplier))
                mod_ex["sets"] = new_sets

            # Reduce reps slightly
            if "reps" in mod_ex:
                original_reps = mod_ex["reps"]
                new_reps = max(6, int(original_reps * (adjustments.volume_multiplier + 0.1)))
                mod_ex["reps"] = new_reps

            # Reduce weight
            if "weight_kg" in mod_ex and mod_ex["weight_kg"]:
                original_weight = mod_ex["weight_kg"]
                new_weight = original_weight * adjustments.intensity_multiplier
                # Round to nearest 2.5 kg
                mod_ex["weight_kg"] = round(new_weight / 2.5) * 2.5

            # Add extra rest
            if "rest_seconds" in mod_ex:
                mod_ex["rest_seconds"] = mod_ex["rest_seconds"] + adjustments.extra_rest_seconds
            else:
                mod_ex["rest_seconds"] = 60 + adjustments.extra_rest_seconds

            # Add comeback note
            if adjustments.notes:
                existing_notes = mod_ex.get("notes", "")
                mod_ex["notes"] = f"[COMEBACK] {adjustments.notes}. {existing_notes}".strip()

            modified.append(mod_ex)

        return modified

    async def log_comeback_event(
        self,
        user_id: str,
        event_type: str,
        event_data: Dict[str, Any]
    ) -> None:
        """
        Log a comeback-related event for analytics.

        Args:
            user_id: User ID
            event_type: Type of event (e.g., "comeback_started", "workout_completed")
            event_data: Additional event data
        """
        try:
            db = get_supabase_db()

            db.client.table("user_context_logs").insert({
                "user_id": user_id,
                "event_type": f"comeback_{event_type}",
                "event_data": event_data,
                "context": {
                    "time_of_day": datetime.now().strftime("%H:00"),
                    "day_of_week": datetime.now().strftime("%A").lower()
                }
            }).execute()

        except Exception as e:
            logger.warning(f"Failed to log comeback event: {e}")


# Singleton instance
comeback_service = ComebackService()


def get_comeback_service() -> ComebackService:
    """Get the singleton ComebackService instance."""
    return comeback_service
