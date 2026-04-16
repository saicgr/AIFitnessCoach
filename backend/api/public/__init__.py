"""Public (unauthenticated) API surface for shareable resources."""
from fastapi import APIRouter

from api.public import recipes as recipes_public

router = APIRouter()
router.include_router(recipes_public.router)
