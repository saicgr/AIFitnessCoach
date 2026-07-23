import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/equipment_calibration.dart';
import '../../data/repositories/equipment_calibration_repository.dart';
import '../../widgets/pill_app_bar.dart';

import '../../l10n/generated/app_localizations.dart';
import '../common/app_refresh_indicator.dart';
/// Per-user equipment calibration — Phase 1 of workouts overhaul.
///
/// Lets the user tell the app the *actual* weight of their gym hardware so
/// plate math and weight suggestions match reality. From the r/Gravl
/// migration thread: "I told it my EZ bar is 17.5lb, which allows it to
/// give me weight options for exercises properly."
///
/// Routes:
///   • /equipment/calibration                  — list view
///   • /equipment/calibration/<id>             — edit a row
///   • /equipment/calibration/new              — add a new row
class EquipmentCalibrationScreen extends ConsumerWidget {
  const EquipmentCalibrationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final calibrationsAsync = ref.watch(equipmentCalibrationListProvider);

    return Scaffold(
      backgroundColor: bg,
      appBar: PillAppBar(
        title: AppLocalizations.of(context).equipmentCalibrationTitle,
        actions: [
          PillAppBarAction(
            icon: Icons.add_rounded,
            onTap: () => _openEditor(context, ref, null),
          ),
        ],
      ),
      body: SafeArea(
        child: calibrationsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _errorView(context, e, textPrimary, () {
            // Refresh — invalidates the FutureProvider, which re-runs list().
            ref.invalidate(equipmentCalibrationListProvider);
          }),
          data: (items) {
            if (items.isEmpty) {
              return _emptyView(context, textPrimary, () => _openEditor(context, ref, null));
            }
            return AppRefreshIndicator(
              onRefresh: () async {
                ref.read(equipmentCalibrationRepositoryProvider).invalidate();
                ref.invalidate(equipmentCalibrationListProvider);
                await ref.read(equipmentCalibrationListProvider.future);
              },
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                itemCount: items.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  if (i == 0) {
                    return _intro(context, textPrimary);
                  }
                  final c = items[i - 1];
                  return _CalibrationCard(
                    calibration: c,
                    onTap: () => _openEditor(context, ref, c),
                    onDelete: () => _confirmDelete(context, ref, c),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }

  void _openEditor(
    BuildContext context,
    WidgetRef ref,
    EquipmentCalibration? existing,
  ) {
    showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalibrationEditorSheet(existing: existing),
    ).then((didChange) {
      if (didChange == true) {
        ref.invalidate(equipmentCalibrationListProvider);
      }
    });
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EquipmentCalibration c,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Remove ${c.label ?? c.category ?? 'equipment'}?'),
        content: Text(AppLocalizations.of(context).equipmentCalibrationPlateMathWillFall),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).buttonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: Text(AppLocalizations.of(context).workoutPlanDrawerRemove),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(equipmentCalibrationRepositoryProvider).delete(c.id);
      ref.invalidate(equipmentCalibrationListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  Widget _intro(BuildContext context, Color textPrimary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context).equipmentCalibrationIntroTitle,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Plate suggestions and weight prescriptions will match what you '
            'actually own. Set your bar weights, machine sled weights, cable '
            'pin increments, and plate / dumbbell inventory.',
            style: TextStyle(
              fontSize: 13,
              color: textPrimary.withOpacity(0.7),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyView(BuildContext context, Color textPrimary, VoidCallback onAdd) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _intro(context, textPrimary),
        const SizedBox(height: 32),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.fitness_center,
                size: 64,
                color: textPrimary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context).equipmentCalibrationNoCalibratedEquipmentYet,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context).equipmentCalibrationAddABarbellMachine,
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary.withOpacity(0.65),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: Text(AppLocalizations.of(context).equipmentCalibrationAddEquipment),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _errorView(
    BuildContext context,
    Object error,
    Color textPrimary,
    VoidCallback onRetry,
  ) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          Icons.error_outline,
          size: 48,
          color: textPrimary.withOpacity(0.5),
        ),
        const SizedBox(height: 12),
        Text(
          AppLocalizations.of(context).equipmentCalibrationCouldNotLoadCalibrations,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          '$error',
          style: TextStyle(
            fontSize: 12,
            color: textPrimary.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: Text(AppLocalizations.of(context).buttonRetry),
          ),
        ),
      ],
    );
  }
}

