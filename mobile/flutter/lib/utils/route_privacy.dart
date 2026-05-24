// route_privacy.dart
//
// Pure-function helpers for obfuscating GPS polylines before rendering.
//
// Why this exists:
//   Runners frequently start and end an outdoor activity at their home or
//   office. Rendering the raw polyline leaks that address. The widely-used
//   privacy convention (Strava, Garmin) is to hide the first and last N
//   meters of the route. The user-configurable value lives at
//   `public.users.route_privacy_meters` (default 200, migration 2094).
//
// Caller contract:
//   - Input `points` is the full polyline in walked/recorded order.
//   - `hideMeters` is total distance to trim from EACH end (start AND end).
//   - Returns the trimmed middle. If trimming leaves <2 points, returns []
//     so the widget can render a "Route too short to display privately"
//     empty state instead of a single dot.
//   - Pure, no I/O, no side effects — safe to unit-test offline.
//
// SLICE_GPS — iOS GPS re-add — Google Play scope declaration pending;
// Android map UI hidden via Platform.isIOS gate in route_map.dart.

import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Trim the first and last [hideMeters] of [points] using cumulative haversine
/// distance from each end. The trimming is independent on each side, so a
/// route shorter than `2 * hideMeters` returns an empty list.
///
/// Edge cases handled explicitly:
///   * [points] empty or length 1 → returns []
///   * [hideMeters] <= 0 → returns the original list as-is
///   * Trimming would leave <2 surviving points → returns []
///   * Exactly `2 * hideMeters` long route → returns [] (caller renders
///     empty state — there is no meaningful interior to show)
///
/// This is intentionally a coarse trim — we drop whole sample points rather
/// than interpolating between them. With Apple Watch's ~1 sample/sec GPS
/// stream that's ≤ 1–2m of imprecision at the trim boundary, well inside the
/// 200m default privacy radius.
List<LatLng> obfuscatePolyline(List<LatLng> points, int hideMeters) {
  // Guard: nothing to do for tiny inputs.
  if (points.length < 2) return const [];
  if (hideMeters <= 0) return List<LatLng>.unmodifiable(points);

  final hide = hideMeters.toDouble();

  // --- Walk forward from index 0 accumulating distance until we've covered
  // `hide` meters. The first surviving point is the one *after* the cutoff.
  int firstKeep = -1;
  double acc = 0;
  for (int i = 1; i < points.length; i++) {
    acc += _haversineMeters(points[i - 1], points[i]);
    if (acc >= hide) {
      firstKeep = i;
      break;
    }
  }
  // Whole route shorter than `hideMeters` from start → nothing survives.
  if (firstKeep < 0) return const [];

  // --- Walk backward from the last index accumulating distance until we've
  // covered `hide` meters. The last surviving point is the one *before* the
  // cutoff.
  int lastKeep = -1;
  acc = 0;
  for (int i = points.length - 2; i >= 0; i--) {
    acc += _haversineMeters(points[i + 1], points[i]);
    if (acc >= hide) {
      lastKeep = i;
      break;
    }
  }
  if (lastKeep < 0) return const [];

  // Trims overlap or collapse — no meaningful middle remains.
  if (lastKeep <= firstKeep) return const [];

  final trimmed = points.sublist(firstKeep, lastKeep + 1);
  // Final guard — sublist could still be <2 if firstKeep == lastKeep.
  if (trimmed.length < 2) return const [];
  return List<LatLng>.unmodifiable(trimmed);
}

/// Haversine distance in meters between two lat/lng pairs.
/// Earth radius 6,371,000m. Plenty precise at the sub-km scale we care about.
double _haversineMeters(LatLng a, LatLng b) {
  const earthRadiusM = 6371000.0;
  final lat1 = _toRad(a.latitude);
  final lat2 = _toRad(b.latitude);
  final dLat = _toRad(b.latitude - a.latitude);
  final dLng = _toRad(b.longitude - a.longitude);
  final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) *
          math.cos(lat2) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
  return earthRadiusM * c;
}

double _toRad(double deg) => deg * math.pi / 180.0;
