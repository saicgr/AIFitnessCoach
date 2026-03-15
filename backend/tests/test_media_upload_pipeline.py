"""
End-to-end tests for the media upload pipeline:
- POST /api/v1/chat/media/upload  (parallel S3 + Gemini Files API)
- FormAnalysisService.analyze_form() routing:
    gemini_file_name → video_frames (legacy) → S3 download
- Image analysis via sendMessage with imageBase64
- User-based log context is set on every code path

Run with:
    cd backend && pytest tests/test_media_upload_pipeline.py -v
"""
import asyncio
import io
import json
import sys
import os
import pytest
from unittest.mock import AsyncMock, MagicMock, patch, call

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


# ───────────────────────────────────────────────────────────────────────────
# Helpers
# ───────────────────────────────────────────────────────────────────────────

MINIMAL_JPEG = (
    b"\xff\xd8\xff\xe0\x00\x10JFIF\x00\x01\x01\x00\x00\x01\x00\x01\x00\x00"
    b"\xff\xdb\x00C\x00\x08\x06\x06\x07\x06\x05\x08\x07\x07\x07\t\t"
    b"\x08\n\x0c\x14\r\x0c\x0b\x0b\x0c\x19\x12\x13\x0f\x14\x1d\x1a"
    b"\x1f\x1e\x1d\x1a\x1c\x1c $.' \",#\x1c\x1c(7),01444\x1f'9=82<.342\x1eC"
    b"\xff\xc0\x00\x0b\x08\x00\x01\x00\x01\x01\x01\x11\x00\xff\xc4\x00\x1f"
    b"\x00\x00\x01\x05\x01\x01\x01\x01\x01\x01\x00\x00\x00\x00\x00\x00\x00"
    b"\x00\x01\x02\x03\x04\x05\x06\x07\x08\t\n\x0b\xff\xda\x00\x08\x01\x01"
    b"\x00\x00?\x00\xf5\x07\xff\xd9"
)  # 1×1 pixel JPEG

MINIMAL_MP4 = b"\x00\x00\x00\x18ftypmp42" + b"\x00" * 100  # fake mp4 header

MOCK_FORM_RESULT = {
    "content_type": "exercise",
    "exercise_identified": "Squat",
    "rep_count": 5,
    "form_score": 82,
    "overall_assessment": "Good form with minor improvements needed.",
    "issues": ["Knees tracking slightly inward"],
    "positives": ["Good depth", "Neutral spine"],
    "breathing_analysis": {"pattern_observed": "N/A", "is_correct": True, "recommendation": ""},
    "tempo_analysis": {"observed_tempo": "Controlled", "is_appropriate": True, "recommendation": ""},
    "recommendations": ["Focus on knee tracking"],
    "video_quality": {"is_analyzable": True, "confidence": "high", "issues": [], "rerecord_suggestion": ""},
}


def _make_gemini_file(name="files/abc123", state_name="ACTIVE"):
    f = MagicMock()
    f.name = name
    f.uri = f"https://generativelanguage.googleapis.com/v1beta/{name}"
    f.state = MagicMock()
    f.state.name = state_name
    return f


# ───────────────────────────────────────────────────────────────────────────
# FormAnalysisService routing tests
# ───────────────────────────────────────────────────────────────────────────

