part of 'measurements_screen.dart';


// ─────────────────────────────────────────────────────────────────
// Add Measurement Sheet
// ─────────────────────────────────────────────────────────────────

class _AddMeasurementSheet extends StatefulWidget {
  final MeasurementType selectedType;
  final bool isMetric;
  final Future<void> Function(MeasurementType type, double value, String unit, String? notes) onSubmit;

  /// When non-null, the sheet is a "quick log" for exactly this measurement:
  /// the group+metric dropdowns are hidden and the user can only edit the
  /// value/notes. Entered from tile tap-to-log / body-view long-press.
  final MeasurementType? lockedType;

  const _AddMeasurementSheet({
    required this.selectedType,
    required this.isMetric,
    required this.onSubmit,
    this.lockedType,
  });

  @override
  State<_AddMeasurementSheet> createState() => _AddMeasurementSheetState();
}


class _AddMeasurementSheetState extends State<_AddMeasurementSheet> {
  late MeasurementType _selectedType;
  late String _selectedGroup;
  late bool _isMetric;
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  String _groupForType(MeasurementType type) {
    for (final group in _MeasurementsScreenState._measurementGroups) {
      final types = group['types'] as List<MeasurementType>;
      if (types.contains(type)) return group['title'] as String;
    }
    return 'Body Composition';
  }

  List<MeasurementType> _typesForGroup(String groupTitle) {
    final group = _MeasurementsScreenState._measurementGroups.firstWhere((g) => g['title'] == groupTitle);
    return group['types'] as List<MeasurementType>;
  }