/// Card showing one calibration row at-a-glance.
class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard({
    required this.calibration,
    required this.onTap,
    required this.onDelete,
  });

  final EquipmentCalibration calibration;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final lines = _summary(calibration);
    final title = calibration.label ??
        _humanCategory(calibration.category) ??
        'Equipment';

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              _categoryIcon(calibration.category),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    if (lines.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        lines.join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: textPrimary.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, size: 20),
                color: textPrimary.withOpacity(0.5),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _categoryIcon(String? category) {
    final icon = switch (category) {
      'barbell' => Icons.fitness_center,
      'dumbbell' => Icons.sports_gymnastics,
      'cable' => Icons.linear_scale,
      'machine' => Icons.settings_input_component,
      'plate_set' => Icons.album,
      'kettlebell' => Icons.sports_handball,
      _ => Icons.fitness_center_outlined,
    };
    return Icon(icon, size: 28);
  }

  static String? _humanCategory(String? c) => switch (c) {
        'barbell' => 'Barbell',
        'dumbbell' => 'Dumbbells',
        'cable' => 'Cable machine',
        'machine' => 'Plate-loaded machine',
        'plate_set' => 'Plate set',
        'kettlebell' => 'Kettlebells',
        'other' => 'Equipment',
        null => null,
        _ => c,
      };

  static List<String> _summary(EquipmentCalibration c) {
    final out = <String>[];
    final unit = c.weightUnit;
    if (c.barEmptyWeightKg != null) {
      final v = c.barEmptyWeightIn(unit) ?? c.barEmptyWeightKg!;
      out.add('Bar ${_fmt(v)}$unit');
    }
    if (c.machineEmptyWeightKg != null) {
      final v = c.machineEmptyWeightIn(unit) ?? c.machineEmptyWeightKg!;
      out.add('Sled +${_fmt(v)}$unit');
    }
    if (c.cablePinIncrementKg != null) {
      final v = unit == 'lb'
          ? c.cablePinIncrementKg! / 0.45359237
          : c.cablePinIncrementKg!;
      out.add('Pin ${_fmt(v)}$unit steps');
    }
    if (c.plateInventory.isNotEmpty) {
      out.add('${c.plateInventory.length} plate sizes');
    }
    if (c.dumbbellInventory.isNotEmpty) {
      out.add('${c.dumbbellInventory.length} DB sizes');
    }
    return out;
  }

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
  }
}

/// Bottom-sheet editor for creating or updating a calibration row.
class _CalibrationEditorSheet extends ConsumerStatefulWidget {
  const _CalibrationEditorSheet({this.existing});
  final EquipmentCalibration? existing;

  @override
  ConsumerState<_CalibrationEditorSheet> createState() =>
      _CalibrationEditorSheetState();
}

