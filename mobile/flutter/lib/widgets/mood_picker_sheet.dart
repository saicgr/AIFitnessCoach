import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/constants/app_colors.dart';
import '../data/models/mood.dart';
import '../data/providers/mood_workout_provider.dart';
import '../data/services/context_logging_service.dart';
import '../data/services/haptic_service.dart';
import '../data/repositories/workout_repository.dart';
import 'main_shell.dart';

/// Shows the mood picker bottom sheet.
void showMoodPickerSheet(BuildContext context, WidgetRef ref) {
  HapticService.light();
  ref.read(floatingNavBarVisibleProvider.notifier).state = false;

  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    useRootNavigator: true,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.5),
    builder: (context) => const MoodPickerSheet(),
  ).then((_) {
    ref.read(floatingNavBarVisibleProvider.notifier).state = true;
  });
}

/// Bottom sheet for selecting mood and generating workout or just logging.
class MoodPickerSheet extends ConsumerStatefulWidget {
  const MoodPickerSheet({super.key});

  @override
  ConsumerState<MoodPickerSheet> createState() => _MoodPickerSheetState();
}

class _MoodPickerSheetState extends ConsumerState<MoodPickerSheet> {
  Mood? _selectedMood;
  bool _isLogging = false;
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Handle bar
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: textMuted.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Header
                  Text(
                    'How are you feeling?',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Mood buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: Mood.values.map((mood) {
                      final isSelected = _selectedMood == mood;
                      return _MoodButton(
                        mood: mood,
                        isSelected: isSelected,
                        onTap: () {
                          HapticService.light();
                          setState(() => _selectedMood = mood);
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),

                  // Just Log Mood button (primary)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedMood == null || _isLogging || _isGenerating
                          ? null
                          : _logMoodOnly,
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedMood?.color ?? (isDark ? Colors.white : Colors.black),
                        foregroundColor: isDark ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.2),
                      ),
                      child: _isLogging
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: isDark ? Colors.black : Colors.white,
                              ),
                            )
                          : const Text(
                              'Just Log Mood',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Generate Workout button (secondary)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _selectedMood == null || _isLogging || _isGenerating
                          ? null
                          : _generateWorkout,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _selectedMood?.color ?? textColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        side: BorderSide(
                          color: _selectedMood?.color.withValues(alpha: 0.5) ??
                              textMuted.withValues(alpha: 0.3),
                        ),
                      ),
                      child: _isGenerating
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _selectedMood?.color ?? textColor,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.fitness_center,
                                  size: 18,
                                  color: _selectedMood?.color ?? textMuted,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Generate Workout',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // View History & Analysis link
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push('/mood-history');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.insights_outlined,
                          size: 18,
                          color: textMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'View History & Analysis',
                          style: TextStyle(
                            color: textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logMoodOnly() async {
    if (_selectedMood == null) return;

    setState(() => _isLogging = true);
    HapticService.medium();

    try {
      // Log mood selection
      ref.read(contextLoggingServiceProvider).logMoodSelection(mood: _selectedMood!);

      // Close sheet and show success
      if (mounted) {
        Navigator.pop(context);
        HapticService.success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(_selectedMood!.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('Mood logged: ${_selectedMood!.label}'),
              ],
            ),
            backgroundColor: _selectedMood!.color,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLogging = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log mood: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _generateWorkout() async {
    if (_selectedMood == null) return;

    setState(() => _isGenerating = true);
    HapticService.medium();

    try {
      // Log mood selection
      ref.read(contextLoggingServiceProvider).logMoodSelection(mood: _selectedMood!);

      // Select mood and start generation
      final notifier = ref.read(moodWorkoutProvider.notifier);
      notifier.selectMood(_selectedMood!);

      // Close the sheet first
      if (mounted) {
        Navigator.pop(context);
      }

      // Show full-screen generating overlay
      if (mounted) {
        _showGeneratingOverlay(_selectedMood!);
      }

      final workout = await notifier.generateMoodWorkout();

      // Close the overlay
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (workout != null) {
        // Log successful generation
        ref.read(contextLoggingServiceProvider).logMoodWorkoutGenerated(
          mood: _selectedMood!,
          workoutId: workout.id ?? '',
          durationMinutes: workout.durationMinutes,
        );

        // Refresh workouts list
        await ref.read(workoutsProvider.notifier).refresh();
        ref.invalidate(workoutsProvider);

        // Navigate to workout
        if (mounted) {
          context.push('/workout/${workout.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate workout: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showGeneratingOverlay(Mood mood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder: (dialogContext) => _MoodWorkoutGeneratingOverlay(mood: mood),
    );
  }
}

/// Individual mood button widget
class _MoodButton extends StatelessWidget {
  final Mood mood;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodButton({
    required this.mood,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? mood.color.withValues(alpha: 0.15)
              : (isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? mood.color.withValues(alpha: 0.5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: mood.color.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedScale(
              scale: isSelected ? 1.15 : 1.0,
              duration: const Duration(milliseconds: 200),
              child: Text(
                mood.emoji,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              mood.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? mood.color
                    : (isDark ? AppColors.textMuted : AppColorsLight.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-screen overlay shown during mood workout generation
class _MoodWorkoutGeneratingOverlay extends ConsumerWidget {
  final Mood mood;

  const _MoodWorkoutGeneratingOverlay({required this.mood});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(moodWorkoutProvider);
    final moodColor = mood.color;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated emoji with glow
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.9, end: 1.1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: moodColor.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: moodColor.withValues(alpha: 0.4),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 56),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Status message
              Text(
                state.statusMessage ?? 'Generating your ${mood.label.toLowerCase()} workout...',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.detail != null) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    state.detail!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Progress bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: state.progress > 0 ? state.progress : null,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state.currentStep > 0
                          ? 'Step ${state.currentStep} of ${state.totalSteps}'
                          : 'Initializing...',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),

              // Error state
              if (state.hasFailed) ...[
                const SizedBox(height: 24),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 32),
                      const SizedBox(height: 8),
                      Text(
                        state.error ?? 'Something went wrong',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
