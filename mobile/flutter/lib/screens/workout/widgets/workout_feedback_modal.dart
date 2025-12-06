import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

/// Feedback modal shown after workout completion
class WorkoutFeedbackModal extends StatefulWidget {
  final String workoutId;
  final String workoutName;
  final int durationMinutes;
  final int exercisesCompleted;
  final int totalSets;
  final int caloriesBurned;
  final Future<void> Function(int rating, String? feedback) onSubmit;
  final VoidCallback onSkip;

  const WorkoutFeedbackModal({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.durationMinutes,
    required this.exercisesCompleted,
    required this.totalSets,
    required this.caloriesBurned,
    required this.onSubmit,
    required this.onSkip,
  });

  @override
  State<WorkoutFeedbackModal> createState() => _WorkoutFeedbackModalState();
}

class _WorkoutFeedbackModalState extends State<WorkoutFeedbackModal> {
  int _rating = 0;
  final _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        _rating,
        _feedbackController.text.isNotEmpty ? _feedbackController.text : null,
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.elevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success animation
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.success.withOpacity(0.4),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 48,
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
              const SizedBox(height: 20),

              // Title
              const Text(
                'Workout Complete!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 8),
              Text(
                widget.workoutName,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 300.ms),
              const SizedBox(height: 24),

              // Stats summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      icon: Icons.timer,
                      value: '${widget.durationMinutes}',
                      label: 'min',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.cardBorder,
                    ),
                    _StatItem(
                      icon: Icons.fitness_center,
                      value: '${widget.totalSets}',
                      label: 'sets',
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: AppColors.cardBorder,
                    ),
                    _StatItem(
                      icon: Icons.local_fire_department,
                      value: '${widget.caloriesBurned}',
                      label: 'cal',
                      iconColor: AppColors.orange,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Rating
              const Text(
                'How was your workout?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ).animate().fadeIn(delay: 500.ms),
              const SizedBox(height: 12),

              // Star rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starNumber = index + 1;
                  final isSelected = starNumber <= _rating;
                  return GestureDetector(
                    onTap: () => setState(() => _rating = starNumber),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Icon(
                        isSelected ? Icons.star : Icons.star_border,
                        size: 40,
                        color: isSelected ? AppColors.orange : AppColors.textMuted,
                      ),
                    ),
                  )
                      .animate(delay: Duration(milliseconds: 500 + (index * 50)))
                      .scale(begin: const Offset(0.5, 0.5))
                      .fadeIn();
                }),
              ),
              const SizedBox(height: 8),
              Text(
                _ratingLabel,
                style: TextStyle(
                  fontSize: 14,
                  color: _rating > 0 ? AppColors.orange : AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 20),

              // Feedback text field
              TextField(
                controller: _feedbackController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any additional feedback? (optional)',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.glassSurface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ).animate().fadeIn(delay: 700.ms),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isSubmitting ? null : widget.onSkip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cyan,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Submit Feedback',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms),
            ],
          ),
        ),
      ),
    );
  }

  String get _ratingLabel {
    switch (_rating) {
      case 1:
        return 'Too easy';
      case 2:
        return 'Somewhat easy';
      case 3:
        return 'Just right';
      case 4:
        return 'Challenging';
      case 5:
        return 'Very hard';
      default:
        return 'Tap to rate';
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color? iconColor;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: iconColor ?? AppColors.cyan),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }
}

/// PR Celebration overlay animation
class PRCelebration extends StatelessWidget {
  final String exerciseName;
  final VoidCallback onComplete;

  const PRCelebration({
    super.key,
    required this.exerciseName,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black54,
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.orange.withOpacity(0.2),
                AppColors.purple.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.orange.withOpacity(0.5),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Trophy icon with glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.orange, AppColors.purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.orange.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events,
                  size: 56,
                  color: Colors.white,
                ),
              )
                  .animate(onComplete: (_) => onComplete())
                  .scale(
                    begin: const Offset(0, 0),
                    end: const Offset(1, 1),
                    duration: 400.ms,
                    curve: Curves.elasticOut,
                  )
                  .then()
                  .shake(
                    hz: 4,
                    offset: const Offset(5, 0),
                    duration: 500.ms,
                  )
                  .then(delay: 2000.ms)
                  .fadeOut(),
              const SizedBox(height: 24),

              // PR Text
              const Text(
                'NEW PR!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                  letterSpacing: 4,
                ),
              )
                  .animate()
                  .fadeIn(delay: 200.ms)
                  .scale(begin: const Offset(0.5, 0.5)),

              const SizedBox(height: 8),

              Text(
                exerciseName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Confetti-like particles would go here
              // For now just a simple message
              const Text(
                'You beat your personal record!',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}
