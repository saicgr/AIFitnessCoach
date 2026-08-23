"""
Client/server route contract test.

Retires the class of bug behind rows 373 ("POST /cardio/log" 404), 374
(cardio navigation path 404) and 408 ("POST /diabetes/glucose/readings"
404): the Flutter client requesting a path the FastAPI route table does
not contain, with nothing in the build catching it.

Row 411's own attempted fix (a regex diff of `.get/.post/...` call sites
against `@router.*` decorator text) was NOT trustworthy — it caught both
known 404s, but 6 flagged candidates it also raised
(`/kegel/preferences/*`, `/hormonal-health/profile/*`, `/social/feed`,
`/nutrition/saved-foods`, `/activity/health-goals/*`, `/sync/accounts`)
all resolved live (401/405, never 404): the regex mis-resolved
`include_router(..., prefix=...)` nesting, especially routers that
declare their OWN prefix and get included without a second one.

This test avoids that whole class of mistake by reading the SERVER side
from the running app (`app.routes`) instead of re-deriving prefixes by
hand — Starlette has already resolved every `include_router` nesting by
the time `main.app` exists, so there is nothing left to get wrong there.

The CLIENT side is read from the two directories that ARE the app's
single typed API layer (`lib/data/repositories/`, `lib/data/services/`)
rather than every screen file, so a widget calling into that layer is
covered without re-scanning UI code for stray literals.
"""
import json
import re
from pathlib import Path

import pytest
from fastapi.routing import APIRoute

from main import app

REPO_ROOT = Path(__file__).resolve().parents[2]
BASELINE_PATH = Path(__file__).with_name("client_server_contract_baseline.json")
FLUTTER_CLIENT_DIRS = [
    REPO_ROOT / "mobile" / "flutter" / "lib" / "data" / "repositories",
    REPO_ROOT / "mobile" / "flutter" / "lib" / "data" / "services",
    # Not every call site lives behind a repository/service — row 408
    # (`POST /diabetes/glucose/readings`, a real 404) called straight out of
    # a provider file. Scanning providers too is what actually catches it.
    REPO_ROOT / "mobile" / "flutter" / "lib" / "data" / "providers",
]

API_V1_PREFIX = "/api/v1"

# Call sites that are known-good exceptions to the "every path is under
# /api/v1" assumption (e.g. hit a different host, or a presigned URL handed
# back by the server) — add a path fragment here with a one-line reason
# rather than silencing the whole test.
ALLOWED_NON_API_CALLS: set[str] = {
    # places_service.dart builds its OWN Dio with
    # baseUrl='https://maps.googleapis.com/maps/api' — these never touch
    # our backend at all.
    "/place/autocomplete/json",
    "/place/details/json",
    "/place/nearbysearch/json",
    "/geocode/json",
}

_CALL_RE = re.compile(
    r"""\.(get|post|put|patch|delete)\(\s*(['"])(/[^'"]*)\2""",
)


def _server_routes() -> set[tuple[str, str]]:
    """(METHOD, path-with-{param}-placeholders) for every /api/v1 route,
    exactly as FastAPI/Starlette resolved it — nested `include_router`
    prefixes and all."""
    routes: set[tuple[str, str]] = set()
    for route in app.routes:
        if not isinstance(route, APIRoute):
            continue
        if not route.path.startswith(API_V1_PREFIX):
            continue
        rel_path = route.path[len(API_V1_PREFIX):] or "/"
        for method in route.methods or set():
            if method in ("HEAD", "OPTIONS"):
                continue
            routes.add((method, rel_path))
    return routes


def _client_call_sites() -> list[tuple[str, str, str]]:
    """(METHOD, path-literal-from-source, "file:line") for every call in
    the typed API layer whose first argument is a string literal that
    looks like a URL path (starts with `/`)."""
    sites: list[tuple[str, str, str]] = []
    for base_dir in FLUTTER_CLIENT_DIRS:
        if not base_dir.is_dir():
            continue
        for dart_file in sorted(base_dir.glob("*.dart")):
            text = dart_file.read_text(encoding="utf-8", errors="ignore")
            for m in _CALL_RE.finditer(text):
                method = m.group(1).upper()
                path = m.group(3)
                if path in ALLOWED_NON_API_CALLS:
                    continue
                line_no = text.count("\n", 0, m.start()) + 1
                sites.append((method, path, f"{dart_file.relative_to(REPO_ROOT)}:{line_no}"))
    return sites


def _segments(path: str) -> list[str]:
    return path.split("?", 1)[0].split("/")


def _is_param_segment(seg: str) -> bool:
    """True for a FastAPI `{param}` placeholder OR a Dart-interpolated
    segment (`$id`, `${id}`, or a segment containing either) — either side
    being a variable means "matches anything here"."""
    return (seg.startswith("{") and seg.endswith("}")) or "$" in seg


def _path_matches(server_path: str, client_path: str) -> bool:
    s_segs = _segments(server_path)
    c_segs = _segments(client_path)
    if len(s_segs) != len(c_segs):
        return False
    for s, c in zip(s_segs, c_segs):
        if _is_param_segment(s) or _is_param_segment(c):
            continue
        if s != c:
            return False
    return True


def _load_baseline() -> set[tuple[str, str]]:
    """Grandfathered (METHOD, path) pairs — mirrors the pattern already used
    by `scripts/tz_audit_baseline.json` etc: the gate fails only on a NEW
    mismatch, not the pre-existing backlog this one pass didn't sign up to
    fix. Each entry in the file also carries a `note` for a human reader;
    only `method`/`path` are load-bearing for the diff."""
    if not BASELINE_PATH.exists():
        return set()
    data = json.loads(BASELINE_PATH.read_text())
    return {(e["method"], e["path"]) for e in data}


def test_flutter_typed_api_layer_paths_resolve_on_the_server():
    """Every (method, path) the typed API layer calls must resolve against
    the REAL, running FastAPI route table, or already be named in
    `client_server_contract_baseline.json`.

    This is deliberately narrow — a false negative (a real route the
    matcher fails to see) is far cheaper than a false positive (flagging a
    path that actually works), which is exactly what sank the original
    hand-rolled regex diff.
    """
    for base_dir in FLUTTER_CLIENT_DIRS:
        if not base_dir.is_dir():
            pytest.skip(f"Flutter client directory not present in this checkout: {base_dir}")

    server_routes = _server_routes()
    assert server_routes, "app.routes yielded no /api/v1 routes — main.app failed to wire up"

    client_sites = _client_call_sites()
    assert client_sites, "No client call sites found — the scan itself is broken"

    baseline = _load_baseline()
    unmatched = []
    for method, path, location in client_sites:
        if (method, path) in baseline:
            continue
        if not any(
            method == s_method and _path_matches(s_path, path)
            for s_method, s_path in server_routes
        ):
            unmatched.append(f"{method} {path}  ({location})")

    assert not unmatched, (
        "Client call(s) with no matching server route (and not in "
        f"{BASELINE_PATH.name}):\n  " + "\n  ".join(unmatched)
    )
