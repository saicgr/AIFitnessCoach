import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

/// Photo color-palette extractor for shareable "doc" cards.
///
/// Given the user's meal photo (a local file path, an https URL, or null),
/// this decodes the image, downsamples it, and buckets its pixels into the
/// handful of most prominent distinct colors. The result is used to seed the
/// shareable card editor's background tones and accent color so generated
/// cards visually match the food in the photo.
///
/// Everything here is fail-soft: any decode/network error, an unreadable
/// file, or a null source returns a sensible neutral default palette so the
/// editor always has usable colors to render with.

/// Neutral fallback palette — a few dark tones plus a warm accent.
/// Ordered by prominence (darkest/base first, accent last).
const List<Color> _defaultPalette = <Color>[
  Color(0xFF1C1C1E), // near-black base
  Color(0xFF2C2C2E), // dark surface
  Color(0xFF3A3A3C), // mid surface
  Color(0xFF8E8E93), // muted gray
  Color(0xFFFF8A3D), // warm accent
];

/// Default accent used when no vibrant swatch can be derived.
const Color _defaultAccent = Color(0xFFFF8A3D);

/// Target longest-edge size for downsampling before quantization.
const int _downsampleSize = 64;

/// Number of swatches to return.
const int _paletteSize = 5;

/// Bits kept per channel when bucketing (3 bits => 8 levels per channel,
/// 512 possible buckets). Coarse enough to merge perceptually similar pixels.
const int _quantBits = 3;

/// Extracts up to [_paletteSize] prominent, distinct colors from [source].
///
/// [source] may be:
///   * a local filesystem path (decoded via `dart:io` File bytes),
///   * an `https`/`http` URL (fetched via `dart:io` HttpClient),
///   * `null`.
///
/// Near-white and near-black pixels are skipped as noise so the returned
/// swatches are usable as card background/accent colors. On any failure the
/// neutral [_defaultPalette] is returned.
Future<List<Color>> extractCardPalette(String? source) async {
  if (source == null || source.trim().isEmpty) {
    return List<Color>.from(_defaultPalette);
  }

  try {
    final Uint8List? bytes = await _loadBytes(source.trim());
    if (bytes == null || bytes.isEmpty) {
      return List<Color>.from(_defaultPalette);
    }

    img.Image? decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return List<Color>.from(_defaultPalette);
    }

    // Downsample so quantization is cheap and pixel-level noise is averaged out.
    final int longestEdge = math.max(decoded.width, decoded.height);
    if (longestEdge > _downsampleSize) {
      final bool widthIsLongest = decoded.width >= decoded.height;
      decoded = img.copyResize(
        decoded,
        width: widthIsLongest ? _downsampleSize : null,
        height: widthIsLongest ? null : _downsampleSize,
        interpolation: img.Interpolation.average,
      );
    }

    final List<Color> palette = _quantize(decoded);
    if (palette.isEmpty) {
      return List<Color>.from(_defaultPalette);
    }

    // Pad with defaults if the photo yielded fewer than _paletteSize colors
    // (e.g. a very monochrome image) so callers always get a full palette.
    if (palette.length < _paletteSize) {
      for (final Color fallback in _defaultPalette) {
        if (palette.length >= _paletteSize) break;
        if (!palette.any((Color c) => _colorDistance(c, fallback) < 24)) {
          palette.add(fallback);
        }
      }
    }

    return palette.take(_paletteSize).toList(growable: false);
  } catch (_) {
    // Fail-soft: never let a bad photo break the editor.
    return List<Color>.from(_defaultPalette);
  }
}

/// Returns the most vibrant (high-saturation, reasonable-lightness) swatch
/// from [palette], which makes a good accent color. Falls back to
/// [_defaultAccent] when [palette] is empty or contains no vibrant color.
Color suggestedAccent(List<Color> palette) {
  if (palette.isEmpty) {
    return _defaultAccent;
  }

  Color? best;
  double bestScore = -1;

  for (final Color color in palette) {
    final HSLColor hsl = HSLColor.fromColor(color);

    // Penalize colors that are too dark or too light to read as an accent.
    final double lightnessFitness = 1.0 - (hsl.lightness - 0.5).abs() * 2.0;
    final double score =
        hsl.saturation * 0.75 + math.max(0.0, lightnessFitness) * 0.25;

    if (score > bestScore) {
      bestScore = score;
      best = color;
    }
  }

  // If even the "best" swatch is essentially gray, prefer the default accent.
  if (best == null || HSLColor.fromColor(best).saturation < 0.15) {
    return _defaultAccent;
  }
  return best;
}

