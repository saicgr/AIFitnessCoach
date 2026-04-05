"""
Flexibility Assessment Service.

Handles flexibility testing, evaluation, progress tracking, and personalized recommendations.
"""

from .assessment_helpers import (  # noqa: F401
    _get_age_group,
    _get_rating_from_norms,
    calculate_percentile,
    get_recommendations,
    evaluate_flexibility,
    FlexibilityAssessmentService,
    get_flexibility_assessment_service,
)
from typing import Dict, List, Optional, Tuple, Any
from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime, timedelta
from core.logger import get_logger

logger = get_logger(__name__)


class FlexibilityTest(Enum):
    """Available flexibility tests."""
    SIT_AND_REACH = "sit_and_reach"
    SHOULDER_FLEXIBILITY = "shoulder_flexibility"
    HIP_FLEXOR = "hip_flexor"
    HAMSTRING = "hamstring"
    ANKLE_DORSIFLEXION = "ankle_dorsiflexion"
    THORACIC_ROTATION = "thoracic_rotation"
    GROIN_FLEXIBILITY = "groin_flexibility"
    QUADRICEPS = "quadriceps"
    CALF_FLEXIBILITY = "calf_flexibility"
    NECK_ROTATION = "neck_rotation"


class FlexibilityRating(Enum):
    """Rating levels for flexibility assessments."""
    POOR = "poor"
    FAIR = "fair"
    GOOD = "good"
    EXCELLENT = "excellent"


@dataclass
class TestNorms:
    """Age and gender-adjusted norms for a flexibility test."""
    poor: Tuple[float, float]  # (min, max) range for poor rating
    fair: Tuple[float, float]
    good: Tuple[float, float]
    excellent: Tuple[float, float]


@dataclass
class FlexibilityTestDefinition:
    """Complete definition of a flexibility test."""
    id: str
    name: str
    description: str
    instructions: List[str]
    unit: str
    target_muscles: List[str]
    equipment_needed: List[str]
    video_url: Optional[str] = None
    image_url: Optional[str] = None
    # Higher is better for most tests, but for some (like shoulder gap), lower is better
    higher_is_better: bool = True
    # Norms by gender (male/female) and age group (18-29, 30-39, 40-49, 50-59, 60+)
    norms: Dict[str, Dict[str, TestNorms]] = field(default_factory=dict)
    tips: List[str] = field(default_factory=list)
    common_mistakes: List[str] = field(default_factory=list)


