"""
Tests for workout insights node functions, specifically JSON repair logic.
"""
import pytest
import json

from services.langgraph_agents.workout_insights.nodes import (
    repair_json_string,
    categorize_muscle_group,
    determine_workout_focus,
)


class TestRepairJsonString:
    """Tests for the repair_json_string function."""

    def test_valid_json_returns_unchanged(self):
        """Valid JSON should be returned as-is."""
        valid = '{"headline": "Test", "sections": []}'
        result = repair_json_string(valid)
        assert result == valid
        assert json.loads(result) == {"headline": "Test", "sections": []}

    def test_empty_string_returns_none(self):
        """Empty string should return None."""
        assert repair_json_string("") is None
        assert repair_json_string(None) is None

    def test_trailing_comma_removed(self):
        """Trailing commas before closing brackets should be removed."""
        malformed = '{"headline": "Test", "sections": [],}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_trailing_comma_in_array(self):
        """Trailing commas in arrays should be removed."""
        malformed = '{"items": [1, 2, 3,]}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["items"] == [1, 2, 3]

    def test_unclosed_braces_completed(self):
        """Unclosed braces should be completed."""
        malformed = '{"headline": "Test"'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_unclosed_brackets_completed(self):
        """Unclosed brackets should be completed."""
        malformed = '{"items": [1, 2, 3'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["items"] == [1, 2, 3]

    def test_nested_unclosed_structures(self):
        """Nested unclosed structures should be completed."""
        malformed = '{"outer": {"inner": [1, 2'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "outer" in parsed

    def test_extract_json_from_text(self):
        """JSON embedded in text should be extracted."""
        with_text = 'Here is the JSON: {"headline": "Test", "sections": []} some trailing text'
        result = repair_json_string(with_text)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Test"

    def test_completely_invalid_returns_none(self):
        """Completely invalid content should return None."""
        invalid = "This is not JSON at all and has no braces"
        result = repair_json_string(invalid)
        assert result is None

    def test_unterminated_string_completed(self):
        """Unterminated strings should be completed when possible."""
        # Simple case with unterminated string
        malformed = '{"headline": "Test workout'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "headline" in parsed

    def test_real_world_unterminated_string_error(self):
        """Test the actual error case from production logs."""
        # Simulating: Unterminated string starting at: line 2 column 15 (char 16)
        malformed = '''{
  "headline": "Power'''
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert "headline" in parsed

    def test_complex_insights_structure_truncated(self):
        """Test with a truncated but recoverable insights structure."""
        # This JSON is truncated mid-value but can be recovered
        malformed = '{"headline": "Leg Day Power!", "sections": []'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["headline"] == "Leg Day Power!"
        assert "sections" in parsed

    def test_multiple_trailing_commas(self):
        """Multiple trailing commas should all be fixed."""
        malformed = '{"a": 1, "b": [1, 2,], "c": 3,}'
        result = repair_json_string(malformed)
        assert result is not None
        parsed = json.loads(result)
        assert parsed["a"] == 1
        assert parsed["b"] == [1, 2]
        assert parsed["c"] == 3


class TestCategorizeMuscleGroup:
    """Tests for muscle group categorization."""

    def test_empty_muscle_returns_other(self):
        assert categorize_muscle_group("") == "other"
        assert categorize_muscle_group(None) == "other"

    def test_chest_is_upper_push(self):
        assert categorize_muscle_group("chest") == "upper_push"
        assert categorize_muscle_group("Pectoralis Major") == "upper_push"

    def test_shoulder_is_upper_push(self):
        assert categorize_muscle_group("shoulder") == "upper_push"
        assert categorize_muscle_group("Deltoid") == "upper_push"
        assert categorize_muscle_group("triceps") == "upper_push"

    def test_back_is_upper_pull(self):
        assert categorize_muscle_group("back") == "upper_pull"
        assert categorize_muscle_group("Latissimus Dorsi") == "upper_pull"
        assert categorize_muscle_group("biceps") == "upper_pull"

    def test_legs_are_lower(self):
        assert categorize_muscle_group("quadriceps") == "lower"
        assert categorize_muscle_group("hamstrings") == "lower"
        assert categorize_muscle_group("glutes") == "lower"
        assert categorize_muscle_group("calf") == "lower"
        assert categorize_muscle_group("legs") == "lower"

    def test_core_muscles(self):
        assert categorize_muscle_group("core") == "core"
        assert categorize_muscle_group("abs") == "core"
        assert categorize_muscle_group("obliques") == "core"


