"""Unified rewards aggregator.

Flutter's Rewards screen calls three endpoints under `/progress/rewards/*`:
  GET  {user_id}/available   — list everything unclaimed
  GET  {user_id}/claimed     — history of past claims
  POST {user_id}/claim       — claim-in-place OR redirect for merch

None of them existed until now, which is why the screen showed empty while
the "1 ready" count on the You/Profile overview card said otherwise (the
card reads a different endpoint).

This router is a thin **aggregator** over three pre-existing subsystems:

  1. **Daily / streak / activity crates** — unopened rows surfaced via the
     `get_unclaimed_crates` RPC; claimed via `claim_daily_crate` RPC.
     Same pair already powers /xp/unclaimed-crates + /xp/claim-daily-crate.

  2. **Merch claims** (migration 1929) — `merch_claims` rows in
     `pending_address` status. Not claimable in place — the user is
     redirected to the existing merch address submission screen.

  3. **Level-up consumable awards** (migration 1935) — `level_up_events`
     rows with `acknowledged_at IS NULL`. The consumables themselves are
     already in `user_consumables` inventory; the reward shown on the
     Rewards screen is the acknowledgment UX so the user can replay the
     "you leveled up!" celebration.

Reward IDs are prefixed so the single /claim endpoint can route:
    crate:{crate_date}:{crate_type}   e.g. crate:2026-04-22:daily
    merch:{uuid}
    consumable:{level_up_event_id}
"""

from datetime import datetime, date as date_type
from typing import Any, Dict, List, Optional

import asyncio
import logging

from fastapi import APIRouter, Depends, HTTPException, Request
from pydantic import BaseModel

from core.auth import get_current_user, verify_user_ownership
from core.db import get_supabase_db
from core.exceptions import safe_internal_error
from core.timezone_utils import resolve_timezone, get_user_today


logger = logging.getLogger(__name__)
router = APIRouter()


# ---------------------------------------------------------------------------
# Response shapes — normalized across reward sources so the frontend can
# render one list widget for daily crates + merch + consumables.
# ---------------------------------------------------------------------------

class RewardItem(BaseModel):
    id: str                          # "crate:YYYY-MM-DD:tier" / "merch:<uuid>" / "consumable:<uuid>"
    reward_type: str                 # "daily_crate" | "merch" | "consumable"
    title: str
    subtitle: Optional[str] = None
    icon: Optional[str] = None       # Material icon name hint for the client
    earned_at: Optional[str] = None  # ISO-8601
    metadata: Dict[str, Any] = {}


class ClaimRequest(BaseModel):
    reward_id: str
    delivery_email: Optional[str] = None  # ignored except for gift cards


# ---------------------------------------------------------------------------
# Helpers — fetch from each subsystem, already-existing RPCs do the heavy
# lifting. Keep these tolerant: one source failing must not blank the list.
# ---------------------------------------------------------------------------

def _safe_rpc(db, name: str, params: Dict[str, Any]) -> List[Dict[str, Any]]:
    """Run an RPC and return its `.data` list, or [] on error. We log the
    failure to avoid masking regressions (the aggregator endpoint returns
    200 with whatever sources succeeded)."""
    try:
        result = db.client.rpc(name, params).execute()
        return result.data or []
    except Exception as e:
        logger.error(f"[rewards] RPC {name} failed: {e}", exc_info=True)
        return []


def _safe_query(desc: str, fn):
    try:
        return fn()
    except Exception as e:
        logger.error(f"[rewards] {desc} failed: {e}", exc_info=True)
        return []


def _fetch_unclaimed_crates(db, user_id: str, today_str: str) -> List[RewardItem]:
    rows = _safe_rpc(db, "get_unclaimed_crates", {
        "p_user_id": user_id,
        "p_user_date": today_str,
    })
    out: List[RewardItem] = []
    for row in rows:
        crate_date = str(row.get("crate_date"))
        # The RPC returns which tiers are available per date. Surface the
        # BEST tier the user can claim (activity > streak > daily) — they
        # only get one per date, so we don't want to show three separate
        # rows for one date that all resolve to the same claim.
        tier: Optional[str] = None
        if row.get("activity_crate_available"):
            tier, title = "activity", "Activity Crate"
        elif row.get("streak_crate_available"):
            tier, title = "streak", "Streak Crate"
        elif row.get("daily_crate_available", True):
            tier, title = "daily", "Daily Crate"
        else:
            continue
        out.append(RewardItem(
            id=f"crate:{crate_date}:{tier}",
            reward_type="daily_crate",
            title=title,
            subtitle=f"Earned {crate_date} · tap to open",
            icon="card_giftcard",
            earned_at=f"{crate_date}T00:00:00Z",
            metadata={"crate_date": crate_date, "crate_type": tier},
        ))
    return out


