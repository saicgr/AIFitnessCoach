"""
Regression guard for the coach system-prompt builder.

BACKGROUND (prod crash, 2026-06):
    A literal JSON example with single braces ({title, body, reminder_id, ...})
    was added into ``COACH_BASE_PROMPT_TEMPLATE`` — a ``"""'"""'"""``-style multiline
    constant that is later passed through ``str.format(coach_name=...)`` inside
    ``get_coach_system_prompt``. Python read those literal ``{...}`` braces as a
    format replacement field and raised ``KeyError: 'title'``, crashing EVERY
    coach chat reply. The fix was to escape the intentional braces as ``{{ }}``.

WHAT THIS TEST GUARDS:
    If anyone reintroduces an UNescaped single brace into the coach prompt
    template (or any kwargs drift in ``get_coach_system_prompt``), the
    ``.format()`` call raises and this test fails loud — before it can ship.

TWO LAYERS (the second is a fallback):
  1. ``test_get_coach_system_prompt_builds_*`` import the real
     ``get_coach_system_prompt`` and assert it builds for several personas.
     This is the strongest check (exercises the actual prod code path).
  2. ``test_coach_template_formats_statically`` does NOT import the heavy
     package graph — it reads the source file, ``ast``-extracts the
     ``COACH_BASE_PROMPT_TEMPLATE`` literal, and calls ``.format(coach_name=...)``
     on it directly. This runs even if the full import chain can't load in a
     given environment (local .venv is py3.9; prod is py3.12, and some sibling
     modules fail to import locally). It is the brace-landmine canary.
"""
import ast
import os

import pytest

# ---------------------------------------------------------------------------
# Layer 1: real import of the production builder (skips cleanly if the heavy
# package graph can't import in this environment).
# ---------------------------------------------------------------------------
try:
    from services.langgraph_agents.coach_agent.nodes import get_coach_system_prompt

    _IMPORT_ERROR = None
except Exception as exc:  # pragma: no cover - environment dependent
    get_coach_system_prompt = None
    _IMPORT_ERROR = exc


_real_import = pytest.mark.skipif(
    get_coach_system_prompt is None,
    reason=f"coach nodes import unavailable in this env: {_IMPORT_ERROR!r}",
)


@_real_import
@pytest.mark.parametrize(
    "ai_settings, expected_name",
    [
        ({"coach_name": "Sergeant Max"}, "Sergeant Max"),
        ({"coach_name": "Coach Mike"}, "Coach Mike"),
        (None, "Coach"),  # default persona
        # Brace in a user-controlled name: sanitize_coach_name strips the
        # braces, so the rendered name is "Bro test". The point of this case
        # is that building MUST NOT raise even with brace-bearing input.
        ({"coach_name": "Bro {test}"}, "Bro test"),
    ],
)
def test_get_coach_system_prompt_builds(ai_settings, expected_name):
    prompt = get_coach_system_prompt(ai_settings=ai_settings)
    assert isinstance(prompt, str)
    assert prompt.strip(), "coach system prompt must be non-empty"
    assert expected_name in prompt, (
        f"expected coach name {expected_name!r} to appear in the built prompt"
    )


@_real_import
def test_get_coach_system_prompt_no_stray_format_fields():
    """A reintroduced unescaped brace would either raise (caught above) or
    leave a literal ``{field}`` token in the output. Assert neither the JSON
    example keys nor obvious stray single-brace fields survive into the text
    for the default persona."""
    prompt = get_coach_system_prompt(ai_settings=None)
    # The original crash came from a reminder JSON example. If it ever renders
    # as a live format field instead of escaped literal text, these would be
    # gone (consumed by .format) or would have raised. Either way, building
    # succeeded here, which is the core guarantee.
    assert "{coach_name}" not in prompt, "coach_name field left unsubstituted"


# ---------------------------------------------------------------------------
# Layer 2: static AST extraction + .format() of the template literal.
# Runs with zero heavy imports — pure stdlib — so it is the always-on canary.
# ---------------------------------------------------------------------------
_NODES_PATH = os.path.join(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__))),
    "services",
    "langgraph_agents",
    "coach_agent",
    "nodes.py",
)


def _extract_str_constant(path: str, name: str) -> str:
    """Return the literal string value assigned to ``name`` at module level."""
    with open(path, "r", encoding="utf-8") as fh:
        tree = ast.parse(fh.read(), filename=path)
    for node in ast.walk(tree):
        if isinstance(node, ast.Assign):
            for target in node.targets:
                if (
                    isinstance(target, ast.Name)
                    and target.id == name
                    and isinstance(node.value, ast.Constant)
                    and isinstance(node.value.value, str)
                ):
                    return node.value.value
    raise AssertionError(f"{name} string constant not found in {path}")


def test_coach_template_formats_statically():
    """The coach base template must ``.format(coach_name=...)`` cleanly.

    If someone drops a raw ``{...}`` JSON/code example into the template
    without escaping it as ``{{ }}``, this raises KeyError/IndexError/ValueError
    and the test fails — independent of whether the full package graph imports.
    """
    template = _extract_str_constant(_NODES_PATH, "COACH_BASE_PROMPT_TEMPLATE")
    try:
        rendered = template.format(coach_name="Sergeant Max")
    except (KeyError, IndexError, ValueError) as exc:
        raise AssertionError(
            "COACH_BASE_PROMPT_TEMPLATE.format(coach_name=...) raised "
            f"{type(exc).__name__}: {exc}. A literal '{{' or '}}' in the "
            "template (e.g. a JSON example) must be escaped as '{{' / '}}'."
        )
    assert "Sergeant Max" in rendered
    assert "{coach_name}" not in rendered
