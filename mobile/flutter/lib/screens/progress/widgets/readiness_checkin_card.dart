import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../data/models/scores.dart';
import '../../../data/providers/scores_provider.dart';

/// Card for daily readiness check-in using Hooper Index
class ReadinessCheckinCard extends ConsumerStatefulWidget {
  final String userId;
  final VoidCallback? onCheckInComplete;

  const ReadinessCheckinCard({
    super.key,
    required this.userId,
    this.onCheckInComplete,
  });

  @override
  ConsumerState<ReadinessCheckinCard> createState() =>
      _ReadinessCheckinCardState();
}

class _ReadinessCheckinCardState extends ConsumerState<ReadinessCheckinCard> {
  bool _isExpanded = false;

  // Hooper Index values (1-7, 1 = best, 7 = worst)
  int _sleepQuality = 4;
  int _fatigueLevel = 4;
  int _stressLevel = 4;
  int _muscleSoreness = 4;

  @override
  void initState() {
    super.initState();
    _loadExistingCheckIn();
  }

  Future<void> _loadExistingCheckIn() async {
    // Load scores to check if already checked in today
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scoresProvider.notifier).loadScoresOverview(userId: widget.userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final scoresState = ref.watch(scoresProvider);
    final hasCheckedIn = scoresState.hasCheckedInToday;
    final todayReadiness = scoresState.todayReadiness;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: hasCheckedIn
              ? [
                  Color(todayReadiness?.levelColor ?? 0xFF4CAF50)
                      .withOpacity(0.2),
                  Color(todayReadiness?.levelColor ?? 0xFF4CAF50)
                      .withOpacity(0.1),
                ]
              : [
                  colorScheme.primaryContainer,
                  colorScheme.primaryContainer.withOpacity(0.7),
                ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasCheckedIn
              ? Color(todayReadiness?.levelColor ?? 0xFF4CAF50).withOpacity(0.3)
              : colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          // Header (always visible)
          InkWell(
            onTap: hasCheckedIn ? null : () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: hasCheckedIn
                  ? _buildCheckedInHeader(todayReadiness!)
                  : _buildCheckInPromptHeader(),
            ),
          ),

          // Expandable form (only when not checked in)
          if (!hasCheckedIn && _isExpanded)
            _buildCheckInForm(colorScheme),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0);
  }

  Widget _buildCheckedInHeader(ReadinessScore readiness) {
    final colorScheme = Theme.of(context).colorScheme;
    final levelColor = Color(readiness.levelColor);

    return Row(
      children: [
        // Score circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: levelColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: levelColor.withOpacity(0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${readiness.readinessScore}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Today\'s Readiness',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                readiness.readinessLevel.toUpperCase(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                ),
              ),
              if (readiness.aiWorkoutRecommendation != null) ...[
                const SizedBox(height: 4),
                Text(
                  readiness.aiWorkoutRecommendation!,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        Icon(
          Icons.check_circle,
          color: levelColor,
          size: 28,
        ),
      ],
    );
  }

  Widget _buildCheckInPromptHeader() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: colorScheme.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.wb_sunny_outlined,
            color: colorScheme.primary,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'How are you feeling today?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Quick check-in helps optimize your workout',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Icon(
          _isExpanded ? Icons.expand_less : Icons.expand_more,
          color: colorScheme.primary,
        ),
      ],
    );
  }

  Widget _buildCheckInForm(ColorScheme colorScheme) {
    final isSubmitting = ref.watch(scoresProvider).isSubmittingReadiness;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          const Divider(),
          const SizedBox(height: 8),

          // Sleep Quality
          _buildSlider(
            label: 'Sleep Quality',
            icon: Icons.bedtime_outlined,
            value: _sleepQuality,
            lowLabel: 'Great',
            highLabel: 'Poor',
            onChanged: (v) => setState(() => _sleepQuality = v.toInt()),
          ),

          // Fatigue Level
          _buildSlider(
            label: 'Energy/Fatigue',
            icon: Icons.battery_charging_full,
            value: _fatigueLevel,
            lowLabel: 'Fresh',
            highLabel: 'Exhausted',
            onChanged: (v) => setState(() => _fatigueLevel = v.toInt()),
          ),

          // Stress Level
          _buildSlider(
            label: 'Stress Level',
            icon: Icons.psychology_outlined,
            value: _stressLevel,
            lowLabel: 'Relaxed',
            highLabel: 'Very Stressed',
            onChanged: (v) => setState(() => _stressLevel = v.toInt()),
          ),

          // Muscle Soreness
          _buildSlider(
            label: 'Muscle Soreness',
            icon: Icons.fitness_center,
            value: _muscleSoreness,
            lowLabel: 'None',
            highLabel: 'Severe',
            onChanged: (v) => setState(() => _muscleSoreness = v.toInt()),
          ),

          const SizedBox(height: 16),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : _submitCheckIn,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check),
              label: Text(isSubmitting ? 'Submitting...' : 'Submit Check-in'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String label,
    required IconData icon,
    required int value,
    required String lowLabel,
    required String highLabel,
    required ValueChanged<double> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    // Color gradient from green (1) to red (7)
    final sliderColor = Color.lerp(
      Colors.green,
      Colors.red,
      (value - 1) / 6,
    )!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                lowLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green[600],
                ),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: sliderColor,
                    thumbColor: sliderColor,
                    overlayColor: sliderColor.withOpacity(0.2),
                    inactiveTrackColor: colorScheme.outline.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: value.toDouble(),
                    min: 1,
                    max: 7,
                    divisions: 6,
                    onChanged: onChanged,
                  ),
                ),
              ),
              Text(
                highLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _submitCheckIn() async {
    final result = await ref.read(scoresProvider.notifier).submitReadinessCheckIn(
      userId: widget.userId,
      sleepQuality: _sleepQuality,
      fatigueLevel: _fatigueLevel,
      stressLevel: _stressLevel,
      muscleSoreness: _muscleSoreness,
    );

    if (result != null) {
      widget.onCheckInComplete?.call();

      // Show celebration dialog
      if (mounted) {
        _showResultDialog(result);
      }
    }
  }

  void _showResultDialog(ReadinessScore result) {
    final levelColor = Color(result.levelColor);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: levelColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.check_circle,
            color: levelColor,
            size: 48,
          ),
        ),
        title: Text(
          'Readiness: ${result.readinessScore}',
          style: TextStyle(color: levelColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              result.readinessLevel.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
            const SizedBox(height: 12),
            if (result.aiWorkoutRecommendation != null)
              Text(
                result.aiWorkoutRecommendation!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
        actionsAlignment: MainAxisAlignment.center,
      ),
    );
  }
}
