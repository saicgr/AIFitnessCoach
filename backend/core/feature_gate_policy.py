"""
Canonical subscription-tier ranking and reset-period policy for feature gates.

WHY THIS MODULE EXISTS
----------------------
Every feature gate in the backend used to carry its own inline copy of the tier
hierarchy (`{"free": 0, "premium": 1, "premium_plus": 2}` in core/premium_gate.py,
`{... "lifetime": 3}` in api/v1/subscriptions/management.py and
api/v1/subscriptions/webhooks.py, ad-hoc tuples in api/v1/equipment/snap.py and
api/v1/content_catalogs.py). Those copies drifted: the production
`subscription_tier` enum is

    free, premium, ultra, lifetime, premium_plus

and core/premium_gate.py knew only three of the five, so a founder converted to
`tier = 'lifetime'` by POST /subscriptions/{user_id}/convert-to-lifetime was
ranked at level 0 — metered and 402'd as a FREE user at 20 coach messages/day
after paying $149.99.

A hardcoded per-call-site tier list IS the bug. This module is the ONE source:
every gate imports `is_paid_tier()` / `meets_minimum_tier()` from here, and
`--check` proves the map still covers every label of the live `subscription_tier`
enum, so a future enum value cannot be silently dropped again.

UNKNOWN LABELS ARE NEVER SILENTLY DEMOTED
-----------------------------------------
`free` is in the map, and both `user_subscriptions.tier` and
`feature_gates.minimum_tier` are constrained by the `subscription_tier` enum, so
a label this module does not recognise is by construction a *paid* tier that was
added to the enum after this map was last updated. It is therefore ranked at the
lowest PAID rank (never 0/free) and logged at ERROR level — the previous
`.get(tier, 0)` shape is what turned a stale map into lost revenue.

RESET PERIODS
-------------
`feature_gates.reset_period` used to be nullable with no default and no CHECK,
and core/premium_gate.py read NULL as "sum all-time usage" — i.e. a NULL turned a
daily free cap into a LIFETIME cap (migration 2330 repaired the one row that had
already rotted). Migration 2380 makes NULL impossible (backfill + DEFAULT 'daily'
+ NOT NULL + CHECK). `VALID_RESET_PERIODS` / `DEFAULT_RESET_PERIOD` below are the
same values the migration and the `--check` gate enforce.

Deliberately dependency-free (stdlib only) so it can be imported by anything and
run standalone as a gate under either virtualenv.
"""
import logging
import os
import sys
from typing import Dict, FrozenSet, Iterable, List, Optional, Tuple

logger = logging.getLogger(__name__)

# Name of the Postgres enum that constrains user_subscriptions.tier and
# feature_gates.minimum_tier. The --check gate reads its labels from pg_enum.
SUBSCRIPTION_TIER_ENUM = "subscription_tier"

FREE_TIER = "free"

# Privilege ranking. Aligned with the sibling handlers this module was drifting
# from (api/v1/subscriptions/management.py, api/v1/subscriptions/webhooks.py,
# api/v1/subscriptions/retention.py, api/v1/notifications_endpoints.py all use
# free < premium < premium_plus < lifetime) plus `ultra`, the legacy name of the
# second paid tier — feature_gates still carries minimum_tier = 'ultra' rows
# (priority_support, trainer_mode, workout_sharing) and feature_gates has both a
# `premium_limit` and an `ultra_limit` column, so `ultra` ranks with its rename,
# `premium_plus`. Equal ranks are intentional: they are the same product tier.
TIER_RANK: Dict[str, int] = {
    "free": 0,
    "premium": 1,
    "premium_plus": 2,
    "ultra": 2,
    "lifetime": 3,
}

FREE_RANK: int = TIER_RANK[FREE_TIER]

# Derived, never hand-listed: anything ranked above free is a paying member.
PAID_TIERS: FrozenSet[str] = frozenset(
    tier for tier, rank in TIER_RANK.items() if rank > FREE_RANK
)
MIN_PAID_RANK: int = min(TIER_RANK[tier] for tier in PAID_TIERS)

# feature_gates.reset_period — enforced in the schema by migration 2380.
VALID_RESET_PERIODS: Tuple[str, ...] = ("daily", "monthly")
# 'daily' is the safest default for a metered gate: a mis-seeded row costs a user
# one day of the feature, never the lifetime cap a NULL used to produce.
DEFAULT_RESET_PERIOD = "daily"


def tier_rank(tier: Optional[str], context: str = "") -> int:
    """
    Privilege rank for a subscription tier.

    An unrecognised label is ranked at MIN_PAID_RANK (not 0) and logged at ERROR:
    `free` is known, so an unknown enum label is by construction a paid tier and
    must never be metered as free. Missing/empty tier (no user_subscriptions row)
    is a genuine free user.
    """
    if not tier:
        return FREE_RANK
    normalized = str(tier).strip().lower()
    rank = TIER_RANK.get(normalized)
    if rank is None:
        logger.error(
            "Unknown subscription tier %r%s is missing from "
            "core/feature_gate_policy.TIER_RANK — treating it as a paid tier. "
            "Add it to TIER_RANK and re-run the --check gate.",
            tier,
            f" ({context})" if context else "",
        )
        return MIN_PAID_RANK
    return rank


