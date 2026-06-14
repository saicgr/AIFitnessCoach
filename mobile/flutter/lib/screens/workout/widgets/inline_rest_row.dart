/// Inline Rest Row Widget
///
/// Displays between completed and active sets during rest period.
/// Features: timer, +/-15s controls, skip, water, RPE rating, achievement prompts, AI tips.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/models/set_progression.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';

import '../../../l10n/generated/app_localizations.dart';
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

  /// Adaptation feedback to display (null if no adaptation occurred)
  final AdaptationFeedback? adaptationFeedback;

  /// Weight unit for display ('lb' or 'kg')
  final String weightUnit;

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
    this.adaptationFeedback,
    this.weightUnit = 'lb',
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
    // Signature inline-rest "ember" row — the accent at low alpha, hairline
    // bordered. Never a boxed glass card; the accent stays reserved by tint.
    final accent = ThemeColors.of(context).accent;
    final backgroundColor = accent.withValues(alpha: isDark ? 0.10 : 0.06);
    final borderColor = accent.withValues(alpha: 0.30);
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(10),
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

          // Adaptation feedback chip (if any)
          if (widget.adaptationFeedback != null &&
              widget.adaptationFeedback!.type != AdaptationFeedbackType.none)
            _buildAdaptationChip(isDark),

          // RPE Rating
          _buildRpeRating(isDark, textPrimary, textSecondary, textMuted),

          // Note input (expandable)
          if (_showNoteInput) _buildNoteInput(isDark, textPrimary, textMuted),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimerRow(bool isDark, Color textPrimary, Color textMuted) {
    final accent = ThemeColors.of(context).accent;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 6),
      child: Row(
        children: [
          // Timer display — Barlow "REST" kicker + Space Mono telemetry numeral.
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 1.0 + (_pulseController.value * 0.03);
              return Transform.scale(
                scale: _remainingSeconds <= 10 ? scale : 1.0,
                child: Row(
                  children: [
                    Text(
                      AppLocalizations.of(context).workoutSummaryAdvancedRest
                          .toUpperCase(),
                      style: ZType.lbl(10.5, color: textMuted, letterSpacing: 2),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      _formatTime(_remainingSeconds),
                      style: ZType.data(
                        20,
                        color: _remainingSeconds <= 10 ? accent : textPrimary,
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
            label: AppLocalizations.of(context).inlineRestRow15s,
            onTap: () => _adjustTime(-15),
            isDark: isDark,
            textMuted: textMuted,
          ),
          const SizedBox(width: 6),

          // +15s button
          _buildTimeAdjustButton(
            label: AppLocalizations.of(context).inlineRestRow15s2,
            onTap: () => _adjustTime(15),
            isDark: isDark,
            textMuted: textMuted,
          ),
          const SizedBox(width: 8),

          // Skip control — Barlow uppercase, accent-tinted.
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              widget.onSkipRest();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accent.withValues(alpha: 0.30)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context).onboardingSkip.toUpperCase(),
                    style: ZType.lbl(10.5, color: accent, letterSpacing: 1.2),
                  ),
                  const SizedBox(width: 3),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: accent,
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
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label.toUpperCase(),
          style: ZType.lbl(10.5, color: textMuted, letterSpacing: 1),
        ),
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final accent = ThemeColors.of(context).accent;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: _progress,
          minHeight: 4,
          backgroundColor: accent.withValues(alpha: 0.18),
          valueColor: AlwaysStoppedAnimation<Color>(accent),
        ),
      ),
    );
  }

  Widget _buildAchievementPrompt(bool isDark, Color textPrimary) {
    final goldColor = Colors.amber.shade600;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: goldColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: goldColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 15)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.achievementPrompt!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? goldColor : Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptationChip(bool isDark) {
    final feedback = widget.adaptationFeedback!;
    final Color chipColor;
    final String icon;
    final String message;
    final unit = widget.weightUnit;
    final absDelta = feedback.weightDelta.abs();
    final deltaStr = absDelta % 1 == 0
        ? absDelta.toStringAsFixed(0)
        : absDelta.toStringAsFixed(1);

    // Variant pools (\u22654) per situation. Pick deterministically by hashing
    // restDurationSeconds (proxy for set context) so the user sees stable copy
    // for a given set but variety across sets/sessions. Keeps the table's
    // next-set delta and the chip text in lockstep \u2014 both reading the same
    // weightDelta from progressive_overload, so they cannot drift.
    String pickVariant(List<String> pool) {
      final seed = widget.restDurationSeconds + feedback.weightDelta.toInt() * 7;
      return pool[seed.abs() % pool.length];
    }

    switch (feedback.type) {
      case AdaptationFeedbackType.weightTooLight:
        chipColor = isDark ? AppColors.orange : Colors.orange.shade700;
        icon = '\u26A1'; // lightning
        message = pickVariant([
          'Weight too light \u2014 bump +$deltaStr $unit next',
          'Plenty in the tank: +$deltaStr $unit next set',
          'Step up: add $deltaStr $unit on the next set',
          'Easy money \u2014 +$deltaStr $unit incoming',
        ]);
      case AdaptationFeedbackType.weightIncreased:
        chipColor = AppColors.electricBlue;
        icon = '\u2197';
        message = pickVariant([
          'Adding +$deltaStr $unit next set',
          'Stepping up \u2014 +$deltaStr $unit on the next one',
          'Climbing +$deltaStr $unit \u2014 nice work',
          'Next set +$deltaStr $unit \u2014 keep the form',
        ]);
      case AdaptationFeedbackType.fatigueDetected:
        chipColor = isDark ? AppColors.coral : Colors.red.shade600;
        icon = '\u26A0\uFE0F';
        message = absDelta > 0
            ? pickVariant([
                'Fatigue detected \u2014 dropping $deltaStr $unit',
                'Easing off $deltaStr $unit \u2014 keep quality high',
                'Backing down $deltaStr $unit on the next set',
                '\u2212$deltaStr $unit \u2014 protect the form, not the ego',
              ])
            : 'Fatigue detected \u2014 reducing weight';
      case AdaptationFeedbackType.weightDecreased:
        chipColor = isDark ? AppColors.coral : Colors.red.shade600;
        icon = '\u2198';
        // Conflict tie-break: if RIR signaled "increase" but reps were below
        // target, progressive_overload already chose the rep-based decrease.
        // Chip text stays in agreement with the table's next target.
        message = pickVariant([
          'Reducing weight \u2212$deltaStr $unit',
          'Backing off \u2212$deltaStr $unit \u2014 quality first',
          'Lighten up: \u2212$deltaStr $unit next',
          '\u2212$deltaStr $unit on the next set \u2014 preserve form',
        ]);
      case AdaptationFeedbackType.none:
        return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      width: double.infinity,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: chipColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: chipColor.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  message.toUpperCase(),
                  style: ZType.lbl(10, color: chipColor, letterSpacing: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRpeRating(
      bool isDark, Color textPrimary, Color textSecondary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RPE is captured by the mandatory post-set intensity sheet, so the
          // inline "how did that feel?" stars were a duplicate ask and have
          // been removed. Only the "+ Note" affordance remains here.
          Row(
            children: [
              const Spacer(),
              // + Note button
              GestureDetector(
                onTap: () {
                  setState(() => _showNoteInput = !_showNoteInput);
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _showNoteInput ? Icons.close : Icons.add,
                        size: 12,
                        color: textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context).workoutUiBuildersNote
                            .toUpperCase(),
                        style: ZType.lbl(10, color: textMuted, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  Widget _buildNoteInput(bool isDark, Color textPrimary, Color textMuted) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _noteController,
              style: TextStyle(fontSize: 14, color: textPrimary),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context).inlineRestRowAddANoteAbout,
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
                color: ThemeColors.of(context).accent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.send_rounded,
                size: 20,
                color: ThemeColors.of(context).accentContrast,
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
                        AppLocalizations.of(context).inlineRestRowGettingTip,
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
