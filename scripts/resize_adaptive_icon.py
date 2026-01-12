#!/usr/bin/env python3
"""
Resize adaptive icon foreground images to fit within the safe zone.

Android adaptive icons have a 108dp canvas but only the center 66% (72dp)
is guaranteed visible. This script resizes the logo to fit within that safe zone.

Density    | Full Canvas | Safe Zone
-----------|-------------|----------
mdpi       | 108px       | 72px
hdpi       | 162px       | 108px
xhdpi      | 216px       | 144px
xxhdpi     | 324px       | 216px
xxxhdpi    | 432px       | 288px
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
except ImportError:
    print("❌ Pillow not installed. Installing...")
    os.system(f"{sys.executable} -m pip install Pillow")
    from PIL import Image


# Adaptive icon dimensions per density
DENSITIES = {
    "mdpi": {"canvas": 108, "safe": 72},
    "hdpi": {"canvas": 162, "safe": 108},
    "xhdpi": {"canvas": 216, "safe": 144},
    "xxhdpi": {"canvas": 324, "safe": 216},
    "xxxhdpi": {"canvas": 432, "safe": 288},
}

# Additional padding within safe zone (percentage) to give breathing room
INNER_PADDING_PERCENT = 0.08  # 8% extra padding


def resize_foreground(input_path: str, output_dir: str, density: str = None):
    """
    Resize a foreground image to fit within the adaptive icon safe zone.

    Args:
        input_path: Path to the source high-res foreground image
        output_dir: Directory to save resized images
        density: Specific density to generate (or None for all)
    """
    print(f"🔍 Loading source image: {input_path}")

    # Load the source image
    source = Image.open(input_path).convert("RGBA")
    print(f"   Source size: {source.width}x{source.height}")

    # Find the bounding box of non-transparent content
    bbox = source.getbbox()
    if bbox:
        print(f"   Content bounds: {bbox}")
        # Crop to content
        content = source.crop(bbox)
    else:
        content = source

    print(f"   Content size: {content.width}x{content.height}")

    densities_to_process = {density: DENSITIES[density]} if density else DENSITIES

    for density_name, dims in densities_to_process.items():
        canvas_size = dims["canvas"]
        safe_size = dims["safe"]

        # Apply inner padding for breathing room
        target_size = int(safe_size * (1 - INNER_PADDING_PERCENT * 2))

        # Calculate scale to fit content within target size
        scale = min(target_size / content.width, target_size / content.height)
        new_width = int(content.width * scale)
        new_height = int(content.height * scale)

        # Resize content
        resized_content = content.resize((new_width, new_height), Image.Resampling.LANCZOS)

        # Create new canvas with transparency
        canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))

        # Center the content on canvas
        x_offset = (canvas_size - new_width) // 2
        y_offset = (canvas_size - new_height) // 2

        canvas.paste(resized_content, (x_offset, y_offset), resized_content)

        # Save
        output_path = Path(output_dir) / f"drawable-{density_name}" / "ic_launcher_foreground.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)
        canvas.save(output_path, "PNG")

        print(f"✅ {density_name}: {canvas_size}x{canvas_size}px (content: {new_width}x{new_height}px) -> {output_path}")

    # Also save a base drawable version (xxxhdpi)
    base_output = Path(output_dir) / "drawable" / "ic_launcher_foreground.png"
    base_output.parent.mkdir(parents=True, exist_ok=True)

    canvas_size = DENSITIES["xxxhdpi"]["canvas"]
    safe_size = DENSITIES["xxxhdpi"]["safe"]
    target_size = int(safe_size * (1 - INNER_PADDING_PERCENT * 2))
    scale = min(target_size / content.width, target_size / content.height)
    new_width = int(content.width * scale)
    new_height = int(content.height * scale)
    resized_content = content.resize((new_width, new_height), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    x_offset = (canvas_size - new_width) // 2
    y_offset = (canvas_size - new_height) // 2
    canvas.paste(resized_content, (x_offset, y_offset), resized_content)
    canvas.save(base_output, "PNG")
    print(f"✅ base drawable: {canvas_size}x{canvas_size}px -> {base_output}")


def main():
    # Paths
    project_root = Path(__file__).parent.parent

    # Source: use the highest resolution foreground available
    source_candidates = [
        project_root / "mobile/flutter/android/app/src/main/res/drawable/ic_launcher_foreground.png",
        project_root / "mobile/flutter/android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png",
        project_root / "fitwiz_android_icon_pack/android_res/drawable/ic_launcher_foreground.png",
    ]

    source_path = None
    for candidate in source_candidates:
        if candidate.exists():
            source_path = candidate
            break

    if not source_path:
        print("❌ No source foreground image found!")
        print("   Please provide a high-resolution foreground image.")
        sys.exit(1)

    # Output directory
    output_dir = project_root / "mobile/flutter/android/app/src/main/res"

    print("=" * 60)
    print("🎨 Adaptive Icon Foreground Resizer")
    print("=" * 60)
    print()
    print(f"📁 Source: {source_path}")
    print(f"📁 Output: {output_dir}")
    print()
    print("This will resize the logo to fit within the 66% safe zone")
    print("with an additional 8% inner padding for breathing room.")
    print()

    resize_foreground(str(source_path), str(output_dir))

    print()
    print("=" * 60)
    print("✅ Done! Rebuild your app to see the changes.")
    print()
    print("To rebuild:")
    print("  cd mobile/flutter && flutter clean && flutter build apk")
    print("=" * 60)


if __name__ == "__main__":
    main()
