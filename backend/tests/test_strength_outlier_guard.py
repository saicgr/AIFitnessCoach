"""Unit tests for the machine/gym calibration outlier guard (2026-06).

Background: a user training the same machine exercise across two gyms with
differently-calibrated cable stacks (e.g. a cable lateral pulldown reading 95 lb at one
gym and 35 lb at another) saw their strength score swing for months. Root cause: a single
anomalously-heavy session set the sticky all-time best (``max()`` then a 120-day decayed
carry-forward that OVERRIDES the honest fresh window), so the score spiked then read as
"declining". The guard (:func:`_trusted_window_best`) refuses to promote a lone,
uncorroborated spike to the all-time best.

py3.9-safe: ``strength_recalc`` imports only ``StrengthCalculatorService`` at module load
(py3.9-safe). The single py3.10+ dependency it uses — ``api.v1.scores._flatten_logs_for_strength``
— is imported lazily inside the functions under test, so we stub it in ``sys.modules`` to
keep this test deterministic on every interpreter. The real flatten has its own coverage
and runs in prod (py3.12). Run:

    python -m pytest backend/tests/test_strength_outlier_guard.py -q
"""
import os
import sys
import types

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))

# ── Stub the one lazily-imported py3.10+ dependency BEFORE the functions run ──────────
# _session_one_rms_by_exercise / _display_names_by_key do `from api.v1.scores import
# _flatten_logs_for_strength` lazily. Inject faithful package + module stubs so the
# import resolves to our deterministic flatten (input rows already in kg for simplicity).
def _stub_flatten(rows):
    out = {}
    for row in rows:
        payload = row.get("sets_json") or []
        for el in payload:
            name = el.get("name") or el.get("exercise_name") or ""
            if not name:
                continue
            reps = int(el.get("reps") or 0)
            if reps <= 0:
                continue
            weight = float(el.get("weight_kg", el.get("weight", 0)) or 0)
            sets = int(el.get("sets") or 1)
            key = name.strip().lower()
            score = weight * reps
            prev = out.get(key)
            if prev is None or score > prev["_score"]:
                out[key] = {"exercise_name": name, "weight_kg": weight,
                            "reps": reps, "sets": sets, "_score": score}
            else:
                prev["sets"] += sets
    return [{k: v for k, v in e.items() if k != "_score"} for e in out.values()]


_api = types.ModuleType("api"); _api.__path__ = []          # noqa: E702
_apiv1 = types.ModuleType("api.v1"); _apiv1.__path__ = []    # noqa: E702
_scores = types.ModuleType("api.v1.scores")
_scores._flatten_logs_for_strength = _stub_flatten
sys.modules.setdefault("api", _api)
sys.modules.setdefault("api.v1", _apiv1)
sys.modules["api.v1.scores"] = _scores

import services.strength_recalc as sr  # noqa: E402
from services.strength_calculator_service import StrengthCalculatorService  # noqa: E402


# ── Pure guard: _trusted_window_best ─────────────────────────────────────────────────
def test_empty_is_zero():
    assert sr._trusted_window_best([]) == 0.0


def test_single_session_accepted():
    # Nothing to compare against — a lone session is taken at face value.
    assert sr._trusted_window_best([40.0]) == 40.0


def test_lone_spike_drops_to_corroborated_runner_up():
    # 95 is >1.4x the next-best (36) and nothing corroborates it → use the runner-up.
    assert sr._trusted_window_best([95.0, 36.0, 35.0, 34.0]) == 36.0


def test_within_ratio_is_kept():
    assert sr._trusted_window_best([95.0, 90.0]) == 95.0
    # 95 < 1.4 * 70 (= 98) → still a believable jump, kept.
    assert sr._trusted_window_best([95.0, 70.0]) == 95.0


def test_exact_ratio_boundary_kept():
    # top == 1.4*second is NOT > ratio → kept (strict inequality).
    assert sr._trusted_window_best([70.0, 50.0]) == 70.0


def test_clear_spike_excluded():
    assert sr._trusted_window_best([100.0, 50.0]) == 50.0


def test_corroborated_high_weight_is_kept():
    # Two sessions both heavy → genuine capacity, not an artifact.
    assert sr._trusted_window_best([95.0, 92.0, 30.0]) == 95.0


# ── Reddit scenario: lone heavy machine session excluded from carry-forward ───────────
def _row(weight_kg, reps, name="Cable Lateral Pulldown", gym=None):
    return {
        "gym_profile_id": gym,
        "completed_at": "2026-06-01T10:00:00Z",
        "sets_json": [{"name": name, "weight_kg": weight_kg, "reps": reps, "sets": 3}],
    }


def test_session_extraction_collects_one_per_row():
    svc = StrengthCalculatorService()
    logs = [_row(60, 10), _row(40, 10), _row(40, 10)]
    by_ex = sr._session_one_rms_by_exercise(logs, svc)
    key = next(iter(by_ex))
    assert len(by_ex[key]) == 3  # three sessions → three per-session 1RMs


def test_lone_machine_spike_excluded_from_window_best():
    svc = StrengthCalculatorService()
    # One 95kg session (easy-calibrated machine) amid five honest ~40kg sessions.
    logs = [_row(95, 10, gym="A")] + [_row(40, 10, gym="B") for _ in range(5)]
    by_ex = sr._session_one_rms_by_exercise(logs, svc)
    key = next(iter(by_ex))
    vals = sorted(by_ex[key], reverse=True)
    raw_top = vals[0]
    trusted = sr._trusted_window_best(by_ex[key])
    assert trusted < raw_top, "lone 95kg spike must not set the sticky best"
    # The trusted best should reflect the corroborated ~40kg work, not the 95kg artifact.
    assert trusted == vals[1]


def test_consistent_machine_weight_is_trusted():
    svc = StrengthCalculatorService()
    # Same exercise, consistently ~50kg across sessions → that IS the user's capacity.
    logs = [_row(50, 10) for _ in range(4)]
    by_ex = sr._session_one_rms_by_exercise(logs, svc)
    key = next(iter(by_ex))
    trusted = sr._trusted_window_best(by_ex[key])
    assert trusted == max(by_ex[key])


def test_display_names_preserved():
    names = sr._display_names_by_key([_row(50, 10, name="Cable Lateral Pulldown")])
    assert names["cable lateral pulldown"] == "Cable Lateral Pulldown"
