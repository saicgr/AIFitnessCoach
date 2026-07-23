"""Tests for the Supabase column-drift gate's static write-payload resolver.

The resolver (backend/scripts/audit_supabase_column_drift.py) is ~200 lines of
AST analysis that decides whether a `.insert()/.update()/.upsert()` payload
carries a column that does not exist. Both failure directions are expensive:

  * a MISS ships a PGRST204 that silently discards the whole payload (the
    2026-07-21 `food_logs.rating` incident), and
  * a FALSE POSITIVE makes the CLAUDE.md-mandated `--check` gate untrustworthy,
    which is how it ends up being ignored.

So these pin both: the bug shapes that must be caught, and the safe shapes that
must NOT be reported.

The `schema` argument is a stub table map — the point of these tests is the
resolver's control-flow reasoning, not the production schema. Production
schema shapes are exercised by `test_real_tree_audit_runs`, which runs the real
audit over the real backend tree with the real checked-in snapshot.
"""
import importlib.util
import json
from pathlib import Path

import pytest

_SCRIPT = (
    Path(__file__).resolve().parent.parent / "scripts" / "audit_supabase_column_drift.py"
)
_spec = importlib.util.spec_from_file_location("_column_drift_audit", _SCRIPT)
drift = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(drift)


# A stub schema. `food_logs` mirrors the real columns the incident touched.
SCHEMA = {
    "food_logs": [
        "id", "user_id", "health_score", "inflammation_score", "glycemic_load",
        "fodmap_rating", "score_status", "added_sugar_g",
    ],
    "widgets": ["id", "user_id", "name"],
}


def violations(src: str):
    """(table, column) pairs the write-payload pass reports for `src`."""
    return [
        (table, col.replace(" [write]", ""))
        for _f, _line, table, col in drift._write_violations(src, "t.py", SCHEMA)
    ]


def columns(src: str):
    return {col for _table, col in violations(src)}


# ---------------------------------------------------------------------------
# 1. The bug shapes that MUST be caught
# ---------------------------------------------------------------------------

def test_rating_style_helper_built_payload_is_caught():
    """The exact 2026-07-21 shape: a helper builds the payload key-by-key in a
    local, returns it, and the caller writes it. Inline-literal detection alone
    would miss this — the phantom key never appears next to `.update(`."""
    src = '''
async def _build_payload(items):
    update_payload = {}
    update_payload["inflammation_score"] = 3
    update_payload["glycemic_load"] = 12
    update_payload["rating"] = "green"
    return update_payload

async def enrich(db, food_log_id, items):
    payload = await _build_payload(items)
    payload["score_status"] = "ok"
    db.client.table("food_logs").update(payload).eq("id", food_log_id).execute()
'''
    assert ("food_logs", "rating") in violations(src)
    # ...and the legitimate keys are NOT reported.
    assert columns(src) == {"rating"}


def test_inline_literal_payload_is_caught():
    src = '''
def go(db):
    db.client.table("food_logs").insert({"user_id": 1, "rating": "green"}).execute()
'''
    assert columns(src) == {"rating"}


def test_list_of_dicts_payload_is_caught():
    src = '''
def go(db):
    db.client.table("food_logs").insert([
        {"user_id": 1},
        {"bogus_col": 2},
    ]).execute()
'''
    assert columns(src) == {"bogus_col"}


def test_subscript_and_update_mutations_accumulate():
    src = '''
def go(db):
    p = {"user_id": 1}
    p["health_score"] = 5
    p.update({"phantom_a": 1})
    p.setdefault("phantom_b", 2)
    db.client.table("food_logs").update(p).eq("id", 1).execute()
'''
    assert columns(src) == {"phantom_a", "phantom_b"}


def test_key_added_on_only_one_branch_is_still_reported():
    """An if/else join unions both branches: the phantom key really can reach
    the write on one path, so reporting it is a true positive."""
    src = '''
def go(db, flag):
    p = {"user_id": 1}
    if flag:
        p["phantom_branch"] = 1
    else:
        p["health_score"] = 2
    db.client.table("food_logs").update(p).eq("id", 1).execute()
'''
    assert columns(src) == {"phantom_branch"}


# ---------------------------------------------------------------------------
# 2. Class-body coverage (regression: the scope walk used to skip ClassDef)
# ---------------------------------------------------------------------------

def test_class_body_level_write_is_caught():
    """A `.insert({...})` evaluated at class-body level (not inside a method)."""
    src = '''
class Bootstrap:
    db = get_db()
    seeded = db.client.table("food_logs").insert({"phantom_class_col": 1}).execute()
'''
    assert columns(src) == {"phantom_class_col"}


def test_class_body_variable_payload_is_caught():
    src = '''
class Bootstrap:
    payload = {"user_id": 1}
    payload["phantom_class_var"] = 2
    res = db.client.table("food_logs").insert(payload).execute()
'''
    assert columns(src) == {"phantom_class_var"}


def test_method_writes_still_caught_inside_class():
    src = '''
class Repo:
    def save(self, db):
        p = {"user_id": 1, "phantom_method_col": 2}
        db.client.table("food_logs").insert(p).execute()
'''
    assert columns(src) == {"phantom_method_col"}


# ---------------------------------------------------------------------------
# 3. False positives that must NOT be reported
# ---------------------------------------------------------------------------

def test_rebinding_to_a_different_dict_is_not_reported():
    """The reviewer's reproduced false positive: a name reused for an unrelated
    local dict before being rebound to the real payload."""
    src = '''
def go(db):
    d = {"some_local_cache_key": 1}
    use(d)
    d = {"user_id": 2}
    db.client.table("food_logs").insert(d).execute()
'''
    assert violations(src) == []


