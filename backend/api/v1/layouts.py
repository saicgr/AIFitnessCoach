"""
Home Layout Customization API endpoints.

ENDPOINTS:
- GET  /api/v1/layouts/user/{user_id} - Get all layouts for a user
- GET  /api/v1/layouts/user/{user_id}/active - Get active layout
- POST /api/v1/layouts/user/{user_id} - Create new layout
- PUT  /api/v1/layouts/{layout_id} - Update a layout
- DELETE /api/v1/layouts/{layout_id} - Delete a layout
- POST /api/v1/layouts/{layout_id}/activate - Activate a layout
- GET  /api/v1/layouts/templates - Get all system templates
- POST /api/v1/layouts/user/{user_id}/from-template/{template_id} - Create from template
"""
from datetime import datetime
from fastapi import APIRouter, HTTPException, Request
from typing import Optional, List, Any
from pydantic import BaseModel

from core.supabase_db import get_supabase_db
from core.logger import get_logger
from core.activity_logger import log_user_activity, log_user_error

router = APIRouter(prefix="/layouts", tags=["layouts"])
logger = get_logger(__name__)


# ===================================
# Pydantic Models
# ===================================

class HomeTile(BaseModel):
    """A single tile configuration."""
    id: str
    type: str
    size: str
    order: int
    is_visible: bool = True


class HomeLayoutResponse(BaseModel):
    """Response model for a home layout."""
    id: str
    user_id: str
    name: str
    tiles: List[HomeTile]
    is_active: bool
    template_id: Optional[str]
    created_at: datetime
    updated_at: datetime


class HomeLayoutTemplateResponse(BaseModel):
    """Response model for a layout template."""
    id: str
    name: str
    description: Optional[str]
    tiles: List[HomeTile]
    icon: Optional[str]
    category: Optional[str]
    created_at: Optional[datetime]


class CreateLayoutRequest(BaseModel):
    """Request body for creating a layout."""
    name: str
    tiles: List[HomeTile]
    template_id: Optional[str] = None


class UpdateLayoutRequest(BaseModel):
    """Request body for updating a layout."""
    name: Optional[str] = None
    tiles: Optional[List[HomeTile]] = None


# ===================================
# Helper Functions
# ===================================

def parse_tiles(tiles_json: Any) -> List[HomeTile]:
    """Parse tiles from JSON to list of HomeTile objects."""
    if not tiles_json:
        return []
    if isinstance(tiles_json, list):
        return [HomeTile(**tile) if isinstance(tile, dict) else tile for tile in tiles_json]
    return []


