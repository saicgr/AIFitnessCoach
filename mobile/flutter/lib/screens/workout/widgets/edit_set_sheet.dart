import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/workout.dart';

/// Mutable data class backing each editable set row.
class _EditableSet {
  int setNumber;
  int reps;
  double weightKg;
  double? rpe;
  String setType;

  _EditableSet({
    required this.setNumber,
    required this.reps,
    required this.weightKg,
    this.rpe,
    this.setType = 'working',
  });

  Map<String, dynamic> toMap() => {
        'set_number': setNumber,
        'reps': reps,
        'weight_kg': weightKg,
        'rpe': rpe,
        'set_type': setType,
      };
}

class EditSetSheet extends StatefulWidget {
  final String exerciseName;
  final List<SetLogInfo> initialSets;
  final bool isDark;
  final Color accentColor;
  final Function(List<Map<String, dynamic>> sets) onSave;

  const EditSetSheet({
    super.key,
    required this.exerciseName,
    required this.initialSets,
    required this.isDark,
    required this.accentColor,
    required this.onSave,
  });

  /// Convenience method to show the sheet as a modal bottom sheet.
  static Future<void> show(
    BuildContext context, {
    required String exerciseName,
    required List<SetLogInfo> initialSets,
    required bool isDark,
    required Color accentColor,
    required Function(List<Map<String, dynamic>> sets) onSave,
  }) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (context, scrollController) => EditSetSheet(
          exerciseName: exerciseName,
          initialSets: initialSets,
          isDark: isDark,
          accentColor: accentColor,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<EditSetSheet> createState() => _EditSetSheetState();
}

class _EditSetSheetState extends State<EditSetSheet> {
  late final List<_EditableSet> _sets;
  final _formKey = GlobalKey<FormState>();

  // Controllers keyed by set index — rebuilt when the list changes.
  final Map<int, TextEditingController> _repsControllers = {};
  final Map<int, TextEditingController> _weightControllers = {};
  final Map<int, TextEditingController> _rpeControllers = {};

  @override
  void initState() {
    super.initState();
    _sets = widget.initialSets.map((s) {
      return _EditableSet(
        setNumber: s.setNumber,
        reps: s.repsCompleted,
        weightKg: s.weightKg,
        rpe: s.rpe,
        setType: s.setType,
      );
    }).toList();

    // Ensure at least one set
    if (_sets.isEmpty) {
      _sets.add(_EditableSet(setNumber: 1, reps: 0, weightKg: 0));
    }

    _syncControllers();
  }

  void _syncControllers() {
    // Dispose old controllers that are no longer needed
    final validIndices = List.generate(_sets.length, (i) => i).toSet();
    _repsControllers.keys
        .where((k) => !validIndices.contains(k))
        .toList()
        .forEach((k) {
      _repsControllers[k]?.dispose();
      _repsControllers.remove(k);
    });
    _weightControllers.keys
        .where((k) => !validIndices.contains(k))
        .toList()
        .forEach((k) {
      _weightControllers[k]?.dispose();
      _weightControllers.remove(k);
    });
    _rpeControllers.keys
        .where((k) => !validIndices.contains(k))
        .toList()
        .forEach((k) {
      _rpeControllers[k]?.dispose();
      _rpeControllers.remove(k);
    });

    // Create controllers for new indices
    for (int i = 0; i < _sets.length; i++) {
      final s = _sets[i];
      _repsControllers.putIfAbsent(
          i, () => TextEditingController(text: s.reps.toString()));
      _weightControllers.putIfAbsent(
          i,
          () => TextEditingController(
              text: s.weightKg == s.weightKg.roundToDouble()
                  ? s.weightKg.toInt().toString()
                  : s.weightKg.toStringAsFixed(1)));
      _rpeControllers.putIfAbsent(
          i,
          () => TextEditingController(
              text: s.rpe != null ? s.rpe!.toStringAsFixed(0) : ''));
    }
  }

