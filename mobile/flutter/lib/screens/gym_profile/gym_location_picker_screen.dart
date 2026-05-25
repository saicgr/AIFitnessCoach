import 'package:flutter/material.dart';
import '../../data/models/gym_location.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
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
      appBar: PillAppBar(
        title: AppLocalizations.of(context).gymLocationPickerGymLocation,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            AppLocalizations.of(context).gymLocationPickerMapBasedLocationPicker,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
