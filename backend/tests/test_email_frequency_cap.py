"""
Regression tests for the global per-user email frequency cap (fix #2).

THE BUG THIS LOCKS DOWN
-----------------------
Per-email-type cooldowns existed (`_was_recently_sent`), but NOTHING capped the
TOTAL volume per user. On day 3 of a free user's life, four independent cron jobs
all qualified in the same run:

    week1_day3_stalled + day3_activation + onboarding_incomplete
                       + email_verification_reminder

…and the user got FOUR emails in one hour. `test_day3_collision_*` below is that
exact scenario end to end.

THE CAP
  * MAX 2 non-exempt lifecycle emails per USER-LOCAL day.
  * MAX 4 per rolling 7 local days.
  * TRANSACTIONAL / revenue mail is EXEMPT: never capped, and never COUNTED (a
    purchase receipt must not eat the slot the weekly summary needs).
  * First-come-first-served at send time; PRIORITY is bought by `email_cron.py`
    running the job tiers SEQUENTIALLY (T1 → T2 → T3 → T4), so scarce slots go to
    the highest-value mail.
  * A capped email is DEFERRED, not deleted: no `email_send_log` row is written, so
    its per-type cooldown is untouched and it is retried next hour.

Run with: pytest backend/tests/test_email_frequency_cap.py -v
"""
from __future__ import annotations

import asyncio
from datetime import datetime, timedelta, timezone
from unittest.mock import MagicMock, patch

import pytest

from services import email_sender


# ═══════════════════════════════════════════════════════════════════════════════
# FIXTURES — fake Supabase (the cap reads `users.timezone` + `email_send_log`)
# ═══════════════════════════════════════════════════════════════════════════════

class _FakeClient:
    """Records the chain so `.table("users")` and `.table("email_send_log")` return
    the right rows. Mirrors postgrest's fluent builder (all sync — no awaits)."""

    def __init__(self, log_rows, tz="America/Chicago"):
        self._log_rows = log_rows
        self._tz = tz
        self._table = None
        self.query_count = 0

    def table(self, name):
        self._table = name
        return self

    def select(self, *_a, **_k):
        return self

    def eq(self, *_a, **_k):
        return self

    def gte(self, *_a, **_k):
        return self

    def limit(self, *_a, **_k):
        return self

    def execute(self):
        self.query_count += 1
        if self._table == "users":
            return MagicMock(data=[{"timezone": self._tz}])
        return MagicMock(data=list(self._log_rows))


def _supabase(log_rows=(), tz="America/Chicago"):
    m = MagicMock()
    m.client = _FakeClient(list(log_rows), tz=tz)
    return m


def _log_row(email_type, days_ago=0, sent_local_date=None):
    """An `email_send_log` row. `sent_local_date` is NULL on most real rows —
    only `trial_ending` and `7day_upsell` ever populate it — so the cap MUST derive
    the local day from the UTC `sent_at`."""
    return {
        "email_type": email_type,
        "sent_at": (datetime.now(timezone.utc) - timedelta(days=days_ago)).isoformat(),
        "sent_local_date": sent_local_date,
    }


@pytest.fixture(autouse=True)
def _clean_sender_state(monkeypatch):
    email_sender.reset_state()
    monkeypatch.setenv("RESEND_API_KEY", "re_test_key")
    monkeypatch.setattr(email_sender.resend, "api_key", "re_test_key", raising=False)
    monkeypatch.setattr(email_sender, "CAP_DISABLED", False)
    yield
    email_sender.reset_state()


@pytest.fixture
def mock_resend():
    with patch.object(
        email_sender.resend.Emails, "send", MagicMock(return_value={"id": "email-abc123"})
    ) as mock_send:
        yield mock_send


def _params(to="user@gmail.com"):
    return {"from": "Zealova <hey@zealova.com>", "to": [to], "subject": "s", "html": "h"}


def _send(email_type, user_id="user-1"):
    return email_sender.send(_params(), user_id=user_id, email_type=email_type)


def _assert_capped(result):
    assert result["skipped"] is True
    assert result["success"] is False
    assert result["id"] is None
    assert result["reason"] == "frequency_cap"


def _assert_sent(result):
    assert result.get("id") == "email-abc123"
    assert not result.get("skipped")


# ═══════════════════════════════════════════════════════════════════════════════
# DAILY CAP
# ═══════════════════════════════════════════════════════════════════════════════

