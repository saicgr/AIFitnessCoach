"""Regression gate for the user-preference write path.

    cd backend && .venv312/bin/python -m api.v1.preferences_contract --check

Three checks, each of which was a live production defect on 2026-07-30:

  1. FIELD ROUTING — every field declared on `UserUpdate` /
     `UserPreferencesRequest` names a destination in
     `api/v1/users/field_routing.py`, and both models set `extra="forbid"`.
     32 of 81 `UserUpdate` fields were declared-but-unrouted: accepted,
     validated, discarded, answered 200.

  2. CLIENT KEY COVERAGE — every key the Flutter onboarding/profile code
     actually sends to `POST /users/{id}/preferences` and `PUT /users/{id}` is
     a DECLARED field on the matching model. This is the check that would have
     caught the fitness assessment: five capacities POSTed by every onboarding
     client since the screen shipped, declared by nothing, dropped by
     Pydantic's default `extra="ignore"`. With `extra="forbid"` in place this
     check is also a compatibility gate — a client key that is not declared no
     longer just vanishes, it 422s, so this must stay green.

  3. WEEKLY-RATE PARITY — the server's `WEEKLY_RATE_KG_BY_DIRECTION` matches,
     value for value and direction for direction, the rate chips the user
     actually taps in `quiz_weight_rate.dart`. Four independent copies of that
     map existed and disagreed, quoting three different goal dates for one plan.

Exit code 0 = clean, 1 = drift. Prints file:line for every finding.
"""
from __future__ import annotations

import argparse
import os
import re
import sys
from typing import Dict, List, Set, Tuple

_HERE = os.path.dirname(os.path.abspath(__file__))
_BACKEND = os.path.abspath(os.path.join(_HERE, "..", ".."))
_REPO = os.path.abspath(os.path.join(_BACKEND, ".."))
_FLUTTER_LIB = os.path.join(_REPO, "mobile", "flutter", "lib")

if _BACKEND not in sys.path:
    sys.path.insert(0, _BACKEND)


# ── 1. field routing ────────────────────────────────────────────────────────

def check_field_routing() -> List[str]:
    from api.v1.users.field_routing import (
        USER_UPDATE_ROUTING,
        USER_PREFERENCES_ROUTING,
        contract_violations,
    )
    from api.v1.users.models import UserPreferencesRequest
    from models.user import UserUpdate

    return (
        contract_violations(UserUpdate, USER_UPDATE_ROUTING, "USER_UPDATE")
        + contract_violations(
            UserPreferencesRequest, USER_PREFERENCES_ROUTING, "USER_PREFERENCES"
        )
    )


# ── 2. client key coverage ──────────────────────────────────────────────────

# Keys that appear inside a payload literal but are NOT top-level request
# fields — nested object members. Listed explicitly rather than inferred,
# because a wrong inference here would hide a real dropped field.
_NESTED_KEYS: Set[str] = {
    "voice_announcements_enabled",  # inside notification_preferences
    "cadence", "placement",         # inside cardio_preference
    "android",                      # a platform literal, not a payload key
    "cm",                           # unit literal in a ternary, not a key
    "protocol",                     # inside the fasting block
}

# (dart file, 1-based line of the `.post(`/`.put(`, model) call sites. Found by
# walking the tree; the model is decided by the URL suffix.
_PREF_URL = "/preferences"


def _dart_files() -> List[str]:
    out = []
    for dirpath, _dirs, files in os.walk(_FLUTTER_LIB):
        for f in files:
            if f.endswith(".dart"):
                out.append(os.path.join(dirpath, f))
    return sorted(out)


def _url_literal(call_args: str):
    """First single-quoted string in a Dart call's arg list — the URL."""
    m = re.search(r"'([^'\n]*)'", call_args)
    return m.group(1) if m else None


def _classify_users_url(url: str):
    """'root' for PUT /users/{id}, 'preferences' for its /preferences child.

    None for every other /users/* endpoint — those have their own models.
    """
    tail = url.split("ApiConstants.users}", 1)[-1]
    # Collapse the interpolated id: '/$userId', '/${user.id}', '/$id'
    tail = re.sub(r"\$\{[^}]*\}|\$[A-Za-z_][A-Za-z0-9_.]*", "<id>", tail)
    if tail == "/<id>":
        return "root"
    if tail == "/<id>/preferences":
        return "preferences"
    return None


def _balanced(src: str, open_idx: int, opener: str = "(", closer: str = ")") -> str:
    depth = 0
    i = open_idx
    while i < len(src):
        if src[i] == opener:
            depth += 1
        elif src[i] == closer:
            depth -= 1
            if depth == 0:
                return src[open_idx:i + 1]
        i += 1
    return src[open_idx:]


