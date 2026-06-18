"""
Slideshow / Transformation-Video Service
========================================
Server-side render of a 9:16 MP4 from a span of a user's photos — the
"year of workout pics" transformation video — covering THREE photo sources:

    * ``workout_photos``  (migration 2265 — casual gym selfies / lift snaps)
    * ``progress_photos`` (migration 055  — front/side/back body photos)
    * ``food``            (food_logs.image_url / image_storage_key)

The render is a deterministic ffmpeg composite of the user's REAL photos — no
per-frame AI, no mock imagery (CLAUDE.md cost-discipline + no-mock rules). The
bundled ``imageio-ffmpeg`` binary is invoked via subprocess with a filtergraph
that:

    * scales + pads every photo to a fixed 1080x1920 canvas (no distortion),
    * applies a slow Ken-Burns zoom (``zoompan``) per frame,
    * cross-fades between consecutive frames (``xfade``),
    * optionally burns a per-frame date caption (``drawtext`` + bundled font).

Three render entry points share the same compositing core:

    * ``render_slideshow``    — the full transformation montage (date-ordered).
    * ``render_count_up``     — F9 reveal: a number ticking 0 → final.
    * ``render_before_after`` — F4 reveal: two photos + one caption (the AI
                                caption is generated UPSTREAM and passed in as a
                                plain string — this module never calls an LLM).

All outputs are uploaded to S3 under ``slideshows/{user_id}/`` and the storage
key + a presigned URL are returned.

Logging prefixes follow CLAUDE.md: 🎬 milestone, 🔍 debug, ✅ success, ❌ error.
"""

from __future__ import annotations

import math
import os
import shutil
import subprocess
import tempfile
import uuid
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional, Tuple

import imageio_ffmpeg

from core.db import get_supabase_db
from core.logger import get_logger
from services.s3_service import get_s3_service

logger = get_logger(__name__)

# --------------------------------------------------------------------------- #
# Render constants
# --------------------------------------------------------------------------- #

CANVAS_W = 1080
CANVAS_H = 1920
FPS = 30

# Per-photo timing (seconds).
HOLD_SECONDS = 2.0          # time a photo is fully on-screen
XFADE_SECONDS = 0.6         # cross-fade overlap between consecutive photos
COUNT_UP_SECONDS = 3.0      # F9 tick duration
REVEAL_HOLD_SECONDS = 2.5   # F4 per-photo hold

# Hard caps — protect render time + memory on Render. A montage of >100 photos
# would take minutes and is never a good share anyway.
MAX_PHOTOS = 100
MIN_PHOTOS = 1

# Valid sources.
SOURCE_WORKOUT = "workout_photos"
SOURCE_PROGRESS = "progress_photos"
SOURCE_FOOD = "food"
VALID_SOURCES = {SOURCE_WORKOUT, SOURCE_PROGRESS, SOURCE_FOOD}

# Background color for letterbox padding (near-black, matches share aesthetic).
PAD_COLOR = "0x0A0A0Bff"

# Bundled brand fonts (copied from mobile/flutter/assets/fonts). Anton is the
# display face used across the shareables library; Archivo is the body face.
_FONT_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "assets", "fonts")
FONT_DISPLAY = os.path.join(_FONT_DIR, "Anton-Regular.ttf")
FONT_BODY = os.path.join(_FONT_DIR, "Archivo.ttf")


def _ffmpeg_exe() -> str:
    """Path to the bundled ffmpeg binary."""
    return imageio_ffmpeg.get_ffmpeg_exe()


def _escape_drawtext(text: str) -> str:
    """Escape a string for ffmpeg drawtext ``text=`` (special chars: \\ : ' %)."""
    if text is None:
        return ""
    out = text.replace("\\", "\\\\")
    out = out.replace(":", r"\:")
    out = out.replace("'", r"\'")
    out = out.replace("%", r"\%")
    out = out.replace(",", r"\,")
    return out


# --------------------------------------------------------------------------- #
# Photo sourcing
# --------------------------------------------------------------------------- #


@dataclass
class _Frame:
    """One sourced photo: S3 key + an optional caption (e.g. its date)."""
    storage_key: str
    caption: Optional[str] = None
    taken_at: Optional[datetime] = None


def _parse_dt(value) -> Optional[datetime]:
    if not value:
        return None
    if isinstance(value, datetime):
        return value
    try:
        return datetime.fromisoformat(str(value).replace("Z", "+00:00"))
    except Exception:
        return None


