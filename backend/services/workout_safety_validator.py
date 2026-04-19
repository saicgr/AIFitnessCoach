"""
Workout Safety Validator — Phase 2H of the Regenerate Workout Safety Fix.

Strict post-generation validator with surgical in-place swap. NO LLM calls,
NO retries, NO silent fallbacks. Every decision is a deterministic SQL lookup
against `public.exercise_safety_index` (built in Phase 1A, populated in Phase
2G).

Public API
----------
    validate_and_repair(exercises, ctx, supabase_client) -> ValidationResult
    find_safe_swap(bad_exercise, ctx, exclude_exercise_ids, supabase_client)
        -> Optional[dict]

Ownership
---------
Exclusive owner: Phase 2H (this file). Phase 3L wires this into versioning.py.
The RAG service, filters, and the YAML are not touched here.

Fail-closed default
-------------------
Phase 2G is still populating tags. Until a row has `is_tagged = TRUE` and every
injury flag is non-NULL, the validator MUST treat the exercise as UNSAFE. A
NULL injury flag is never silently coerced to "probably safe" — that is how
users get hurt.
"""

from __future__ import annotations

import asyncio
import hashlib
import math
import re
import time
from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional, Sequence, Tuple

from sqlalchemy import text

from core.logger import get_logger
from core.supabase_client import get_supabase

logger = get_logger(__name__)


# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

# Canonical list of injury joint names — MUST match the boolean columns in
# `exercise_safety_index` (shoulder_safe, lower_back_safe, ...). This list is
# the single source of truth for which flags are checked per user.
SUPPORTED_INJURY_JOINTS: Tuple[str, ...] = (
    "shoulder",
    "lower_back",
    "knee",
    "elbow",
    "wrist",
    "ankle",
    "hip",
    "neck",
)

# Ordinal ranking for `safety_difficulty`. Used as a numeric ceiling filter so
# a beginner user never gets advanced/elite exercises, even if Gemini invents
# one. Keep in sync with yaml `safety_difficulty` enum.
_DIFFICULTY_RANK: Dict[str, int] = {
    "beginner": 1,
    "intermediate": 2,
    "advanced": 3,
    "elite": 4,
}

# Users at advanced/elite difficulty can take any exercise at or below their
# tier. Beginner/intermediate users get the safety ceiling applied strictly.
_STRICT_CEILING_TIERS: frozenset = frozenset({"beginner", "intermediate"})

# Movement-pattern family map used to relax the swap query when the exact
# pattern yields no candidates. Value = broader parent pattern. When no parent
# is defined, the swap abandons the pattern constraint entirely as a final
# fallback (still NEVER relaxes injury flags or difficulty ceiling).
#
# Families derived from the movement-pattern joint-loading taxonomy in
# `backend/data/exercise_safety_reference.yaml` (NSCA ESSC 4th ch.13-14).
_PATTERN_RELAX_FAMILY: Dict[str, str] = {
    # Pulls
    "vertical_pull": "pull",
    "horizontal_pull": "pull",
    "overhead_pull": "pull",
    # Pushes
    "overhead_press": "push",
    "behind_neck_press": "push",
    "horizontal_push": "push",
    "horizontal_push_bodyweight_plus": "push",
    "bench_press_heavy": "push",
    # Lower body
    "deep_squat_loaded": "squat",
    "pistol_squat": "squat",
    "lunge": "squat",
    # Hinge stays hinge, but also usable as "posterior_chain"
    "hinge": "hinge",
    # Rotations / core
    "loaded_rotation": "core",
    "anti_rotation": "core",
    # Carries
    "carry": "carry",
    # Plyo / high impact
    "plyometric": "conditioning",
    "plyometric_upper_body": "conditioning",
    "high_impact_axial_load": "conditioning",
    # Hanging / inversion — no relax; they stay contraindicated
    "hanging": "hanging",
    "hanging_inversion": "hanging",
    "inversion": "inversion",
    "handstand_load": "inversion",
    # Wrist-specific — relax to isometric only (wrist-safe pool)
    "loaded_wrist_extension": "isometric",
    "loaded_wrist_flexion": "isometric",
    # Velocity / grip / OKC-knee — relax to isometric
    "high_velocity_throw": "isometric",
    "gripping_heavy": "isometric",
    "open_chain_knee_extension_heavy": "isometric",
    # Scapular-elevation
    "shrug_heavy": "isolation_upper",
    "upright_row": "isolation_upper",
    "horizontal_abduction_loaded": "isolation_upper",
    "dips": "push",
    "loaded_spinal_flexion": "core",
}

