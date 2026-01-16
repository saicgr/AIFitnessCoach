import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// A text input field with unit toggle (metric/imperial).
class UnitToggleInput extends StatefulWidget {
  final String label;
  final UnitType unitType;
  final double? value; // Always stored in metric (cm or kg)
  final ValueChanged<double?> onChanged;
  final String? hint;
  final bool isRequired;

  const UnitToggleInput({
    super.key,
    required this.label,
    required this.unitType,
    required this.value,
    required this.onChanged,
    this.hint,
    this.isRequired = false,
  });

  @override
  State<UnitToggleInput> createState() => _UnitToggleInputState();
}

class _UnitToggleInputState extends State<UnitToggleInput> {
  late bool _isMetric;
  late TextEditingController _controller;
  late TextEditingController _feetController;
  late TextEditingController _inchesController;

  @override
  void initState() {
    super.initState();
    _isMetric = true;
    _controller = TextEditingController();
    _feetController = TextEditingController();
    _inchesController = TextEditingController();
    _updateControllers();
  }

  @override
  void didUpdateWidget(UnitToggleInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _updateControllers();
    }
  }

  void _updateControllers() {
    if (widget.value == null) {
      _controller.text = '';
      _feetController.text = '';
      _inchesController.text = '';
      return;
    }

    if (widget.unitType == UnitType.height) {
      if (_isMetric) {
        _controller.text = widget.value!.toStringAsFixed(0);
      } else {
        final totalInches = widget.value! / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        _feetController.text = feet.toString();
        _inchesController.text = inches.toString();
      }
    } else {
      if (_isMetric) {
        _controller.text = widget.value!.toStringAsFixed(1);
      } else {
        final lbs = widget.value! * 2.20462;
        _controller.text = lbs.toStringAsFixed(1);
      }
    }
  }

  void _onMetricChanged(bool isMetric) {
    setState(() {
      _isMetric = isMetric;
      _updateControllers();
    });
  }

  void _onValueChanged(String text) {
    if (text.isEmpty) {
      widget.onChanged(null);
      return;
    }

    final value = double.tryParse(text);
    if (value == null) return;

    if (widget.unitType == UnitType.height) {
      if (_isMetric) {
        widget.onChanged(value);
      } else {
        // This shouldn't be called for height in imperial mode
        widget.onChanged(value);
      }
    } else {
      if (_isMetric) {
        widget.onChanged(value);
      } else {
        // Convert lbs to kg
        widget.onChanged(value / 2.20462);
      }
    }
  }

  void _onHeightImperialChanged() {
    final feet = int.tryParse(_feetController.text) ?? 0;
    final inches = int.tryParse(_inchesController.text) ?? 0;
    final totalInches = feet * 12 + inches;
    final cm = totalInches * 2.54;
    widget.onChanged(cm);
  }

  @override
  void dispose() {
    _controller.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            _buildUnitToggle(),
          ],
        ),
        const SizedBox(height: 8),
        if (widget.unitType == UnitType.height && !_isMetric)
          _buildHeightImperialInput()
        else
          _buildSingleInput(),
      ],
    );
  }

  Widget _buildUnitToggle() {
    final metricLabel = widget.unitType == UnitType.height ? 'cm' : 'kg';
    final imperialLabel = widget.unitType == UnitType.height ? 'ft/in' : 'lbs';

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _UnitButton(
            label: metricLabel,
            isSelected: _isMetric,
            onTap: () => _onMetricChanged(true),
          ),
          _UnitButton(
            label: imperialLabel,
            isSelected: !_isMetric,
            onTap: () => _onMetricChanged(false),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleInput() {
    final suffix = widget.unitType == UnitType.height
        ? (_isMetric ? 'cm' : 'lbs')
        : (_isMetric ? 'kg' : 'lbs');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: _controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        onChanged: _onValueChanged,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: widget.hint ?? 'Enter value',
          hintStyle: const TextStyle(color: AppColors.textMuted),
          suffixText: suffix,
          suffixStyle: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildHeightImperialInput() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _feetController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _onHeightImperialChanged(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textMuted),
                suffixText: 'ft',
                suffixStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: TextField(
              controller: _inchesController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (_) => _onHeightImperialChanged(),
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
              decoration: const InputDecoration(
                hintText: '0',
                hintStyle: TextStyle(color: AppColors.textMuted),
                suffixText: 'in',
                suffixStyle: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}

enum UnitType { height, weight }

/// A simple text input for the onboarding form.
class OnboardingTextField extends StatelessWidget {
  final String label;
  final String? value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final TextInputType keyboardType;
  final bool isRequired;

  const OnboardingTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: TextEditingController(text: value),
            keyboardType: keyboardType,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
}

/// A number input with +/- buttons.
class NumberStepperInput extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int step;
  final String? suffix;
  final ValueChanged<int> onChanged;

  const NumberStepperInput({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 100,
    this.step = 1,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: value > min
                    ? () => onChanged(value - step)
                    : null,
                icon: Icon(
                  Icons.remove_circle_outline,
                  color: value > min
                      ? AppColors.textSecondary
                      : AppColors.textMuted,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                suffix != null ? '$value $suffix' : value.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: value < max
                    ? () => onChanged(value + step)
                    : null,
                icon: Icon(
                  Icons.add_circle_outline,
                  color: value < max
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
