"""
Equipment API package.

ENDPOINTS:
- POST   /api/v1/equipment/snap                    — Classify equipment photo, return ranked matches.
- GET    /api/v1/equipment/calibration             — List user's equipment calibration rows.
- POST   /api/v1/equipment/calibration             — Create a calibration row.
- PATCH  /api/v1/equipment/calibration/{id}        — Update calibration fields.
- DELETE /api/v1/equipment/calibration/{id}        — Remove a calibration row.
"""
from fastapi import APIRouter

from api.v1.equipment.snap import router as snap_router
from api.v1.equipment.calibration import router as calibration_router

router = APIRouter()
router.include_router(snap_router)
router.include_router(calibration_router)