def _s3_key_from_url(url: Optional[str]) -> Optional[str]:
    """Extract the S3 object key from a direct/presigned S3 URL.

    food_logs stores ``image_url`` (a direct S3 URL) and ``image_storage_key``.
    We prefer the explicit key; this is the fallback when only a URL exists.
    """
    if not url:
        return None
    try:
        from urllib.parse import urlparse, unquote

        parsed = urlparse(url)
        if not parsed.netloc or ".s3." not in parsed.netloc and "s3." not in parsed.netloc:
            # Not an S3 URL we can extract a key from.
            return None
        key = unquote(parsed.path.lstrip("/"))
        return key or None
    except Exception:
        return None


def _fetch_frames(
    user_id: str,
    source: str,
    date_from: Optional[str],
    date_to: Optional[str],
) -> List[_Frame]:
    """Pull the user's photos for ``source`` in [date_from, date_to], ordered by
    capture time ASCENDING (oldest → newest, the natural transformation order).

    Ownership is enforced by the ``user_id`` filter on every query.
    """
    db = get_supabase_db()
    frames: List[_Frame] = []

    if source == SOURCE_WORKOUT:
        q = (
            db.client.table("workout_photos")
            .select("storage_key, photo_url, taken_at")
            .eq("user_id", user_id)
            .order("taken_at", desc=False)
            .limit(MAX_PHOTOS)
        )
        if date_from:
            q = q.gte("taken_at", date_from)
        if date_to:
            q = q.lte("taken_at", date_to)
        for row in (q.execute().data or []):
            key = row.get("storage_key") or _s3_key_from_url(row.get("photo_url"))
            if key:
                dt = _parse_dt(row.get("taken_at"))
                frames.append(_Frame(storage_key=key, caption=_caption_for_date(dt), taken_at=dt))

    elif source == SOURCE_PROGRESS:
        q = (
            db.client.table("progress_photos")
            .select("storage_key, photo_url, taken_at")
            .eq("user_id", user_id)
            .order("taken_at", desc=False)
            .limit(MAX_PHOTOS)
        )
        if date_from:
            q = q.gte("taken_at", date_from)
        if date_to:
            q = q.lte("taken_at", date_to)
        for row in (q.execute().data or []):
            key = row.get("storage_key") or _s3_key_from_url(row.get("photo_url"))
            if key:
                dt = _parse_dt(row.get("taken_at"))
                frames.append(_Frame(storage_key=key, caption=_caption_for_date(dt), taken_at=dt))

    elif source == SOURCE_FOOD:
        q = (
            db.client.table("food_logs")
            .select("image_storage_key, image_url, logged_at")
            .eq("user_id", user_id)
            .not_.is_("image_url", "null")
            .order("logged_at", desc=False)
            .limit(MAX_PHOTOS)
        )
        if date_from:
            q = q.gte("logged_at", date_from)
        if date_to:
            q = q.lte("logged_at", date_to)
        for row in (q.execute().data or []):
            key = row.get("image_storage_key") or _s3_key_from_url(row.get("image_url"))
            if key:
                dt = _parse_dt(row.get("logged_at"))
                frames.append(_Frame(storage_key=key, caption=_caption_for_date(dt), taken_at=dt))

    else:
        raise ValueError(f"Unknown slideshow source: {source!r}")

    return frames


def _caption_for_date(dt: Optional[datetime]) -> Optional[str]:
    """Human date caption for a frame (e.g. 'Mar 2025'). None when no date."""
    if not dt:
        return None
    return dt.strftime("%b %Y")


def _download_frames(frames: List[_Frame], workdir: str) -> List[Tuple[str, Optional[str]]]:
    """Download each frame's S3 object to ``workdir``. Returns [(local_path,
    caption)] preserving order. Frames that fail to download are skipped (a
    single corrupt/missing object must not sink the whole render), but if NONE
    download we raise — there is nothing to render.
    """
    s3 = get_s3_service()
    downloaded: List[Tuple[str, Optional[str]]] = []
    for idx, fr in enumerate(frames):
        try:
            data = s3.get_object_bytes(fr.storage_key)
            if not data:
                logger.debug(f"🔍 [Slideshow] Empty object for {fr.storage_key}, skipping")
                continue
            # Extension is irrelevant to ffmpeg's image2 demuxer (it sniffs the
            # header), but a sane suffix keeps the temp dir readable.
            path = os.path.join(workdir, f"frame_{idx:04d}.img")
            with open(path, "wb") as fh:
                fh.write(data)
            downloaded.append((path, fr.caption))
        except Exception as e:
            logger.error(f"❌ [Slideshow] Failed to download {fr.storage_key}: {e}")
            continue

    if not downloaded:
        raise RuntimeError("No photos could be downloaded for the slideshow")
    return downloaded


