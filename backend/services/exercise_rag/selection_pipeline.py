"""
Post-filtering pipeline for exercise selection.

Handles boosting, penalizing, capping, and reordering candidates
after the initial RAG query and equipment/difficulty filtering.
"""
from typing import List, Dict, Optional

from core.logger import get_logger
from .filters import (
    pre_filter_by_injuries,
    filter_by_avoided_muscles,
    INJURY_CONTRAINDICATIONS,
)
from .difficulty import get_difficulty_score, get_exercise_difficulty_category

logger = get_logger(__name__)


def apply_difficulty_scoring(candidates: List[Dict], validated_fitness_level: str, difficulty_adjustment: int):
    """Apply difficulty compatibility score to candidates for ranking."""
    for candidate in candidates:
        original_similarity = candidate.get("similarity", 0.5)
        d_score = candidate.get("difficulty_score", 0.5)
        candidate["similarity"] = (original_similarity * 0.7) + (d_score * 0.3)
        candidate["original_similarity"] = original_similarity

    candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)

    logger.info(
        f"Applied difficulty scoring for {validated_fitness_level} user: "
        f"{len([c for c in candidates if c.get('difficulty_category') == 'beginner'])} beginner, "
        f"{len([c for c in candidates if c.get('difficulty_category') == 'intermediate'])} intermediate, "
        f"{len([c for c in candidates if c.get('difficulty_category') == 'advanced'])} advanced exercises available"
    )


def boost_equipment_matches(candidates: List[Dict], equipment: List[str]):
    """Boost exercises matching user's selected (non-bodyweight) equipment."""
    _BW_EQUIPMENT = {"bodyweight", "body weight", "none", ""}
    user_real_equipment = [
        eq.lower() for eq in (equipment or [])
        if eq.lower() not in _BW_EQUIPMENT
    ]
    if user_real_equipment:
        for candidate in candidates:
            ex_eq = (candidate.get("equipment", "") or "").lower()
            if ex_eq not in _BW_EQUIPMENT:
                for user_eq in user_real_equipment:
                    if user_eq in ex_eq or ex_eq in user_eq:
                        candidate["similarity"] *= 1.15
                        break
        candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)


def cap_bodyweight_exercises(candidates: List[Dict], equipment: List[str]) -> List[Dict]:
    """Cap bodyweight exercises at 2 for users with real equipment."""
    _BW_ONLY_EQUIPMENT = {"bodyweight", "bodyweight_only", "bodyweight only", "body weight", "none", ""}
    has_non_bodyweight_equipment = any(
        eq.lower() not in _BW_ONLY_EQUIPMENT for eq in (equipment or [])
    )

    if has_non_bodyweight_equipment:
        bw_keywords = {"bodyweight", "body weight", "none", ""}
        bw_candidates = [c for c in candidates if (c.get("equipment", "") or "").lower() in bw_keywords]
        equip_candidates = [c for c in candidates if (c.get("equipment", "") or "").lower() not in bw_keywords]
        if len(bw_candidates) > 2:
            logger.info(
                f"[Equipment Cap] Capping bodyweight candidates from {len(bw_candidates)} to 2 "
                f"(gym user has {len(equip_candidates)} equipment-based candidates)"
            )
            candidates = equip_candidates + bw_candidates[:2]
            candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)

    return candidates


def apply_injury_filter(candidates: List[Dict], injuries: List[str]) -> List[Dict]:
    """Filter candidates by injuries, with safety fallback."""
    if not injuries:
        return candidates

    safe_candidates = pre_filter_by_injuries(candidates, injuries)
    if safe_candidates:
        logger.info(f"Pre-filtered {len(candidates)} candidates to {len(safe_candidates)} safe exercises")
        return safe_candidates

    logger.warning(f"Injury filter too restrictive - all {len(candidates)} exercises flagged as unsafe")

    active_patterns = set()
    for injury in [inj.lower() for inj in injuries]:
        for key, patterns in INJURY_CONTRAINDICATIONS.items():
            if key in injury:
                active_patterns.update(patterns)

    def count_matches(candidate):
        name_lower = candidate.get("name", "").lower()
        target_lower = candidate.get("target_muscle", "").lower()
        body_lower = candidate.get("body_part", "").lower()
        count = 0
        for pattern in active_patterns:
            if pattern in name_lower or pattern in target_lower or pattern in body_lower:
                count += 1
        return count

    candidates.sort(key=lambda c: (count_matches(c), -c.get("similarity", 0)))
    if candidates:
        min_matches = count_matches(candidates[0])
        candidates = [c for c in candidates if count_matches(c) == min_matches]
        logger.info(f"Selected {len(candidates)} least-risky exercises (match count: {min_matches})")

    return candidates


