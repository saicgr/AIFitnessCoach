"""
Form analysis service using Gemini Vision.

Supports two video analysis paths:
  1. Key frame extraction (default for long videos / multi-video comparison)
     - Extracts JPEG frames via FFmpeg, sends as image parts
     - Eliminates Gemini Files API upload/polling latency
     - ~50% token savings vs full video
  2. Gemini Files API (fallback for short videos / when keyframes disabled)

Also integrates Gemini context caching for form analysis prompts.

Supports:
- Single video/image form analysis
- Multi-video form comparison (e.g., comparing sets or sessions)
"""

import asyncio
import json
import os
import tempfile
import time
import uuid
from typing import Any, Dict, List, Optional

import boto3
from google.genai import types as genai_types

from core.config import get_settings
from core.gemini_client import get_genai_client
from core.logger import get_logger

logger = get_logger(__name__)

# Concurrency limit for simultaneous analyses
_semaphore = asyncio.Semaphore(10)

# Structured JSON schema for form analysis output
FORM_ANALYSIS_SCHEMA = {
    "type": "object",
    "properties": {
        "content_type": {
            "type": "string",
            "enum": ["exercise", "not_exercise"],
            "description": "Whether this video/image shows someone performing an exercise. Set to 'not_exercise' if the content is unrelated to fitness (e.g., cooking, gaming, scenery, text/screenshots, no person visible, etc.)"
        },
        "not_exercise_reason": {
            "type": "string",
            "description": "If content_type is 'not_exercise', a brief friendly explanation of what was seen instead (e.g., 'This looks like a cooking video', 'I can see a screenshot of text', 'No person is visible in this video'). Empty string if content_type is 'exercise'."
        },
        "exercise_identified": {
            "type": "string",
            "description": "The exercise being performed (e.g., 'Barbell Back Squat'). Set to 'N/A' if content_type is 'not_exercise'."
        },
        "rep_count": {
            "type": "integer",
            "description": "Estimated number of complete repetitions observed. Count carefully from first to last frame."
        },
        "form_score": {
            "type": "integer",
            "description": "Overall form score from 1 (dangerous) to 10 (perfect)",
            "minimum": 1,
            "maximum": 10
        },
        "overall_assessment": {
            "type": "string",
            "description": "Brief overall assessment of the form (1-2 sentences)"
        },
        "issues": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "body_part": {
                        "type": "string",
                        "description": "Body part affected (e.g., 'knees', 'lower back', 'shoulders')"
                    },
                    "severity": {
                        "type": "string",
                        "enum": ["minor", "moderate", "critical"],
                        "description": "How serious the form issue is"
                    },
                    "description": {
                        "type": "string",
                        "description": "What the issue is"
                    },
                    "correction": {
                        "type": "string",
                        "description": "How to fix the issue"
                    },
                    "timestamp_seconds": {
                        "type": "number",
                        "description": "Approximate timestamp in the video where the issue is visible (null for images)"
                    }
                },
                "required": ["body_part", "severity", "description", "correction"]
            },
            "description": "List of form issues found"
        },
        "positives": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Things the user is doing well"
        },
        "breathing_analysis": {
            "type": "object",
            "properties": {
                "pattern_observed": {
                    "type": "string",
                    "description": "Describe the breathing pattern observed (e.g., 'exhaling on exertion', 'holding breath', 'shallow breathing', 'not observable')"
                },
                "is_correct": {
                    "type": "boolean",
                    "description": "Whether the breathing pattern is correct for this exercise"
                },
                "recommendation": {
                    "type": "string",
                    "description": "Specific breathing advice for this exercise (e.g., 'Exhale during the push phase, inhale during the lowering phase')"
                }
            },
            "required": ["pattern_observed", "is_correct", "recommendation"],
            "description": "Analysis of breathing technique during the exercise"
        },
        "tempo_analysis": {
            "type": "object",
            "properties": {
                "observed_tempo": {
                    "type": "string",
                    "description": "The observed rep tempo (e.g., '2s up, 1s pause, 3s down' or 'too fast to count')"
                },
                "is_appropriate": {
                    "type": "boolean",
                    "description": "Whether the tempo is appropriate for the exercise"
                },
                "recommendation": {
                    "type": "string",
                    "description": "Tempo advice if needed"
                }
            },
            "required": ["observed_tempo", "is_appropriate", "recommendation"],
            "description": "Analysis of rep speed and tempo control"
        },
        "recommendations": {
            "type": "array",
            "items": {"type": "string"},
            "description": "Actionable tips to improve form"
        },
        "video_quality": {
            "type": "object",
            "properties": {
                "is_analyzable": {
                    "type": "boolean",
                    "description": "Whether the video/image quality is sufficient for a reliable form analysis"
                },
                "confidence": {
                    "type": "string",
                    "enum": ["high", "medium", "low"],
                    "description": "How confident the analysis is given the recording quality"
                },
                "issues": {
                    "type": "array",
                    "items": {"type": "string"},
                    "description": "List of recording quality issues"
                },
                "rerecord_suggestion": {
                    "type": "string",
                    "description": "A gentle one-time tip for next time. Empty string if recording quality is fine."
                }
            },
            "required": ["is_analyzable", "confidence", "issues", "rerecord_suggestion"],
            "description": "Assessment of the recording quality"
        }
    },
    "required": ["content_type", "exercise_identified", "form_score", "overall_assessment", "issues", "positives", "breathing_analysis", "tempo_analysis", "recommendations", "video_quality"]
}