def row_to_layout_response(row: dict) -> HomeLayoutResponse:
    """Convert database row to HomeLayoutResponse."""
    return HomeLayoutResponse(
        id=row["id"],
        user_id=row["user_id"],
        name=row["name"],
        tiles=parse_tiles(row.get("tiles", [])),
        is_active=row.get("is_active", False),
        template_id=row.get("template_id"),
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


def row_to_template_response(row: dict) -> HomeLayoutTemplateResponse:
    """Convert database row to HomeLayoutTemplateResponse."""
    return HomeLayoutTemplateResponse(
        id=row["id"],
        name=row["name"],
        description=row.get("description"),
        tiles=parse_tiles(row.get("tiles", [])),
        icon=row.get("icon"),
        category=row.get("category"),
        created_at=row.get("created_at"),
    )


# ===================================
# Endpoints
# ===================================

@router.get("/templates")
async def get_templates() -> List[HomeLayoutTemplateResponse]:
    """
    Get all system layout templates.

    Returns:
        List of available layout templates
    """
    try:
        db = get_supabase_db()
        client = db.client

        result = client.table("home_layout_templates").select("*").execute()

        if not result.data:
            return []

        templates = [row_to_template_response(row) for row in result.data]
        logger.info(f"Fetched {len(templates)} layout templates")
        return templates

    except Exception as e:
        logger.error(f"Error fetching layout templates: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}")
async def get_user_layouts(user_id: str) -> List[HomeLayoutResponse]:
    """
    Get all layouts for a user.

    Args:
        user_id: User ID

    Returns:
        List of user's layouts sorted by creation date
    """
    try:
        db = get_supabase_db()
        client = db.client

        result = client.table("home_layouts").select("*").eq(
            "user_id", user_id
        ).order("created_at", desc=True).execute()

        if not result.data:
            return []

        layouts = [row_to_layout_response(row) for row in result.data]
        logger.info(f"Fetched {len(layouts)} layouts for user {user_id}")
        return layouts

    except Exception as e:
        logger.error(f"Error fetching layouts for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/user/{user_id}/active")
async def get_active_layout(user_id: str) -> HomeLayoutResponse:
    """
    Get the active layout for a user, creating default if none exists.

    Args:
        user_id: User ID

    Returns:
        The user's active layout
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Try to get active layout
        result = client.table("home_layouts").select("*").eq(
            "user_id", user_id
        ).eq("is_active", True).limit(1).execute()

        if result.data:
            logger.info(f"Found active layout for user {user_id}")
            return row_to_layout_response(result.data[0])

        # No active layout - call helper function to create default
        logger.info(f"Creating default layout for user {user_id}")
        rpc_result = client.rpc("get_or_create_default_layout", {
            "p_user_id": user_id
        }).execute()

        if not rpc_result.data:
            raise HTTPException(status_code=500, detail="Failed to create default layout")

        # Fetch the created layout
        layout_id = rpc_result.data
        fetch_result = client.table("home_layouts").select("*").eq(
            "id", layout_id
        ).single().execute()

        if not fetch_result.data:
            raise HTTPException(status_code=500, detail="Failed to fetch created layout")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_created",
            endpoint="/api/v1/layouts/user/{user_id}/active",
            message="Default home layout created",
            metadata={"layout_id": layout_id},
            status_code=200
        )

        return row_to_layout_response(fetch_result.data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error fetching active layout for user {user_id}: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}", status_code=201)
async def create_layout(user_id: str, layout: CreateLayoutRequest) -> HomeLayoutResponse:
    """
    Create a new layout for a user.

    Args:
        user_id: User ID
        layout: Layout details

    Returns:
        Created layout
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Prepare tiles as JSON
        tiles_json = [tile.model_dump() for tile in layout.tiles]

        # Insert layout
        insert_result = client.table("home_layouts").insert({
            "user_id": user_id,
            "name": layout.name,
            "tiles": tiles_json,
            "template_id": layout.template_id,
            "is_active": False,
        }).execute()

        if not insert_result.data:
            raise HTTPException(status_code=500, detail="Failed to create layout")

        created_layout = insert_result.data[0]
        logger.info(f"Created layout {created_layout['id']} for user {user_id}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_created",
            endpoint="/api/v1/layouts/user/{user_id}",
            message=f"Created layout: {layout.name}",
            metadata={
                "layout_id": created_layout['id'],
                "name": layout.name,
                "tile_count": len(layout.tiles),
            },
            status_code=201
        )

        return row_to_layout_response(created_layout)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating layout for user {user_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="layout_created",
            error=e,
            endpoint="/api/v1/layouts/user/{user_id}",
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.put("/{layout_id}")
async def update_layout(
    layout_id: str,
    layout: UpdateLayoutRequest,
    user_id: str
) -> HomeLayoutResponse:
    """
    Update an existing layout.

    Args:
        layout_id: Layout ID
        layout: Update data
        user_id: User ID (for authorization)

    Returns:
        Updated layout
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Verify ownership
        existing = client.table("home_layouts").select("user_id").eq(
            "id", layout_id
        ).single().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Layout not found")

        if existing.data["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to update this layout")

        # Build update data
        update_data = {"updated_at": datetime.utcnow().isoformat()}
        if layout.name is not None:
            update_data["name"] = layout.name
        if layout.tiles is not None:
            update_data["tiles"] = [tile.model_dump() for tile in layout.tiles]

        # Update layout
        update_result = client.table("home_layouts").update(update_data).eq(
            "id", layout_id
        ).execute()

        if not update_result.data:
            raise HTTPException(status_code=500, detail="Failed to update layout")

        updated_layout = update_result.data[0]
        logger.info(f"Updated layout {layout_id}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_updated",
            endpoint=f"/api/v1/layouts/{layout_id}",
            message=f"Updated layout: {updated_layout.get('name', '')}",
            metadata={
                "layout_id": layout_id,
                "fields_updated": list(update_data.keys()),
            },
            status_code=200
        )

        return row_to_layout_response(updated_layout)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error updating layout {layout_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="layout_updated",
            error=e,
            endpoint=f"/api/v1/layouts/{layout_id}",
            metadata={"layout_id": layout_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.delete("/{layout_id}")
async def delete_layout(layout_id: str, user_id: str):
    """
    Delete a layout.

    Args:
        layout_id: Layout ID
        user_id: User ID (for authorization)

    Returns:
        Success message
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Verify ownership
        existing = client.table("home_layouts").select("user_id, is_active").eq(
            "id", layout_id
        ).single().execute()

        if not existing.data:
            raise HTTPException(status_code=404, detail="Layout not found")

        if existing.data["user_id"] != user_id:
            raise HTTPException(status_code=403, detail="Not authorized to delete this layout")

        # Prevent deleting active layout if it's the only one
        if existing.data["is_active"]:
            count_result = client.table("home_layouts").select(
                "id", count="exact"
            ).eq("user_id", user_id).execute()

            if count_result.count and count_result.count <= 1:
                raise HTTPException(
                    status_code=400,
                    detail="Cannot delete the only layout. Create another layout first."
                )

        # Delete layout
        client.table("home_layouts").delete().eq("id", layout_id).execute()
        logger.info(f"Deleted layout {layout_id}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_deleted",
            endpoint=f"/api/v1/layouts/{layout_id}",
            message="Deleted home layout",
            metadata={"layout_id": layout_id},
            status_code=200
        )

        return {"message": "Layout deleted successfully"}

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error deleting layout {layout_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="layout_deleted",
            error=e,
            endpoint=f"/api/v1/layouts/{layout_id}",
            metadata={"layout_id": layout_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/{layout_id}/activate")
async def activate_layout(layout_id: str, user_id: str) -> HomeLayoutResponse:
    """
    Activate a layout (deactivates all others).

    Args:
        layout_id: Layout ID
        user_id: User ID

    Returns:
        Activated layout
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Use the helper function
        rpc_result = client.rpc("activate_home_layout", {
            "p_user_id": user_id,
            "p_layout_id": layout_id
        }).execute()

        if not rpc_result.data:
            raise HTTPException(status_code=404, detail="Layout not found or not authorized")

        # Fetch the activated layout
        result = client.table("home_layouts").select("*").eq(
            "id", layout_id
        ).single().execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to fetch activated layout")

        logger.info(f"Activated layout {layout_id} for user {user_id}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_activated",
            endpoint=f"/api/v1/layouts/{layout_id}/activate",
            message=f"Activated layout: {result.data.get('name', '')}",
            metadata={"layout_id": layout_id},
            status_code=200
        )

        return row_to_layout_response(result.data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error activating layout {layout_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="layout_activated",
            error=e,
            endpoint=f"/api/v1/layouts/{layout_id}/activate",
            metadata={"layout_id": layout_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/user/{user_id}/from-template/{template_id}", status_code=201)
async def create_from_template(
    user_id: str,
    template_id: str,
    name: Optional[str] = None
) -> HomeLayoutResponse:
    """
    Create a new layout from a template.

    Args:
        user_id: User ID
        template_id: Template ID
        name: Optional custom name for the layout

    Returns:
        Created layout
    """
    try:
        db = get_supabase_db()
        client = db.client

        # Use the helper function
        rpc_result = client.rpc("create_layout_from_template", {
            "p_user_id": user_id,
            "p_template_id": template_id,
            "p_layout_name": name
        }).execute()

        if not rpc_result.data:
            raise HTTPException(status_code=404, detail="Template not found")

        layout_id = rpc_result.data

        # Fetch the created layout
        result = client.table("home_layouts").select("*").eq(
            "id", layout_id
        ).single().execute()

        if not result.data:
            raise HTTPException(status_code=500, detail="Failed to fetch created layout")

        logger.info(f"Created layout from template {template_id} for user {user_id}")

        # Log activity
        await log_user_activity(
            user_id=user_id,
            action="layout_from_template",
            endpoint=f"/api/v1/layouts/user/{user_id}/from-template/{template_id}",
            message=f"Created layout from template: {result.data.get('name', '')}",
            metadata={
                "layout_id": layout_id,
                "template_id": template_id,
            },
            status_code=201
        )

        return row_to_layout_response(result.data)

    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error creating layout from template {template_id}: {e}")
        await log_user_error(
            user_id=user_id,
            action="layout_from_template",
            error=e,
            endpoint=f"/api/v1/layouts/user/{user_id}/from-template/{template_id}",
            metadata={"template_id": template_id},
            status_code=500
        )
        raise HTTPException(status_code=500, detail=str(e))
