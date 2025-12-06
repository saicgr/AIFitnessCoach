import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../onboarding_data.dart';
import '../widgets/unit_toggle_input.dart';

class BodyMetricsStep extends StatefulWidget {
  final OnboardingData data;
  final VoidCallback onDataChanged;

  const BodyMetricsStep({
    super.key,
    required this.data,
    required this.onDataChanged,
  });

  @override
  State<BodyMetricsStep> createState() => _BodyMetricsStepState();
}

class _BodyMetricsStepState extends State<BodyMetricsStep> {
  bool _showAdvanced = false;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          const Text(
            'Body Measurements',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Used to calculate BMI, BMR, and track progress',
            style: TextStyle(
              fontSize: 15,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),

          // Height
          UnitToggleInput(
            label: 'Height *',
            unitType: UnitType.height,
            value: widget.data.heightCm,
            onChanged: (value) {
              widget.data.heightCm = value;
              widget.onDataChanged();
            },
            hint: 'Enter height',
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Current Weight
          UnitToggleInput(
            label: 'Current Weight *',
            unitType: UnitType.weight,
            value: widget.data.weightKg,
            onChanged: (value) {
              widget.data.weightKg = value;
              widget.onDataChanged();
            },
            hint: 'Enter weight',
            isRequired: true,
          ),
          const SizedBox(height: 24),

          // Target Weight
          UnitToggleInput(
            label: 'Target Weight (optional)',
            unitType: UnitType.weight,
            value: widget.data.targetWeightKg,
            onChanged: (value) {
              widget.data.targetWeightKg = value;
              widget.onDataChanged();
            },
            hint: 'Enter target',
          ),
          const SizedBox(height: 32),

          // Advanced Measurements Toggle
          GestureDetector(
            onTap: () => setState(() => _showAdvanced = !_showAdvanced),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    _showAdvanced
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Advanced Measurements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    _showAdvanced ? 'Hide' : 'Show',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.cyan,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Advanced Measurements
          if (_showAdvanced) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'These measurements help calculate body composition more accurately',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Waist
                  UnitToggleInput(
                    label: 'Waist Circumference',
                    unitType: UnitType.height,
                    value: widget.data.waistCm,
                    onChanged: (value) {
                      widget.data.waistCm = value;
                      widget.onDataChanged();
                    },
                    hint: 'Measure at navel',
                  ),
                  const SizedBox(height: 16),

                  // Hip
                  UnitToggleInput(
                    label: 'Hip Circumference',
                    unitType: UnitType.height,
                    value: widget.data.hipCm,
                    onChanged: (value) {
                      widget.data.hipCm = value;
                      widget.onDataChanged();
                    },
                    hint: 'Widest point',
                  ),
                  const SizedBox(height: 16),

                  // Neck
                  UnitToggleInput(
                    label: 'Neck Circumference',
                    unitType: UnitType.height,
                    value: widget.data.neckCm,
                    onChanged: (value) {
                      widget.data.neckCm = value;
                      widget.onDataChanged();
                    },
                    hint: 'Below Adam\'s apple',
                  ),
                  const SizedBox(height: 16),

                  // Body Fat %
                  _buildNumberInput(
                    'Body Fat %',
                    widget.data.bodyFatPercent?.toInt(),
                    (value) {
                      widget.data.bodyFatPercent = value?.toDouble();
                      widget.onDataChanged();
                    },
                    suffix: '%',
                    hint: 'If known',
                  ),
                  const SizedBox(height: 16),

                  // Resting Heart Rate
                  _buildNumberInput(
                    'Resting Heart Rate',
                    widget.data.restingHeartRate,
                    (value) {
                      widget.data.restingHeartRate = value;
                      widget.onDataChanged();
                    },
                    suffix: 'bpm',
                    hint: 'Beats per minute',
                  ),
                  const SizedBox(height: 16),

                  // Blood Pressure
                  const Text(
                    'Blood Pressure',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildSmallNumberInput(
                          'Systolic',
                          widget.data.bloodPressureSystolic,
                          (value) {
                            widget.data.bloodPressureSystolic = value;
                            widget.onDataChanged();
                          },
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          '/',
                          style: TextStyle(
                            fontSize: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      Expanded(
                        child: _buildSmallNumberInput(
                          'Diastolic',
                          widget.data.bloodPressureDiastolic,
                          (value) {
                            widget.data.bloodPressureDiastolic = value;
                            widget.onDataChanged();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNumberInput(
    String label,
    int? value,
    ValueChanged<int?> onChanged, {
    String? suffix,
    String? hint,
  }) {
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
          decoration: BoxDecoration(
            color: AppColors.glassSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextField(
            controller: TextEditingController(text: value?.toString() ?? ''),
            keyboardType: TextInputType.number,
            onChanged: (text) => onChanged(int.tryParse(text)),
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textMuted),
              suffixText: suffix,
              suffixStyle: const TextStyle(color: AppColors.textSecondary),
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

  Widget _buildSmallNumberInput(
    String hint,
    int? value,
    ValueChanged<int?> onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: TextField(
        controller: TextEditingController(text: value?.toString() ?? ''),
        keyboardType: TextInputType.number,
        onChanged: (text) => onChanged(int.tryParse(text)),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 16,
          color: AppColors.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 12),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 14,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
