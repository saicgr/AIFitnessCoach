"""
Regression tests for the undeliverable-recipient guard (fix #3).

THE BUG THIS LOCKS DOWN
-----------------------
`backend/scripts/injury_test_harness.py`, `injury_edge_probe.py`,
`injury_count_probe.py`, `scripts/loadtest/gen_test_tokens.py` and `seed_qa_user.py`
create real `users` rows with UNDELIVERABLE addresses (`@zealova.invalid`,
`@zealova-loadtest.dev`). Verification + lifecycle mail then followed those users
all the way to SES: 566 of 752 lifetime sends bounced (75%). SES suspends a sending
account above ~5%.

`services/email_sender.send` is now the ONE place `resend.Emails.send` is called,
and it drops undeliverable recipients before Resend ever sees them.

INVARIANTS
  * A send to a reserved TLD (.invalid/.test/.local/.localhost/.example) or a known
    synthetic domain NEVER reaches `resend.Emails.send`.
  * A blocked send returns {"id": None, "success": False, "skipped": True,
    "reason": "undeliverable_domain"} and NEVER raises — blocking is normal control
    flow, not an error.
  * A real address still sends, and the response comes back UNCHANGED (call sites
    read `response.get("id")`).
  * Multi-recipient: undeliverable recipients are dropped, the rest still send.
    Only when NONE remain is the send blocked.

Run with: pytest backend/tests/test_email_sender_guard.py -v
"""
from __future__ import annotations

from unittest.mock import MagicMock, patch

import pytest

from services import email_sender


# ═══════════════════════════════════════════════════════════════════════════════
# FIXTURES  (mirrors tests/test_email_service.py's patch-the-resend-module style)
# ═══════════════════════════════════════════════════════════════════════════════

@pytest.fixture(autouse=True)
def _clean_sender_state(monkeypatch):
    """Fresh ledger + a configured Resend key around every test."""
    email_sender.reset_state()
    monkeypatch.setenv("RESEND_API_KEY", "re_test_key")
    monkeypatch.setattr(email_sender.resend, "api_key", "re_test_key", raising=False)
    monkeypatch.setattr(email_sender, "CAP_DISABLED", False)
    monkeypatch.delenv("EMAIL_SUPPRESS_DOMAINS", raising=False)
    yield
    email_sender.reset_state()


@pytest.fixture
def mock_resend():
    """Patch the ONE `resend.Emails.send` the chokepoint owns."""
    with patch.object(
        email_sender.resend.Emails, "send", MagicMock(return_value={"id": "email-abc123"})
    ) as mock_send:
        yield mock_send


def _params(to="user@gmail.com", **extra):
    p = {"from": "Zealova <hey@zealova.com>", "to": [to], "subject": "s", "html": "<p>h</p>"}
    p.update(extra)
    return p


def _assert_blocked(result, reason="undeliverable_domain"):
    assert result["skipped"] is True
    assert result["success"] is False
    assert result["id"] is None
    assert result["reason"] == reason


# ═══════════════════════════════════════════════════════════════════════════════
# THE HARNESS DOMAINS — the 566 bounces
# ═══════════════════════════════════════════════════════════════════════════════

