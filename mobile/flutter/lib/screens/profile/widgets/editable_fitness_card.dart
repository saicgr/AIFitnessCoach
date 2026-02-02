import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/warmup_duration_provider.dart';
import '../../../data/models/gym_profile.dart';
import '../../../data/providers/gym_profile_provider.dart';
import '../../../data/providers/today_workout_provider.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/api_client.dart';
import '../../home/widgets/manage_gym_profiles_sheet.dart';

/// Editable fitness card with inline editing for goal, level, days, and injuries.
class EditableFitnessCard extends ConsumerStatefulWidget {
  final dynamic user;

  const EditableFitnessCard({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditableFitnessCard> createState() => _EditableFitnessCardState();
}

class _EditableFitnessCardState extends ConsumerState<EditableFitnessCard> {
  bool _isEditing = false;
  bool _isSaving = false;

  String _selectedLevel = 'Intermediate';
  String _selectedGoal = 'Build Muscle';
  List<int> _selectedDays = [];
  List<String> _selectedInjuries = [];
  double _selectedDurationMin = 30; // Duration range min in minutes
  double _selectedDurationMax = 45; // Duration range max in minutes
  int _selectedWarmupDuration = 5; // Warmup duration in minutes (1-15)
  int _selectedStretchDuration = 5; // Stretch duration in minutes (1-15)

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _goalOptions = ['Build Muscle', 'Lose Weight', 'Increase Endurance', 'Stay Active'];
  static const _levelOptions = ['Beginner', 'Intermediate', 'Advanced'];
  static const _warmupStretchOptions = [3, 5, 7, 10, 15]; // Common warmup/stretch durations
  static const _injuryOptions = [
    'Lower Back',
    'Shoulder',
    'Knee',
    'Neck',
    'Wrist',
    'Ankle',
    'Hip',
    'Elbow',
  ];

  @override
  void initState() {
    super.initState();
    _loadValues();
  }

  void _loadValues() {
    if (widget.user != null) {
      _selectedLevel = widget.user.fitnessLevel ?? 'Intermediate';
      _selectedGoal = widget.user.fitnessGoal ?? 'Build Muscle';
      _selectedDays = List<int>.from(widget.user.workoutDays ?? []);
      _selectedInjuries = List<String>.from(widget.user.injuriesList ?? []);
    }
    // Load duration range from active gym profile
    final activeProfile = ref.read(activeGymProfileProvider);
    if (activeProfile != null) {
      _selectedDurationMin = (activeProfile.durationMinutesMin ?? activeProfile.durationMinutes).toDouble();
      _selectedDurationMax = (activeProfile.durationMinutesMax ?? activeProfile.durationMinutes).toDouble();
    }
    // Load warmup and stretch durations
    final warmupState = ref.read(warmupDurationProvider);
    _selectedWarmupDuration = warmupState.warmupDurationMinutes;
    _selectedStretchDuration = warmupState.stretchDurationMinutes;
  }

  /// Format duration range for display
  String _formatDurationDisplay() {
    final min = _selectedDurationMin.round();
    final max = _selectedDurationMax.round();
    if (min == max) {
      return '$min min';
    }
    return '$min-$max min';
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) throw Exception('User not found');

      // Save user fitness settings
      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {
          'fitness_level': _selectedLevel,
          'goals': _selectedGoal,
          'days_per_week': _selectedDays.length,
          'workout_days': _selectedDays,
          'active_injuries': _selectedInjuries,
        },
      );

      // Update gym profile duration range if changed
      final activeProfile = ref.read(activeGymProfileProvider);
      if (activeProfile != null) {
        final oldMin = activeProfile.durationMinutesMin ?? activeProfile.durationMinutes;
        final oldMax = activeProfile.durationMinutesMax ?? activeProfile.durationMinutes;
        if (oldMin != _selectedDurationMin.round() || oldMax != _selectedDurationMax.round()) {
          final update = GymProfileUpdate(
            durationMinutes: _selectedDurationMin.round(),
            durationMinutesMin: _selectedDurationMin.round(),
            durationMinutesMax: _selectedDurationMax.round(),
          );
          await ref.read(gymProfilesProvider.notifier).updateProfile(
            activeProfile.id,
            update,
          );
        }
      }

      // Update warmup and stretch durations if changed
      final warmupState = ref.read(warmupDurationProvider);
      if (warmupState.warmupDurationMinutes != _selectedWarmupDuration ||
          warmupState.stretchDurationMinutes != _selectedStretchDuration) {
        await ref.read(warmupDurationProvider.notifier).setBothDurations(
          warmupMinutes: _selectedWarmupDuration,
          stretchMinutes: _selectedStretchDuration,
        );
      }

      await ref.read(authStateProvider.notifier).refreshUser();

      // Invalidate workout providers to trigger regeneration
      ref.invalidate(todayWorkoutProvider);
      ref.invalidate(workoutsProvider);

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitness settings updated - workouts will regenerate'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    // Use monochrome accent
    final accentColor = isDark ? AppColors.accent : AppColorsLight.accent;

    // Watch the active gym profile
    final activeGymProfile = ref.watch(activeGymProfileProvider);

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              // Active Gym (tappable to switch/manage gyms)
              _buildGymRow(
                profile: activeGymProfile,
                isDark: isDark,
                textMuted: textMuted,
                textSecondary: textSecondary,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Duration (editable range)
              _buildEditableRow(
                icon: Icons.timer_outlined,
                iconColor: accentColor,
                label: 'Duration',
                value: _formatDurationDisplay(),
                isEditing: _isEditing,
                editWidget: _buildDurationRangeSelector(accentColor),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Warmup Duration
              _buildEditableRow(
                icon: Icons.whatshot_outlined,
                iconColor: AppColors.orange,
                label: 'Warmup',
                value: '$_selectedWarmupDuration min',
                isEditing: _isEditing,
                editWidget: _buildWarmupSelector(AppColors.orange, cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Stretch Duration
              _buildEditableRow(
                icon: Icons.self_improvement_outlined,
                iconColor: AppColors.purple,
                label: 'Stretch',
                value: '$_selectedStretchDuration min',
                isEditing: _isEditing,
                editWidget: _buildStretchSelector(AppColors.purple, cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Goal
              _buildEditableRow(
                icon: Icons.flag,
                iconColor: accentColor,
                label: 'Goal',
                value: _selectedGoal,
                isEditing: _isEditing,
                editWidget: _buildGoalSelector(accentColor, cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Level
              _buildEditableRow(
                icon: Icons.signal_cellular_alt,
                iconColor: accentColor,
                label: 'Level',
                value: _selectedLevel,
                isEditing: _isEditing,
                editWidget: _buildLevelSelector(accentColor, cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Workout Days
              _buildEditableRow(
                icon: Icons.calendar_today,
                iconColor: accentColor,
                label: 'Workout Days',
                value: _selectedDays.isEmpty
                    ? 'Not set'
                    : _selectedDays.map((d) => ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][d]).join(', '),
                isEditing: _isEditing,
                editWidget: _buildDaysSelector(accentColor, cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),
              Divider(height: 1, color: cardBorder, indent: 56),

              // Injuries
              _buildEditableRow(
                icon: Icons.healing,
                iconColor: AppColors.error,
                label: 'Injuries',
                value: _selectedInjuries.isEmpty ? 'None' : _selectedInjuries.join(', '),
                isEditing: _isEditing,
                editWidget: _buildInjurySelector(cardBorder, textSecondary),
                isDark: isDark,
                textMuted: textMuted,
              ),

              // Warning when editing
              if (_isEditing)
                _buildEditingWarning(isDark),
            ],
          ),
        ),
        // Edit button positioned in top-right corner
        Positioned(
          top: 8,
          right: 8,
          child: _buildEditButton(accentColor, textMuted),
        ),
      ],
    );
  }

  Widget _buildGoalSelector(Color purple, Color cardBorder, Color textSecondary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _goalOptions.map((goal) {
        final isSelected = _selectedGoal == goal;
        return _buildChip(
          label: goal,
          isSelected: isSelected,
          color: purple,
          borderColor: cardBorder,
          textColor: textSecondary,
          onTap: _isSaving ? null : () => setState(() => _selectedGoal = goal),
        );
      }).toList(),
    );
  }

  Widget _buildLevelSelector(Color cyan, Color cardBorder, Color textSecondary) {
    return Row(
      children: _levelOptions.map((level) {
        final isSelected = _selectedLevel == level;
        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: _buildChip(
            label: level,
            isSelected: isSelected,
            color: cyan,
            borderColor: cardBorder,
            textColor: textSecondary,
            onTap: _isSaving ? null : () => setState(() => _selectedLevel = level),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDurationRangeSelector(Color accentColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Range display
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '15 min',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _formatDurationDisplay(),
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              '90 min',
              style: TextStyle(fontSize: 11, color: textMuted),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Range slider
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: accentColor,
            inactiveTrackColor: accentColor.withOpacity(0.2),
            thumbColor: accentColor,
            overlayColor: accentColor.withOpacity(0.2),
            trackHeight: 4,
            rangeThumbShape: const RoundRangeSliderThumbShape(
              enabledThumbRadius: 8,
            ),
          ),
          child: RangeSlider(
            values: RangeValues(_selectedDurationMin, _selectedDurationMax),
            min: 15,
            max: 90,
            divisions: 15, // 5 min increments
            onChanged: _isSaving
                ? null
                : (RangeValues values) {
                    setState(() {
                      _selectedDurationMin = values.start;
                      _selectedDurationMax = values.end;
                    });
                  },
          ),
        ),
      ],
    );
  }

  Widget _buildWarmupSelector(Color color, Color cardBorder, Color textSecondary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _warmupStretchOptions.map((duration) {
        final isSelected = _selectedWarmupDuration == duration;
        return _buildChip(
          label: '$duration min',
          isSelected: isSelected,
          color: color,
          borderColor: cardBorder,
          textColor: textSecondary,
          onTap: _isSaving ? null : () => setState(() => _selectedWarmupDuration = duration),
        );
      }).toList(),
    );
  }

  Widget _buildStretchSelector(Color color, Color cardBorder, Color textSecondary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _warmupStretchOptions.map((duration) {
        final isSelected = _selectedStretchDuration == duration;
        return _buildChip(
          label: '$duration min',
          isSelected: isSelected,
          color: color,
          borderColor: cardBorder,
          textColor: textSecondary,
          onTap: _isSaving ? null : () => setState(() => _selectedStretchDuration = duration),
        );
      }).toList(),
    );
  }

  Widget _buildDaysSelector(Color cyan, Color cardBorder, Color textSecondary) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final isSelected = _selectedDays.contains(index);
        return GestureDetector(
          onTap: _isSaving
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.remove(index);
                    } else {
                      _selectedDays.add(index);
                      _selectedDays.sort();
                    }
                  });
                },
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isSelected ? cyan.withOpacity(0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? cyan : cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(
                _dayNames[index],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? cyan : textSecondary,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildInjurySelector(Color cardBorder, Color textSecondary) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: _injuryOptions.map((injury) {
        final isSelected = _selectedInjuries.contains(injury);
        return GestureDetector(
          onTap: _isSaving
              ? null
              : () {
                  setState(() {
                    if (isSelected) {
                      _selectedInjuries.remove(injury);
                    } else {
                      _selectedInjuries.add(injury);
                    }
                  });
                },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.error.withOpacity(0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isSelected ? AppColors.error : cardBorder),
            ),
            child: Text(
              injury,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? AppColors.error : textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChip({
    required String label,
    required bool isSelected,
    required Color color,
    required Color borderColor,
    required Color textColor,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? color : textColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEditingWarning(bool isDark) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.orange, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Changes affect your workout program',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? AppColors.textSecondary : AppColorsLight.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(Color cyan, Color textMuted) {
    if (_isEditing) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () {
                    _loadValues();
                    setState(() => _isEditing = false);
                  },
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text('Cancel', style: TextStyle(color: textMuted, fontSize: 12)),
          ),
          TextButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: cyan),
                  )
                : Text('Save', style: TextStyle(color: cyan, fontWeight: FontWeight.w600, fontSize: 12)),
          ),
        ],
      );
    }