class _CalibrationEditorSheetState
    extends ConsumerState<_CalibrationEditorSheet> {
  late String _category;
  late String _weightUnit;
  late final TextEditingController _labelCtl;
  late final TextEditingController _barCtl;
  late final TextEditingController _sledCtl;
  late final TextEditingController _cablePinStartCtl;
  late final TextEditingController _cablePinIncCtl;
  late final TextEditingController _plateInvCtl;
  late final TextEditingController _dbInvCtl;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _category = e?.category ?? 'barbell';
    _weightUnit = e?.weightUnit ?? 'lb';
    _labelCtl = TextEditingController(text: e?.label ?? '');
    _barCtl = TextEditingController(
      text: e?.barEmptyWeightIn(_weightUnit)?.toStringAsFixed(2) ?? '',
    );
    _sledCtl = TextEditingController(
      text: e?.machineEmptyWeightIn(_weightUnit)?.toStringAsFixed(2) ?? '',
    );
    final pinStartUnit = _weightUnit == 'lb'
        ? (e?.cablePinStartKg ?? 0) / 0.45359237
        : (e?.cablePinStartKg ?? 0);
    final pinIncUnit = _weightUnit == 'lb'
        ? (e?.cablePinIncrementKg ?? 0) / 0.45359237
        : (e?.cablePinIncrementKg ?? 0);
    _cablePinStartCtl = TextEditingController(
      text: e?.cablePinStartKg == null ? '' : pinStartUnit.toStringAsFixed(2),
    );
    _cablePinIncCtl = TextEditingController(
      text: e?.cablePinIncrementKg == null ? '' : pinIncUnit.toStringAsFixed(2),
    );
    _plateInvCtl = TextEditingController(
      text: _inventoryToCsv(e?.plateInventory ?? const {}),
    );
    _dbInvCtl = TextEditingController(
      text: _inventoryToCsv(e?.dumbbellInventory ?? const {}),
    );
  }

  @override
  void dispose() {
    _labelCtl.dispose();
    _barCtl.dispose();
    _sledCtl.dispose();
    _cablePinStartCtl.dispose();
    _cablePinIncCtl.dispose();
    _plateInvCtl.dispose();
    _dbInvCtl.dispose();
    super.dispose();
  }

  static String _inventoryToCsv(Map<String, int> inv) {
    if (inv.isEmpty) return '';
    final entries = inv.entries.toList()
      ..sort((a, b) => double.parse(b.key).compareTo(double.parse(a.key)));
    return entries.map((e) => '${e.key}×${e.value}').join(', ');
  }

  /// Parse "45x4, 25x4, 10x2, 5x2" into {"45":4,"25":4,"10":2,"5":2}.
  /// Accepts × and x and *. Tolerates "45 x 4" with spaces.
  static Map<String, int>? _csvToInventory(String input) {
    final s = input.trim();
    if (s.isEmpty) return const {};
    final out = <String, int>{};
    for (final raw in s.split(RegExp(r'[,;\n]'))) {
      final piece = raw.trim();
      if (piece.isEmpty) continue;
      final m = RegExp(r'^([0-9]+(?:\.[0-9]+)?)\s*[x×*]\s*([0-9]+)$')
          .firstMatch(piece);
      if (m == null) return null;
      out[m.group(1)!] = int.parse(m.group(2)!);
    }
    return out;
  }

  /// Convert UI input (in user's chosen unit) to kg for the backend.
  double? _toKg(String text) {
    final v = double.tryParse(text.trim());
    if (v == null) return null;
    return _weightUnit == 'lb' ? v * 0.45359237 : v;
  }

  Future<void> _save() async {
    final plateInv = _csvToInventory(_plateInvCtl.text);
    final dbInv = _csvToInventory(_dbInvCtl.text);
    if (plateInv == null) {
      setState(() => _error = 'Plate inventory format: 45x4, 25x4, 10x2');
      return;
    }
    if (dbInv == null) {
      setState(() => _error = 'Dumbbell inventory format: 20x2, 25x2, 30x1');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(equipmentCalibrationRepositoryProvider);
      if (widget.existing == null) {
        await repo.create(
          label: _labelCtl.text.trim().isEmpty ? null : _labelCtl.text.trim(),
          category: _category,
          barEmptyWeightKg: _toKg(_barCtl.text),
          machineEmptyWeightKg: _toKg(_sledCtl.text),
          cablePinStartKg: _toKg(_cablePinStartCtl.text),
          cablePinIncrementKg: _toKg(_cablePinIncCtl.text),
          plateInventory: plateInv.isEmpty ? null : plateInv,
          dumbbellInventory: dbInv.isEmpty ? null : dbInv,
          weightUnit: _weightUnit,
        );
      } else {
        await repo.patch(
          widget.existing!.id,
          label: _labelCtl.text.trim().isEmpty ? null : _labelCtl.text.trim(),
          category: _category,
          barEmptyWeightKg: _toKg(_barCtl.text),
          machineEmptyWeightKg: _toKg(_sledCtl.text),
          cablePinStartKg: _toKg(_cablePinStartCtl.text),
          cablePinIncrementKg: _toKg(_cablePinIncCtl.text),
          plateInventory: plateInv,
          dumbbellInventory: dbInv,
          weightUnit: _weightUnit,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _saving = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).colorScheme.surface;
    final textPrimary = Theme.of(context).colorScheme.onSurface;
    final mq = MediaQuery.of(context);

    final showBar = _category == 'barbell';
    final showSled = _category == 'machine';
    final showCable = _category == 'cable' || _category == 'machine';
    final showPlates = _category == 'barbell' || _category == 'plate_set';
    final showDb = _category == 'dumbbell';

    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: textPrimary.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                widget.existing == null ? AppLocalizations.of(context).equipmentCalibrationAddEquipment : AppLocalizations.of(context).equipmentCalibrationEditEquipment,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _categoryPicker(textPrimary),
              const SizedBox(height: 12),
              TextField(
                controller: _labelCtl,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context).equipmentCalibrationLabelOptional,
                  hintText: AppLocalizations.of(context).equipmentCalibrationEGHomeRack,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              _unitToggle(textPrimary),
              const SizedBox(height: 16),
              if (showBar)
                _numericField(
                  controller: _barCtl,
                  label: AppLocalizations.of(context)!.equipmentCalibrationScreenBarEmptyWeight(_weightUnit),
                  hint: _weightUnit == 'lb' ? AppLocalizations.of(context).equipmentCalibration175ForEz : AppLocalizations.of(context).equipmentCalibration794ForEz,
                ),
              if (showSled) ...[
                const SizedBox(height: 12),
                _numericField(
                  controller: _sledCtl,
                  label: AppLocalizations.of(context)!.equipmentCalibrationScreenMachineSledCarriage(_weightUnit),
                  hint: _weightUnit == 'lb' ? AppLocalizations.of(context).equipmentCalibrationLegPress45 : AppLocalizations.of(context).equipmentCalibrationLegPress20,
                ),
              ],
              if (showCable) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _numericField(
                        controller: _cablePinStartCtl,
                        label: AppLocalizations.of(context)!.equipmentCalibrationScreenPinStart(_weightUnit),
                        hint: _weightUnit == 'lb' ? '20' : '9',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _numericField(
                        controller: _cablePinIncCtl,
                        label: AppLocalizations.of(context)!.equipmentCalibrationScreenPinStep(_weightUnit),
                        hint: _weightUnit == 'lb' ? '10' : '5',
                      ),
                    ),
                  ],
                ),
              ],
              if (showPlates) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _plateInvCtl,
                  decoration: InputDecoration(
                    labelText: 'Plate inventory ($_weightUnit × count)',
                    hintText: _weightUnit == 'lb'
                        ? AppLocalizations.of(context).equipmentCalibration45x435x225x410x2
                        : '20x4, 15x2, 10x4, 5x2, 2.5x2, 1.25x2',
                    helperText: AppLocalizations.of(context).equipmentCalibrationLeaveBlankToUse,
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
              ],
              if (showDb) ...[
                const SizedBox(height: 12),
                TextField(
                  controller: _dbInvCtl,
                  decoration: InputDecoration(
                    labelText: 'Dumbbell inventory ($_weightUnit × count)',
                    hintText: _weightUnit == 'lb'
                        ? AppLocalizations.of(context).equipmentCalibration15x220x225x230x2
                        : '7x2, 10x2, 12x2, 15x2, 20x2',
                    border: const OutlineInputBorder(),
                  ),
                  minLines: 1,
                  maxLines: 2,
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.existing == null ? AppLocalizations.of(context).equipmentCalibrationAddEquipment : AppLocalizations.of(context).equipmentCalibrationSaveChanges),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _categoryPicker(Color textPrimary) {
    const items = [
      ('barbell', 'Barbell'),
      ('dumbbell', 'Dumbbells'),
      ('cable', 'Cable'),
      ('machine', 'Plate-loaded machine'),
      ('plate_set', 'Plate set'),
      ('kettlebell', 'Kettlebell'),
    ];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final selected = _category == item.$1;
        return ChoiceChip(
          label: Text(item.$2),
          selected: selected,
          onSelected: (_) => setState(() => _category = item.$1),
        );
      }).toList(),
    );
  }

  Widget _unitToggle(Color textPrimary) {
    return Row(
      children: [
        Text(
          AppLocalizations.of(context).settingsCardUiUnits,
          style: TextStyle(
            fontSize: 13,
            color: textPrimary.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'lb', label: Text('lb')),
            ButtonSegment(value: 'kg', label: Text('kg')),
          ],
          selected: {_weightUnit},
          onSelectionChanged: (set) =>
              setState(() => _weightUnit = set.first),
        ),
      ],
    );
  }

  Widget _numericField({
    required TextEditingController controller,
    required String label,
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
