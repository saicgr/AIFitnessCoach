import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  /// Whether generation has permanently failed after retries (Fix 4)
  final bool isGenerationFailed;

  const GenerateWorkoutPlaceholder({
    super.key,
    required this.date,
    required this.onGenerate,
    this.isGenerating = false,
    this.isGenerationFailed = false,
  });

  @override
  ConsumerState<GenerateWorkoutPlaceholder> createState() =>
      _GenerateWorkoutPlaceholderState();
}

class _GenerateWorkoutPlaceholderState
    extends ConsumerState<GenerateWorkoutPlaceholder>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
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
    _bounceController.dispose();
    super.dispose();
  }

  String _getDayLabel() {
    final weekdays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    return weekdays[widget.date.weekday - 1];
  }

  String _getFullDayName() {
    final weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
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

                  // Main message with info icon (Fix 5: contextual messages)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.isGenerationFailed
                              ? 'Generation failed'
                              : widget.isGenerating
                                  ? 'Generating your ${_getFullDayName()} workout...'
                                  : 'Ready to train?',
                          style: TextStyle(
                            color: widget.isGenerationFailed
                                ? (isDark ? Colors.redAccent : Colors.red[700])
                                : (isDark ? Colors.white : Colors.black87),
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                        ),
                      ),
                      if (!widget.isGenerating && !widget.isGenerationFailed)
                        _buildInfoIcon(context, isDark, accentColor),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Subtitle (Fix 5: contextual date info)
                  Text(
                    widget.isGenerationFailed
                        ? 'Tap below to try again'
                        : widget.isGenerating
                            ? '${_getDateLabel()} - This may take a moment'
                            : 'Tap below to generate your personalized workout',
                    style: TextStyle(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.7)
                          : Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Animated down arrow (hide during generation and failure)
                  if (!widget.isGenerating && !widget.isGenerationFailed)
                    _buildDownArrow(accentColor),
                  const SizedBox(height: 12),

                  // Generate / Retry / Loading button (Fix 4 + Fix 5)
                  SizedBox(
                    width: double.infinity,
                    child: widget.isGenerating
                        ? _buildLoadingButton(isDark, accentColor)
                        : widget.isGenerationFailed
                            ? _buildRetryButton(isDark, accentColor)
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
                  if (!widget.isGenerating && !widget.isGenerationFailed) ...[
                    const SizedBox(height: 12),
                    _buildWorkoutHistoryIndicator(isDark, accentColor),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoIcon(BuildContext context, bool isDark, Color accentColor) {
    return GestureDetector(
      onTap: () {
        HapticService.light();
        _showGenerationInfoSheet(context, isDark, accentColor);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.05),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.info_outline,
          size: 20,
          color: isDark
              ? Colors.white.withValues(alpha: 0.7)
              : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildDownArrow(Color accentColor) {
    return AnimatedBuilder(
      animation: _bounceController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceController.value * 6),
          child: Icon(
            Icons.keyboard_double_arrow_down,
            size: 28,
            color: accentColor.withValues(alpha: 0.8),
          ),
        );
      },
    );
  }

  Widget _buildWorkoutHistoryIndicator(bool isDark, Color accentColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.insights,
          size: 14,
          color: isDark
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.black38,
        ),
        const SizedBox(width: 6),
        Text(
          'Personalized using your workout history',
          style: TextStyle(
            fontSize: 12,
            color: isDark
                ? Colors.white.withValues(alpha: 0.5)
                : Colors.black38,
          ),
        ),
      ],
    );
  }

  void _showGenerationInfoSheet(BuildContext context, bool isDark, Color accentColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useRootNavigator: true, // Shows above the floating nav bar
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: accentColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'What powers your workout?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Your AI coach creates workouts based on:',
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoItem(isDark, accentColor, 'Fitness Level & Experience'),
            _buildInfoItem(isDark, accentColor, 'Your Goals (muscle building, weight loss, etc.)'),
            _buildInfoItem(isDark, accentColor, 'Available Equipment'),
            _buildInfoItem(isDark, accentColor, 'Any Injuries or Limitations'),
            _buildInfoItem(isDark, accentColor, 'Target Duration & Difficulty'),
            _buildInfoItem(isDark, accentColor, 'Previous Workout Performance'),
            _buildInfoItem(isDark, accentColor, 'Your Physical Profile (age, weight, height)'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    color: accentColor,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Each workout adapts to help you progress safely!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(bool isDark, Color accentColor, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.check_circle,
            size: 18,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
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

  /// Retry button shown after generation has permanently failed (Fix 4)
  Widget _buildRetryButton(bool isDark, Color accentColor) {
    return ElevatedButton.icon(
      onPressed: () {
        HapticService.medium();
        widget.onGenerate();
      },
      icon: const Icon(Icons.refresh, size: 20),
      label: const Text(
        'TAP TO RETRY',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          fontSize: 14,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? Colors.redAccent.withValues(alpha: 0.8) : Colors.red[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        elevation: 4,
        shadowColor: Colors.red.withValues(alpha: 0.3),
      ),
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
