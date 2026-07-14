#!/usr/bin/env python3
"""
Email chokepoint audit — regression gate for the ONE guarded Resend call site.

`services/email_sender.py` is the single place `resend.Emails.send` may be called.
It is what blocks undeliverable recipients (the injury/loadtest harnesses mint users
at `@zealova.invalid` / `@zealova-loadtest.dev`; 566 of 752 lifetime sends bounced —
75%, and SES suspends an account above ~5%) and what enforces the global per-user
frequency cap (2 lifecycle emails per user-local day, 4 per rolling 7).

Both protections are bypassed by ANY code that reaches Resend on its own. Before the
2026-07 refactor there were 46 direct `resend.Emails.send(...)` call sites across 13
files and no chokepoint at all. This gate exists so a 47th can never appear.

What it checks:
  1. DIRECT SEND — no file in backend/ other than services/email_sender.py may CALL
     into the `resend` namespace (`resend.Emails.send`, `resend.Batch.send`,
     `from resend import Emails; Emails.send(...)`, aliased imports). Parsed with
     `ast`, so a comment, a docstring or a string literal can never trip it — and a
     rename (`import resend as r`) can never hide from it. Monkeypatch ASSIGNMENTS
     (`resend.Emails.send = fake` in the preview script, `monkeypatch.setattr(...)`
     in tests) are deliberately allowed: they are interception, not sending.
  2. BACKDOOR — app code (`api/`, `services/`) may not even IMPORT resend, and no
     file may hand-roll HTTP to `api.resend.com`. Importing the SDK in a request
     path is the seed of the next unguarded call site.
  3. CAP PRIORITY — every cron job registered in `email_cron.py`'s `tiers` list must
     have a `PRIORITY_TIER` entry in email_sender, at the SAME tier index, and every
     `_job_*` defined in email_cron must be registered in `tiers` (a job with no tier
     silently loses cap priority — the daily 2-slot budget then goes first-come).
     Every literal `email_type=` handed to `email_sender.send` must be exempt or
     registered, else `priority_tier()` logs 🚨 and silently demotes it to T3.
  4. RETIRED TYPES — `cardio_digest` (the standalone Sunday recap, now a section
     inside the Monday `weekly_summary`) must not be sent again.

Usage:
    python scripts/audit_email_chokepoint.py            # report
    python scripts/audit_email_chokepoint.py --check    # exit 1 on any violation

Run --check after touching ANY email code path, adding a cron job, or adding an
email_type. Exit 0 = clean, 1 = violations, 2 = the gate could not run.
"""
import argparse
import ast
import sys
from pathlib import Path
from typing import Dict, List, Optional, Set, Tuple

BACKEND = Path(__file__).resolve().parent.parent

# The one blessed file. Everything else must go through it.
CHOKEPOINT = Path("services/email_sender.py")
EMAIL_CRON = Path("api/v1/email_cron.py")

# The gate itself names the very patterns it hunts for (`api.resend.com`,
# `resend.Emails.send`) in its docstrings and messages. Scanning itself would be a
# guaranteed self-report, so it is the one file excluded from the source walk.
SELF = Path("scripts/audit_email_chokepoint.py")

# App code — a request/cron path. May not import the Resend SDK at all.
APP_DIRS = ("api", "services")

SKIP_DIR_NAMES = {
    "__pycache__", "node_modules", "migrations", "alembic",
    "venv", ".venv", ".venv312", "env", ".git", "site-packages",
}

# Retired email types: still present in historical email_send_log rows, but nothing
# may SEND them anymore.
RETIRED_EMAIL_TYPES = {"cardio_digest"}


class Violation:
    __slots__ = ("file", "line", "func", "rule", "message")

    def __init__(self, file: str, line: int, func: str, rule: str, message: str):
        self.file, self.line, self.func, self.rule, self.message = (
            file, line, func, rule, message,
        )

    def __str__(self) -> str:
        where = f"{self.file}:{self.line}"
        return f"  [{self.rule}] {where} — {self.func}() — {self.message}"


