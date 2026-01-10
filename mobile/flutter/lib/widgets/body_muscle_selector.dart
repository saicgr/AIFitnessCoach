import 'package:flutter/material.dart';
import 'package:muscle_selector/muscle_selector.dart';
import '../core/constants/app_colors.dart';

/// Mapping from muscle_selector package group names to our backend muscle names
const Map<String, String> packageGroupToBackendMuscle = {
  'chest': 'chest',
  'shoulders': 'shoulders',
  'obliques': 'obliques',
  'abs': 'abs',
  'abductor': 'abductors',
  'biceps': 'biceps',
  'calves': 'calves',
  'forearm': 'forearms',
  'glutes': 'glutes',
  'harmstrings': 'hamstrings', // Note: package has typo "harmstrings"
  'lats': 'lats',
  'upper_back': 'upper_back',
  'quads': 'quadriceps',
  'trapezius': 'traps',
  'triceps': 'triceps',
  'adductors': 'adductors',
  'lower_back': 'lower_back',
  'neck': 'core', // Map neck to core for now
};

/// Reverse mapping from backend muscle names to package group names
const Map<String, String> backendMuscleToPackageGroup = {
  'chest': 'chest',
  'shoulders': 'shoulders',
  'obliques': 'obliques',
  'abs': 'abs',
  'abductors': 'abductor',
  'biceps': 'biceps',
  'calves': 'calves',
  'forearms': 'forearm',
  'glutes': 'glutes',
  'hamstrings': 'harmstrings', // Package has typo
  'lats': 'lats',
  'upper_back': 'upper_back',
  'quadriceps': 'quads',
  'traps': 'trapezius',
  'triceps': 'triceps',
  'adductors': 'adductors',
  'lower_back': 'lower_back',
  'core': 'neck',
  'hip_flexors': 'abs', // Map to abs region
};

/// Get display name for muscle
String getMuscleDisplayName(String muscle) {
  return muscle
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) =>
          word.isNotEmpty ? '${word[0].toUpperCase()}${word.substring(1)}' : '')
      .join(' ');
}

/// Get muscle group name from a Muscle object
String? getMuscleGroupFromMuscle(Muscle muscle) {
  // The muscle id is like "chest1", "chest2", etc.
  // We need to find which group it belongs to
  final muscleGroups = {
    'chest': ['chest1', 'chest2'],
    'shoulders': ['shoulder1', 'shoulder2', 'shoulder3', 'shoulder4'],
    'obliques': ['obliques1', 'obliques2'],
    'abs': ['abs1', 'abs2', 'abs3', 'abs4', 'abs5', 'abs6', 'abs7', 'abs8'],
    'abductor': ['abductor1', 'abductor2'],
    'biceps': ['biceps1', 'biceps2'],
    'calves': ['calves1', 'calves2', 'calves3', 'calves4'],
    'forearm': ['forearm1', 'forearm2', 'forearm3', 'forearm4'],
    'glutes': ['glutes1', 'glutes2'],
    'harmstrings': ['harmstrings1', 'harmstrings2'],
    'lats': ['lats1', 'lats2'],
    'upper_back': ['upper_back1', 'upper_back2'],
    'quads': ['quads1', 'quads2', 'quads3', 'quads4'],
    'trapezius': [
      'trapezius1',
      'trapezius2',
      'trapezius3',
      'trapezius4',
      'trapezius5'
    ],
    'triceps': ['triceps1', 'triceps2'],
    'adductors': ['adductors1', 'adductors2'],
    'lower_back': ['lower_back'],
    'neck': ['neck'],
  };

  for (final entry in muscleGroups.entries) {
    if (entry.value.contains(muscle.id)) {
      return entry.key;
    }
  }
  return null;
}

/// Interactive body diagram for selecting muscles using the muscle_selector package
class BodyMuscleSelectorWidget extends StatefulWidget {
  final Set<String> selectedMuscles;
  final Function(String muscle) onMuscleToggle;
  final double height;

  const BodyMuscleSelectorWidget({
    super.key,
    required this.selectedMuscles,
    required this.onMuscleToggle,
    this.height = 400,
  });

  @override
  State<BodyMuscleSelectorWidget> createState() =>
      _BodyMuscleSelectorWidgetState();
}

class _BodyMuscleSelectorWidgetState extends State<BodyMuscleSelectorWidget> {
  final GlobalKey<MusclePickerMapState> _mapKey = GlobalKey();
  bool _isLoaded = false;

  // Convert backend muscle names to package group names for initial selection
  List<String> get _initialGroups => widget.selectedMuscles
      .map((m) => backendMuscleToPackageGroup[m])
      .whereType<String>()
      .toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;

    return Column(
      children: [
        // Body diagram with interactive viewer for zoom/pan
        Container(
          height: widget.height,
          width: double.infinity,
          decoration: BoxDecoration(
            color: backgroundColor.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Calculate dimensions to fit the body diagram
                final availableWidth = constraints.maxWidth;
                final availableHeight = constraints.maxHeight;

                // The body SVG is roughly 2:3 aspect ratio (width:height)
                // Use more of the available space for larger body models
                final bodyWidth = availableHeight * 0.85;
                final bodyHeight = availableHeight;

                return Stack(
                  children: [
                    // Loading indicator (shown until map loads)
                    if (!_isLoaded)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(
                              color: AppColors.cyan,
                              strokeWidth: 2,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Loading body diagram...',
                              style: TextStyle(
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Body map
                    Center(
                      child: SizedBox(
                        width: availableWidth,
                        height: availableHeight,
                        child: InteractiveViewer(
                          minScale: 0.8,
                          maxScale: 2.5,
                          child: Center(
                            child: MusclePickerMap(
                              key: _mapKey,
                              map: Maps.BODY,
                              width: bodyWidth,
                              height: bodyHeight,
                              onChanged: (muscles) {
                                if (!_isLoaded) {
                                  setState(() => _isLoaded = true);
                                }
                                _handleMuscleChange(muscles);
                              },
                              actAsToggle: true,
                              dotColor: AppColors.cyan,
                              selectedColor: AppColors.error.withValues(alpha: 0.7),
                              strokeColor: isDark
                                  ? Colors.white.withValues(alpha: 0.4)
                                  : Colors.black.withValues(alpha: 0.4),
                              initialSelectedGroups: _initialGroups,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // Instruction text
        const SizedBox(height: 12),
        Text(
          'Tap on a muscle to select • Pinch to zoom',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  void _handleMuscleChange(Set<Muscle> muscles) {
    // Find what changed (added or removed)
    final newGroups = <String>{};

    for (final muscle in muscles) {
      final group = getMuscleGroupFromMuscle(muscle);
      if (group != null) {
        newGroups.add(group);
      }
    }

    // Convert to backend muscle names
    final newBackendMuscles = newGroups
        .map((g) => packageGroupToBackendMuscle[g])
        .whereType<String>()
        .toSet();

    // Find what was added or removed
    final currentBackendMuscles = widget.selectedMuscles;

    // Find newly added muscles
    for (final muscle in newBackendMuscles) {
      if (!currentBackendMuscles.contains(muscle)) {
        widget.onMuscleToggle(muscle);
        return; // Only toggle one at a time
      }
    }

    // Find removed muscles
    for (final muscle in currentBackendMuscles) {
      if (!newBackendMuscles.contains(muscle)) {
        widget.onMuscleToggle(muscle);
        return; // Only toggle one at a time
      }
    }
  }
}
