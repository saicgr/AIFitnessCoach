/// Number input widgets for workout screens
///
/// Reusable input widgets for weight and reps during workout.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';

/// Inline number input with +/- buttons
class InlineNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isDecimal;
  final bool isActive;
  final Color accentColor;
  final VoidCallback? onShowDialog;

  const InlineNumberInput({
    super.key,
    required this.controller,
    required this.isDecimal,
    this.isActive = false,
    required this.accentColor,
    this.onShowDialog,
  });

  @override
  State<InlineNumberInput> createState() => _InlineNumberInputState();
}

class _InlineNumberInputState extends State<InlineNumberInput> {
  void _decrement() {
    final increment = widget.isDecimal ? 2.5 : 1.0;
    if (widget.isDecimal) {
      final current = double.tryParse(widget.controller.text) ?? 0;
      final newVal = (current - increment).clamp(0.0, 999.0);
      widget.controller.text =
          newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    } else {
      final current = int.tryParse(widget.controller.text) ?? 0;
      final newVal = (current - 1).clamp(0, 999);
      widget.controller.text = newVal.toString();
    }
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  void _increment() {
    final increment = widget.isDecimal ? 2.5 : 1.0;
    if (widget.isDecimal) {
      final current = double.tryParse(widget.controller.text) ?? 0;
      final newVal = current + increment;
      widget.controller.text =
          newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    } else {
      final current = int.tryParse(widget.controller.text) ?? 0;
      final newVal = current + 1;
      widget.controller.text = newVal.toString();
    }
    setState(() {});
    HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final buttonWidth = widget.isActive ? 32.0 : 28.0;
    final height = widget.isActive ? 40.0 : 36.0;
    final iconSize = widget.isActive ? 18.0 : 16.0;
    final fontSize = widget.isActive ? 15.0 : 13.0;
    final inputBg = widget.isActive
        ? (isDark ? AppColors.pureBlack : AppColorsLight.pureWhite)
        : (isDark ? AppColors.elevated : AppColorsLight.glassSurface);
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(widget.isActive ? 10 : 8),
        border: Border.all(
          color: widget.isActive
              ? widget.accentColor
              : widget.accentColor.withOpacity(0.5),
          width: widget.isActive ? 1.5 : 1,
        ),
        boxShadow: widget.isActive
            ? [
                BoxShadow(
                  color: widget.accentColor.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 6,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          // Minus button
          GestureDetector(
            onTap: _decrement,
            child: Container(
              width: buttonWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: widget.isActive
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.accentColor.withOpacity(0.3),
                          widget.accentColor.withOpacity(0.15),
                        ],
                      )
                    : null,
                color: widget.isActive
                    ? null
                    : widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(widget.isActive ? 8 : 7),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.remove,
                  size: iconSize,
                  color: widget.isActive ? Colors.white : widget.accentColor,
                ),
              ),
            ),
          ),
          // Text display
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onShowDialog?.call();
              },
              child: Container(
                height: height,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.controller.text.isEmpty
                        ? '0'
                        : widget.controller.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: widget.isActive ? textColor : widget.accentColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: _increment,
            child: Container(
              width: buttonWidth,
              height: height,
              decoration: BoxDecoration(
                gradient: widget.isActive
                    ? LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.accentColor.withOpacity(0.3),
                          widget.accentColor.withOpacity(0.15),
                        ],
                      )
                    : null,
                color: widget.isActive
                    ? null
                    : widget.accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(widget.isActive ? 8 : 7),
                ),
              ),
              child: Center(
                child: Icon(
                  Icons.add,
                  size: iconSize,
                  color: widget.isActive ? Colors.white : widget.accentColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Expanded number input with larger touch targets
class ExpandedNumberInput extends StatefulWidget {
  final TextEditingController controller;
  final bool isDecimal;
  final Color accentColor;
  final VoidCallback? onShowDialog;

  const ExpandedNumberInput({
    super.key,
    required this.controller,
    required this.isDecimal,
    required this.accentColor,
    this.onShowDialog,
  });

  @override
  State<ExpandedNumberInput> createState() => _ExpandedNumberInputState();
}

class _ExpandedNumberInputState extends State<ExpandedNumberInput> {
  void _decrement() {
    final increment = widget.isDecimal ? 2.5 : 1.0;
    if (widget.isDecimal) {
      final current = double.tryParse(widget.controller.text) ?? 0;
      final newVal = (current - increment).clamp(0.0, 999.0);
      widget.controller.text =
          newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    } else {
      final current = int.tryParse(widget.controller.text) ?? 0;
      final newVal = (current - 1).clamp(0, 999);
      widget.controller.text = newVal.toString();
    }
    setState(() {});
  }

  void _increment() {
    final increment = widget.isDecimal ? 2.5 : 1.0;
    if (widget.isDecimal) {
      final current = double.tryParse(widget.controller.text) ?? 0;
      final newVal = current + increment;
      widget.controller.text =
          newVal.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
    } else {
      final current = int.tryParse(widget.controller.text) ?? 0;
      final newVal = current + 1;
      widget.controller.text = newVal.toString();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inputBg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textColor = isDark ? Colors.white : AppColorsLight.textPrimary;

    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: inputBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.accentColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.accentColor.withOpacity(isDark ? 0.3 : 0.15),
            blurRadius: 12,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Large minus button
          GlowingIncrementButton(
            icon: Icons.remove,
            accentColor: widget.accentColor,
            isLeft: true,
            onTap: _decrement,
          ),
          // Large text display
          Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                widget.onShowDialog?.call();
              },
              child: Container(
                height: 64,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.controller.text.isEmpty
                        ? '0'
                        : widget.controller.text,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Large plus button
          GlowingIncrementButton(
            icon: Icons.add,
            accentColor: widget.accentColor,
            isLeft: false,
            onTap: _increment,
          ),
        ],
      ),
    );
  }
}

