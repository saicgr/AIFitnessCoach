"""
Cardio Phase Service — period-aware cardio intensity recommendation.

Surfaces a subtle, evidence-cited banner on the cardio plan / log-cardio start
screens recommending a cardio intensity (low/moderate/high) appropriate to the
user's current menstrual-cycle phase. Reuses the deterministic
`services.cycle.cycle_predictor` engine — does NOT introduce a second source
of truth for cycle phase.

Hard gates (return None) — never show the banner unless ALL apply:
    1. `users.cycle_aware_reminders` is true (the master cycle-content opt-in).
    2. Hormonal profile exists and `menstrual_tracking_enabled` is true.
    3. User is NOT pregnant (tracking_mode != "pregnancy") and NOT in
       post-menopause (menopause_status != "post"). Peri / pre / not-applicable
       are fine.
    4. User is NOT on hormonal contraceptives (the pill suppresses ovulation, so
       a phase-based recommendation is meaningless). Detected via the
       hormonal_profile.hormonal_contraceptive flag if present; absent column ⇒
       skip the gate (treat as opted-in).

Phase → recommendation map (research-cited):
    menstrual / early follicular   → low      (Z2 walks, easy run)
    follicular (mid)               → high     (intervals, tempo)
    ovulation                      → high
    early luteal (≤7 days post-O)  → moderate (steady Z2 endurance)
    late luteal (within 5d of next)→ low      (recovery, gentle Z2)

The predictor exposes 4 phases (menstrual/follicular/ovulation/luteal). This
service refines the luteal split into early/late using `days_until_next_period`
from the same prediction payload — keeping prediction logic in one place.

Calibration: when the predictor has insufficient history (predictions_available
but confidence == "low" with cycles_tracked == 0), we return a "tracking
calibration" recommendation with intensity=None so the UI shows a softer state.

Evidence citation pinned to: Stachenfeld 2008 (sex-hormone fluid balance) and
Sims & Heather 2018 (Roar — period-specific training research).
"""
from __future__ import annotations

from dataclasses import dataclass, asdict
from datetime import date
from typing import Any, Optional

from core.logger import get_logger
from services.cycle.cycle_predictor import predict_for_user

logger = get_logger(__name__)

EVIDENCE_CITATION = "Stachenfeld 2008; Sims & Heather 2018"


@dataclass
class PhaseRecommendation:
    """Period-aware cardio intensity recommendation for a single date."""

    phase: str                          # "menstrual" | "follicular" | "ovulation"
                                        # | "early_luteal" | "late_luteal"
                                        # | "tracking calibration"
    recommended_intensity: Optional[str]  # "low" | "moderate" | "high" | None
    rationale: str
    evidence_citation: str = EVIDENCE_CITATION
    cycle_day: Optional[int] = None
    confidence: Optional[str] = None

    def to_dict(self) -> dict:
        return asdict(self)


# ---------------------------------------------------------------------------
# Phase → copy / intensity map. Kept module-level so tests can introspect.
# ---------------------------------------------------------------------------
_RATIONALES: dict[str, tuple[Optional[str], str]] = {
    "menstrual": (
        "low",
        "Steady Z2 walks or an easy run if you feel up to it — energy is "
        "typically lower during your period.",
    ),
    "follicular": (
        "high",
        "Great time for intervals or a hard tempo session — rising estrogen "
        "tends to mean faster recovery and a higher ceiling.",
    ),
    "ovulation": (
        "high",
        "Peak-energy window — a strong day for hard intervals, a tempo, or "
        "a long quality session.",
    ),
    "early_luteal": (
        "moderate",
        "Solid Z2 endurance day — progesterone is rising but mid-intensity "
        "is typically well tolerated.",
    ),
    "late_luteal": (
        "low",
        "Recovery mode: gentle Z2 today. Watch RPE — perceived effort spikes "
        "and cramps may show up as your period nears.",
    ),
}

_CALIBRATION_RATIONALE = (
    "We need a couple more logged cycles before we can recommend a "
    "phase-specific cardio intensity. Train by feel for now."
)