def is_paid_tier(tier: Optional[str]) -> bool:
    """True for every tier above free (premium, premium_plus, ultra, lifetime)."""
    return tier_rank(tier, context="user_subscriptions.tier") > FREE_RANK


def meets_minimum_tier(user_tier: Optional[str], minimum_tier: Optional[str]) -> bool:
    """
    Does `user_tier` satisfy a gate's `minimum_tier`?

    A NULL/empty minimum_tier means the gate is not tier-restricted. An unknown
    minimum_tier label is a paid tier that post-dates this map, so it requires at
    least MIN_PAID_RANK — free users are still blocked, paying members are not.
    """
    if not minimum_tier:
        return True
    return tier_rank(user_tier, context="user_subscriptions.tier") >= tier_rank(
        minimum_tier, context="feature_gates.minimum_tier"
    )


def normalize_reset_period(reset_period: Optional[str], feature_key: str = "") -> str:
    """
    Coerce a gate's reset_period onto VALID_RESET_PERIODS.

    Migration 2380 makes NULL/invalid impossible in the schema, so reaching the
    error branch means a row was written outside the constraint (or an in-code
    fallback table went stale). Loudly logged — and resolved to DEFAULT_RESET_PERIOD
    rather than the old "sum all-time usage" branch, which silently converted a
    daily free cap into a permanent one.
    """
    if reset_period:
        normalized = str(reset_period).strip().lower()
        if normalized in VALID_RESET_PERIODS:
            return normalized
    logger.error(
        "feature_gates.reset_period=%r is not one of %s for feature %r — "
        "falling back to %r. Fix the row; migration 2380 constrains this column.",
        reset_period,
        VALID_RESET_PERIODS,
        feature_key,
        DEFAULT_RESET_PERIOD,
    )
    return DEFAULT_RESET_PERIOD


def missing_tiers(enum_labels: Iterable[str]) -> List[str]:
    """Enum labels that TIER_RANK does not rank (empty list == map is complete)."""
    return sorted(label for label in enum_labels if label not in TIER_RANK)


def _check() -> int:
    """
    Gate: prove TIER_RANK covers the live subscription_tier enum and that no
    feature_gates row is enforced with a NULL/invalid reset_period or an unranked
    minimum_tier. Run after adding a subscription tier or a feature gate row:

        cd backend && set -a && source ./.env && set +a && \
          .venv/bin/python core/feature_gate_policy.py --check
    """
    import psycopg2  # local import: only the gate needs a DB driver

    dsn = os.environ["DATABASE_URL"].replace("postgresql+asyncpg://", "postgresql://")
    conn = psycopg2.connect(dsn)
    cur = conn.cursor()

    cur.execute(
        "SELECT e.enumlabel FROM pg_type t JOIN pg_enum e ON e.enumtypid = t.oid "
        "WHERE t.typname = %s ORDER BY e.enumsortorder",
        (SUBSCRIPTION_TIER_ENUM,),
    )
    labels = [row[0] for row in cur.fetchall()]
    if not labels:
        print(f"FAIL: enum {SUBSCRIPTION_TIER_ENUM} not found in the database")
        return 1

    failures = []
    absent = missing_tiers(labels)
    if absent:
        failures.append(
            f"subscription_tier labels missing from TIER_RANK: {absent} "
            f"(enum = {labels})"
        )

    cur.execute(
        "SELECT feature_key, minimum_tier, free_limit, reset_period, is_enabled "
        "FROM feature_gates ORDER BY feature_key"
    )
    rows = cur.fetchall()
    for feature_key, minimum_tier, free_limit, reset_period, is_enabled in rows:
        if reset_period is None or reset_period not in VALID_RESET_PERIODS:
            failures.append(
                f"feature_gates.{feature_key}: reset_period={reset_period!r} "
                f"not in {VALID_RESET_PERIODS} (a NULL period metered as an "
                f"all-time cap before migration 2380)"
            )
        if minimum_tier is not None and minimum_tier not in TIER_RANK:
            failures.append(
                f"feature_gates.{feature_key}: minimum_tier={minimum_tier!r} "
                f"is not ranked in TIER_RANK"
            )
    cur.close()
    conn.close()

    if failures:
        print("FAIL: feature gate policy drift")
        for failure in failures:
            print(f"  - {failure}")
        return 1

    print(
        f"OK: TIER_RANK covers all {len(labels)} subscription_tier labels "
        f"({', '.join(labels)}); {len(rows)} feature_gates rows have a valid "
        f"reset_period and a ranked minimum_tier"
    )
    return 0


if __name__ == "__main__":
    if "--check" in sys.argv:
        sys.exit(_check())
    print(__doc__)
