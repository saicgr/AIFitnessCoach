import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// Placeholder card shown in the carousel when no workout exists for a day
/// User can tap to generate a workout for that specific date
class GenerateWorkoutPlaceholder extends ConsumerStatefulWidget {
  /// The date this placeholder represents
  final DateTime date;

  /// Callback when user taps to generate
  final VoidCallback onGenerate;

  /// Whether generation is currently in progress
  final bool isGenerating;

  const GenerateWorkoutPlaceholder({
    super.key,
    required this.date,
    required this.onGenerate,
    this.isGenerating = false,
  });

  @override
  ConsumerState<GenerateWorkoutPlaceholder> createState() =>
      _GenerateWorkoutPlaceholderState();
}

class _GenerateWorkoutPlaceholderState
    extends ConsumerState<GenerateWorkoutPlaceholder>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isGenerating) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GenerateWorkoutPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isGenerating && !oldWidget.isGenerating) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isGenerating && oldWidget.isGenerating) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getDayLabel() {
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[widget.date.weekday - 1];
  }

  String _getDateLabel() {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[widget.date.month - 1]} ${widget.date.day}';
  }

  bool _isToday() {
    final now = DateTime.now();
    return widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColorEnum = ref.watch(accentColorProvider);
    final accentColor = accentColorEnum.getColor(isDark);
    final isToday = _isToday();

    return Container(
        height: 440,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: accentColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient
            _buildBackground(isDark),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [
                          Colors.black.withValues(alpha: 0.0),
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.7),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.0),
                          Colors.white.withValues(alpha: 0.3),
                          Colors.white.withValues(alpha: 0.8),
                        ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Day badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.2)
                            : Colors.black.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Text(
                      isToday ? 'TODAY' : _getDayLabel(),
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Date label
                  Text(
                    _getDateLabel(),
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : Colors.black45,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Main message
                  Text(
                    widget.isGenerating
                        ? 'Generating workout...'
                        : 'No workout scheduled',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    widget.isGenerating
                        ? 'This may take a moment'
                        : 'Tap to create a personalized workout',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    child: widget.isGenerating
                        ? _buildLoadingButton(isDark, accentColor)
                        : ElevatedButton.icon(
                            onPressed: () {
                              HapticService.medium();
                              widget.onGenerate();
                            },
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            label: const Text(
                              'GENERATE WORKOUT',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                                fontSize: 14,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: accentColor.withValues(alpha: 0.5),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingButton(bool isDark, Color accentColor) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: accentColor.withValues(
              alpha: 0.3 + (_pulseController.value * 0.2),
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: accentColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'GENERATING...',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground(bool isDark) {
    Color startColor;
    Color endColor;

    if (isDark) {
      startColor = const Color(0xFF1a1a1a);
      endColor = const Color(0xFF252525);
    } else {
      startColor = const Color(0xFFF8F9FA);
      endColor = const Color(0xFFEEF0F2);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [startColor, endColor],
        ),
      ),
      child: Center(
        child: Opacity(
          opacity: isDark ? 0.05 : 0.08,
          child: Icon(
            Icons.add_circle_outline,
            size: 200,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}
