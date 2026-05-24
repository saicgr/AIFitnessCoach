// route_map.dart
//
// flutter_map polyline renderer for HealthKit GPS-recorded outdoor activity
// routes. Renders over the free OpenStreetMap tile server with the required
// attribution overlay.
//
// iOS GPS re-add — Google Play scope declaration pending; Android map UI
// hidden via `Platform.isIOS` gate. On Android we render an inline
// `EmptyRouteState` rather than the map so we don't surface a feature the
// platform doesn't yet support.
//
// Usage:
//   RouteMap(
//     polyline: latLngList,            // full recorded polyline
//     obfuscateMeters: user.routePrivacyMeters ?? 200,
//     sportKind: 'running',            // for the empty-state icon
//   )
//
// SLICE_GPS — composer agent will wire this into
// `lib/screens/profile/synced_workout_detail_screen.dart`. Do not import
// it from that screen here.

import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/accent_color_provider.dart';
import '../../utils/route_privacy.dart';

class RouteMap extends StatelessWidget {
  /// Full recorded polyline. Will be trimmed by [obfuscateMeters] before
  /// rendering. Pass an empty list to render [EmptyRouteState] directly.
  final List<LatLng> polyline;

  /// Distance in meters to hide from the start AND end of the route to
  /// anonymize the user's home/work address. Defaults to 200m which matches
  /// the `public.users.route_privacy_meters` column default (migration 2094).
  final int obfuscateMeters;

  /// Optional sport kind ('running', 'cycling', 'walking', 'hiking', …).
  /// Used to pick the empty-state icon. Falls back to a generic activity
  /// icon when unknown.
  final String? sportKind;

  /// Map widget height. The synced workout detail screen renders this in a
  /// scrollable column so a fixed height is appropriate.
  final double height;

  const RouteMap({
    super.key,
    required this.polyline,
    this.obfuscateMeters = 200,
    this.sportKind,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    // Android: GPS route capture / display is intentionally gated off until
    // Google Play scope declaration lands. Show a tidy empty state instead.
    if (!Platform.isIOS) {
      return EmptyRouteState(
        sportKind: sportKind,
        message: 'Outdoor route maps are coming to Android soon.',
        height: height,
      );
    }

    // No GPS captured for this workout (indoor activity, treadmill, gym
    // session with HR-only). Show the indoor empty state.
    if (polyline.isEmpty) {
      return EmptyRouteState(sportKind: sportKind, height: height);
    }

    final trimmed = obfuscatePolyline(polyline, obfuscateMeters);

    // Route exists but is shorter than 2 × obfuscateMeters → nothing
    // meaningful remains after privacy trim. Surface that explicitly so the
    // user knows their route IS recorded; we just can't draw a private
    // version of it.
    if (trimmed.length < 2) {
      return EmptyRouteState(
        sportKind: sportKind,
        message: 'Route too short to display privately.',
        height: height,
      );
    }

    return SizedBox(
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                // Auto-fit bounds to the trimmed polyline with a small inset
                // so the polyline doesn't kiss the edge of the tile.
                initialCameraFit: CameraFit.coordinates(
                  coordinates: trimmed,
                  padding: const EdgeInsets.all(24),
                ),
                interactionOptions: const InteractionOptions(
                  // Allow pan / pinch-zoom; disable rotation since the
                  // route doesn't have a meaningful "up" we want to lock.
                  flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  // OSM tile usage policy requires a real UA per app — use
                  // our reverse-DNS bundle id. See:
                  // https://operations.osmfoundation.org/policies/tiles/
                  userAgentPackageName: 'com.aifitnesscoach.app',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: trimmed,
                      strokeWidth: 4.0,
                      color: accent,
                      borderStrokeWidth: 1.5,
                      borderColor: Colors.white.withValues(alpha: 0.9),
                    ),
                  ],
                ),
              ],
            ),
            // Required OSM attribution. Pinned to bottom-right with a
            // semi-transparent pill so it stays legible over both light and
            // dark map tiles.
            Positioned(
              right: 6,
              bottom: 6,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.black.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Inline empty state shown when there is no polyline to render. The
/// synced-workout detail composer can call this directly with a custom
/// `message` when, for example, a workout has been imported but route
/// fetching hasn't completed.
class EmptyRouteState extends StatelessWidget {
  final String? sportKind;
  final String message;
  final double height;

  const EmptyRouteState({
    super.key,
    this.sportKind,
    this.message = 'Route not recorded (indoor activity)',
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return SizedBox(
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.4 : 0.6,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForSport(sportKind),
                size: 36,
                color: accent.withValues(alpha: 0.75),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Match the per-kind iconography used elsewhere in the synced-workout
  /// UI. Unknown / null kind → generic fitness icon.
  IconData _iconForSport(String? kind) {
    switch (kind) {
      case 'running':
        return Icons.directions_run;
      case 'walking':
        return Icons.directions_walk;
      case 'cycling':
        return Icons.directions_bike;
      case 'hiking':
        return Icons.terrain;
      case 'swimming':
        return Icons.pool;
      case 'rowing':
        return Icons.rowing;
      default:
        return Icons.fitness_center;
    }
  }
}