class TestUndeliverableDomainsAreBlocked:

    @pytest.mark.parametrize("address", [
        # The exact addresses our harnesses mint:
        "injury-probe-1@zealova.invalid",         # injury_test_harness.py
        "qa-user@zealova.invalid",                # seed_qa_user.py
        "load-7f2a@zealova-loadtest.dev",         # scripts/loadtest/gen_test_tokens.py
        "prelaunch@cloudtestlabaccounts.com",     # Play pre-launch report devices
        # Reserved TLDs (RFC 2606 / 6761) — always bounce:
        "someone@foo.test",
        "someone@box.local",
        "someone@localhost",
        "someone@my.localhost",
        "someone@corp.example",
        "someone@example",
    ])
    def test_undeliverable_address_never_reaches_resend(self, mock_resend, address):
        result = email_sender.send(
            _params(address), user_id="u1", email_type="streak_at_risk"
        )
        _assert_blocked(result)
        mock_resend.assert_not_called()

    def test_malformed_address_is_treated_as_undeliverable(self, mock_resend):
        """Never hand garbage to SES — a missing @ is a bounce waiting to happen."""
        _assert_blocked(email_sender.send(_params("not-an-email"), email_type="idle_nudge"))
        _assert_blocked(email_sender.send(_params(""), email_type="idle_nudge"))
        mock_resend.assert_not_called()

    def test_display_name_form_is_unwrapped_before_the_domain_check(self, mock_resend):
        """`"QA Bot <qa@zealova.invalid>"` must be blocked, not naively parsed as
        a domain of `zealova.invalid>`."""
        result = email_sender.send(
            _params("QA Bot <qa@zealova.invalid>"), user_id="u1", email_type="comeback"
        )
        _assert_blocked(result)
        mock_resend.assert_not_called()

    def test_case_and_whitespace_do_not_dodge_the_block(self, mock_resend):
        for addr in ("  QA@ZEALOVA.INVALID  ", "Load@Zealova-LoadTest.DEV"):
            _assert_blocked(email_sender.send(_params(addr), email_type="idle_nudge"))
        mock_resend.assert_not_called()

    def test_blocked_send_never_raises(self, mock_resend):
        """Blocking is control flow, not an error. 26 cron jobs depend on this."""
        try:
            result = email_sender.send(
                _params("qa@zealova.invalid"), user_id="u1", email_type="week1_day5"
            )
        except Exception as e:                              # pragma: no cover
            pytest.fail(f"blocked send raised {type(e).__name__}: {e}")
        _assert_blocked(result)

    def test_exempt_transactional_mail_is_blocked_too(self, mock_resend):
        """Cap-exempt does NOT mean bounce-exempt. `verification` mail to a harness
        user IS the bounce source — the guard runs BEFORE the exemption check."""
        result = email_sender.send(
            _params("injury-probe-1@zealova.invalid"),
            user_id="u1",
            email_type="verification",
        )
        _assert_blocked(result)
        mock_resend.assert_not_called()

    def test_is_undeliverable_predicate(self):
        assert email_sender.is_undeliverable("x@zealova.invalid") is True
        assert email_sender.is_undeliverable("x@zealova-loadtest.dev") is True
        assert email_sender.is_undeliverable("x@cloudtestlabaccounts.com") is True
        assert email_sender.is_undeliverable("x@gmail.com") is False
        # `zealova.dev` is NOT `zealova-loadtest.dev` — no substring matching.
        assert email_sender.is_undeliverable("x@zealova.dev") is False
        # `.invalid` is a TLD rule, not a domain rule — any subdomain bounces.
        assert email_sender.is_undeliverable("x@deep.sub.invalid") is True


# ═══════════════════════════════════════════════════════════════════════════════
# REAL ADDRESSES STILL SEND
# ═══════════════════════════════════════════════════════════════════════════════