def test_rebinding_after_the_write_is_not_reported():
    src = '''
def go(db):
    d = {"user_id": 2}
    db.client.table("food_logs").insert(d).execute()
    d = {"some_local_cache_key": 1}
    use(d)
'''
    assert violations(src) == []


def test_rebinding_to_an_unresolvable_value_clears_stale_keys():
    """`p = opaque()` means we no longer know p's keys — we must forget the old
    ones rather than keep reporting them."""
    src = '''
def go(db):
    p = {"phantom_old": 1}
    p = build_it_somehow()
    db.client.table("food_logs").update(p).eq("id", 1).execute()
'''
    assert violations(src) == []


def test_same_name_in_two_functions_does_not_bleed():
    src = '''
def helper_a():
    payload = {"phantom_only_in_a": 1}
    return None

def go(db):
    payload = {"user_id": 1}
    db.client.table("food_logs").insert(payload).execute()
'''
    assert violations(src) == []


def test_loop_variable_keys_are_skipped():
    src = '''
def go(db, cols):
    p = {"user_id": 1}
    for c in cols:
        p[c] = 1
    db.client.table("food_logs").update(p).eq("id", 1).execute()
'''
    assert violations(src) == []


def test_spread_payload_is_skipped():
    src = '''
def go(db, extra):
    db.client.table("food_logs").update({**extra}).eq("id", 1).execute()
'''
    assert violations(src) == []


def test_spread_does_not_suppress_sibling_literal_keys():
    """A dict with both a spread and literal keys: the literal keys are still
    real writes, so they stay validated."""
    src = '''
def go(db, extra):
    db.client.table("food_logs").update({**extra, "phantom_lit": 1}).eq("id", 1).execute()
'''
    assert columns(src) == {"phantom_lit"}


def test_dict_comprehension_payload_is_skipped():
    src = '''
def go(db, cols):
    p = {c: 1 for c in cols}
    db.client.table("food_logs").update(p).eq("id", 1).execute()
'''
    assert violations(src) == []


def test_unknown_table_is_skipped():
    src = '''
def go(db):
    db.client.table("not_in_snapshot").insert({"whatever": 1}).execute()
'''
    assert violations(src) == []


def test_plain_dict_update_is_not_mistaken_for_a_db_write():
    src = '''
def go():
    d = {"a": 1}
    d.update({"b": 2})
'''
    assert violations(src) == []


def test_overloaded_helper_name_is_dropped_as_ambiguous():
    """Two same-file functions with one name returning different dicts: we
    cannot tell which the caller got, so we report nothing."""
    src = '''
def build():
    return {"phantom_one": 1}

def build():
    return {"user_id": 1}

def go(db):
    p = build()
    db.client.table("food_logs").insert(p).execute()
'''
    assert violations(src) == []


# ---------------------------------------------------------------------------
# 4. The baseline gate mechanism
# ---------------------------------------------------------------------------

def test_signature_ignores_line_numbers():
    """Baseline identity must survive unrelated edits that shift lines."""
    a = ("api/v1/x.py", 10, "food_logs", "rating [write]")
    b = ("api/v1/x.py", 4210, "food_logs", "rating [write]")
    assert drift._sig(a) == drift._sig(b)


def test_baseline_file_exists_and_parses():
    assert drift.BASELINE.exists(), "checked-in baseline missing"
    data = json.loads(drift.BASELINE.read_text())
    # An EMPTY baseline is the goal state, not an error: it means every phantom
    # write in the tree has been fixed (as of 2026-07-22, all 68 were). The
    # baseline is a shrinking backlog, so `entries` may legitimately be [].
    assert isinstance(data["entries"], list)
    assert data["count"] == len(data["entries"])


def test_baseline_entries_match_current_violations():
    """The checked-in baseline must describe the tree as it actually is: no
    entry may be stale (a stale entry hides a regression at the same site)."""
    schema = json.loads(drift.SNAPSHOT.read_text())
    live = {drift._sig(v) for v in drift.audit(schema)}
    stale = set(json.loads(drift.BASELINE.read_text())["entries"]) - live
    assert not stale, f"stale baseline entries — re-run --update-baseline: {sorted(stale)}"


def test_check_mode_would_pass_on_the_current_tree():
    """The whole point of the baseline: `--check` must be answerable today."""
    schema = json.loads(drift.SNAPSHOT.read_text())
    baseline = drift._load_baseline()
    new = [v for v in drift.audit(schema) if drift._sig(v) not in baseline]
    assert not new, f"NEW column drift introduced: {new}"


# ---------------------------------------------------------------------------
# 5. Real tree / real schema smoke
# ---------------------------------------------------------------------------

def test_real_tree_audit_runs():
    schema = json.loads(drift.SNAPSHOT.read_text())
    assert "food_logs" in schema
    drift.audit(schema)  # must not raise on any real backend file


def test_food_score_enrichment_has_no_phantom_writes():
    """Direct regression guard for the incident this gate was extended for."""
    schema = json.loads(drift.SNAPSHOT.read_text())
    target = drift.BACKEND / "services" / "food_score_enrichment.py"
    found = drift._write_violations(target.read_text(), target, schema)
    assert found == [], found


def test_rating_is_not_a_food_logs_column():
    """Pins WHY the write was deleted rather than the column added."""
    schema = json.loads(drift.SNAPSHOT.read_text())
    assert "rating" not in schema["food_logs"]


if __name__ == "__main__":
    raise SystemExit(pytest.main([__file__, "-q"]))