# Comprehensive flexibility test definitions with age and gender norms
FLEXIBILITY_TESTS: Dict[str, FlexibilityTestDefinition] = {
    "sit_and_reach": FlexibilityTestDefinition(
        id="sit_and_reach",
        name="Sit and Reach Test",
        description="Measures hamstring and lower back flexibility - one of the most common flexibility assessments used worldwide.",
        instructions=[
            "Sit on the floor with legs extended straight in front of you",
            "Keep your feet flat against a box or wall, about hip-width apart",
            "Place a ruler or measuring tape along your legs, with the 0 mark at your feet",
            "Slowly reach forward as far as possible with both hands",
            "Keep your knees straight - don't bend them",
            "Hold the maximum reach position for 2 seconds",
            "Record the distance in inches past (positive) or before (negative) your toes"
        ],
        unit="inches",
        target_muscles=["hamstrings", "lower_back", "calves"],
        equipment_needed=["ruler or measuring tape", "sit and reach box (optional)"],
        higher_is_better=True,
        norms={
            "male": {
                "18-29": TestNorms(poor=(-100, 0), fair=(1, 4), good=(5, 9), excellent=(10, 100)),
                "30-39": TestNorms(poor=(-100, -1), fair=(0, 3), good=(4, 8), excellent=(9, 100)),
                "40-49": TestNorms(poor=(-100, -2), fair=(-1, 2), good=(3, 7), excellent=(8, 100)),
                "50-59": TestNorms(poor=(-100, -3), fair=(-2, 1), good=(2, 6), excellent=(7, 100)),
                "60+": TestNorms(poor=(-100, -4), fair=(-3, 0), good=(1, 5), excellent=(6, 100)),
            },
            "female": {
                "18-29": TestNorms(poor=(-100, 1), fair=(2, 5), good=(6, 10), excellent=(11, 100)),
                "30-39": TestNorms(poor=(-100, 0), fair=(1, 4), good=(5, 9), excellent=(10, 100)),
                "40-49": TestNorms(poor=(-100, -1), fair=(0, 3), good=(4, 8), excellent=(9, 100)),
                "50-59": TestNorms(poor=(-100, -2), fair=(-1, 2), good=(3, 7), excellent=(8, 100)),
                "60+": TestNorms(poor=(-100, -3), fair=(-2, 1), good=(2, 6), excellent=(7, 100)),
            },
        },
        tips=[
            "Warm up with 5-10 minutes of light cardio before testing",
            "Exhale as you reach forward to allow deeper stretch",
            "Keep your head neutral - don't strain your neck",
            "Practice consistently 3-4 times per week for improvement"
        ],
        common_mistakes=[
            "Bending knees during the reach",
            "Bouncing to get extra distance",
            "Not warming up before testing",
            "Holding breath during the stretch"
        ]
    ),
    "shoulder_flexibility": FlexibilityTestDefinition(
        id="shoulder_flexibility",
        name="Shoulder Flexibility Test (Apley Scratch Test)",
        description="Measures shoulder range of motion and flexibility by testing how close you can bring your hands together behind your back.",
        instructions=[
            "Stand straight with good posture",
            "Reach one arm over your shoulder (same side as dominant hand first)",
            "Reach the other arm behind your back, palm facing out",
            "Try to touch or overlap your fingers",
            "Measure the gap between fingertips (positive = gap, negative = overlap)",
            "Test both sides separately and record the average",
            "Hold for 2 seconds at maximum reach"
        ],
        unit="inches",
        target_muscles=["shoulders", "rotator_cuff", "chest", "upper_back"],
        equipment_needed=["ruler or measuring tape", "partner (helpful but not required)"],
        higher_is_better=False,  # Lower gap is better, overlap is best
        norms={
            "male": {
                "18-29": TestNorms(poor=(4, 100), fair=(2, 3.9), good=(0, 1.9), excellent=(-100, -0.1)),
                "30-39": TestNorms(poor=(5, 100), fair=(3, 4.9), good=(1, 2.9), excellent=(-100, 0.9)),
                "40-49": TestNorms(poor=(6, 100), fair=(4, 5.9), good=(2, 3.9), excellent=(-100, 1.9)),
                "50-59": TestNorms(poor=(7, 100), fair=(5, 6.9), good=(3, 4.9), excellent=(-100, 2.9)),
                "60+": TestNorms(poor=(8, 100), fair=(6, 7.9), good=(4, 5.9), excellent=(-100, 3.9)),
            },
            "female": {
                "18-29": TestNorms(poor=(3, 100), fair=(1, 2.9), good=(-1, 0.9), excellent=(-100, -1.1)),
                "30-39": TestNorms(poor=(4, 100), fair=(2, 3.9), good=(0, 1.9), excellent=(-100, -0.1)),
                "40-49": TestNorms(poor=(5, 100), fair=(3, 4.9), good=(1, 2.9), excellent=(-100, 0.9)),
                "50-59": TestNorms(poor=(6, 100), fair=(4, 5.9), good=(2, 3.9), excellent=(-100, 1.9)),
                "60+": TestNorms(poor=(7, 100), fair=(5, 6.9), good=(3, 4.9), excellent=(-100, 2.9)),
            },
        },
        tips=[
            "Warm up shoulders with arm circles before testing",
            "Don't force the movement - stretch gently",
            "Test both sides to identify imbalances",
            "Regular doorway stretches can improve shoulder flexibility"
        ],
        common_mistakes=[
            "Arching the back to reach further",
            "Twisting the torso during the test",
            "Not testing both sides equally",
            "Rushing the movement instead of controlled reaching"
        ]
    ),
    "hip_flexor": FlexibilityTestDefinition(
        id="hip_flexor",
        name="Thomas Test (Hip Flexor Flexibility)",
        description="Assesses hip flexor tightness by measuring how flat your leg can rest when one knee is pulled to chest.",
        instructions=[
            "Lie on your back at the edge of a table or firm surface",
            "Pull one knee to your chest and hold it firmly",
            "Let the other leg hang off the edge naturally",
            "Measure the angle between the hanging thigh and the table",
            "A flat thigh (0 degrees) indicates good flexibility",
            "Record the angle in degrees from horizontal",
            "Test both legs and note any differences"
        ],
        unit="degrees",
        target_muscles=["hip_flexors", "iliopsoas", "rectus_femoris", "quadriceps"],
        equipment_needed=["sturdy table or bench", "goniometer or protractor (optional)", "partner (helpful)"],
        higher_is_better=False,  # Lower angle is better (0 = flat thigh)
        norms={
            "male": {
                "18-29": TestNorms(poor=(20, 90), fair=(15, 19), good=(5, 14), excellent=(0, 4)),
                "30-39": TestNorms(poor=(25, 90), fair=(18, 24), good=(8, 17), excellent=(0, 7)),
                "40-49": TestNorms(poor=(30, 90), fair=(22, 29), good=(12, 21), excellent=(0, 11)),
                "50-59": TestNorms(poor=(35, 90), fair=(25, 34), good=(15, 24), excellent=(0, 14)),
                "60+": TestNorms(poor=(40, 90), fair=(30, 39), good=(18, 29), excellent=(0, 17)),
            },
            "female": {
                "18-29": TestNorms(poor=(18, 90), fair=(12, 17), good=(4, 11), excellent=(0, 3)),
                "30-39": TestNorms(poor=(22, 90), fair=(15, 21), good=(6, 14), excellent=(0, 5)),
                "40-49": TestNorms(poor=(27, 90), fair=(19, 26), good=(10, 18), excellent=(0, 9)),
                "50-59": TestNorms(poor=(32, 90), fair=(23, 31), good=(13, 22), excellent=(0, 12)),
                "60+": TestNorms(poor=(38, 90), fair=(28, 37), good=(17, 27), excellent=(0, 16)),
            },
        },
        tips=[
            "Keep the knee of the hanging leg slightly bent",
            "Don't arch your lower back - keep it flat",
            "Breathe naturally throughout the test",
            "Tight hip flexors are common in people who sit a lot"
        ],
        common_mistakes=[
            "Arching the lower back to compensate",
            "Not pulling the test knee far enough",
            "Letting the hanging leg move outward",
            "Tensing up instead of relaxing"
        ]
    ),
    "hamstring": FlexibilityTestDefinition(
        id="hamstring",
        name="Active Straight Leg Raise (ASLR)",
        description="Measures hamstring flexibility by lifting your straight leg while lying on your back.",
        instructions=[
            "Lie flat on your back on a firm surface",
            "Keep both legs straight and arms by your sides",
            "Slowly raise one leg as high as possible, keeping it straight",
            "Keep the other leg flat on the ground",
            "Measure the angle of the raised leg from the ground",
            "Hold for 2 seconds at maximum height",
            "Test both legs and record each angle"
        ],
        unit="degrees",
        target_muscles=["hamstrings", "hip_flexors"],
        equipment_needed=["yoga mat or firm surface", "goniometer or smartphone angle app (optional)"],
        higher_is_better=True,  # Higher angle = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(0, 59), fair=(60, 69), good=(70, 79), excellent=(80, 180)),
                "30-39": TestNorms(poor=(0, 54), fair=(55, 64), good=(65, 74), excellent=(75, 180)),
                "40-49": TestNorms(poor=(0, 49), fair=(50, 59), good=(60, 69), excellent=(70, 180)),
                "50-59": TestNorms(poor=(0, 44), fair=(45, 54), good=(55, 64), excellent=(65, 180)),
                "60+": TestNorms(poor=(0, 39), fair=(40, 49), good=(50, 59), excellent=(60, 180)),
            },
            "female": {
                "18-29": TestNorms(poor=(0, 64), fair=(65, 74), good=(75, 84), excellent=(85, 180)),
                "30-39": TestNorms(poor=(0, 59), fair=(60, 69), good=(70, 79), excellent=(80, 180)),
                "40-49": TestNorms(poor=(0, 54), fair=(55, 64), good=(65, 74), excellent=(75, 180)),
                "50-59": TestNorms(poor=(0, 49), fair=(50, 59), good=(60, 69), excellent=(70, 180)),
                "60+": TestNorms(poor=(0, 44), fair=(45, 54), good=(55, 64), excellent=(65, 180)),
            },
        },
        tips=[
            "Keep your lower back pressed into the floor",
            "Don't bend the knee of the raised leg",
            "Use controlled movement, not momentum",
            "Practice hamstring stretches daily for improvement"
        ],
        common_mistakes=[
            "Bending the knee of the raised leg",
            "Lifting the non-test leg off the ground",
            "Arching the lower back",
            "Using momentum instead of controlled movement"
        ]
    ),
    "ankle_dorsiflexion": FlexibilityTestDefinition(
        id="ankle_dorsiflexion",
        name="Ankle Dorsiflexion Test (Knee-to-Wall)",
        description="Measures how far your knee can travel past your toes while keeping your heel on the ground.",
        instructions=[
            "Stand facing a wall with one foot about 4 inches from the wall",
            "Keep your heel firmly on the ground",
            "Slowly lunge forward, trying to touch your knee to the wall",
            "If you can touch, move your foot back and try again",
            "Find the maximum distance where you can still touch the wall",
            "Measure the distance from your big toe to the wall",
            "Test both ankles and record separately"
        ],
        unit="inches",
        target_muscles=["calves", "achilles_tendon", "anterior_tibialis"],
        equipment_needed=["wall", "ruler or measuring tape"],
        higher_is_better=True,  # Greater distance = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(0, 2.9), fair=(3, 3.9), good=(4, 4.9), excellent=(5, 12)),
                "30-39": TestNorms(poor=(0, 2.4), fair=(2.5, 3.4), good=(3.5, 4.4), excellent=(4.5, 12)),
                "40-49": TestNorms(poor=(0, 1.9), fair=(2, 2.9), good=(3, 3.9), excellent=(4, 12)),
                "50-59": TestNorms(poor=(0, 1.4), fair=(1.5, 2.4), good=(2.5, 3.4), excellent=(3.5, 12)),
                "60+": TestNorms(poor=(0, 0.9), fair=(1, 1.9), good=(2, 2.9), excellent=(3, 12)),
            },
            "female": {
                "18-29": TestNorms(poor=(0, 3.4), fair=(3.5, 4.4), good=(4.5, 5.4), excellent=(5.5, 12)),
                "30-39": TestNorms(poor=(0, 2.9), fair=(3, 3.9), good=(4, 4.9), excellent=(5, 12)),
                "40-49": TestNorms(poor=(0, 2.4), fair=(2.5, 3.4), good=(3.5, 4.4), excellent=(4.5, 12)),
                "50-59": TestNorms(poor=(0, 1.9), fair=(2, 2.9), good=(3, 3.9), excellent=(4, 12)),
                "60+": TestNorms(poor=(0, 1.4), fair=(1.5, 2.4), good=(2.5, 3.4), excellent=(3.5, 12)),
            },
        },
        tips=[
            "Keep your heel firmly planted - it's the key to accurate testing",
            "Align your knee over your second toe as you lunge",
            "Good ankle mobility is crucial for squats and injury prevention",
            "Calf stretches and foam rolling can improve ankle dorsiflexion"
        ],
        common_mistakes=[
            "Lifting the heel off the ground",
            "Letting the knee cave inward",
            "Not keeping the foot straight",
            "Moving too quickly"
        ]
    ),
    "thoracic_rotation": FlexibilityTestDefinition(
        id="thoracic_rotation",
        name="Thoracic Spine Rotation Test",
        description="Measures rotational flexibility of the mid-back, important for sports and daily activities.",
        instructions=[
            "Sit on the floor with legs extended or in a chair",
            "Cross your arms over your chest, hands on opposite shoulders",
            "Keep your hips facing forward and stable",
            "Rotate your upper body as far as possible to one side",
            "Measure the angle of rotation from the starting position",
            "Hold for 2 seconds at maximum rotation",
            "Test both directions and record each measurement"
        ],
        unit="degrees",
        target_muscles=["thoracic_spine", "obliques", "intercostals"],
        equipment_needed=["chair or floor mat", "goniometer or protractor (optional)"],
        higher_is_better=True,  # Greater rotation = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(0, 34), fair=(35, 44), good=(45, 54), excellent=(55, 90)),
                "30-39": TestNorms(poor=(0, 29), fair=(30, 39), good=(40, 49), excellent=(50, 90)),
                "40-49": TestNorms(poor=(0, 24), fair=(25, 34), good=(35, 44), excellent=(45, 90)),
                "50-59": TestNorms(poor=(0, 19), fair=(20, 29), good=(30, 39), excellent=(40, 90)),
                "60+": TestNorms(poor=(0, 14), fair=(15, 24), good=(25, 34), excellent=(35, 90)),
            },
            "female": {
                "18-29": TestNorms(poor=(0, 39), fair=(40, 49), good=(50, 59), excellent=(60, 90)),
                "30-39": TestNorms(poor=(0, 34), fair=(35, 44), good=(45, 54), excellent=(55, 90)),
                "40-49": TestNorms(poor=(0, 29), fair=(30, 39), good=(40, 49), excellent=(50, 90)),
                "50-59": TestNorms(poor=(0, 24), fair=(25, 34), good=(35, 44), excellent=(45, 90)),
                "60+": TestNorms(poor=(0, 19), fair=(20, 29), good=(30, 39), excellent=(40, 90)),
            },
        },
        tips=[
            "Keep your hips stable - rotation should come from your mid-back",
            "Breathe out as you rotate for extra range",
            "Good thoracic mobility reduces lower back strain",
            "Practice open book stretches and thoracic extensions"
        ],
        common_mistakes=[
            "Moving the hips during rotation",
            "Leaning to one side instead of rotating",
            "Not keeping arms crossed properly",
            "Holding breath during the movement"
        ]
    ),
    "groin_flexibility": FlexibilityTestDefinition(
        id="groin_flexibility",
        name="Groin Flexibility Test (Butterfly Stretch)",
        description="Measures inner thigh and groin flexibility using the seated butterfly position.",
        instructions=[
            "Sit on the floor with your back straight",
            "Bring the soles of your feet together",
            "Pull your feet as close to your body as comfortable",
            "Let your knees fall outward toward the floor",
            "Measure the distance from each knee to the floor",
            "Record the average of both sides in inches",
            "Hold the position for 2-3 seconds while measuring"
        ],
        unit="inches",
        target_muscles=["adductors", "hip_flexors", "inner_thighs"],
        equipment_needed=["yoga mat or floor", "ruler or measuring tape"],
        higher_is_better=False,  # Lower distance to floor = better
        norms={
            "male": {
                "18-29": TestNorms(poor=(8, 24), fair=(5, 7.9), good=(2, 4.9), excellent=(0, 1.9)),
                "30-39": TestNorms(poor=(9, 24), fair=(6, 8.9), good=(3, 5.9), excellent=(0, 2.9)),
                "40-49": TestNorms(poor=(10, 24), fair=(7, 9.9), good=(4, 6.9), excellent=(0, 3.9)),
                "50-59": TestNorms(poor=(11, 24), fair=(8, 10.9), good=(5, 7.9), excellent=(0, 4.9)),
                "60+": TestNorms(poor=(12, 24), fair=(9, 11.9), good=(6, 8.9), excellent=(0, 5.9)),
            },
            "female": {
                "18-29": TestNorms(poor=(6, 24), fair=(3, 5.9), good=(1, 2.9), excellent=(0, 0.9)),
                "30-39": TestNorms(poor=(7, 24), fair=(4, 6.9), good=(2, 3.9), excellent=(0, 1.9)),
                "40-49": TestNorms(poor=(8, 24), fair=(5, 7.9), good=(3, 4.9), excellent=(0, 2.9)),
                "50-59": TestNorms(poor=(9, 24), fair=(6, 8.9), good=(4, 5.9), excellent=(0, 3.9)),
                "60+": TestNorms(poor=(10, 24), fair=(7, 9.9), good=(5, 6.9), excellent=(0, 4.9)),
            },
        },
        tips=[
            "Sit on a cushion if you have lower back discomfort",
            "Don't force your knees down - let gravity do the work",
            "Lean slightly forward from the hips for a deeper stretch",
            "Practice daily for gradual improvement"
        ],
        common_mistakes=[
            "Pressing down on knees with hands",
            "Rounding the lower back",
            "Holding breath during the stretch",
            "Bouncing to try to get lower"
        ]
    ),
    "quadriceps": FlexibilityTestDefinition(
        id="quadriceps",
        name="Quadriceps Flexibility Test (Prone Heel to Buttock)",
        description="Measures quadriceps and hip flexor flexibility by seeing how close your heel can reach your buttock.",
        instructions=[
            "Lie face down on a flat surface",
            "Bend one knee and bring your heel toward your buttock",
            "Use your hand to gently assist if needed",
            "Measure the distance between your heel and buttock",
            "Keep your hips flat on the ground - don't let them rise",
            "Hold for 2 seconds at maximum stretch",
            "Test both legs and record each measurement"
        ],
        unit="inches",
        target_muscles=["quadriceps", "hip_flexors"],
        equipment_needed=["yoga mat or firm surface", "ruler or measuring tape"],
        higher_is_better=False,  # Smaller distance = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(6, 24), fair=(4, 5.9), good=(2, 3.9), excellent=(0, 1.9)),
                "30-39": TestNorms(poor=(7, 24), fair=(5, 6.9), good=(3, 4.9), excellent=(0, 2.9)),
                "40-49": TestNorms(poor=(8, 24), fair=(6, 7.9), good=(4, 5.9), excellent=(0, 3.9)),
                "50-59": TestNorms(poor=(9, 24), fair=(7, 8.9), good=(5, 6.9), excellent=(0, 4.9)),
                "60+": TestNorms(poor=(10, 24), fair=(8, 9.9), good=(6, 7.9), excellent=(0, 5.9)),
            },
            "female": {
                "18-29": TestNorms(poor=(5, 24), fair=(3, 4.9), good=(1, 2.9), excellent=(0, 0.9)),
                "30-39": TestNorms(poor=(6, 24), fair=(4, 5.9), good=(2, 3.9), excellent=(0, 1.9)),
                "40-49": TestNorms(poor=(7, 24), fair=(5, 6.9), good=(3, 4.9), excellent=(0, 2.9)),
                "50-59": TestNorms(poor=(8, 24), fair=(6, 7.9), good=(4, 5.9), excellent=(0, 3.9)),
                "60+": TestNorms(poor=(9, 24), fair=(7, 8.9), good=(5, 6.9), excellent=(0, 4.9)),
            },
        },
        tips=[
            "Keep your hips pressed into the floor throughout",
            "Don't force the stretch - go to comfortable tension",
            "Tight quads are common in runners and cyclists",
            "Foam rolling before stretching can help"
        ],
        common_mistakes=[
            "Lifting hips off the ground",
            "Rotating the hip outward",
            "Pulling too aggressively on the foot",
            "Arching the lower back"
        ]
    ),
    "calf_flexibility": FlexibilityTestDefinition(
        id="calf_flexibility",
        name="Calf Flexibility Test (Standing Wall Stretch)",
        description="Measures gastrocnemius (calf) flexibility using a wall stretch position.",
        instructions=[
            "Stand facing a wall, about arm's length away",
            "Place both hands on the wall at shoulder height",
            "Step one foot back, keeping it straight",
            "Lean into the wall, keeping the back heel on the ground",
            "Measure the distance from your back heel to the wall",
            "Find the maximum distance while keeping heel down",
            "Test both legs and record each measurement"
        ],
        unit="inches",
        target_muscles=["gastrocnemius", "soleus", "achilles_tendon"],
        equipment_needed=["wall", "ruler or measuring tape"],
        higher_is_better=True,  # Greater distance = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(0, 17), fair=(18, 23), good=(24, 29), excellent=(30, 48)),
                "30-39": TestNorms(poor=(0, 15), fair=(16, 21), good=(22, 27), excellent=(28, 48)),
                "40-49": TestNorms(poor=(0, 13), fair=(14, 19), good=(20, 25), excellent=(26, 48)),
                "50-59": TestNorms(poor=(0, 11), fair=(12, 17), good=(18, 23), excellent=(24, 48)),
                "60+": TestNorms(poor=(0, 9), fair=(10, 15), good=(16, 21), excellent=(22, 48)),
            },
            "female": {
                "18-29": TestNorms(poor=(0, 15), fair=(16, 21), good=(22, 27), excellent=(28, 48)),
                "30-39": TestNorms(poor=(0, 13), fair=(14, 19), good=(20, 25), excellent=(26, 48)),
                "40-49": TestNorms(poor=(0, 11), fair=(12, 17), good=(18, 23), excellent=(24, 48)),
                "50-59": TestNorms(poor=(0, 9), fair=(10, 15), good=(16, 21), excellent=(22, 48)),
                "60+": TestNorms(poor=(0, 7), fair=(8, 13), good=(14, 19), excellent=(20, 48)),
            },
        },
        tips=[
            "Keep your back leg completely straight",
            "Point your toes forward, not outward",
            "Lean your hips toward the wall, not just your upper body",
            "Calf stretches are essential for runners and walkers"
        ],
        common_mistakes=[
            "Bending the back knee",
            "Lifting the heel off the ground",
            "Turning the back foot outward",
            "Leaning only from the upper body"
        ]
    ),
    "neck_rotation": FlexibilityTestDefinition(
        id="neck_rotation",
        name="Neck Rotation Test",
        description="Measures cervical spine rotation - how far you can turn your head to each side.",
        instructions=[
            "Sit or stand with good posture, looking straight ahead",
            "Slowly rotate your head to one side as far as comfortable",
            "Keep your chin level - don't tilt up or down",
            "Your shoulders should remain still and facing forward",
            "Measure the angle of rotation from center",
            "Hold for 2 seconds at maximum rotation",
            "Test both sides and record each measurement"
        ],
        unit="degrees",
        target_muscles=["neck_rotators", "sternocleidomastoid", "upper_trapezius"],
        equipment_needed=["goniometer or smartphone angle app (optional)"],
        higher_is_better=True,  # Greater rotation = better flexibility
        norms={
            "male": {
                "18-29": TestNorms(poor=(0, 54), fair=(55, 64), good=(65, 74), excellent=(75, 90)),
                "30-39": TestNorms(poor=(0, 49), fair=(50, 59), good=(60, 69), excellent=(70, 90)),
                "40-49": TestNorms(poor=(0, 44), fair=(45, 54), good=(55, 64), excellent=(65, 90)),
                "50-59": TestNorms(poor=(0, 39), fair=(40, 49), good=(50, 59), excellent=(60, 90)),
                "60+": TestNorms(poor=(0, 34), fair=(35, 44), good=(45, 54), excellent=(55, 90)),
            },
            "female": {
                "18-29": TestNorms(poor=(0, 59), fair=(60, 69), good=(70, 79), excellent=(80, 90)),
                "30-39": TestNorms(poor=(0, 54), fair=(55, 64), good=(65, 74), excellent=(75, 90)),
                "40-49": TestNorms(poor=(0, 49), fair=(50, 59), good=(60, 69), excellent=(70, 90)),
                "50-59": TestNorms(poor=(0, 44), fair=(45, 54), good=(55, 64), excellent=(65, 90)),
                "60+": TestNorms(poor=(0, 39), fair=(40, 49), good=(50, 59), excellent=(60, 90)),
            },
        },
        tips=[
            "Move slowly and smoothly - never force the movement",
            "Keep your shoulders relaxed",
            "Good neck mobility helps prevent tension headaches",
            "Regular neck stretches are important for desk workers"
        ],
        common_mistakes=[
            "Tilting the head while rotating",
            "Moving the shoulders",
            "Rotating too quickly",
            "Holding breath during the movement"
        ]
    ),
}


