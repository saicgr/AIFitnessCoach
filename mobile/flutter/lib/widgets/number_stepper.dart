/// Number Stepper Widget
///
/// Large futuristic number input with prominent +/- buttons
/// for weight and reps entry during workouts.
library;

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/constants/app_colors.dart';
import 'glow_button.dart';

/// Large number stepper with glowing +/- buttons
class NumberStepper extends StatefulWidget {
  /// Current value
  final double value;

  /// Callback when value changes
  final ValueChanged<double> onChanged;

  /// Minimum allowed value
  final double minValue;

  /// Maximum allowed value
  final double maxValue;

  /// Step increment for +/- buttons
  final double step;

  /// Label shown below the value (e.g., "KG" or "REPS")
  final String label;

  /// Unit to display next to value (e.g., "kg")
  final String? unit;

  /// Primary color for buttons
  final Color color;

  /// Whether to show decimal places
  final bool showDecimals;

  /// Number of decimal places to show
  final int decimalPlaces;

  /// Size of increment buttons
  final double buttonSize;

  /// Whether the stepper is disabled
  final bool isDisabled;

  /// Callback when long-press starts on a button (for rapid increment)
  final VoidCallback? onLongPressStart;

  /// Callback when long-press ends
  final VoidCallback? onLongPressEnd;

  /// Callback when label is tapped (e.g., to toggle units)
  final VoidCallback? onLabelTap;

  const NumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.minValue = 0,
    this.maxValue = 999,
    this.step = 1,
    this.label = '',
    this.unit,
    this.color = AppColors.glowCyan,
    this.showDecimals = false,
    this.decimalPlaces = 1,
    this.buttonSize = 56,
    this.isDisabled = false,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.onLabelTap,
  });

  /// Factory for weight input (kg)
  factory NumberStepper.weight({
    Key? key,
    required double value,
    required ValueChanged<double> onChanged,
    double step = 2.5,
    bool useKg = true,
    bool isDisabled = false,
    VoidCallback? onUnitToggle,
  }) {
    return NumberStepper(
      key: key,
      value: value,
      onChanged: onChanged,
      step: step,
      label: useKg ? 'KG' : 'LBS',
      color: AppColors.glowCyan,
      showDecimals: true,
      decimalPlaces: 1,
      minValue: 0,
      maxValue: 500,
      isDisabled: isDisabled,
      onLabelTap: onUnitToggle,
    );
  }

  /// Factory for reps input
  factory NumberStepper.reps({
    Key? key,
    required int value,
    required ValueChanged<int> onChanged,
    bool isDisabled = false,
  }) {
    return NumberStepper(
      key: key,
      value: value.toDouble(),
      onChanged: (v) => onChanged(v.toInt()),
      step: 1,
      label: 'REPS',
      color: AppColors.glowPurple,
      showDecimals: false,
      minValue: 0,
      maxValue: 100,
      isDisabled: isDisabled,
    );
  }

  @override
  State<NumberStepper> createState() => _NumberStepperState();
}

