import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';

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

  static const _dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _goalOptions = ['Build Muscle', 'Lose Weight', 'Increase Endurance', 'Stay Active'];
  static const _levelOptions = ['Beginner', 'Intermediate', 'Advanced'];
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
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) throw Exception('User not found');

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

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fitness settings updated'),
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

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
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
