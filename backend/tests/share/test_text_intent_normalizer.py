"""Tests for backend/services/text_intent_normalizer.py.

Pure-function service — no mocking required.
"""
from services.text_intent_normalizer import (
    NormalizedText,
    fingerprints_to_signals,
    normalize,
    soft_hash,
)


def test_normalize_empty_returns_empty_text() -> None:
    n = normalize("")
    assert n.text == ""
    assert n.char_count == 0
    assert not n.has_numbered_list
    assert not n.has_set_rep_markers


def test_strips_markdown_fences_and_headings() -> None:
    src = """```\n# Heading\n**Bold** _italic_\n```\nbody"""
    n = normalize(src)
    assert "```" not in n.text
    assert "Heading" in n.text
    assert "Bold" in n.text and "italic" in n.text


def test_numbered_list_fingerprint() -> None:
    n = normalize("1. Bench press 4x8\n2. Squat 3x10")
    assert n.has_numbered_list is True
    assert n.has_set_rep_markers is True


def test_bullet_list_fingerprint() -> None:
    n = normalize("- 1 cup rice\n- 200 g chicken")
    assert n.has_bullet_list is True
    assert n.has_ingredient_markers is True


def test_day_markers_fingerprint() -> None:
    n = normalize("Day 1: oatmeal\nDay 2: rice")
    assert n.has_day_markers is True


def test_macro_markers_fingerprint() -> None:
    n = normalize("Protein: 40 g, carbs: 60 g, fat 12 g")
    assert n.has_macro_markers is True


def test_max_chars_truncation() -> None:
    big = "X" * 50_000
    n = normalize(big, max_chars=4_096)
    assert len(n.text) == 4_096
    # char_count reflects the PRE-truncation length so downstream code
    # can decide whether a payload exceeded the cap.
    assert n.char_count == 50_000


def test_signals_dict_only_contains_yes_values() -> None:
    fp = normalize("Day 1\n1. Bench 4x8")
    sigs = fingerprints_to_signals(fp)
    assert sigs.get("numbered_list") == "yes"
    assert sigs.get("day_markers") == "yes"
    assert sigs.get("set_rep_markers") == "yes"
    # macro / ingredient markers absent → key not present
    assert "macro_markers" not in sigs


def test_soft_hash_stable_and_collision_resistant() -> None:
    assert soft_hash("a") == soft_hash("a")
    assert soft_hash("a") != soft_hash("b")
    # Whitespace trimming
    assert soft_hash("  hello  ") == soft_hash("hello")
    # Returns hex digest
    h = soft_hash("anything")
    assert len(h) == 40
    int(h, 16)  # valid hex
