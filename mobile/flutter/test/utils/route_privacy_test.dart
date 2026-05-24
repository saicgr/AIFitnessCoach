// route_privacy_test.dart
//
// Tests for the haversine-based polyline trim used to anonymize the start
// and end of a recorded GPS route before rendering on the synced workout
// detail screen.

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

import 'package:fitwiz/utils/route_privacy.dart';

// Reference point near San Francisco; we generate synthetic straight-line
// routes east of it using a coarse "1 degree of longitude ≈ 78,847m at
// latitude 37.77°" approximation. We DO use real haversine inside the
// implementation, so the expected trim metres won't be perfect — tests
// allow generous tolerances rather than assert exact-distance equality.
const double _baseLat = 37.7749;
const double _baseLng = -122.4194;

// Roughly 1 meter east at this latitude.
const double _oneMeterDegLng = 1.0 / 87000.0;

List<LatLng> _straightEast(int lengthMeters, {int sampleEveryMeters = 10}) {
  final pts = <LatLng>[];
  for (int m = 0; m <= lengthMeters; m += sampleEveryMeters) {
    pts.add(LatLng(_baseLat, _baseLng + m * _oneMeterDegLng));
  }
  return pts;
}

void main() {
  group('obfuscatePolyline', () {
    test('empty input returns empty', () {
      expect(obfuscatePolyline(const [], 200), isEmpty);
    });

    test('single-point input returns empty (cannot draw line from 1 pt)', () {
      expect(
        obfuscatePolyline([const LatLng(_baseLat, _baseLng)], 200),
        isEmpty,
      );
    });

    test('hideMeters <= 0 returns the route unchanged', () {
      final route = _straightEast(1000);
      final result = obfuscatePolyline(route, 0);
      expect(result.length, route.length);
      expect(result.first, route.first);
      expect(result.last, route.last);
    });

    test('hideMeters negative also returns route unchanged (no-op)', () {
      final route = _straightEast(1000);
      expect(obfuscatePolyline(route, -50).length, route.length);
    });

    test('100m route with 200m obfuscation collapses to []', () {
      final route = _straightEast(100, sampleEveryMeters: 5);
      expect(obfuscatePolyline(route, 200), isEmpty);
    });

    test('exactly 200m route with 200m obfuscation collapses to []', () {
      // 2 * hideMeters → trims meet in the middle, no interior survives.
      final route = _straightEast(200, sampleEveryMeters: 5);
      expect(obfuscatePolyline(route, 200), isEmpty);
    });

    test('1km route with 200m trim keeps ~600m middle and surviving >=2 pts',
        () {
      final route = _straightEast(1000, sampleEveryMeters: 10);
      final trimmed = obfuscatePolyline(route, 200);

      // Must have at least 2 points to render as a polyline.
      expect(trimmed.length, greaterThanOrEqualTo(2));

      // First surviving point should be > 180m east of start (allow some
      // sample-quantization slack since we trim whole points).
      const Distance distance = Distance();
      final startTrimMeters = distance(route.first, trimmed.first);
      expect(startTrimMeters, greaterThanOrEqualTo(180));
      expect(startTrimMeters, lessThanOrEqualTo(260));

      // Same on the tail.
      final endTrimMeters = distance(route.last, trimmed.last);
      expect(endTrimMeters, greaterThanOrEqualTo(180));
      expect(endTrimMeters, lessThanOrEqualTo(260));
    });

    test('5km route with 200m trim returns the unmodifiable middle list', () {
      final route = _straightEast(5000, sampleEveryMeters: 25);
      final trimmed = obfuscatePolyline(route, 200);
      expect(trimmed.length, greaterThan(100));
      // Returned list is unmodifiable — guards callers against mutating
      // the trimmed result back into the original buffer.
      expect(() => trimmed.add(const LatLng(0, 0)), throwsUnsupportedError);
    });

    test('returns [] when start trim and end trim overlap (route < 2*hide)',
        () {
      // 300m route, 200m trim from each end → 400m of trim needed in 300m
      // available → overlap → empty.
      final route = _straightEast(300, sampleEveryMeters: 5);
      expect(obfuscatePolyline(route, 200), isEmpty);
    });
  });
}
