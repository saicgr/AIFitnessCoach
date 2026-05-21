import 'dart:io';

import 'package:flutter/material.dart';

/// A capture-safe food image widget for share templates.
///
/// Food shares carry a photo that is either an S3 `https` URL (logged photo
/// already uploaded) or a local file path (just-picked `image_picker` output),
/// or nothing at all. This widget resolves all three cases and — critically —
/// **never shows a blank box** in a captured PNG: a failed network fetch, a
/// still-loading network fetch, and a missing/unreadable local file all fall
/// back to [fallbackBuilder] (or a neutral dark gradient).
///
/// The public constructor here is a contract other share-template agents code
/// against — do not change its shape.
class FoodImage extends StatelessWidget {
  /// An S3 `https` URL, a local file path, or null/empty.
  final String? url;

  /// How the image fills its box. Defaults to [BoxFit.cover] — food photos
  /// are almost always shown edge-to-edge behind a scrim.
  final BoxFit fit;

  /// Built when [url] is null/empty, or when a network/file load fails or is
  /// still in flight. When null, a neutral dark gradient placeholder is used
  /// so the capture pipeline always has something to screenshot.
  final Widget Function()? fallbackBuilder;

  const FoodImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.fallbackBuilder,
  });

  /// True when [u] is a remote URL we should fetch over the network. Anything
  /// not starting with `http` is treated as an on-device file path.
  static bool _isNetwork(String u) =>
      u.startsWith('http://') || u.startsWith('https://');

  Widget _fallback() {
    final builder = fallbackBuilder;
    if (builder != null) return builder();
    // Neutral dark gradient — matches the charcoal canvas family so a
    // missing photo reads as an intentional dark backdrop, not a bug.
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1C2128),
            Color(0xFF0D1117),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final raw = url;
    if (raw == null || raw.trim().isEmpty) {
      return _fallback();
    }
    final src = raw.trim();

    if (_isNetwork(src)) {
      return Image.network(
        src,
        fit: fit,
        // Keeps the previously-decoded frame on screen across rebuilds so a
        // template re-layout never flashes blank mid-capture.
        gaplessPlayback: true,
        // A 404 / DNS failure / decode error falls back to the gradient so
        // the captured PNG is never an empty box.
        errorBuilder: (_, __, ___) => _fallback(),
        // While bytes are in flight (or if the host stalls), show the
        // fallback rather than a spinner — the share-capture screenshots the
        // widget tree and a half-loaded image would capture as blank.
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return _fallback();
        },
      );
    }

    // Local file path (image_picker output, cached download, etc.).
    final file = File(src);
    return Image.file(
      file,
      fit: fit,
      gaplessPlayback: true,
      // File missing / unreadable / not a valid image → gradient fallback.
      errorBuilder: (_, __, ___) => _fallback(),
    );
  }
}