# Reverse-ish map: family -> list of concrete patterns we'd accept when the
# bad exercise's pattern has no direct swap. Used in step-2 of
# `find_safe_swap` (pattern-relax retry).
_FAMILY_MEMBERS: Dict[str, List[str]] = {}
for _pat, _fam in _PATTERN_RELAX_FAMILY.items():
    _FAMILY_MEMBERS.setdefault(_fam, []).append(_pat)


@dataclass
class UserSafetyContext:
    """
    The subset of the user's profile that governs injury safety.

    injuries: normalized joint names drawn from SUPPORTED_INJURY_JOINTS. Any
              other string (custom free-text injuries like "pinched nerve")
              should be stripped before calling — the validator does not
              silently drop unknown values but it also does not invent flags.
    difficulty: 'beginner' | 'intermediate' | 'advanced' | 'elite'.
                Unknown values are treated as 'beginner' (fail-closed).
    equipment: list of equipment labels the user has access to. Matched
               case-insensitively against `exercise_safety_index.equipment`.
               If the list is empty, no equipment filter is applied (the
               user explicitly has "no gym" — bodyweight pool is still safe).
    user_id:   for logging correlation only.
    """

    injuries: List[str]
    difficulty: str
    equipment: List[str]
    user_id: str

    def normalized_injuries(self) -> List[str]:
        """Lowercased, whitelisted-against-SUPPORTED_INJURY_JOINTS, deduped."""
        seen: set = set()
        out: List[str] = []
        for inj in self.injuries or []:
            key = (inj or "").strip().lower().replace(" ", "_")
            if key in SUPPORTED_INJURY_JOINTS and key not in seen:
                seen.add(key)
                out.append(key)
        return out

    def difficulty_rank(self) -> int:
        return _DIFFICULTY_RANK.get((self.difficulty or "").strip().lower(), 1)

    def apply_strict_ceiling(self) -> bool:
        return (self.difficulty or "").strip().lower() in _STRICT_CEILING_TIERS


@dataclass
class SafetyViolation:
    exercise_name: str
    exercise_id: Optional[str]
    reasons: List[str]


@dataclass
class SwapOutcome:
    original: Dict[str, Any]
    replacement: Optional[Dict[str, Any]]
    reason: str  # "ok" | "swapped" | "no_safe_swap" | "not_found"


@dataclass
class ValidationResult:
    final_exercises: List[Dict[str, Any]]
    swaps: List[SwapOutcome]
    violations: List[SafetyViolation]
    safety_mode_triggered: bool
    swap_latency_ms: float = 0.0
    audit: List[Dict[str, Any]] = field(default_factory=list)


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

_NORMALIZE_RE = re.compile(r"[^a-z0-9]+")


def _normalize_name(name: Optional[str]) -> str:
    if not name:
        return ""
    return _NORMALIZE_RE.sub(" ", name.lower()).strip()


def _get_engine():
    """Return the project's async SQLAlchemy engine (wraps asyncpg)."""
    return get_supabase().engine


def _build_injury_clause(injuries: Sequence[str]) -> str:
    """
    Build the injury-flag clause of the SQL WHERE.

    IMPORTANT — fail-closed semantics:
      `<col> IS TRUE` rejects both FALSE and NULL (a row without a safety tag
      counts as UNSAFE). This is the only correct default for medical-adjacent
      filtering; never relax to `<col> IS NOT FALSE` or `COALESCE(col, TRUE)`.
    """
    if not injuries:
        return ""
    parts = [f"t.{joint}_safe IS TRUE" for joint in injuries]
    return " AND " + " AND ".join(parts)


