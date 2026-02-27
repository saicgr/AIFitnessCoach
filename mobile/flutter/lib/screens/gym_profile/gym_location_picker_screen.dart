import 'package:flutter/material.dart';
import '../../data/models/gym_location.dart';

/// Gym location picker — Google Maps temporarily removed for v1.
/// Re-enable by uncommenting google_maps_flutter in pubspec.yaml
/// and restoring the original implementation.
class GymLocationPickerScreen extends StatelessWidget {
  final GymLocation? initialLocation;
  final void Function(GymLocation location) onLocationSelected;

  const GymLocationPickerScreen({
    super.key,
    this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gym Location')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Map-based location picker is not yet available.\nFor now, set your gym name in the profile.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
