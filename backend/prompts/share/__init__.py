"""Loader for Imports-feature prompts.

Each Gemini prompt for the share funnel lives in a `.md` sibling so it
can be edited without a code change. `load(name)` returns the string
contents — cached after first read.
"""
from __future__ import annotations

import os
from functools import lru_cache

_PROMPTS_DIR = os.path.dirname(__file__)


@lru_cache(maxsize=16)
def load(name: str) -> str:
    """Return the prompt body for `name` (without extension)."""
    path = os.path.join(_PROMPTS_DIR, f"{name}.md")
    with open(path, "r", encoding="utf-8") as fh:
        return fh.read().rstrip() + "\n"