def _resolve_data_arg(src: str, call_args: str) -> str:
    """Return the map literal a call's `data:` refers to.

    The three biggest payloads in the app are built into a local variable and
    passed by name (`data: preferencesPayload`), so a scanner that only reads
    the call site sees zero keys and reports a clean bill of health for the
    exact payload that carried the dropped fields. When `data:` is a bare
    identifier, splice in the `final <ident> = {...}` literal from the same
    file.
    """
    m = re.search(r"data:\s*([A-Za-z_][A-Za-z0-9_]*)\s*[,)]", call_args)
    if not m:
        return call_args
    ident = m.group(1)
    decl = re.search(
        r"(?:final|var|const)\s+" + re.escape(ident) + r"\s*=\s*[^;{]*\{", src
    )
    if not decl:
        return call_args
    brace = src.index("{", decl.start())
    return call_args + _balanced(src, brace, "{", "}")


def collect_client_keys() -> Tuple[Dict[str, List[str]], Dict[str, List[str]]]:
    """-> ({pref_key: [file:line, ...]}, {put_key: [file:line, ...]})."""
    pref: Dict[str, List[str]] = {}
    put: Dict[str, List[str]] = {}
    key_re = re.compile(r"['\"]([a-z_][a-z0-9_]*)['\"]\s*:")

    def map_keys(text: str) -> List[str]:
        """Quoted identifiers used as MAP KEYS in a Dart literal.

        A quoted identifier followed by ':' is a key — unless a '?' precedes
        it, in which case it is the true-branch VALUE of a ternary
        (`_isCustomMode ? 'custom' : _selectedCoach?.id`) and the ':' belongs
        to the ternary, not to a map entry.
        """
        out = []
        for mm in key_re.finditer(text):
            before = text[:mm.start()].rstrip()
            if before.endswith("?"):
                continue
            out.append(mm.group(1))
        return out

    for path in _dart_files():
        try:
            src = open(path, encoding="utf-8", errors="replace").read()
        except OSError:
            continue
        rel = os.path.relpath(path, _REPO)

        # Direct api client calls that name the users endpoint. The URL literal
        # decides which model applies, and anything that is neither
        # `${ApiConstants.users}/$id` nor `${ApiConstants.users}/$id/preferences`
        # is a DIFFERENT endpoint with its own request model
        # (/calculate-nutrition-targets, /sign-in-device, /change-email …) and
        # is not this contract's business.
        for m in re.finditer(r"\.(post|put)\(", src):
            open_idx = src.index("(", m.start())
            arg = _balanced(src, open_idx)
            url = _url_literal(arg)
            if url is None or "ApiConstants.users" not in url:
                continue
            kind = _classify_users_url(url)
            if kind is None:
                continue
            target = pref if kind == "preferences" else put
            line = src[:m.start()].count("\n") + 1
            arg = _resolve_data_arg(src, arg)
            for k in map_keys(arg):
                if k in _NESTED_KEYS:
                    continue
                target.setdefault(k, []).append(f"{rel}:{line}")

        # The auth notifier's profile updater PUTs its map verbatim.
        for m in re.finditer(r"updateUserProfile\s*\(", src):
            open_idx = src.index("(", m.start())
            arg = _balanced(src, open_idx)
            line = src[:m.start()].count("\n") + 1
            for k in map_keys(arg):
                if k in _NESTED_KEYS:
                    continue
                put.setdefault(k, []).append(f"{rel}:{line}")

    # The onboarding payload builder is a separate function whose output is
    # spread into the /preferences body at two call sites.
    builder = os.path.join(_FLUTTER_LIB, "data", "models", "ai_profile_payload.dart")
    if os.path.exists(builder):
        src = open(builder, encoding="utf-8", errors="replace").read()
        rel = os.path.relpath(builder, _REPO)
        # Only the assignment form `payload['x'] =` / `block['x'] =`; the
        # readable-string dumper below it merely READS keys.
        cut = src.find("static String toReadableString")
        head = src[:cut] if cut > 0 else src
        for m in re.finditer(r"\w+\[['\"]([a-z_][a-z0-9_]*)['\"]\]\s*=", head):
            k = m.group(1)
            if k in _NESTED_KEYS:
                continue
            line = head[:m.start()].count("\n") + 1
            pref.setdefault(k, []).append(f"{rel}:{line}")
    return pref, put


