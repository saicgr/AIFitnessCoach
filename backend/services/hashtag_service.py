"""Hashtag extraction service."""

import re
from typing import List


def extract_hashtags(text: str) -> List[str]:
    """Extract unique hashtags from text.

    Args:
        text: Text to extract hashtags from.

    Returns:
        List of unique lowercase hashtag strings (without the # symbol).
    """
    if not text:
        return []
    matches = re.findall(r'#(\w{1,50})', text)
    return list(set(tag.lower() for tag in matches))


def extract_mentions(text: str) -> List[str]:
    """Extract unique @mentions from text. Returns lowercase usernames without @."""
    if not text:
        return []
    matches = re.findall(r'@(\w{1,30})', text)
    return list(set(tag.lower() for tag in matches))
