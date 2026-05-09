"""
Equipment API package.

ENDPOINTS:
- POST /api/v1/equipment/snap         — Classify a single equipment photo
                                        and return ranked exercise matches.
"""
from fastapi import APIRouter

from api.v1.equipment.snap import router as snap_router

router = APIRouter()
router.include_router(snap_router)