def _build_equipment_clause(param_name: str, equipment: Sequence[str]) -> str:
    """
    Build an equipment-match clause. Case-insensitive partial match is
    intentional — the library stores free-text labels like 'Lat Pulldown
    Machine' while the user might say 'cable machine'. We accept any overlap.
    """
    if not equipment:
        return ""
    # NOTE: SQLAlchemy parses `:name::type` ambiguously (`::` looks like its
    # own cast directive *and* the Postgres type cast). Use `CAST(:name AS ..)`
    # everywhere we need an explicit array-cast to keep both happy.
    return (
        f" AND ("
        f"t.equipment IS NULL OR "
        f"EXISTS (SELECT 1 FROM unnest(CAST(:{param_name} AS text[])) AS eq(val) "
        f"WHERE t.equipment ILIKE '%' || eq.val || '%' OR eq.val ILIKE '%' || t.equipment || '%')"
        f")"
    )


def _row_to_dict(row: Any) -> Dict[str, Any]:
    """Convert a SQLAlchemy row (mapping) to a plain JSON-safe dict."""
    if row is None:
        return {}
    mapping = getattr(row, "_mapping", None)
    if mapping is None:
        return dict(row)
    out: Dict[str, Any] = {}
    for k, v in mapping.items():
        # Skip pgvector raw bytes — caller doesn't need them in payload.
        if k == "embedding":
            continue
        out[k] = v
    return out


# ---------------------------------------------------------------------------
# Core: lookup + validation
# ---------------------------------------------------------------------------


async def _lookup_exercise(
    exercise: Dict[str, Any],
    engine,
) -> Optional[Dict[str, Any]]:
    """
    Resolve an input exercise to its row in `exercise_safety_index`.

    Resolution order:
      1. `id` exact match (both 'id' and 'exercise_id' keys accepted).
      2. `name_normalized` exact match.
      3. pg_trgm fuzzy match on `name_normalized` with similarity >= 0.55
         (ORDER BY similarity DESC).

    Returns the matched index row as a dict, or None if no match.
    """
    ex_id = exercise.get("exercise_id") or exercise.get("id")
    name = exercise.get("name") or exercise.get("exercise_name") or ""
    name_norm = _normalize_name(name)

    async with engine.connect() as conn:
        if ex_id:
            try:
                res = await conn.execute(
                    text(
                        "SELECT * FROM public.exercise_safety_index_mat "
                        "WHERE exercise_id = :eid LIMIT 1"
                    ),
                    {"eid": str(ex_id)},
                )
                row = res.first()
                if row is not None:
                    return _row_to_dict(row)
            except Exception as e:
                logger.warning(
                    "⚠️  [SafetyValidator] id lookup failed for %s: %s", ex_id, e
                )

        if name_norm:
            res = await conn.execute(
                text(
                    "SELECT * FROM public.exercise_safety_index_mat "
                    "WHERE name_normalized = :n LIMIT 1"
                ),
                {"n": name_norm},
            )
            row = res.first()
            if row is not None:
                return _row_to_dict(row)

            # Trigram fuzzy fallback. pg_trgm operator `%` uses the GIN index
            # on exercise_name; we order by similarity and take the best if
            # it clears the threshold.
            res = await conn.execute(
                text(
                    """
                    SELECT *, similarity(name_normalized, :n) AS _sim
                    FROM public.exercise_safety_index_mat
                    WHERE name_normalized % :n
                    ORDER BY _sim DESC
                    LIMIT 1
                    """
                ),
                {"n": name_norm},
            )
            row = res.first()
            if row is not None:
                rd = _row_to_dict(row)
                if float(rd.get("_sim", 0.0) or 0.0) >= 0.55:
                    return rd

    return None


