"""
Injury Management Service.

Handles injury tracking, recovery phases, rehab exercises, and workout modifications.
"""
from datetime import datetime, timedelta
from typing import List, Dict, Any, Optional
from dataclasses import dataclass
from core.logger import get_logger

logger = get_logger(__name__)


@dataclass
class Injury:
    """Represents an active injury."""
    id: int
    user_id: int
    body_part: str
    severity: str  # "mild", "moderate", "severe"
    reported_at: datetime
    expected_recovery_date: datetime
    recovery_phase: str = "acute"
    is_active: bool = True
    pain_level: Optional[int] = None
    notes: Optional[str] = None


class InjuryService:
    """
    Service for managing injuries, recovery phases, and workout modifications.

    Recovery Timeline:
    - Mild: 1-2 weeks
    - Moderate: 3 weeks (default)
    - Severe: 4-6 weeks
    """

    # Severity to duration mapping (in weeks)
    SEVERITY_DURATION = {
        "mild": 2,
        "moderate": 3,
        "severe": 5,
    }

    # Recovery phases with timeline (days since injury reported)
    RECOVERY_PHASES = {
        "acute": {
            "start_day": 0,
            "end_day": 7,
            "intensity": "none",
            "description": "Rest and recovery - no exercises for injured area"
        },
        "subacute": {
            "start_day": 7,
            "end_day": 14,
            "intensity": "light",
            "description": "Light stretches and mobility work only"
        },
        "recovery": {
            "start_day": 14,
            "end_day": 21,
            "intensity": "moderate",
            "description": "Gentle strengthening exercises"
        },
        "healed": {
            "start_day": 21,
            "end_day": None,
            "intensity": "full",
            "description": "Full exercise capability restored"
        },
    }

    # Rehab exercises for each body part and phase
    REHAB_EXERCISES = {
        "back": {
            "acute": [],  # Rest only
            "subacute": [
                {"name": "Cat-Cow Stretch", "sets": 2, "reps": "10 each", "notes": "Gentle spinal mobility"},
                {"name": "Bird Dog", "sets": 2, "reps": "8 each side", "notes": "Core stability, slow controlled movement"},
                {"name": "Knee-to-Chest Stretch", "sets": 2, "reps": "30 sec hold each", "notes": "Lower back relief"},
            ],
            "recovery": [
                {"name": "Glute Bridge", "sets": 3, "reps": "12", "notes": "Strengthen glutes to support back"},
                {"name": "Dead Bug", "sets": 3, "reps": "10 each side", "notes": "Core engagement without back strain"},
                {"name": "Superman Hold", "sets": 2, "reps": "15 sec hold", "notes": "Gentle back strengthening"},
                {"name": "Pelvic Tilts", "sets": 2, "reps": "15", "notes": "Lumbar mobility"},
            ],
        },
        "shoulder": {
            "acute": [],
            "subacute": [
                {"name": "Pendulum Swings", "sets": 2, "reps": "15 each direction", "notes": "Passive mobility"},
                {"name": "Wall Slides", "sets": 2, "reps": "10", "notes": "Controlled range of motion"},
                {"name": "Shoulder Circles", "sets": 2, "reps": "10 each direction", "notes": "Gentle mobility"},
            ],
            "recovery": [
                {"name": "External Rotation with Band", "sets": 3, "reps": "12", "notes": "Rotator cuff strengthening"},
                {"name": "Face Pulls (light)", "sets": 3, "reps": "15", "notes": "Rear delt and upper back"},
                {"name": "Scapular Squeezes", "sets": 3, "reps": "15", "notes": "Scapular stability"},
            ],
        },
        "knee": {
            "acute": [],
            "subacute": [
                {"name": "Straight Leg Raise", "sets": 2, "reps": "12 each", "notes": "Quad activation"},
                {"name": "Seated Knee Extension", "sets": 2, "reps": "10", "notes": "Gentle quad work"},
                {"name": "Heel Slides", "sets": 2, "reps": "15", "notes": "Range of motion"},
            ],
            "recovery": [
                {"name": "Wall Sit", "sets": 3, "reps": "20 sec hold", "notes": "Isometric quad strength"},
                {"name": "Step-Ups (low box)", "sets": 2, "reps": "10 each", "notes": "Controlled movement"},
                {"name": "Terminal Knee Extension", "sets": 3, "reps": "15", "notes": "VMO strengthening"},
            ],
        },
        "hip": {
            "acute": [],
            "subacute": [
                {"name": "Hip Circles", "sets": 2, "reps": "10 each direction", "notes": "Gentle mobility"},
                {"name": "Supine Hip Flexor Stretch", "sets": 2, "reps": "30 sec each", "notes": "Hip flexor relief"},
                {"name": "Clamshells", "sets": 2, "reps": "12 each", "notes": "Hip abductor activation"},
            ],
            "recovery": [
                {"name": "Glute Bridge", "sets": 3, "reps": "15", "notes": "Glute strengthening"},
                {"name": "Side-lying Hip Abduction", "sets": 3, "reps": "12 each", "notes": "Hip stability"},
                {"name": "Hip Flexor March", "sets": 2, "reps": "10 each", "notes": "Controlled hip flexion"},
            ],
        },
        "ankle": {
            "acute": [],
            "subacute": [
                {"name": "Ankle Circles", "sets": 2, "reps": "10 each direction", "notes": "Mobility"},
                {"name": "Alphabet Draws", "sets": 1, "reps": "Full alphabet", "notes": "Range of motion"},
                {"name": "Towel Scrunches", "sets": 2, "reps": "15", "notes": "Foot strengthening"},
            ],
            "recovery": [
                {"name": "Single Leg Balance", "sets": 3, "reps": "30 sec each", "notes": "Proprioception"},
                {"name": "Resistance Band Dorsiflexion", "sets": 3, "reps": "15", "notes": "Tibialis strengthening"},
                {"name": "Calf Raises (slow)", "sets": 2, "reps": "12", "notes": "Controlled calf work"},
            ],
        },
        "wrist": {
            "acute": [],
            "subacute": [
                {"name": "Wrist Circles", "sets": 2, "reps": "10 each direction", "notes": "Mobility"},
                {"name": "Wrist Flexor Stretch", "sets": 2, "reps": "30 sec each", "notes": "Forearm relief"},
                {"name": "Finger Extensions", "sets": 2, "reps": "15", "notes": "Hand mobility"},
            ],
            "recovery": [
                {"name": "Wrist Curls (light)", "sets": 2, "reps": "15", "notes": "Forearm strengthening"},
                {"name": "Reverse Wrist Curls", "sets": 2, "reps": "15", "notes": "Extensor work"},
                {"name": "Grip Squeezes", "sets": 2, "reps": "20", "notes": "Grip strength"},
            ],
        },
        "elbow": {
            "acute": [],
            "subacute": [
                {"name": "Elbow Flexion/Extension", "sets": 2, "reps": "15", "notes": "Range of motion"},
                {"name": "Forearm Pronation/Supination", "sets": 2, "reps": "15", "notes": "Rotation mobility"},
                {"name": "Wrist Flexor Stretch", "sets": 2, "reps": "30 sec", "notes": "Tennis elbow relief"},
            ],
            "recovery": [
                {"name": "Hammer Curls (light)", "sets": 2, "reps": "12", "notes": "Brachialis strengthening"},
                {"name": "Reverse Curls (light)", "sets": 2, "reps": "12", "notes": "Forearm work"},
                {"name": "Tricep Extensions (light)", "sets": 2, "reps": "12", "notes": "Tricep strengthening"},
            ],
        },
        "neck": {
            "acute": [],
            "subacute": [
                {"name": "Chin Tucks", "sets": 2, "reps": "10", "notes": "Deep neck flexor activation"},
                {"name": "Gentle Neck Rotations", "sets": 2, "reps": "5 each way", "notes": "Slow controlled rotation"},
                {"name": "Neck Side Bends", "sets": 2, "reps": "5 each side", "notes": "Lateral mobility"},
            ],
            "recovery": [
                {"name": "Isometric Neck Holds", "sets": 3, "reps": "10 sec each direction", "notes": "Neck strengthening"},
                {"name": "Scapular Retractions", "sets": 3, "reps": "15", "notes": "Upper back posture"},
                {"name": "Prone Y Raises", "sets": 2, "reps": "10", "notes": "Lower trap strengthening"},
            ],
        },
    }

    # Exercises to AVOID for each injury (keywords to match)
    CONTRAINDICATIONS = {
        "back": ["deadlift", "barbell row", "good morning", "squat", "bent over", "hyperextension",
                 "romanian", "back extension", "sit-up", "crunch", "leg raise"],
        "shoulder": ["overhead press", "lateral raise", "bench press", "dip", "pull-up", "upright row",
                     "shoulder press", "military press", "arnold", "fly", "pulldown", "row"],
        "knee": ["squat", "lunge", "leg press", "leg extension", "jump", "running", "plyometric",
                 "box jump", "step up", "leg curl", "hack squat"],
        "wrist": ["push-up", "bench press", "curl", "front raise", "plank", "burpee",
                  "clean", "snatch", "farmer", "deadlift"],
        "hip": ["squat", "deadlift", "lunge", "hip thrust", "leg press", "romanian",
                "good morning", "step up", "split squat"],
        "ankle": ["running", "jump", "calf raise", "lunge", "squat", "box jump",
                  "skip", "hop", "sprint", "plyometric"],
        "neck": ["shrug", "upright row", "overhead press", "pulldown", "pullover",
                 "neck curl", "wrestling bridge"],
        "elbow": ["tricep", "curl", "skull crusher", "pushdown", "dip", "close grip",
                  "preacher", "hammer curl", "push-up"],
    }

    def get_duration_for_severity(self, severity: str) -> int:
        """Get recovery duration in weeks based on severity."""
        return self.SEVERITY_DURATION.get(severity.lower(), 3)

    def get_injury_phase(self, injury: Injury) -> str:
        """
        Determine current recovery phase based on time since injury.

        Args:
            injury: The injury object

        Returns:
            Phase name: "acute", "subacute", "recovery", or "healed"
        """
        days_since = (datetime.now() - injury.reported_at).days

        for phase, info in self.RECOVERY_PHASES.items():
            end_day = info.get("end_day")
            if end_day is None or days_since < end_day:
                return phase

        return "healed"

    def get_phase_info(self, phase: str) -> Dict[str, Any]:
        """Get information about a recovery phase."""
        return self.RECOVERY_PHASES.get(phase, self.RECOVERY_PHASES["healed"])

    def get_allowed_intensity(self, injury: Injury) -> str:
        """Get allowed exercise intensity for injured area."""
        phase = self.get_injury_phase(injury)
        return self.RECOVERY_PHASES[phase]["intensity"]

    def get_rehab_exercises(self, injury: Injury) -> List[Dict[str, Any]]:
        """
        Get appropriate rehab exercises for current recovery phase.

        Args:
            injury: The injury object

        Returns:
            List of rehab exercise dictionaries
        """
        phase = self.get_injury_phase(injury)
        body_part = injury.body_part.lower()

        if body_part in self.REHAB_EXERCISES:
            exercises = self.REHAB_EXERCISES[body_part].get(phase, [])
            # Add metadata to each exercise
            return [
                {
                    **ex,
                    "is_rehab": True,
                    "for_injury": body_part,
                    "recovery_phase": phase,
                }
                for ex in exercises
            ]

        logger.warning(f"No rehab exercises defined for body part: {body_part}")
        return []

    def is_exercise_safe(self, exercise_name: str, injury: Injury) -> bool:
        """
        Check if an exercise is safe given the injury.

        Args:
            exercise_name: Name of the exercise
            injury: The injury object

        Returns:
            True if exercise is safe, False if contraindicated
        """
        phase = self.get_injury_phase(injury)

        # If healed, all exercises are safe
        if phase == "healed":
            return True

        body_part = injury.body_part.lower()
        contraindicated_terms = self.CONTRAINDICATIONS.get(body_part, [])

        exercise_lower = exercise_name.lower()
        for term in contraindicated_terms:
            if term in exercise_lower:
                logger.debug(f"Exercise '{exercise_name}' contraindicated for {body_part} injury (matched: {term})")
                return False

        return True

    def filter_workout_for_injuries(
        self,
        exercises: List[Dict[str, Any]],
        active_injuries: List[Injury]
    ) -> tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
        """
        Filter a workout for active injuries.

        Args:
            exercises: List of exercise dictionaries
            active_injuries: List of active Injury objects

        Returns:
            Tuple of (safe_exercises, removed_exercises)
        """
        safe = []
        removed = []

        for exercise in exercises:
            exercise_name = exercise.get("name", "")
            is_safe = True

            for injury in active_injuries:
                if not self.is_exercise_safe(exercise_name, injury):
                    is_safe = False
                    exercise["removed_due_to"] = injury.body_part
                    break

            if is_safe:
                safe.append(exercise)
            else:
                removed.append(exercise)

        logger.info(f"Filtered workout: {len(safe)} safe, {len(removed)} removed")
        return safe, removed

    def add_rehab_exercises_to_workout(
        self,
        exercises: List[Dict[str, Any]],
        active_injuries: List[Injury]
    ) -> List[Dict[str, Any]]:
        """
        Add appropriate rehab exercises to a workout.

        Args:
            exercises: Current workout exercises
            active_injuries: List of active injuries

        Returns:
            Extended exercise list with rehab exercises at the end
        """
        rehab_exercises = []

        for injury in active_injuries:
            phase_exercises = self.get_rehab_exercises(injury)
            rehab_exercises.extend(phase_exercises)

        if rehab_exercises:
            logger.info(f"Adding {len(rehab_exercises)} rehab exercises to workout")

        # Add rehab exercises at the end of workout
        return exercises + rehab_exercises

    def get_recovery_summary(self, injury: Injury) -> Dict[str, Any]:
        """
        Get a summary of injury recovery status.

        Args:
            injury: The injury object

        Returns:
            Dictionary with recovery information
        """
        phase = self.get_injury_phase(injury)
        phase_info = self.get_phase_info(phase)
        days_since = (datetime.now() - injury.reported_at).days
        days_remaining = max(0, (injury.expected_recovery_date - datetime.now()).days)

        return {
            "body_part": injury.body_part,
            "severity": injury.severity,
            "days_since_injury": days_since,
            "days_remaining": days_remaining,
            "current_phase": phase,
            "phase_description": phase_info["description"],
            "allowed_intensity": phase_info["intensity"],
            "expected_recovery_date": injury.expected_recovery_date.strftime("%Y-%m-%d"),
            "is_active": injury.is_active,
            "progress_percent": min(100, round(days_since / max(1, days_since + days_remaining) * 100)),
        }

    def get_contraindicated_exercises(self, body_part: str) -> List[str]:
        """Get list of exercise keywords to avoid for a body part."""
        return self.CONTRAINDICATIONS.get(body_part.lower(), [])

    def should_check_in(self, injury: Injury) -> bool:
        """
        Determine if AI should check in on injury progress.

        Returns True if:
        - It's been 3+ days since last check-in
        - User is transitioning phases
        - Pain level was high
        """
        days_since = (datetime.now() - injury.reported_at).days

        # Check in at phase transitions (day 7, 14, 21)
        if days_since in [7, 14, 21]:
            return True

        # Check in every 3 days in acute phase
        if days_since < 7 and days_since % 3 == 0:
            return True

        # Weekly check-ins after first week
        if days_since >= 7 and days_since % 7 == 0:
            return True

        return False


# Singleton instance
_injury_service: Optional[InjuryService] = None


def get_injury_service() -> InjuryService:
    """Get the InjuryService singleton instance."""
    global _injury_service
    if _injury_service is None:
        _injury_service = InjuryService()
    return _injury_service
