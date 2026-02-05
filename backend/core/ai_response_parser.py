"""
Centralized AI Response Parser for robust JSON extraction.

This module provides a battle-tested utility for extracting and repairing
JSON from AI responses, handling all common edge cases:
- Markdown code blocks (```json, ```)
- Text before/after JSON
- Multiple JSON objects
- Truncated responses
- Control characters
- Trailing commas
- Nested quote issues
- Unicode escaping problems

Usage:
    from core.ai_response_parser import parse_ai_json

    result = parse_ai_json(ai_response, expected_fields=["headline", "sections"])

    if result.success:
        data = result.data
    else:
        logger.error(f"Parse failed: {result.error}")
"""

import ast
import json
import re
from dataclasses import dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple

from core.logger import get_logger

logger = get_logger(__name__)


class ParseStrategy(Enum):
    """Strategies used to parse the JSON, ordered by preference."""

    DIRECT = "direct"  # Direct json.loads()
    MARKDOWN_EXTRACTION = "markdown"  # Extracted from code blocks
    BOUNDARY_EXTRACTION = "boundary"  # Found JSON boundaries { }
    TRAILING_COMMA_FIX = "trailing_comma"  # Fixed trailing commas
    CONTROL_CHAR_FIX = "control_char"  # Fixed control characters
    TRUNCATION_REPAIR = "truncation"  # Closed unclosed brackets
    AST_FALLBACK = "ast"  # Python AST literal eval
    REGEX_EXTRACTION = "regex"  # Field-by-field extraction


@dataclass
class ParseResult:
    """Result of JSON parsing attempt."""

    success: bool
    data: Optional[Dict[str, Any]]
    strategy_used: Optional[ParseStrategy]
    error: Optional[str]
    original_content: str
    repaired_content: Optional[str]
    repair_steps: List[str] = field(default_factory=list)

    @property
    def was_repaired(self) -> bool:
        """True if any repair was needed."""
        return self.strategy_used not in [ParseStrategy.DIRECT, None]