# ═══════════════════════════════════════════════════════════════════════════════
# Source walking
# ═══════════════════════════════════════════════════════════════════════════════

def _iter_sources():
    """Yield (relative_path, source_text, ast_tree) for every backend .py file."""
    for py in sorted(BACKEND.rglob("*.py")):
        rel = py.relative_to(BACKEND)
        if rel == SELF:
            continue
        if any(part in SKIP_DIR_NAMES or part.startswith(".venv") for part in rel.parts):
            continue
        try:
            src = py.read_text()
            tree = ast.parse(src, filename=str(rel))
        except (OSError, SyntaxError, UnicodeDecodeError) as e:
            print(f"⚠️  could not parse {rel}: {e}", file=sys.stderr)
            continue
        yield rel, src, tree


def _enclosing_functions(tree: ast.AST) -> Dict[int, str]:
    """Map every line inside a function body to that function's name.

    Innermost wins (a nested def shadows its parent), so a violation is reported
    against the function you actually have to open and fix.
    """
    spans: List[Tuple[int, int, str]] = []
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            end = getattr(node, "end_lineno", None) or node.lineno
            spans.append((node.lineno, end, node.name))
    spans.sort(key=lambda s: s[1] - s[0], reverse=True)   # widest first → innermost last
    line_map: Dict[int, str] = {}
    for start, end, name in spans:
        for ln in range(start, end + 1):
            line_map[ln] = name
    return line_map


def _dotted(node: ast.AST) -> Optional[str]:
    """`a.b.c` → "a.b.c" for Name/Attribute chains; None for anything else."""
    parts: List[str] = []
    cur = node
    while isinstance(cur, ast.Attribute):
        parts.append(cur.attr)
        cur = cur.value
    if not isinstance(cur, ast.Name):
        return None
    parts.append(cur.id)
    return ".".join(reversed(parts))


# ═══════════════════════════════════════════════════════════════════════════════
# Rule 1 + 2 — nothing but the chokepoint may reach Resend
# ═══════════════════════════════════════════════════════════════════════════════

