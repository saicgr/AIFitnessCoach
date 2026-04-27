// =============================================================================
// GymMapSection — modular gym-discovery map for the Discover tab.
//
// CURRENTLY DISABLED: We have not signed an iOS/Android Google Maps API key
// for Zealova. The dependency `google_maps_flutter: ^2.9.0` and `geolocator`
// are intentionally COMMENTED OUT in `pubspec.yaml`. The full implementation
// below is also commented out so the rest of Discover keeps compiling.
//
// Why ship the scaffold now?
//   1. Locks in the placement: GymMapSection lives inside DiscoverScreen as a
//      collapsible card alongside leaderboard/peers/radar.
//   2. Keeps the gym-finder feature gap visible in the codebase so we don't
//      forget — GymBeat's most concrete differentiator.
//   3. Makes future enablement a 3-step task: uncomment pubspec deps, add
//      Maps API key to AndroidManifest + AppDelegate, uncomment this file.
//
// To re-enable:
//   1. `pubspec.yaml`:
//        google_maps_flutter: ^2.9.0
//        geolocator: ^11.0.0
//   2. iOS: add `GMSServices.provideAPIKey(...)` in AppDelegate.swift
//      Android: add `<meta-data android:name="com.google.android.geo.API_KEY"
//               android:value="..."/>` in AndroidManifest.xml
//   3. Uncomment the implementation block below + the import line in
//      `discover_screen.dart` that mounts `<GymMapSection/>`.
//
// Backend endpoint (also TBD):
//   GET /api/v1/discover/gyms?lat=..&lng=..&radius_mi=..&q=..
//   → [ { id, name, lat, lng, distance_mi, equipment: [..], rating } ]
// =============================================================================

import 'package:flutter/material.dart';

/// Visible-but-disabled stub. Renders nothing today; lives in the widget tree
/// so a future PR can swap it for the real map without rewiring callers.
class GymMapSection extends StatelessWidget {
  const GymMapSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/*
// =============================================================================
// REAL IMPLEMENTATION (commented until Maps API key is provisioned)
// =============================================================================
//
// import 'dart:async';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:geolocator/geolocator.dart';
//
// import '../../../core/constants/app_colors.dart';
// import '../../../data/services/api_client.dart';
// import 'gym_search_bar.dart';            // sibling widget — equipment + name search
// import 'gym_pin_card.dart';              // sibling widget — selected-gym summary
//
// /// Modular gym map. Single Riverpod widget — own state, own API call, own UI.
// /// Drop into DiscoverScreen with `const GymMapSection()` and nothing else.
// class GymMapSection extends ConsumerStatefulWidget {
//   const GymMapSection({super.key});
//
//   @override
//   ConsumerState<GymMapSection> createState() => _GymMapSectionState();
// }
//
// class _GymMapSectionState extends ConsumerState<GymMapSection> {
//   final Completer<GoogleMapController> _ctl = Completer();
//   final Set<Marker> _markers = {};
//   LatLng? _here;
//   double _radiusMi = 6;
//   String _query = '';
//   bool _loading = false;
//   String? _error;
//   GymHit? _selected;
//
//   @override
//   void initState() {
//     super.initState();
//     _bootstrap();
//   }
//
//   Future<void> _bootstrap() async {
//     try {
//       // Permission flow handled here — do NOT request location at app launch.
//       final perm = await Geolocator.checkPermission();
//       if (perm == LocationPermission.denied) {
//         await Geolocator.requestPermission();
//       }
//       final pos = await Geolocator.getCurrentPosition();
//       setState(() => _here = LatLng(pos.latitude, pos.longitude));
//       await _fetchGyms();
//     } catch (e) {
//       setState(() => _error = 'Location unavailable');
//     }
//   }
//
//   Future<void> _fetchGyms() async {
//     if (_here == null) return;
//     setState(() => _loading = true);
//     try {
//       final api = ref.read(apiClientProvider);
//       final res = await api.get(
//         '/api/v1/discover/gyms'
//         '?lat=${_here!.latitude}'
//         '&lng=${_here!.longitude}'
//         '&radius_mi=$_radiusMi'
//         '&q=${Uri.encodeQueryComponent(_query)}',
//       );
//       final gyms = (res.data as List)
//           .map((g) => GymHit.fromJson(g as Map<String, dynamic>))
//           .toList();
//       setState(() {
//         _markers
//           ..clear()
//           ..addAll(gyms.map((g) => Marker(
//                 markerId: MarkerId(g.id),
//                 position: LatLng(g.lat, g.lng),
//                 infoWindow: InfoWindow(title: g.name),
//                 onTap: () => setState(() => _selected = g),
//               )));
//         _loading = false;
//       });
//     } catch (e) {
//       setState(() {
//         _error = 'Failed to load gyms';
//         _loading = false;
//       });
//     }
//   }
//
//   Future<void> _recenter() async {
//     if (_here == null) return;
//     final c = await _ctl.future;
//     await c.animateCamera(CameraUpdate.newLatLngZoom(_here!, 13));
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//     final accent = isDark ? AppColors.cyan : AppColorsLight.cyan;
//
//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       height: 380,
//       decoration: BoxDecoration(
//         color: isDark ? AppColors.elevated : AppColorsLight.elevated,
//         borderRadius: BorderRadius.circular(16),
//       ),
//       clipBehavior: Clip.antiAlias,
//       child: Stack(
//         children: [
//           if (_here != null)
//             GoogleMap(
//               initialCameraPosition: CameraPosition(target: _here!, zoom: 12),
//               markers: _markers,
//               myLocationEnabled: true,
//               myLocationButtonEnabled: false,
//               zoomControlsEnabled: false,
//               onMapCreated: _ctl.complete,
//             ),
//           Positioned(
//             top: 12, left: 12, right: 12,
//             child: GymSearchBar(
//               onChanged: (q) {
//                 _query = q;
//                 _fetchGyms();
//               },
//             ),
//           ),
//           if (_loading)
//             const Positioned(top: 80, left: 0, right: 0,
//               child: Center(child: CircularProgressIndicator()),
//             ),
//           if (_error != null)
//             Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Text(_error!, style: TextStyle(color: accent)),
//               ),
//             ),
//           Positioned(
//             right: 12, bottom: 12,
//             child: FloatingActionButton.small(
//               heroTag: 'gym_recenter',
//               backgroundColor: accent,
//               onPressed: _recenter,
//               child: const Icon(Icons.my_location_rounded, color: Colors.white),
//             ),
//           ),
//           if (_selected != null)
//             Positioned(
//               left: 12, right: 12, bottom: 12,
//               child: GymPinCard(
//                 gym: _selected!,
//                 onClose: () => setState(() => _selected = null),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }
//
// class GymHit {
//   final String id;
//   final String name;
//   final double lat;
//   final double lng;
//   final double distanceMi;
//   final List<String> equipment;
//   final double? rating;
//
//   GymHit({
//     required this.id,
//     required this.name,
//     required this.lat,
//     required this.lng,
//     required this.distanceMi,
//     required this.equipment,
//     this.rating,
//   });
//
//   factory GymHit.fromJson(Map<String, dynamic> j) => GymHit(
//         id: j['id'] as String,
//         name: j['name'] as String,
//         lat: (j['lat'] as num).toDouble(),
//         lng: (j['lng'] as num).toDouble(),
//         distanceMi: (j['distance_mi'] as num).toDouble(),
//         equipment: List<String>.from(j['equipment'] as List? ?? const []),
//         rating: (j['rating'] as num?)?.toDouble(),
//       );
// }
*/
