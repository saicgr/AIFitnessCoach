"""
API endpoints for leaderboard system.

Endpoints:
- GET /leaderboard - Get leaderboard data
- GET /rank - Get user's rank
- GET /unlock-status - Check if user has unlocked leaderboard
- GET /stats - Get overall leaderboard statistics
- POST /async-challenge - Create async "Beat Their Best" challenge
"""

from fastapi import APIRouter, Depends, HTTPException, Query
from core.auth import get_current_user
from core.exceptions import safe_internal_error
from typing import Optional
from datetime import datetime, timezone, timedelta

from models.leaderboard import (
    GetLeaderboardRequest, GetUserRankRequest,
    LeaderboardEntry, UserRank, LeaderboardResponse,
    LeaderboardUnlockStatus, LeaderboardStats,
    AsyncChallengeRequest, AsyncChallengeResponse,
    LeaderboardType, LeaderboardFilter,
)
from services.leaderboard_service import LeaderboardService

router = APIRouter(prefix="/leaderboard")
leaderboard_service = LeaderboardService()


# ============================================================
# GET LEADERBOARD
# ============================================================

@router.get("/", response_model=LeaderboardResponse)
async def get_leaderboard(
    user_id: str,
    leaderboard_type: LeaderboardType = Query(LeaderboardType.challenge_masters),
    filter_type: LeaderboardFilter = Query(LeaderboardFilter.global_lb),
    country_code: Optional[str] = Query(None),
    limit: int = Query(100, ge=1, le=500),
    offset: int = Query(0, ge=0),
    current_user: dict = Depends(get_current_user),
):
    """
    Get leaderboard data with filtering and pagination.

    Args:
        user_id: Requesting user ID (for friend filtering and rank display)
        leaderboard_type: Type of leaderboard (challenge_masters, volume_kings, etc.)
        filter_type: Filter (global, country, friends)
        country_code: ISO country code (required if filter=country)
        limit: Number of entries to return
        offset: Offset for pagination

    Returns:
        Leaderboard data with user's rank
    """
    # Check unlock status — migration 1939: friends scope unlocks at 1 workout,
    # global/country still require 10.
    scope_str = "friends" if filter_type == LeaderboardFilter.friends else \
                ("country" if filter_type == LeaderboardFilter.country else "global")
    unlock_status = leaderboard_service.check_unlock_status(user_id, scope=scope_str)
    is_unlocked = unlock_status.get("is_unlocked", False)

    if not is_unlocked:
        raise HTTPException(
            status_code=403,
            detail=f"Complete {unlock_status.get('workouts_needed', 10)} more workouts to unlock this leaderboard"
        )

    # Validate country filter
    if filter_type == LeaderboardFilter.country and not country_code:
        raise HTTPException(status_code=400, detail="country_code required for country filter")

    # Get leaderboard entries from service
    result = leaderboard_service.get_leaderboard_entries(
        leaderboard_type=leaderboard_type,
        filter_type=filter_type,
        user_id=user_id,
        country_code=country_code,
        limit=limit,
        offset=offset,
    )

    entries_data = result["entries"]
    total_entries = result["total"]

    # Handle empty results
    if not entries_data:
        return LeaderboardResponse(
            leaderboard_type=leaderboard_type,
            filter_type=filter_type,
            country_code=country_code,
            entries=[],
            total_entries=0,
            limit=limit,
            offset=offset,
            has_more=False,
            last_updated=datetime.now(timezone.utc),
        )

    # Get friend IDs for flags
    friend_ids_set = set(leaderboard_service._get_friend_ids(user_id))

    # Convert to LeaderboardEntry models
    entries = []
    for idx, entry in enumerate(entries_data):
        rank = offset + idx + 1
        is_friend = entry["user_id"] in friend_ids_set
        is_current_user = entry["user_id"] == user_id

        entries.append(_build_leaderboard_entry(
            entry, rank, leaderboard_type, is_friend, is_current_user
        ))

    # Get user's rank
    user_rank_data = leaderboard_service.get_user_rank(
        user_id=user_id,
        leaderboard_type=leaderboard_type,
        country_filter=country_code if filter_type == LeaderboardFilter.country else None,
    )

    user_rank = None
    if user_rank_data:
        rank_info = user_rank_data["rank_info"]
        stats = user_rank_data["stats"]
        user_stats = _build_leaderboard_entry(stats, rank_info["rank"], leaderboard_type, False, True)
        user_rank = UserRank(
            user_id=user_id,
            rank=rank_info["rank"],
            total_users=rank_info["total_users"],
            percentile=rank_info["percentile"],
            user_stats=user_stats,
        )

    # Calculate refresh time
    last_updated = entries_data[0].get("last_updated", datetime.now(timezone.utc))
    if isinstance(last_updated, str):
        last_updated = datetime.fromisoformat(last_updated.replace("Z", "+00:00"))

    refreshes_in = _calculate_refresh_time(last_updated)

    return LeaderboardResponse(
        leaderboard_type=leaderboard_type,
        filter_type=filter_type,
        country_code=country_code,
        entries=entries,
        total_entries=total_entries,
        limit=limit,
        offset=offset,
        has_more=(offset + limit) < total_entries,
        user_rank=user_rank,
        last_updated=last_updated,
        refreshes_in=refreshes_in,
    )