# ---------------------------------------------------------------------------
# Hard-gate helpers
# ---------------------------------------------------------------------------
def _user_opted_in(client, user_id: str) -> bool:
    """Master opt-in: `users.cycle_aware_reminders` must be true."""
    try:
        res = client.table("users").select(
            "cycle_aware_reminders"
        ).eq("id", user_id).maybe_single().execute()
    except Exception as e:
        logger.warning(f"[CardioPhase] users lookup failed for {user_id}: {e}")
        return False
    if not res or not res.data:
        return False
    return bool(res.data.get("cycle_aware_reminders"))


def _profile_eligible(profile: dict) -> bool:
    """Return True when the hormonal profile permits a phase recommendation.

    Excludes pregnancy mode, post-menopause, and (if the column exists) users
    on hormonal contraceptives — since the pill suppresses ovulation, phase
    is not biologically meaningful for them.
    """
    if not profile:
        return False
    if not profile.get("menstrual_tracking_enabled"):
        return False
    if (profile.get("tracking_mode") or "tracking") == "pregnancy":
        return False
    menopause = profile.get("menopause_status") or "not_applicable"
    if menopause == "post":
        return False
    # `hormonal_contraceptive` may not exist on every deployment; treat absent
    # column as "not on contraceptives". Truthy ⇒ skip the recommendation.
    if profile.get("hormonal_contraceptive"):
        return False
    return True


# ---------------------------------------------------------------------------
# Pure phase refinement (luteal → early/late) — testable without DB
# ---------------------------------------------------------------------------
def refine_phase(prediction: dict) -> str:
    """Map the predictor's 4-phase output onto our 5-phase intensity grid.

    Splits "luteal" into early_luteal / late_luteal using
    `days_until_next_period`: within 5 days of the forecast next period ⇒
    late luteal (recovery mode). Otherwise early luteal (moderate). Other
    phases pass through unchanged.
    """
    phase = prediction.get("current_phase")
    if phase != "luteal":
        return phase or ""
    days_until = prediction.get("days_until_next_period")
    if days_until is not None and days_until <= 5:
        return "late_luteal"
    return "early_luteal"


def _is_calibration(prediction: dict) -> bool:
    """First-cycle / very-low-history → calibration short-circuit."""
    if not prediction.get("predictions_available"):
        return True
    stats = prediction.get("stats") or {}
    cycles = stats.get("cycles_tracked") or 0
    return prediction.get("confidence") == "low" and cycles == 0


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------
def get_phase_recommendation(
    client: Any,
    user_id: str,
    target_date: date,
) -> Optional[PhaseRecommendation]:
    """Return a period-aware cardio intensity recommendation for `target_date`.

    Returns None whenever the feature must stay invisible (opt-out, pregnancy,
    post-menopause, contraceptive user, no hormonal profile, or any error in
    the predictor — fail safe to "show nothing" rather than a misleading hint).
    """
    user_id = str(user_id)

    # Gate 1 — master opt-in flag on the users table.
    if not _user_opted_in(client, user_id):
        return None

    # Gate 2/3/4 — hormonal profile must exist and permit phase tracking.
    try:
        profile_res = client.table("hormonal_profiles").select("*").eq(
            "user_id", user_id
        ).execute()
    except Exception as e:
        logger.warning(f"[CardioPhase] hormonal_profiles lookup failed for {user_id}: {e}")
        return None
    profile = profile_res.data[0] if profile_res.data else {}
    if not _profile_eligible(profile):
        return None

    # Run the deterministic cycle predictor (single source of truth).
    try:
        prediction = predict_for_user(client, user_id, target_date)
    except Exception as e:
        logger.warning(f"[CardioPhase] cycle prediction failed for {user_id}: {e}")
        return None

    if _is_calibration(prediction):
        return PhaseRecommendation(
            phase="tracking calibration",
            recommended_intensity=None,
            rationale=_CALIBRATION_RATIONALE,
            cycle_day=prediction.get("current_cycle_day"),
            confidence=prediction.get("confidence"),
        )

    refined = refine_phase(prediction)
    if refined not in _RATIONALES:
        # Defensive: predictor returned an unexpected phase string.
        logger.warning(
            f"[CardioPhase] unrecognized phase {refined!r} for {user_id} — skipping"
        )
        return None

    intensity, rationale = _RATIONALES[refined]
    return PhaseRecommendation(
        phase=refined,
        recommended_intensity=intensity,
        rationale=rationale,
        cycle_day=prediction.get("current_cycle_day"),
        confidence=prediction.get("confidence"),
    )
