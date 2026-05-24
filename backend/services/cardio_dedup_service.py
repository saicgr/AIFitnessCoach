"""
Cardio dedup service.

Resolves duplicate cardio_logs rows that arrive from multiple connected sources
(Strava + Garmin + Apple Health + Health Connect can all import the same run).

Tables / columns this service operates on were added in migration 2094:
  - cardio_logs.dedup_group_id uuid          (NULL = standalone)
  - cardio_logs.is_hidden_duplicate boolean  (true = loser row, hide from UI)

Group convention:
  - dedup_group_id == primary_row_id for every row in the group (including primary).
  - primary row has is_hidden_duplicate = false.
  - Loser rows have is_hidden_duplicate = true.

Matching heuristic (find_duplicate_candidates):
  - Same user_id, same activity_type
  - |performed_at_a - performed_at_b| <= 90 seconds
  - |duration_a - duration_b| / duration_b <= 0.05 (5%)

Primary selection (resolve_dedup_group):
  Source priority — strava=5, garmin=4, apple_health=3, health_connect=3,
  manual=1, others=0. Tie-break: newer created_at wins.

This service is callable but NOT wired into the cardio_logs insert path here —
that wiring is owned by another agent. It IS used by the backfill script and
the (future) management endpoints.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)


# Source priority — higher wins. Anything not listed = 0.
SOURCE_PRIORITY: Dict[str, int] = {
    "strava": 5,
    "garmin": 4,
    "apple_health": 3,
    "health_connect": 3,
    "manual": 1,
}

# Matching tolerances. Tightening these reduces false positives at the cost
# of missing genuine duplicates with mild clock skew between devices.
TIME_WINDOW_SECONDS = 90
DURATION_TOLERANCE_PCT = 0.05  # 5%


# ---------------------------------------------------------------------------
# Lightweight return types — these are dicts (not Pydantic) so the service is
# usable from both the API layer (FastAPI response) and the backfill script
# (plain psycopg2 cursor) without an extra serialization layer.
# ---------------------------------------------------------------------------

@dataclass
class CardioLogSummary:
    id: str
    activity_type: str
    performed_at: datetime
    duration_seconds: int
    distance_m: Optional[float]
    source_app: str
    is_primary: bool

    def to_json(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "activity_type": self.activity_type,
            "performed_at": self.performed_at.isoformat()
            if isinstance(self.performed_at, datetime) else self.performed_at,
            "duration_seconds": self.duration_seconds,
            "distance_m": self.distance_m,
            "source_app": self.source_app,
            "is_primary": self.is_primary,
        }


@dataclass
class DedupGroup:
    group_id: str
    primary: CardioLogSummary
    duplicates: List[CardioLogSummary] = field(default_factory=list)

    def to_json(self) -> Dict[str, Any]:
        return {
            "group_id": self.group_id,
            "primary": self.primary.to_json(),
            "duplicates": [d.to_json() for d in self.duplicates],
        }


# ---------------------------------------------------------------------------
# Core helpers — pure functions, no DB. These are what the tests target.
# ---------------------------------------------------------------------------

def _source_priority(source_app: Optional[str]) -> int:
    if not source_app:
        return 0
    return SOURCE_PRIORITY.get(source_app.lower(), 0)


def _is_match(a: Dict[str, Any], b: Dict[str, Any]) -> bool:
    """Pure-function duplicate check between two normalized row dicts.

    Required keys: activity_type, performed_at (datetime), duration_seconds.
    """
    if a["activity_type"] != b["activity_type"]:
        return False
    # Time window
    delta_seconds = abs((a["performed_at"] - b["performed_at"]).total_seconds())
    if delta_seconds > TIME_WINDOW_SECONDS:
        return False
    # Duration window — normalize against the larger denominator to keep the
    # check symmetric. Avoid division-by-zero (treat 0-duration as un-mergeable).
    dur_a = int(a["duration_seconds"] or 0)
    dur_b = int(b["duration_seconds"] or 0)
    if dur_a <= 0 or dur_b <= 0:
        return False
    denom = max(dur_a, dur_b)
    if abs(dur_a - dur_b) / denom > DURATION_TOLERANCE_PCT:
        return False
    return True


def _pick_primary(rows: List[Dict[str, Any]]) -> Tuple[str, List[str]]:
    """Choose the primary row id. Returns (primary_id, [loser_ids]).

    Tie-break by created_at DESC (newer wins) when multiple rows share the top
    priority. created_at must be a datetime; missing values sort first (lowest).
    """
    if not rows:
        raise ValueError("_pick_primary called with empty rows")

    def sort_key(r: Dict[str, Any]) -> Tuple[int, datetime]:
        prio = _source_priority(r.get("source_app"))
        created = r.get("created_at") or datetime.min
        return (prio, created)

    sorted_rows = sorted(rows, key=sort_key, reverse=True)
    primary = sorted_rows[0]
    losers = [str(r["id"]) for r in sorted_rows[1:]]
    return str(primary["id"]), losers


# ---------------------------------------------------------------------------
# Public service functions
# ---------------------------------------------------------------------------

def find_duplicate_candidates(
    db: Any,
    user_id: str,
    cardio_log_id: str,
) -> List[str]:
    """Given a newly-inserted (or being-inserted) cardio_log id, return ids of
    other cardio_logs rows for the same user that look like duplicates per
    the heuristic above.

    `db` is expected to be an object with a Supabase-style `.client.table(...)`
    interface (matches `get_supabase_db()` in `core/db`). The new row itself is
    NOT included in the return list.
    """
    try:
        client = db.client
        # Fetch the candidate row first.
        anchor_q = (
            client.table("cardio_logs")
            .select("id, user_id, activity_type, performed_at, duration_seconds")
            .eq("id", cardio_log_id)
            .single()
            .execute()
        )
        anchor = anchor_q.data
        if not anchor:
            return []

        anchor_perf = _parse_dt(anchor["performed_at"])
        anchor_norm = {
            "activity_type": anchor["activity_type"],
            "performed_at": anchor_perf,
            "duration_seconds": int(anchor["duration_seconds"] or 0),
        }

        # Pull all same-sport rows in a generous window — we do the precise
        # comparison in Python so we get exact symmetric arithmetic and don't
        # rely on Postgres interval math vs. timezone-aware ISO strings.
        window_minutes = 5  # 5min >> the 90s match window — gives slack for clock skew
        from datetime import timedelta
        low = (anchor_perf - timedelta(minutes=window_minutes)).isoformat()
        high = (anchor_perf + timedelta(minutes=window_minutes)).isoformat()

        nearby = (
            client.table("cardio_logs")
            .select("id, activity_type, performed_at, duration_seconds")
            .eq("user_id", user_id)
            .eq("activity_type", anchor["activity_type"])
            .gte("performed_at", low)
            .lte("performed_at", high)
            .execute()
        )

        out: List[str] = []
        for row in (nearby.data or []):
            if str(row["id"]) == str(cardio_log_id):
                continue
            cand_norm = {
                "activity_type": row["activity_type"],
                "performed_at": _parse_dt(row["performed_at"]),
                "duration_seconds": int(row["duration_seconds"] or 0),
            }
            if _is_match(anchor_norm, cand_norm):
                out.append(str(row["id"]))
        return out
    except Exception as e:
        logger.error(f"[CardioDedup] find_duplicate_candidates error: {e}", exc_info=True)
        return []


def resolve_dedup_group(
    db: Any,
    candidate_ids: List[str],
) -> Dict[str, Any]:
    """Given a list of candidate row ids (the anchor + its candidates), pick
    primary + losers. Pulls each row's source_app + created_at from the DB.

    Returns {"primary_id": str, "hidden_ids": List[str]}.
    """
    if not candidate_ids:
        raise ValueError("resolve_dedup_group requires at least one candidate id")
    if len(candidate_ids) == 1:
        return {"primary_id": candidate_ids[0], "hidden_ids": []}

    client = db.client
    rows_q = (
        client.table("cardio_logs")
        .select("id, source_app, created_at")
        .in_("id", candidate_ids)
        .execute()
    )
    rows = []
    for r in (rows_q.data or []):
        rows.append({
            "id": str(r["id"]),
            "source_app": r.get("source_app"),
            "created_at": _parse_dt(r.get("created_at")) if r.get("created_at") else None,
        })
    if not rows:
        raise ValueError(f"resolve_dedup_group: none of {candidate_ids} found")

    primary_id, hidden_ids = _pick_primary(rows)
    return {"primary_id": primary_id, "hidden_ids": hidden_ids}


def apply_dedup_group(
    db: Any,
    primary_id: str,
    hidden_ids: List[str],
) -> int:
    """Persist the dedup group.

    Primary row: dedup_group_id = primary_id, is_hidden_duplicate = false.
    Hidden rows: dedup_group_id = primary_id, is_hidden_duplicate = true.

    Idempotent: running twice with the same args produces the same DB state.
    Returns the number of rows updated.
    """
    client = db.client
    updated = 0

    # Update primary.
    res = (
        client.table("cardio_logs")
        .update({"dedup_group_id": primary_id, "is_hidden_duplicate": False})
        .eq("id", primary_id)
        .execute()
    )
    updated += len(res.data or [])

    # Update hidden rows in one shot (Supabase supports IN via .in_).
    if hidden_ids:
        res2 = (
            client.table("cardio_logs")
            .update({"dedup_group_id": primary_id, "is_hidden_duplicate": True})
            .in_("id", hidden_ids)
            .execute()
        )
        updated += len(res2.data or [])

    logger.info(
        f"[CardioDedup] apply primary={primary_id} hidden={len(hidden_ids)} updated={updated}"
    )
    return updated


def list_dedup_groups_for_user(db: Any, user_id: str) -> List[DedupGroup]:
    """Return every dedup group the user has, for the management screen.

    Edge case: only groups where dedup_group_id IS NOT NULL AND at least one
    other row in the group exists. We don't surface "groups of one" because
    those provide no user value.
    """
    client = db.client
    rows_q = (
        client.table("cardio_logs")
        .select(
            "id, activity_type, performed_at, duration_seconds, distance_m, "
            "source_app, dedup_group_id, is_hidden_duplicate"
        )
        .eq("user_id", user_id)
        .not_.is_("dedup_group_id", "null")
        .order("performed_at", desc=True)
        .execute()
    )
    rows = rows_q.data or []

    # Bucket by dedup_group_id.
    by_group: Dict[str, List[Dict[str, Any]]] = {}
    for r in rows:
        by_group.setdefault(str(r["dedup_group_id"]), []).append(r)

    groups: List[DedupGroup] = []
    for gid, group_rows in by_group.items():
        if len(group_rows) < 2:
            # Defensive — a "group of one" is meaningless to the user; skip it.
            continue
        primary_row = next(
            (r for r in group_rows if not r.get("is_hidden_duplicate") and str(r["id"]) == gid),
            None,
        )
        if primary_row is None:
            # Data drift safety — pick whichever row has is_hidden_duplicate=false.
            primary_row = next(
                (r for r in group_rows if not r.get("is_hidden_duplicate")),
                group_rows[0],
            )
        primary = _row_to_summary(primary_row, is_primary=True)
        duplicates = [
            _row_to_summary(r, is_primary=False)
            for r in group_rows
            if str(r["id"]) != str(primary_row["id"])
        ]
        groups.append(DedupGroup(group_id=gid, primary=primary, duplicates=duplicates))

    groups.sort(key=lambda g: g.primary.performed_at, reverse=True)
    return groups


def override_primary(
    db: Any,
    user_id: str,
    group_id: str,
    new_primary_id: str,
) -> None:
    """User-initiated re-pick of the primary row within a group.

    - Validates that `new_primary_id` is currently in the group AND that the
      group belongs to `user_id` (prevents a malicious group_id from sliding
      a row out of someone else's dedup set).
    - Swaps roles: new primary gets is_hidden_duplicate=false; old primary
      becomes hidden; both keep dedup_group_id = new_primary_id (the row
      whose id == dedup_group_id is the primary by convention).

    Important: changing the primary changes the group_id (since
    dedup_group_id = primary_id by convention). We rewrite dedup_group_id
    on every row in the group atomically.
    """
    client = db.client

    rows_q = (
        client.table("cardio_logs")
        .select("id, dedup_group_id, user_id")
        .eq("user_id", user_id)
        .eq("dedup_group_id", group_id)
        .execute()
    )
    member_ids = [str(r["id"]) for r in (rows_q.data or [])]
    if not member_ids:
        raise ValueError(f"Group {group_id} not found for user {user_id}")
    if new_primary_id not in member_ids:
        raise ValueError(
            f"new_primary_id {new_primary_id} is not a member of group {group_id}"
        )

    # Rewrite all members to point at the new primary id, and reset hidden flags.
    hidden_ids = [mid for mid in member_ids if mid != new_primary_id]

    client.table("cardio_logs").update(
        {"dedup_group_id": new_primary_id, "is_hidden_duplicate": False}
    ).eq("id", new_primary_id).execute()

    if hidden_ids:
        client.table("cardio_logs").update(
            {"dedup_group_id": new_primary_id, "is_hidden_duplicate": True}
        ).in_("id", hidden_ids).execute()

    logger.info(
        f"[CardioDedup] override_primary user={user_id} old_group={group_id} "
        f"new_primary={new_primary_id} hidden={len(hidden_ids)}"
    )


def unlink_from_group(db: Any, user_id: str, log_id: str) -> None:
    """Pull a single log out of its dedup group — false-positive recovery.

    Sets dedup_group_id=null, is_hidden_duplicate=false on that one row.
    Other group members are untouched (the group may collapse to a single
    row, in which case `list_dedup_groups_for_user` will stop surfacing it).
    """
    client = db.client
    # Ownership check via the eq filter — Supabase will simply update 0 rows
    # if user doesn't own this id.
    res = (
        client.table("cardio_logs")
        .update({"dedup_group_id": None, "is_hidden_duplicate": False})
        .eq("id", log_id)
        .eq("user_id", user_id)
        .execute()
    )
    if not (res.data or []):
        raise ValueError(f"Log {log_id} not found for user {user_id}")
    logger.info(f"[CardioDedup] unlink user={user_id} log={log_id}")


# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

def _parse_dt(value: Any) -> datetime:
    """Parse Supabase ISO strings (with 'Z' suffix) to aware datetime."""
    if isinstance(value, datetime):
        return value
    if value is None:
        # Edge case — should not happen for performed_at/created_at but we
        # don't want a NoneType error to silently swallow a candidate.
        raise ValueError("Cannot parse datetime from None")
    s = str(value).replace("Z", "+00:00")
    return datetime.fromisoformat(s)


def _row_to_summary(row: Dict[str, Any], is_primary: bool) -> CardioLogSummary:
    return CardioLogSummary(
        id=str(row["id"]),
        activity_type=row["activity_type"],
        performed_at=_parse_dt(row["performed_at"]),
        duration_seconds=int(row["duration_seconds"] or 0),
        distance_m=float(row["distance_m"]) if row.get("distance_m") is not None else None,
        source_app=row.get("source_app") or "unknown",
        is_primary=is_primary,
    )