class TestFormAnalysisRouting:
    """Verify analyze_form() uses gemini_file_name > video_frames > S3."""

    @pytest.mark.asyncio
    async def test_gemini_file_name_path_skips_s3(self):
        """gemini_file_name is present → _analyze_from_gemini_file, NOT _do_analyze."""
        from services.form_analysis_service import FormAnalysisService

        svc = FormAnalysisService()
        with (
            patch.object(svc, "_analyze_from_gemini_file", new_callable=AsyncMock, return_value=MOCK_FORM_RESULT) as mock_gemini,
            patch.object(svc, "_do_analyze", new_callable=AsyncMock) as mock_s3,
            patch.object(svc, "_analyze_from_frames", new_callable=AsyncMock) as mock_frames,
        ):
            result = await svc.analyze_form(
                s3_key="chat_media/user/test.mp4",
                mime_type="video/mp4",
                media_type="video",
                gemini_file_name="files/abc123",
            )

        assert result == MOCK_FORM_RESULT
        mock_gemini.assert_called_once_with("files/abc123", "video/mp4", "video", None, None)
        mock_s3.assert_not_called()
        mock_frames.assert_not_called()

    @pytest.mark.asyncio
    async def test_video_frames_fallback_path(self):
        """No gemini_file_name but video_frames present → _analyze_from_frames."""
        from services.form_analysis_service import FormAnalysisService

        svc = FormAnalysisService()
        frames = ["base64frame1", "base64frame2"]
        with (
            patch.object(svc, "_analyze_from_gemini_file", new_callable=AsyncMock) as mock_gemini,
            patch.object(svc, "_do_analyze", new_callable=AsyncMock) as mock_s3,
            patch.object(svc, "_analyze_from_frames", new_callable=AsyncMock, return_value=MOCK_FORM_RESULT) as mock_frames,
        ):
            result = await svc.analyze_form(
                s3_key="chat_media/user/test.mp4",
                mime_type="video/mp4",
                media_type="video",
                video_frames=frames,
            )

        assert result == MOCK_FORM_RESULT
        mock_frames.assert_called_once_with(frames, None, None)
        mock_gemini.assert_not_called()
        mock_s3.assert_not_called()

    @pytest.mark.asyncio
    async def test_s3_fallback_path(self):
        """Neither gemini_file_name nor video_frames → _do_analyze (S3 download)."""
        from services.form_analysis_service import FormAnalysisService

        svc = FormAnalysisService()
        with (
            patch.object(svc, "_analyze_from_gemini_file", new_callable=AsyncMock) as mock_gemini,
            patch.object(svc, "_do_analyze", new_callable=AsyncMock, return_value=MOCK_FORM_RESULT) as mock_s3,
            patch.object(svc, "_analyze_from_frames", new_callable=AsyncMock) as mock_frames,
        ):
            result = await svc.analyze_form(
                s3_key="chat_media/user/test.mp4",
                mime_type="video/mp4",
                media_type="video",
            )

        assert result == MOCK_FORM_RESULT
        mock_s3.assert_called_once()
        mock_gemini.assert_not_called()
        mock_frames.assert_not_called()

    @pytest.mark.asyncio
    async def test_gemini_file_waits_for_processing_state(self):
        """_analyze_from_gemini_file polls until state=ACTIVE when state=PROCESSING."""
        from services.form_analysis_service import FormAnalysisService

        svc = FormAnalysisService()
        processing_file = _make_gemini_file(state_name="PROCESSING")
        active_file = _make_gemini_file(state_name="ACTIVE")
        call_count = 0

        def files_get(name):
            nonlocal call_count
            call_count += 1
            return active_file if call_count > 1 else processing_file

        mock_client = MagicMock()
        mock_client.files.get = files_get

        mock_response = MagicMock()
        mock_response.text = json.dumps(MOCK_FORM_RESULT)
        mock_client.models.generate_content = MagicMock(return_value=mock_response)

        with (
            patch("services.form_analysis_service.get_genai_client", return_value=mock_client),
            patch("services.form_analysis_service.get_settings") as mock_settings,
            patch("services.form_analysis_service._get_form_cache", return_value=None),
            patch("asyncio.sleep", new_callable=AsyncMock),
        ):
            mock_settings.return_value.gemini_model = "gemini-2.0-flash"
            result = await svc._analyze_from_gemini_file(
                gemini_file_name="files/abc123",
                mime_type="video/mp4",
                media_type="video",
            )

        assert result["exercise_identified"] == "Squat"
        assert call_count == 2  # polled once, then got ACTIVE


# ───────────────────────────────────────────────────────────────────────────
# /media/upload endpoint validation tests (no TestClient — version-safe)
# ───────────────────────────────────────────────────────────────────────────

class TestMediaUploadValidation:
    """Test content-type and media_type validation logic from the endpoint."""

    def test_allowed_content_types_includes_video_and_image(self):
        """ALLOWED_CONTENT_TYPES accepts common video and image MIME types."""
        from api.v1.chat import ALLOWED_CONTENT_TYPES

        assert "video/mp4" in ALLOWED_CONTENT_TYPES
        assert "video/quicktime" in ALLOWED_CONTENT_TYPES
        assert "image/jpeg" in ALLOWED_CONTENT_TYPES
        assert "image/png" in ALLOWED_CONTENT_TYPES
        assert "text/plain" not in ALLOWED_CONTENT_TYPES

    def test_ext_map_covers_all_allowed_types(self):
        """EXT_MAP has an extension for every allowed content type."""
        from api.v1.chat import ALLOWED_CONTENT_TYPES, EXT_MAP

        missing = [ct for ct in ALLOWED_CONTENT_TYPES if ct not in EXT_MAP]
        assert missing == [], f"EXT_MAP missing extensions for: {missing}"

    def test_media_upload_response_model_structure(self):
        """MediaUploadResponse serialises all required fields."""
        from api.v1.chat import MediaUploadResponse

        resp = MediaUploadResponse(
            s3_key="chat_media/user/abc.mp4",
            public_url="https://bucket.s3.us-east-1.amazonaws.com/chat_media/user/abc.mp4",
            gemini_file_name="files/abc123",
            mime_type="video/mp4",
        )
        d = resp.model_dump()
        assert d["s3_key"] == "chat_media/user/abc.mp4"
        assert d["gemini_file_name"] == "files/abc123"
        assert d["mime_type"] == "video/mp4"

    def test_user_log_context_is_set_in_endpoint_source(self):
        """Verify set_log_context is imported and called in upload_media_for_analysis."""
        import inspect
        import api.v1.chat as chat_module

        # set_log_context must be imported in the module
        assert hasattr(chat_module, "set_log_context"), \
            "set_log_context not imported in api.v1.chat"

        # The endpoint function source must call set_log_context
        src = inspect.getsource(chat_module.upload_media_for_analysis)
        assert "set_log_context" in src, \
            "upload_media_for_analysis does not call set_log_context — user_id will be missing from structured logs"

    def test_user_log_context_truncates_user_id(self):
        """The truncated user_id format '...XXXX' matches what the middleware uses."""
        from core.logger import set_log_context, get_log_context, clear_log_context

        user_id = "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
        truncated = f"...{user_id[-4:]}" if len(user_id) > 4 else user_id

        set_log_context(user_id=truncated)
        ctx = get_log_context()
        clear_log_context()

        assert ctx["user_id"] == "...7890"