def check_client_keys() -> List[str]:
    from api.v1.users.models import UserPreferencesRequest
    from models.user import UserUpdate

    if not os.path.isdir(_FLUTTER_LIB):
        return [f"cannot audit client keys: {_FLUTTER_LIB} not found"]

    pref_keys, put_keys = collect_client_keys()
    problems: List[str] = []

    pref_declared = set(UserPreferencesRequest.model_fields)
    for k in sorted(set(pref_keys) - pref_declared):
        where = ", ".join(sorted(set(pref_keys[k]))[:3])
        problems.append(
            f"POST /users/{{id}}/preferences receives '{k}' ({where}) but "
            f"UserPreferencesRequest does not declare it — the write is lost "
            f"(and with extra='forbid' the whole request now 422s)."
        )

    put_declared = set(UserUpdate.model_fields)
    for k in sorted(set(put_keys) - put_declared):
        where = ", ".join(sorted(set(put_keys[k]))[:3])
        problems.append(
            f"PUT /users/{{id}} receives '{k}' ({where}) but UserUpdate does "
            f"not declare it — the write is lost (and with extra='forbid' the "
            f"whole request now 422s)."
        )
    return problems


# ── 3. weekly-rate parity ───────────────────────────────────────────────────

_CHIPS = os.path.join(
    _FLUTTER_LIB, "screens", "onboarding", "widgets", "quiz_weight_rate.dart"
)


def parse_dart_rate_chips() -> Dict[str, Dict[str, float]]:
    """Read the rate chips the user actually taps out of the Dart source.

    `WeightRateOption('<id>', '<label>', <kg_per_week>, ...)` — the losing set
    is inside the `if (isLosing)` branch, the gaining set after it.
    """
    src = open(_CHIPS, encoding="utf-8", errors="replace").read()
    split = src.find("if (isLosing)")
    if split < 0:
        raise RuntimeError(f"{_CHIPS}: 'if (isLosing)' branch not found")
    ret = src.find("return [", src.find("}", src.find("];", split)))
    losing_src, gaining_src = src[split:ret], src[ret:]
    opt = re.compile(
        r"WeightRateOption\(\s*'([a-z]+)'\s*,\s*'[^']*'\s*,\s*([0-9.]+)"
    )
    return {
        "lose": {m.group(1): float(m.group(2)) for m in opt.finditer(losing_src)},
        "gain": {m.group(1): float(m.group(2)) for m in opt.finditer(gaining_src)},
    }


def check_weekly_rates() -> List[str]:
    from api.v1.onboarding import WEEKLY_RATE_KG_BY_DIRECTION

    if not os.path.exists(_CHIPS):
        return [f"cannot audit weekly rates: {_CHIPS} not found"]

    chips = parse_dart_rate_chips()
    problems: List[str] = []
    for direction, chip_rates in chips.items():
        server = WEEKLY_RATE_KG_BY_DIRECTION.get(direction, {})
        if not chip_rates:
            problems.append(
                f"parsed no '{direction}' rate chips out of "
                f"{os.path.relpath(_CHIPS, _REPO)} — the parser or the widget moved."
            )
            continue
        for pace, kg in sorted(chip_rates.items()):
            if direction not in WEEKLY_RATE_KG_BY_DIRECTION:
                problems.append(
                    f"WEEKLY_RATE_KG_BY_DIRECTION has no '{direction}' table."
                )
                break
            if pace not in server:
                problems.append(
                    f"chip {direction}/{pace} = {kg} kg/wk has no server entry — "
                    f"the sign-in 'Goal:' date cannot match the chip."
                )
            elif abs(server[pace] - kg) > 1e-9:
                problems.append(
                    f"chip {direction}/{pace} shows {kg} kg/wk but "
                    f"api/v1/onboarding.py projects at {server[pace]} — the same "
                    f"plan gets two different goal dates (E2E row 39)."
                )
    return problems


# ── driver ──────────────────────────────────────────────────────────────────

def run() -> int:
    sections = (
        ("field routing", check_field_routing),
        ("client key coverage", check_client_keys),
        ("weekly-rate parity", check_weekly_rates),
    )
    failed = 0
    for name, fn in sections:
        problems = fn()
        if problems:
            failed += 1
            print(f"\n❌ {name}: {len(problems)} problem(s)")
            for p in problems:
                print(f"   - {p}")
        else:
            print(f"✅ {name}")
    if failed:
        print(f"\n{failed} section(s) failed.")
        return 1
    print("\nAll preference-contract checks passed.")
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true",
                        help="exit non-zero on any contract drift")
    parser.parse_args()
    sys.exit(run())