# Stretch recommendations based on test results
STRETCH_RECOMMENDATIONS: Dict[str, Dict[str, List[Dict[str, Any]]]] = {
    "sit_and_reach": {
        "poor": [
            {"name": "Seated Forward Fold", "duration": "30 sec", "sets": 3, "notes": "Bend knees slightly if needed"},
            {"name": "Standing Toe Touch", "duration": "20 sec", "sets": 3, "notes": "Let gravity do the work"},
            {"name": "Lying Hamstring Stretch with Strap", "duration": "45 sec each", "sets": 2, "notes": "Keep knee straight"},
            {"name": "Cat-Cow Stretch", "reps": 10, "sets": 2, "notes": "For lower back mobility"},
        ],
        "fair": [
            {"name": "Seated Forward Fold", "duration": "45 sec", "sets": 3, "notes": "Try to keep legs straight"},
            {"name": "Standing Pike Stretch", "duration": "30 sec", "sets": 2, "notes": "Fold from hips"},
            {"name": "Supine Hamstring Stretch", "duration": "45 sec each", "sets": 2, "notes": "Use towel if needed"},
        ],
        "good": [
            {"name": "Deep Forward Fold", "duration": "60 sec", "sets": 2, "notes": "Reach past toes"},
            {"name": "Pancake Stretch", "duration": "45 sec", "sets": 2, "notes": "For advanced flexibility"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec", "sets": 2, "notes": "Keep up the good work!"},
        ],
    },
    "shoulder_flexibility": {
        "poor": [
            {"name": "Cross-Body Shoulder Stretch", "duration": "30 sec each", "sets": 3, "notes": "Gentle pressure only"},
            {"name": "Doorway Chest Stretch", "duration": "30 sec", "sets": 3, "notes": "Step through doorway"},
            {"name": "Thread the Needle", "duration": "30 sec each", "sets": 2, "notes": "Rotate slowly"},
            {"name": "Wall Angels", "reps": 10, "sets": 2, "notes": "Keep back flat against wall"},
        ],
        "fair": [
            {"name": "Behind-Back Clasp Stretch", "duration": "30 sec", "sets": 3, "notes": "Use strap if needed"},
            {"name": "Eagle Arms Stretch", "duration": "30 sec each", "sets": 2, "notes": "Lift elbows"},
            {"name": "Shoulder Dislocates with Stick", "reps": 10, "sets": 2, "notes": "Start wide, narrow over time"},
        ],
        "good": [
            {"name": "Cow Face Arms", "duration": "45 sec each", "sets": 2, "notes": "Try to clasp fingers"},
            {"name": "Sleeper Stretch", "duration": "30 sec each", "sets": 2, "notes": "For internal rotation"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec", "sets": 2, "notes": "Excellent shoulder mobility!"},
        ],
    },
    "hip_flexor": {
        "poor": [
            {"name": "Kneeling Hip Flexor Stretch", "duration": "30 sec each", "sets": 3, "notes": "Don't arch back"},
            {"name": "Couch Stretch", "duration": "45 sec each", "sets": 2, "notes": "Use wall for support"},
            {"name": "Supine Hip Flexor Stretch", "duration": "30 sec each", "sets": 2, "notes": "Keep back flat"},
            {"name": "Standing Quad Stretch", "duration": "30 sec each", "sets": 2, "notes": "Hold wall for balance"},
        ],
        "fair": [
            {"name": "Low Lunge Hold", "duration": "45 sec each", "sets": 2, "notes": "Sink hips forward"},
            {"name": "Pigeon Pose", "duration": "45 sec each", "sets": 2, "notes": "Use props if needed"},
            {"name": "Frog Stretch", "duration": "30 sec", "sets": 2, "notes": "For hip mobility"},
        ],
        "good": [
            {"name": "King Pigeon Pose", "duration": "45 sec each", "sets": 2, "notes": "Reach back for foot"},
            {"name": "Deep Lunge with Rotation", "duration": "30 sec each", "sets": 2, "notes": "Add thoracic twist"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec each", "sets": 2, "notes": "Great hip flexibility!"},
        ],
    },
    "hamstring": {
        "poor": [
            {"name": "Standing Hamstring Stretch", "duration": "30 sec each", "sets": 3, "notes": "Bend supporting knee"},
            {"name": "Supine Hamstring Stretch", "duration": "45 sec each", "sets": 2, "notes": "Use strap or towel"},
            {"name": "Seated Single Leg Stretch", "duration": "30 sec each", "sets": 2, "notes": "Flex foot"},
            {"name": "Wall Hamstring Stretch", "duration": "45 sec each", "sets": 2, "notes": "Lie close to wall"},
        ],
        "fair": [
            {"name": "Standing Forward Fold", "duration": "45 sec", "sets": 2, "notes": "Straight legs if possible"},
            {"name": "Downward Dog", "duration": "30 sec", "sets": 3, "notes": "Pedal feet"},
            {"name": "Pyramid Pose", "duration": "30 sec each", "sets": 2, "notes": "Square hips"},
        ],
        "good": [
            {"name": "Standing Split", "duration": "30 sec each", "sets": 2, "notes": "Against wall for balance"},
            {"name": "Hurdler Stretch", "duration": "45 sec each", "sets": 2, "notes": "Deep stretch"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec each", "sets": 2, "notes": "Excellent hamstring flexibility!"},
        ],
    },
    "ankle_dorsiflexion": {
        "poor": [
            {"name": "Wall Calf Stretch", "duration": "30 sec each", "sets": 3, "notes": "Keep heel down"},
            {"name": "Soleus Stretch", "duration": "30 sec each", "sets": 2, "notes": "Bend back knee"},
            {"name": "Foam Roll Calves", "duration": "60 sec each", "sets": 1, "notes": "Slow passes"},
            {"name": "Ankle Circles", "reps": 10, "sets": 2, "notes": "Both directions"},
        ],
        "fair": [
            {"name": "Elevated Calf Stretch", "duration": "30 sec each", "sets": 2, "notes": "On stairs or step"},
            {"name": "Deep Squat Hold", "duration": "30 sec", "sets": 3, "notes": "Heels down"},
            {"name": "Banded Ankle Stretch", "duration": "30 sec each", "sets": 2, "notes": "Pull toes toward shin"},
        ],
        "good": [
            {"name": "Deep Squat Hold", "duration": "60 sec", "sets": 2, "notes": "Add weight if comfortable"},
            {"name": "Single Leg Calf Stretch", "duration": "30 sec each", "sets": 2, "notes": "Full range"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec", "sets": 2, "notes": "Great ankle mobility!"},
        ],
    },
    "thoracic_rotation": {
        "poor": [
            {"name": "Open Book Stretch", "duration": "30 sec each", "sets": 3, "notes": "Lie on side"},
            {"name": "Thoracic Extension on Foam Roller", "duration": "45 sec", "sets": 2, "notes": "Arms overhead"},
            {"name": "Cat-Cow Stretch", "reps": 10, "sets": 2, "notes": "Focus on mid-back"},
            {"name": "Seated Spinal Twist", "duration": "30 sec each", "sets": 2, "notes": "Keep hips stable"},
        ],
        "fair": [
            {"name": "Thread the Needle", "duration": "30 sec each", "sets": 3, "notes": "Reach far under"},
            {"name": "Windmill Stretch", "duration": "30 sec each", "sets": 2, "notes": "Rotate through mid-back"},
            {"name": "Prone Scorpion", "duration": "30 sec each", "sets": 2, "notes": "Keep shoulders down"},
        ],
        "good": [
            {"name": "Deep Thread the Needle", "duration": "45 sec each", "sets": 2, "notes": "Add reach"},
            {"name": "Standing Rotation Stretch", "duration": "30 sec each", "sets": 2, "notes": "Hold resistance band"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec each", "sets": 2, "notes": "Excellent thoracic mobility!"},
        ],
    },
    "groin_flexibility": {
        "poor": [
            {"name": "Seated Butterfly Stretch", "duration": "30 sec", "sets": 3, "notes": "Don't push knees"},
            {"name": "Side Lunge Stretch", "duration": "30 sec each", "sets": 2, "notes": "Keep knee over toes"},
            {"name": "Frog Stretch", "duration": "30 sec", "sets": 2, "notes": "Start gentle"},
            {"name": "Lying Groin Stretch", "duration": "45 sec", "sets": 2, "notes": "Feet together, knees out"},
        ],
        "fair": [
            {"name": "Sumo Squat Hold", "duration": "30 sec", "sets": 3, "notes": "Wide stance"},
            {"name": "Straddle Stretch", "duration": "45 sec", "sets": 2, "notes": "Sit tall"},
            {"name": "90/90 Hip Stretch", "duration": "30 sec each", "sets": 2, "notes": "Switch sides"},
        ],
        "good": [
            {"name": "Pancake Stretch", "duration": "60 sec", "sets": 2, "notes": "Walk hands forward"},
            {"name": "Side Split Practice", "duration": "45 sec", "sets": 2, "notes": "Use blocks for support"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec", "sets": 2, "notes": "Excellent groin flexibility!"},
        ],
    },
    "quadriceps": {
        "poor": [
            {"name": "Standing Quad Stretch", "duration": "30 sec each", "sets": 3, "notes": "Hold wall for balance"},
            {"name": "Prone Quad Stretch", "duration": "30 sec each", "sets": 2, "notes": "Keep hips down"},
            {"name": "Kneeling Quad Stretch", "duration": "30 sec each", "sets": 2, "notes": "Use cushion under knee"},
            {"name": "Foam Roll Quads", "duration": "60 sec each", "sets": 1, "notes": "Slow passes"},
        ],
        "fair": [
            {"name": "Couch Stretch", "duration": "45 sec each", "sets": 2, "notes": "Wall support"},
            {"name": "King Arthur Stretch", "duration": "45 sec each", "sets": 2, "notes": "Against wall"},
            {"name": "Lying Quad Stretch", "duration": "30 sec each", "sets": 2, "notes": "Side-lying position"},
        ],
        "good": [
            {"name": "Deep Couch Stretch", "duration": "60 sec each", "sets": 2, "notes": "Add hip flexor stretch"},
            {"name": "Saddle Pose", "duration": "45 sec", "sets": 2, "notes": "Lean back carefully"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec each", "sets": 2, "notes": "Excellent quad flexibility!"},
        ],
    },
    "calf_flexibility": {
        "poor": [
            {"name": "Wall Calf Stretch", "duration": "30 sec each", "sets": 3, "notes": "Straight leg"},
            {"name": "Bent Knee Calf Stretch", "duration": "30 sec each", "sets": 2, "notes": "For soleus"},
            {"name": "Step Calf Stretch", "duration": "30 sec each", "sets": 2, "notes": "Drop heel off step"},
            {"name": "Foam Roll Calves", "duration": "60 sec each", "sets": 1, "notes": "Include Achilles"},
        ],
        "fair": [
            {"name": "Downward Dog Calf Stretch", "duration": "30 sec", "sets": 2, "notes": "Alternate pedaling"},
            {"name": "Single Leg Calf Stretch", "duration": "30 sec each", "sets": 2, "notes": "Against wall"},
            {"name": "Seated Calf Stretch with Band", "duration": "30 sec each", "sets": 2, "notes": "Pull toes back"},
        ],
        "good": [
            {"name": "Deep Step Calf Stretch", "duration": "45 sec each", "sets": 2, "notes": "Full range drop"},
            {"name": "Eccentric Calf Raises", "reps": 10, "sets": 2, "notes": "Slow 5-second lower"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "30 sec each", "sets": 2, "notes": "Great calf flexibility!"},
        ],
    },
    "neck_rotation": {
        "poor": [
            {"name": "Gentle Neck Rotation", "duration": "15 sec each", "sets": 3, "notes": "Slow and controlled"},
            {"name": "Chin Tucks", "reps": 10, "sets": 2, "notes": "Double chin position"},
            {"name": "Upper Trap Stretch", "duration": "30 sec each", "sets": 2, "notes": "Ear to shoulder"},
            {"name": "Levator Scapulae Stretch", "duration": "30 sec each", "sets": 2, "notes": "Look to armpit"},
        ],
        "fair": [
            {"name": "Neck Rotation Stretch", "duration": "20 sec each", "sets": 2, "notes": "Gentle hand pressure"},
            {"name": "SCM Stretch", "duration": "30 sec each", "sets": 2, "notes": "Look up and to side"},
            {"name": "Neck Circles", "reps": 5, "sets": 2, "notes": "Slow circles only"},
        ],
        "good": [
            {"name": "Full Range Neck Mobility", "duration": "30 sec", "sets": 2, "notes": "All directions"},
            {"name": "Resistance Neck Stretches", "duration": "20 sec each", "sets": 2, "notes": "Push against hand"},
        ],
        "excellent": [
            {"name": "Maintenance Stretching", "duration": "20 sec each", "sets": 2, "notes": "Great neck mobility!"},
        ],
    },
}