# --------------------------------------------------------------------------- #
# Filtergraph construction
# --------------------------------------------------------------------------- #


def _scale_pad_chain(idx: int, label_in: str, label_out: str, duration: float, kenburns: bool) -> str:
    """Build the per-image normalization chain: scale → pad → (zoompan) → fps.

    The input MUST be a looped still fed with ``-loop 1 -t {duration} -r {FPS}``
    so the stream is already CFR; the trailing ``fps={FPS}`` re-asserts the rate
    after zoompan, which is required for ``xfade`` to accept the stream as a
    constant-frame-rate input (it rejects ``1/0`` otherwise).
    """
    # scale to fit (letterbox), pad to the exact canvas, set SAR 1.
    chain = (
        f"[{label_in}]"
        f"scale={CANVAS_W}:{CANVAS_H}:force_original_aspect_ratio=decrease,"
        f"pad={CANVAS_W}:{CANVAS_H}:(ow-iw)/2:(oh-ih)/2:color={PAD_COLOR},"
        f"setsar=1,format=yuv420p"
    )
    if kenburns:
        # Gentle 1.0 → 1.10 zoom over the clip. The looped input already
        # supplies one frame per output frame, so zoompan runs with d=1 and the
        # zoom progresses by output-frame-number `on` (NOT by accumulating
        # `zoom`, which would over-zoom across the whole looped stream).
        total_frames = max(1, int(round(duration * FPS)))
        step = 0.10 / total_frames
        chain += (
            f",zoompan=z='min(1.0+{step:.6f}*on,1.10)':"
            f"x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':"
            f"d=1:s={CANVAS_W}x{CANVAS_H}:fps={FPS}"
        )
    # Re-assert CFR (xfade requirement) and a clean pixel format.
    chain += f",fps={FPS},format=yuv420p"
    chain += f"[{label_out}]"
    return chain


def _drawtext_date(label_in: str, label_out: str, caption: str) -> str:
    """Burn a small date caption in the lower-left with a soft shadow."""
    esc = _escape_drawtext(caption)
    fontfile = FONT_BODY if os.path.exists(FONT_BODY) else FONT_DISPLAY
    return (
        f"[{label_in}]drawtext=fontfile='{fontfile}':text='{esc}':"
        f"fontcolor=white:fontsize=52:x=64:y=h-140:"
        f"shadowcolor=black@0.6:shadowx=2:shadowy=2[{label_out}]"
    )


def _run_ffmpeg(cmd: List[str]) -> None:
    """Run ffmpeg, raising a clear error (with stderr tail) on failure."""
    logger.debug(f"🔍 [Slideshow] ffmpeg cmd: {' '.join(cmd[:6])} … ({len(cmd)} args)")
    proc = subprocess.run(cmd, capture_output=True, text=True)
    if proc.returncode != 0:
        tail = (proc.stderr or "")[-1500:]
        logger.error(f"❌ [Slideshow] ffmpeg failed (rc={proc.returncode}):\n{tail}")
        raise RuntimeError(f"ffmpeg render failed (rc={proc.returncode})")


