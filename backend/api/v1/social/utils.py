"""
Shared utilities and helper functions for social endpoints.

This module contains common utilities used across social-related endpoints.
"""
from core.supabase_client import get_supabase


def get_supabase_client():
    """Get Supabase client for database operations."""
    return get_supabase().client
