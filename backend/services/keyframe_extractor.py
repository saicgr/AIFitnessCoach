"""
Keyframe extraction from video files using FFmpeg.

Extracts evenly-spaced JPEG frames from video files for use with
Gemini's image analysis when full video upload is unnecessary or
too large (e.g., long videos, multi-video comparisons).

Uses imageio-ffmpeg for a bundled FFmpeg binary so no system install
is required.
"""

import asyncio
import json
import subprocess
from typing import List, Optional, Tuple

import imageio_ffmpeg

from core.config import get_settings
from core.logger import get_logger

logger = get_logger(__name__)

# Limits
_MAX_FRAMES = 20
_EDGE_SKIP_SECONDS = 0.5
_DEFAULT_NUM_FRAMES = 10
_DEFAULT_KEYFRAME_THRESHOLD = 30.0


async def get_video_duration(video_path: str) -> float:
    """
    Get the duration of a video file in seconds.

    Uses ffprobe (via imageio-ffmpeg) to read container metadata.

    Args:
        video_path: Path to the video file on disk.

    Returns:
        Duration in seconds as a float.

    Raises:
        RuntimeError: If ffprobe fails or duration cannot be parsed.
    """
    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

    # Derive ffprobe path from the bundled ffmpeg binary
    ffprobe_exe = ffmpeg_exe.replace("ffmpeg", "ffprobe")
    probe_cmd = [
        ffprobe_exe,
        "-v", "quiet",
        "-print_format", "json",
        "-show_entries", "format=duration",
        video_path,
    ]

    def _run_probe() -> float:
        try:
            result = subprocess.run(
                probe_cmd,
                capture_output=True,
                timeout=30,
            )
            if result.returncode == 0:
                data = json.loads(result.stdout)
                return float(data["format"]["duration"])
        except (FileNotFoundError, KeyError, json.JSONDecodeError, subprocess.TimeoutExpired) as e:
            logger.debug(f"ffprobe duration extraction failed: {e}")

        # Fallback: parse duration from ffmpeg stderr
        result = subprocess.run(
            [ffmpeg_exe, "-i", video_path, "-f", "null", "-"],
            capture_output=True,
            text=True,
            timeout=30,
        )
        # ffmpeg prints "Duration: HH:MM:SS.xx" in stderr
        for line in result.stderr.splitlines():
            if "Duration:" in line:
                time_str = line.split("Duration:")[1].split(",")[0].strip()
                parts = time_str.split(":")
                hours, minutes, seconds = float(parts[0]), float(parts[1]), float(parts[2])
                return hours * 3600 + minutes * 60 + seconds

        raise RuntimeError(
            f"Could not determine video duration for {video_path}: "
            f"stderr={result.stderr[:500]}"
        )

    duration = await asyncio.to_thread(_run_probe)
    logger.info("Video duration: %.2fs", duration, extra={"path": video_path})
    return duration


async def extract_key_frames(
    video_path: str,
    num_frames: int = _DEFAULT_NUM_FRAMES,
) -> List[Tuple[bytes, str]]:
    """
    Extract evenly-spaced JPEG keyframes from a video file.

    Skips the first and last 0.5s to avoid black frames from
    fade-in/fade-out. Returns raw JPEG bytes for each frame.

    Args:
        video_path: Path to the video file on disk.
        num_frames: Desired number of frames (capped at 20).

    Returns:
        List of (jpeg_bytes, "image/jpeg") tuples.
    """
    num_frames = min(num_frames, _MAX_FRAMES)
    duration = await get_video_duration(video_path)

    # Calculate usable range (skip edges)
    start = _EDGE_SKIP_SECONDS
    end = max(duration - _EDGE_SKIP_SECONDS, start + 0.1)

    if end <= start:
        # Very short video - just grab the midpoint
        timestamps = [duration / 2]
    elif num_frames == 1:
        timestamps = [(start + end) / 2]
    else:
        step = (end - start) / (num_frames - 1)
        timestamps = [start + i * step for i in range(num_frames)]

    ffmpeg_exe = imageio_ffmpeg.get_ffmpeg_exe()

    def _extract_frame(timestamp: float) -> Optional[bytes]:
        cmd = [
            ffmpeg_exe,
            "-ss", f"{timestamp:.3f}",
            "-i", video_path,
            "-vframes", "1",
            "-q:v", "2",
            "-f", "image2pipe",
            "-vcodec", "mjpeg",
            "pipe:1",
        ]
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                timeout=15,
            )
            if result.returncode == 0 and len(result.stdout) > 0:
                return result.stdout
            logger.warning(
                "Frame extraction failed at %.2fs (rc=%d)",
                timestamp,
                result.returncode,
            )
            return None
        except subprocess.TimeoutExpired:
            logger.warning("Frame extraction timed out at %.2fs", timestamp)
            return None

    def _extract_all() -> List[Tuple[bytes, str]]:
        result = []
        for ts in timestamps:
            jpeg_data = _extract_frame(ts)
            if jpeg_data:
                result.append((jpeg_data, "image/jpeg"))
        return result

    frames = await asyncio.to_thread(_extract_all)

    logger.info(
        "Extracted %d/%d keyframes from video (duration=%.1fs)",
        len(frames),
        num_frames,
        duration,
        extra={"path": video_path},
    )
    return frames


def should_use_keyframes(
    media_type: str,
    video_duration_hint: Optional[float] = None,
    is_multi_video: bool = False,
) -> bool:
    """
    Determine whether to use keyframe extraction instead of full video upload.

    Decision logic:
    - Images never use keyframes.
    - If keyframe extraction is globally disabled, return False.
    - Multi-video comparisons always use keyframes.
    - Single videos use keyframes if duration exceeds the threshold.

    Args:
        media_type: MIME type prefix, e.g. "video" or "image".
        video_duration_hint: Known or estimated duration in seconds.
        is_multi_video: True when comparing multiple videos.

    Returns:
        True if keyframe extraction should be used.
    """
    if media_type != "video":
        return False

    settings = get_settings()

    # Check global toggle (defaults to True if not yet in config)
    enabled = getattr(settings, "keyframe_extraction_enabled", True)
    if not enabled:
        return False

    # Multi-video always uses keyframes
    if is_multi_video:
        return True

    # Single video: compare against threshold
    if video_duration_hint is not None:
        threshold = getattr(
            settings, "keyframe_threshold_seconds", _DEFAULT_KEYFRAME_THRESHOLD
        )
        return video_duration_hint > threshold

    # No duration hint and not multi-video - default to False
    return False