def _compose_montage(
    photos: List[Tuple[str, Optional[str]]],
    out_path: str,
    *,
    style: str = "kenburns",
    show_captions: bool = True,
) -> None:
    """Composite N normalized photo-clips into one cross-faded MP4.

    ``style`` ∈ {"kenburns", "flat"} — kenburns adds the zoom, flat is a plain
    crossfade slideshow (cheaper, snappier for many photos).
    """
    ff = _ffmpeg_exe()
    n = len(photos)
    kenburns = style == "kenburns" and n <= 40  # zoompan is heavy; cap it
    hold = HOLD_SECONDS
    xfade = XFADE_SECONDS if n > 1 else 0.0
    # Each clip lasts hold + xfade so adjacent clips have overlap to fade through.
    clip_dur = hold + xfade

    cmd: List[str] = [ff, "-y"]
    for path, _cap in photos:
        # Loop a single still into a short CFR video stream. The explicit
        # `-r {FPS}` on the input is what makes xfade accept it downstream.
        cmd += ["-loop", "1", "-t", f"{clip_dur:.3f}", "-r", str(FPS), "-i", path]

    filter_parts: List[str] = []
    seg_labels: List[str] = []
    for i, (_path, caption) in enumerate(photos):
        norm_out = f"n{i}"
        filter_parts.append(_scale_pad_chain(i, f"{i}:v", norm_out, clip_dur, kenburns))
        cur = norm_out
        if show_captions and caption:
            cap_out = f"c{i}"
            filter_parts.append(_drawtext_date(cur, cap_out, caption))
            cur = cap_out
        seg_labels.append(cur)

    if n == 1:
        filter_parts.append(f"[{seg_labels[0]}]copy[outv]")
    else:
        # Chain xfade across all segments. Each xfade offset is the cumulative
        # hold time so far (clips overlap by ``xfade`` seconds).
        prev = seg_labels[0]
        offset = hold
        for i in range(1, n):
            out_label = "outv" if i == n - 1 else f"x{i}"
            filter_parts.append(
                f"[{prev}][{seg_labels[i]}]xfade=transition=fade:"
                f"duration={xfade}:offset={offset:.3f}[{out_label}]"
            )
            prev = out_label
            offset += hold  # next overlap point

    filtergraph = ";".join(filter_parts)
    cmd += [
        "-filter_complex", filtergraph,
        "-map", "[outv]",
        "-c:v", "libx264",
        "-pix_fmt", "yuv420p",
        "-preset", "medium",
        "-crf", "23",
        "-movflags", "+faststart",
        out_path,
    ]
    _run_ffmpeg(cmd)


# --------------------------------------------------------------------------- #
# S3 upload
# --------------------------------------------------------------------------- #


def _upload_result(user_id: str, out_path: str, kind: str) -> Tuple[str, str]:
    """Upload the rendered MP4 to ``slideshows/{user_id}/`` and return
    ``(storage_key, presigned_url)``.
    """
    with open(out_path, "rb") as fh:
        data = fh.read()
    if not data:
        raise RuntimeError("Rendered MP4 is empty")

    s3 = get_s3_service()
    storage_key = s3.upload_bytes(
        data,
        key_prefix=f"slideshows/{user_id}",
        filename=f"{kind}_{uuid.uuid4().hex[:8]}.mp4",
        content_type="video/mp4",
    )
    url = _presign(storage_key)
    logger.info(f"✅ [Slideshow] Uploaded {len(data)} bytes → {storage_key}")
    return storage_key, url


def _presign(storage_key: str, expires_in: int = 24 * 3600) -> str:
    """Presigned GET URL for a slideshow object (24h default)."""
    import boto3
    from botocore.config import Config as BotoConfig
    from core.config import get_settings

    settings = get_settings()
    s3 = boto3.client(
        "s3",
        aws_access_key_id=settings.aws_access_key_id,
        aws_secret_access_key=settings.aws_secret_access_key,
        region_name=settings.aws_default_region,
        config=BotoConfig(signature_version="s3v4"),
    )
    return s3.generate_presigned_url(
        "get_object",
        Params={"Bucket": settings.s3_bucket_name, "Key": storage_key},
        ExpiresIn=expires_in,
    )


# --------------------------------------------------------------------------- #
# Public render entry points
# --------------------------------------------------------------------------- #