# Structured JSON schema for multi-video form comparison
FORM_COMPARISON_SCHEMA = {
    "type": "object",
    "properties": {
        "videos": {
            "type": "array",
            "items": {
                "type": "object",
                "properties": {
                    "label": {"type": "string"},
                    "exercise": {"type": "string"},
                    "form_score": {"type": "integer", "minimum": 1, "maximum": 10},
                    "rep_count": {"type": "integer"},
                    "key_observations": {"type": "array", "items": {"type": "string"}}
                },
                "required": ["label", "exercise", "form_score", "rep_count", "key_observations"]
            }
        },
        "comparison": {
            "type": "object",
            "properties": {
                "improved": {"type": "array", "items": {"type": "string"}},
                "regressed": {"type": "array", "items": {"type": "string"}},
                "consistent": {"type": "array", "items": {"type": "string"}},
                "overall_trend": {"type": "string"}
            },
            "required": ["improved", "regressed", "consistent", "overall_trend"]
        },
        "recommendations": {"type": "array", "items": {"type": "string"}}
    },
    "required": ["videos", "comparison", "recommendations"]
}


def _build_form_analysis_prompt(
    exercise_name: Optional[str],
    user_context: Optional[str],
    using_keyframes: bool = False,
) -> str:
    """Build the dynamic per-request prompt for form analysis."""
    exercise_hint = f'The user says they are performing: "{exercise_name}". ' if exercise_name else ""
    context_hint = f"\nAdditional context: {user_context}" if user_context else ""
    keyframe_note = (
        "\nNote: These are key frames extracted from the video at regular intervals. "
        "Analyze the progression across frames to assess form throughout the movement."
    ) if using_keyframes else ""

    return f"""{exercise_hint}Identify the exercise being performed and score the form from 1 (dangerous/high injury risk) to 10 (textbook perfect form).
{keyframe_note}
{context_hint}

Respond with valid JSON matching the required schema."""