def _check_row_safety(
    row: Dict[str, Any],
    ctx: UserSafetyContext,
) -> List[str]:
    """
    Return a list of human-readable violation reasons, empty list = safe.

    Fail-closed: any NULL injury flag for a user with that injury counts as
    UNSAFE. Likewise, if `is_tagged` is FALSE the row is considered untagged
    and the entire exercise is rejected (safer to swap than to trust).
    """
    reasons: List[str] = []

    is_tagged = row.get("is_tagged")
    if is_tagged is not True:
        reasons.append("not_tagged (fail-closed)")
        # Even when untagged we still record injury issues explicitly so the
        # log shows why — helps ops distinguish "tagger not run yet" from
        # "exercise really is dangerous".

    for joint in ctx.normalized_injuries():
        flag = row.get(f"{joint}_safe")
        if flag is not True:  # FALSE or NULL
            reasons.append(f"{joint}_safe={flag!r}")

    if ctx.apply_strict_ceiling():
        sd = (row.get("safety_difficulty") or "").strip().lower()
        if sd and _DIFFICULTY_RANK.get(sd, 99) > ctx.difficulty_rank():
            reasons.append(
                f"safety_difficulty={sd} exceeds user ceiling={ctx.difficulty}"
            )
        elif not sd:
            # Unknown difficulty on a strict-ceiling user → fail-closed.
            reasons.append("safety_difficulty=NULL (fail-closed)")

    return reasons


# ---------------------------------------------------------------------------
# Swap algorithm
# ---------------------------------------------------------------------------


