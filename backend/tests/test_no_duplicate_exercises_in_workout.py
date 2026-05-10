"""Tests for workout-level exercise dedup (Fix 13 from peppy-conjuring-valley.md).

The endpoint dedup pass in generation_endpoints.py should drop later
occurrences when two exercises share canonical name OR library_id. We
test the helper logic in isolation since the full endpoint requires DB.
"""
from services.exercise_rag.utils import canonicalize_exercise_name


def _dedup(exercises):
    """Replicates the endpoint dedup logic for unit-test isolation."""
    seen_canonical: set = set()
    seen_library: set = set()
    out = []
    for ex in exercises:
        nm = ex.get("name") or ""
        canon = canonicalize_exercise_name(nm) or nm.lower().strip()
        canon_key = canon.lower().strip()
        lib_id = (ex.get("library_id") or ex.get("exercise_id") or "").strip()
        if canon_key and canon_key in seen_canonical:
            continue
        if lib_id and lib_id in seen_library:
            continue
        seen_canonical.add(canon_key)
        if lib_id:
            seen_library.add(lib_id)
        out.append(ex)
    return out


def test_dedup_by_canonical_name():
    """`Pull Up` and `Pull-Up` collapse to the same canonical key."""
    src = [
        {"name": "Pull Up", "library_id": "a"},
        {"name": "Pull-Up", "library_id": "b"},
        {"name": "Burpee", "library_id": "c"},
    ]
    out = _dedup(src)
    assert len(out) == 2
    assert out[0]["library_id"] == "a"
    assert out[1]["name"] == "Burpee"


def test_dedup_by_library_id():
    """Same library_id with different display names → drop later one."""
    src = [
        {"name": "Push-Up", "library_id": "x"},
        {"name": "Push-Up Variation", "library_id": "x"},
    ]
    assert len(_dedup(src)) == 1


def test_dedup_preserves_order_and_first_occurrence():
    src = [
        {"name": "Squat", "library_id": "1"},
        {"name": "Bench Press", "library_id": "2"},
        {"name": "Squat", "library_id": "3"},  # different ID but same canonical name
    ]
    out = _dedup(src)
    assert [e["library_id"] for e in out] == ["1", "2"]


def test_dedup_passes_all_unique():
    src = [
        {"name": f"Ex {i}", "library_id": str(i)}
        for i in range(5)
    ]
    assert len(_dedup(src)) == 5


def test_dedup_handles_missing_library_id():
    src = [
        {"name": "Burpee"},
        {"name": "Burpee"},  # duplicate canonical name, no library_id
    ]
    assert len(_dedup(src)) == 1
