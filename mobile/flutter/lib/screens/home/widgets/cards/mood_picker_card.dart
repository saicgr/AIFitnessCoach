import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/mood.dart';
import '../../../../data/providers/mood_workout_provider.dart';
import '../../../../data/services/context_logging_service.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../../data/repositories/workout_repository.dart';

/// Mood picker card for home screen.
/// Allows users to select a mood and instantly generate a tailored workout.
class MoodPickerCard extends ConsumerStatefulWidget {
  const MoodPickerCard({super.key});

  @override
  ConsumerState<MoodPickerCard> createState() => _MoodPickerCardState();
}

class _MoodPickerCardState extends ConsumerState<MoodPickerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final moodState = ref.watch(moodWorkoutProvider);
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Listen for generated workout to navigate
    ref.listen<MoodWorkoutState>(moodWorkoutProvider, (prev, next) {
      if (next.isCompleted && next.generatedWorkout != null && prev?.generatedWorkout == null) {
        // Workout generated successfully - navigate to it
        _pulseController.stop();
        final workout = next.generatedWorkout!;
        context.push('/workout/${workout.id}');
        // Clear the generated workout from state after navigation
        Future.delayed(const Duration(milliseconds: 500), () {
          ref.read(moodWorkoutProvider.notifier).clearGeneratedWorkout();
        });
      }
    });

    // Show generating state
    if (moodState.isGenerating) {
      return _buildGeneratingCard(context, moodState, isDark);
    }

    // Show error state if there's an error
    if (moodState.hasFailed) {
      return _buildErrorCard(context, moodState.error!, isDark);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.cyan.withOpacity(0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    Icons.wb_sunny_outlined,
                    color: AppColors.cyan,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'How are you feeling?',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Tap to generate a workout for your mood',
                          style: TextStyle(
                            fontSize: 12,
                            color: textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // View history button
                  IconButton(
                    icon: Icon(
                      Icons.history,
                      color: textMuted,
                      size: 20,
                    ),
                    onPressed: () => context.push('/mood-history'),
                    tooltip: 'Mood History',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Mood buttons
              Row(
                children: Mood.values.map((mood) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: mood != Mood.values.last ? 8 : 0,
                      ),
                      child: _MoodButton(
                        mood: mood,
                        isSelected: moodState.selectedMood == mood,
                        onTap: () => _onMoodSelected(mood),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGeneratingCard(
    BuildContext context,
    MoodWorkoutState state,
    bool isDark,
  ) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final mood = state.selectedMood ?? Mood.good;
    final moodColor = mood.color;

    // Start pulse animation
    if (!_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: moodColor.withOpacity(0.4),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                moodColor.withOpacity(0.08),
                Colors.transparent,
              ],
            ),
          ),
          child: Column(
            children: [
              // Animated emoji
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: moodColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: moodColor.withOpacity(0.3),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          mood.emoji,
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              // Status message
              Text(
                state.statusMessage ?? 'Generating your workout...',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
              if (state.detail != null) ...[
                const SizedBox(height: 4),
                Text(
                  state.detail!,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: moodColor.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(moodColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Step ${state.currentStep} of ${state.totalSteps}',
                style: TextStyle(
                  fontSize: 11,
                  color: textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context, String error, bool isDark) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final errorColor = Colors.red.shade400;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: elevatedColor,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: errorColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: errorColor,
                size: 40,
              ),
              const SizedBox(height: 12),
              Text(
                'Generation Failed',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  fontSize: 12,
                  color: errorColor,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  ref.read(moodWorkoutProvider.notifier).reset();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: errorColor,
                  side: BorderSide(color: errorColor),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMoodSelected(Mood mood) async {
    HapticService.medium();

    // Log mood selection
    ref.read(contextLoggingServiceProvider).logMoodSelection(mood: mood);

    // Select mood and start generation
    final notifier = ref.read(moodWorkoutProvider.notifier);
    notifier.selectMood(mood);

    // Show full-screen loading overlay
    _showGeneratingOverlay(mood);

    final workout = await notifier.generateMoodWorkout();

    // Close the overlay
    if (mounted && Navigator.canPop(context)) {
      Navigator.pop(context);
    }

    if (workout != null) {
      // Log successful generation
      ref.read(contextLoggingServiceProvider).logMoodWorkoutGenerated(
        mood: mood,
        workoutId: workout.id ?? '',
        durationMinutes: workout.durationMinutes,
      );

      // Refresh workouts list and invalidate to force UI rebuild
      await ref.read(workoutsProvider.notifier).refresh();
      ref.invalidate(workoutsProvider);
    }
  }

  void _showGeneratingOverlay(Mood mood) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) => _MoodWorkoutGeneratingOverlay(mood: mood),
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
                        color: moodColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: moodColor.withOpacity(0.4),
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
                onEnd: () {
                  // Restart animation for continuous pulse
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
                      color: Colors.white.withOpacity(0.7),
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
                        backgroundColor: Colors.white.withOpacity(0.2),
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
                        color: Colors.white.withOpacity(0.6),
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
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.5)),
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
    final elevatedColor = isDark
        ? AppColors.elevated.withOpacity(0.7)
        : AppColorsLight.elevated.withOpacity(0.9);

    return Material(
      color: isSelected ? mood.color.withOpacity(0.15) : elevatedColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? mood.color.withOpacity(0.5)
                  : Colors.transparent,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mood.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
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
      ),
    );
  }
}