class AIResponseParser:
    """
    Robust JSON parser for AI responses.

    Implements a fallback hierarchy of parsing strategies,
    logging each step for debugging and monitoring.
    """

    def __init__(self, strict_mode: bool = False):
        """
        Initialize parser.

        Args:
            strict_mode: If True, raise exceptions instead of returning ParseResult with errors
        """
        self.strict_mode = strict_mode
        self._parse_attempts = 0
        self._parse_successes = 0
        self._strategy_counts: Dict[ParseStrategy, int] = {}

    def parse_json(
        self,
        content: str,
        expected_fields: Optional[List[str]] = None,
        context: Optional[str] = None,
    ) -> ParseResult:
        """
        Parse JSON from AI response with comprehensive repair strategies.

        Args:
            content: Raw AI response text
            expected_fields: Optional list of required fields for regex extraction fallback
            context: Optional context for logging (e.g., "workout_insights")

        Returns:
            ParseResult with parsed data or error details
        """
        self._parse_attempts += 1
        log_prefix = f"[{context}] " if context else "[AIResponseParser] "
        repair_steps: List[str] = []

        if not content or not content.strip():
            error_msg = "Empty content"
            logger.warning(f"{log_prefix}{error_msg}")
            return ParseResult(
                success=False,
                data=None,
                strategy_used=None,
                error=error_msg,
                original_content=content or "",
                repaired_content=None,
                repair_steps=[],
            )

        original = content
        working_content = content

        # Strategy 1: Direct parse
        result = self._try_direct_parse(working_content)
        if result is not None:
            logger.debug(f"{log_prefix}Direct JSON parse succeeded")
            return self._make_success_result(
                result, ParseStrategy.DIRECT, original, None, []
            )

        # Strategy 2: Extract from markdown code blocks
        extracted, extraction_step = self._extract_from_markdown(working_content)
        if extraction_step:
            repair_steps.append(extraction_step)
            working_content = extracted
            result = self._try_direct_parse(working_content)
            if result is not None:
                logger.info(f"{log_prefix}Parsed after markdown extraction")
                return self._make_success_result(
                    result,
                    ParseStrategy.MARKDOWN_EXTRACTION,
                    original,
                    working_content,
                    repair_steps,
                )

        # Strategy 3: Find JSON boundaries
        bounded, boundary_step = self._find_json_boundaries(working_content)
        if boundary_step:
            repair_steps.append(boundary_step)
            working_content = bounded
            result = self._try_direct_parse(working_content)
            if result is not None:
                logger.info(f"{log_prefix}Parsed after boundary extraction")
                return self._make_success_result(
                    result,
                    ParseStrategy.BOUNDARY_EXTRACTION,
                    original,
                    working_content,
                    repair_steps,
                )

        # Strategy 4: Fix trailing commas
        fixed, comma_step = self._fix_trailing_commas(working_content)
        if comma_step:
            repair_steps.append(comma_step)
            working_content = fixed
            result = self._try_direct_parse(working_content)
            if result is not None:
                logger.info(f"{log_prefix}Parsed after trailing comma fix")
                return self._make_success_result(
                    result,
                    ParseStrategy.TRAILING_COMMA_FIX,
                    original,
                    working_content,
                    repair_steps,
                )

        # Strategy 5: Fix control characters
        fixed, ctrl_step = self._fix_control_characters(working_content)
        if ctrl_step:
            repair_steps.append(ctrl_step)
            working_content = fixed
            result = self._try_direct_parse(working_content)
            if result is not None:
                logger.info(f"{log_prefix}Parsed after control char fix")
                return self._make_success_result(
                    result,
                    ParseStrategy.CONTROL_CHAR_FIX,
                    original,
                    working_content,
                    repair_steps,
                )

        # Strategy 6: Repair truncation (close brackets)
        repaired, trunc_step = self._repair_truncation(working_content)
        if trunc_step:
            repair_steps.append(trunc_step)
            working_content = repaired
            result = self._try_direct_parse(working_content)
            if result is not None:
                logger.info(f"{log_prefix}Parsed after truncation repair")
                return self._make_success_result(
                    result,
                    ParseStrategy.TRUNCATION_REPAIR,
                    original,
                    working_content,
                    repair_steps,
                )

        # Strategy 7: Python AST fallback
        result = self._try_ast_parse(working_content)
        if result is not None:
            repair_steps.append("Used Python AST literal_eval")
            logger.info(f"{log_prefix}Parsed via AST fallback")
            return self._make_success_result(
                result,
                ParseStrategy.AST_FALLBACK,
                original,
                working_content,
                repair_steps,
            )

        # Strategy 8: Regex field extraction (last resort)
        if expected_fields:
            result = self._regex_field_extraction(original, expected_fields)
            if result:
                repair_steps.append(f"Extracted fields via regex: {expected_fields}")
                logger.info(f"{log_prefix}Parsed via regex extraction")
                return self._make_success_result(
                    result,
                    ParseStrategy.REGEX_EXTRACTION,
                    original,
                    None,
                    repair_steps,
                )

        # All strategies failed
        error_msg = "All parsing strategies exhausted"
        logger.warning(
            f"{log_prefix}{error_msg}. Content preview: {original[:200]}..."
        )

        if self.strict_mode:
            raise ValueError(f"{log_prefix}{error_msg}")

        return ParseResult(
            success=False,
            data=None,
            strategy_used=None,
            error=error_msg,
            original_content=original,
            repaired_content=working_content,
            repair_steps=repair_steps,
        )

    def _try_direct_parse(self, content: str) -> Optional[Dict]:
        """Attempt direct JSON parsing."""
        try:
            parsed = json.loads(content)
            if isinstance(parsed, dict):
                return parsed
            # If it's a list or other type, wrap it
            return {"data": parsed}
        except json.JSONDecodeError:
            return None

    def _extract_from_markdown(self, content: str) -> Tuple[str, Optional[str]]:
        """Extract JSON from markdown code blocks."""
        # Handle ```json ... ```
        json_block_match = re.search(r"```json\s*([\s\S]*?)```", content, re.IGNORECASE)
        if json_block_match:
            return json_block_match.group(1).strip(), "Extracted from ```json block"

        # Handle generic ``` ... ```
        generic_block_match = re.search(r"```\s*([\s\S]*?)```", content)
        if generic_block_match:
            extracted = generic_block_match.group(1).strip()
            # Remove language identifier if present (e.g., "json\n{...")
            if extracted.lower().startswith(("json", "javascript")):
                lines = extracted.split("\n", 1)
                if len(lines) > 1:
                    extracted = lines[1].strip()
            return extracted, "Extracted from ``` block"

        # Handle text before JSON like "Here's the JSON:\n{...}"
        prefixes = [
            r"here(?:'s| is) the (?:json|response|output)[:\s]*",
            r"response[:\s]*",
            r"output[:\s]*",
            r"json[:\s]*",
        ]
        for prefix in prefixes:
            match = re.search(prefix + r"(\{[\s\S]*)", content, re.IGNORECASE)
            if match:
                return match.group(1).strip(), f"Removed text prefix before JSON"

        return content, None

    def _find_json_boundaries(self, content: str) -> Tuple[str, Optional[str]]:
        """Find outermost JSON object/array boundaries."""
        # Try to find a JSON object first (most common case)
        first_brace = content.find("{")
        if first_brace != -1:
            # Find matching closing brace by counting
            depth = 0
            in_string = False
            escape_next = False
            last_valid_close = -1

            for i, char in enumerate(content[first_brace:], start=first_brace):
                if escape_next:
                    escape_next = False
                    continue
                if char == "\\":
                    escape_next = True
                    continue
                if char == '"' and not escape_next:
                    in_string = not in_string
                    continue
                if in_string:
                    continue
                if char == "{":
                    depth += 1
                elif char == "}":
                    depth -= 1
                    if depth == 0:
                        last_valid_close = i
                        break

            if last_valid_close != -1:
                extracted = content[first_brace : last_valid_close + 1]
                # Always return extracted content if we found valid boundaries
                # The condition check is only for the step message
                if first_brace > 0 or last_valid_close < len(content) - 1:
                    return extracted, "Found JSON object boundaries"
                else:
                    # Content matches exactly, but still return it for further processing
                    return extracted, "Found JSON object boundaries"

        # Only try array if no object was found
        first_bracket = content.find("[")
        if first_bracket != -1:
            depth = 0
            in_string = False
            escape_next = False
            last_valid_close = -1

            for i, char in enumerate(content[first_bracket:], start=first_bracket):
                if escape_next:
                    escape_next = False
                    continue
                if char == "\\":
                    escape_next = True
                    continue
                if char == '"' and not escape_next:
                    in_string = not in_string
                    continue
                if in_string:
                    continue
                if char == "[":
                    depth += 1
                elif char == "]":
                    depth -= 1
                    if depth == 0:
                        last_valid_close = i
                        break

            if last_valid_close != -1:
                extracted = content[first_bracket : last_valid_close + 1]
                if first_bracket > 0 or last_valid_close < len(content) - 1:
                    return extracted, "Found JSON array boundaries"
                else:
                    return extracted, "Found JSON array boundaries"

        return content, None

    def _fix_trailing_commas(self, content: str) -> Tuple[str, Optional[str]]:
        """Remove trailing commas before closing brackets/braces."""
        original = content
        # Fix trailing commas: ,} or ,]
        fixed = re.sub(r",(\s*[}\]])", r"\1", content)
        if fixed != original:
            return fixed, "Removed trailing commas"
        return content, None

    def _fix_control_characters(self, content: str) -> Tuple[str, Optional[str]]:
        """Fix unescaped control characters in strings."""
        original = content

        # We need to be careful to only fix control chars inside string values
        # For simplicity, we'll fix common patterns
        fixed = content

        # Fix unescaped newlines (but not \\n which is already escaped)
        fixed = re.sub(r'(?<!\\)\n', r'\\n', fixed)
        # Fix unescaped tabs
        fixed = re.sub(r'(?<!\\)\t', r'\\t', fixed)
        # Fix unescaped carriage returns
        fixed = re.sub(r'(?<!\\)\r', r'\\r', fixed)
        # Fix unescaped form feeds
        fixed = re.sub(r'(?<!\\)\f', r'\\f', fixed)
        # Note: We don't fix \b (backspace) because in regex \b is a word boundary
        # and real backspace characters (0x08) are rare in AI responses

        if fixed != original:
            return fixed, "Fixed control characters"
        return content, None

    def _repair_truncation(self, content: str) -> Tuple[str, Optional[str]]:
        """Close unclosed brackets and braces, handle unterminated strings."""
        repaired = content.rstrip()
        changes_made = []

        # Check for unterminated string
        in_string = False
        escape_next = False
        for char in repaired:
            if escape_next:
                escape_next = False
                continue
            if char == "\\":
                escape_next = True
                continue
            if char == '"':
                in_string = not in_string

        if in_string:
            # Close unterminated string
            if repaired.endswith(","):
                repaired = repaired[:-1]
            repaired += '"'
            changes_made.append("closed unterminated string")

        # Count and close brackets/braces
        # Need to recount after potential string fix
        open_braces = 0
        open_brackets = 0
        in_string = False
        escape_next = False

        for char in repaired:
            if escape_next:
                escape_next = False
                continue
            if char == "\\":
                escape_next = True
                continue
            if char == '"':
                in_string = not in_string
                continue
            if in_string:
                continue
            if char == "{":
                open_braces += 1
            elif char == "}":
                open_braces -= 1
            elif char == "[":
                open_brackets += 1
            elif char == "]":
                open_brackets -= 1

        if open_brackets > 0:
            repaired += "]" * open_brackets
            changes_made.append(f"closed {open_brackets} bracket(s)")

        if open_braces > 0:
            repaired += "}" * open_braces
            changes_made.append(f"closed {open_braces} brace(s)")

        if changes_made:
            return repaired, "Truncation repair: " + ", ".join(changes_made)
        return content, None

    def _try_ast_parse(self, content: str) -> Optional[Dict]:
        """Try Python AST for more flexible parsing (handles single quotes, etc.)."""
        try:
            # Convert JSON literals to Python equivalents
            python_str = content
            python_str = re.sub(r'\btrue\b', 'True', python_str)
            python_str = re.sub(r'\bfalse\b', 'False', python_str)
            python_str = re.sub(r'\bnull\b', 'None', python_str)

            result = ast.literal_eval(python_str)
            if isinstance(result, dict):
                return result
            return {"data": result}
        except (SyntaxError, ValueError, TypeError):
            return None

    def _regex_field_extraction(
        self,
        content: str,
        expected_fields: List[str],
    ) -> Optional[Dict]:
        """Extract fields via regex as last resort."""
        result: Dict[str, Any] = {}

        for field_name in expected_fields:
            # Match string values: "field": "value"
            str_match = re.search(
                rf'"{re.escape(field_name)}"\s*:\s*"((?:[^"\\]|\\.)*))"',
                content
            )
            if str_match:
                # Unescape the string
                value = str_match.group(1)
                value = value.replace('\\"', '"').replace("\\n", "\n")
                result[field_name] = value
                continue

            # Match numeric values: "field": 123 or "field": 12.34
            num_match = re.search(
                rf'"{re.escape(field_name)}"\s*:\s*(-?\d+(?:\.\d+)?)',
                content
            )
            if num_match:
                val = num_match.group(1)
                result[field_name] = float(val) if "." in val else int(val)
                continue

            # Match boolean values: "field": true/false
            bool_match = re.search(
                rf'"{re.escape(field_name)}"\s*:\s*(true|false)',
                content,
                re.IGNORECASE,
            )
            if bool_match:
                result[field_name] = bool_match.group(1).lower() == "true"
                continue

            # Match simple array values: "field": ["a", "b"]
            arr_match = re.search(
                rf'"{re.escape(field_name)}"\s*:\s*\[([^\]]*)\]',
                content
            )
            if arr_match:
                arr_content = arr_match.group(1)
                items = re.findall(r'"((?:[^"\\]|\\.)*)"', arr_content)
                result[field_name] = items
                continue

            # Match object values (simple extraction)
            obj_match = re.search(
                rf'"{re.escape(field_name)}"\s*:\s*(\{{[^}}]*\}})',
                content
            )
            if obj_match:
                try:
                    result[field_name] = json.loads(obj_match.group(1))
                except json.JSONDecodeError:
                    pass

        # Only return if we found at least some fields
        return result if result else None

    def _make_success_result(
        self,
        data: Dict,
        strategy: ParseStrategy,
        original: str,
        repaired: Optional[str],
        repair_steps: List[str],
    ) -> ParseResult:
        """Create successful ParseResult and update stats."""
        self._parse_successes += 1
        self._strategy_counts[strategy] = self._strategy_counts.get(strategy, 0) + 1

        return ParseResult(
            success=True,
            data=data,
            strategy_used=strategy,
            error=None,
            original_content=original,
            repaired_content=repaired,
            repair_steps=repair_steps,
        )

    def get_stats(self) -> Dict[str, Any]:
        """Get parsing statistics for monitoring."""
        return {
            "total_attempts": self._parse_attempts,
            "successes": self._parse_successes,
            "failures": self._parse_attempts - self._parse_successes,
            "success_rate": (
                self._parse_successes / self._parse_attempts
                if self._parse_attempts > 0
                else 0
            ),
            "strategy_distribution": {
                s.value: c for s, c in self._strategy_counts.items()
            },
        }

    def reset_stats(self) -> None:
        """Reset parsing statistics."""
        self._parse_attempts = 0
        self._parse_successes = 0
        self._strategy_counts = {}


# Singleton instance for reuse across the application
_default_parser: Optional[AIResponseParser] = None


def get_ai_response_parser() -> AIResponseParser:
    """Get or create the default parser instance."""
    global _default_parser
    if _default_parser is None:
        _default_parser = AIResponseParser()
    return _default_parser


def parse_ai_json(
    content: str,
    expected_fields: Optional[List[str]] = None,
    context: Optional[str] = None,
) -> ParseResult:
    """
    Convenience function for one-off parsing.

    Usage:
        result = parse_ai_json(response.text, expected_fields=["headline", "sections"])
        if result.success:
            data = result.data
        else:
            logger.error(f"Parse failed: {result.error}")

    Args:
        content: Raw AI response text
        expected_fields: Optional list of required fields for regex extraction fallback
        context: Optional context for logging (e.g., "workout_insights")

    Returns:
        ParseResult with parsed data or error details
    """
    return get_ai_response_parser().parse_json(content, expected_fields, context)