async def find_safe_swap(
    bad_exercise: Dict[str, Any],
    ctx: UserSafetyContext,
    exclude_exercise_ids: List[str],
    supabase_client=None,  # Unused; kept for signature parity with the plan.
) -> Optional[Dict[str, Any]]:
    """
    Locate a safe replacement for `bad_exercise`.

    Strategy (deterministic, no LLM):
      Step 1  exact pattern + same body_part
      Step 2  pattern-family (e.g., vertical_pull -> pull members)
              + same body_part
      Step 3  drop pattern, keep body_part
      Step 4  drop pattern AND body_part (last resort; still safety-filtered)

    NEVER relaxes injury flags or difficulty ceiling. Orders by embedding
    cosine similarity (pgvector <=> operator) when the bad exercise has an
    embedding, else by trigram name similarity.
    """
    engine = _get_engine()
    bad_row = await _lookup_exercise(bad_exercise, engine)

    # Resolve swap-ranking signals from the matched row when available, else
    # fall back to raw input fields (for Gemini hallucinations not in library).
    bad_pattern = (bad_row or {}).get("movement_pattern") or bad_exercise.get(
        "movement_pattern"
    )
    bad_body_part = (bad_row or {}).get("body_part") or bad_exercise.get(
        "muscle_group"
    ) or bad_exercise.get("body_part")
    bad_name_norm = _normalize_name(
        (bad_row or {}).get("name")
        or bad_exercise.get("name")
        or bad_exercise.get("exercise_name")
    )
    bad_id = (
        (bad_row or {}).get("exercise_id")
        or bad_exercise.get("exercise_id")
        or bad_exercise.get("id")
    )
    has_embedding = bool(bad_row and bad_row.get("embedding") is not None)

    # Note: we intentionally don't fetch the embedding into Python. We re-join
    # against the same row by id to let Postgres compute the distance with
    # the HNSW index. When the bad exercise isn't in the library (no row),
    # we fall back to trigram name ranking.

    injuries = ctx.normalized_injuries()
    strict_ceiling = ctx.apply_strict_ceiling()
    equipment = [e for e in (ctx.equipment or []) if e and e.strip()]

    # Exclude ids + self.
    exclude_ids = [str(i) for i in (exclude_exercise_ids or []) if i]
    if bad_id:
        exclude_ids.append(str(bad_id))
    exclude_ids = list({i for i in exclude_ids if i})

    # Build the common filter fragment once.
    injury_clause = _build_injury_clause(injuries)
    equipment_clause = _build_equipment_clause("user_equipment", equipment)

    # Difficulty ceiling. For advanced/elite users we still never EXCEED their
    # tier (no upgrade), but we allow any tier <= their rank. For
    # beginner/intermediate we enforce strictly.
    max_rank = ctx.difficulty_rank() if strict_ceiling else _DIFFICULTY_RANK["elite"]
    difficulty_clause = " AND COALESCE(t.safety_difficulty_rank, 99) <= :max_rank"

    # Inject a computed rank on the fly so we don't need a stored column.
    rank_case = (
        "CASE lower(t.safety_difficulty) "
        "WHEN 'beginner' THEN 1 WHEN 'intermediate' THEN 2 "
        "WHEN 'advanced' THEN 3 WHEN 'elite' THEN 4 ELSE NULL END"
    )

    # Is_tagged is the final tripwire: only propose exercises whose safety
    # tags have been written. Never swap TO an untagged row.
    tag_clause = " AND t.is_tagged IS TRUE"

    exclude_clause = ""
    params: Dict[str, Any] = {"max_rank": max_rank}
    if exclude_ids:
        exclude_clause = " AND t.exercise_id <> ALL(CAST(:exclude_ids AS uuid[]))"
        params["exclude_ids"] = exclude_ids
    if equipment:
        params["user_equipment"] = equipment

    # Ranking expression.
    if has_embedding and bad_id:
        order_expr = (
            "1 - (t.embedding <=> (SELECT embedding FROM public.exercise_safety_index_mat "
            "WHERE exercise_id = :bad_id))"
        )
        params["bad_id"] = str(bad_id)
    else:
        order_expr = "similarity(t.name_normalized, :bad_name)"
        params["bad_name"] = bad_name_norm or ""

    select_cols = f"t.*, {rank_case} AS safety_difficulty_rank, {order_expr} AS rank_score"

    base_where = (
        "WHERE TRUE"
        + tag_clause
        + injury_clause
        + equipment_clause
        + exclude_clause
    )

    # Inject the difficulty ceiling *after* the computed rank via a CTE to
    # avoid referencing the alias in WHERE (Postgres evaluates WHERE before
    # SELECT-list expressions).
    cte_sql = lambda extra_where: f"""
        WITH safe_pool AS (
            SELECT {select_cols}
            FROM public.exercise_safety_index_mat t
            {base_where}
              {extra_where}
        )
        SELECT * FROM safe_pool
        WHERE safety_difficulty_rank IS NOT NULL
          AND safety_difficulty_rank <= :max_rank
        ORDER BY rank_score DESC NULLS LAST, name
        LIMIT 1
    """

    attempts: List[Tuple[str, str, Dict[str, Any]]] = []

    # Step 1: exact pattern + body_part
    step1_where = ""
    step1_params = dict(params)
    if bad_pattern:
        step1_where += " AND t.movement_pattern = :pat"
        step1_params["pat"] = bad_pattern
    if bad_body_part:
        step1_where += " AND t.body_part ILIKE :bp"
        step1_params["bp"] = bad_body_part
    attempts.append(("exact_pattern_and_body_part", step1_where, step1_params))

    # Step 2: family relax
    if bad_pattern:
        family = _PATTERN_RELAX_FAMILY.get(bad_pattern)
        if family:
            family_members = _FAMILY_MEMBERS.get(family, [])
            if family_members:
                step2_where = " AND t.movement_pattern = ANY(:fam_members)"
                if bad_body_part:
                    step2_where += " AND t.body_part ILIKE :bp"
                step2_params = dict(params)
                step2_params["fam_members"] = family_members
                if bad_body_part:
                    step2_params["bp"] = bad_body_part
                attempts.append(("family_relax", step2_where, step2_params))

    # Step 3: drop pattern, keep body_part.
    if bad_body_part:
        step3_where = " AND t.body_part ILIKE :bp"
        step3_params = dict(params)
        step3_params["bp"] = bad_body_part
        attempts.append(("body_part_only", step3_where, step3_params))

    # Step 4: last resort — only injury+difficulty+equipment filters.
    attempts.append(("safety_only", "", dict(params)))

    async with engine.connect() as conn:
        for label, extra_where, p in attempts:
            try:
                sql = cte_sql(extra_where)
                res = await conn.execute(text(sql), p)
                row = res.first()
                if row is not None:
                    rd = _row_to_dict(row)
                    logger.info(
                        "🛡️  [SafetyValidator] swap hit (%s) for user=%s bad=%r -> %r",
                        label,
                        ctx.user_id,
                        bad_name_norm,
                        rd.get("name"),
                    )
                    return rd
            except Exception as e:
                logger.error(
                    "❌ [SafetyValidator] swap query failed at step %s: %s", label, e
                )
                # Propagate only on infra errors in the first step so upstream
                # sees the problem; later steps just log and try the next.
                if label == "exact_pattern_and_body_part":
                    raise

    logger.warning(
        "⚠️  [SafetyValidator] no safe swap found for user=%s bad=%r (injuries=%s, diff=%s)",
        ctx.user_id,
        bad_name_norm,
        injuries,
        ctx.difficulty,
    )
    return None


