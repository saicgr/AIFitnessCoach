"""Population strength percentile ("stronger than X% of comparable lifters").

A Hevy / Symmetric-Strength-style percentile shown ALONGSIDE the existing 0-100
composite score (never replacing it — the familiar composite number is unchanged so
no user's headline shifts). The point is to answer "how do I compare to other lifters
at my bodyweight?" without claiming a false precision we can't support.

Method (honest + reuses what we already have):
  * The app already encodes per-exercise beginner→elite bodyweight-ratio standards
    (STRENGTH_STANDARDS + movement-pattern ladders). Those bands ARE population
    anchors in the StrengthLevel/Symmetric-Strength tradition. We map the user's
    bodyweight ratio onto those anchors and interpolate a percentile.
  * Anchor percentiles (industry convention): beginner≈5th, novice≈20th,
    intermediate≈50th, advanced≈80th, elite≈95th.
  * We ONLY return a percentile when the lift resolves to a REAL standard (an exact
    hand-curated entry or a known movement pattern) — NOT the conservative isolation
    default, which would fabricate a percentile for an accessory move. And never for
    machine-derived bests (machine brands vary too much for a cross-user claim).
    Otherwise we return None and the UI omits the percentile (no silent fake).

This deliberately does NOT use single-lift DOTS: DOTS coefficients are calibrated for
the squat+bench+deadlift TOTAL, so a single-lift DOTS percentile would need a
single-lift DOTS distribution we don't have. The bodyweight-ratio→anchor interpolation
is the defensible per-lift percentile and stays consistent with the composite's S1.
"""
from __future__ import annotations

from typing import Dict, Optional

# Anchor percentile for each standard band (industry convention).
_BAND_PERCENTILE = {
    "beginner": 5.0,
    "novice": 20.0,
    "intermediate": 50.0,
    "advanced": 80.0,
    "elite": 95.0,
}
_BANDS = ["beginner", "novice", "intermediate", "advanced", "elite"]


def ratio_to_percentile(standards: Dict[str, float], ratio: float) -> Optional[float]:
    """Interpolate a 0-99 percentile from a bodyweight ratio against a standards ladder.

    `standards` is the resolved {beginner,novice,intermediate,advanced,elite} ratio
    ladder for the exercise (already gender-adjusted by the caller). Returns None if
    the ladder is malformed.
    """
    try:
        anchors = [(standards[b], _BAND_PERCENTILE[b]) for b in _BANDS]
    except (KeyError, TypeError):
        return None
    # Sort by ratio just in case the ladder isn't monotonic.
    anchors.sort(key=lambda x: x[0])

    lowest_ratio, lowest_pct = anchors[0]
    highest_ratio, highest_pct = anchors[-1]

    if ratio <= lowest_ratio:
        # Below beginner → scale 0..5 by how close to the beginner ratio.
        if lowest_ratio <= 0:
            return 1.0
        return round(max(1.0, (ratio / lowest_ratio) * lowest_pct), 1)
    if ratio >= highest_ratio:
        # Above elite → asymptote toward 99 (never claim 100th percentile).
        if highest_ratio <= 0:
            return 99.0
        over = (ratio - highest_ratio) / highest_ratio
        return round(min(99.0, highest_pct + over * 8.0), 1)

    # Interpolate within the band the ratio falls into.
    for (r_lo, p_lo), (r_hi, p_hi) in zip(anchors, anchors[1:]):
        if r_lo <= ratio <= r_hi:
            if r_hi == r_lo:
                return round(p_lo, 1)
            frac = (ratio - r_lo) / (r_hi - r_lo)
            return round(p_lo + frac * (p_hi - p_lo), 1)
    return None