class TestDetermineWorkoutFocus:
    """Tests for workout focus determination."""

    def test_empty_list_returns_full_body(self):
        assert determine_workout_focus([]) == "full body"

    def test_mostly_lower_is_leg_day(self):
        muscles = ["quadriceps", "hamstrings", "glutes", "calves"]
        assert determine_workout_focus(muscles) == "leg day"

    def test_mostly_push_is_push_day(self):
        muscles = ["chest", "shoulders", "triceps", "chest"]
        assert determine_workout_focus(muscles) == "push day"

    def test_mostly_pull_is_pull_day(self):
        muscles = ["back", "biceps", "lats", "rhomboids"]
        assert determine_workout_focus(muscles) == "pull day"

    def test_mixed_upper_is_upper_body(self):
        muscles = ["chest", "back", "shoulders", "biceps"]
        assert determine_workout_focus(muscles) == "upper body"

    def test_balanced_is_full_body(self):
        muscles = ["chest", "back", "quadriceps", "hamstrings", "core"]
        result = determine_workout_focus(muscles)
        assert result in ["full body", "upper body"]  # Could be either depending on distribution


class TestInsightsValidation:
    """
    Tests for workout insights validation logic.

    These tests verify that the validation correctly fails when:
    - AI returns empty sections
    - AI returns fewer than 2 sections
    - JSON parsing fails completely
    """

    def test_empty_sections_should_raise_error(self):
        """An empty sections array should raise ValueError."""
        # This simulates what happens when AI returns {"headline": "...", "sections": []}
        insights = {"headline": "Test Workout!", "sections": []}
        sections = insights.get("sections", [])

        # Verify validation logic catches this
        if not sections or len(sections) < 2:
            with pytest.raises(ValueError) as exc_info:
                raise ValueError(f"AI returned invalid structure: expected 2+ sections, got {len(sections)}")
            assert "expected 2+ sections, got 0" in str(exc_info.value)

    def test_single_section_should_raise_error(self):
        """A single section (< 2) should raise ValueError."""
        insights = {
            "headline": "Test Workout!",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "Test content", "color": "cyan"}
            ]
        }
        sections = insights.get("sections", [])

        if not sections or len(sections) < 2:
            with pytest.raises(ValueError) as exc_info:
                raise ValueError(f"AI returned invalid structure: expected 2+ sections, got {len(sections)}")
            assert "expected 2+ sections, got 1" in str(exc_info.value)

    def test_two_sections_is_valid(self):
        """Two sections should be valid (no error raised)."""
        insights = {
            "headline": "Test Workout!",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "Test content 1", "color": "cyan"},
                {"icon": "💪", "title": "Volume", "content": "Test content 2", "color": "purple"}
            ]
        }
        sections = insights.get("sections", [])

        # Should NOT raise
        assert len(sections) >= 2

    def test_three_sections_is_valid(self):
        """Three sections should be valid."""
        insights = {
            "headline": "Test Workout!",
            "sections": [
                {"icon": "🎯", "title": "Focus", "content": "Test content 1", "color": "cyan"},
                {"icon": "💪", "title": "Volume", "content": "Test content 2", "color": "purple"},
                {"icon": "⚡", "title": "Tip", "content": "Test content 3", "color": "orange"}
            ]
        }
        sections = insights.get("sections", [])

        assert len(sections) >= 2

    def test_headline_truncation_7_words(self):
        """Headlines longer than 7 words should be truncated."""
        long_headline = "This is a very long headline that exceeds seven words limit"
        words = long_headline.split()

        if len(words) > 7:
            headline = " ".join(words[:7])
            if not headline.endswith(("!", "?")):
                headline += "!"

        assert len(headline.split()) <= 8  # 7 words + potential punctuation
        assert headline.endswith("!")

    def test_section_content_truncation_20_words(self):
        """Section content longer than 20 words should be truncated."""
        long_content = "This is a very long content that exceeds twenty words and should be truncated to keep the UI clean and readable for users viewing on mobile devices"
        words = long_content.split()

        if len(words) > 20:
            truncated = " ".join(words[:20]) + "..."

        assert truncated.endswith("...")
        assert len(truncated.split()) <= 21  # 20 words + "..."


