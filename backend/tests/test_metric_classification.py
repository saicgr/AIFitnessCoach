"""Audit: derive_tracking_metadata -> metric_keys classification.

Pure + dependency-free (no DB / network), mirroring the classifier itself, so it
runs anywhere even on the py3.9 local venv. Guards the loaded-carry rule (a
sled/carry is a distance/time STATION that also takes load, so weight must be in
its metric set) and the pure-cardio exclusion (an erg/run is never weighted).
"""
import pytest

from services.exercise_tracking_metric import derive_tracking_metadata


def _keys(name: str):
    return derive_tracking_metadata({"name": name}).get("metric_keys")


# Loaded distance/time stations -> weight MUST be present (prepended).
@pytest.mark.parametrize("name", [
    "Sled Push",
    "Box Sled Push",
    "Dumbbell Farmer's Carry",
    "Sandbag Carry",
])
def test_loaded_carries_include_weight(name):
    keys = _keys(name)
    assert keys is not None, f"{name} produced no metric_keys"
    assert "weight" in keys, f"{name} -> {keys} should include 'weight'"


# Pure cardio -> weight MUST NOT appear.
@pytest.mark.parametrize("name", ["SkiErg", "Row Erg", "Run"])
def test_pure_cardio_excludes_weight(name):
    keys = _keys(name)
    assert keys is not None, f"{name} produced no metric_keys"
    assert "weight" not in keys, f"{name} -> {keys} should NOT include 'weight'"


def test_loaded_lift_is_weight_reps():
    assert _keys("Bench Press") == ["weight", "reps"]


def test_isometric_hold_is_time():
    assert _keys("Plank") == ["time"]


def test_bodyweight_rep_movement_is_reps():
    assert _keys("Push-Up") == ["reps"]
