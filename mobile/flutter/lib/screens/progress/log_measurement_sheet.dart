import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/services/api_client.dart';

/// Model for body measurement entry
class BodyMeasurement {
  final String? id;
  final String userId;
  final DateTime measuredAt;
  final double? waistCm;
  final double? chestCm;
  final double? hipsCm;
  final double? neckCm;
  final double? leftBicepCm;
  final double? rightBicepCm;
  final double? leftForearmCm;
  final double? rightForearmCm;
  final double? leftThighCm;
  final double? rightThighCm;
  final double? leftCalfCm;
  final double? rightCalfCm;
  final double? shouldersCm;
  final double? bodyFatPercentage;
  final String? notes;

  BodyMeasurement({
    this.id,
    required this.userId,
    required this.measuredAt,
    this.waistCm,
    this.chestCm,
    this.hipsCm,
    this.neckCm,
    this.leftBicepCm,
    this.rightBicepCm,
    this.leftForearmCm,
    this.rightForearmCm,
    this.leftThighCm,
    this.rightThighCm,
    this.leftCalfCm,
    this.rightCalfCm,
    this.shouldersCm,
    this.bodyFatPercentage,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'measured_at': measuredAt.toIso8601String(),
      if (waistCm != null) 'waist_cm': waistCm,
      if (chestCm != null) 'chest_cm': chestCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (neckCm != null) 'neck_cm': neckCm,
      if (leftBicepCm != null) 'left_bicep_cm': leftBicepCm,
      if (rightBicepCm != null) 'right_bicep_cm': rightBicepCm,
      if (leftForearmCm != null) 'left_forearm_cm': leftForearmCm,
      if (rightForearmCm != null) 'right_forearm_cm': rightForearmCm,
      if (leftThighCm != null) 'left_thigh_cm': leftThighCm,
      if (rightThighCm != null) 'right_thigh_cm': rightThighCm,
      if (leftCalfCm != null) 'left_calf_cm': leftCalfCm,
      if (rightCalfCm != null) 'right_calf_cm': rightCalfCm,
      if (shouldersCm != null) 'shoulders_cm': shouldersCm,
      if (bodyFatPercentage != null) 'body_fat_percentage': bodyFatPercentage,
      if (notes != null) 'notes': notes,
    };
  }

