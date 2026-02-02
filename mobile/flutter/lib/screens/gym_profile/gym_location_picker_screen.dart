import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/gym_location.dart';
import '../../data/providers/location_permission_provider.dart';
import '../../data/providers/location_provider.dart';
import '../../data/providers/places_provider.dart';
import '../../data/services/haptic_service.dart';

/// Full-screen location picker for gym profiles
///
/// Features:
/// - Search for gyms by name (Google Places autocomplete)
/// - Use current location option
/// - Map display to confirm location
class GymLocationPickerScreen extends ConsumerStatefulWidget {
  /// Existing location to edit (if any)
  final GymLocation? initialLocation;

  /// Callback when location is selected
  final void Function(GymLocation location) onLocationSelected;

  const GymLocationPickerScreen({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  ConsumerState<GymLocationPickerScreen> createState() =>
      _GymLocationPickerScreenState();
}

class _GymLocationPickerScreenState
    extends ConsumerState<GymLocationPickerScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  GoogleMapController? _mapController;
  bool _isLoadingCurrentLocation = false;

  @override
  void initState() {
    super.initState();
    // If we have an initial location, set it
    if (widget.initialLocation != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedLocationProvider.notifier).setLocation(widget.initialLocation!);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(placeSearchProvider.notifier).search(query);
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isLoadingCurrentLocation = true);
    HapticService.light();

    try {
      // Check/request permission first
      final hasPermission = await ref.read(hasLocationPermissionProvider.future);
      if (!hasPermission) {
        // Request permission
        final notifier = ref.read(locationPermissionNotifierProvider.notifier);
        await notifier.requestWhenInUsePermission();
      }

      // Use current location
      await ref.read(selectedLocationProvider.notifier).useCurrentLocation();

      // Clear search
      _searchController.clear();
      ref.read(placeSearchProvider.notifier).clear();
      _searchFocusNode.unfocus();
    } finally {
      if (mounted) {
        setState(() => _isLoadingCurrentLocation = false);
      }
    }
  }

  void _selectPrediction(PlacePrediction prediction) {
    HapticService.light();
    _searchController.clear();
    ref.read(placeSearchProvider.notifier).clear();
    _searchFocusNode.unfocus();
    ref.read(selectedLocationProvider.notifier).selectFromPrediction(prediction);
  }

  void _confirmLocation() {
    final selectedState = ref.read(selectedLocationProvider);
    if (selectedState.location != null) {
      HapticService.success();
      widget.onLocationSelected(selectedState.location!);
      Navigator.of(context).pop();
    }
  }

