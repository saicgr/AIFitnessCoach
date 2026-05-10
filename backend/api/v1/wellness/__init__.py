"""Wellness sub-router: mood, generalized event log, etc.

These endpoints power the conversational logging pipeline + the home
Timeline section. Generated 2026-05-10.
"""
from fastapi import APIRouter

from . import events
from . import mood

router = APIRouter()
router.include_router(events.router, prefix="/events", tags=["Events"])
router.include_router(mood.router, prefix="/wellness/mood", tags=["Wellness", "Mood"])