def _resend_bindings(tree: ast.AST) -> Tuple[Set[str], Set[str]]:
    """Names in this module that point at the resend SDK.

    Returns (module_aliases, member_aliases):
      * module_aliases  — `import resend` / `import resend as r`   → {"resend"} / {"r"}
      * member_aliases  — `from resend import Emails as E`         → {"E"}
    """
    module_aliases: Set[str] = set()
    member_aliases: Set[str] = set()
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for a in node.names:
                if a.name == "resend" or a.name.startswith("resend."):
                    module_aliases.add((a.asname or a.name).split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            mod = node.module or ""
            if mod == "resend" or mod.startswith("resend."):
                for a in node.names:
                    member_aliases.add(a.asname or a.name)
    return module_aliases, member_aliases


def check_direct_resend_calls(rel: Path, tree: ast.AST) -> List[Violation]:
    """Rule 1: any CALL into the resend namespace outside the chokepoint."""
    if rel == CHOKEPOINT:
        return []
    module_aliases, member_aliases = _resend_bindings(tree)
    if not module_aliases and not member_aliases:
        return []

    line_map = _enclosing_functions(tree)
    out: List[Violation] = []
    for node in ast.walk(tree):
        if not isinstance(node, ast.Call):
            continue
        path = _dotted(node.func)
        if not path:
            continue
        root = path.split(".")[0]
        # `resend.Emails.send(...)` / `r.Batch.send(...)` — module-rooted call.
        # `Emails.send(...)` after `from resend import Emails` — member-rooted call.
        if root not in module_aliases and root not in member_aliases:
            continue
        out.append(
            Violation(
                str(rel),
                node.lineno,
                line_map.get(node.lineno, "<module>"),
                "direct-resend",
                f"calls `{path}(...)` directly — every send MUST go through "
                f"`email_sender.send(params, user_id=..., email_type=...)` "
                f"(bypasses the undeliverable-domain block AND the frequency cap)",
            )
        )
    return out


def check_resend_backdoors(rel: Path, tree: ast.AST) -> List[Violation]:
    """Rule 2: app code importing the SDK, or anyone hand-rolling Resend HTTP."""
    if rel == CHOKEPOINT:
        return []
    out: List[Violation] = []
    line_map = _enclosing_functions(tree)
    in_app = rel.parts and rel.parts[0] in APP_DIRS

    if in_app:
        for node in ast.walk(tree):
            names: List[str] = []
            if isinstance(node, ast.Import):
                names = [
                    a.name for a in node.names
                    if a.name == "resend" or a.name.startswith("resend.")
                ]
            elif isinstance(node, ast.ImportFrom):
                mod = node.module or ""
                if mod == "resend" or mod.startswith("resend."):
                    names = [mod]
            for name in names:
                out.append(
                    Violation(
                        str(rel),
                        node.lineno,
                        line_map.get(node.lineno, "<module>"),
                        "resend-import",
                        f"imports `{name}` — app code under {'/'.join(APP_DIRS)}/ must "
                        f"never touch the Resend SDK; import `services.email_sender` "
                        f"and call `email_sender.send(...)`",
                    )
                )

    for node in ast.walk(tree):
        if isinstance(node, ast.Constant) and isinstance(node.value, str):
            if "api.resend.com" in node.value:
                out.append(
                    Violation(
                        str(rel),
                        node.lineno,
                        line_map.get(node.lineno, "<module>"),
                        "resend-http",
                        "hand-rolls HTTP to api.resend.com — route it through "
                        "`email_sender.send(...)` instead",
                    )
                )
    return out


# ═══════════════════════════════════════════════════════════════════════════════
# Rule 3 — cap priority: cron jobs ↔ PRIORITY_TIER
# ═══════════════════════════════════════════════════════════════════════════════

def _load_sender():
    """Import services.email_sender for its PRIORITY_TIER / exemption truth."""
    sys.path.insert(0, str(BACKEND))
    try:
        from services import email_sender          # noqa: WPS433 — deferred by design
    except Exception as e:                          # noqa: BLE001
        print(f"❌ gate cannot run: `from services import email_sender` failed: {e}",
              file=sys.stderr)
        sys.exit(2)
    return email_sender


def _tier_entries(tree: ast.AST) -> List[Tuple[int, str, Optional[str], int]]:
    """Parse email_cron's `tiers = [[("name", _job_x(...)), ...], ...]`.

    Returns [(tier_index_1based, job_name, job_func_name, lineno)].
    """
    entries: List[Tuple[int, str, Optional[str], int]] = []
    for node in ast.walk(tree):
        if not (isinstance(node, (ast.Assign, ast.AnnAssign))):
            continue
        targets = node.targets if isinstance(node, ast.Assign) else [node.target]
        if not any(isinstance(t, ast.Name) and t.id == "tiers" for t in targets):
            continue
        value = node.value
        if not isinstance(value, ast.List):
            continue
        for tier_index, tier in enumerate(value.elts, start=1):
            if not isinstance(tier, (ast.List, ast.Tuple)):
                continue
            for item in tier.elts:
                if not (isinstance(item, ast.Tuple) and len(item.elts) == 2):
                    continue
                name_node, call_node = item.elts
                if not (isinstance(name_node, ast.Constant)
                        and isinstance(name_node.value, str)):
                    continue
                func_name = None
                if isinstance(call_node, ast.Call):
                    func_name = _dotted(call_node.func)
                entries.append(
                    (tier_index, name_node.value, func_name, name_node.lineno)
                )
    return entries


def _defined_jobs(tree: ast.AST) -> Dict[str, int]:
    """`_job_*` functions defined in email_cron (sync or async) → lineno."""
    out: Dict[str, int] = {}
    for node in ast.walk(tree):
        if isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            if node.name.startswith("_job_"):
                out[node.name] = node.lineno
    return out


def _job_helpers(tree: ast.AST) -> Set[str]:
    """`_job_*` functions CALLED from inside another `_job_*` — shared helpers.

    `_job_week1_email` is the body behind `_job_week1_day{1,3,5,7}_email`; it is not
    itself a scheduled job and must not be required to appear in `tiers`.
    """
    helpers: Set[str] = set()
    for node in ast.walk(tree):
        if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if not node.name.startswith("_job_"):
            continue
        for inner in ast.walk(node):
            if isinstance(inner, ast.Call):
                called = _dotted(inner.func)
                if called and called.startswith("_job_") and called != node.name:
                    helpers.add(called)
    return helpers


def _tiers_for_name(sender, name: str) -> Optional[Set[int]]:
    """PRIORITY_TIER tier(s) for a cron job name.

    A job name is either an email_type itself (`weekly_summary`) or the FAMILY of
    the types it can emit (`week1_day3` → `week1_day3_completed` / `_stalled`).
    """
    table: Dict[str, int] = sender.PRIORITY_TIER
    if name in table:
        return {table[name]}
    family = {v for k, v in table.items() if k.startswith(name + "_")}
    return family or None


def check_cron_tiers(sender) -> List[Violation]:
    cron_path = BACKEND / EMAIL_CRON
    if not cron_path.exists():
        return [Violation(str(EMAIL_CRON), 0, "<module>", "cron-tiers",
                          "email_cron.py not found — the gate cannot verify tiers")]
    tree = ast.parse(cron_path.read_text(), filename=str(EMAIL_CRON))
    entries = _tier_entries(tree)
    out: List[Violation] = []

    if not entries:
        return [Violation(str(EMAIL_CRON), 0, "run_email_cron", "cron-tiers",
                          "no `tiers = [[...]]` job registry found — cap priority "
                          "ordering is gone (jobs would run in one flat gather)")]

    registered_funcs: Set[str] = set()
    for tier_index, name, func_name, lineno in entries:
        if func_name:
            registered_funcs.add(func_name)

        if name in RETIRED_EMAIL_TYPES:
            out.append(Violation(
                str(EMAIL_CRON), lineno, "run_email_cron", "retired-type",
                f"job '{name}' is RETIRED — it was merged into the Monday "
                f"weekly_summary and must not be scheduled again",
            ))
            continue

        tiers = _tiers_for_name(sender, name)
        if tiers is None:
            out.append(Violation(
                str(EMAIL_CRON), lineno, "run_email_cron", "cron-tiers",
                f"job '{name}' has NO entry in email_sender.PRIORITY_TIER — "
                f"priority_tier() will log 🚨 and silently demote it to T3, so it "
                f"loses its claim on the user's scarce daily cap slots",
            ))
            continue
        if tiers != {tier_index}:
            out.append(Violation(
                str(EMAIL_CRON), lineno, "run_email_cron", "cron-tiers",
                f"job '{name}' runs in cron tier T{tier_index} but PRIORITY_TIER says "
                f"T{sorted(tiers)} — the two orderings disagree; the cron order is what "
                f"actually decides who gets the slot",
            ))

    defined = _defined_jobs(tree)
    helpers = _job_helpers(tree)
    for func_name, lineno in sorted(defined.items()):
        if func_name in registered_funcs or func_name in helpers:
            continue
        out.append(Violation(
            str(EMAIL_CRON), lineno, func_name, "cron-tiers",
            f"`{func_name}` is defined but is NOT registered in any `tiers` list — "
            f"it either never runs, or runs with no tier and no cap priority",
        ))
    return out


# ═══════════════════════════════════════════════════════════════════════════════
# Rule 3b + 4 — every email_type routed through send() is registered / not retired
# ═══════════════════════════════════════════════════════════════════════════════

def _is_sender_send(func: ast.AST) -> bool:
    """True for `email_sender.send(...)` (or `send(...)` after a from-import)."""
    path = _dotted(func)
    if not path:
        return False
    return path.endswith("email_sender.send") or path == "send"


def check_email_types(rel: Path, tree: ast.AST, sender) -> Tuple[List[Violation], List[str]]:
    """Literal `email_type=` kwargs on email_sender.send must be known + live.

    Returns (violations, dynamic_notes) — a non-literal email_type cannot be checked
    statically; it is listed, never silently ignored.
    """
    if rel == CHOKEPOINT:
        return [], []
    # `send(...)` bare-name matches need the module to actually import email_sender.
    imports_sender = any(
        (isinstance(n, ast.ImportFrom) and (n.module or "").endswith("email_sender"))
        or (isinstance(n, ast.ImportFrom) and (n.module or "") == "services"
            and any(a.name == "email_sender" for a in n.names))
        or (isinstance(n, ast.Import)
            and any(a.name.endswith("email_sender") for a in n.names))
        for n in ast.walk(tree)
    )
    if not imports_sender:
        return [], []

    line_map = _enclosing_functions(tree)
    out: List[Violation] = []
    dynamic: List[str] = []
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Call) and _is_sender_send(node.func)):
            continue
        kw = next((k for k in node.keywords if k.arg == "email_type"), None)
        func = line_map.get(node.lineno, "<module>")
        if kw is None:
            continue                                    # no type → exempt by contract
        if not (isinstance(kw.value, ast.Constant) and isinstance(kw.value.value, str)):
            # Tests parametrize email_type on purpose — that is the point of a test.
            if rel.parts and rel.parts[0] != "tests":
                dynamic.append(f"  {rel}:{node.lineno} — {func}() — email_type is "
                               f"dynamic (not statically checkable)")
            continue
        etype = kw.value.value
        if etype in RETIRED_EMAIL_TYPES:
            out.append(Violation(
                str(rel), node.lineno, func, "retired-type",
                f"sends RETIRED email_type '{etype}' — it lives inside the Monday "
                f"weekly_summary now; delete this send",
            ))
            continue
        if sender.is_exempt(etype):
            continue                                    # exempt: never capped, never tiered
        if etype not in sender.PRIORITY_TIER:
            out.append(Violation(
                str(rel), node.lineno, func, "cron-tiers",
                f"email_type '{etype}' is neither EXEMPT nor in PRIORITY_TIER — "
                f"priority_tier() logs 🚨 and defaults it to T3; register it in "
                f"services/email_sender.py",
            ))
    return out, dynamic