def apply_avoided_muscles_filter(candidates: List[Dict], avoided_muscles: Dict) -> List[Dict]:
    """Filter by avoided muscles."""
    if not avoided_muscles:
        return candidates

    original_count = len(candidates)
    candidates, primary_filtered, secondary_filtered = filter_by_avoided_muscles(
        candidates, avoided_muscles
    )

    if primary_filtered > 0 or secondary_filtered > 0:
        logger.info(
            f"Avoided muscles filter: {original_count} -> {len(candidates)} exercises "
            f"(primary: {primary_filtered}, secondary: {secondary_filtered} filtered)"
        )

    candidates.sort(key=lambda x: x.get("similarity", 0), reverse=True)
    return candidates


def apply_workout_type_filter(candidates: List[Dict], workout_type_preference: str):
    """Boost/penalize candidates based on workout type preference."""
    if not workout_type_preference or workout_type_preference == "strength":
        return

    workout_type_keywords = {
        "cardio": ["cardio", "hiit", "jumping", "running", "cycling", "burpee", "jump", "sprint", "rowing", "skipping"],
        "mixed": [],
        "mobility": ["stretch", "mobility", "flexibility", "yoga", "foam", "rotation", "dynamic"],
        "recovery": ["stretch", "foam", "light", "recovery", "mobility", "yoga", "breathing"],
    }

    keywords = workout_type_keywords.get(workout_type_preference, [])
    if keywords:
        for candidate in candidates:
            name_lower = candidate["name"].lower()
            instructions = (candidate.get("instructions") or "").lower()
            matches_type = any(kw in name_lower or kw in instructions for kw in keywords)

            if workout_type_preference in ["cardio", "mobility", "recovery"]:
                if matches_type:
                    candidate["similarity"] = min(1.0, candidate["similarity"] * 1.5)
                    candidate["workout_type_boost"] = True
                else:
                    candidate["similarity"] = candidate["similarity"] * 0.7
                    candidate["workout_type_penalty"] = True

        candidates.sort(key=lambda x: x["similarity"], reverse=True)


def apply_favorites_boost(candidates: List[Dict], favorite_exercises: Optional[List[str]]):
    """Boost favorite exercises with 2.5x multiplier."""
    if not favorite_exercises:
        return

    favorite_names_lower = [f.lower() for f in favorite_exercises]
    for candidate in candidates:
        if candidate["name"].lower() in favorite_names_lower:
            candidate["similarity"] = min(1.0, candidate["similarity"] * 2.5)
            candidate["is_favorite"] = True
            candidate["boost_reason"] = "favorite"
            logger.info(f"Boosted favorite exercise (2.5x): {candidate['name']} -> {candidate['similarity']:.2f}")
        else:
            candidate["is_favorite"] = False

    candidates.sort(key=lambda x: x["similarity"], reverse=True)


def apply_consistency_mode(
    candidates: List[Dict],
    recently_used_exercises: Optional[List[str]],
    consistency_mode: str,
    variation_percentage: int,
):
    """Apply consistency or variety mode based on recently used exercises."""
    if not recently_used_exercises:
        return

    recently_used_lower = [e.lower() for e in recently_used_exercises]

    if consistency_mode == "consistent":
        boosted_count = 0
        for candidate in candidates:
            if candidate["name"].lower() in recently_used_lower:
                candidate["similarity"] = min(1.0, candidate["similarity"] * 1.8)
                candidate["consistency_boosted"] = True
                if not candidate.get("boost_reason"):
                    candidate["boost_reason"] = "consistent_routine"
                else:
                    candidate["boost_reason"] += "+consistent_routine"
                boosted_count += 1
            else:
                candidate["consistency_boosted"] = False

        if boosted_count > 0:
            logger.info(f"Consistency mode: boosted {boosted_count} recently used exercises")
            candidates.sort(key=lambda x: x["similarity"], reverse=True)
    else:
        # "vary" mode (default) — strong penalty scaled by variation_percentage
        # 30% → 0.225x, 50% → 0.175x, 80% → 0.10x, 100% → 0.05x
        penalty_factor = max(0.05, 0.3 - (variation_percentage / 100.0) * 0.25)
        penalized_count = 0
        for candidate in candidates:
            if candidate["name"].lower() in recently_used_lower:
                candidate["similarity"] = candidate["similarity"] * penalty_factor
                candidate["variety_penalized"] = True
                penalized_count += 1
            else:
                candidate["variety_penalized"] = False

        if penalized_count > 0:
            logger.info(f"Vary mode: penalized {penalized_count} recently used exercises (factor={penalty_factor:.1f}x)")
            candidates.sort(key=lambda x: x["similarity"], reverse=True)


