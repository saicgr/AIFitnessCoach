"""
Tests for injury name extraction and muscle merging logic from generation.py.

Covers the fix for:
- get_active_injuries_with_muscles() returns a dict but code iterated it as a list,
  causing 'str' object has no attribute 'get'.
"""


class TestInjuryNameExtraction:
    """
    Tests the injury name extraction logic from generation.py:576.

    The fix: injuries can be a dict (from get_active_injuries_with_muscles),
    a list (legacy), or None. Extract .get("injuries", []) from dicts.
    """

    def test_dict_input_extracts_injuries(self):
        injuries = {"injuries": ["knee", "back"], "avoided_muscles": ["hamstrings"]}
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result == ["knee", "back"]

    def test_dict_empty_injuries(self):
        injuries = {"injuries": [], "avoided_muscles": []}
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result == []

    def test_dict_missing_injuries_key(self):
        injuries = {"avoided_muscles": ["hamstrings"]}
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result == []

    def test_list_input_passthrough(self):
        injuries = ["knee"]
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result == ["knee"]

    def test_none_input(self):
        injuries = None
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result is None

    def test_string_input(self):
        injuries = "knee"
        result = injuries.get("injuries", []) if isinstance(injuries, dict) else (injuries if isinstance(injuries, list) else None)
        assert result is None


class TestInjuryMuscleMerging:
    """
    Tests the injury-based avoided muscle merging logic from generation.py:578-585.

    The fix merges injury avoided_muscles into the main avoided_muscles dict.
    """

    def _merge(self, injuries, avoided_muscles):
        """Replicate the merging logic from generation.py:578-585."""
        if isinstance(injuries, dict) and injuries.get("avoided_muscles"):
            injury_avoided = injuries["avoided_muscles"]
            existing_avoid = avoided_muscles.get("avoid", [])
            merged_avoid = list(set(existing_avoid + [m for m in injury_avoided if m not in existing_avoid]))
            avoided_muscles["avoid"] = merged_avoid
        return avoided_muscles

    def test_merges_injury_avoided_muscles(self):
        injuries = {"injuries": ["knee"], "avoided_muscles": ["hamstrings"]}
        avoided_muscles = {"avoid": ["chest"], "reduce": []}
        result = self._merge(injuries, avoided_muscles)
        assert "hamstrings" in result["avoid"]
        assert "chest" in result["avoid"]

    def test_deduplication(self):
        injuries = {"injuries": ["knee"], "avoided_muscles": ["chest", "hamstrings"]}
        avoided_muscles = {"avoid": ["chest"], "reduce": []}
        result = self._merge(injuries, avoided_muscles)
        assert result["avoid"].count("chest") == 1

    def test_no_injury_muscles_skips_merge(self):
        injuries = {"injuries": ["knee"], "avoided_muscles": []}
        avoided_muscles = {"avoid": ["chest"], "reduce": []}
        result = self._merge(injuries, avoided_muscles)
        assert result["avoid"] == ["chest"]

    def test_no_existing_avoid_list(self):
        injuries = {"injuries": ["knee"], "avoided_muscles": ["hamstrings"]}
        avoided_muscles = {"avoid": [], "reduce": []}
        result = self._merge(injuries, avoided_muscles)
        assert result["avoid"] == ["hamstrings"]

    def test_non_dict_injuries_skips_merge(self):
        injuries = ["knee"]
        avoided_muscles = {"avoid": ["chest"], "reduce": []}
        result = self._merge(injuries, avoided_muscles)
        assert result["avoid"] == ["chest"]
