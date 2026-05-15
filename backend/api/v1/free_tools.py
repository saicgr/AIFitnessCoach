"""
Public, unauthenticated AI "free tools" — marketing-funnel endpoints that let
prospects try Zealova's AI without signing up. Each tool is hard-capped at 2
calls per client IP per 24 hours; usage is persisted in `free_tool_usage`.

Three endpoints:
  POST /api/v1/free-tools/ai-food-photo        — upload food image, get macros
  POST /api/v1/free-tools/ai-workout-generator — get one AI-built workout day
  POST /api/v1/free-tools/ai-roast-routine     — paste routine, get critique

NO auth headers. IP is the only identity. We hash the IP server-side so raw
IPs never land in the DB (see utils/free_tool_rate_limit.py).
"""

import base64
import hashlib
import json
import re
from typing import Any, Dict, List, Literal, Optional

from fastapi import APIRouter, BackgroundTasks, Form, HTTPException, Request, UploadFile, File
from google.genai import types
from pydantic import BaseModel, EmailStr, Field, conint, constr, ValidationError

from core.config import get_settings
from core.db import get_supabase_db
from core.logger import get_logger
from services.gemini.constants import gemini_generate_with_retry
from services.vision_service import get_vision_service
from utils.free_tool_rate_limit import (
    FreeToolLimitExceeded,
    GlobalCapExceeded,
    _client_ip,
    check_and_consume,
    check_global_cap,
)

logger = get_logger(__name__)
settings = get_settings()

router = APIRouter(prefix="/free-tools", tags=["Free Tools"])

# Limits are intentionally low — these endpoints are marketing samplers, not
# product surfaces. Two calls is enough to demonstrate quality without
# attracting scraping.
LIMIT_PER_WINDOW = 2
WINDOW_HOURS = 24

# 10 MB image cap. Larger payloads are rejected before we touch Gemini so an
# abusive client can't burn vision tokens with a 50 MB JPEG.
MAX_IMAGE_BYTES = 10 * 1024 * 1024