  void _clearLocation() {
    ref.read(selectedLocationProvider.notifier).clear();
    HapticService.light();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.background : AppColorsLight.background;
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    final searchState = ref.watch(placeSearchProvider);
    final selectedState = ref.watch(selectedLocationProvider);
    final isConfigured = ref.watch(isPlacesApiConfiguredProvider);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: elevatedColor,
        title: Text(
          'Set Gym Location',
          style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search section
          Container(
            color: elevatedColor,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                // Search field
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  onChanged: _onSearchChanged,
                  style: TextStyle(color: textPrimary, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: isConfigured
                        ? 'Search for your gym (e.g., "Anytime Fitness")'
                        : 'Google Maps API key required',
                    hintStyle: TextStyle(color: textSecondary.withOpacity(0.6)),
                    prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear_rounded, color: textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(placeSearchProvider.notifier).clear();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.black.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  enabled: isConfigured,
                ),

                // API key warning
                if (!isConfigured) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Google Maps API key not configured. Add your key to enable gym search.',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Search results or map
          Expanded(
            child: searchState.predictions.isNotEmpty
                ? _buildSearchResults(searchState, isDark, textPrimary, textSecondary, accentColor)
                : _buildMapSection(selectedState, isDark, textPrimary, textSecondary, accentColor, elevatedColor),
          ),

          // Bottom section with confirm button
          _buildBottomSection(selectedState, isDark, textPrimary, textSecondary, accentColor, elevatedColor),
        ],
      ),
    );
  }

  Widget _buildSearchResults(
    PlaceSearchState searchState,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: searchState.predictions.length,
      itemBuilder: (context, index) {
        final prediction = searchState.predictions[index];
        return ListTile(
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.place_rounded, color: accentColor, size: 20),
          ),
          title: Text(
            prediction.mainText,
            style: TextStyle(
              color: textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                prediction.secondaryText,
                style: TextStyle(color: textSecondary, fontSize: 13),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (prediction.formattedDistance != null) ...[
                const SizedBox(height: 2),
                Text(
                  prediction.formattedDistance!,
                  style: TextStyle(color: accentColor, fontSize: 12),
                ),
              ],
            ],
          ),
          onTap: () => _selectPrediction(prediction),
        );
      },
    );
  }

  Widget _buildMapSection(
    SelectedLocationState selectedState,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color elevatedColor,
  ) {
    return Column(
      children: [
        // Use current location button
        Padding(
          padding: const EdgeInsets.all(16),
          child: InkWell(
            onTap: _isLoadingCurrentLocation ? null : _useCurrentLocation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isLoadingCurrentLocation)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: accentColor,
                      ),
                    )
                  else
                    Icon(Icons.my_location_rounded, color: accentColor),
                  const SizedBox(width: 12),
                  Text(
                    _isLoadingCurrentLocation
                        ? 'Getting location...'
                        : 'Use Current Location',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Divider
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              Expanded(child: Divider(color: textSecondary.withOpacity(0.3))),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'or search above',
                  style: TextStyle(color: textSecondary, fontSize: 12),
                ),
              ),
              Expanded(child: Divider(color: textSecondary.withOpacity(0.3))),
            ],
          ),
        ),

        // Map or placeholder
        Expanded(
          child: selectedState.location != null && selectedState.location!.hasValidCoordinates
              ? _buildMap(selectedState.location!, isDark, accentColor)
              : _buildMapPlaceholder(isDark, textSecondary),
        ),
      ],
    );
  }

  Widget _buildMap(GymLocation location, bool isDark, Color accentColor) {
    final position = LatLng(location.latitude, location.longitude);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: position,
            zoom: 16,
          ),
          onMapCreated: (controller) {
            _mapController = controller;
            // Apply dark style if needed
            if (isDark) {
              controller.setMapStyle(_darkMapStyle);
            }
          },
          markers: {
            Marker(
              markerId: const MarkerId('selected'),
              position: position,
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
            ),
          },
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
        ),
      ),
    );
  }

  Widget _buildMapPlaceholder(bool isDark, Color textSecondary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.map_rounded,
            size: 64,
            color: textSecondary.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Search for a gym or use\nyour current location',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection(
    SelectedLocationState selectedState,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
    Color accentColor,
    Color elevatedColor,
  ) {
    final hasLocation = selectedState.location != null;
    final isLoading = selectedState.isLoading;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: elevatedColor,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Selected location info
            if (hasLocation && !isLoading) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.place_rounded, color: accentColor, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedState.location!.name,
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          if (selectedState.location!.address.isNotEmpty)
                            Text(
                              selectedState.location!.address,
                              style: TextStyle(color: textSecondary, fontSize: 12),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: _clearLocation,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Error message
            if (selectedState.error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        selectedState.error!,
                        style: const TextStyle(color: Colors.red, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Confirm button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: hasLocation && !isLoading ? _confirmLocation : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: accentColor.withOpacity(0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Confirm Location',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Dark mode map style
  static const String _darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#212121"}]
  },
  {
    "elementType": "labels.icon",
    "stylers": [{"visibility": "off"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#212121"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#757575"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [{"color": "#181818"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#616161"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#2c2c2c"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8a8a8a"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry",
    "stylers": [{"color": "#373737"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [{"color": "#3c3c3c"}]
  },
  {
    "featureType": "road.highway.controlled_access",
    "elementType": "geometry",
    "stylers": [{"color": "#4e4e4e"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [{"color": "#000000"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#3d3d3d"}]
  }
]
''';
}