class TestDeliverableMailStillSends:

    def test_real_address_calls_resend_and_returns_the_response_unchanged(self, mock_resend):
        """The success-path shape is UNCHANGED — every call site does
        `response.get("id")`."""
        params = _params("sai@gmail.com")
        result = email_sender.send(params, email_type="welcome")

        mock_resend.assert_called_once()
        assert result == {"id": "email-abc123"}          # verbatim Resend response
        assert result.get("id") == "email-abc123"
        assert "skipped" not in result

    def test_params_are_passed_through_untouched(self, mock_resend):
        """`tags`, `reply_to`, custom `from` must all survive the chokepoint."""
        params = _params(
            "sai@gmail.com",
            reply_to="support@zealova.com",
            tags=[{"name": "type", "value": "weekly_summary"}],
        )
        email_sender.send(params, email_type="welcome")

        sent = mock_resend.call_args[0][0]
        assert sent["reply_to"] == "support@zealova.com"
        assert sent["tags"] == [{"name": "type", "value": "weekly_summary"}]
        assert sent["from"] == "Zealova <hey@zealova.com>"
        assert sent["html"] == "<p>h</p>"

    def test_bare_string_to_field_is_supported(self, mock_resend):
        """Resend accepts `to` as a str OR a list; call sites use both shapes."""
        email_sender.send(
            {"from": "f", "to": "sai@gmail.com", "subject": "s", "html": "h"},
            email_type="welcome",
        )
        assert mock_resend.call_args[0][0]["to"] == "sai@gmail.com"   # shape preserved

        mock_resend.reset_mock()
        _assert_blocked(email_sender.send(
            {"from": "f", "to": "qa@zealova.invalid", "subject": "s", "html": "h"},
            email_type="welcome",
        ))
        mock_resend.assert_not_called()

    def test_missing_recipient_is_blocked_not_sent(self, mock_resend):
        _assert_blocked(email_sender.send({"from": "f", "subject": "s", "html": "h"}))
        _assert_blocked(email_sender.send({"from": "f", "to": [], "subject": "s", "html": "h"}))
        mock_resend.assert_not_called()


# ═══════════════════════════════════════════════════════════════════════════════
# MULTI-RECIPIENT — partial drop
# ═══════════════════════════════════════════════════════════════════════════════

class TestMultiRecipient:

    def test_undeliverable_recipients_are_dropped_and_the_rest_still_send(self, mock_resend):
        params = _params()
        params["to"] = ["real@gmail.com", "qa@zealova.invalid", "second@outlook.com"]

        result = email_sender.send(params, email_type="welcome")

        mock_resend.assert_called_once()
        assert mock_resend.call_args[0][0]["to"] == ["real@gmail.com", "second@outlook.com"]
        assert result == {"id": "email-abc123"}

    def test_the_callers_params_dict_is_never_mutated(self, mock_resend):
        """The drop happens on a COPY — a caller that reuses/logs `params` after the
        send must still see what it built."""
        params = _params()
        params["to"] = ["real@gmail.com", "qa@zealova.invalid"]

        email_sender.send(params, email_type="welcome")

        assert params["to"] == ["real@gmail.com", "qa@zealova.invalid"]   # untouched

    def test_send_is_blocked_when_no_deliverable_recipient_remains(self, mock_resend):
        params = _params()
        params["to"] = ["qa@zealova.invalid", "load@zealova-loadtest.dev"]

        _assert_blocked(email_sender.send(params, user_id="u1", email_type="idle_nudge"))
        mock_resend.assert_not_called()


# ═══════════════════════════════════════════════════════════════════════════════
# ENV-DRIVEN SUPPRESSION + UNCONFIGURED
# ═══════════════════════════════════════════════════════════════════════════════

