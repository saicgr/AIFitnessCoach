"""
rtp_protocols.py — Phase 6 #19 of workouts overhaul.

Structured Return-to-Play (RTP) milestone protocols per major injury class.
DETERMINISTIC — no LLM (per `feedback_no_llm_for_safety_classification`).
Sourced from NSCA / NASM / ACSM published RTP guidelines, simplified for
self-directed users.

Overlays on the existing `injury_history` + `injury_rehab_exercises` tables
(audit confirmed both fully exist). The protocol defines week-by-week
allowable load progressions; the active-workout screen + AI coach gate
exercise selection against these milestones.

Schema of a protocol entry::

    {
      "injury_class": "knee_acl_grade_i",
      "phases": [
        {"week_range": [1, 2], "name": "Acute / pain control",
         "allowed_movements": ["isometric_quad", "straight_leg_raise"],
         "load_pct_of_1rm": 0.0,
         "milestones": ["pain <3/10 with ADLs", "knee flexion 90°"]},
        {"week_range": [3, 4], "name": "Early loading", ...},
        {"week_range": [5, 8], "name": "Progressive loading", ...},
        {"week_range": [9, 12], "name": "Return to sport", ...},
      ],
      "graduation_criteria": ["single-leg hop ≥90% of contralateral", ...],
    }

Disclaimer surfaced in the UI: NOT medical advice; clearance from a
healthcare provider is required before progression on each phase.
"""
from typing import Dict, List, Optional


