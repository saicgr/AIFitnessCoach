"""
Data export and import endpoints.
"""
import io
from datetime import datetime
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from core.auth import get_current_user, verify_user_ownership
from core.exceptions import safe_internal_error
from fastapi.responses import StreamingResponse
from typing import Optional

from core.supabase_db import get_supabase_db
from core.logger import get_logger

router = APIRouter()
logger = get_logger(__name__)


@router.get("/{user_id}/export")
async def export_user_data(
    user_id: str,
    format: str = "csv",
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Export all user data in the specified format.

    Query parameters:
    - format: Export format - "csv" (ZIP of CSVs), "json", "xlsx", or "parquet" (ZIP of Parquet files). Default: "csv"
    - start_date: Optional ISO date string (YYYY-MM-DD) for filtering data from this date
    - end_date: Optional ISO date string (YYYY-MM-DD) for filtering data until this date
    """
    import time
    start_time = time.time()
    logger.info(f"Starting data export for user: id={user_id}, format={format}, date_range={start_date} to {end_date}")

    if format not in ("csv", "json", "xlsx", "parquet"):
        raise HTTPException(status_code=400, detail=f"Unsupported export format: {format}. Use csv, json, xlsx, or parquet.")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for export: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.info(f"User verified, generating {format} export...")

        date_str = datetime.utcnow().strftime("%Y-%m-%d")

        if format == "json":
            from services.data_export import export_user_data_json
            data = export_user_data_json(user_id, start_date=start_date, end_date=end_date)
            from fastapi.responses import JSONResponse
            elapsed = time.time() - start_time
            logger.info(f"JSON export complete for user {user_id} in {elapsed:.2f}s")
            return JSONResponse(
                content=data,
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.json"',
                }
            )

        elif format == "xlsx":
            from services.data_export import export_user_data_excel
            xlsx_bytes = export_user_data_excel(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"Excel export complete for user {user_id} in {elapsed:.2f}s, size: {len(xlsx_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(xlsx_bytes),
                media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.xlsx"',
                    "Content-Length": str(len(xlsx_bytes)),
                }
            )

        elif format == "parquet":
            from services.data_export import export_user_data_parquet
            parquet_bytes = export_user_data_parquet(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"Parquet export complete for user {user_id} in {elapsed:.2f}s, size: {len(parquet_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(parquet_bytes),
                media_type="application/octet-stream",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.zip"',
                    "Content-Length": str(len(parquet_bytes)),
                }
            )

        else:
            # Default: CSV ZIP
            from services.data_export import export_user_data as do_export
            zip_bytes = do_export(user_id, start_date=start_date, end_date=end_date)
            elapsed = time.time() - start_time
            logger.info(f"CSV export complete for user {user_id} in {elapsed:.2f}s, size: {len(zip_bytes)} bytes")
            return StreamingResponse(
                io.BytesIO(zip_bytes),
                media_type="application/zip",
                headers={
                    "Content-Disposition": f'attachment; filename="fitness_data_{date_str}.zip"',
                    "Content-Length": str(len(zip_bytes)),
                }
            )

    except HTTPException:
        raise
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"Failed to export user data after {elapsed:.2f}s: {e}")
        raise safe_internal_error(e, "users")


@router.get("/{user_id}/export-text")
async def export_user_data_text(
    user_id: str,
    start_date: Optional[str] = None,
    end_date: Optional[str] = None,
    current_user: dict = Depends(get_current_user),
):
    """
    Export workout logs as a plain text file.

    Query parameters:
    - start_date: Optional ISO date string (YYYY-MM-DD) for filtering data from this date
    - end_date: Optional ISO date string (YYYY-MM-DD) for filtering data until this date

    Returns a formatted plain text file with workout history including:
    - Workout name, date, duration
    - Each exercise with sets, reps, weight, RPE
    - Notes if present
    - Calculated totals (total sets, total reps, total volume)
    """
    import time
    start_time = time.time()
    logger.info(f"Starting text export for user: id={user_id}, date_range={start_date} to {end_date}")

    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for text export: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        logger.info(f"User verified, generating text export...")

        # Import here to avoid circular imports
        from services.data_export import export_workout_logs_text

        # Generate text content with date filters
        text_content = export_workout_logs_text(user_id, start_date=start_date, end_date=end_date)

        # Create filename with date
        date_str = datetime.utcnow().strftime("%Y-%m-%d")
        filename = f"workout_log_{date_str}.txt"

        elapsed = time.time() - start_time
        logger.info(f"Text export complete for user {user_id} in {elapsed:.2f}s, size: {len(text_content)} chars")

        # Return as plain text response
        from fastapi.responses import Response
        return Response(
            content=text_content,
            media_type="text/plain; charset=utf-8",
            headers={
                "Content-Disposition": f'attachment; filename="{filename}"',
                "Content-Length": str(len(text_content.encode('utf-8'))),
            }
        )

    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Text export validation error: {e}")
        raise HTTPException(status_code=404, detail="Export failed")
    except Exception as e:
        elapsed = time.time() - start_time
        logger.error(f"Failed to export user data as text after {elapsed:.2f}s: {e}")
        raise safe_internal_error(e, "users")


@router.post("/{user_id}/import")
async def import_user_data(user_id: str, file: UploadFile = File(...),
    current_user: dict = Depends(get_current_user),
):
    """
    Import user data from a previously exported ZIP file.

    This will:
    1. Validate the ZIP structure and metadata
    2. Parse all CSV files
    3. Import data with new IDs (preserving relationships)
    4. Update user profile with imported settings

    WARNING: This may replace existing data. Use with caution.
    """
    logger.info(f"Importing data for user: id={user_id}, filename={file.filename}")
    try:
        verify_user_ownership(current_user, user_id)
        db = get_supabase_db()

        # Check if user exists
        existing = db.get_user(user_id)
        if not existing:
            logger.warning(f"User not found for import: id={user_id}")
            raise HTTPException(status_code=404, detail="User not found")

        # Validate file type
        if not file.filename.endswith('.zip'):
            raise HTTPException(status_code=400, detail="File must be a ZIP archive")

        # Read file content
        content = await file.read()
        if len(content) > 50 * 1024 * 1024:  # 50MB limit
            raise HTTPException(status_code=400, detail="File too large. Maximum size is 50MB.")

        # Import here to avoid circular imports
        from services.data_import import import_user_data as do_import

        # Perform import
        result = do_import(user_id, content)

        logger.info(f"Data import complete for user {user_id}: {result}")

        return {
            "message": "Data import successful",
            "user_id": user_id,
            "imported": result
        }

    except HTTPException:
        raise
    except ValueError as e:
        logger.error(f"Import validation error: {e}")
        raise HTTPException(status_code=400, detail="Import failed")
    except Exception as e:
        logger.error(f"Failed to import user data: {e}")
        raise safe_internal_error(e, "users")