  @override
  void dispose() {
    for (final c in _repsControllers.values) {
      c.dispose();
    }
    for (final c in _weightControllers.values) {
      c.dispose();
    }
    for (final c in _rpeControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════

  void _addSet() {
    final lastSet = _sets.last;
    setState(() {
      _sets.add(_EditableSet(
        setNumber: _sets.length + 1,
        reps: lastSet.reps,
        weightKg: lastSet.weightKg,
        rpe: lastSet.rpe,
        setType: lastSet.setType,
      ));
      _syncControllers();
    });
  }

  void _deleteSet(int index) {
    if (_sets.length <= 1) return;

    void doDelete() {
      setState(() {
        // Dispose controllers for this index
        _repsControllers[index]?.dispose();
        _repsControllers.remove(index);
        _weightControllers[index]?.dispose();
        _weightControllers.remove(index);
        _rpeControllers[index]?.dispose();
        _rpeControllers.remove(index);

        _sets.removeAt(index);

        // Renumber sets
        for (int i = 0; i < _sets.length; i++) {
          _sets[i].setNumber = i + 1;
        }

        // Rebuild controller map with correct indices
        final oldReps =
            Map<int, TextEditingController>.from(_repsControllers);
        final oldWeights =
            Map<int, TextEditingController>.from(_weightControllers);
        final oldRpe =
            Map<int, TextEditingController>.from(_rpeControllers);
        _repsControllers.clear();
        _weightControllers.clear();
        _rpeControllers.clear();

        // Re-assign remaining controllers in order
        int ci = 0;
        for (final entry in oldReps.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
          if (entry.key != index) {
            _repsControllers[ci] = entry.value;
            ci++;
          }
        }
        ci = 0;
        for (final entry in oldWeights.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
          if (entry.key != index) {
            _weightControllers[ci] = entry.value;
            ci++;
          }
        }
        ci = 0;
        for (final entry in oldRpe.entries.toList()..sort((a, b) => a.key.compareTo(b.key))) {
          if (entry.key != index) {
            _rpeControllers[ci] = entry.value;
            ci++;
          }
        }

        _syncControllers();
      });
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor:
            widget.isDark ? AppColors.elevated : Colors.white,
        title: Text(
          'Delete Set ${index + 1}?',
          style: TextStyle(
            color: widget.isDark ? AppColors.textPrimary : Colors.black87,
          ),
        ),
        content: Text(
          'This set will be removed.',
          style: TextStyle(
            color:
                widget.isDark ? AppColors.textSecondary : Colors.grey.shade600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: widget.isDark
                    ? AppColors.textSecondary
                    : Colors.grey.shade600,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              doDelete();
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _commitFieldValues() {
    for (int i = 0; i < _sets.length; i++) {
      final repsText = _repsControllers[i]?.text ?? '';
      final weightText = _weightControllers[i]?.text ?? '';
      final rpeText = _rpeControllers[i]?.text ?? '';

      _sets[i].reps = int.tryParse(repsText) ?? 0;
      _sets[i].weightKg = double.tryParse(weightText) ?? 0.0;
      _sets[i].rpe =
          rpeText.isNotEmpty ? double.tryParse(rpeText) : null;
    }
  }

  void _onSave() {
    _commitFieldValues();

    if (!(_formKey.currentState?.validate() ?? false)) return;

    // Renumber before saving
    for (int i = 0; i < _sets.length; i++) {
      _sets[i].setNumber = i + 1;
    }

    widget.onSave(_sets.map((s) => s.toMap()).toList());
    Navigator.pop(context);
  }

  // ═══════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final accent = widget.accentColor;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nearBlack : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.shade200,
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            _buildHeader(isDark),

            const SizedBox(height: 4),

            // Column headers
            _buildColumnHeaders(isDark),

            // Set list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _sets.length,
                itemBuilder: (context, index) =>
                    _buildSetRow(index, isDark),
              ),
            ),

            // Add set button
            _buildAddSetButton(isDark, accent),

            // Save button
            _buildSaveButton(isDark, accent),

            SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Sets',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textPrimary : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.exerciseName,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondary
                        : Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.grey.shade100,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // COLUMN HEADERS
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildColumnHeaders(bool isDark) {
    final style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: isDark ? AppColors.textMuted : Colors.grey.shade500,
      letterSpacing: 0.5,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          SizedBox(width: 32, child: Text('SET', style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text('REPS', style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 3, child: Text('WEIGHT (kg)', style: style)),
          const SizedBox(width: 8),
          Expanded(flex: 2, child: Text('RPE', style: style)),
          const SizedBox(width: 36), // space for delete icon
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SET ROW
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSetRow(int index, bool isDark) {
    final set = _sets[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.04)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Set number label
          SizedBox(
            width: 32,
            child: Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${set.setNumber}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimary : Colors.black87,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps field
          Expanded(
            flex: 3,
            child: _buildNumberField(
              controller: _repsControllers[index]!,
              isDark: isDark,
              hintText: '0',
              isDecimal: false,
              validator: (value) {
                final v = int.tryParse(value ?? '');
                if (v == null || v <= 0) return '';
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),

          // Weight field
          Expanded(
            flex: 3,
            child: _buildNumberField(
              controller: _weightControllers[index]!,
              isDark: isDark,
              hintText: '0',
              isDecimal: true,
              validator: (value) {
                final v = double.tryParse(value ?? '');
                if (v == null || v < 0) return '';
                return null;
              },
            ),
          ),
          const SizedBox(width: 8),

          // RPE field (optional)
          Expanded(
            flex: 2,
            child: _buildNumberField(
              controller: _rpeControllers[index]!,
              isDark: isDark,
              hintText: '-',
              isDecimal: false,
              validator: (value) {
                if (value == null || value.isEmpty) return null; // optional
                final v = double.tryParse(value);
                if (v == null || v < 1 || v > 10) return '';
                return null;
              },
            ),
          ),

          // Delete button
          SizedBox(
            width: 36,
            child: _sets.length > 1
                ? IconButton(
                    onPressed: () => _deleteSet(index),
                    icon: Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: AppColors.error.withValues(alpha: 0.8),
                    ),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 32, minHeight: 32),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // NUMBER FIELD
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildNumberField({
    required TextEditingController controller,
    required bool isDark,
    required String hintText,
    required bool isDecimal,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: [
        if (isDecimal)
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,1}'))
        else
          FilteringTextInputFormatter.digitsOnly,
      ],
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColors.textPrimary : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          fontSize: 14,
          color: isDark ? AppColors.textMuted : Colors.grey.shade400,
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.grey.shade100,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.grey.shade200,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: widget.accentColor.withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.error.withValues(alpha: 0.6),
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        errorStyle: const TextStyle(fontSize: 0, height: 0),
        isDense: true,
      ),
      validator: validator,
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // ADD SET BUTTON
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildAddSetButton(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: _addSet,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.grey.shade200,
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_rounded,
                size: 18,
                color: isDark ? AppColors.textSecondary : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'Add Set',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark ? AppColors.textSecondary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SAVE BUTTON
  // ═══════════════════════════════════════════════════════════════════

  Widget _buildSaveButton(bool isDark, Color accent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton(
          onPressed: _onSave,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor:
                isDark ? AppColors.accentContrast : AppColors.accentContrast,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            'Save Changes',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
