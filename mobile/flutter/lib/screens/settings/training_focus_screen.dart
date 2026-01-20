import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/api_constants.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/services/api_client.dart';

/// Screen for editing training focus settings:
/// - Primary goal (hypertrophy, strength, or both)
/// - Muscle focus points (allocate 5 points to priority muscles)
class TrainingFocusScreen extends ConsumerStatefulWidget {
  const TrainingFocusScreen({super.key});

  @override
  ConsumerState<TrainingFocusScreen> createState() => _TrainingFocusScreenState();
}

class _TrainingFocusScreenState extends ConsumerState<TrainingFocusScreen> {
  String? _selectedPrimaryGoal;
  Map<String, int> _muscleFocusPoints = {};
  bool _isLoading = false;
  bool _hasChanges = false;

  static const int maxTotalPoints = 5;

  int get totalPointsUsed => _muscleFocusPoints.values.fold(0, (a, b) => a + b);
  int get availablePoints => maxTotalPoints - totalPointsUsed;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final authState = ref.read(authStateProvider);
    final user = authState.user;
    if (user != null) {
      setState(() {
        _selectedPrimaryGoal = user.primaryGoal;
        _muscleFocusPoints = Map<String, int>.from(user.muscleFocusPoints ?? {});
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_hasChanges) {
      context.pop();
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authState = ref.read(authStateProvider);
      final user = authState.user;
      if (user == null) throw Exception('User not found');

      final api = ref.read(apiClientProvider);
      await api.put(
        '${ApiConstants.users}/${user.id}',
        data: {
          'primary_goal': _selectedPrimaryGoal,
          'muscle_focus_points': _muscleFocusPoints.isEmpty ? null : _muscleFocusPoints,
        },
      );

      // Refresh user data
      await ref.read(authStateProvider.notifier).refreshUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Training focus updated'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
      appBar: AppBar(
        title: const Text('Training Focus'),
        backgroundColor: isDark ? AppColors.pureBlack : Colors.white,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveSettings,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: _hasChanges ? AppColors.accent : textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Primary Goal Section
          Text(
            'PRIMARY TRAINING GOAL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          ..._buildGoalOptions(isDark, elevated, cardBorder, textPrimary, textSecondary),
          const SizedBox(height: 32),

          // Muscle Focus Section
          Text(
            'MUSCLE FOCUS POINTS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: textSecondary,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Allocate up to 5 focus points to prioritize specific muscle groups',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          _buildPointsIndicator(isDark, elevated, cardBorder, textPrimary, textSecondary),
          const SizedBox(height: 16),
          _buildMuscleList(isDark, elevated, cardBorder, textPrimary, textSecondary),
        ],
      ),
    );
  }

  List<Widget> _buildGoalOptions(bool isDark, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary) {
    final goals = [
      {
        'id': 'muscle_hypertrophy',
        'label': 'Muscle Hypertrophy',
        'description': 'Focus on muscle size (8-12 reps)',
        'icon': Icons.fitness_center,
      },
      {
        'id': 'muscle_strength',
        'label': 'Muscle Strength',
        'description': 'Focus on maximal strength (3-6 reps)',
        'icon': Icons.bolt,
      },
      {
        'id': 'strength_hypertrophy',
        'label': 'Both Strength & Hypertrophy',
        'description': 'Balanced approach (6-10 reps)',
        'icon': Icons.all_inclusive,
      },
    ];

    return goals.map((goal) {
      final isSelected = _selectedPrimaryGoal == goal['id'];
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() {
              _selectedPrimaryGoal = goal['id'] as String;
              _hasChanges = true;
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.accentGradient : null,
              color: isSelected ? null : elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accent : cardBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  goal['icon'] as IconData,
                  color: isSelected ? Colors.white : textSecondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['label'] as String,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : textPrimary,
                        ),
                      ),
                      Text(
                        goal['description'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isSelected ? Colors.white70 : textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
                    border: isSelected ? null : Border.all(color: cardBorder, width: 2),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                      : null,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPointsIndicator(bool isDark, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Focus Points',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                '$availablePoints/$maxTotalPoints available',
                style: TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: List.generate(maxTotalPoints, (index) {
              final isFilled = index < totalPointsUsed;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: isFilled ? AppColors.accentGradient : null,
                    color: isFilled ? null : Colors.transparent,
                    border: isFilled ? null : Border.all(color: cardBorder, width: 2),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildMuscleList(bool isDark, Color elevated, Color cardBorder, Color textPrimary, Color textSecondary) {
    final muscleGroups = {
      'Upper Body': ['chest', 'shoulders', 'triceps', 'biceps', 'lats', 'upper_back', 'upper_traps', 'forearms'],
      'Core': ['abs', 'obliques', 'lower_back'],
      'Lower Body': ['quadriceps', 'hamstrings', 'glutes', 'calves', 'hip_flexors'],
    };

    return Column(
      children: muscleGroups.entries.map((entry) {
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: elevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
              ...entry.value.asMap().entries.map((muscleEntry) {
                final muscle = muscleEntry.value;
                final isLast = muscleEntry.key == entry.value.length - 1;
                final points = _muscleFocusPoints[muscle] ?? 0;
                final hasPoints = points > 0;

                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              muscle.replaceAll('_', ' ').split(' ').map((w) => w[0].toUpperCase() + w.substring(1)).join(' '),
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: hasPoints ? FontWeight.w600 : FontWeight.w500,
                                color: hasPoints ? textPrimary : textSecondary,
                              ),
                            ),
                          ),
                          // Decrement button
                          GestureDetector(
                            onTap: points > 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      if (points == 1) {
                                        _muscleFocusPoints.remove(muscle);
                                      } else {
                                        _muscleFocusPoints[muscle] = points - 1;
                                      }
                                      _hasChanges = true;
                                    });
                                  }
                                : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(
                                Icons.remove,
                                size: 18,
                                color: points > 0 ? textPrimary : textSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                          // Points display
                          SizedBox(
                            width: 32,
                            child: Center(
                              child: Text(
                                '$points',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: hasPoints ? AppColors.accent : textSecondary,
                                ),
                              ),
                            ),
                          ),
                          // Increment button
                          GestureDetector(
                            onTap: availablePoints > 0
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _muscleFocusPoints[muscle] = points + 1;
                                      _hasChanges = true;
                                    });
                                  }
                                : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: cardBorder),
                              ),
                              child: Icon(
                                Icons.add,
                                size: 18,
                                color: availablePoints > 0 ? textPrimary : textSecondary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) Divider(height: 1, indent: 12, color: cardBorder.withValues(alpha: 0.5)),
                  ],
                );
              }),
            ],
          ),
        );
      }).toList(),
    );
  }
}