  @override
  void initState() {
    super.initState();
    // When locked, force the type to the caller's choice so the sheet can't
    // silently drift to a different metric.
    _selectedType = widget.lockedType ?? widget.selectedType;
    _selectedGroup = _groupForType(_selectedType);
    _isMetric = widget.isMetric;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.nearBlack : AppColorsLight.nearWhite;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;
    final unit = _isMetric ? _selectedType.metricUnit : _selectedType.imperialUnit;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.lockedType != null
                      ? 'Log ${widget.lockedType!.displayName}'
                      : 'Add Measurement',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Unit toggle
                GestureDetector(
                  onTap: () {
                    if (_selectedType != MeasurementType.bodyFat) {
                      final val = double.tryParse(_valueController.text);
                      if (val != null) {
                        _valueController.text = (_isMetric ? val / 2.54 : val * 2.54).toStringAsFixed(1);
                      }
                    }
                    setState(() => _isMetric = !_isMetric);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _isMetric ? 'Metric' : 'Imperial',
                      style: TextStyle(
                        fontSize: 12,
                        color: cyan,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Measurement type selector — hidden in locked mode (quick-log
            // from a tile or body-view pill already knows the target).
            if (widget.lockedType == null) ...[
              Text(
                'MEASUREMENT TYPE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGroup,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: textMuted, size: 20),
                          dropdownColor: elevated,
                          style: TextStyle(fontSize: 13, color: textMuted),
                          items: _MeasurementsScreenState._measurementGroups.map((group) {
                            final title = group['title'] as String;
                            return DropdownMenuItem(value: title, child: Text(title));
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            final types = _typesForGroup(value);
                            setState(() {
                              _selectedGroup = value;
                              _selectedType = types.first;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: elevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cyan),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<MeasurementType>(
                          value: _selectedType,
                          isExpanded: true,
                          icon: Icon(Icons.keyboard_arrow_down, color: cyan, size: 20),
                          dropdownColor: elevated,
                          style: TextStyle(fontSize: 13, color: cyan, fontWeight: FontWeight.w600),
                          items: _typesForGroup(_selectedGroup).map((type) {
                            return DropdownMenuItem(
                              value: type,
                              child: Text(type.displayName),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _selectedType = value);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Locked-mode header row: icon chip + metric name.
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cyan.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      // _getIconForType is defined on _MeasurementsScreenState,
                      // same library since this file is `part of`.
                      _MeasurementsScreenState._iconFor(_selectedType),
                      color: cyan,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _selectedType.displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Value input
            Text(
              'VALUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _valueController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: '0.0',
                suffix: _selectedType == MeasurementType.bodyFat
                    ? Text('%', style: TextStyle(color: textMuted))
                    : GestureDetector(
                        onTap: () {
                          final val = double.tryParse(_valueController.text);
                          if (val != null) {
                            _valueController.text = (_isMetric ? val / 2.54 : val * 2.54).toStringAsFixed(1);
                          }
                          setState(() => _isMetric = !_isMetric);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cyan.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: cyan.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(unit, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: cyan)),
                              const SizedBox(width: 3),
                              Icon(Icons.swap_horiz, size: 14, color: cyan.withOpacity(0.7)),
                            ],
                          ),
                        ),
                      ),
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notes input
            Text(
              'NOTES (OPTIONAL)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Add any notes...',
                filled: true,
                fillColor: elevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cyan,
                  foregroundColor: isDark ? AppColors.pureBlack : Colors.white,
                  disabledBackgroundColor: cyan.withOpacity(0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: isDark ? AppColors.pureBlack : Colors.white,
                        ),
                      )
                    : const Text(
                        'Save',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final valueText = _valueController.text.trim();
    if (valueText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a value'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final value = double.tryParse(valueText);
    if (value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final notes = _notesController.text.trim();

    // Single source of truth for lbs→kg / in→cm conversion. See
    // measurement_unit_conversion.dart.
    final converted = convertToMetric(value, _selectedType, !_isMetric);

    await widget.onSubmit(
      _selectedType,
      converted.value,
      converted.unit,
      notes.isNotEmpty ? notes : null,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
    }
  }
}


// ─────────────────────────────────────────────────────────────────
// Measurements Export Sheet
// ─────────────────────────────────────────────────────────────────

class _MeasurementsExportSheet extends StatefulWidget {
  final WidgetRef ref;

  const _MeasurementsExportSheet({required this.ref});

  @override
  State<_MeasurementsExportSheet> createState() => _MeasurementsExportSheetState();
}


class _MeasurementsExportSheetState extends State<_MeasurementsExportSheet> {
  String _selectedFormat = 'csv';
  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedTypes = {
    'weight', 'body_fat', 'chest', 'waist', 'hips', 'neck', 'shoulders',
    'biceps_left', 'biceps_right', 'forearm_left', 'forearm_right',
    'thigh_left', 'thigh_right', 'calf_left', 'calf_right',
  };

  static const _formats = [
    {'label': 'CSV', 'value': 'csv'},
    {'label': 'JSON', 'value': 'json'},
    {'label': 'Excel', 'value': 'xlsx'},
    {'label': 'Parquet', 'value': 'parquet'},
  ];

  static const _allTypes = [
    {'key': 'weight', 'label': 'Weight'},
    {'key': 'body_fat', 'label': 'Body Fat'},
    {'key': 'chest', 'label': 'Chest'},
    {'key': 'waist', 'label': 'Waist'},
    {'key': 'hips', 'label': 'Hips'},
    {'key': 'neck', 'label': 'Neck'},
    {'key': 'shoulders', 'label': 'Shoulders'},
    {'key': 'biceps_left', 'label': 'Biceps L'},
    {'key': 'biceps_right', 'label': 'Biceps R'},
    {'key': 'forearm_left', 'label': 'Forearm L'},
    {'key': 'forearm_right', 'label': 'Forearm R'},
    {'key': 'thigh_left', 'label': 'Thigh L'},
    {'key': 'thigh_right', 'label': 'Thigh R'},
    {'key': 'calf_left', 'label': 'Calf L'},
    {'key': 'calf_right', 'label': 'Calf R'},
  ];

  bool get _allSelected => _selectedTypes.length == _allTypes.length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              children: [
                Icon(Icons.upload_outlined, color: cyan, size: 22),
              const SizedBox(width: 10),
              Text(
                'Export Measurements',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Format label with info button
          Row(
            children: [
              Text(
                'Format',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _showFormatInfoDialog(context),
                child: Icon(Icons.info_outline, size: 16, color: textMuted),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Format chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _formats.map((fmt) {
              final isSelected = _selectedFormat == fmt['value'];
              return ChoiceChip(
                label: Text(fmt['label']!),
                selected: isSelected,
                onSelected: (_) => setState(() => _selectedFormat = fmt['value']!),
                selectedColor: cyan.withOpacity(0.2),
                backgroundColor: elevated,
                side: BorderSide(color: isSelected ? cyan : cardBorder),
                labelStyle: TextStyle(
                  color: isSelected ? cyan : textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Date range filter
          Row(
            children: [
              Text(
                'Date Range',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              if (_startDate != null || _endDate != null)
                GestureDetector(
                  onTap: () => setState(() { _startDate = null; _endDate = null; }),
                  child: Text('Clear', style: TextStyle(fontSize: 12, color: cyan)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _startDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _startDate != null ? DateFormat('MMM d, y').format(_startDate!) : 'Start date',
                      style: TextStyle(fontSize: 13, color: _startDate != null ? textPrimary : textMuted),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('to', style: TextStyle(color: textMuted, fontSize: 12)),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setState(() => _endDate = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: elevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: cardBorder),
                    ),
                    child: Text(
                      _endDate != null ? DateFormat('MMM d, y').format(_endDate!) : 'End date',
                      style: TextStyle(fontSize: 13, color: _endDate != null ? textPrimary : textMuted),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Measurement types filter
          Row(
            children: [
              Text(
                'Measurements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (_allSelected) {
                      _selectedTypes.clear();
                    } else {
                      _selectedTypes.addAll(_allTypes.map((t) => t['key']!));
                    }
                  });
                },
                child: Text(
                  _allSelected ? 'Deselect All' : 'Select All',
                  style: TextStyle(fontSize: 12, color: cyan),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _allTypes.map((t) {
              final key = t['key']!;
              final isSelected = _selectedTypes.contains(key);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedTypes.remove(key);
                    } else {
                      _selectedTypes.add(key);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected ? cyan.withOpacity(0.15) : elevated,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: isSelected ? cyan : cardBorder),
                  ),
                  child: Text(
                    t['label']!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected ? cyan : textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          // Option 1: Measurements Only
          _ExportOptionTile(
            icon: Icons.straighten,
            title: 'Measurements Only',
            subtitle: _selectedTypes.isEmpty
                ? 'Select at least one measurement type'
                : 'Export ${_allSelected ? "all" : "${_selectedTypes.length}"} measurement types as .$_selectedFormat',
            iconColor: _selectedTypes.isEmpty ? textMuted : cyan,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            elevated: elevated,
            cardBorder: cardBorder,
            onTap: _selectedTypes.isEmpty ? () {} : () => _exportMeasurements(context),
          ),
          const SizedBox(height: 10),

          // Option 2: Export All Data
          _ExportOptionTile(
            icon: Icons.cloud_download_outlined,
            title: 'Export All Data',
            subtitle: 'Workouts, nutrition, measurements & more',
            iconColor: cyan,
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            elevated: elevated,
            cardBorder: cardBorder,
            onTap: () {
              Navigator.pop(context);
              showExportDialog(context, widget.ref);
            },
          ),
        ],
        ),
      ),
    );
  }

  void _showFormatInfoDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.elevated : AppColorsLight.pureWhite,
        title: Text('Export Info', style: TextStyle(color: textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columns section
              Text('Exported Columns', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              _columnInfoRow('date', 'When the measurement was recorded', textPrimary, textSecondary),
              _columnInfoRow('type', 'Measurement type (weight, waist, etc.)', textPrimary, textSecondary),
              _columnInfoRow('value', 'The recorded value', textPrimary, textSecondary),
              _columnInfoRow('unit', 'Unit of measurement (kg, %, cm)', textPrimary, textSecondary),
              _columnInfoRow('notes', 'Optional notes for the entry', textPrimary, textSecondary),
              const SizedBox(height: 14),

              // Available types
              Text('Available Measurement Types', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              Text(
                'weight, body_fat, chest, waist, hips, neck, shoulders, biceps_left, biceps_right, forearm_left, forearm_right, thigh_left, thigh_right, calf_left, calf_right',
                style: TextStyle(fontSize: 11, color: textMuted, height: 1.5),
              ),
              const SizedBox(height: 14),

              // Formats section
              Text('Formats', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: cyan)),
              const SizedBox(height: 6),
              _formatInfoRow('CSV', 'Opens in Excel, Google Sheets, any spreadsheet app', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('JSON', 'Structured data. Best for developers or importing into other apps', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('Excel', 'Native .xlsx workbook. Opens directly in Excel', textPrimary, textSecondary),
              const SizedBox(height: 8),
              _formatInfoRow('Parquet', 'Columnar storage. Compact for large datasets. Used in Python/Pandas, R, Spark', textPrimary, textSecondary),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Got it', style: TextStyle(color: cyan)),
          ),
        ],
      ),
    );
  }

  Widget _columnInfoRow(String name, String desc, Color titleColor, Color descColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: titleColor, fontFamily: 'monospace')),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(desc, style: TextStyle(fontSize: 11, color: descColor))),
        ],
      ),
    );
  }

  Widget _formatInfoRow(String name, String desc, Color titleColor, Color descColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: titleColor)),
        const SizedBox(height: 2),
        Text(desc, style: TextStyle(fontSize: 12, color: descColor)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _exportMeasurements(BuildContext context) async {
    final auth = widget.ref.read(authStateProvider);
    if (auth.user == null) return;

    final userId = auth.user!.id;
    final apiClient = widget.ref.read(apiClientProvider);

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final queryParams = <String, String>{
        'format': _selectedFormat,
      };
      if (_startDate != null) queryParams['start_date'] = _formatDate(_startDate!);
      if (_endDate != null) queryParams['end_date'] = _formatDate(_endDate!);
      if (!_allSelected && _selectedTypes.isNotEmpty) {
        queryParams['types'] = _selectedTypes.join(',');
      }

      final useBytes = _selectedFormat != 'json';
      final response = await apiClient.dio.get(
        '${ApiConstants.apiVersion}${ApiConstants.metrics}/body/export/$userId',
        queryParameters: queryParams,
        options: Options(
          responseType: useBytes ? ResponseType.bytes : ResponseType.plain,
        ),
      );

      final dir = await getTemporaryDirectory();
      final ext = _selectedFormat == 'xlsx' ? 'xlsx' : _selectedFormat;
      final file = File('${dir.path}/measurements.$ext');

      if (useBytes) {
        await file.writeAsBytes(response.data as List<int>);
      } else {
        await file.writeAsString(response.data as String);
      }

      // Dismiss loading
      if (context.mounted) Navigator.pop(context);
      // Dismiss export sheet
      if (context.mounted) Navigator.pop(context);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: '${Branding.appName} Measurements Export',
      );
    } catch (e) {
      // Dismiss loading
      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: ${e is DioException ? e.message : e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }
}


class _ExportOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color textPrimary;
  final Color textSecondary;
  final Color elevated;
  final Color cardBorder;
  final VoidCallback onTap;

  const _ExportOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.elevated,
    required this.cardBorder,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: cardBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

