"""Regression gates for the Founding-500 web lifetime flow.

Covers the two defects that took money and gave nothing back:

1. A buyer with no app account at checkout time never received Premium.
   `link_web_lifetime_to_user` was invoked from exactly one place — the Stripe
   webhook, and only inside an `if the users row already exists` branch. Nothing
   linked the purchase when the account was created afterwards, which is the
   normal order for a web-first launch, and there was no reconciliation job.

2. Refunding a founder reissued their seat number to the next buyer.
   `release_founder_seat(n)` ignored `n` and just decremented a counter, while
   `claim_founder_seat()` returned `counter + 1`. The reissued number then
   violated `UNIQUE (founder_seat_number)`, the exception was swallowed by the
   webhook's background processor, and a captured payment was stranded at
   status='pending' with no entitlement and no email.

The SQL-level allocation invariants live in migration 2329 and are asserted
here against the module's call contract; these tests deliberately do not touch
a live database.
"""
import re
from pathlib import Path

import pytest

BACKEND = Path(__file__).resolve().parents[1]
REPO = BACKEND.parent
LIFETIME_WEB = BACKEND / "api/v1/subscriptions/lifetime_web.py"
MANAGEMENT = BACKEND / "api/v1/subscriptions/management.py"
MIGRATION = BACKEND / "migrations/2329_lifetime_founder_seat_allocation.sql"


# =============================================================================
# 1. Entitlement reaches buyers who had no account at checkout time
# =============================================================================

def test_subscription_read_links_an_unclaimed_web_lifetime():
    """The status read is the only place a buy-then-sign-up founder can be linked."""
    src = MANAGEMENT.read_text()
    assert "link_web_lifetime_if_any" in src, (
        "GET /subscriptions/{user_id} must attempt to link a web Founding-500 "
        "purchase. Without it, anyone who bought before creating an app account "
        "stays on the free tier forever."
    )


def test_subscription_read_does_not_raise_for_a_user_with_no_row():
    """A first-time founder has no user_subscriptions row yet — that must read as free, not 500."""
    src = MANAGEMENT.read_text()
    get_sub = src.split("async def get_subscription")[1].split("async def ")[0]
    assert ".maybe_single()" in get_sub, "use maybe_single(); .single() raises on 0 rows"
    assert ".single()" not in get_sub.replace(".maybe_single()", ""), (
        "a bare .single() throws PGRST116 for a brand-new account"
    )
    assert "res.data if res else None" in get_sub, (
        "maybe_single returns None ITSELF on 0 rows — guard the result object, "
        "not just .data (see CLAUDE.md)"
    )


def test_link_helper_is_the_single_chokepoint():
    """Both call sites route through one helper so they cannot drift apart."""
    from services import lifetime_entitlement

    assert callable(lifetime_entitlement.link_web_lifetime_if_any)

    web_src = LIFETIME_WEB.read_text()
    assert "link_web_lifetime_if_any" in web_src, (
        "the webhook must use the shared helper, not a hand-rolled rpc() call"
    )
    direct_rpc = re.findall(r'rpc\(\s*\n?\s*"link_web_lifetime_to_user"', web_src)
    assert not direct_rpc, "call the helper, not the RPC directly"


def test_link_helper_never_raises_into_the_status_read(monkeypatch):
    """A reconciliation failure must not take down the subscription endpoint."""
    from services.lifetime_entitlement import link_web_lifetime_if_any

    class Boom:
        class client:
            @staticmethod
            def rpc(*_a, **_kw):
                raise RuntimeError("postgrest is down")

    assert link_web_lifetime_if_any(Boom(), "user-1", "founder@example.com") is False


def test_link_helper_skips_the_query_when_there_is_no_email():
    from services.lifetime_entitlement import link_web_lifetime_if_any

    class Tripwire:
        class client:
            @staticmethod
            def rpc(*_a, **_kw):
                raise AssertionError("must not query without an email")

    assert link_web_lifetime_if_any(Tripwire(), "user-1", None) is False
    assert link_web_lifetime_if_any(Tripwire(), "", "founder@example.com") is False


# =============================================================================
# 2. Seat allocation cannot reissue a live seat number
# =============================================================================