def _fetch_pending_merch(db, user_id: str) -> List[RewardItem]:
    rows = _safe_query(
        "merch_claims pending_address fetch",
        lambda: (db.client.table("merch_claims")
                 .select("id, merch_type, awarded_at_level, claimed_at, status")
                 .eq("user_id", user_id)
                 .eq("status", "pending_address")
                 .order("awarded_at_level", desc=False)
                 .execute().data or []),
    )
    return [
        RewardItem(
            id=f"merch:{row['id']}",
            reward_type="merch",
            title=_merch_title(row.get("merch_type"), row.get("awarded_at_level")),
            subtitle="Tap to submit shipping address",
            icon="local_shipping",
            earned_at=row.get("claimed_at"),
            metadata={
                "merch_type": row.get("merch_type"),
                "awarded_at_level": row.get("awarded_at_level"),
                "status": row.get("status"),
                "claim_id": row["id"],
            },
        )
        for row in rows
        if row.get("id")
    ]


def _fetch_unacknowledged_levelups(db, user_id: str) -> List[RewardItem]:
    rows = _safe_query(
        "level_up_events unacknowledged fetch",
        lambda: (db.client.table("level_up_events")
                 .select("id, level_reached, is_milestone, merch_type, rewards_snapshot, created_at")
                 .eq("user_id", user_id)
                 .is_("acknowledged_at", "null")
                 .order("level_reached", desc=False)
                 .limit(50)
                 .execute().data or []),
    )
    out: List[RewardItem] = []
    for row in rows:
        items = row.get("rewards_snapshot") or []
        # Summarise the item list into the subtitle ("+3 streak shields · +2 crates")
        consumable_items = [i for i in items if i.get("type") != "merch"]
        subtitle = _summarise_consumables(consumable_items)
        # If the only thing the level gave was merch, skip (already surfaced
        # by _fetch_pending_merch). Acknowledging is still useful for history
        # but Available should not show a duplicate row.
        if not consumable_items:
            continue
        out.append(RewardItem(
            id=f"consumable:{row['id']}",
            reward_type="consumable",
            title=f"Level {row.get('level_reached')} reached!",
            subtitle=subtitle,
            icon="military_tech" if row.get("is_milestone") else "auto_awesome",
            earned_at=row.get("created_at"),
            metadata={
                "level_reached": row.get("level_reached"),
                "is_milestone": row.get("is_milestone"),
                "items": consumable_items,
                "event_id": row["id"],
            },
        ))
    return out


def _fetch_claimed_crates(db, user_id: str) -> List[RewardItem]:
    """Claimed crates from `user_daily_crates`. Schema (per migration that
    seeded the daily-crate system): selected_crate VARCHAR, reward JSONB
    with {reward_type, reward_amount, ...}, claimed_at TIMESTAMPTZ. Rows
    with claimed_at NULL are still unopened and surface via `available`."""
    rows = _safe_query(
        "claimed crates fetch",
        lambda: (db.client.table("user_daily_crates")
                 .select("id, crate_date, selected_crate, reward, claimed_at")
                 .eq("user_id", user_id)
                 .not_.is_("claimed_at", "null")
                 .order("claimed_at", desc=True)
                 .limit(60)
                 .execute().data or []),
    )
    out: List[RewardItem] = []
    for row in rows:
        reward_payload = row.get("reward") or {}
        rtype = reward_payload.get("reward_type") or "xp"
        amount = reward_payload.get("reward_amount") or 0
        crate_tier = row.get("selected_crate") or "daily"
        out.append(RewardItem(
            id=f"crate:{row.get('crate_date')}:{crate_tier}:opened",
            reward_type="daily_crate",
            title=f"{crate_tier.title()} Crate opened",
            subtitle=f"+{amount} {rtype.replace('_', ' ')}",
            icon="card_giftcard",
            earned_at=row.get("claimed_at"),
            metadata={
                "crate_date": str(row.get("crate_date")),
                "crate_type": crate_tier,
                "reward_type": rtype,
                "reward_amount": amount,
            },
        ))
    return out


def _fetch_shipped_merch(db, user_id: str) -> List[RewardItem]:
    rows = _safe_query(
        "merch_claims claimed fetch",
        lambda: (db.client.table("merch_claims")
                 .select("id, merch_type, awarded_at_level, status, address_submitted_at, shipped_at, delivered_at")
                 .eq("user_id", user_id)
                 .in_("status", ("address_submitted", "awaiting_outreach", "shipped", "delivered"))
                 .order("awarded_at_level", desc=True)
                 .execute().data or []),
    )
    out: List[RewardItem] = []
    for row in rows:
        status = row.get("status") or ""
        out.append(RewardItem(
            id=f"merch:{row['id']}:{status}",
            reward_type="merch",
            title=_merch_title(row.get("merch_type"), row.get("awarded_at_level")),
            subtitle=_merch_status_subtitle(status),
            icon="local_shipping",
            earned_at=(row.get("delivered_at") or row.get("shipped_at")
                       or row.get("address_submitted_at")),
            metadata={
                "merch_type": row.get("merch_type"),
                "awarded_at_level": row.get("awarded_at_level"),
                "status": status,
                "claim_id": row["id"],
            },
        ))
    return out