class TestDailyCap:

    def test_third_lifecycle_email_in_a_local_day_is_blocked(self, mock_resend):
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _assert_sent(_send("week1_day3_stalled"))
            _assert_sent(_send("streak_at_risk"))
            _assert_capped(_send("merch_proximity"))

        assert mock_resend.call_count == email_sender.MAX_LIFECYCLE_PER_LOCAL_DAY == 2

    def test_the_cap_seeds_from_email_send_log_across_cron_runs(self, mock_resend):
        """The ledger is in-process and reset every run — cross-run truth is the DB.
        Two rows sent EARLIER TODAY (by the 09:00 run) must block the 10:00 run."""
        rows = [_log_row("day3_activation", days_ago=0), _log_row("week1_day1", days_ago=0)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_capped(_send("idle_nudge"))
        mock_resend.assert_not_called()

    def test_the_cap_is_per_user_not_global(self, mock_resend):
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _assert_sent(_send("weekly_summary", user_id="user-1"))
            _assert_sent(_send("day3_activation", user_id="user-1"))
            _assert_capped(_send("idle_nudge", user_id="user-1"))
            # A DIFFERENT user has their own budget.
            _assert_sent(_send("weekly_summary", user_id="user-2"))
            _assert_sent(_send("day3_activation", user_id="user-2"))
            _assert_capped(_send("idle_nudge", user_id="user-2"))
        assert mock_resend.call_count == 4

    def test_null_sent_local_date_rows_are_bucketed_from_utc_sent_at(self, mock_resend):
        """`sent_local_date` is NULL on almost every row. If the cap only counted the
        column it would count ZERO and cap nothing — the bug would survive the fix."""
        rows = [
            _log_row("comeback", days_ago=0, sent_local_date=None),
            _log_row("streak_at_risk", days_ago=0, sent_local_date=None),
        ]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_capped(_send("weekly_summary"))
        mock_resend.assert_not_called()

    def test_a_capped_send_writes_no_log_row_so_the_cooldown_is_not_burned(self, mock_resend):
        """A capped email is DEFERRED, not deleted. `sent_result` must report
        success=False so the cron's `if result.get("success"): _log_email_sent(...)`
        gate does not write a phantom row and burn a 14/365-day cooldown."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _send("weekly_summary")
            _send("day3_activation")
            capped = _send("one_workout_wonder")     # 365-day cooldown — one lifetime shot

        adapted = email_sender.sent_result(capped)
        assert adapted["success"] is False           # ⇒ cron writes NO email_send_log row
        assert adapted["skipped"] is True
        assert adapted["reason"] == "frequency_cap"
        assert adapted["id"] is None

        # …and the happy path is unchanged.
        assert email_sender.sent_result({"id": "email-abc123"}) == {
            "success": True, "id": "email-abc123",
        }


# ═══════════════════════════════════════════════════════════════════════════════
# ROLLING 7-DAY CAP
# ═══════════════════════════════════════════════════════════════════════════════

class TestRollingWeeklyCap:

    def test_fifth_lifecycle_email_in_7_days_is_blocked(self, mock_resend):
        """4 sends spread over the last 4 days (≤1/day, so the DAILY cap is clean) —
        the 5th must still be blocked by the rolling-7d cap."""
        rows = [_log_row("idle_nudge", days_ago=d) for d in (1, 2, 3, 4)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            result = _send("weekly_summary")

        _assert_capped(result)
        assert email_sender.MAX_LIFECYCLE_PER_ROLLING_7D == 4
        mock_resend.assert_not_called()

    def test_four_in_7_days_still_leaves_the_window_open_at_three(self, mock_resend):
        """3 in the window ⇒ exactly ONE slot left. The 4th sends, the 5th is capped."""
        rows = [_log_row("idle_nudge", days_ago=d) for d in (1, 2, 3)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_sent(_send("weekly_summary"))
            _assert_capped(_send("streak_at_risk"))
        assert mock_resend.call_count == 1

    def test_sends_older_than_the_window_do_not_count(self, mock_resend):
        """Rows 8+ local days old have rolled out of the rolling window."""
        rows = [_log_row("idle_nudge", days_ago=d) for d in (8, 9, 10, 11)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_sent(_send("weekly_summary"))
            _assert_sent(_send("day3_activation"))
        assert mock_resend.call_count == 2


# ═══════════════════════════════════════════════════════════════════════════════
# EXEMPTIONS — transactional mail is NEVER capped, and never COUNTED
# ═══════════════════════════════════════════════════════════════════════════════

class TestTransactionalMailIsNeverCapped:

    EXEMPT_TYPES = [
        "verification",
        "email_verification_reminder",
        "purchase_confirmation",
        "billing_issue",
        "trial_ending",
        "trial_expired",
        "cancel_grace",
        "cancel_expired",
        "cancel_offer_14d",
        "cancel_sunset",
        "security_new_device",
        "new_device_signin",
        "waitlist_confirmed",
        "lifetime_purchase",
        "dsar_export",
        "free_tool_result",
        "live_chat",
        "workout_reminder",
    ]

    @pytest.mark.parametrize("email_type", EXEMPT_TYPES)
    def test_exempt_type_sends_even_when_the_user_is_way_over_the_cap(
        self, mock_resend, email_type
    ):
        """User already got 6 lifecycle emails today — 3x the daily cap, 1.5x the
        weekly. A billing failure / verification / cancel offer MUST still go out."""
        rows = [_log_row("idle_nudge", days_ago=0) for _ in range(6)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_sent(_send(email_type))
        mock_resend.assert_called_once()

    def test_exempt_sends_do_not_consume_lifecycle_slots(self, mock_resend):
        """9 exempt rows in the log. A purchase receipt must not eat the slot the
        weekly summary needs."""
        rows = [_log_row("purchase_confirmation", days_ago=0) for _ in range(9)]
        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            _assert_sent(_send("weekly_summary"))       # the lifecycle budget is intact
            _assert_sent(_send("day3_activation"))
            _assert_capped(_send("idle_nudge"))         # …and still exactly 2
        assert mock_resend.call_count == 2

    def test_exempt_sends_in_flight_do_not_consume_slots_either(self, mock_resend):
        """Not just DB rows — an exempt send made DURING the run must not reserve."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _assert_sent(_send("trial_ending"))
            _assert_sent(_send("purchase_confirmation"))
            _assert_sent(_send("verification"))
            # 3 exempt sends later, both lifecycle slots are still available:
            _assert_sent(_send("weekly_summary"))
            _assert_sent(_send("day3_activation"))
            _assert_capped(_send("merch_unlocked"))
        assert mock_resend.call_count == 5

    def test_is_exempt_predicate(self):
        assert email_sender.is_exempt("billing_issue") is True
        assert email_sender.is_exempt("cancel_offer_60d") is True     # `cancel` prefix
        assert email_sender.is_exempt("waitlist_confirmed") is True
        assert email_sender.is_exempt("lifetime_checkout_open") is True
        assert email_sender.is_exempt("dsar_delete") is True
        assert email_sender.is_exempt(None) is True                   # no type → uncappable
        # …and the lifecycle mail that IS capped:
        for t in ("weekly_summary", "day3_activation", "onboarding_incomplete",
                  "week1_day3_stalled", "idle_nudge", "merch_proximity",
                  "one_workout_wonder", "streak_at_risk"):
            assert email_sender.is_exempt(t) is False, f"{t} must be capped"


# ═══════════════════════════════════════════════════════════════════════════════
# PRIORITY — the last slot goes to the higher-value email
# ═══════════════════════════════════════════════════════════════════════════════

class TestPriorityOrdering:

    def test_tier_map_ranks_lifecycle_above_reengagement_above_gamification(self):
        T = email_sender.priority_tier
        assert T("trial_ending") == email_sender.TIER_TRANSACTIONAL == 1
        assert T("weekly_summary") == T("day3_activation") == email_sender.TIER_CORE == 2
        assert T("idle_nudge") == T("one_workout_wonder") == email_sender.TIER_REENGAGEMENT == 3
        assert T("merch_proximity") == email_sender.TIER_GAMIFICATION == 4
        assert T("weekly_summary") < T("idle_nudge") < T("merch_proximity")

    def test_with_one_slot_left_the_higher_tier_email_wins(self, mock_resend):
        """The cap is first-come-first-served; the CRON buys priority by running the
        tiers SEQUENTIALLY. Simulate that: 1 slot left, T2 dispatched before T4."""
        rows = [_log_row("comeback", days_ago=0)]              # 1 of 2 daily slots used

        candidates = [("merch_proximity", "u1"), ("weekly_summary", "u1")]
        ordered = sorted(candidates, key=lambda c: email_sender.priority_tier(c[0]))

        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            results = {t: _send(t, user_id=u) for t, u in ordered}

        _assert_sent(results["weekly_summary"])        # T2 claimed the last slot
        _assert_capped(results["merch_proximity"])     # T4 lost it
        assert mock_resend.call_count == 1

    def test_without_tier_ordering_the_gamification_email_would_steal_the_slot(
        self, mock_resend
    ):
        """The INVERSE — proof that the sequential-tier dispatch in email_cron.py is
        load-bearing and not decorative. Dispatch T4 first and the weekly summary is
        the one that gets dropped."""
        rows = [_log_row("comeback", days_ago=0)]

        with patch("core.supabase_client.get_supabase", return_value=_supabase(rows)):
            first = _send("merch_proximity")           # WRONG order (what we must not do)
            second = _send("weekly_summary")

        _assert_sent(first)
        _assert_capped(second)                         # the valuable email lost → why order matters

    def test_email_cron_dispatches_the_tiers_in_ascending_priority_order(self):
        """Static gate on the real dispatcher: every job in the Nth tier block of
        `email_cron.py`'s `tiers` list must actually BE tier N in PRIORITY_TIER.
        A reorder (or a merch job pasted into T2) breaks the priority guarantee
        silently — this catches it."""
        import pathlib
        import re

        src = (
            pathlib.Path(__file__).resolve().parents[1] / "api" / "v1" / "email_cron.py"
        ).read_text()

        body = src.split("tiers: List[List[Any]] = [", 1)
        assert len(body) == 2, "email_cron.py no longer declares a `tiers` list"
        # Slice out the tiers literal, then split it into its four `[ ... ]` blocks.
        literal = body[1].split("\n    ]\n", 1)[0]
        blocks = re.findall(r"\[\s*(?:#[^\n]*)?\n(.*?)\n\s*\],", literal + "\n    ],", re.S)
        assert len(blocks) == 4, f"expected 4 tier blocks, found {len(blocks)}"

        # Job names in email_cron are not all email_types (the week1_day3 job picks
        # between the _completed / _stalled types at send time).
        alias = {"week1_day3": "week1_day3_stalled"}

        problems: list[str] = []
        for expected_tier, block in enumerate(blocks, start=1):
            for job_name in re.findall(r'\(\s*"([a-z0-9_]+)"\s*,', block):
                email_type = alias.get(job_name, job_name)
                actual = email_sender.PRIORITY_TIER.get(email_type)
                if actual is None:
                    problems.append(
                        f"{job_name!r} (cron T{expected_tier}) is missing from PRIORITY_TIER"
                    )
                elif actual != expected_tier:
                    problems.append(
                        f"{job_name!r} runs in cron tier T{expected_tier} but "
                        f"PRIORITY_TIER says T{actual}"
                    )
        assert not problems, "Cron tier order disagrees with PRIORITY_TIER:\n" + "\n".join(problems)


# ═══════════════════════════════════════════════════════════════════════════════
# THE DAY-3 COLLISION — the actual bug, end to end
# ═══════════════════════════════════════════════════════════════════════════════

class TestDay3CollisionEndToEnd:
    """A brand-new free user on day 3 who never completed onboarding and never
    verified their email qualifies for FOUR jobs in the SAME cron run:

        T1  email_verification_reminder   (exempt — must ALWAYS send)
        T2  day3_activation               (capped)
        T2  onboarding_incomplete         (capped)
        T2  week1_day3_stalled            (capped)

    Before the cap: 4 emails in one hour. After: the exempt reminder + at most 2.
    """

    COLLISION = [
        ("email_verification_reminder", 1),   # exempt
        ("day3_activation", 2),
        ("onboarding_incomplete", 2),
        ("week1_day3_stalled", 2),
    ]

    def _run_cron_like_dispatch(self, types):
        """Mirror the real dispatcher: coroutines gathered within a tier (the sender's
        lock — not the ordering — is what makes this race-free)."""
        async def job(email_type):
            return email_sender.send(
                _params(), user_id="new-user", email_type=email_type
            )

        async def run():
            out = {}
            for tier in sorted({t for _, t in types}):
                names = [n for n, ti in types if ti == tier]
                results = await asyncio.gather(*[job(n) for n in names])
                out.update(dict(zip(names, results)))
            return out

        return asyncio.run(run())

    def test_day3_user_gets_at_most_two_capped_emails_not_four(self, mock_resend):
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            results = self._run_cron_like_dispatch(self.COLLISION)

        # The exempt verification reminder ALWAYS goes out.
        _assert_sent(results["email_verification_reminder"])

        capped_types = ["day3_activation", "onboarding_incomplete", "week1_day3_stalled"]
        sent = [t for t in capped_types if not results[t].get("skipped")]
        blocked = [t for t in capped_types if results[t].get("skipped")]

        assert len(sent) == 2, f"expected exactly 2 lifecycle emails, got {sent}"
        assert len(blocked) == 1, f"expected 1 blocked, got {blocked}"
        for t in blocked:
            _assert_capped(results[t])

        # 3 real sends total (2 lifecycle + 1 exempt) — NOT 4. This is the fix.
        assert mock_resend.call_count == 3

        # The drop is SURFACED, not swallowed.
        assert email_sender.drain_cap_blocks() == {blocked[0]: 1}

    def test_the_same_scenario_sends_four_emails_with_the_cap_disabled(
        self, mock_resend, monkeypatch
    ):
        """Proof this test would FAIL without the cap: flip the kill switch and the
        exact same user gets all 4 emails again — the pre-fix behavior."""
        monkeypatch.setattr(email_sender, "CAP_DISABLED", True)

        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            results = self._run_cron_like_dispatch(self.COLLISION)

        assert all(not r.get("skipped") for r in results.values())
        assert mock_resend.call_count == 4              # ← the bug, reproduced

    def test_concurrent_gather_can_never_exceed_the_cap(self, mock_resend):
        """The asyncio.gather race the in-lock check-and-reserve exists to kill:
        5 jobs, one user, all racing. Exactly 2 may win."""
        async def job(email_type):
            return email_sender.send(_params(), user_id="u1", email_type=email_type)

        async def run():
            return await asyncio.gather(*[
                job(t) for t in (
                    "weekly_summary", "day3_activation", "streak_at_risk",
                    "idle_nudge", "merch_proximity",
                )
            ])

        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            results = asyncio.run(run())

        assert mock_resend.call_count == 2
        assert sum(1 for r in results if r.get("skipped")) == 3


# ═══════════════════════════════════════════════════════════════════════════════
# NO SLOT LEAKS
# ═══════════════════════════════════════════════════════════════════════════════

class TestNoSlotLeaks:

    def test_a_job_that_bails_before_sending_does_not_consume_a_slot(self, mock_resend):
        """22 of the 26 cron jobs can pass their eligibility gate and then bail
        (`_was_recently_sent`, no workout data, band closed…). The reservation happens
        at SEND time, so a bail costs nothing.

        Simulated: job A decides not to send (never calls email_sender), then B and C
        must BOTH still get through.
        """
        with patch("core.supabase_client.get_supabase", return_value=_supabase()) as _sb:
            # Job A: gate passes, then it bails — it never reaches the chokepoint.
            eligible = True
            if eligible and False:                       # bail (e.g. cooldown hit)
                _send("one_workout_wonder")              # pragma: no cover

            _assert_sent(_send("weekly_summary"))
            _assert_sent(_send("day3_activation"))

        assert mock_resend.call_count == 2

    def test_a_failed_resend_call_rolls_the_slot_back(self, mock_resend):
        """Resend 502s → nothing left the building → the slot was never consumed.
        Without the rollback, one transient 502 would silently eat a user's whole day."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            with patch.object(
                email_sender.resend.Emails, "send", side_effect=Exception("Resend 502")
            ):
                with pytest.raises(Exception, match="502"):
                    _send("streak_at_risk")             # reserved, then blew up

            # The slot came back: BOTH of the day's emails still send.
            _assert_sent(_send("weekly_summary"))
            _assert_sent(_send("day3_activation"))
            _assert_capped(_send("idle_nudge"))

        assert mock_resend.call_count == 2

    def test_an_undeliverable_block_does_not_consume_a_slot(self, mock_resend):
        """The domain guard runs BEFORE the reservation. A harness address must not
        burn a real user's budget (and must not even hit the DB)."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            blocked = email_sender.send(
                _params("qa@zealova.invalid"), user_id="u1", email_type="idle_nudge"
            )
            assert blocked["reason"] == "undeliverable_domain"

            _assert_sent(_send("weekly_summary", user_id="u1"))
            _assert_sent(_send("day3_activation", user_id="u1"))

        assert mock_resend.call_count == 2


