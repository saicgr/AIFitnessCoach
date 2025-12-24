import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/services/api_client.dart';

/// Goal banner with editable goal display.
class GoalBanner extends ConsumerStatefulWidget {
  const GoalBanner({super.key});

  @override
  ConsumerState<GoalBanner> createState() => _GoalBannerState();
}

class _GoalBannerState extends ConsumerState<GoalBanner> {
  bool _isEditing = false;
  String? _selectedGoal;
  bool _isSaving = false;
  bool _isOtherSelected = false;
  final TextEditingController _customGoalController = TextEditingController();

  static const _goalOptions = [
    ('Build Muscle', Icons.fitness_center, AppColors.cyan),
    ('Lose Weight', Icons.monitor_weight, AppColors.orange),
    ('Increase Endurance', Icons.directions_run, AppColors.purple),
    ('Stay Active', Icons.self_improvement, AppColors.success),
  ];

  static const _predefinedGoals = ['Build Muscle', 'Lose Weight', 'Increase Endurance', 'Stay Active'];

  @override
  void dispose() {
    _customGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    final authState = ref.watch(authStateProvider);
    final currentGoal = authState.user?.fitnessGoal ?? 'Not set';

    // Check if current goal is a custom one (not in predefined list)
    final isCurrentGoalCustom = currentGoal != 'Not set' && !_predefinedGoals.contains(currentGoal);

    // Initialize selected goal and custom controller
    if (_selectedGoal == null) {
      _selectedGoal = currentGoal;
      if (isCurrentGoalCustom) {
        _isOtherSelected = true;
        _customGoalController.text = currentGoal;
      }
    }

    // Find goal info - for custom goals, use a special color
    final goalInfo = _goalOptions.firstWhere(
      (g) => g.$1 == currentGoal,
      orElse: () => (currentGoal, Icons.star, AppColors.purple),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            goalInfo.$3.withOpacity(0.15),
            goalInfo.$3.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: goalInfo.$3.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: goalInfo.$3.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(goalInfo, textMuted, textPrimary, currentGoal),
          _buildEditSection(
            backgroundColor,
            cardBorder,
            textSecondary,
            textMuted,
            textPrimary,
            currentGoal,
            goalInfo.$3,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    (String, IconData, Color) goalInfo,
    Color textMuted,
    Color textPrimary,
    String currentGoal,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: goalInfo.$3.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(goalInfo.$2, color: goalInfo.$3, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR GOAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                currentGoal,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: _isSaving ? null : () => setState(() => _isEditing = !_isEditing),
          child: Text(
            _isEditing ? 'Cancel' : 'Edit',
            style: TextStyle(
              color: goalInfo.$3,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditSection(
    Color backgroundColor,
    Color cardBorder,
    Color textSecondary,
    Color textMuted,
    Color textPrimary,
    String currentGoal,
    Color goalColor,
  ) {
    return AnimatedCrossFade(
      firstChild: const SizedBox.shrink(),
      secondChild: Column(
        children: [
          const SizedBox(height: 16),
          _buildGoalOptions(backgroundColor, cardBorder, textSecondary),
          if (_isOtherSelected) _buildCustomGoalInput(backgroundColor, textPrimary, textMuted),
          const SizedBox(height: 16),
          _buildSaveButton(currentGoal, goalColor),
          const SizedBox(height: 8),
          Text(
            'Changing your goal affects AI recommendations',
            style: TextStyle(
              fontSize: 12,
              color: textMuted,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      crossFadeState: _isEditing ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      duration: const Duration(milliseconds: 200),
    );
  }

  Widget _buildGoalOptions(Color backgroundColor, Color cardBorder, Color textSecondary) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ..._goalOptions.map((goal) {
          final isSelected = !_isOtherSelected && _selectedGoal == goal.$1;
          return _buildGoalChip(
            goal: goal,
            isSelected: isSelected,
            backgroundColor: backgroundColor,
            cardBorder: cardBorder,
            textSecondary: textSecondary,
          );
        }),
        _buildOtherChip(backgroundColor, cardBorder, textSecondary),
      ],
    );
  }

  Widget _buildGoalChip({
    required (String, IconData, Color) goal,
    required bool isSelected,
    required Color backgroundColor,
    required Color cardBorder,
    required Color textSecondary,
  }) {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () => setState(() {
                _selectedGoal = goal.$1;
                _isOtherSelected = false;
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? goal.$3.withOpacity(0.2) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? goal.$3 : cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(goal.$2, color: isSelected ? goal.$3 : textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              goal.$1,
              style: TextStyle(
                color: isSelected ? goal.$3 : textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherChip(Color backgroundColor, Color cardBorder, Color textSecondary) {
    return GestureDetector(
      onTap: _isSaving
          ? null
          : () => setState(() {
                _isOtherSelected = true;
                _selectedGoal = _customGoalController.text.isNotEmpty
                    ? _customGoalController.text
                    : 'Custom Goal';
              }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _isOtherSelected ? AppColors.purple.withOpacity(0.2) : backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isOtherSelected ? AppColors.purple : cardBorder,
            width: _isOtherSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.star, color: _isOtherSelected ? AppColors.purple : textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(
              'Other',
              style: TextStyle(
                color: _isOtherSelected ? AppColors.purple : textSecondary,
                fontWeight: _isOtherSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomGoalInput(Color backgroundColor, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple),
        ),
        child: TextField(
          controller: _customGoalController,
          enabled: !_isSaving,
          onChanged: (value) => setState(() {
            _selectedGoal = value.isNotEmpty ? value : 'Custom Goal';
          }),
          style: TextStyle(
            fontSize: 14,
            color: textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your custom goal...',
            hintStyle: TextStyle(color: textMuted),
            prefixIcon: const Icon(Icons.edit, color: AppColors.purple, size: 20),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: InputBorder.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSaveButton(String currentGoal, Color goalColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _canSave(currentGoal) ? _saveGoal : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: goalColor,
          foregroundColor: Colors.white,
          disabledBackgroundColor: goalColor.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : const Text('Save Goal', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  bool _canSave(String currentGoal) {
    if (_isSaving) return false;

    final goalToSave = _isOtherSelected ? _customGoalController.text.trim() : _selectedGoal;

    if (goalToSave == null || goalToSave.isEmpty) return false;
    if (goalToSave == currentGoal) return false;

    return true;
  }

  Future<void> _saveGoal() async {
    final goalToSave = _isOtherSelected ? _customGoalController.text.trim() : _selectedGoal;

    if (goalToSave == null || goalToSave.isEmpty) return;

    setState(() => _isSaving = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      final userId = await apiClient.getUserId();

      if (userId == null) {
        throw Exception('User not found');
      }

      await apiClient.put(
        '${ApiConstants.users}/$userId',
        data: {'goals': goalToSave},
      );

      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
          _selectedGoal = goalToSave;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Goal updated to "$goalToSave"'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update goal: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}