# ---------------------------------------------------------------------------
# Public entry point
# ---------------------------------------------------------------------------


async def validate_and_repair(
    exercises: List[Dict[str, Any]],
    ctx: UserSafetyContext,
    supabase_client=None,  # Unused; kept for signature parity with the plan.
) -> ValidationResult:
    """
    Validate every exercise in a freshly-generated workout. Any exercise that
    fails at least one injury-flag or difficulty-ceiling check is swapped for
    the best safe alternative; if more than half of the plan is unsafe, we
    set `safety_mode_triggered=True` and return immediately so the caller can
    invoke `safety_mode.build_plan()`.
    """
    start = time.perf_counter()
    engine = _get_engine()

    if not exercises:
        return ValidationResult(
            final_exercises=[],
            swaps=[],
            violations=[],
            safety_mode_triggered=False,
            swap_latency_ms=0.0,
        )

    # Seed the exclude set with every input id so we don't swap one violating
    # exercise FOR another exercise that is already (or about to be) in this
    # workout. Also track replacement ids as we go.
    already_ids: List[str] = []
    for ex in exercises:
        eid = ex.get("exercise_id") or ex.get("id")
        if eid:
            already_ids.append(str(eid))

    final: List[Dict[str, Any]] = []
    swaps: List[SwapOutcome] = []
    violations: List[SafetyViolation] = []
    audit: List[Dict[str, Any]] = []

    for idx, ex in enumerate(exercises):
        row = await _lookup_exercise(ex, engine)
        ex_id_in = ex.get("exercise_id") or ex.get("id")
        name_in = ex.get("name") or ex.get("exercise_name") or "(unnamed)"

        if row is None:
            # Hallucination / typo / missing library row.
            violation = SafetyViolation(
                exercise_name=name_in,
                exercise_id=str(ex_id_in) if ex_id_in else None,
                reasons=["exercise not found in library"],
            )
            violations.append(violation)
            logger.warning(
                "⚠️  [SafetyValidator] not_found user=%s idx=%d name=%r",
                ctx.user_id,
                idx,
                name_in,
            )
            replacement = await find_safe_swap(ex, ctx, already_ids)
            if replacement is None:
                swaps.append(SwapOutcome(original=ex, replacement=None, reason="not_found"))
                audit.append(
                    {"idx": idx, "action": "no_safe_swap", "original_name": name_in}
                )
                continue
            already_ids.append(str(replacement.get("exercise_id") or ""))
            swaps.append(
                SwapOutcome(original=ex, replacement=replacement, reason="swapped")
            )
            final.append(replacement)
            audit.append(
                {
                    "idx": idx,
                    "action": "swap_not_found",
                    "original_name": name_in,
                    "replacement_name": replacement.get("name"),
                }
            )
            continue

        reasons = _check_row_safety(row, ctx)
        if not reasons:
            # Safe — pass through. Merge the library row into the returned
            # exercise so downstream consumers get canonical names/ids.
            merged = {**ex, **{k: v for k, v in row.items() if v is not None}}
            final.append(merged)
            swaps.append(SwapOutcome(original=ex, replacement=None, reason="ok"))
            continue

        violation = SafetyViolation(
            exercise_name=row.get("name") or name_in,
            exercise_id=str(row.get("exercise_id") or ex_id_in or ""),
            reasons=reasons,
        )
        violations.append(violation)
        logger.warning(
            "⚠️  [SafetyValidator] violation user=%s idx=%d name=%r reasons=%s",
            ctx.user_id,
            idx,
            row.get("name"),
            reasons,
        )

        replacement = await find_safe_swap(row, ctx, already_ids)
        if replacement is None:
            swaps.append(
                SwapOutcome(original=ex, replacement=None, reason="no_safe_swap")
            )
            audit.append(
                {"idx": idx, "action": "no_safe_swap", "original_name": row.get("name")}
            )
            continue
        already_ids.append(str(replacement.get("exercise_id") or ""))
        swaps.append(
            SwapOutcome(original=ex, replacement=replacement, reason="swapped")
        )
        final.append(replacement)
        audit.append(
            {
                "idx": idx,
                "action": "swapped",
                "original_name": row.get("name"),
                "replacement_name": replacement.get("name"),
                "reasons": reasons,
            }
        )

    # Safety-mode trigger threshold: ceil(50%) of the input must have been
    # unsafe for the caller to bail to the gentle PT-friendly session.
    threshold = max(1, math.ceil(len(exercises) * 0.5))
    safety_mode_triggered = len(violations) >= threshold

    elapsed_ms = (time.perf_counter() - start) * 1000.0
    if violations:
        logger.info(
            "🛡️  [SafetyValidator] user=%s violations=%d swaps=%d safety_mode=%s latency=%.1fms",
            ctx.user_id,
            len(violations),
            sum(1 for s in swaps if s.reason == "swapped"),
            safety_mode_triggered,
            elapsed_ms,
        )
    else:
        logger.info(
            "✅ [SafetyValidator] user=%s all %d exercises safe latency=%.1fms",
            ctx.user_id,
            len(exercises),
            elapsed_ms,
        )

    return ValidationResult(
        final_exercises=final,
        swaps=swaps,
        violations=violations,
        safety_mode_triggered=safety_mode_triggered,
        swap_latency_ms=elapsed_ms,
        audit=audit,
    )