# ═══════════════════════════════════════════════════════════════════════════════

def audit() -> Tuple[List[Violation], List[str]]:
    if not (BACKEND / CHOKEPOINT).exists():
        print(f"❌ gate cannot run: {CHOKEPOINT} does not exist — the chokepoint is "
              f"the entire point of this audit", file=sys.stderr)
        sys.exit(2)

    sender = _load_sender()
    violations: List[Violation] = []
    dynamic: List[str] = []

    for rel, _src, tree in _iter_sources():
        violations += check_direct_resend_calls(rel, tree)
        violations += check_resend_backdoors(rel, tree)
        v, d = check_email_types(rel, tree, sender)
        violations += v
        dynamic += d

    violations += check_cron_tiers(sender)
    violations.sort(key=lambda v: (v.rule, v.file, v.line))
    return violations, dynamic


def main():
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    ap.add_argument("--check", action="store_true", help="exit 1 on any violation")
    args = ap.parse_args()

    violations, dynamic = audit()

    if dynamic:
        print(f"ℹ️  {len(dynamic)} send(s) with a dynamic email_type (not statically "
              f"checkable — verify by hand):")
        for line in dynamic:
            print(line)
        print()

    if violations:
        by_rule: Dict[str, List[Violation]] = {}
        for v in violations:
            by_rule.setdefault(v.rule, []).append(v)
        print(f"❌ {len(violations)} email-chokepoint violation(s):\n")
        for rule, group in by_rule.items():
            print(f"── {rule} ({len(group)}) " + "─" * (52 - len(rule)))
            for v in group:
                print(str(v))
            print()
        print("Fix: every outbound email goes through "
              "`services/email_sender.py::send(params, user_id=..., email_type=...)`.")
        sys.exit(1 if args.check else 0)

    print("✅ email chokepoint intact — services/email_sender.py is the only caller of "
          "resend.Emails.send; cron tiers match PRIORITY_TIER; no retired types sent")


if __name__ == "__main__":
    main()