def _fetch_acknowledged_levelups(db, user_id: str) -> List[RewardItem]:
    rows = _safe_query(
        "level_up_events acknowledged fetch",
        lambda: (db.client.table("level_up_events")
                 .select("id, level_reached, is_milestone, rewards_snapshot, acknowledged_at, created_at")
                 .eq("user_id", user_id)
                 .not_.is_("acknowledged_at", "null")
                 .order("level_reached", desc=True)
                 .limit(50)
                 .execute().data or []),
    )
    out: List[RewardItem] = []
    for row in rows:
        items = row.get("rewards_snapshot") or []
        consumable_items = [i for i in items if i.get("type") != "merch"]
        if not consumable_items:
            continue
        out.append(RewardItem(
            id=f"consumable:{row['id']}:acknowledged",
            reward_type="consumable",
            title=f"Level {row.get('level_reached')} rewards",
            subtitle=_summarise_consumables(consumable_items),
            icon="military_tech" if row.get("is_milestone") else "auto_awesome",
            earned_at=row.get("acknowledged_at") or row.get("created_at"),
            metadata={
                "level_reached": row.get("level_reached"),
                "items": consumable_items,
            },
        ))
    return out


# ---------------------------------------------------------------------------
# Copy helpers — keep user-facing strings together so the shape is tweakable
# without touching the DB-fetch code.
# ---------------------------------------------------------------------------

_MERCH_NAMES = {
    "shaker_bottle": "Shaker Bottle",
    "t_shirt": "T-Shirt",
    "hoodie": "Hoodie",
    "full_merch_kit": "Full Merch Kit",
    "signed_premium_kit": "Signed Premium Kit",
}

_CONSUMABLE_NAMES = {
    "xp_token_2x": "Double XP Token",
    "streak_shield": "Streak Shield",
    "fitness_crate": "Fitness Crate",
    "premium_crate": "Premium Crate",
}


def _merch_title(merch_type: Optional[str], level: Optional[int]) -> str:
    label = _MERCH_NAMES.get(merch_type or "", (merch_type or "").replace("_", " ").title())
    if level:
        return f"Level {level} {label}"
    return label or "Milestone Merch"


def _merch_status_subtitle(status: str) -> str:
    return {
        "address_submitted": "Shipping address received",
        "awaiting_outreach": "Address received, awaiting outreach",
        "shipped": "In transit",
        "delivered": "Delivered",
    }.get(status, status.replace("_", " ").title())


def _summarise_consumables(items: List[Dict[str, Any]]) -> str:
    if not items:
        return ""
    parts: List[str] = []
    for item in items:
        t = item.get("type") or ""
        qty = item.get("quantity") or 1
        label = _CONSUMABLE_NAMES.get(t, t.replace("_", " ").title())
        parts.append(f"+{qty} {label}")
    return " · ".join(parts)


# ---------------------------------------------------------------------------
# Endpoints
# ---------------------------------------------------------------------------

@router.get("/{user_id}/available", response_model=List[RewardItem])
async def get_available_rewards(
    user_id: str,
    request: Request,
    current_user=Depends(get_current_user),
):
    """All rewards the user has earned but not yet resolved.

    Three sources merged into one list:
      - Unopened daily/streak/activity crates
      - Merch claims pending an address
      - Level-up consumable drops awaiting acknowledgment

    Each row's `id` is prefixed so POST /claim can route correctly.
    """
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        user_tz = resolve_timezone(request, db, user_id)
        today_str = get_user_today(user_tz)

        # asyncio.gather is nice but the Supabase client here is sync; the
        # fetch helpers just call blocking RPCs. Run serially but cheaply —
        # three fast queries, each ~50ms.
        crates = _fetch_unclaimed_crates(db, user_id, today_str)
        merch = _fetch_pending_merch(db, user_id)
        levelups = _fetch_unacknowledged_levelups(db, user_id)

        combined = crates + merch + levelups
        # Sort by earned_at DESC so the newest reward lands at the top.
        combined.sort(key=lambda r: r.earned_at or "", reverse=True)
        return combined
    except Exception as e:
        logger.error(f"[rewards] /available failed: {e}", exc_info=True)
        raise safe_internal_error(e, "rewards")