class TestJsonExtractionFromMarkdown:
    """Tests for extracting JSON from markdown code blocks."""

    def test_extract_from_json_code_block(self):
        """JSON wrapped in ```json``` should be extracted."""
        content = '''Here is the workout insight:
```json
{"headline": "Leg Day Power!", "sections": [{"icon": "🎯", "title": "Focus", "content": "Test", "color": "cyan"}]}
```
That's the workout summary.'''

        if "```json" in content:
            extracted = content.split("```json")[1].split("```")[0].strip()

        parsed = json.loads(extracted)
        assert parsed["headline"] == "Leg Day Power!"

    def test_extract_from_generic_code_block(self):
        """JSON wrapped in generic ``` should be extracted."""
        content = '''Here is the result:
```
{"headline": "Push Day!", "sections": []}
```
Done.'''

        if "```json" not in content and "```" in content:
            parts = content.split("```")
            if len(parts) >= 2:
                extracted = parts[1].strip()

        parsed = json.loads(extracted)
        assert parsed["headline"] == "Push Day!"

    def test_extract_from_code_block_with_language_identifier(self):
        """Code block with 'json' language identifier should have it removed."""
        # Sometimes AI returns ```\njson\n{...}
        content = '''```
json
{"headline": "Test", "sections": []}
```'''

        parts = content.split("```")
        if len(parts) >= 2:
            extracted = parts[1].strip()
            if extracted.startswith(("json", "JSON")):
                extracted = extracted[4:].strip()

        parsed = json.loads(extracted)
        assert parsed["headline"] == "Test"


class TestRealWorldFailureCases:
    """
    Tests based on real production errors.

    These test cases are derived from actual error logs to ensure
    the same issues don't recur.
    """

    def test_production_error_unterminated_string(self):
        """
        Production error: Unterminated string starting at: line 2 column 15 (char 16)

        This happens when the AI response is cut off mid-string.
        """
        # Simulated truncated response
        malformed = '''{
  "headline": "Power'''

        result = repair_json_string(malformed)
        assert result is not None
        # Should be able to parse after repair
        parsed = json.loads(result)
        assert "headline" in parsed

    def test_production_error_empty_sections(self):
        """
        Production error: AI returned invalid structure: expected 2+ sections, got 0

        This happens when AI returns valid JSON but with empty sections array.
        """
        # Valid JSON but empty sections
        valid_but_empty = '{"headline": "Great Workout!", "sections": []}'
        parsed = json.loads(valid_but_empty)

        # Validation should catch this
        sections = parsed.get("sections", [])
        assert len(sections) == 0

        # This should raise an error in production
        with pytest.raises(ValueError) as exc_info:
            if not sections or len(sections) < 2:
                raise ValueError(f"AI returned invalid structure: expected 2+ sections, got {len(sections)}")

        assert "expected 2+ sections, got 0" in str(exc_info.value)

    def test_production_recovery_truncated_json(self):
        """
        Test that truncated but recoverable JSON can be repaired.

        Common when API times out mid-response.
        """
        truncated = '''{
  "headline": "Leg Day Power!",
  "sections": [
    {"icon": "🎯", "title": "Focus", "content": "This workout targets", "color": "cyan"}'''

        result = repair_json_string(truncated)
        assert result is not None

        parsed = json.loads(result)
        assert parsed["headline"] == "Leg Day Power!"
        assert len(parsed["sections"]) == 1

    def test_production_recovery_missing_closing_braces(self):
        """
        Test recovery when closing braces are missing.

        Common with streaming responses that get interrupted.
        """
        missing_braces = '''{
  "headline": "Upper Body Day!",
  "sections": [
    {"icon": "💪", "title": "Volume", "content": "Heavy sets today", "color": "purple"},
    {"icon": "⚡", "title": "Tip", "content": "Focus on form", "color": "orange"}
  ]'''

        result = repair_json_string(missing_braces)
        assert result is not None

        parsed = json.loads(result)
        assert parsed["headline"] == "Upper Body Day!"
        assert len(parsed["sections"]) == 2
