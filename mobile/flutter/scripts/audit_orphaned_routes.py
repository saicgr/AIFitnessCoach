#!/usr/bin/env python3
"""Audit for orphaned GoRouter routes — declared but never navigated to.

Finding #380: 194 declared routes, 8 with no in-app entry point (cardio
logging, pelvic floor, My Wrapped reachable only via deep link or a
transposed-path bug). The bug class, not any one screen, is the problem —
so this is a standing gate, not a one-off cleanup.

What it does:
  1. Parses every `path: '...'` / `path: "..."` in lib/navigation/app_router*.dart
     as a DECLARED route.
  2. Collects every string literal starting with `/` anywhere else in lib/,
     as a candidate NAVIGATION REFERENCE. Deliberately not restricted to
     `.push('/x')`/`.go('/x')` call syntax — a lot of real entry points are
     data-driven (e.g. a settings-row model carrying `route: '/x'`, read
     generically by one shared `context.push(row.route)`), so the call site
     itself never contains the literal. Interpolated segments (`$var`,
     `${...}`) are normalised to a wildcard so `'/wrapped/${x.period}'`
     still matches the declared `/wrapped/:periodKey`.
  3. Flags any declared route with zero matching references, unless it is
     in ALLOWLIST (routes that are legitimately deep-link-only, OS/system
     entry points, or transient screens set via `initialLocation` rather
     than pushed).

This is a heuristic static check, not a router simulator — it cannot see
routes reached only via a runtime-constructed string it can't statically
resolve, or via a native deep link table outside this repo. Treat a
reported orphan as a strong signal to verify by hand, not an infallible
verdict; add a genuinely deep-link-only route to ALLOWLIST with a one-line
reason rather than silencing the check by deleting it.

Usage:
    python3 scripts/audit_orphaned_routes.py --check

Exits 1 (and lists the orphans) if any undeclared-reference route is found
outside ALLOWLIST; exits 0 otherwise. Run from mobile/flutter/, or anywhere
— paths are resolved relative to this script's location.
"""
from __future__ import annotations

import re
import sys
from pathlib import Path

FLUTTER_ROOT = Path(__file__).resolve().parent.parent
LIB_DIR = FLUTTER_ROOT / "lib"
NAV_DIR = LIB_DIR / "navigation"

# Routes that are intentionally NOT reached via an in-app .push()/.go() call.
# Each entry names the real reason so this list can't quietly become a junk
# drawer for future orphans.
ALLOWLIST: dict[str, str] = {
    "/splash": "initial route set via app bootstrap, never pushed",
    "/workout-loading": "transient interstitial set as the initial route "
        "during workout generation, not pushed from elsewhere",
    "/log": "OS home-screen-widget deep link only (fitwiz://log)",
    "/coming-soon": "superseded by /features (FeatureVotingScreen); see "
        "settings_screen.dart's E2E-row-85 comment — kept only pending a "
        "decision to delete the dead screen + route",
    "/paywall-timeline": "superseded by /paywall-pricing's own trial "
        "timeline; see paywall_features_screen.dart's comment — kept only "
        "pending a decision to delete the dead screen + route",
}

PATH_DECL_RE = re.compile(r"""path:\s*['"]([^'"]+)['"]""")

# Any quoted string literal starting with `/` — deliberately not scoped to
# push()/go() call syntax, see module docstring point 2.
ROUTE_LITERAL_RE = re.compile(r"""['"](/[^'"]*)['"]""")


def declared_routes() -> dict[str, Path]:
    """Every declared `path:`, mapped to the file it lives in.

    A route whose GoRoute block is `redirect:`-only (no `builder`/
    `pageBuilder`) is a legacy-alias route by construction — it exists so an
    OLD external link still lands somewhere, and is never meant to be
    `.push()`ed from inside the app. Those are excluded here rather than
    flagged as orphans.
    """
    routes: dict[str, Path] = {}
    for f in sorted(NAV_DIR.glob("app_router*.dart")):
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in PATH_DECL_RE.finditer(text):
            # Look at the text between this `path:` and the next one (or the
            # next 400 chars, whichever is shorter) to classify the block.
            window = text[m.end():m.end() + 400]
            next_path = PATH_DECL_RE.search(window)
            if next_path:
                window = window[: next_path.start()]
            has_redirect = re.search(r"\bredirect\s*:", window)
            has_builder = re.search(r"\b(?:builder|pageBuilder)\s*:", window)
            if has_redirect and not has_builder:
                continue  # legacy-alias route, not an orphan
            routes[m.group(1)] = f
    return routes


def normalize(path: str) -> str:
    """Collapse a dynamic path segment (`:id`) or an interpolated literal
    segment (`$var`, `${expr}`) to a single `*` wildcard segment so a
    declaration and a call site compare equal regardless of the real value.
    """
    # Interpolation: `$identifier` or `${...}` anywhere in a segment.
    path = re.sub(r"\$\{[^}]*\}", "*", path)
    path = re.sub(r"\$[A-Za-z_][A-Za-z0-9_]*", "*", path)
    parts = path.split("?", 1)[0].split("/")
    parts = ["*" if p.startswith(":") or p == "*" else p for p in parts]
    return "/".join(parts)


def referenced_routes() -> set[str]:
    refs: set[str] = set()
    for f in LIB_DIR.rglob("*.dart"):
        if f.parent == NAV_DIR:
            continue  # route declarations themselves aren't a "reference"
        if f.name.endswith(".g.dart") or "/generated/" in str(f):
            continue  # codegen / l10n output, not app navigation
        text = f.read_text(encoding="utf-8", errors="ignore")
        for m in ROUTE_LITERAL_RE.finditer(text):
            refs.add(normalize(m.group(1)))
    return refs


def main() -> int:
    check_mode = "--check" in sys.argv
    declared = declared_routes()
    referenced = referenced_routes()

    orphans = []
    for path, owner in sorted(declared.items()):
        if path in ALLOWLIST:
            continue
        if normalize(path) in referenced:
            continue
        orphans.append((path, owner))

    if not orphans:
        print(f"OK — {len(declared)} declared routes, all referenced or allowlisted.")
        return 0

    print(f"Found {len(orphans)} orphaned route(s) out of {len(declared)} declared:\n")
    for path, owner in orphans:
        print(f"  {path}  (declared in {owner.relative_to(FLUTTER_ROOT)})")
    print(
        "\nEach one needs a real .push()/.go() call site, an ALLOWLIST entry "
        "with a reason, or removal of the dead route."
    )
    return 1 if check_mode else 0


if __name__ == "__main__":
    raise SystemExit(main())