# ============================================================
# GET USER RANK
# ============================================================

@router.get("/rank", response_model=UserRank)
async def get_user_rank(
    user_id: str,
    leaderboard_type: LeaderboardType = Query(LeaderboardType.challenge_masters),
    country_filter: Optional[str] = Query(None),
    current_user: dict = Depends(get_current_user),
):
    """
    Get user's rank in specified leaderboard.

    Args:
        user_id: User ID
        leaderboard_type: Type of leaderboard
        country_filter: Optional country filter

    Returns:
        User's rank and stats
    """
    result = leaderboard_service.get_user_rank(
        user_id=user_id,
        leaderboard_type=leaderboard_type,
        country_filter=country_filter,
    )

    if not result:
        raise HTTPException(status_code=404, detail="User rank not found")

    rank_info = result["rank_info"]
    stats = result["stats"]

    user_stats = _build_leaderboard_entry(
        stats, rank_info["rank"], leaderboard_type, False, True
    )

    return UserRank(
        user_id=user_id,
        rank=rank_info["rank"],
        total_users=rank_info["total_users"],
        percentile=rank_info["percentile"],
        user_stats=user_stats,
    )


# ============================================================
# GET UNLOCK STATUS
# ============================================================

@router.get("/unlock-status", response_model=LeaderboardUnlockStatus)
async def get_unlock_status(user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Check if user has unlocked global leaderboard.

    Args:
        user_id: User ID

    Returns:
        Unlock status and progress
    """
    data = leaderboard_service.check_unlock_status(user_id)

    is_unlocked = data["is_unlocked"]
    workouts_completed = data["workouts_completed"]
    workouts_needed = data["workouts_needed"]
    days_active = data.get("days_active", 0)

    # Create unlock message
    if is_unlocked:
        unlock_message = "🏆 Global leaderboard unlocked!"
    elif workouts_needed > 0:
        unlock_message = f"Complete {workouts_needed} more workout{'s' if workouts_needed > 1 else ''} to unlock global leaderboard!"
    else:
        unlock_message = "Keep going! Almost there!"

    # Calculate progress percentage
    progress = min((workouts_completed / 10) * 100, 100)

    return LeaderboardUnlockStatus(
        is_unlocked=is_unlocked,
        workouts_completed=workouts_completed,
        workouts_needed=workouts_needed,
        days_active=days_active,
        unlock_message=unlock_message,
        progress_percentage=round(progress, 1),
    )


# ============================================================
# GET LEADERBOARD STATS
# ============================================================

@router.get("/stats", response_model=LeaderboardStats)
async def get_leaderboard_stats(
    current_user: dict = Depends(get_current_user),
):
    """
    Get overall leaderboard statistics.

    Returns:
        Aggregate stats across all leaderboards
    """
    stats = leaderboard_service.get_leaderboard_stats()

    return LeaderboardStats(
        total_users=stats["total_users"],
        total_countries=stats["total_countries"],
        top_country=stats["top_country"],
        average_wins=stats["average_wins"],
        highest_streak=stats["highest_streak"],
        total_volume_lifted=stats["total_volume_lifted"],
    )


# ============================================================
# CREATE ASYNC CHALLENGE (Beat Their Best)
# ============================================================

@router.post("/async-challenge", response_model=AsyncChallengeResponse)
async def create_async_challenge(
    user_id: str,
    request: AsyncChallengeRequest,
    current_user: dict = Depends(get_current_user),
):
    """
    Create async 'Beat Their Best' challenge from leaderboard.

    This creates a challenge WITHOUT notifying the target user.
    They only get notified IF you beat their record.

    Args:
        user_id: Challenging user ID
        request: Challenge details

    Returns:
        Challenge created confirmation
    """
    try:
        result = leaderboard_service.create_async_challenge(
            user_id=user_id,
            target_user_id=request.target_user_id,
            workout_log_id=request.workout_log_id,
            challenge_message=request.challenge_message,
        )

        return AsyncChallengeResponse(
            message="Challenge created! Beat their record and they'll be notified!",
            challenge_created=True,
            target_user_name=result["target_user_name"],
            workout_name=result["workout_name"],
            target_stats=result["target_stats"],
            notification_sent=False,  # Only notified if you beat it
        )
    except ValueError as e:
        raise HTTPException(status_code=404, detail="Resource not found")
    except Exception as e:
        raise safe_internal_error(e, "leaderboard_challenge")


# ============================================================
# HELPER FUNCTIONS
# ============================================================

def _get_order_column(leaderboard_type: LeaderboardType) -> str:
    """Get the primary ordering column for leaderboard type."""
    return {
        LeaderboardType.challenge_masters: "first_wins",
        LeaderboardType.volume_kings: "total_volume_lbs",
        LeaderboardType.streaks: "best_streak",
        LeaderboardType.weekly_challenges: "weekly_wins",
    }[leaderboard_type]


def _build_leaderboard_entry(
    data: dict,
    rank: int,
    leaderboard_type: LeaderboardType,
    is_friend: bool,
    is_current_user: bool,
) -> LeaderboardEntry:
    """Build LeaderboardEntry from database row."""
    entry = LeaderboardEntry(
        rank=rank,
        user_id=data["user_id"],
        user_name=data["user_name"],
        avatar_url=_presign_avatar(data.get("avatar_url")),
        country_code=data.get("country_code"),
        is_friend=is_friend,
        is_current_user=is_current_user,
    )

    # Add type-specific stats
    if leaderboard_type == LeaderboardType.challenge_masters:
        entry.first_wins = data.get("first_wins", 0)
        entry.win_rate = data.get("win_rate", 0.0)
        entry.total_completed = data.get("total_completed", 0)
    elif leaderboard_type == LeaderboardType.volume_kings:
        entry.total_volume_lbs = data.get("total_volume_lbs", 0.0)
        entry.total_workouts = data.get("total_workouts", 0)
        entry.avg_volume_per_workout = data.get("avg_volume_per_workout", 0.0)
    elif leaderboard_type == LeaderboardType.streaks:
        entry.current_streak = data.get("current_streak", 0)
        entry.best_streak = data.get("best_streak", 0)
        entry.last_workout_date = data.get("last_workout_date")
    elif leaderboard_type == LeaderboardType.weekly_challenges:
        entry.weekly_wins = data.get("weekly_wins", 0)
        entry.weekly_completed = data.get("weekly_completed", 0)
        entry.weekly_win_rate = data.get("weekly_win_rate", 0.0)

    return entry


def _calculate_refresh_time(last_updated: datetime) -> str:
    """Calculate when leaderboard refreshes next."""
    # Leaderboards refresh every hour
    next_refresh = last_updated + timedelta(hours=1)
    now = datetime.now(timezone.utc)
    delta = next_refresh - now

    if delta.total_seconds() < 60:
        return f"{int(delta.total_seconds())} seconds"
    elif delta.total_seconds() < 3600:
        return f"{int(delta.total_seconds() / 60)} minutes"
    else:
        return f"{int(delta.total_seconds() / 3600)} hours"


# ============================================================
# DISCOVER TAB AGGREGATOR — single call (migration 1939 / W2)
# ============================================================

from pydantic import BaseModel as _BaseModel
from typing import List as _List
from core.db import get_supabase_db as _get_supabase_db
from api.v1.users.photo import presign_profile_photo_url as _presign_avatar


class DiscoverLeaderboardEntry(_BaseModel):
    user_id: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    rank: int
    metric_value: float
    is_current_user: bool = False


class DiscoverRisingStar(_BaseModel):
    user_id: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    current_rank: int
    previous_rank: int
    rank_delta: int
    metric_value: float


class DiscoverSnapshot(_BaseModel):
    board: str
    scope: str
    week_start: str
    your_rank: int
    your_percentile: float
    your_tier: str
    your_metric: float
    total_active: int
    next_tier: Optional[str] = None
    units_to_next: int = 0
    metric_label: str = ""
    near_you: _List[DiscoverLeaderboardEntry] = []
    rising_stars: _List[DiscoverRisingStar] = []
    top_10: _List[DiscoverLeaderboardEntry] = []


@router.get("/discover", response_model=DiscoverSnapshot)
async def get_discover_snapshot(
    board: str = Query("xp", pattern="^(xp|volume|streaks)$"),
    scope: str = Query("global", pattern="^(global|country|friends)$"),
    current_user: dict = Depends(get_current_user),
):
    """
    Single-call aggregator for the Discover tab (migration 1939 / W2).
    Returns percentile hero, Rising Stars, Near You, Top 10 in one payload.
    """
    from datetime import date as _date
    import datetime as _dt

    try:
        db = _get_supabase_db()
        user_id = current_user["id"]
        # ISO week start (Monday)
        today = _date.today()
        week_start = today - _dt.timedelta(days=today.weekday())
        week_start_str = week_start.isoformat()

        # 1. Percentile + tier + user metric
        perc_res = db.client.rpc(
            "compute_user_percentile",
            {"p_user_id": user_id, "p_week_start": week_start_str, "p_board_type": board},
        ).execute()
        pdata = perc_res.data[0] if isinstance(perc_res.data, list) and perc_res.data else (perc_res.data or {})
        your_rank = pdata.get("rank", 0) or 0
        your_percentile = float(pdata.get("percentile", 0) or 0)
        your_tier = pdata.get("tier", "starter") or "starter"
        your_metric = float(pdata.get("metric_value", 0) or 0)
        total_active = pdata.get("total", 0) or 0

        # 2. Next tier progress
        tier_res = db.client.rpc(
            "get_next_tier_progress",
            {"p_user_id": user_id, "p_week_start": week_start_str, "p_board_type": board},
        ).execute()
        tdata = tier_res.data[0] if isinstance(tier_res.data, list) and tier_res.data else (tier_res.data or {})
        next_tier = tdata.get("next_tier")
        units_to_next = int(tdata.get("units_to_next", 0) or 0)
        metric_label = tdata.get("metric_label", "")

        # 3. Near You (5 above + you + 5 below)
        near_res = db.client.rpc(
            "get_near_you_leaderboard",
            {
                "p_user_id": user_id,
                "p_week_start": week_start_str,
                "p_board_type": board,
                "p_scope": scope,
                "p_window": 5,
            },
        ).execute()
        near_you = [
            DiscoverLeaderboardEntry(
                user_id=str(r.get("user_id")),
                username=r.get("username"),
                display_name=r.get("display_name"),
                avatar_url=_presign_avatar(r.get("avatar_url")),
                rank=r.get("rank") or 0,
                metric_value=float(r.get("metric_value") or 0),
                is_current_user=bool(r.get("is_current_user")),
            )
            for r in (near_res.data or [])
        ]

        # 4. Rising Stars (top 3 biggest weekly improvers)
        rising_res = db.client.rpc(
            "get_rising_stars",
            {
                "p_week_start": week_start_str,
                "p_board_type": board,
                "p_scope": scope,
                "p_limit": 3,
                "p_exclude_user": user_id,
            },
        ).execute()
        rising_stars = [
            DiscoverRisingStar(
                user_id=str(r.get("user_id")),
                username=r.get("username"),
                display_name=r.get("display_name"),
                avatar_url=_presign_avatar(r.get("avatar_url")),
                current_rank=r.get("current_rank") or 0,
                previous_rank=r.get("previous_rank") or 0,
                rank_delta=r.get("rank_delta") or 0,
                metric_value=float(r.get("metric_value") or 0),
            )
            for r in (rising_res.data or [])
        ]

        # 5. Top 10 (reuse near-you RPC with window=999 — easier: query directly)
        # For MVP: use a separate call with large window effectively returning top entries
        top_10 = []
        try:
            # simple inline query via RPC or direct SQL — we'll use a direct view lookup later
            # For now: near_you if user rank <= 10 covers this; else fetch top 10 via archive
            if your_rank and your_rank <= 10:
                top_10 = [e for e in near_you if e.rank <= 10]
            else:
                # Call the SQL directly via raw query
                top_res = db.client.rpc(
                    "get_near_you_leaderboard",
                    {
                        "p_user_id": user_id,
                        "p_week_start": week_start_str,
                        "p_board_type": board,
                        "p_scope": scope,
                        "p_window": 9999,  # wide window → full board
                    },
                ).execute()
                top_10 = [
                    DiscoverLeaderboardEntry(
                        user_id=str(r.get("user_id")),
                        username=r.get("username"),
                        display_name=r.get("display_name"),
                        avatar_url=_presign_avatar(r.get("avatar_url")),
                        rank=r.get("rank") or 0,
                        metric_value=float(r.get("metric_value") or 0),
                        is_current_user=bool(r.get("is_current_user")),
                    )
                    for r in (top_res.data or [])
                    if (r.get("rank") or 0) <= 10
                ][:10]
        except Exception:
            top_10 = []

        return DiscoverSnapshot(
            board=board,
            scope=scope,
            week_start=week_start_str,
            your_rank=your_rank,
            your_percentile=your_percentile,
            your_tier=your_tier,
            your_metric=your_metric,
            total_active=total_active,
            next_tier=next_tier,
            units_to_next=units_to_next,
            metric_label=metric_label,
            near_you=near_you,
            rising_stars=rising_stars,
            top_10=top_10,
        )
    except Exception as e:
        raise safe_internal_error(e, "leaderboard")


# ─── Discover peek: dual-overlay fitness profile (6-axis radar) ────────────
# Lazy per-tap endpoint. RPC runs ~50-80ms, client caches 5s to dedupe rapid taps.

class FitnessProfileResponse(_BaseModel):
    # 6 axes 0.0-1.0; NULL in target list if target has profile_stats_visible=FALSE
    target_scores: _List[Optional[float]]   # [strength, muscle, recovery, consistency, endurance, nutrition]
    viewer_scores: _List[Optional[float]]   # same order, for dual overlay
    target_bio: Optional[str] = None
    target_stats_hidden: bool = False
    axis_labels: _List[str] = [
        "Strength", "Muscle", "Recovery",
        "Consistency", "Endurance", "Nutrition",
    ]


class FitnessHistoryPoint(_BaseModel):
    date: str  # ISO date (YYYY-MM-DD)
    target_scores: _List[Optional[float]]  # len 6, NULL if target stats hidden
    viewer_scores: _List[Optional[float]]  # len 6


class FitnessHistoryResponse(_BaseModel):
    points: _List[FitnessHistoryPoint]  # chronological, oldest → newest
    days_back: int
    axis_labels: _List[str] = [
        "Strength", "Muscle", "Recovery",
        "Consistency", "Endurance", "Nutrition",
    ]


@router.get(
    "/user-profile/{target_user_id}/history",
    response_model=FitnessHistoryResponse,
)
async def get_fitness_profile_history(
    target_user_id: str,
    days: int = Query(90, ge=7, le=365),
    current_user: dict = Depends(get_current_user),
):
    """
    Dual-series radar-shape history for the Discover peek scrubber.
    Returns one row per date with both target + viewer snapshot values so
    the Flutter slider can animate the radar across time with zero extra
    network requests.
    """
    try:
        db = _get_supabase_db()
        viewer_id = current_user["id"]

        res = db.client.rpc(
            "get_dual_fitness_shape_history",
            {
                "p_target_user_id": target_user_id,
                "p_viewer_user_id": viewer_id,
                "p_days_back": days,
            },
        ).execute()

        def _num(v):
            return None if v is None else float(v)

        points = []
        for row in (res.data or []):
            points.append(
                FitnessHistoryPoint(
                    date=str(row.get("snapshot_date")),
                    target_scores=[
                        _num(row.get("target_strength")),
                        _num(row.get("target_muscle")),
                        _num(row.get("target_recovery")),
                        _num(row.get("target_consistency")),
                        _num(row.get("target_endurance")),
                        _num(row.get("target_nutrition")),
                    ],
                    viewer_scores=[
                        _num(row.get("viewer_strength")),
                        _num(row.get("viewer_muscle")),
                        _num(row.get("viewer_recovery")),
                        _num(row.get("viewer_consistency")),
                        _num(row.get("viewer_endurance")),
                        _num(row.get("viewer_nutrition")),
                    ],
                )
            )

        return FitnessHistoryResponse(points=points, days_back=days)
    except Exception as e:
        raise safe_internal_error(e, "leaderboard")


@router.get("/user-profile/{target_user_id}", response_model=FitnessProfileResponse)
async def get_user_fitness_profile(
    target_user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """
    Returns 6-axis fitness scores for the tapped user + the viewer, plus bio.
    Powers the Discover peek sheet's dual-overlay radar chart. Respects the
    target's `profile_stats_visible` privacy flag.
    """
    try:
        db = _get_supabase_db()
        viewer_id = current_user["id"]

        res = db.client.rpc(
            "get_user_fitness_profile",
            {"p_target_user_id": target_user_id, "p_viewer_user_id": viewer_id},
        ).execute()

        row = res.data[0] if isinstance(res.data, list) and res.data else (res.data or {})

        def _axis(key: str) -> Optional[float]:
            v = row.get(key)
            return None if v is None else float(v)

        return FitnessProfileResponse(
            target_scores=[
                _axis("target_strength"),
                _axis("target_muscle"),
                _axis("target_recovery"),
                _axis("target_consistency"),
                _axis("target_endurance"),
                _axis("target_nutrition"),
            ],
            viewer_scores=[
                _axis("viewer_strength"),
                _axis("viewer_muscle"),
                _axis("viewer_recovery"),
                _axis("viewer_consistency"),
                _axis("viewer_endurance"),
                _axis("viewer_nutrition"),
            ],
            target_bio=row.get("target_bio"),
            target_stats_hidden=bool(row.get("target_stats_hidden", False)),
        )
    except Exception as e:
        raise safe_internal_error(e, "leaderboard")
