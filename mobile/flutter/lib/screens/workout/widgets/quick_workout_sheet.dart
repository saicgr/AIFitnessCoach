import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';
import '../../../data/providers/quick_workout_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/main_shell.dart';

/// Shows the Quick Workout bottom sheet for busy users
/// who want 5-15 minute workouts.
Future<Workout?> showQuickWorkoutSheet(BuildContext context, WidgetRef ref) async {
  // Hide nav bar while sheet is open
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  final result = await showModalBottomSheet<Workout>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const _QuickWorkoutSheet(),
  );

  // Show nav bar when sheet is closed
  ref.read(floatingNavBarVisibleProvider.notifier).state = true;

  return result;
}

class _QuickWorkoutSheet extends ConsumerStatefulWidget {
  const _QuickWorkoutSheet();

  @override
  ConsumerState<_QuickWorkoutSheet> createState() => _QuickWorkoutSheetState();
}

class _QuickWorkoutSheetState extends ConsumerState<_QuickWorkoutSheet> {
  int _selectedDuration = 10;
  String? _selectedFocus;

  final List<int> _durations = [5, 10, 15];
  final List<Map<String, dynamic>> _focusOptions = [
    {'value': 'cardio', 'label': 'Cardio', 'icon': Icons.directions_run, 'color': AppColors.cardio},
    {'value': 'strength', 'label': 'Strength', 'icon': Icons.fitness_center, 'color': AppColors.strength},
    {'value': 'stretch', 'label': 'Stretch', 'icon': Icons.self_improvement, 'color': AppColors.flexibility},
    {'value': 'full_body', 'label': 'Full Body', 'icon': Icons.accessibility_new, 'color': AppColors.cyan},
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quickWorkoutProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.pureWhite;
    final cardBackground = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textMuted.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.flash_on,
                    color: AppColors.cyan,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Workout',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Perfect for busy days',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: textMuted),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Duration selector
                  Text(
                    'Duration',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: _durations.map((duration) {
                      final isSelected = _selectedDuration == duration;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: duration != _durations.last ? 12 : 0,
                          ),
                          child: _DurationCard(
                            duration: duration,
                            isSelected: isSelected,
                            onTap: () {
                              HapticService.light();
                              setState(() => _selectedDuration = duration);
                            },
                            cardBackground: cardBackground,
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 24),

                  // Focus selector
                  Text(
                    'Focus (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _focusOptions.map((option) {
                      final isSelected = _selectedFocus == option['value'];
                      return _FocusChip(
                        label: option['label'] as String,
                        icon: option['icon'] as IconData,
                        color: option['color'] as Color,
                        isSelected: isSelected,
                        onTap: () {
                          HapticService.light();
                          setState(() {
                            _selectedFocus = isSelected ? null : option['value'] as String;
                          });
                        },
                        cardBackground: cardBackground,
                        textPrimary: textPrimary,
                        textMuted: textMuted,
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Info text
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBackground,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.cyan.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.tips_and_updates_outlined,
                          color: AppColors.cyan,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AI will generate an efficient workout tailored to your available time and equipment.',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Generate button
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: state.isGenerating
                    ? null
                    : () => _generateQuickWorkout(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.cyan,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.cyan.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: state.isGenerating
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            state.statusMessage ?? 'Generating...',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on, size: 22),
                          const SizedBox(width: 8),
                          Text(
                            'Generate $_selectedDuration-min Workout',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),

          // Error message
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: TextStyle(color: AppColors.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _generateQuickWorkout() async {
    HapticService.medium();

    final workout = await ref.read(quickWorkoutProvider.notifier).generateQuickWorkout(
      duration: _selectedDuration,
      focus: _selectedFocus,
    );

    if (workout != null && mounted) {
      Navigator.pop(context, workout);
      // Navigate to active workout screen
      context.push('/workout/${workout.id}');
    }
  }
}

class _DurationCard extends StatelessWidget {
  final int duration;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _DurationCard({
    required this.duration,
    required this.isSelected,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.cyan.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.cyan : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(
              '$duration',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.cyan : textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'min',
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? AppColors.cyan : textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FocusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;
  final Color cardBackground;
  final Color textPrimary;
  final Color textMuted;

  const _FocusChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
    required this.cardBackground,
    required this.textPrimary,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isSelected ? color : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