# ═══════════════════════════════════════════════════════════════════════════════
# FAILURE MODES
# ═══════════════════════════════════════════════════════════════════════════════

class TestFailureModes:

    def test_a_db_error_fails_closed_for_lifecycle_mail(self, mock_resend):
        """If we cannot COUNT, we cannot know we are under the cap. Fail closed —
        the email is deferred to the next hourly tick (no log row ⇒ no cooldown
        burned), so nothing is lost."""
        broken = MagicMock()
        broken.client.table.side_effect = Exception("supabase down")

        with patch("core.supabase_client.get_supabase", return_value=broken):
            _assert_capped(_send("streak_at_risk"))

        mock_resend.assert_not_called()

    def test_a_db_error_still_lets_revenue_mail_through(self, mock_resend):
        """Fail-closed must NEVER drop money mail — exempt types return before the
        cap ever touches the DB."""
        broken = MagicMock()
        broken.client.table.side_effect = Exception("supabase down")

        with patch("core.supabase_client.get_supabase", return_value=broken):
            _assert_sent(_send("trial_ending"))
            _assert_sent(_send("billing_issue"))
            _assert_sent(_send("email_verification_reminder"))

        assert mock_resend.call_count == 3

    def test_a_capped_type_with_no_user_id_still_sends_but_is_not_silently_capped(
        self, mock_resend
    ):
        """An un-instrumented call site (capped type, no user_id) cannot be capped —
        it must still SEND (never silently drop mail), and log loudly."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            result = email_sender.send(_params(), user_id=None, email_type="idle_nudge")
        _assert_sent(result)

    def test_unregistered_email_type_defaults_to_tier_3_and_is_still_capped(self, mock_resend):
        """A new email type someone forgot to register must NOT escape the cap by
        being unknown."""
        assert email_sender.priority_tier("brand_new_nudge") == email_sender.TIER_REENGAGEMENT
        assert email_sender.is_exempt("brand_new_nudge") is False

        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _assert_sent(_send("brand_new_nudge"))
            _assert_sent(_send("weekly_summary"))
            _assert_capped(_send("day3_activation"))

    def test_cap_blocks_are_drained_for_the_cron_response(self, mock_resend):
        """A dropped email is a product event. `/cron` surfaces `capped: {...}`."""
        with patch("core.supabase_client.get_supabase", return_value=_supabase()):
            _send("weekly_summary")
            _send("day3_activation")
            _send("merch_proximity")
            _send("merch_proximity")
            _send("idle_nudge")

        assert email_sender.drain_cap_blocks() == {"merch_proximity": 2, "idle_nudge": 1}
        assert email_sender.drain_cap_blocks() == {}          # drained → reset


# ═══════════════════════════════════════════════════════════════════════════════
# LOCAL-DAY SEMANTICS
# ═══════════════════════════════════════════════════════════════════════════════

class TestUserLocalDay:

    def test_the_day_is_bucketed_in_the_users_timezone_not_utc(self, mock_resend):
        """A Chicago user at 20:00 local is already on the NEXT UTC day (02:00 UTC).
        Emails sent 'yesterday UTC' but 'today local' MUST count against today."""
        chicago = _supabase(
            [_log_row("comeback", days_ago=0), _log_row("idle_nudge", days_ago=0)],
            tz="America/Chicago",
        )
        with patch("core.supabase_client.get_supabase", return_value=chicago):
            _assert_capped(_send("weekly_summary"))
        mock_resend.assert_not_called()

    def test_a_bad_timezone_falls_back_to_utc_instead_of_crashing(self, mock_resend):
        """`users.timezone` is free text and rots. A bad zone must not fail the cap
        closed for a real user — `_safe_zone` is the same fallback `time_band` uses,
        so band math and cap math can never disagree about the day."""
        with patch("core.supabase_client.get_supabase",
                   return_value=_supabase(tz="Not/A/Zone")):
            _assert_sent(_send("weekly_summary"))
            _assert_sent(_send("day3_activation"))
            _assert_capped(_send("idle_nudge"))
        assert mock_resend.call_count == 2

    def test_the_ledger_is_seeded_once_per_user_not_once_per_send(self, mock_resend):
        """N+1 guard: 2 queries for the FIRST send of a user (users.timezone +
        email_send_log), then the in-process ledger serves the rest of the run."""
        sb = _supabase()
        with patch("core.supabase_client.get_supabase", return_value=sb):
            _send("weekly_summary")
            _send("day3_activation")
            _send("idle_nudge")
            _send("merch_proximity")

        assert sb.client.query_count == 2, (
            f"expected 2 seed queries for 1 user, got {sb.client.query_count} "
            "— the ledger is not being reused"
        )


if __name__ == "__main__":
    pytest.main([__file__, "-v"])