def _build_form_analysis_prompt_full(
    exercise_name: Optional[str],
    user_context: Optional[str],
    using_keyframes: bool = False,
) -> str:
    """Build the full prompt for form analysis (used when cache is unavailable)."""
    exercise_hint = f'The user says they are performing: "{exercise_name}". ' if exercise_name else ""
    context_hint = f"\nAdditional context: {user_context}" if user_context else ""
    keyframe_note = (
        "\nNote: These are key frames extracted from the video at regular intervals. "
        "Analyze the progression across frames to assess form throughout the movement."
    ) if using_keyframes else ""

    return f"""You are an expert exercise form analyst, certified personal trainer, and movement specialist.
This is a fitness app. Users send videos/images for exercise form analysis.

FIRST: Determine if this video/image actually shows someone performing an exercise.

If it does NOT show exercise (e.g., cooking, gaming, scenery, animals, text/screenshots, no person, unrelated content):
- Set content_type to "not_exercise"
- Set not_exercise_reason to a brief, friendly description of what you see instead
- Set exercise_identified to "N/A", form_score to 1, rep_count to 0
- Leave all other arrays empty and analysis objects with default values
- Do NOT lecture or shame the user

If it DOES show exercise, set content_type to "exercise" and not_exercise_reason to "" and proceed with full analysis:

{exercise_hint}Identify the exercise being performed and score the form from 1 (dangerous/high injury risk) to 10 (textbook perfect form).
{keyframe_note}

REP COUNTING INSTRUCTIONS (CRITICAL - be precise):
- Watch the ENTIRE video from the very first frame to the very last frame
- A rep = one complete movement cycle (e.g., for push-ups: start position -> down -> back up to start)
- Count each rep as it completes (the person returns to starting position)
- Include partial reps at the end only if they complete at least 50% of the range of motion
- Double-check your count before reporting

ANALYZE THESE ASPECTS:

1. **Form Issues**: For each form issue found:
   - Identify the body part affected
   - Rate severity as minor, moderate, or critical
   - Describe what is wrong
   - Provide a specific, actionable correction
   - Note the approximate timestamp (for videos)

2. **Breathing**: Analyze the breathing pattern

3. **Tempo & Speed**: Analyze the rep speed

4. **Positives**: Highlight what the user is doing well

5. **Recommendations**: Provide actionable tips to improve

6. **Video/Image Quality Assessment**:
   - ALWAYS give your BEST possible analysis regardless of video quality
   - NEVER ask or demand the user to re-record
   - Default to "high" confidence
{context_hint}

Respond with valid JSON matching the required schema."""


def _build_form_comparison_prompt(
    labels: List[str],
    exercise_name: Optional[str],
    user_context: Optional[str],
    using_keyframes: bool = False,
) -> str:
    """Build the prompt for multi-video form comparison."""
    exercise_hint = f'The exercise being performed is: "{exercise_name}". ' if exercise_name else ""
    context_hint = f"\nAdditional context: {user_context}" if user_context else ""
    keyframe_note = (
        "\nNote: These are key frames extracted from each video at regular intervals. "
        "Analyze the progression across frames within and between videos."
    ) if using_keyframes else ""

    video_list = "\n".join([f"- Video {i+1} (labeled: '{label}')" for i, label in enumerate(labels)])

    return f"""You are an expert exercise form analyst comparing multiple videos of the same exercise.

{exercise_hint}The user has uploaded {len(labels)} videos for comparison:
{video_list}
{keyframe_note}

For each video:
1. Identify the exercise (should be the same across videos)
2. Score form from 1-10
3. Count reps precisely
4. Note key observations specific to that video

Then COMPARE across videos:
- **Improved**: What got better from earlier to later videos
- **Regressed**: What got worse (possibly due to fatigue)
- **Consistent**: What stayed the same
- **Overall Trend**: A summary sentence about the progression

Focus on:
- Form consistency as fatigue builds
- Whether the user maintains proper mechanics
- Any compensatory patterns that develop
- Range of motion changes
{context_hint}

Respond with valid JSON matching the required schema."""


def _get_form_cache() -> Optional[str]:
    """Get the form analysis cache name from GeminiService (if available)."""
    try:
        from services.gemini_service import GeminiService
        return GeminiService._form_analysis_cache
    except Exception:
        return None