def extract_staple_exercises(
    candidates: List[Dict],
    staple_names: List[str],
    staple_exercises: Optional[List] = None,
) -> tuple[List[Dict], List[str], List[Dict]]:
    """
    Extract staple exercises from candidates.

    Returns:
        (staple_included, staple_names_used, remaining_candidates)
    """
    if not staple_names:
        return [], [], candidates

    staple_included = []
    staple_names_used = []
    staple_names_lower = [s.lower() for s in staple_names]

    staple_reasons = {}
    if staple_exercises:
        for s in staple_exercises:
            if isinstance(s, dict):
                staple_reasons[s.get("name", "").lower()] = s.get("reason", "favorite")

    for staple_name in staple_names:
        staple_lower = staple_name.lower()
        for candidate in candidates:
            if candidate["name"].lower() == staple_lower:
                staple_included.append(candidate)
                staple_names_used.append(candidate["name"])
                candidate["is_staple"] = True
                candidate["staple_reason"] = staple_reasons.get(staple_lower, "favorite")
                logger.info(f"Including STAPLE exercise: {candidate['name']}")
                break

    remaining = [c for c in candidates if c["name"].lower() not in staple_names_lower]
    logger.info(f"Staples included: {len(staple_included)} of {len(staple_names)}")
    return staple_included, staple_names_used, remaining


def extract_queued_exercises(
    candidates: List[Dict],
    queued_exercises: Optional[List[Dict]],
    focus_area: str,
) -> tuple[List[Dict], List[str], List[Dict], List[Dict]]:
    """
    Extract queued exercises from candidates.

    Returns:
        (queued_included, queued_names_used, remaining_candidates, exclusion_reasons)
    """
    if not queued_exercises:
        return [], [], candidates, []

    queued_included = []
    queued_names_used = []
    queued_exclusion_reasons = []
    queued_names = [q["name"].lower() for q in queued_exercises]
    candidate_names_lower = [c["name"].lower() for c in candidates]

    for queued in queued_exercises:
        queued_name_lower = queued["name"].lower()
        queued_focus = queued.get("target_muscle_group", "").lower()

        found_in_candidates = False
        for candidate in candidates:
            if candidate["name"].lower() == queued_name_lower:
                queued_included.append(candidate)
                queued_names_used.append(candidate["name"])
                candidate["from_queue"] = True
                found_in_candidates = True
                logger.info(f"Including queued exercise: {candidate['name']}")
                break

        if not found_in_candidates:
            reason = {
                "exercise_name": queued["name"],
                "queued_focus": queued_focus,
                "current_focus": focus_area,
            }
            if queued_focus and queued_focus != focus_area.lower():
                reason["exclusion_reason"] = f"Focus area mismatch: queued for '{queued_focus}', today is '{focus_area}'"
            elif queued_name_lower not in candidate_names_lower:
                reason["exclusion_reason"] = "Exercise not found in available library for current equipment"
            else:
                reason["exclusion_reason"] = "Exercise filtered out (equipment/injury filter)"
            queued_exclusion_reasons.append(reason)
            logger.info(f"Queued exercise excluded: {queued['name']} - {reason['exclusion_reason']}")

    remaining = [c for c in candidates if c["name"].lower() not in queued_names]
    return queued_included, queued_names_used, remaining, queued_exclusion_reasons


def adjust_workout_params_for_readiness(
    workout_params: Optional[Dict],
    readiness_score: Optional[int],
    user_mood: Optional[str],
) -> Dict:
    """Adjust workout params based on readiness score and mood."""
    adjusted = dict(workout_params or {})

    if readiness_score is not None:
        if readiness_score < 50:
            base_sets = adjusted.get("sets", 3)
            base_reps = adjusted.get("reps", 10)
            base_rest = adjusted.get("rest_seconds", 60)
            adjusted["sets"] = max(2, int(base_sets * 0.8))
            adjusted["reps"] = max(6, int(base_reps * 0.8) if isinstance(base_reps, int) else 8)
            adjusted["rest_seconds"] = int(base_rest * 1.3)
            adjusted["readiness_adjustment"] = "low_readiness"
            logger.info(f"[AI Consistency] Low readiness ({readiness_score}): Reduced intensity")
        elif readiness_score > 70:
            base_sets = adjusted.get("sets", 3)
            base_reps = adjusted.get("reps", 10)
            base_rest = adjusted.get("rest_seconds", 60)
            adjusted["sets"] = min(5, int(base_sets * 1.1))
            adjusted["reps"] = min(15, int(base_reps * 1.1) if isinstance(base_reps, int) else 12)
            adjusted["rest_seconds"] = max(45, int(base_rest * 0.9))
            adjusted["readiness_adjustment"] = "high_readiness"
            logger.info(f"[AI Consistency] High readiness ({readiness_score}): Increased intensity")

    if user_mood and user_mood.lower() in ["tired", "stressed", "anxious"]:
        current_sets = adjusted.get("sets", 3)
        current_reps = adjusted.get("reps", 10)
        current_rest = adjusted.get("rest_seconds", 60)
        adjusted["sets"] = max(2, int(current_sets * 0.9))
        adjusted["reps"] = max(5, int(current_reps * 0.9) if isinstance(current_reps, int) else 8)
        adjusted["rest_seconds"] = int(current_rest * 1.2)
        adjusted["mood_adjustment"] = user_mood.lower()
        logger.info(f"[AI Consistency] Mood ({user_mood}): Further reduced intensity")

    return adjusted