  factory BodyMeasurement.fromJson(Map<String, dynamic> json) {
    return BodyMeasurement(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      measuredAt: DateTime.parse(json['measured_at'] as String),
      waistCm: (json['waist_cm'] as num?)?.toDouble(),
      chestCm: (json['chest_cm'] as num?)?.toDouble(),
      hipsCm: (json['hips_cm'] as num?)?.toDouble(),
      neckCm: (json['neck_cm'] as num?)?.toDouble(),
      leftBicepCm: (json['left_bicep_cm'] as num?)?.toDouble(),
      rightBicepCm: (json['right_bicep_cm'] as num?)?.toDouble(),
      leftForearmCm: (json['left_forearm_cm'] as num?)?.toDouble(),
      rightForearmCm: (json['right_forearm_cm'] as num?)?.toDouble(),
      leftThighCm: (json['left_thigh_cm'] as num?)?.toDouble(),
      rightThighCm: (json['right_thigh_cm'] as num?)?.toDouble(),
      leftCalfCm: (json['left_calf_cm'] as num?)?.toDouble(),
      rightCalfCm: (json['right_calf_cm'] as num?)?.toDouble(),
      shouldersCm: (json['shoulders_cm'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
    );
  }
}

class LogMeasurementSheet extends ConsumerStatefulWidget {
  final String userId;
  final BodyMeasurement? existingMeasurement;

  const LogMeasurementSheet({
    super.key,
    required this.userId,
    this.existingMeasurement,
  });

  @override
  ConsumerState<LogMeasurementSheet> createState() =>
      _LogMeasurementSheetState();
}

class _LogMeasurementSheetState extends ConsumerState<LogMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  DateTime _selectedDate = DateTime.now();
  bool _isSaving = false;

  // Controllers for each measurement
  final _waistController = TextEditingController();
  final _chestController = TextEditingController();
  final _hipsController = TextEditingController();
  final _neckController = TextEditingController();
  final _leftBicepController = TextEditingController();
  final _rightBicepController = TextEditingController();
  final _leftForearmController = TextEditingController();
  final _rightForearmController = TextEditingController();
  final _leftThighController = TextEditingController();
  final _rightThighController = TextEditingController();
  final _leftCalfController = TextEditingController();
  final _rightCalfController = TextEditingController();
  final _shouldersController = TextEditingController();
  final _bodyFatController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingMeasurement != null) {
      _populateExisting(widget.existingMeasurement!);
    }
  }

  void _populateExisting(BodyMeasurement m) {
    _selectedDate = m.measuredAt;
    if (m.waistCm != null) _waistController.text = m.waistCm!.toString();
    if (m.chestCm != null) _chestController.text = m.chestCm!.toString();
    if (m.hipsCm != null) _hipsController.text = m.hipsCm!.toString();
    if (m.neckCm != null) _neckController.text = m.neckCm!.toString();
    if (m.leftBicepCm != null) _leftBicepController.text = m.leftBicepCm!.toString();
    if (m.rightBicepCm != null) _rightBicepController.text = m.rightBicepCm!.toString();
    if (m.leftForearmCm != null) _leftForearmController.text = m.leftForearmCm!.toString();
    if (m.rightForearmCm != null) _rightForearmController.text = m.rightForearmCm!.toString();
    if (m.leftThighCm != null) _leftThighController.text = m.leftThighCm!.toString();
    if (m.rightThighCm != null) _rightThighController.text = m.rightThighCm!.toString();
    if (m.leftCalfCm != null) _leftCalfController.text = m.leftCalfCm!.toString();
    if (m.rightCalfCm != null) _rightCalfController.text = m.rightCalfCm!.toString();
    if (m.shouldersCm != null) _shouldersController.text = m.shouldersCm!.toString();
    if (m.bodyFatPercentage != null) _bodyFatController.text = m.bodyFatPercentage!.toString();
    if (m.notes != null) _notesController.text = m.notes!;
  }

  @override
  void dispose() {
    _waistController.dispose();
    _chestController.dispose();
    _hipsController.dispose();
    _neckController.dispose();
    _leftBicepController.dispose();
    _rightBicepController.dispose();
    _leftForearmController.dispose();
    _rightForearmController.dispose();
    _leftThighController.dispose();
    _rightThighController.dispose();
    _leftCalfController.dispose();
    _rightCalfController.dispose();
    _shouldersController.dispose();
    _bodyFatController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.6),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outline.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  Text(
                    'Log Measurements',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _isSaving ? null : _saveMeasurement,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save'),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding + 16),
                  children: [
                    // Date Picker
                    _buildDatePicker(),
                    const SizedBox(height: 24),

                    // Core Measurements
                    _buildSectionHeader('Core Measurements', Icons.accessibility),
                    const SizedBox(height: 12),
                    _buildMeasurementRow(
                      'Waist',
                      _waistController,
                      'Around belly button',
                    ),
                    _buildMeasurementRow(
                      'Chest',
                      _chestController,
                      'Under armpits',
                    ),
                    _buildMeasurementRow(
                      'Hips',
                      _hipsController,
                      'Widest point',
                    ),
                    _buildMeasurementRow(
                      'Shoulders',
                      _shouldersController,
                      'Across front',
                    ),
                    _buildMeasurementRow(
                      'Neck',
                      _neckController,
                      'Below Adam\'s apple',
                    ),

                    const SizedBox(height: 24),

                    // Arms
                    _buildSectionHeader('Arms', Icons.fitness_center),
                    const SizedBox(height: 12),
                    _buildMeasurementRow(
                      'Left Bicep',
                      _leftBicepController,
                      'Flexed at peak',
                    ),
                    _buildMeasurementRow(
                      'Right Bicep',
                      _rightBicepController,
                      'Flexed at peak',
                    ),
                    _buildMeasurementRow(
                      'Left Forearm',
                      _leftForearmController,
                      'Widest point',
                    ),
                    _buildMeasurementRow(
                      'Right Forearm',
                      _rightForearmController,
                      'Widest point',
                    ),

                    const SizedBox(height: 24),

                    // Legs
                    _buildSectionHeader('Legs', Icons.directions_walk),
                    const SizedBox(height: 12),
                    _buildMeasurementRow(
                      'Left Thigh',
                      _leftThighController,
                      'Widest point',
                    ),
                    _buildMeasurementRow(
                      'Right Thigh',
                      _rightThighController,
                      'Widest point',
                    ),
                    _buildMeasurementRow(
                      'Left Calf',
                      _leftCalfController,
                      'Widest point',
                    ),
                    _buildMeasurementRow(
                      'Right Calf',
                      _rightCalfController,
                      'Widest point',
                    ),

                    const SizedBox(height: 24),

                    // Body Composition
                    _buildSectionHeader('Body Composition', Icons.monitor_weight),
                    const SizedBox(height: 12),
                    _buildMeasurementRow(
                      'Body Fat %',
                      _bodyFatController,
                      'If known',
                      suffix: '%',
                    ),

                    const SizedBox(height: 24),

                    // Notes
                    _buildSectionHeader('Notes', Icons.note),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Any notes about this measurement...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: colorScheme.primary),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Measurement Date',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 20, color: colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildMeasurementRow(
    String label,
    TextEditingController controller,
    String hint, {
    String suffix = 'cm',
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  hint,
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                suffixText: suffix,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _saveMeasurement() async {
    // Check if at least one measurement is entered
    final hasAnyMeasurement = [
      _waistController.text,
      _chestController.text,
      _hipsController.text,
      _neckController.text,
      _leftBicepController.text,
      _rightBicepController.text,
      _leftForearmController.text,
      _rightForearmController.text,
      _leftThighController.text,
      _rightThighController.text,
      _leftCalfController.text,
      _rightCalfController.text,
      _shouldersController.text,
      _bodyFatController.text,
    ].any((c) => c.isNotEmpty);

    if (!hasAnyMeasurement) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least one measurement'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final measurement = BodyMeasurement(
        userId: widget.userId,
        measuredAt: _selectedDate,
        waistCm: _parseDouble(_waistController.text),
        chestCm: _parseDouble(_chestController.text),
        hipsCm: _parseDouble(_hipsController.text),
        neckCm: _parseDouble(_neckController.text),
        leftBicepCm: _parseDouble(_leftBicepController.text),
        rightBicepCm: _parseDouble(_rightBicepController.text),
        leftForearmCm: _parseDouble(_leftForearmController.text),
        rightForearmCm: _parseDouble(_rightForearmController.text),
        leftThighCm: _parseDouble(_leftThighController.text),
        rightThighCm: _parseDouble(_rightThighController.text),
        leftCalfCm: _parseDouble(_leftCalfController.text),
        rightCalfCm: _parseDouble(_rightCalfController.text),
        shouldersCm: _parseDouble(_shouldersController.text),
        bodyFatPercentage: _parseDouble(_bodyFatController.text),
        notes: _notesController.text.isEmpty ? null : _notesController.text,
      );

      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        '/body-measurements',
        data: measurement.toJson(),
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Measurements saved!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving measurement: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  double? _parseDouble(String value) {
    if (value.isEmpty) return null;
    return double.tryParse(value);
  }
}