ALLOWED_IMAGE_MIME = {
    "image/jpeg",
    "image/jpg",
    "image/png",
    "image/webp",
    "image/heic",
    "image/heif",
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def _raise_429(exc: FreeToolLimitExceeded, message: str) -> None:
    """Translate a FreeToolLimitExceeded into the documented 429 envelope."""
    raise HTTPException(
        status_code=429,
        detail={
            "error": "limit_reached",
            "uses_remaining_today": 0,
            "resets_at_iso": exc.resets_at.isoformat(),
            "message": message,
        },
    )


def _raise_global_429(exc: GlobalCapExceeded) -> None:
    """Translate a GlobalCapExceeded into the same 429 envelope shape.

    `error: capacity_reached` lets the client distinguish a site-wide lock
    ("everyone is busy") from the user's own per-IP limit.
    """
    raise HTTPException(
        status_code=429,
        detail={
            "error": "capacity_reached",
            "uses_remaining_today": 0,
            "resets_at_iso": exc.resets_at.isoformat(),
            "message": (
                "This free tool is at capacity right now. "
                "Get unlimited, instant access in the Zealova app."
            ),
        },
    )


# ---------------------------------------------------------------------------
# 1. AI Food Photo
# ---------------------------------------------------------------------------


@router.post("/ai-food-photo")
async def ai_food_photo(request: Request, image: UploadFile = File(...)):
    """Analyze a single food image and return macro estimates.

    Reuses `VisionService.analyze_food_image` — the same single-image plate
    analyzer used by the authenticated nutrition flow. No fallbacks.
    """
    ip = _client_ip(request)

    try:
        await check_global_cap("ai-food-photo")
    except GlobalCapExceeded as e:
        _raise_global_429(e)

    try:
        remaining = await check_and_consume(
            ip=ip,
            tool="ai-food-photo",
            limit=LIMIT_PER_WINDOW,
            window_hours=WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        _raise_429(
            e,
            "You've used your 2 free food scans today. Get unlimited in Zealova.",
        )

    # Validate content type up front. UploadFile's content_type comes from the
    # multipart header; we still check actual bytes via the size guard below.
    content_type = (image.content_type or "").lower()
    if content_type not in ALLOWED_IMAGE_MIME:
        raise HTTPException(
            status_code=400,
            detail=f"Unsupported image type: {content_type or 'unknown'}. "
            "Use JPEG, PNG, WebP, or HEIC.",
        )

    raw = await image.read()
    if not raw:
        raise HTTPException(status_code=400, detail="Empty image upload.")
    if len(raw) > MAX_IMAGE_BYTES:
        raise HTTPException(
            status_code=400,
            detail=f"Image too large ({len(raw)} bytes). Max 10 MB.",
        )

    image_b64 = base64.b64encode(raw).decode("ascii")

    try:
        vision = get_vision_service()
        result = await vision.analyze_food_image(image_base64=image_b64)
    except ValueError as e:
        # Vision returned unparseable JSON — surface as 400, not 500.
        logger.warning(f"[free-tools/food-photo] vision parse failed: {e}")
        raise HTTPException(
            status_code=400,
            detail="Could not read that image. Try a clearer, well-lit photo of the food.",
        )
    except Exception as e:
        logger.error(f"[free-tools/food-photo] vision call failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="AI analysis is temporarily unavailable. Try again in a minute.",
        )

    # Shape the response to the documented contract. The vision service
    # returns rich data (micros, health_score, feedback, glycemic_load); the
    # public free-tool surface now exposes the full picture as an install-
    # conversion demo. Backwards-compatible: original macro fields preserved.
    items_in = result.get("food_items") or []
    items_out: List[dict] = []
    for it in items_in:
        gl = it.get("glycemic_load")
        items_out.append(
            {
                "name": it.get("name", "Unknown item"),
                "grams": float(it.get("weight_g") or 0),
                "calories": int(round(float(it.get("calories") or 0))),
                "protein_g": float(it.get("protein_g") or 0),
                "carbs_g": float(it.get("carbs_g") or 0),
                "fat_g": float(it.get("fat_g") or 0),
                "fiber_g": float(it.get("fiber_g") or 0),
                "glycemic_load": int(gl) if gl is not None else None,
                "confidence": it.get("confidence") or "medium",
            }
        )

    totals = {
        "calories": int(round(float(result.get("total_calories") or 0))),
        "protein_g": float(result.get("total_protein_g") or 0),
        "carbs_g": float(result.get("total_carbs_g") or 0),
        "fat_g": float(result.get("total_fat_g") or 0),
        "fiber_g": float(
            result.get("total_fiber_g") or result.get("fiber_g") or 0
        ),
    }

    # Micronutrients: the vision service emits these as top-level keys on the
    # FoodAnalysisResponse schema (not nested under "micronutrients"). We
    # collect the most useful subset and convert vitamin D from IU -> µg
    # (1 µg = 40 IU) so the frontend can compare against the FDA DV in µg.
    micro_keys = [
        "vitamin_a_ug", "vitamin_c_mg", "vitamin_e_mg", "vitamin_k_ug",
        "vitamin_b1_mg", "vitamin_b2_mg", "vitamin_b3_mg", "vitamin_b6_mg",
        "vitamin_b9_ug", "vitamin_b12_ug", "choline_mg",
        "calcium_mg", "iron_mg", "magnesium_mg", "zinc_mg", "selenium_ug",
        "potassium_mg", "sodium_mg", "phosphorus_mg", "copper_mg",
        "manganese_mg", "iodine_ug",
        "sugar_g", "cholesterol_mg", "caffeine_mg",
    ]
    micros: Dict[str, float] = {}
    for k in micro_keys:
        v = result.get(k)
        if v is not None:
            try:
                micros[k] = float(v)
            except (TypeError, ValueError):
                continue
    # Vitamin D: schema stores IU; UI compares against µg DV (20µg = 800 IU).
    vit_d_iu = result.get("vitamin_d_iu")
    if vit_d_iu is not None:
        try:
            micros["vitamin_d_ug"] = float(vit_d_iu) / 40.0
        except (TypeError, ValueError):
            pass
    # Omega-3 / Omega-6: schema uses omega3_g/omega6_g; expose as omega_3_g
    # / omega_6_g for the frontend (matches DV table naming).
    for src, dst in (("omega3_g", "omega_3_g"), ("omega6_g", "omega_6_g")):
        v = result.get(src)
        if v is not None:
            try:
                micros[dst] = float(v)
            except (TypeError, ValueError):
                continue

    # Health score: schema uses an integer 1-10. Map to a letter grade so the
    # frontend badge can colour-code consistently (A=10, A-=9, B+=8, B=7,
    # B-=6, C+=5, C=4, C-=3, D=2, F=1). Pass through unchanged if a string.
    raw_score = result.get("health_score")
    health_score: Optional[str] = None
    if isinstance(raw_score, str) and raw_score.strip():
        health_score = raw_score.strip()
    elif isinstance(raw_score, (int, float)):
        n = int(round(float(raw_score)))
        n = max(1, min(10, n))
        health_score = {
            10: "A", 9: "A-", 8: "B+", 7: "B", 6: "B-",
            5: "C+", 4: "C", 3: "C-", 2: "D", 1: "F",
        }[n]

    # Commentary: prefer `feedback`, fall back to `ai_suggestion`.
    commentary_raw = result.get("feedback") or result.get("ai_suggestion")
    commentary = commentary_raw.strip() if isinstance(commentary_raw, str) and commentary_raw.strip() else None

    return {
        "items": items_out,
        "totals": totals,
        "micros": micros or None,
        "health_score": health_score,
        "commentary": commentary,
        "uses_remaining_today": remaining,
    }


# ---------------------------------------------------------------------------
# 2. AI Workout Generator
# ---------------------------------------------------------------------------


class WorkoutGeneratorRequest(BaseModel):
    goal: Literal["strength", "muscle", "fat-loss", "endurance"]
    days_per_week: Literal[3, 4, 5, 6]
    minutes_per_session: Literal[30, 45, 60, 75, 90]
    experience: Literal["beginner", "intermediate", "advanced"]
    equipment: List[Literal["barbell", "dumbbells", "cable", "machines", "bodyweight"]] = Field(
        ..., min_length=1
    )
    focus: Optional[constr(max_length=200)] = None


_WORKOUT_SYSTEM = """You are a strength and conditioning coach designing ONE workout day for a fitness app preview.

Rules (these are non-negotiable):
- Output valid JSON only. No prose, no markdown fences.
- Beginner: keep compound lifts to 3 sets max, use RIR 3 to RIR 4, simple movements only.
- Intermediate: 3 to 4 sets on main lifts, RIR 2 to RIR 3.
- Advanced: 4 to 5 sets on main lifts, RIR 1 to RIR 2, allow tempo cues.
- Match exercises strictly to the equipment list. If only bodyweight, use only bodyweight movements.
- Goal alignment:
    strength  -> lower reps (3 to 6), longer rest (180 to 240s), big compounds first.
    muscle    -> 8 to 12 reps, 60 to 120s rest, mix compounds + isolations.
    fat-loss  -> 10 to 15 reps, 45 to 75s rest, supersets allowed in notes.
    endurance -> 15+ reps or time-based, short rest, circuits acceptable.
- Duration must fit the requested minutes (count warmup + main + cooldown).
- NEVER include an em dash in any string field. Use periods or commas only.
- Real exercise names. No joke entries. No "ego lift" nonsense.
"""


@router.post("/ai-workout-generator")
async def ai_workout_generator(payload: WorkoutGeneratorRequest, request: Request):
    ip = _client_ip(request)
    try:
        await check_global_cap("ai-workout-generator")
    except GlobalCapExceeded as e:
        _raise_global_429(e)
    try:
        remaining = await check_and_consume(
            ip=ip,
            tool="ai-workout-generator",
            limit=LIMIT_PER_WINDOW,
            window_hours=WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        _raise_429(
            e,
            "You've used your 2 free workout generations today. Get unlimited in Zealova.",
        )

    user_prompt = f"""Build ONE workout for this lifter. Return JSON matching this exact schema:

{{
  "title": "<concise title, e.g. 'Lower Body Strength, 60 min'>",
  "duration_min": <int, equal to minutes_per_session>,
  "warmup":   [{{"exercise": "...", "duration_or_reps": "...", "notes": "..."}}],
  "main":     [{{"exercise": "...", "sets": <int>, "reps": "<string>", "rest_s": <int>, "rir": <int>, "notes": "..."}}],
  "cooldown": [{{"exercise": "...", "duration_or_reps": "...", "notes": "..."}}]
}}

Inputs:
- goal: {payload.goal}
- days_per_week: {payload.days_per_week}
- minutes_per_session: {payload.minutes_per_session}
- experience: {payload.experience}
- equipment available: {", ".join(payload.equipment)}
- focus (optional, may be empty): {payload.focus or "no specific focus"}

Constraints:
- 2 to 4 warmup items.
- 4 to 7 main lifts. Order: heaviest compound first.
- 2 to 4 cooldown items, mobility or static stretching.
- Reps field is a string ("5", "8-12", "AMRAP", "30s", "10/side").
- rest_s is integer seconds.
- rir is integer 0 to 4. Match the experience rule above.

Return JSON only.
"""

    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[_WORKOUT_SYSTEM, user_prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                max_output_tokens=4000,
                temperature=0.7,
            ),
            method_name="free_tools_workout_generator",
            timeout=60.0,
        )
        text = response.text.strip()
        plan = json.loads(text)
    except json.JSONDecodeError as e:
        logger.error(
            f"[free-tools/workout-gen] invalid JSON from Gemini: {e}; raw={text[:300] if 'text' in dir() else ''}"
        )
        raise HTTPException(
            status_code=500,
            detail="AI returned an unreadable plan. Try again.",
        )
    except Exception as e:
        logger.error(f"[free-tools/workout-gen] gemini failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="AI generation is temporarily unavailable. Try again in a minute.",
        )

    # Defensive: make sure all four documented keys exist (Gemini occasionally
    # drops a section if the prompt feels too tight). Empty list is a safer
    # default than missing key for the Flutter side.
    for key in ("warmup", "main", "cooldown"):
        plan.setdefault(key, [])
    plan.setdefault("title", f"{payload.goal.title()} Day, {payload.minutes_per_session} min")
    plan.setdefault("duration_min", payload.minutes_per_session)
    plan["uses_remaining_today"] = remaining
    return plan


# ---------------------------------------------------------------------------
# 3. AI Roast Routine
# ---------------------------------------------------------------------------


class RoastRoutineRequest(BaseModel):
    routine_text: constr(min_length=10, max_length=2000)
    tone: Optional[Literal["spicy", "constructive"]] = "spicy"


_ROAST_SYSTEM_BASE = """You are a smart strength coach reviewing a lifter's self-described routine for a fitness app preview.

You analyze:
- Weekly volume per major muscle (chest, back, shoulders, biceps, triceps, quads, hamstrings, glutes, calves, core).
- Frequency per muscle (sessions per week).
- Antagonist balance (push vs pull, quad vs hamstring, anterior vs posterior).
- Missing essentials (direct arm work, hip hinge, rotator cuff work, calves, core).
- Recovery realism (back-to-back same-muscle days, too many sets per session).

Then you assign a letter grade A, A-, B+, B, B-, C+, C, C-, D, or F.

OUTPUT FORMAT — JSON only, no prose, no markdown fences:
{
  "verdict": "<letter grade>",
  "summary_one_liner": "<one sentence summary of the routine's headline issue or strength>",
  "wins":        ["<3 to 5 specific positives>"],
  "concerns":    ["<3 to 6 specific problems, each with a concrete reason>"],
  "suggestions": ["<3 to 6 specific actionable fixes, each with sets per week>"],
  "roast": "<single paragraph, see tone rules below>"
}

Voice rules — ABSOLUTE:
- NEVER include an em dash. Use periods or commas only.
- NEVER comment on the user's body, weight, appearance, sex, age, race, or perceived size.
- The roast targets the ROUTINE structure ONLY. Sets, splits, exercise choice, frequency.
- Wins, concerns, and suggestions are always plainspoken and specific.
"""

_ROAST_SPICY = """Tone for the "roast" field: spicy. Humorous, sharp, gym-bro-adjacent but never mean. Think Reddit r/Fitness top-comment energy. Funny, specific, ends with a clear directive. 2 to 4 sentences."""

_ROAST_CONSTRUCTIVE = """Tone for the "roast" field: constructive. Straight-faced coach summary. No jokes. Direct, professional, 2 to 3 sentences ending with the single highest-priority change."""


@router.post("/ai-roast-routine")
async def ai_roast_routine(payload: RoastRoutineRequest, request: Request):
    ip = _client_ip(request)
    try:
        await check_global_cap("ai-roast-routine")
    except GlobalCapExceeded as e:
        _raise_global_429(e)
    try:
        remaining = await check_and_consume(
            ip=ip,
            tool="ai-roast-routine",
            limit=LIMIT_PER_WINDOW,
            window_hours=WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        _raise_429(
            e,
            "You've used your 2 free routine reviews today. Get unlimited in Zealova.",
        )

    tone_block = _ROAST_SPICY if payload.tone == "spicy" else _ROAST_CONSTRUCTIVE
    system = f"{_ROAST_SYSTEM_BASE}\n\n{tone_block}"
    user_prompt = f"""The lifter's routine (verbatim, may be messy):
---
{payload.routine_text}
---

Analyze and return JSON per the schema above. Be specific. Cite muscle groups by name in concerns and suggestions. Include sets-per-week numbers in suggestions.
"""

    try:
        response = await gemini_generate_with_retry(
            model=settings.gemini_model,
            contents=[system, user_prompt],
            config=types.GenerateContentConfig(
                response_mime_type="application/json",
                max_output_tokens=3000,
                # Spicy tone benefits from slightly higher temp; constructive
                # benefits from lower. 0.8 / 0.4 keeps both readable.
                temperature=0.8 if payload.tone == "spicy" else 0.4,
            ),
            method_name="free_tools_roast_routine",
            timeout=60.0,
        )
        text = response.text.strip()
        review = json.loads(text)
    except json.JSONDecodeError as e:
        logger.error(f"[free-tools/roast] invalid JSON from Gemini: {e}")
        raise HTTPException(
            status_code=500,
            detail="AI returned an unreadable review. Try again.",
        )
    except Exception as e:
        logger.error(f"[free-tools/roast] gemini failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="AI review is temporarily unavailable. Try again in a minute.",
        )

    # Defensive defaults so the Flutter side never crashes on a missing key.
    for key in ("wins", "concerns", "suggestions"):
        review.setdefault(key, [])
    review.setdefault("verdict", "C")
    review.setdefault("summary_one_liner", "Routine needs structural review.")
    review.setdefault("roast", "")
    review["uses_remaining_today"] = remaining
    return review


# ---------------------------------------------------------------------------
# 4. Email Signup (post-result + during-processing capture)
# ---------------------------------------------------------------------------

# Stricter regex than EmailStr's default. Rejects whitespace, multi-@, and
# trailing dots so we never persist obvious junk to the marketing list.
_EMAIL_RE = re.compile(r"^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$")

# Cap result_summary serialized payload at 4 KB. Anything bigger almost
# certainly means a tool client is dumping its full state, not a summary.
_MAX_RESULT_SUMMARY_BYTES = 4 * 1024

# Email-signup rate limit. Generous so legitimate users on shared NATs (offices,
# campuses) aren't blocked, but low enough to deter scrapers seeding the list.
EMAIL_SIGNUP_LIMIT = 10
EMAIL_SIGNUP_WINDOW_HOURS = 1


class EmailSignupRequest(BaseModel):
    email: constr(strip_whitespace=True, min_length=5, max_length=254)
    tool_slug: constr(strip_whitespace=True, min_length=1, max_length=100)
    result_summary: Optional[Dict[str, Any]] = None
    source: Literal["after_result", "during_processing", "manual"] = "manual"


def _hash_ip_signup(ip: str) -> str:
    """Hash IP under the dedicated email-signup salt (not the rate-limit salt).

    Privacy isolation: rate-limit table rows for this same IP use a different
    salt, so even with full DB access you cannot join them.
    """
    salt = "zealova:free:emailsignup:row:v1"
    return hashlib.sha256(f"{salt}|{ip}".encode("utf-8")).hexdigest()


@router.post("/email-signup")
async def email_signup(
    payload: EmailSignupRequest,
    request: Request,
    background_tasks: BackgroundTasks,
):
    """Capture a prospect's email after they used (or while they're using) a
    free tool. Idempotent on (email, tool_slug) — duplicate calls return
    `already_subscribed: true` rather than 409 for a friendlier UX.
    """
    ip = _client_ip(request)
    try:
        await check_and_consume(
            ip=ip,
            tool="email-signup",
            limit=EMAIL_SIGNUP_LIMIT,
            window_hours=EMAIL_SIGNUP_WINDOW_HOURS,
        )
    except FreeToolLimitExceeded as e:
        _raise_429(
            e,
            "Too many signups from this network. Try again in a bit.",
        )

    # Validate email shape. Pydantic already enforced length; this regex
    # rejects shapes EmailStr would accept that we don't want (e.g. unusual
    # TLDs or quoted local parts).
    email = payload.email.strip().lower()
    if not _EMAIL_RE.match(email):
        raise HTTPException(status_code=400, detail="That email doesn't look right.")

    tool_slug = payload.tool_slug.strip()
    if not tool_slug:
        raise HTTPException(status_code=400, detail="Missing tool_slug.")

    # Bound the JSONB payload. No silent truncation — reject loudly.
    result_summary = payload.result_summary
    if result_summary is not None:
        try:
            serialized = json.dumps(result_summary)
        except (TypeError, ValueError) as e:
            raise HTTPException(
                status_code=400,
                detail=f"result_summary not JSON-serializable: {e}",
            )
        if len(serialized.encode("utf-8")) > _MAX_RESULT_SUMMARY_BYTES:
            raise HTTPException(
                status_code=400,
                detail="result_summary too large (max 4KB).",
            )

    ip_hash = _hash_ip_signup(ip)
    user_agent = (request.headers.get("user-agent") or "")[:500]
    referrer = (request.headers.get("referer") or "")[:500]

    db = get_supabase_db()
    client = db.client

    # Check existing row first. UNIQUE (email, tool_slug) would let us rely
    # on the DB to surface conflicts, but the Supabase client raises on
    # conflict rather than returning a structured error, so a lookup-first
    # path keeps the response shape clean.
    existing = (
        client.table("free_tools_email_signup")
        .select("id")
        .eq("email", email)
        .eq("tool_slug", tool_slug)
        .limit(1)
        .execute()
    )
    if existing.data:
        logger.info(
            f"[free-tools/email-signup] duplicate email={email[:3]}*** tool={tool_slug}"
        )
        return {
            "success": True,
            "already_subscribed": True,
            "message": "You're already on the list for this one. We'll be in touch.",
        }

    row = {
        "email": email,
        "tool_slug": tool_slug,
        "ip_hash": ip_hash,
        "result_summary": result_summary,
        "source": payload.source,
        "user_agent": user_agent or None,
        "referrer": referrer or None,
    }

    try:
        client.table("free_tools_email_signup").insert(row).execute()
    except Exception as e:
        # If a race produced a duplicate between our SELECT and INSERT, treat
        # it the same as the existing branch above. Surface any other error.
        msg = str(e).lower()
        if "duplicate" in msg or "unique" in msg or "23505" in msg:
            return {
                "success": True,
                "already_subscribed": True,
                "message": "You're already on the list for this one. We'll be in touch.",
            }
        logger.error(f"[free-tools/email-signup] insert failed: {e}", exc_info=True)
        raise HTTPException(
            status_code=500,
            detail="Could not save your email. Try again in a minute.",
        )

    logger.info(
        f"[free-tools/email-signup] new email={email[:3]}*** tool={tool_slug} source={payload.source}"
    )

    # Fire the transactional result email via Resend in the background so
    # the response stays fast and a Resend hiccup never blocks signup.
    # Lazy import to avoid pulling email service into module-load time.
    try:
        from services.email_service import EmailService

        email_service = EmailService()
        background_tasks.add_task(
            email_service.send_free_tool_result,
            to_email=email,
            tool_slug=tool_slug,
            result_summary=result_summary,
        )
    except Exception as e:
        # Never let an email-send setup error block the signup. The row is
        # already in the DB.
        logger.error(
            f"[free-tools/email-signup] background email schedule failed: {e}",
            exc_info=True,
        )

    return {
        "success": True,
        "already_subscribed": False,
        "message": "Check your inbox. Your result is on its way.",
    }


# ───────────────────────────── Usage counters ────────────────────────────
# Each tool fires a fire-and-forget increment when it produces a result.
# The /free-tools index reads the aggregate to show "N calculations run"
# social proof per card. Counts are coarse and never joined to a user.

_USAGE_SLUG_RE = re.compile(r"^[a-z0-9\-]{1,100}$")

# Per-IP throttle so a single visitor refreshing a tool can't inflate a
# counter. Generous because legitimate users do recompute repeatedly.
USAGE_PING_LIMIT = 60
USAGE_PING_WINDOW_HOURS = 1


@router.get("/usage")
async def get_usage_counts():
    """Return every tool's usage count as a {slug: count} map.

    Read by the /free-tools index page. Public, unauthenticated, cacheable.
    """
    db = get_supabase_db()
    try:
        res = (
            db.client.table("free_tool_usage_counts")
            .select("slug, count")
            .execute()
        )
    except Exception as e:
        logger.error(f"[free-tools/usage] read failed: {e}", exc_info=True)
        # Soft-fail: an empty map just means no counts render. Never 500
        # the index page over social-proof chrome.
        return {"counts": {}}

    counts = {row["slug"]: row["count"] for row in (res.data or [])}
    return {"counts": counts}


@router.post("/usage/{slug}")
async def increment_usage(slug: str, request: Request):
    """Increment a tool's usage counter. Fire-and-forget from the client.

    Lightly IP-throttled to stop a single visitor inflating a number.
    Always returns 200 with the (best-effort) new count so the client
    never has to handle an error path for a non-critical ping.
    """
    slug = slug.strip().lower()
    if not _USAGE_SLUG_RE.match(slug):
        raise HTTPException(status_code=400, detail="Invalid tool slug.")

    ip = _client_ip(request)
    try:
        await check_and_consume(
            ip=ip,
            tool=f"usage-ping",
            limit=USAGE_PING_LIMIT,
            window_hours=USAGE_PING_WINDOW_HOURS,
        )
    except FreeToolLimitExceeded:
        # Over the throttle: silently no-op. The counter is approximate by
        # design, so a dropped ping is fine. Return current value if known.
        return {"slug": slug, "counted": False}

    db = get_supabase_db()
    try:
        res = db.client.rpc(
            "increment_free_tool_usage", {"p_slug": slug}
        ).execute()
        new_count = res.data if isinstance(res.data, int) else None
        return {"slug": slug, "counted": True, "count": new_count}
    except Exception as e:
        logger.error(f"[free-tools/usage] increment failed slug={slug}: {e}")
        # Non-critical: never surface to the user.
        return {"slug": slug, "counted": False}