def render_slideshow(
    user_id: str,
    source: str,
    date_from: Optional[str] = None,
    date_to: Optional[str] = None,
    style: str = "kenburns",
) -> dict:
    """Render the full transformation montage for ``source`` over a date span.

    Returns ``{"storage_key", "result_url", "photo_count"}``. Raises if the span
    has no usable photos (no mock/fallback — the caller surfaces the error).
    """
    if source not in VALID_SOURCES:
        raise ValueError(f"source must be one of {sorted(VALID_SOURCES)}")

    logger.info(f"🎬 [Slideshow] render_slideshow user={user_id} source={source} "
                f"from={date_from} to={date_to} style={style}")

    frames = _fetch_frames(user_id, source, date_from, date_to)
    if len(frames) < MIN_PHOTOS:
        raise RuntimeError(
            f"No {source} photos found for this date range — add photos first"
        )
    frames = frames[:MAX_PHOTOS]

    workdir = tempfile.mkdtemp(prefix="slideshow_")
    try:
        photos = _download_frames(frames, workdir)
        out_path = os.path.join(workdir, "out.mp4")
        _compose_montage(photos, out_path, style=style, show_captions=True)
        storage_key, url = _upload_result(user_id, out_path, "transformation")
        return {
            "storage_key": storage_key,
            "result_url": url,
            "photo_count": len(photos),
        }
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def render_count_up(
    user_id: str,
    final_value: float,
    label: str,
    *,
    unit: str = "",
    background_key: Optional[str] = None,
    value_format: str = "int",
) -> dict:
    """F9 count-up reveal: a number ticks 0 → ``final_value`` over a few seconds,
    centered over an optional background photo (else a dark gradient).

    ``value_format`` ∈ {"int", "float1"} controls decimal display. ``label`` is
    the caption under the number (e.g. "TOTAL VOLUME (LBS)" or "CALORIES").

    Returns ``{"storage_key", "result_url"}``.
    """
    logger.info(f"🎬 [Slideshow] render_count_up user={user_id} final={final_value} "
                f"label={label!r} unit={unit!r}")

    ff = _ffmpeg_exe()
    workdir = tempfile.mkdtemp(prefix="countup_")
    try:
        # Background: a downloaded photo (scaled+darkened) or a solid dark canvas.
        bg_path: Optional[str] = None
        if background_key:
            try:
                data = get_s3_service().get_object_bytes(background_key)
                if data:
                    bg_path = os.path.join(workdir, "bg.img")
                    with open(bg_path, "wb") as fh:
                        fh.write(data)
            except Exception as e:
                logger.debug(f"🔍 [Slideshow] count-up bg download failed: {e}")
                bg_path = None

        duration = COUNT_UP_SECONDS
        out_path = os.path.join(workdir, "out.mp4")

        # Build the ticking number expression. ffmpeg drawtext can't print an
        # arbitrary runtime float cleanly, so we pre-render N discrete frames'
        # worth of text via the `text='%{eif:...}'` expansion on a per-frame
        # counter. eif prints an integer; for float1 we scale by 10 and insert
        # a decimal via a second drawtext is messy — instead we use the
        # `t` (time) based linear interpolation and `%{eif}` for the integer.
        font = FONT_DISPLAY if os.path.exists(FONT_DISPLAY) else FONT_BODY
        label_font = FONT_BODY if os.path.exists(FONT_BODY) else FONT_DISPLAY

        # value(t) = final * min(t/duration, 1), eased.
        # ease-out: 1-(1-p)^2 where p=t/duration.
        ease = f"(1-pow(1-min(t/{duration},1),2))"
        if value_format == "float1":
            # Print one decimal: integer part + '.' + first decimal digit.
            int_expr = f"floor({final_value}*{ease})"
            dec_expr = f"floor(mod({final_value}*{ease}*10,10))"
            number_draw = (
                f"drawtext=fontfile='{font}':"
                f"text='%{{eif\\:{int_expr}\\:d}}.%{{eif\\:{dec_expr}\\:d}}':"
                f"fontcolor=white:fontsize=220:x=(w-text_w)/2:y=(h-text_h)/2-80:"
                f"shadowcolor=black@0.5:shadowx=3:shadowy=3"
            )
        else:
            int_expr = f"floor({final_value}*{ease})"
            number_draw = (
                f"drawtext=fontfile='{font}':"
                f"text='%{{eif\\:{int_expr}\\:d}}':"
                f"fontcolor=white:fontsize=240:x=(w-text_w)/2:y=(h-text_h)/2-80:"
                f"shadowcolor=black@0.5:shadowx=3:shadowy=3"
            )

        caption_text = label.upper()
        if unit:
            caption_text = f"{caption_text} ({unit.upper()})"
        label_draw = (
            f"drawtext=fontfile='{label_font}':text='{_escape_drawtext(caption_text)}':"
            f"fontcolor=white@0.85:fontsize=64:x=(w-text_w)/2:y=(h/2)+140:"
            f"shadowcolor=black@0.5:shadowx=2:shadowy=2"
        )

        if bg_path:
            cmd = [
                ff, "-y", "-loop", "1", "-t", f"{duration:.3f}", "-r", str(FPS), "-i", bg_path,
                "-filter_complex",
                (
                    f"[0:v]scale={CANVAS_W}:{CANVAS_H}:force_original_aspect_ratio=increase,"
                    f"crop={CANVAS_W}:{CANVAS_H},setsar=1,"
                    f"eq=brightness=-0.25,format=yuv420p,"
                    f"{number_draw},{label_draw}[outv]"
                ),
                "-map", "[outv]",
            ]
        else:
            cmd = [
                ff, "-y",
                "-f", "lavfi",
                "-i", f"color=c=0x0A0A0B:s={CANVAS_W}x{CANVAS_H}:d={duration:.3f}:r={FPS}",
                "-filter_complex",
                f"[0:v]format=yuv420p,{number_draw},{label_draw}[outv]",
                "-map", "[outv]",
            ]
        cmd += [
            "-t", f"{duration:.3f}",
            "-c:v", "libx264", "-pix_fmt", "yuv420p",
            "-preset", "medium", "-crf", "23", "-movflags", "+faststart",
            out_path,
        ]
        _run_ffmpeg(cmd)
        storage_key, url = _upload_result(user_id, out_path, "countup")
        return {"storage_key": storage_key, "result_url": url}
    finally:
        shutil.rmtree(workdir, ignore_errors=True)