class TestEnvSuppressionAndConfiguration:

    def test_email_suppress_domains_extends_the_block_list(self, mock_resend, monkeypatch):
        """Ops can kill a bouncing domain with an env change and no redeploy — the
        list is read at CALL time, not import time."""
        assert email_sender.is_undeliverable("someone@leaky-partner.com") is False

        monkeypatch.setenv("EMAIL_SUPPRESS_DOMAINS", "leaky-partner.com, other.io")

        assert email_sender.is_undeliverable("someone@leaky-partner.com") is True
        assert email_sender.is_undeliverable("someone@other.io") is True

        _assert_blocked(email_sender.send(
            _params("someone@leaky-partner.com"), user_id="u1", email_type="idle_nudge"
        ))
        mock_resend.assert_not_called()

        # Unlisted domains are unaffected.
        assert email_sender.send(_params("real@gmail.com"), email_type="welcome")["id"]
        mock_resend.assert_called_once()

    def test_empty_suppress_domains_env_does_not_block_everything(self, mock_resend, monkeypatch):
        """A stray trailing comma must not turn "" into a blocked domain."""
        monkeypatch.setenv("EMAIL_SUPPRESS_DOMAINS", " , ,")
        assert email_sender.send(_params("real@gmail.com"), email_type="welcome")["id"]
        mock_resend.assert_called_once()

    def test_no_api_key_returns_the_skipped_shape_and_does_not_raise(self, monkeypatch):
        monkeypatch.delenv("RESEND_API_KEY", raising=False)
        monkeypatch.setattr(email_sender.resend, "api_key", None, raising=False)

        with patch.object(email_sender.resend.Emails, "send") as mock_send:
            try:
                result = email_sender.send(
                    _params("real@gmail.com"), user_id="u1", email_type="idle_nudge"
                )
            except Exception as e:                          # pragma: no cover
                pytest.fail(f"unconfigured send raised {type(e).__name__}: {e}")

        _assert_blocked(result, reason="not_configured")
        mock_send.assert_not_called()

    def test_undeliverable_check_runs_before_the_api_key_check(self, monkeypatch):
        """Reason precedence matters for triage: a harness address must report
        `undeliverable_domain`, not `not_configured`."""
        monkeypatch.delenv("RESEND_API_KEY", raising=False)
        monkeypatch.setattr(email_sender.resend, "api_key", None, raising=False)

        result = email_sender.send(_params("qa@zealova.invalid"), email_type="verification")
        _assert_blocked(result, reason="undeliverable_domain")


# ═══════════════════════════════════════════════════════════════════════════════
# THE CHOKEPOINT ITSELF — no bypass routes
# ═══════════════════════════════════════════════════════════════════════════════

class TestChokepointIsTheOnlyRoute:

    def test_no_direct_resend_sends_outside_the_chokepoint(self):
        """The fix-#3 gate: 46 direct `resend.Emails.send(...)` call sites existed
        across 13 files. Every one of them must now go through `email_sender.send`.

        Also catches the deleted Sunday `_resend.Emails.send` block in email_cron.py
        (fix #1's weekly merge).
        """
        import pathlib
        import re

        root = pathlib.Path(__file__).resolve().parents[1]
        allow = {
            "services/email_sender.py",                          # the chokepoint itself
            "scripts/render_transactional_email_preview.py",     # monkeypatches, never sends
        }
        # A CALL: `resend.Emails.send(` / `_resend.Emails.send(`. Prose mentions of
        # the symbol (docs, the audit script's own docstring) are not offenders, so
        # comments and `backticked` spans are stripped before matching — but a real
        # call anywhere, including in the audit script, still trips this.
        pattern = re.compile(r"\b(?:resend|_resend)\.Emails\.send\s*\(")

        offenders: list[str] = []
        for sub in ("api", "services", "scripts"):
            for path in (root / sub).rglob("*.py"):
                rel = str(path.relative_to(root))
                if rel in allow:
                    continue
                for lineno, line in enumerate(path.read_text().splitlines(), 1):
                    code = re.sub(r"#.*$", "", line)          # drop comments
                    code = re.sub(r"`[^`]*`", "", code)       # drop `backticked` prose
                    if pattern.search(code):
                        offenders.append(f"{rel}:{lineno}: {line.strip()}")

        assert not offenders, (
            "Direct Resend sends BYPASS the undeliverable-domain guard and the "
            "frequency cap:\n" + "\n".join(offenders)
        )

    def test_sunday_cardio_digest_send_is_gone_from_email_cron(self):
        """Fix #1: the standalone Sunday `cardio_digest` send (and its local
        `import resend as _resend`) is retired — cardio is now a SECTION inside the
        Monday weekly summary. Two recaps in 24h behind one preference flag was the
        bug."""
        import pathlib

        src = (
            pathlib.Path(__file__).resolve().parents[1] / "api" / "v1" / "email_cron.py"
        ).read_text()

        assert "import resend as _resend" not in src
        assert "_resend.Emails.send" not in src