class FormAnalysisService:
    """Service for analyzing exercise form from video/image media."""

    def __init__(self):
        settings = get_settings()
        self._s3_client = boto3.client(
            "s3",
            aws_access_key_id=settings.aws_access_key_id,
            aws_secret_access_key=settings.aws_secret_access_key,
            region_name=settings.aws_default_region,
        )
        self._bucket = settings.s3_bucket_name

    async def _download_s3_to_temp(self, s3_key: str, mime_type: str, prefix: str = "form_") -> str:
        """Download an S3 object to a temp file. Returns the temp file path."""
        ext = mime_type.split("/")[-1].replace("quicktime", "mov")
        fd, tmp_path = tempfile.mkstemp(suffix=f".{ext}", prefix=prefix)
        os.close(fd)

        logger.info(f"Downloading S3 object {s3_key} to {tmp_path}")
        s3_obj = await asyncio.to_thread(
            self._s3_client.get_object,
            Bucket=self._bucket,
            Key=s3_key,
        )

        with open(tmp_path, "wb") as f:
            body = s3_obj["Body"]
            while True:
                chunk = await asyncio.to_thread(body.read, 1024 * 1024)  # 1MB
                if not chunk:
                    break
                f.write(chunk)

        file_size = os.path.getsize(tmp_path)
        logger.info(f"Downloaded {file_size} bytes from S3 to temp file")
        return tmp_path

    async def analyze_form(
        self,
        s3_key: str,
        mime_type: str,
        media_type: str,
        exercise_name: Optional[str] = None,
        user_context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """
        Analyze exercise form from an S3-stored video or image.

        Uses keyframe extraction for long videos (>30s) to skip Gemini Files API.
        Falls back to Gemini Files API for short videos and images.
        """
        async with _semaphore:
            return await self._do_analyze(s3_key, mime_type, media_type, exercise_name, user_context)

    async def _do_analyze(
        self,
        s3_key: str,
        mime_type: str,
        media_type: str,
        exercise_name: Optional[str],
        user_context: Optional[str],
    ) -> Dict[str, Any]:
        """Internal analysis implementation with keyframe + cache support."""
        tmp_path = None
        gemini_file = None

        try:
            # Step 1: Download from S3
            tmp_path = await self._download_s3_to_temp(s3_key, mime_type)

            client = get_genai_client()
            settings = get_settings()

            # Step 2: Decide keyframe vs Gemini Files API path
            use_keyframes = False
            if media_type == "video":
                from services.keyframe_extractor import should_use_keyframes, get_video_duration, extract_key_frames

                try:
                    duration = await get_video_duration(tmp_path)
                    use_keyframes = should_use_keyframes(
                        media_type=media_type,
                        video_duration_hint=duration,
                    )
                except Exception as e:
                    logger.warning(f"Could not determine video duration, falling back to Files API: {e}")

            if use_keyframes:
                # Keyframe path: extract frames, send as image parts
                logger.info(f"Using keyframe extraction for {s3_key} (duration={duration:.1f}s)")
                frames = await extract_key_frames(tmp_path, num_frames=settings.keyframe_default_count)

                if not frames:
                    logger.warning("No keyframes extracted, falling back to Gemini Files API")
                    use_keyframes = False

            if use_keyframes:
                # Build parts from keyframes
                parts = []
                for i, (jpeg_bytes, frame_mime) in enumerate(frames):
                    parts.append(genai_types.Part.from_bytes(data=jpeg_bytes, mime_type=frame_mime))

                # Build prompt (dynamic per-request part only if cache available)
                cache_name = _get_form_cache()
                if cache_name:
                    prompt = _build_form_analysis_prompt(exercise_name, user_context, using_keyframes=True)
                else:
                    prompt = _build_form_analysis_prompt_full(exercise_name, user_context, using_keyframes=True)

                parts.append(genai_types.Part.from_text(text=prompt))

                gen_config = genai_types.GenerateContentConfig(
                    temperature=0.1,
                    response_mime_type="application/json",
                    response_schema=FORM_ANALYSIS_SCHEMA,
                )
                if cache_name:
                    gen_config.cached_content = cache_name

                response = await asyncio.to_thread(
                    client.models.generate_content,
                    model=settings.gemini_model,
                    contents=[genai_types.Content(parts=parts)],
                    config=gen_config,
                )
            else:
                # Gemini Files API path (original flow)
                logger.info(f"Uploading to Gemini Files API (mime_type={mime_type})")

                gemini_file = await asyncio.to_thread(
                    client.files.upload,
                    file=tmp_path,
                    config=genai_types.UploadFileConfig(
                        mime_type=mime_type,
                        display_name=f"form_analysis_{uuid.uuid4().hex[:8]}",
                    ),
                )

                logger.info(f"Gemini file created: {gemini_file.name}, state={gemini_file.state}")

                # Poll until ACTIVE (videos need processing)
                if media_type == "video":
                    start_poll = time.time()
                    timeout = 120  # 2 minutes max
                    while gemini_file.state.name == "PROCESSING":
                        elapsed = time.time() - start_poll
                        if elapsed > timeout:
                            raise TimeoutError(f"Gemini file processing timed out after {timeout}s")

                        logger.debug(f"Gemini file still processing ({elapsed:.0f}s elapsed)...")
                        await asyncio.sleep(2)
                        gemini_file = await asyncio.to_thread(
                            client.files.get,
                            name=gemini_file.name,
                        )

                    if gemini_file.state.name == "FAILED":
                        raise RuntimeError(f"Gemini file processing failed: {gemini_file.state}")

                logger.info(f"Gemini file ready: state={gemini_file.state.name}")

                # Build prompt
                cache_name = _get_form_cache()
                if cache_name:
                    prompt = _build_form_analysis_prompt(exercise_name, user_context)
                else:
                    prompt = _build_form_analysis_prompt_full(exercise_name, user_context)

                gen_config = genai_types.GenerateContentConfig(
                    temperature=0.1,
                    response_mime_type="application/json",
                    response_schema=FORM_ANALYSIS_SCHEMA,
                )
                if cache_name:
                    gen_config.cached_content = cache_name

                response = await asyncio.to_thread(
                    client.models.generate_content,
                    model=settings.gemini_model,
                    contents=[
                        genai_types.Content(
                            parts=[
                                genai_types.Part.from_uri(
                                    file_uri=gemini_file.uri,
                                    mime_type=mime_type,
                                ),
                                genai_types.Part.from_text(text=prompt),
                            ]
                        )
                    ],
                    config=gen_config,
                )

            # Parse the response
            response_text = None
            try:
                response_text = response.text
            except (ValueError, AttributeError) as e:
                logger.debug(f"Failed to get response text: {e}")

            # Check if Gemini blocked the content (safety filters)
            if not response_text:
                block_reason = "unknown"
                try:
                    if hasattr(response, "prompt_feedback") and response.prompt_feedback:
                        block_reason = str(response.prompt_feedback.block_reason or "safety_filter")
                    elif hasattr(response, "candidates") and response.candidates:
                        candidate = response.candidates[0]
                        if hasattr(candidate, "finish_reason"):
                            block_reason = str(candidate.finish_reason)
                except Exception as e:
                    logger.debug(f"Failed to get block reason: {e}")

                logger.warning(f"Gemini blocked form analysis response: {block_reason}")
                return {
                    "content_type": "not_exercise",
                    "not_exercise_reason": "I wasn't able to analyze this video. It may not contain exercise content, or the content couldn't be processed.",
                    "exercise_identified": "N/A",
                    "rep_count": 0,
                    "form_score": 0,
                    "overall_assessment": "",
                    "issues": [],
                    "positives": [],
                    "breathing_analysis": {"pattern_observed": "N/A", "is_correct": True, "recommendation": ""},
                    "tempo_analysis": {"observed_tempo": "N/A", "is_appropriate": True, "recommendation": ""},
                    "recommendations": [],
                    "video_quality": {"is_analyzable": False, "confidence": "low", "issues": [], "rerecord_suggestion": ""},
                }

            logger.info(f"Gemini form analysis response received ({len(response_text)} chars)")

            result = json.loads(response_text)

            # Ensure rep_count has a default
            if "rep_count" not in result:
                result["rep_count"] = 0

            return result

        except TimeoutError:
            logger.error(f"Form analysis timed out for {s3_key}")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse Gemini response as JSON: {e}")
            raise ValueError(f"Failed to parse form analysis response: {e}")
        except Exception as e:
            logger.error(f"Form analysis failed for {s3_key}: {e}", exc_info=True)
            raise

        finally:
            # Clean up temp file
            if tmp_path and os.path.exists(tmp_path):
                try:
                    os.unlink(tmp_path)
                    logger.debug(f"Cleaned up temp file: {tmp_path}")
                except OSError as e:
                    logger.warning(f"Failed to clean up temp file {tmp_path}: {e}")

            # Clean up Gemini file (best effort)
            if gemini_file and hasattr(gemini_file, "name"):
                try:
                    client = get_genai_client()
                    await asyncio.to_thread(client.files.delete, name=gemini_file.name)
                    logger.debug(f"Cleaned up Gemini file: {gemini_file.name}")
                except Exception as e:
                    logger.warning(f"Failed to clean up Gemini file: {e}")

    async def analyze_form_comparison(
        self,
        s3_keys: list[str],
        mime_types: list[str],
        labels: list[str],
        exercise_name: str | None = None,
        user_context: str | None = None,
    ) -> dict:
        """
        Compare exercise form across multiple videos.

        Always uses keyframe extraction path (multi-video is always expensive).
        Falls back to Gemini Files API only if keyframe extraction fails.
        """
        async with _semaphore:
            return await self._do_compare(s3_keys, mime_types, labels, exercise_name, user_context)

    async def _do_compare(
        self,
        s3_keys: list[str],
        mime_types: list[str],
        labels: list[str],
        exercise_name: str | None,
        user_context: str | None,
    ) -> dict:
        """Internal comparison implementation with keyframe + cache support."""
        tmp_paths = []
        gemini_files = []
        client = get_genai_client()
        settings = get_settings()
        use_keyframes = True

        try:
            from services.keyframe_extractor import should_use_keyframes, extract_key_frames

            # Check if keyframes are globally enabled
            if not should_use_keyframes("video", is_multi_video=True):
                use_keyframes = False
        except ImportError:
            use_keyframes = False

        try:
            # Step 1: Download all videos
            for i, (s3_key, mime_type) in enumerate(zip(s3_keys, mime_types)):
                tmp_path = await self._download_s3_to_temp(s3_key, mime_type, prefix=f"compare_{i}_")
                tmp_paths.append(tmp_path)

            if use_keyframes:
                # Keyframe path: extract frames from each video
                logger.info(f"Using keyframe extraction for {len(s3_keys)}-video comparison")
                parts = []

                for i, (tmp_path, mime_type, label) in enumerate(zip(tmp_paths, mime_types, labels)):
                    parts.append(genai_types.Part.from_text(
                        text=f"\n--- Video {i+1} (labeled: '{label}') - Key Frames ---\n"
                    ))

                    try:
                        frames = await extract_key_frames(tmp_path, num_frames=settings.keyframe_default_count)
                        for jpeg_bytes, frame_mime in frames:
                            parts.append(genai_types.Part.from_bytes(data=jpeg_bytes, mime_type=frame_mime))
                        logger.info(f"Extracted {len(frames)} keyframes from video {i+1}")
                    except Exception as e:
                        logger.warning(f"Keyframe extraction failed for video {i+1}, falling back to Files API: {e}")
                        use_keyframes = False
                        parts = []  # Reset parts
                        break

            if not use_keyframes:
                # Gemini Files API fallback
                logger.info(f"Using Gemini Files API for {len(s3_keys)}-video comparison")
                for i, (tmp_path, mime_type, label) in enumerate(zip(tmp_paths, mime_types, labels)):
                    gemini_file = await asyncio.to_thread(
                        client.files.upload,
                        file=tmp_path,
                        config=genai_types.UploadFileConfig(
                            mime_type=mime_type,
                            display_name=f"compare_{label}_{uuid.uuid4().hex[:8]}",
                        ),
                    )
                    gemini_files.append(gemini_file)
                    logger.info(f"Gemini file created for video {i+1}: {gemini_file.name}")

                # Poll until ALL files are ACTIVE
                start_poll = time.time()
                timeout = 180  # 3 minutes for multiple videos
                for i, gf in enumerate(gemini_files):
                    while gf.state.name == "PROCESSING":
                        elapsed = time.time() - start_poll
                        if elapsed > timeout:
                            raise TimeoutError(f"Gemini file processing timed out after {timeout}s")
                        logger.debug(f"Video {i+1} still processing ({elapsed:.0f}s)...")
                        await asyncio.sleep(2)
                        gf = await asyncio.to_thread(client.files.get, name=gf.name)
                        gemini_files[i] = gf

                    if gf.state.name == "FAILED":
                        raise RuntimeError(f"Gemini file processing failed for video {i+1}: {gf.state}")

                logger.info(f"All {len(gemini_files)} Gemini files ready")

                # Build parts from Gemini files
                parts = []
                for i, (gf, mime_type, label) in enumerate(zip(gemini_files, mime_types, labels)):
                    parts.append(genai_types.Part.from_text(
                        text=f"\n--- Video {i+1} (labeled: '{label}') ---\n"
                    ))
                    parts.append(genai_types.Part.from_uri(
                        file_uri=gf.uri,
                        mime_type=mime_type,
                    ))

            # Build prompt and config
            cache_name = _get_form_cache()
            prompt = _build_form_comparison_prompt(labels, exercise_name, user_context, using_keyframes=use_keyframes)
            parts.append(genai_types.Part.from_text(text=prompt))

            gen_config = genai_types.GenerateContentConfig(
                temperature=0.1,
                response_mime_type="application/json",
                response_schema=FORM_COMPARISON_SCHEMA,
            )
            if cache_name:
                gen_config.cached_content = cache_name

            response = await asyncio.to_thread(
                client.models.generate_content,
                model=settings.gemini_model,
                contents=[genai_types.Content(parts=parts)],
                config=gen_config,
            )

            response_text = None
            try:
                response_text = response.text
            except (ValueError, AttributeError) as e:
                logger.debug(f"Failed to get comparison text: {e}")

            if not response_text:
                logger.warning("Gemini blocked form comparison response")
                return {
                    "videos": [],
                    "comparison": {
                        "improved": [],
                        "regressed": [],
                        "consistent": [],
                        "overall_trend": "Unable to analyze the comparison. The videos may not contain exercise content.",
                    },
                    "recommendations": [],
                }

            logger.info(f"Form comparison response received ({len(response_text)} chars)")
            result = json.loads(response_text)
            return result

        except TimeoutError:
            logger.error(f"Form comparison timed out for {len(s3_keys)} videos")
            raise
        except json.JSONDecodeError as e:
            logger.error(f"Failed to parse comparison JSON: {e}")
            raise ValueError(f"Failed to parse form comparison response: {e}")
        except Exception as e:
            logger.error(f"Form comparison failed: {e}", exc_info=True)
            raise

        finally:
            # Clean up all temp files
            for tmp_path in tmp_paths:
                if tmp_path and os.path.exists(tmp_path):
                    try:
                        os.unlink(tmp_path)
                        logger.debug(f"Cleaned up temp file: {tmp_path}")
                    except OSError as e:
                        logger.warning(f"Failed to clean up temp file {tmp_path}: {e}")

            # Clean up all Gemini files (best effort)
            for gf in gemini_files:
                if gf and hasattr(gf, "name"):
                    try:
                        await asyncio.to_thread(client.files.delete, name=gf.name)
                        logger.debug(f"Cleaned up Gemini file: {gf.name}")
                    except Exception as e:
                        logger.warning(f"Failed to clean up Gemini file: {e}")
