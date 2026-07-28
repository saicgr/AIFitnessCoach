"""Single chokepoint for attaching a web Founding-500 purchase to an app account.

Why this exists
---------------
Founding-500 Lifetime is sold on the web (Stripe), but entitlement lives on
``user_subscriptions`` in the app. Those two facts are joined by email, and the
join has to happen in whichever order the user does things:

    buy -> then create the app account     (the common case at launch: the
                                            buyer has no account at checkout)
    create the app account -> then buy     (webhook links immediately)

The Stripe webhook can only cover the second order — at payment time it looks
the buyer up in ``users`` and links if a row exists, otherwise it just logs
"no app account yet". Nothing used to close the first case, so a buyer who
paid before signing up stayed on the free tier forever: money captured, seat
number issued, confirmation email sent, no Premium in the app, and no
reconciliation job to notice.

So the link is done at READ time instead: every time the app asks for a
subscription and the answer is not already lifetime, we ask whether an unlinked
paid seat is sitting there under this email. It is one indexed lookup against a
table with a hard 500-row ceiling, it self-heals a webhook that failed
mid-flight, and it works no matter which order the user did things in.
"""
from typing import Optional

from core.logger import get_logger

logger = get_logger(__name__)


def link_web_lifetime_if_any(supabase, user_id: str, email: Optional[str]) -> bool:
    """Attach any paid-but-unlinked Founding-500 seat for ``email`` to ``user_id``.

    Delegates to the ``link_web_lifetime_to_user`` SQL function, which is the
    authority: it matches on ``email_normalized`` against an *active* purchase,
    stamps ``web_lifetime_purchases.user_id``, and upserts the lifetime tier
    onto ``user_subscriptions``. It returns FALSE (touching nothing) when there
    is no active purchase for the email, which is the overwhelmingly common
    answer — every non-founder hits that path.

    Returns True only when a seat was actually linked, so callers know to
    re-read the subscription row. Never raises: a reconciliation failure must
    not take down the subscription-status read that carries it.
    """
    if not user_id or not email:
        return False

    try:
        result = supabase.client.rpc(
            "link_web_lifetime_to_user",
            {"p_user_id": str(user_id), "p_email": email},
        ).execute()
    except Exception as e:
        logger.warning(f"Web lifetime link check failed for user {user_id} (non-fatal): {e}")
        return False

    linked = result.data is True
    if linked:
        logger.info(f"🥇 Linked web Founding-500 lifetime to user {user_id} ({email})")
    return linked
