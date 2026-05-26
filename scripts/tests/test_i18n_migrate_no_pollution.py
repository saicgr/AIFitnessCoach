"""Tests for the namespace-pollution guard in scripts/i18n_migrate_screen.py.

Run with:
    python3 -m pytest scripts/tests/test_i18n_migrate_no_pollution.py -v
"""
from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

# Load i18n_migrate_screen.py as a module (it's a script, not a package).
_HERE = Path(__file__).resolve().parent
_SCRIPT = _HERE.parent / "i18n_migrate_screen.py"
_spec = importlib.util.spec_from_file_location("i18n_migrate_screen", _SCRIPT)
_mod = importlib.util.module_from_spec(_spec)
sys.modules["i18n_migrate_screen"] = _mod
_spec.loader.exec_module(_mod)

strip = _mod._strip_namespace_pollution
camel_words = _mod._camel_words


# ---- _camel_words ---------------------------------------------------------

def test_camel_words_splits_namespace():
    assert camel_words("unifiedHomeWidgets") == ["unified", "home", "widgets"]


def test_camel_words_single_segment():
    assert camel_words("common") == ["common"]


def test_camel_words_with_acronym():
    # The migrate-script convention is consistent camelCase — uppercased
    # acronyms are treated as a new word boundary per letter, matching how
    # _camelize generates keys upstream.
    assert camel_words("aiSettings") == ["ai", "settings"]


# ---- _strip_namespace_pollution ------------------------------------------

def test_strips_polluted_body_with_matching_prefix():
    """The canonical failure mode the guard exists to prevent."""
    assert strip(
        "Unified home widgets wake hydration",
        "unifiedHomeWidgets",
    ) == "Wake hydration"


def test_strips_long_polluted_body():
    assert strip(
        "Ai model download best quality",
        "aiModelDownload",
    ) == "Best quality"


def test_strips_with_placeholder_preserved():
    assert strip(
        "Compliance ring card great pace {arg0}",
        "complianceRingCard",
    ) == "Great pace {arg0}"


def test_short_body_left_unchanged():
    """When body has no namespace duplication (e.g. legitimate one-word value),
    the guard must not mutate it."""
    assert strip("Connect", "unifiedHomeWidgets") == "Connect"


def test_body_without_prefix_unchanged():
    """A body that begins with words unrelated to the prefix is left as-is."""
    assert strip(
        "Tap to view profile",
        "unifiedHomeWidgets",
    ) == "Tap to view profile"


def test_partial_prefix_match_unchanged():
    """If only some prefix words are present at the start, do nothing — we
    only strip when the FULL prefix matches to avoid mangling values that
    happen to share an opening word with the namespace."""
    assert strip(
        "Unified rest day notice",
        "unifiedHomeWidgets",
    ) == "Unified rest day notice"


def test_empty_prefix_returns_body():
    assert strip("Anything", "") == "Anything"


def test_empty_body_returns_body():
    assert strip("", "unifiedHomeWidgets") == ""


def test_body_equal_to_prefix_alone_unchanged():
    """If stripping the prefix would leave nothing, keep the original body
    rather than blanking the value."""
    assert strip(
        "Unified home widgets",
        "unifiedHomeWidgets",
    ) == "Unified home widgets"