    return TextButton.icon(
      onPressed: () => setState(() => _isEditing = true),
      icon: Icon(Icons.edit, size: 12, color: cyan),
      label: Text('Edit', style: TextStyle(color: cyan, fontSize: 12)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// Build the gym row with profile color dot and tap to manage
  Widget _buildGymRow({
    required GymProfile? profile,
    required bool isDark,
    required Color textMuted,
    required Color textSecondary,
  }) {
    final gymName = profile?.name ?? 'No gym selected';
    final gymColor = profile?.profileColor ?? Colors.grey;
    final gymIcon = _getGymIconData(profile?.icon ?? 'fitness_center');

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useRootNavigator: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const ManageGymProfilesSheet(),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: gymColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(gymIcon, color: gymColor, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Gym',
                    style: TextStyle(fontSize: 11, color: textMuted),
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          gymName,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: gymColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  /// Get IconData for gym icon name
  IconData _getGymIconData(String iconName) {
    switch (iconName) {
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      case 'home':
        return Icons.home_rounded;
      case 'business':
        return Icons.business_rounded;
      case 'hotel':
        return Icons.hotel_rounded;
      case 'park':
        return Icons.park_rounded;
      case 'sports_gymnastics':
        return Icons.sports_gymnastics_rounded;
      case 'self_improvement':
        return Icons.self_improvement_rounded;
      case 'directions_run':
        return Icons.directions_run_rounded;
      default:
        return Icons.fitness_center_rounded;
    }
  }

  Widget _buildEditableRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isEditing,
    required Widget editWidget,
    required bool isDark,
    required Color textMuted,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(fontSize: 11, color: textMuted),
                    ),
                    if (!isEditing)
                      Text(
                        value,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (isEditing) ...[
            const SizedBox(height: 10),
            editWidget,
          ],
        ],
      ),
    );
  }
}
