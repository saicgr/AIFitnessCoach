import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';

/// Basic info form for quick onboarding data collection
/// Collects: Name, Date of Birth, Gender, Height, Weight, Activity Level
class BasicInfoForm extends StatefulWidget {
  final void Function({
    required String name,
    required DateTime dateOfBirth,
    required int age,
    required String gender,
    required int heightCm,
    required double weightKg,
    required String activityLevel,
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
  final _heightController = TextEditingController();
  final _feetController = TextEditingController();
  final _inchesController = TextEditingController();
  final _weightController = TextEditingController();

  String _gender = '';
  String _activityLevel = '';
  bool _useCm = true;
  bool _useKg = true;
  DateTime? _dateOfBirth;

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int get _calculatedAge {
    if (_dateOfBirth == null) return 0;
    final now = DateTime.now();
    int age = now.year - _dateOfBirth!.year;
    if (now.month < _dateOfBirth!.month ||
        (now.month == _dateOfBirth!.month && now.day < _dateOfBirth!.day)) {
      age--;
    }
    return age;
  }

  bool get _isValid {
    if (_nameController.text.trim().isEmpty) return false;
    if (_dateOfBirth == null) return false;
    final age = _calculatedAge;
    if (age < 13 || age > 100) return false;
    if (_gender.isEmpty) return false;
    if (_activityLevel.isEmpty) return false;
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

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day);
    final firstDate = DateTime(now.year - 100);
    final lastDate = DateTime(now.year - 13);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(lastDate) ? lastDate : initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      helpText: 'Select your date of birth',
      builder: (context, child) {
        final colors = context.colors;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: context.isDarkMode
                ? ColorScheme.dark(
                    primary: colors.cyan,
                    onPrimary: Colors.white,
                    surface: colors.elevated,
                    onSurface: colors.textPrimary,
                  )
                : ColorScheme.light(
                    primary: colors.cyan,
                    onPrimary: Colors.white,
                    surface: colors.elevated,
                    onSurface: colors.textPrimary,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  void _handleSubmit() {
    if (!_isValid || widget.disabled) return;

    HapticFeedback.mediumImpact();

    final age = _calculatedAge;
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
      dateOfBirth: _dateOfBirth!,
      age: age,
      gender: _gender,
      heightCm: heightCm,
      weightKg: (weightKg * 10).round() / 10,
      activityLevel: _activityLevel,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      margin: const EdgeInsets.only(left: 52, top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick info to get started',
            style: TextStyle(fontSize: 12, color: colors.textMuted),
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

          // Date of Birth + Gender row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Date of Birth'),
                    _buildDateOfBirthPicker(),
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
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text("'", style: TextStyle(color: colors.textMuted)),
                          ),
                          Expanded(
                            child: _buildTextField(
                              controller: _inchesController,
                              hint: '10',
                              keyboardType: TextInputType.number,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text('"', style: TextStyle(color: colors.textMuted)),
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
          const SizedBox(height: 12),

          // Activity Level + Continue button row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel('Activity Level'),
                    _buildActivityLevelDropdown(),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _buildCompactSubmitButton(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: colors.textSecondary),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    final colors = context.colors;
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !widget.disabled,
      style: TextStyle(fontSize: 14, color: colors.textPrimary),
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        hintText: hint,
        hintStyle: TextStyle(color: colors.textMuted, fontSize: 14),
        filled: true,
        fillColor: colors.elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.cyan),
        ),
      ),
    );
  }

  Widget _buildDateOfBirthPicker() {
    final colors = context.colors;
    final formattedDate = _dateOfBirth != null
        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
        : null;
    final ageText = _dateOfBirth != null ? ' (${_calculatedAge}y)' : '';

    return GestureDetector(
      onTap: widget.disabled ? null : _pickDateOfBirth,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: colors.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colors.cardBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                formattedDate != null ? '$formattedDate$ageText' : 'Select',
                style: TextStyle(
                  fontSize: 14,
                  color: formattedDate != null ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ),
            Icon(Icons.calendar_today, size: 16, color: colors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _gender.isEmpty ? null : _gender,
          hint: Text('Select', style: TextStyle(color: colors.textMuted, fontSize: 14)),
          isExpanded: true,
          dropdownColor: colors.elevated,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: widget.disabled ? null : (v) => setState(() => _gender = v ?? ''),
        ),
      ),
    );
  }

  Widget _buildActivityLevelDropdown() {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.elevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.cardBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _activityLevel.isEmpty ? null : _activityLevel,
          hint: Text('How active are you?', style: TextStyle(color: colors.textMuted, fontSize: 14)),
          isExpanded: true,
          dropdownColor: colors.elevated,
          style: TextStyle(fontSize: 14, color: colors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'sedentary', child: Text('Sedentary (little or no exercise)')),
            DropdownMenuItem(value: 'lightly_active', child: Text('Lightly Active (1-3 days/week)')),
            DropdownMenuItem(value: 'moderately_active', child: Text('Moderately Active (3-5 days/week)')),
            DropdownMenuItem(value: 'very_active', child: Text('Very Active (6-7 days/week)')),
          ],
          onChanged: widget.disabled ? null : (v) => setState(() => _activityLevel = v ?? ''),
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
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToggleButton(
          label: labelTrue,
          isSelected: value,
          onTap: () => onChanged(true),
          colors: colors,
        ),
        const SizedBox(width: 2),
        _buildToggleButton(
          label: labelFalse,
          isSelected: !value,
          onTap: () => onChanged(false),
          colors: colors,
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? colors.cyan : colors.glassSurface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : colors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactSubmitButton() {
    final colors = context.colors;
    final isEnabled = _isValid && !widget.disabled;

    return GestureDetector(
      onTap: isEnabled ? _handleSubmit : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isEnabled ? AppColors.cyanGradient : null,
          color: isEnabled ? null : colors.glassSurface,
          borderRadius: BorderRadius.circular(10),
          border: isEnabled ? null : Border.all(color: colors.cardBorder),
          boxShadow: isEnabled
              ? [BoxShadow(color: colors.cyan.withOpacity(0.3), blurRadius: 12)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isEnabled ? Colors.white : colors.textMuted,
              ),
            ),
            if (isEnabled) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_forward, size: 14, color: Colors.white),
            ],
          ],
        ),
      ),
    );
  }
}