/// Loads raw image bytes from a local path or an http(s) URL.
/// Returns `null` if the source cannot be read.
Future<Uint8List?> _loadBytes(String source) async {
  final Uri? uri = Uri.tryParse(source);
  final bool isRemote =
      uri != null && (uri.scheme == 'https' || uri.scheme == 'http');

  if (isRemote) {
    final HttpClient client = HttpClient();
    try {
      client.connectionTimeout = const Duration(seconds: 10);
      final HttpClientRequest request = await client.getUrl(uri);
      final HttpClientResponse response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        return null;
      }
      final List<int> collected = <int>[];
      await for (final List<int> chunk in response) {
        collected.addAll(chunk);
      }
      return Uint8List.fromList(collected);
    } finally {
      client.close(force: true);
    }
  }

  // Treat anything else as a local file path.
  final File file = File(source);
  if (!await file.exists()) {
    return null;
  }
  return file.readAsBytes();
}

/// Buckets the pixels of [image] into coarse color cells, drops near-white and
/// near-black noise, and returns the most populated buckets as [Color]s
/// ordered by prominence (most pixels first). Visually near-duplicate
/// swatches are merged so the returned palette is distinct.
List<Color> _quantize(img.Image image) {
  final int shift = 8 - _quantBits;
  final Map<int, _Bucket> buckets = <int, _Bucket>{};

  for (final img.Pixel pixel in image) {
    final int r = pixel.r.toInt();
    final int g = pixel.g.toInt();
    final int b = pixel.b.toInt();
    final int a = pixel.a.toInt();

    // Skip fully/mostly transparent pixels.
    if (a < 16) continue;

    // Skip near-white and near-black noise so swatches stay usable.
    final int luma = ((r * 299) + (g * 587) + (b * 114)) ~/ 1000;
    if (luma >= 244 || luma <= 12) continue;

    final int key =
        ((r >> shift) << (_quantBits * 2)) |
        ((g >> shift) << _quantBits) |
        (b >> shift);

    final _Bucket bucket = buckets.putIfAbsent(key, () => _Bucket());
    bucket.add(r, g, b);
  }

  if (buckets.isEmpty) {
    return <Color>[];
  }

  // Most populated buckets first.
  final List<_Bucket> ranked = buckets.values.toList()
    ..sort((_Bucket x, _Bucket y) => y.count.compareTo(x.count));

  final List<Color> result = <Color>[];
  for (final _Bucket bucket in ranked) {
    final Color color = bucket.averageColor();
    // Merge swatches that are perceptually too close to an already-picked one.
    final bool duplicate =
        result.any((Color c) => _colorDistance(c, color) < 40);
    if (duplicate) continue;
    result.add(color);
    if (result.length >= _paletteSize) break;
  }
  return result;
}

/// Simple Euclidean distance in RGB space, used to detect near-duplicate
/// swatches. Cheap and good enough for palette de-duplication.
double _colorDistance(Color a, Color b) {
  final int dr = _channel8(a.r) - _channel8(b.r);
  final int dg = _channel8(a.g) - _channel8(b.g);
  final int db = _channel8(a.b) - _channel8(b.b);
  return math.sqrt((dr * dr + dg * dg + db * db).toDouble());
}

/// Converts a normalized 0..1 color channel to an 0..255 integer.
int _channel8(double normalized) => (normalized * 255.0).round().clamp(0, 255);

/// Accumulator for a single quantization bucket — sums channel values so the
/// final swatch is the average of all pixels that fell into the bucket.
class _Bucket {
  int _sumR = 0;
  int _sumG = 0;
  int _sumB = 0;
  int count = 0;

  void add(int r, int g, int b) {
    _sumR += r;
    _sumG += g;
    _sumB += b;
    count++;
  }

  Color averageColor() {
    if (count == 0) {
      return _defaultPalette.first;
    }
    return Color.fromARGB(
      255,
      (_sumR ~/ count).clamp(0, 255),
      (_sumG ~/ count).clamp(0, 255),
      (_sumB ~/ count).clamp(0, 255),
    );
  }
}
