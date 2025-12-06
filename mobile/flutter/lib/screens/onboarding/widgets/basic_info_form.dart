import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

/// Basic info form for quick onboarding data collection
/// Collects: Name, Age, Gender, Height, Weight
class BasicInfoForm extends StatefulWidget {
  final void Function({
    required String name,
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
  }) onSubmit;
  final bool disabled;

  const BasicInfoForm({
    super.key,
    required this.onSubmit,
    this.disabled = false,
  });

  @override
  State<BasicInfoForm> createState() => _BasicInfoFormState();
}

class _BasicInfoFormState extends State<BasicInfoForm> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = '';
  bool _useCm = true;
  bool _useKg = true;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_nameController.text.trim().isEmpty) return false;
    if (_ageController.text.isEmpty) return false;
    if (_gender.isEmpty) return false;
    if (_useCm) {
      if (_heightController.text.isEmpty) return false;
    } else {
      if (_feetController.text.isEmpty || _inchesController.text.isEmpty) {
        return false;
      }
    }
    if (_weightController.text.isEmpty) return false;
    return true;
  }

  void _handleSubmit() {
    if (!_isValid || widget.disabled) return;

    HapticFeedback.mediumImpact();

    final age = int.tryParse(_ageController.text) ?? 0;
    if (age < 13 || age > 100) return;

    // Convert height to cm
    int heightCm;
    if (_useCm) {
      heightCm = int.tryParse(_heightController.text) ?? 0;
      if (heightCm < 100 || heightCm > 250) return;
    } else {
      final feet = int.tryParse(_feetController.text) ?? 0;
      final inches = int.tryParse(_inchesController.text) ?? 0;
      if (feet < 3 || feet > 8) return;
      heightCm = ((feet * 12 + inches) * 2.54).round();
    }

    // Convert weight to kg
    double weightKg;
    final weightNum = double.tryParse(_weightController.text) ?? 0;
    if (_useKg) {
      weightKg = weightNum;
      if (weightKg < 30 || weightKg > 300) return;
    } else {
      weightKg = weightNum / 2.20462;
      if (weightKg < 30 || weightKg > 300) return;
    }

    widget.onSubmit(
      name: _nameController.text.trim(),
      age: age,
      gender: _gender,
      heightCm: heightCm,
      weightKg: (weightKg * 10).round() / 10,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 52, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick info to get started',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 12),

          // Name
          _buildLabel('Name'),
          _buildTextField(
            controller: _nameController,
            hint: 'Your name',
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 12),

          // Age + Gender row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Age'),
                    _buildTextField(
                      controller: _ageController,
                      hint: 'e.g., 25',
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Gender'),
                    _buildGenderDropdown(),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Height + Weight row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Height'),
                        _buildUnitToggle(
                          value: _useCm,
                          labelTrue: 'cm',
                          labelFalse: 'ft',
                          onChanged: (v) => setState(() => _useCm = v),
                        ),
                      ],
                    ),
                    if (_useCm)
                      _buildTextField(
                        controller: _heightController,
                        hint: '170',
                        keyboardType: TextInputType.number,
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _feetController,
                              hint: '5',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Text("'", style: TextStyle(color: AppColors.textMuted)),
                          ),
                          Expanded(
                            child: _buildTextField(
                              controller: _inchesController,
                              hint: '10',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text('"', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Weight'),
                        _buildUnitToggle(
                          value: _useKg,
                          labelTrue: 'kg',
                          labelFalse: 'lbs',
                          onChanged: (v) => setState(() => _useKg = v),
                        ),
                      ],
                    ),
                    _buildTextField(
                      controller: _weightController,
                      hint: _useKg ? '70' : '154',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: _isValid && !widget.disabled ? _handleSubmit : null,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: _isValid && !widget.disabled
                      ? AppColors.cyanGradient
                      : null,
                  color: _isValid && !widget.disabled
                      ? null
                      : AppColors.glassSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isValid && !widget.disabled
                      ? [
                          BoxShadow(
                            color: AppColors.cyan.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _isValid && !widget.disabled
                          ? Colors.white
                          : AppColors.textMuted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !widget.disabled,
      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        filled: true,
        fillColor: AppColors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.cyan),
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender.isEmpty ? null : _gender,
          hint: const Text(
            'Select',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          isExpanded: true,
          dropdownColor: AppColors.elevated,
          style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: widget.disabled
              ? null
              : (v) => setState(() => _gender = v ?? ''),
        ),
      ),
    );
  }

  Widget _buildUnitToggle({
    required bool value,
    required String labelTrue,
    required String labelFalse,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () => onChanged(true),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: value ? AppColors.cyan : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelTrue,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: value ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
        const SizedBox(width: 2),
        GestureDetector(
          onTap: () => onChanged(false),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: !value ? AppColors.cyan : AppColors.glassSurface,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              labelFalse,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: !value ? Colors.white : AppColors.textMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
