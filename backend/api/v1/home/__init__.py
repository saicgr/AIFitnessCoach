"""Home screen endpoints."""
from fastapi import APIRouter

from .bootstrap import router as bootstrap_router

router = APIRouter()
router.include_router(bootstrap_router)