class _NumberStepperState extends State<NumberStepper> {
  late TextEditingController _controller;
  bool _isEditing = false;
  Timer? _rapidIncrementTimer;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
  }

  @override
  void didUpdateWidget(NumberStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && !_isEditing) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _rapidIncrementTimer?.cancel();
    super.dispose();
  }

  String _formatValue(double value) {
    if (widget.showDecimals) {
      return value.toStringAsFixed(widget.decimalPlaces);
    }
    return value.toInt().toString();
  }

  void _increment() {
    if (widget.isDisabled) return;
    final newValue = (widget.value + widget.step).clamp(widget.minValue, widget.maxValue);
    widget.onChanged(newValue);
    HapticFeedback.selectionClick();
  }

  void _decrement() {
    if (widget.isDisabled) return;
    final newValue = (widget.value - widget.step).clamp(widget.minValue, widget.maxValue);
    widget.onChanged(newValue);
    HapticFeedback.selectionClick();
  }

  void _startRapidIncrement(bool isAdd) {
    _rapidIncrementTimer?.cancel();
    _rapidIncrementTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (isAdd) {
        _increment();
      } else {
        _decrement();
      }
    });
  }

  void _stopRapidIncrement() {
    _rapidIncrementTimer?.cancel();
    _rapidIncrementTimer = null;
  }

  void _startEditing() {
    setState(() => _isEditing = true);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  void _finishEditing() {
    setState(() => _isEditing = false);
    final parsed = double.tryParse(_controller.text);
    if (parsed != null) {
      final clamped = parsed.clamp(widget.minValue, widget.maxValue);
      widget.onChanged(clamped);
    } else {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final mutedColor = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing - scale down buttons and font on small screens
        // Small: < 150px, Medium: 150-180px, Large: >= 180px
        final availableWidth = constraints.maxWidth;
        final isSmallScreen = availableWidth < 150;
        final isMediumScreen = availableWidth >= 150 && availableWidth < 180;

        // Progressive scaling for button sizes
        final double buttonSize;
        final double valueFontSize;
        final double labelFontSize;

        if (isSmallScreen) {
          buttonSize = 40.0;
          valueFontSize = 28.0;
          labelFontSize = 10.0;
        } else if (isMediumScreen) {
          buttonSize = 48.0;
          valueFontSize = 34.0;
          labelFontSize = 11.0;
        } else {
          buttonSize = widget.buttonSize; // 56.0 default
          valueFontSize = 40.0;
          labelFontSize = 13.0;
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Main row with buttons and value
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Decrement button
                GestureDetector(
                  onLongPressStart: (_) => _startRapidIncrement(false),
                  onLongPressEnd: (_) => _stopRapidIncrement(),
                  child: GlowIncrementButton(
                    onTap: _decrement,
                    isAdd: false,
                    size: buttonSize,
                    color: widget.color,
                    isDisabled: widget.isDisabled || widget.value <= widget.minValue,
                  ),
                ),

                // Value display / input
                Flexible(
                  child: GestureDetector(
                    onTap: _isEditing ? null : _startEditing,
                    child: Container(
                      constraints: BoxConstraints(
                        minWidth: isSmallScreen ? 44 : (isMediumScreen ? 52 : 60),
                        maxWidth: isSmallScreen ? 70 : (isMediumScreen ? 85 : 100),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: _isEditing
                          ? TextField(
                              controller: _controller,
                              keyboardType: TextInputType.numberWithOptions(
                                decimal: widget.showDecimals,
                              ),
                              textAlign: TextAlign.center,
                              autofocus: true,
                              style: TextStyle(
                                fontSize: valueFontSize,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                border: UnderlineInputBorder(
                                  borderSide: BorderSide(color: widget.color),
                                ),
                                focusedBorder: UnderlineInputBorder(
                                  borderSide: BorderSide(color: widget.color, width: 2),
                                ),
                              ),
                              onSubmitted: (_) => _finishEditing(),
                              onTapOutside: (_) => _finishEditing(),
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _formatValue(widget.value),
                                    style: TextStyle(
                                      fontSize: valueFontSize,
                                      fontWeight: FontWeight.w700,
                                      color: widget.isDisabled ? mutedColor : textColor,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),

                // Increment button
                GestureDetector(
                  onLongPressStart: (_) => _startRapidIncrement(true),
                  onLongPressEnd: (_) => _stopRapidIncrement(),
                  child: GlowIncrementButton(
                    onTap: _increment,
                    isAdd: true,
                    size: buttonSize,
                    color: widget.color,
                    isDisabled: widget.isDisabled || widget.value >= widget.maxValue,
                  ),
                ),
              ],
            ),

            // Label (tappable if onLabelTap provided)
            if (widget.label.isNotEmpty) ...[
              const SizedBox(height: 6),
              GestureDetector(
                onTap: widget.onLabelTap != null
                    ? () {
                        HapticFeedback.selectionClick();
                        widget.onLabelTap!();
                      }
                    : null,
                child: Container(
                  padding: widget.onLabelTap != null
                      ? const EdgeInsets.symmetric(horizontal: 12, vertical: 6)
                      : EdgeInsets.zero,
                  decoration: widget.onLabelTap != null
                      ? BoxDecoration(
                          color: widget.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: widget.color.withOpacity(0.3),
                          ),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: labelFontSize,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                          color: widget.isDisabled
                              ? mutedColor.withOpacity(0.5)
                              : widget.color,
                        ),
                      ),
                      if (widget.onLabelTap != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 14,
                          color: widget.color.withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Compact number stepper for smaller spaces
class CompactNumberStepper extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final double step;
  final String? label;
  final Color color;
  final bool showDecimals;
  final double minValue;
  final double maxValue;

  const CompactNumberStepper({
    super.key,
    required this.value,
    required this.onChanged,
    this.step = 1,
    this.label,
    this.color = AppColors.glowCyan,
    this.showDecimals = false,
    this.minValue = 0,
    this.maxValue = 999,
  });

  String _formatValue() {
    return showDecimals ? value.toStringAsFixed(1) : value.toInt().toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          GestureDetector(
            onTap: () {
              if (value > minValue) {
                HapticFeedback.selectionClick();
                onChanged((value - step).clamp(minValue, maxValue));
              }
            },
            child: Icon(
              Icons.remove,
              size: 18,
              color: value <= minValue ? Colors.grey : color,
            ),
          ),

          // Value
          Container(
            constraints: const BoxConstraints(minWidth: 40),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatValue(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimary : AppColorsLight.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (label != null)
                  Text(
                    label!,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      color: color.withOpacity(0.7),
                    ),
                  ),
              ],
            ),
          ),

          // Plus button
          GestureDetector(
            onTap: () {
              if (value < maxValue) {
                HapticFeedback.selectionClick();
                onChanged((value + step).clamp(minValue, maxValue));
              }
            },
            child: Icon(
              Icons.add,
              size: 18,
              color: value >= maxValue ? Colors.grey : color,
            ),
          ),
        ],
      ),
    );
  }
}
