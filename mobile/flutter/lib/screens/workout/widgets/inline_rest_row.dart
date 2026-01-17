/// Inline Rest Row Widget
///
/// Displays between completed and active sets during rest period.
/// Features: timer, +/-15s controls, skip, water, RPE rating, achievement prompts, AI tips.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Inline rest row that appears between sets during rest period
class InlineRestRow extends StatefulWidget {
  /// Initial rest duration in seconds
  final int restDurationSeconds;

  /// Called when rest timer completes
  final VoidCallback onRestComplete;

  /// Called when user skips rest
  final VoidCallback onSkipRest;

  /// Called when user adjusts time (+/- seconds)
  final Function(int adjustment) onAdjustTime;

  /// Called when user rates the set (RPE 1-10)
  final Function(int rpe) onRateSet;

  /// Called when user adds a note
  final Function(String note) onAddNote;

  /// Called when user taps RPE info icon
  final VoidCallback onShowRpeInfo;

  /// Achievement prompt to display (null if none)
  final String? achievementPrompt;

  /// AI-generated tip to display (null if loading or unavailable)
  final String? aiTip;

  /// Whether AI tip is currently loading
  final bool isLoadingAiTip;

  /// Current RPE value (null if not rated yet)
  final int? currentRpe;

  const InlineRestRow({
    super.key,
    required this.restDurationSeconds,
    required this.onRestComplete,
    required this.onSkipRest,
    required this.onAdjustTime,
    required this.onRateSet,
    required this.onAddNote,
    required this.onShowRpeInfo,
    this.achievementPrompt,
    this.aiTip,
    this.isLoadingAiTip = false,
    this.currentRpe,
  });

  @override
  State<InlineRestRow> createState() => _InlineRestRowState();
}

class _InlineRestRowState extends State<InlineRestRow>
    with SingleTickerProviderStateMixin {
  late int _remainingSeconds;
  Timer? _timer;
  late AnimationController _pulseController;
  bool _showNoteInput = false;
  final TextEditingController _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.restDurationSeconds;
    _startTimer();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        HapticFeedback.mediumImpact();
        widget.onRestComplete();
      } else {
        setState(() => _remainingSeconds--);
      }
    });
  }

  void _adjustTime(int adjustment) {
    setState(() {
      _remainingSeconds = (_remainingSeconds + adjustment).clamp(0, 600);
    });
    widget.onAdjustTime(adjustment);
    HapticFeedback.selectionClick();
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  double get _progress =>
      _remainingSeconds / widget.restDurationSeconds.clamp(1, 600);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.electricBlue.withValues(alpha: 0.08)
        : AppColors.electricBlue.withValues(alpha: 0.05);
    final borderColor = isDark
        ? AppColors.electricBlue.withValues(alpha: 0.3)
        : AppColors.electricBlue.withValues(alpha: 0.2);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Timer row
          _buildTimerRow(isDark, textPrimary, textMuted),

          // Progress bar
          _buildProgressBar(isDark),

          // Achievement prompt (if any)
          if (widget.achievementPrompt != null)
            _buildAchievementPrompt(isDark, textPrimary),

          // RPE Rating
          _buildRpeRating(isDark, textPrimary, textSecondary, textMuted),

          // Note input (expandable)
          if (_showNoteInput) _buildNoteInput(isDark, textPrimary, textMuted),

          // AI Tip (if any)
          if (widget.aiTip != null || widget.isLoadingAiTip)
            _buildAiTip(isDark, textSecondary, textMuted),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildTimerRow(bool isDark, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Timer display
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.03);
              return Transform.scale(
                scale: _remainingSeconds <= 10 ? scale : 1.0,
                child: Row(
                  children: [
                    Icon(
                      Icons.timer_outlined,
                      size: 24,
                      color: _remainingSeconds <= 10
                          ? AppColors.orange
                          : AppColors.electricBlue,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                        color: _remainingSeconds <= 10
                            ? AppColors.orange
                            : textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          const Spacer(),

          // -15s button
          _buildTimeAdjustButton(
            label: '-15s',
            onTap: () => _adjustTime(-15),
            isDark: isDark,
            textMuted: textMuted,
          ),
          const SizedBox(width: 8),

          // +15s button
          _buildTimeAdjustButton(
            label: '+15s',
            onTap: () => _adjustTime(15),
            isDark: isDark,
            textMuted: textMuted,
          ),
          const SizedBox(width: 12),

          // Skip button
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onSkipRest();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.electricBlue.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.electricBlue,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.electricBlue,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeAdjustButton({
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    required Color textMuted,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: 6,
          backgroundColor: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.08),
          valueColor: AlwaysStoppedAnimation<Color>(
            _remainingSeconds <= 10 ? AppColors.orange : AppColors.electricBlue,
          ),
        ),
      ),
    );
  }

  Widget _buildAchievementPrompt(bool isDark, Color textPrimary) {
    final goldColor = Colors.amber.shade600;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: goldColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              widget.achievementPrompt!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? goldColor : Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRpeRating(
      bool isDark, Color textPrimary, Color textSecondary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label row
          Row(
            children: [
              Text(
                'How did that feel?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '(RPE)',
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: widget.onShowRpeInfo,
                child: Icon(
                  Icons.info_outline,
                  size: 16,
                  color: textMuted,
                ),
              ),
              const Spacer(),
              // + Note button
              GestureDetector(
                onTap: () {
                  setState(() => _showNoteInput = !_showNoteInput);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showNoteInput ? Icons.close : Icons.add,
                        size: 14,
                        color: textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Note',
                        style: TextStyle(
                          fontSize: 12,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Star rating row with emoji anchors
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Easy emoji
              const Text('😌', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),

              // 10 stars - always golden/yellow
              ...List.generate(10, (index) {
                final rpeValue = index + 1;
                final isSelected =
                    widget.currentRpe != null && rpeValue <= widget.currentRpe!;
                final isExactSelection = widget.currentRpe == rpeValue;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    // If tapping the same star, deselect (set to 0)
                    // Otherwise, select this rating
                    if (isExactSelection) {
                      widget.onRateSet(0); // Deselect
                    } else {
                      widget.onRateSet(rpeValue);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Icon(
                      isSelected ? Icons.star_rounded : Icons.star_outline_rounded,
                      size: 24,
                      color: isSelected
                          ? Colors.amber.shade600 // Golden yellow for selected
                          : textMuted.withValues(alpha: 0.5),
                    ),
                  ),
                );
              }),

              const SizedBox(width: 8),
              // Hard emoji
              const Text('😤', style: TextStyle(fontSize: 20)),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNoteInput(bool isDark, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Add a note about this set...',
                hintStyle: TextStyle(fontSize: 14, color: textMuted),
                filled: true,
                fillColor: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              maxLines: 2,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_noteController.text.isNotEmpty) {
                widget.onAddNote(_noteController.text);
                _noteController.clear();
                setState(() => _showNoteInput = false);
                HapticFeedback.mediumImpact();
              }
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.electricBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.send_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiTip(bool isDark, Color textSecondary, Color textMuted) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.purple.withValues(alpha: 0.1)
            : AppColors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Text('💡', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 10),
          Expanded(
            child: widget.isLoadingAiTip
                ? Row(
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.purple),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Getting tip...',
                        style: TextStyle(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: textMuted,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '"${widget.aiTip}"',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: textSecondary,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