/// Glowing increment button with press animation
class GlowingIncrementButton extends StatefulWidget {
  final IconData icon;
  final Color accentColor;
  final bool isLeft;
  final VoidCallback onTap;

  const GlowingIncrementButton({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.isLeft,
    required this.onTap,
  });

  @override
  State<GlowingIncrementButton> createState() => _GlowingIncrementButtonState();
}

class _GlowingIncrementButtonState extends State<GlowingIncrementButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _glowController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _glowController.reverse();
    widget.onTap();
    HapticFeedback.mediumImpact();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _glowController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedBuilder(
        animation: _glowAnimation,
        builder: (context, child) {
          final glowIntensity = _glowAnimation.value;
          const baseOpacity = 0.4;
          final pressedOpacity = baseOpacity + (0.3 * glowIntensity);
          const baseOpacity2 = 0.2;
          final pressedOpacity2 = baseOpacity2 + (0.15 * glowIntensity);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            width: 56,
            height: 64,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  widget.accentColor.withOpacity(pressedOpacity),
                  widget.accentColor.withOpacity(pressedOpacity2),
                ],
              ),
              borderRadius: BorderRadius.horizontal(
                left: widget.isLeft ? const Radius.circular(14) : Radius.zero,
                right: widget.isLeft ? Radius.zero : const Radius.circular(14),
              ),
              boxShadow: _isPressed
                  ? [
                      BoxShadow(
                        color: widget.accentColor
                            .withOpacity(0.4 * glowIntensity),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft ripple effect
                if (_isPressed)
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 80),
                    opacity: glowIntensity * 0.3,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ),
                // Icon
                AnimatedScale(
                  duration: const Duration(milliseconds: 80),
                  scale: _isPressed ? 0.9 : 1.0,
                  child: Icon(
                    widget.icon,
                    size: 28,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Number input field (alternative style)
class NumberInputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String hint;
  final Color color;
  final bool isDecimal;

  const NumberInputField({
    super.key,
    required this.controller,
    required this.icon,
    required this.hint,
    required this.color,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          // Decrement button
          GestureDetector(
            onTap: () {
              final current = isDecimal
                  ? (double.tryParse(controller.text) ?? 0)
                  : (int.tryParse(controller.text) ?? 0);
              final newValue = isDecimal
                  ? (current - 2.5).clamp(0, 999)
                  : (current - 1).clamp(0, 999);
              controller.text = isDecimal
                  ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                  : newValue.toInt().toString();
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.remove, color: color, size: 20),
            ),
          ),
          // Text field
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.center,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: isDecimal),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: hint,
                hintStyle: TextStyle(color: color.withOpacity(0.4)),
              ),
            ),
          ),
          // Increment button
          GestureDetector(
            onTap: () {
              final current = isDecimal
                  ? (double.tryParse(controller.text) ?? 0)
                  : (int.tryParse(controller.text) ?? 0);
              final newValue = isDecimal ? current + 2.5 : current + 1;
              controller.text = isDecimal
                  ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                  : newValue.toInt().toString();
              HapticFeedback.selectionClick();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Icon(Icons.add, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

/// Inline number input with label (for settings/config)
class InlineNumberInputWithLabel extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final Color color;
  final bool isDecimal;
  final String? unitLabel;
  final VoidCallback? onUnitToggle;

  const InlineNumberInputWithLabel({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    required this.color,
    this.isDecimal = false,
    this.unitLabel,
    this.onUnitToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Label with optional unit toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              if (unitLabel != null) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onUnitToggle,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withAlpha(40),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: color.withAlpha(80)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          unitLabel!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(Icons.swap_horiz, size: 10, color: color),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          // Input row with +/- buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  final current = isDecimal
                      ? (double.tryParse(controller.text) ?? 0)
                      : (int.tryParse(controller.text) ?? 0);
                  final newValue = isDecimal
                      ? (current - 2.5).clamp(0.0, 999.0)
                      : (current - 1).clamp(0, 999);
                  controller.text = isDecimal
                      ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                      : newValue.toInt().toString();
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.remove, color: color, size: 18),
                ),
              ),
              // Value field
              SizedBox(
                width: 60,
                child: TextField(
                  controller: controller,
                  textAlign: TextAlign.center,
                  keyboardType:
                      TextInputType.numberWithOptions(decimal: isDecimal),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {
                  final current = isDecimal
                      ? (double.tryParse(controller.text) ?? 0)
                      : (int.tryParse(controller.text) ?? 0);
                  final newValue = isDecimal ? current + 2.5 : current + 1;
                  controller.text = isDecimal
                      ? newValue.toStringAsFixed(1).replaceAll('.0', '')
                      : newValue.toInt().toString();
                  HapticFeedback.selectionClick();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.add, color: color, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
