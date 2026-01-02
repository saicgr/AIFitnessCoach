"""
Username generation utility.

Generates unique, friendly usernames for users during registration.
Format: name-based prefix + random numbers (e.g., FitAlex123, StrongSam456)
"""
import random
import string
import re
from typing import Optional

from core.supabase_client import get_supabase


def _sanitize_name(name: str) -> str:
    """Sanitize a name for use in username - remove special chars, keep letters."""
    # Remove non-alphanumeric characters
    sanitized = re.sub(r'[^a-zA-Z0-9]', '', name)
    # Capitalize first letter
    if sanitized:
        sanitized = sanitized[0].upper() + sanitized[1:].lower()
    return sanitized[:12]  # Max 12 chars from name


def _generate_suffix() -> str:
    """Generate a random numeric suffix."""
    return ''.join(random.choices(string.digits, k=random.randint(3, 5)))


def generate_username(name: Optional[str] = None, email: Optional[str] = None) -> str:
    """
    Generate a username from the user's name or email.

    Args:
        name: User's display name (preferred)
        email: User's email (fallback)

    Returns:
        A username like "FitAlex123" or "StrongUser456"
    """
    prefix = ""

    # Try to use name first
    if name:
        # Get first name only (split on space)
        first_name = name.split()[0] if name.split() else name
        prefix = _sanitize_name(first_name)

    # Fall back to email prefix
    if not prefix and email:
        email_prefix = email.split('@')[0]
        prefix = _sanitize_name(email_prefix)

    # Ultimate fallback
    if not prefix:
        fitness_prefixes = ['Fit', 'Strong', 'Active', 'Power', 'Flex']
        prefix = random.choice(fitness_prefixes) + 'User'

    # Add random suffix
    suffix = _generate_suffix()

    return f"{prefix}{suffix}"


async def generate_unique_username(name: Optional[str] = None, email: Optional[str] = None) -> str:
    """
    Generate a username that doesn't already exist in the database.

    Args:
        name: User's display name (preferred)
        email: User's email (fallback)

    Returns:
        A unique username
    """
    supabase = get_supabase()
    max_attempts = 10

    for _ in range(max_attempts):
        username = generate_username(name, email)

        # Check if username exists
        result = supabase.client.table("users").select("id").eq("username", username).execute()

        if not result.data:
            # Username is unique
            return username

    # Fallback: add timestamp to make it unique
    import time
    timestamp = int(time.time()) % 100000
    return f"{generate_username(name, email)}{timestamp}"


def generate_username_sync(name: Optional[str] = None, email: Optional[str] = None) -> str:
    """
    Synchronous version - generates username and checks uniqueness.

    Args:
        name: User's display name (preferred)
        email: User's email (fallback)

    Returns:
        A unique username
    """
    supabase = get_supabase()
    max_attempts = 10

    for _ in range(max_attempts):
        username = generate_username(name, email)

        # Check if username exists
        result = supabase.client.table("users").select("id").eq("username", username).execute()

        if not result.data:
            # Username is unique
            return username

    # Fallback: add timestamp to make it unique
    import time
    timestamp = int(time.time()) % 100000
    return f"{generate_username(name, email)}{timestamp}"