def test_webhook_allocates_and_stamps_atomically():
    """Two-step claim-then-stamp is what let a refunded number be reissued."""
    src = LIFETIME_WEB.read_text()
    assert "activate_founder_purchase" in src
    assert "claim_founder_seat" not in src, (
        "claim_founder_seat is a bare counter (dropped in migration 2329) — "
        "allocation must go through activate_founder_purchase, which allocates "
        "and stamps the row in one serialized transaction"
    )


def test_webhook_does_not_stamp_the_seat_a_second_time():
    """The RPC already wrote status/seat/payment fields; a follow-up UPDATE would race it."""
    src = LIFETIME_WEB.read_text()
    completed = src.split("async def _handle_checkout_completed")[1].split("async def ")[0]
    happy_path = completed.split("issuing refund")[-1]
    assert '"founder_seat_number": seat_number' not in happy_path, (
        "the seat is stamped inside activate_founder_purchase"
    )


def test_migration_allocates_the_lowest_free_seat_not_a_counter():
    sql = MIGRATION.read_text()
    assert "FOR UPDATE" in sql, "allocation must serialize on the counter row"
    assert "generate_series(1, v_total)" in sql, (
        "the next seat must be the lowest number nobody HOLDS, derived from "
        "web_lifetime_purchases — not seats_claimed + 1"
    )
    assert "DROP FUNCTION IF EXISTS claim_founder_seat()" in sql


def test_migration_release_frees_the_seat_it_was_given():
    sql = MIGRATION.read_text()
    release = sql.split("CREATE OR REPLACE FUNCTION release_founder_seat")[1]
    assert "founder_seat_number = p_seat_number" in release, (
        "release_founder_seat previously ignored its argument entirely and just "
        "decremented the counter, which is what caused the collision"
    )
    assert "status = 'refunded'" in release, (
        "guard on status so a stray release cannot strip an active founder's seat"
    )
    assert "released_seat_number" in release, "preserve the number for support/audit"


def test_migration_recomputes_the_public_counter_from_truth():
    """seats_claimed is a cache; every mutation must re-derive it so it cannot drift."""
    sql = MIGRATION.read_text()
    derivations = sql.count("WHERE founder_seat_number IS NOT NULL")
    assert derivations >= 3, (
        "expected seats_claimed to be recomputed on allocate, on release, and "
        "once at migration time"
    )


def test_idempotent_redelivery_returns_the_same_seat():
    sql = MIGRATION.read_text()
    activate = sql.split("CREATE OR REPLACE FUNCTION activate_founder_purchase")[1]
    assert "IF v_status = 'active' AND v_seat IS NOT NULL THEN" in activate, (
        "Stripe retries webhooks; a re-delivery must return the existing seat "
        "rather than allocate a second one"
    )


# =============================================================================
# 3. Price is server-owned; the page can never advertise a stale number
# =============================================================================

def test_marketing_page_renders_the_backend_price():
    page = (REPO / "frontend/src/pages/Lifetime.tsx").read_text()
    assert "seats?.price_usd" in page, "the rendered price must come from GET /seats"
    rendered_literals = re.findall(r'\$\{?149\.99', page)
    assert not rendered_literals, (
        "no hardcoded price in rendered copy — raising "
        "settings.lifetime_price_usd_cents must move every number on the page, "
        "or Stripe charges one price while the page advertises another"
    )


def test_lifetime_value_math_falls_back_to_configured_price():
    src = (BACKEND / "api/v1/subscriptions/lifetime.py").read_text()
    assert "99.99" not in src, "stale literal misreports every founder's 'value saved'"
    assert "lifetime_price_usd_cents" in src


# =============================================================================
# 4. The page is reachable
# =============================================================================

@pytest.mark.parametrize("script,label", [
    ("frontend/scripts/prerender.mjs", "prerender (else it ships as an empty shell)"),
    ("frontend/scripts/generate-seo.mjs", "sitemap"),
])
def test_lifetime_route_is_registered(script, label):
    assert "'/lifetime'" in (REPO / script).read_text(), f"/lifetime missing from {label}"


def test_marketing_footer_links_to_lifetime():
    footer = (REPO / "frontend/src/components/marketing/MarketingFooter.tsx").read_text()
    assert 'to="/lifetime"' in footer, (
        "with no inbound link the page is orphaned — nothing on the site reaches it"
    )