def render_before_after(
    user_id: str,
    before_key: str,
    after_key: str,
    caption: str,
    *,
    style: str = "wipe",
) -> dict:
    """F4 before/after reveal: ``before`` photo, then a wipe/fade to ``after``,
    with one caption line burned on the after-frame.

    ``caption`` is generated UPSTREAM (Gemini-Flash, cached) and passed in as a
    plain string — this function makes NO LLM call.

    Returns ``{"storage_key", "result_url"}``.
    """
    logger.info(f"🎬 [Slideshow] render_before_after user={user_id} caption={caption!r}")

    ff = _ffmpeg_exe()
    workdir = tempfile.mkdtemp(prefix="beforeafter_")
    try:
        s3 = get_s3_service()
        before_path = os.path.join(workdir, "before.img")
        after_path = os.path.join(workdir, "after.img")
        for key, path in ((before_key, before_path), (after_key, after_path)):
            data = s3.get_object_bytes(key)
            if not data:
                raise RuntimeError(f"Photo {key} could not be downloaded")
            with open(path, "wb") as fh:
                fh.write(data)

        hold = REVEAL_HOLD_SECONDS
        xfade = 0.8
        clip = hold + xfade
        transition = "wipeleft" if style == "wipe" else "fade"

        font = FONT_BODY if os.path.exists(FONT_BODY) else FONT_DISPLAY
        cap_draw = (
            f"drawtext=fontfile='{font}':text='{_escape_drawtext(caption)}':"
            f"fontcolor=white:fontsize=58:x=(w-text_w)/2:y=h-200:"
            f"box=1:boxcolor=black@0.45:boxborderw=24:"
            f"shadowcolor=black@0.6:shadowx=2:shadowy=2"
        )

        # "BEFORE" / "AFTER" corner labels.
        before_label = (
            f"drawtext=fontfile='{font}':text='BEFORE':fontcolor=white@0.9:"
            f"fontsize=56:x=64:y=120:shadowcolor=black@0.6:shadowx=2:shadowy=2"
        )
        after_label = (
            f"drawtext=fontfile='{font}':text='AFTER':fontcolor=white@0.95:"
            f"fontsize=56:x=64:y=120:shadowcolor=black@0.6:shadowx=2:shadowy=2"
        )

        norm = (
            f"scale={CANVAS_W}:{CANVAS_H}:force_original_aspect_ratio=decrease,"
            f"pad={CANVAS_W}:{CANVAS_H}:(ow-iw)/2:(oh-ih)/2:color={PAD_COLOR},"
            f"setsar=1,format=yuv420p"
        )
        # No `trim` — the `-loop 1 -t {clip} -r {FPS}` inputs already bound the
        # duration; a trim here would strip the framerate and break xfade's CFR
        # requirement. `fps={FPS}` is the LAST filter on each branch.
        filtergraph = (
            f"[0:v]{norm},{before_label},fps={FPS}[b];"
            f"[1:v]{norm},{after_label},{cap_draw},fps={FPS}[a];"
            f"[b][a]xfade=transition={transition}:duration={xfade}:offset={hold:.3f}[outv]"
        )

        out_path = os.path.join(workdir, "out.mp4")
        cmd = [
            ff, "-y",
            "-loop", "1", "-t", f"{clip:.3f}", "-r", str(FPS), "-i", before_path,
            "-loop", "1", "-t", f"{clip:.3f}", "-r", str(FPS), "-i", after_path,
            "-filter_complex", filtergraph,
            "-map", "[outv]",
            "-c:v", "libx264", "-pix_fmt", "yuv420p",
            "-preset", "medium", "-crf", "23", "-movflags", "+faststart",
            out_path,
        ]
        _run_ffmpeg(cmd)
        storage_key, url = _upload_result(user_id, out_path, "beforeafter")
        return {"storage_key": storage_key, "result_url": url}
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