@router.get("/{user_id}/claimed", response_model=List[RewardItem])
async def get_claimed_rewards(
    user_id: str,
    current_user=Depends(get_current_user),
):
    """History of claimed rewards — opened crates, merch in flight /
    delivered, and acknowledged level-up snapshots so the user can replay
    the celebration copy."""
    verify_user_ownership(current_user, user_id)
    try:
        db = get_supabase_db()
        crates = _fetch_claimed_crates(db, user_id)
        merch = _fetch_shipped_merch(db, user_id)
        levelups = _fetch_acknowledged_levelups(db, user_id)
        combined = crates + merch + levelups
        combined.sort(key=lambda r: r.earned_at or "", reverse=True)
        return combined
    except Exception as e:
        logger.error(f"[rewards] /claimed failed: {e}", exc_info=True)
        raise safe_internal_error(e, "rewards")


@router.post("/{user_id}/claim")
async def claim_reward(
    user_id: str,
    body: ClaimRequest,
    http_request: Request,
    current_user=Depends(get_current_user),
):
    """Unified claim dispatcher.

    Branches on the reward_id prefix:
      crate:<date>:<tier>      → call claim_daily_crate RPC (same as /xp/claim-daily-crate).
      consumable:<event_id>    → call acknowledge_level_up_events RPC. Consumables
                                  were already added to inventory at level-up
                                  time; this just moves the row Available →
                                  Claimed so the user stops seeing it as "ready".
      merch:<claim_id>         → return `redirect: "merch_address"` + claim_id.
                                  The Flutter screen navigates to the existing
                                  merch address submission flow; there's
                                  nothing to claim in place.
    """
    verify_user_ownership(current_user, user_id)
    reward_id = body.reward_id or ""
    if ":" not in reward_id:
        raise HTTPException(status_code=400, detail="Invalid reward_id")

    kind, _, remainder = reward_id.partition(":")

    try:
        db = get_supabase_db()

        if kind == "crate":
            # crate:<date>:<tier>
            parts = remainder.split(":")
            if len(parts) < 2:
                raise HTTPException(status_code=400, detail="Invalid crate reward_id")
            crate_date_str, crate_type = parts[0], parts[1]
            try:
                date_type.fromisoformat(crate_date_str)
            except ValueError:
                raise HTTPException(status_code=400, detail="Invalid crate date")

            rpc_params = {
                "p_user_id": user_id,
                "p_crate_type": crate_type,
                "p_crate_date": crate_date_str,
            }
            result = db.client.rpc("claim_daily_crate", rpc_params).execute()
            if not result.data or not result.data.get("success"):
                detail = (result.data or {}).get("error") or "Crate already claimed or unavailable"
                raise HTTPException(status_code=400, detail=detail)
            data = result.data
            return {
                "success": True,
                "reward_type": "daily_crate",
                "crate_type": data.get("crate_type", crate_type),
                "reward": {
                    "type": data.get("reward_type", "xp"),
                    "amount": data.get("reward_amount", 0),
                },
            }

        if kind == "consumable":
            # consumable:<event_uuid>
            event_id = remainder
            if not event_id:
                raise HTTPException(status_code=400, detail="Missing event id")
            result = db.client.rpc(
                "acknowledge_level_up_events",
                {"p_user_id": user_id, "p_event_ids": [event_id]},
            ).execute()
            ack_count = result.data if isinstance(result.data, int) else 0
            # Return the snapshot so the client can show "Nice — +3 Streak
            # Shields added to your inventory".
            event = (db.client.table("level_up_events")
                     .select("level_reached, rewards_snapshot")
                     .eq("id", event_id)
                     .eq("user_id", user_id)
                     .limit(1)
                     .execute().data or [])
            snapshot = event[0] if event else {}
            return {
                "success": ack_count > 0,
                "reward_type": "consumable",
                "message": "Added to your inventory",
                "level_reached": snapshot.get("level_reached"),
                "items": [i for i in (snapshot.get("rewards_snapshot") or []) if i.get("type") != "merch"],
            }

        if kind == "merch":
            # merch:<uuid> — no in-place claim. Tell the client to navigate.
            claim_id = remainder.split(":")[0]
            if not claim_id:
                raise HTTPException(status_code=400, detail="Missing merch claim id")
            return {
                "success": True,
                "reward_type": "merch",
                "redirect": "merch_address",
                "claim_id": claim_id,
                "message": "Submit your shipping address to finish claiming this reward.",
            }

        raise HTTPException(status_code=400, detail=f"Unknown reward kind: {kind}")
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"[rewards] /claim failed for {reward_id}: {e}", exc_info=True)
        raise safe_internal_error(e, "rewards")