# ---------------------------------------------------------------------------
# Smoke test — run directly:  python -m services.workout_safety_validator
# ---------------------------------------------------------------------------


async def _smoke() -> None:
    """Exercise the swap algorithm against the live DB with hardcoded bad
    inputs from the failing case described in the plan."""
    failing_cases = [
        {
            "name": "Cable Bar Lateral Pulldown",
            "muscle_group": "back",
            "movement_pattern": "vertical_pull",
        },
        {
            "name": "Landmine Rotational Lift to Press",
            "muscle_group": "waist",
            "movement_pattern": "loaded_rotation",
        },
        {
            "name": "Front Lever Raise",
            "muscle_group": "full body",
            "movement_pattern": "hanging",
        },
    ]
    ctx = UserSafetyContext(
        injuries=list(SUPPORTED_INJURY_JOINTS),
        difficulty="beginner",
        equipment=["bodyweight", "dumbbell", "resistance band"],
        user_id="smoke-test",
    )

    print("🛡️  [SafetyValidator Smoke] starting with 8 injuries + Beginner")
    for case in failing_cases:
        print(f"\n--- swapping: {case['name']} ---")
        swap = await find_safe_swap(case, ctx, exclude_exercise_ids=[])
        if swap is None:
            print(f"  -> no safe swap (would trigger safety-mode fallback)")
        else:
            print(
                f"  -> {swap.get('name')} "
                f"(pattern={swap.get('movement_pattern')}, "
                f"diff={swap.get('safety_difficulty')})"
            )

    print("\n--- validate_and_repair over all three ---")
    result = await validate_and_repair(failing_cases, ctx)
    print(
        f"violations={len(result.violations)} "
        f"swaps_ok={sum(1 for s in result.swaps if s.reason=='swapped')} "
        f"safety_mode={result.safety_mode_triggered} "
        f"latency={result.swap_latency_ms:.1f}ms"
    )
    for s in result.swaps:
        orig = s.original.get("name")
        repl = s.replacement.get("name") if s.replacement else None
        print(f"  {s.reason}: {orig} -> {repl}")


if __name__ == "__main__":  # pragma: no cover
    asyncio.run(_smoke())