RTP_PROTOCOLS: Dict[str, Dict] = {
    "knee_acl_grade_i": {
        "injury_class": "knee_acl_grade_i",
        "display_name": "Knee — ACL sprain (Grade I)",
        "total_weeks": 8,
        "disclaimer": "Self-guided framework. Clearance from a physical therapist is required before progressing each phase.",
        "phases": [
            {
                "week_range": [1, 2],
                "name": "Acute — pain control + ROM",
                "allowed_movements": ["isometric_quad", "straight_leg_raise", "ankle_pumps"],
                "load_pct_of_1rm": 0.0,
                "milestones": ["Pain <3/10 with ADLs", "Knee flexion ≥90°"],
            },
            {
                "week_range": [3, 4],
                "name": "Early loading — bilateral",
                "allowed_movements": ["wall_sit", "leg_press_bilateral_partial", "stationary_bike"],
                "load_pct_of_1rm": 0.30,
                "milestones": ["Wall sit 60s", "Full knee extension"],
            },
            {
                "week_range": [5, 6],
                "name": "Progressive loading — unilateral allowed",
                "allowed_movements": ["leg_press", "step_up", "bulgarian_split_squat_bodyweight"],
                "load_pct_of_1rm": 0.50,
                "milestones": ["Single-leg balance 30s", "No pain w/ bodyweight squat"],
            },
            {
                "week_range": [7, 8],
                "name": "Return-to-load — gradual",
                "allowed_movements": ["back_squat_low_intensity", "lunge", "single_leg_rdl"],
                "load_pct_of_1rm": 0.70,
                "milestones": ["Single-leg hop ≥80% contralateral", "Pain-free under load"],
            },
        ],
        "graduation_criteria": [
            "Single-leg hop ≥90% of contralateral",
            "No swelling/pain after a full session",
            "Self-reported confidence ≥8/10",
        ],
    },
    "lower_back_strain": {
        "injury_class": "lower_back_strain",
        "display_name": "Lower back — strain",
        "total_weeks": 6,
        "disclaimer": "Self-guided. Red-flag symptoms (numbness/radiating pain) require immediate medical evaluation.",
        "phases": [
            {
                "week_range": [1, 1],
                "name": "Acute — McGill big 3",
                "allowed_movements": ["mcgill_curl_up", "side_plank", "bird_dog"],
                "load_pct_of_1rm": 0.0,
                "milestones": ["Pain <4/10 walking", "Sleep without waking from pain"],
            },
            {
                "week_range": [2, 3],
                "name": "Early loading — hinge pattern restore",
                "allowed_movements": ["hip_thrust", "glute_bridge", "goblet_squat"],
                "load_pct_of_1rm": 0.30,
                "milestones": ["Hip hinge with broomstick pain-free", "Full ROM walking"],
            },
            {
                "week_range": [4, 5],
                "name": "Progressive loading — deadlift accessory",
                "allowed_movements": ["romanian_deadlift_light", "trap_bar_deadlift", "single_leg_rdl"],
                "load_pct_of_1rm": 0.55,
                "milestones": ["RDL @ 50% pain-free", "Plank 60s"],
            },
            {
                "week_range": [6, 6],
                "name": "Return-to-load",
                "allowed_movements": ["deadlift_low_intensity", "back_squat_low_intensity"],
                "load_pct_of_1rm": 0.70,
                "milestones": ["No pain through full ROM at 70%"],
            },
        ],
        "graduation_criteria": [
            "Deadlift @ 70% 1RM pain-free for 3 sets",
            "Side plank ≥60s both sides",
            "No pain on waking 7d consecutive",
        ],
    },
    "shoulder_impingement": {
        "injury_class": "shoulder_impingement",
        "display_name": "Shoulder — impingement",
        "total_weeks": 6,
        "disclaimer": "If pain persists past 4 weeks, see a healthcare provider for imaging.",
        "phases": [
            {
                "week_range": [1, 2],
                "name": "Acute — scapular control",
                "allowed_movements": ["wall_slide", "scap_pushup", "band_pull_apart"],
                "load_pct_of_1rm": 0.0,
                "milestones": ["Pain-free overhead reach to ear-level"],
            },
            {
                "week_range": [3, 4],
                "name": "Early loading — horizontal first",
                "allowed_movements": ["chest_supported_row", "neutral_grip_dumbbell_press"],
                "load_pct_of_1rm": 0.40,
                "milestones": ["Full ROM horizontal press/pull pain-free"],
            },
            {
                "week_range": [5, 5],
                "name": "Vertical re-introduction",
                "allowed_movements": ["landmine_press", "neutral_grip_dumbbell_overhead"],
                "load_pct_of_1rm": 0.55,
                "milestones": ["Pain-free landmine press 3 sets"],
            },
            {
                "week_range": [6, 6],
                "name": "Full return",
                "allowed_movements": ["overhead_press", "bench_press", "pullup"],
                "load_pct_of_1rm": 0.75,
                "milestones": ["OHP @ 75% pain-free 3 sets"],
            },
        ],
        "graduation_criteria": [
            "Pain-free full overhead ROM",
            "OHP @ 75% prior 1RM for 3 sets of 5",
        ],
    },
    "tennis_elbow": {
        "injury_class": "tennis_elbow",
        "display_name": "Elbow — lateral epicondylitis (tennis elbow)",
        "total_weeks": 8,
        "disclaimer": "Tyler twist + eccentric loading is the protocol with strongest evidence base.",
        "phases": [
            {
                "week_range": [1, 2],
                "name": "Acute — load deload + tyler twist",
                "allowed_movements": ["tyler_twist_flexbar", "wrist_extensor_isometric"],
                "load_pct_of_1rm": 0.0,
                "milestones": ["Pain <4/10 with daily activities"],
            },
            {
                "week_range": [3, 5],
                "name": "Eccentric loading",
                "allowed_movements": ["wrist_extension_eccentric", "reverse_curl_light"],
                "load_pct_of_1rm": 0.30,
                "milestones": ["Eccentric wrist extension 3×15 pain-free"],
            },
            {
                "week_range": [6, 8],
                "name": "Progressive return",
                "allowed_movements": ["barbell_curl_light", "hammer_curl", "row_neutral_grip"],
                "load_pct_of_1rm": 0.60,
                "milestones": ["Curl @ 60% pain-free 3 sets of 8"],
            },
        ],
        "graduation_criteria": [
            "Grip strength ≥90% contralateral",
            "Barbell curl @ 70% prior 1RM pain-free",
        ],
    },
}


def get_protocol(injury_class: str) -> Optional[Dict]:
    """Return the protocol for an injury class, or None if not catalogued."""
    return RTP_PROTOCOLS.get(injury_class)


def list_protocols() -> List[Dict]:
    """Return all available protocols for the UI picker."""
    return [
        {
            "injury_class": p["injury_class"],
            "display_name": p["display_name"],
            "total_weeks": p["total_weeks"],
            "phase_count": len(p["phases"]),
        }
        for p in RTP_PROTOCOLS.values()
    ]


def current_phase(injury_class: str, weeks_since_injury: int) -> Optional[Dict]:
    """Given an injury class and how many weeks since injury, return the
    current phase definition (or None if past graduation)."""
    p = RTP_PROTOCOLS.get(injury_class)
    if not p:
        return None
    for phase in p["phases"]:
        start, end = phase["week_range"]
        if start <= weeks_since_injury <= end:
            return phase
    return None  # Past final phase — caller surfaces graduation criteria.


def allowed_for_exercise(
    injury_class: str,
    weeks_since_injury: int,
    exercise_movement_key: str,
) -> bool:
    """Gate: should an exercise be allowed at the current week of the protocol?"""
    phase = current_phase(injury_class, weeks_since_injury)
    if not phase:
        # Past final phase → assume cleared.
        return True
    allowed = set(phase.get("allowed_movements", []))
    return exercise_movement_key.lower() in allowed
