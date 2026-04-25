import 'dart:io';

import 'package:flutter/material.dart';

/// Full-bleed photo backdrop with a vertical darkening scrim so overlaid
/// metrics stay legible. Used by every Photo-category template.
///
/// When [path] is null/empty (user hasn't uploaded a photo yet), falls back
/// to a gradient using [fallbackGradient] so the template still renders
/// correctly — the share sheet shows an inline upload chip but the
/// preview is never blank.
class PhotoBackdrop extends StatelessWidget {
  final String? path;
  final List<Color> fallbackGradient;

  /// Scrim opacity at the top of the canvas (0..1). Lower means the
  /// photo shows through cleanly; raise it for moody/quote templates.
  final double topScrim;

  /// Scrim opacity at the bottom (0..1). Higher because most overlays
  /// (hero numbers, stat strips, watermarks) sit in the lower half.
  final double bottomScrim;

  /// When true, applies a vignette as well — helps when a busy photo
  /// fights with light text near the corners.
  final bool vignette;

  const PhotoBackdrop({
    super.key,
    required this.path,
    required this.fallbackGradient,
    this.topScrim = 0.15,
    this.bottomScrim = 0.55,
    this.vignette = false,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (path != null && path!.isNotEmpty)
          Image.file(
            File(path!),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _gradient(),
          )
        else
          _gradient(),
        // Scrim — vertical gradient, dark at the bottom.
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: topScrim),
                Colors.black.withValues(alpha: (topScrim + bottomScrim) / 2),
                Colors.black.withValues(alpha: bottomScrim),
              ],
            ),
          ),
        ),
        if (vignette)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.1,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _gradient() {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: fallbackGradient,
        ),
      ),
    );
  }
}