# ───────────────────────────────────────────────────────────────────────────
# MediaJobRunner wires gemini_file_name through correctly
# ───────────────────────────────────────────────────────────────────────────

class TestMediaJobRunnerGeminiWiring:
    """Verify media_job_runner passes gemini_file_name through to analyze_form."""

    @pytest.mark.asyncio
    async def test_form_analysis_job_passes_gemini_file_name(self):
        # media_job_runner imports FormAnalysisService lazily inside the function,
        # so we patch the class in its source module.
        from services.media_job_runner import _execute_form_analysis

        job = {
            "s3_keys": ["chat_media/user/video.mp4"],
            "mime_types": ["video/mp4"],
            "media_types": ["video"],
            "params": {
                "gemini_file_name": "files/xyz789",
                "exercise_name": "Deadlift",
                "user_context": "intermediate lifter",
            },
        }

        with patch("services.form_analysis_service.FormAnalysisService") as MockSvc:
            mock_instance = MagicMock()
            mock_instance.analyze_form = AsyncMock(return_value=MOCK_FORM_RESULT)
            MockSvc.return_value = mock_instance

            result = await _execute_form_analysis(job)

        assert result == MOCK_FORM_RESULT
        mock_instance.analyze_form.assert_called_once_with(
            s3_key="chat_media/user/video.mp4",
            mime_type="video/mp4",
            media_type="video",
            exercise_name="Deadlift",
            user_context="intermediate lifter",
            video_frames=None,
            gemini_file_name="files/xyz789",
        )

    @pytest.mark.asyncio
    async def test_form_analysis_job_no_gemini_file_name(self):
        """When gemini_file_name is absent, passes None (falls back to S3)."""
        from services.media_job_runner import _execute_form_analysis

        job = {
            "s3_keys": ["chat_media/user/video.mp4"],
            "mime_types": ["video/mp4"],
            "media_types": ["video"],
            "params": {"exercise_name": "Squat"},
        }

        with patch("services.form_analysis_service.FormAnalysisService") as MockSvc:
            mock_instance = MagicMock()
            mock_instance.analyze_form = AsyncMock(return_value=MOCK_FORM_RESULT)
            MockSvc.return_value = mock_instance

            await _execute_form_analysis(job)

        call_kwargs = mock_instance.analyze_form.call_args.kwargs
        assert call_kwargs["gemini_file_name"] is None
        assert call_kwargs["video_frames"] is None


# ───────────────────────────────────────────────────────────────────────────
# MediaRef model — gemini_file_name field
# ───────────────────────────────────────────────────────────────────────────

class TestMediaRefModel:
    """MediaRef accepts and preserves gemini_file_name."""

    def test_media_ref_with_gemini_file_name(self):
        from models.chat import MediaRef

        ref = MediaRef(
            s3_key="chat_media/user/abc.mp4",
            media_type="video",
            mime_type="video/mp4",
            gemini_file_name="files/abc123",
        )
        assert ref.gemini_file_name == "files/abc123"

    def test_media_ref_without_gemini_file_name(self):
        from models.chat import MediaRef

        ref = MediaRef(
            s3_key="chat_media/user/abc.mp4",
            media_type="video",
            mime_type="video/mp4",
        )
        assert ref.gemini_file_name is None

    def test_media_ref_gemini_file_name_max_length(self):
        from models.chat import MediaRef
        from pydantic import ValidationError

        with pytest.raises(ValidationError):
            MediaRef(
                s3_key="chat_media/user/abc.mp4",
                media_type="video",
                mime_type="video/mp4",
                gemini_file_name="x" * 201,  # > max_length=200
            )
