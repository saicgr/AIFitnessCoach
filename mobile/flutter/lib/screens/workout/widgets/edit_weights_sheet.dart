import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/weight_utils.dart';
import '../../../data/providers/gym_profile_provider.dart'
    show activeProfileEnvironmentProvider;
import '../../../models/equipment_item.dart';
import '../../home/widgets/gym_equipment_sheet.dart'
    show stackMachineEquipment;

// ─────────────────────────────────────────────────────────────────────────
// Per-equipment weight tables.
//
// One canonical list per equipment kind + unit, sourced from REP Fitness,
// Bells of Steel, Eleiko, Rogue catalogs. Replaces the previous global
// 5/10/.../100 list that was a one-size-fits-none compromise.
//
// Kettlebells especially need their own list: real bells come in 5 lb gaps
// to 50 lb, then 10 lb gaps; competition bells in 4 kg gaps. Showing
// 55/65/75 lb tiles is misleading — those sizes effectively don't exist.
// ─────────────────────────────────────────────────────────────────────────

const Map<String, List<double>> _equipmentWeightLbs = {
  'dumbbells': [
    2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20, 22.5, 25, 30, 35, 40, 45,
    50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 110, 120,
  ],
  'kettlebells': [
    5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 60, 70, 80, 90, 100,
  ],
  'weight_plates': [1.25, 2.5, 5, 10, 25, 35, 45, 55],
  'bumper_plates': [10, 15, 25, 35, 45, 55],
  'barbell': [15, 25, 35, 45, 55],
  'ez_curl_bar': [15, 20, 25],
  'trap_bar': [45, 60, 75],
  'medicine_ball': [4, 6, 8, 10, 12, 14, 16, 18, 20, 25, 30],
};

const Map<String, List<double>> _equipmentWeightKg = {
  'dumbbells': [
    1, 2, 2.5, 3, 4, 5, 6, 7.5, 8, 10, 12.5, 15, 17.5, 20, 22.5,
    25, 27.5, 30, 32.5, 35, 37.5, 40, 42.5, 45, 50,
  ],
  'kettlebells': [
    4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 36, 40, 44, 48,
  ],
  'weight_plates': [0.5, 1, 1.25, 2.5, 5, 10, 15, 20, 25],
  'bumper_plates': [5, 10, 15, 20, 25],
  'barbell': [7, 10, 15, 20, 25],
  'ez_curl_bar': [6, 8, 10],
  'trap_bar': [20, 25, 30],
  'medicine_ball': [2, 3, 4, 5, 6, 7, 8, 9, 10, 12],
};

/// Equipment-mode dispatch. Replaces the one-size-fits-all qty 0→4 cycle
/// that made no sense for non-dumbbell equipment.
enum _InventoryMode {
  /// Dumbbells. Default qty 2 (a pair). Long-press = +/- pair stepper.
  pairs,

  /// Kettlebells, barbell, ez-curl, trap-bar, medicine-ball — items
  /// typically owned in singles. Binary toggle, no qty badge.
  singles,

  /// Plates (weight_plates, bumper_plates). Tap cycles 0→2→4→6→0 per side;
  /// long-press opens keypad (cap 16).
  count,

  /// Cable machines / stack-based equipment. Uses min/max/step config UI,
  /// not the rack-tile grid.
  stack,
}

/// Preset choices shown in the "Preset ▼" dropdown.
enum _Preset {
  commercialFull,
  homeAdjustable,
  competitionKettlebell,
  microloading,
  clearAll,
}

/// Lowercase + strip trailing 's' (kettlebells → kettlebell, plates → plate)
/// for tolerant string matching. Preserves underscores so 'weight_plates'
/// still matches the table key 'weight_plates' before stripping.
String _normalizeSlug(String name) {
  final lower = name.toLowerCase().trim();
  // Direct hit first.
  if (_equipmentWeightLbs.containsKey(lower)) return lower;
  if (_equipmentWeightKg.containsKey(lower)) return lower;
  // Strip plural 's' on the last token.
  if (lower.endsWith('s')) {
    final singular = lower.substring(0, lower.length - 1);
    if (_equipmentWeightLbs.containsKey('${singular}s')) return '${singular}s';
    if (_equipmentWeightLbs.containsKey(singular)) return singular;
  }
  return lower;
}

/// Sheet for editing available weights for a specific equipment.
///
/// Behavior is mode-dependent ([_InventoryMode]): dumbbells get pair-aware
/// rack tiles, kettlebells/barbell/etc. get binary toggles, plates get
/// per-side count cycling, cable/leg-press get a stack-config UI.
class EditWeightsSheet extends ConsumerStatefulWidget {
  final EquipmentItem equipment;
  final void Function(EquipmentItem updated) onSave;

  const EditWeightsSheet({
    super.key,
    required this.equipment,
    required this.onSave,
  });

  @override
  ConsumerState<EditWeightsSheet> createState() => _EditWeightsSheetState();
}

class _EditWeightsSheetState extends ConsumerState<EditWeightsSheet> {
  late Map<double, int> _weightInventory;
  late String _weightUnit;
  final TextEditingController _customWeightController = TextEditingController();

  // Stack-machine config — only used when _isStackMachine is true.
  late double _stackMin;
  late double _stackMax;
  late double _stackIncrement;

  bool get _isStackMachine =>
      stackMachineEquipment.contains(widget.equipment.name);

  String get _slug => _normalizeSlug(widget.equipment.name);

  /// Pick the inventory mode for the current equipment. See [_InventoryMode].
  _InventoryMode get _mode {
    if (_isStackMachine) return _InventoryMode.stack;
    final s = _slug;
    if (s == 'dumbbells' || s == 'dumbbell') return _InventoryMode.pairs;
    if (s.contains('plate')) return _InventoryMode.count;
    return _InventoryMode.singles;
  }

  /// Default quantity applied when the user selects a fresh weight via tap
  /// or custom input. Pairs default to 2, plates to 4 per side, singles 1.
  int get _modeDefaultQty {
    switch (_mode) {
      case _InventoryMode.pairs:
        return 2;
      case _InventoryMode.count:
        return 4;
      case _InventoryMode.singles:
      case _InventoryMode.stack:
        return 1;
    }
  }

  /// Per-equipment table for the current unit, or a fallback list when the
  /// equipment isn't in the table (custom equipment).
  List<double> get _commonWeights {
    final table = _weightUnit == 'kg' ? _equipmentWeightKg : _equipmentWeightLbs;
    final hit = table[_slug];
    if (hit != null) return hit;
    return _weightUnit == 'kg'
        ? const [5, 10, 15, 20, 25, 30, 35, 40]
        : const [10, 20, 30, 40, 50, 60, 70, 80];
  }

  @override
  void initState() {
    super.initState();
    _weightUnit = widget.equipment.weightUnit;

    // Restore stored inventory, migrating legacy list-of-weights → map.
    if (widget.equipment.weightInventory.isNotEmpty) {
      _weightInventory = Map.from(widget.equipment.weightInventory);
    } else if (widget.equipment.weights.isNotEmpty) {
      _weightInventory = {
        for (final w in widget.equipment.weights) w: _modeDefaultQty,
      };
    } else {
      _weightInventory = {};
    }

    // Backwards-compat normalization. Old UI let users set kettlebell qty=3
    // which is nonsense for singles mode. Squash any noise into the mode's
    // canonical value so subsequent edits round-trip cleanly.
    _normalizeInventoryForMode();

    // Seed from gym profile ONLY when truly empty AND there were no legacy
    // weights either. This protects the mid-workout editor: a quick tweak
    // mid-session must never silently inject 25 commercial-gym defaults.
    if (_weightInventory.isEmpty &&
        widget.equipment.weights.isEmpty &&
        !_isStackMachine) {
      final env = ref.read(activeProfileEnvironmentProvider);
      _weightInventory = _seedForEnvironment(env);
    }

    _initStackConfig();
  }

  /// Walk every stored entry through the mode's expected qty. Heap-stable —
  /// only normalizes obviously-wrong values.
  void _normalizeInventoryForMode() {
    switch (_mode) {
      case _InventoryMode.singles:
        // Any qty > 0 collapses to 1.
        for (final w in _weightInventory.keys.toList()) {
          if ((_weightInventory[w] ?? 0) > 0) _weightInventory[w] = 1;
        }
        break;
      case _InventoryMode.pairs:
        // Treat any qty in [1..3] as the "you own this size" signal and
        // default to a pair. Larger qty (4+) preserved — user explicitly
        // entered it via long-press.
        for (final w in _weightInventory.keys.toList()) {
          final q = _weightInventory[w] ?? 0;
          if (q > 0 && q < 2) _weightInventory[w] = 2;
        }
        break;
      case _InventoryMode.count:
      case _InventoryMode.stack:
        // No normalization needed.
        break;
    }
  }

  void _initStackConfig() {
    if (_weightInventory.isNotEmpty) {
      final sorted = _weightInventory.keys.toList()..sort();
      _stackMin = sorted.first;
      _stackMax = sorted.last;
      _stackIncrement = sorted.length >= 2
          ? (sorted[1] - sorted[0])
          : (_weightUnit == 'kg' ? 5 : 10);
    } else if (_weightUnit == 'kg') {
      _stackMin = 5;
      _stackMax = 100;
      _stackIncrement = 5;
    } else {
      _stackMin = 10;
      _stackMax = 250;
      _stackIncrement = 10;
    }
  }

  /// Per-environment seed. Commercial gym pre-fills the full standard table;
  /// home variants pre-fill a starter subset; sparse environments stay empty.
  Map<double, int> _seedForEnvironment(String env) {
    final qty = _modeDefaultQty;
    final isKg = _weightUnit == 'kg';
    final fullTable = _commonWeights;

    List<double> subset;
    switch (env) {
      case 'commercial_gym':
        subset = fullTable;
        break;
      case 'home_gym':
      case 'apartment_gym':
        subset = _starterSubset(isKg);
        break;
      case 'office_gym':
        // Office gyms typically only have light dumbbells.
        subset = _slug == 'dumbbells'
            ? (isKg
                ? const [2.5, 5, 7.5, 10, 12.5, 15]
                : const [5, 10, 15, 20, 25, 30])
            : const [];
        break;
      default:
        // home / outdoors / hotel / custom → empty.
        subset = const [];
    }
    return {for (final w in subset) w: qty};
  }

  List<double> _starterSubset(bool isKg) {
    switch (_slug) {
      case 'dumbbells':
      case 'dumbbell':
        return isKg
            ? const [2.5, 5, 7.5, 10, 12.5, 15, 17.5, 20, 22.5, 25]
            : const [5, 10, 15, 20, 25, 30, 35, 40, 45, 50];
      case 'kettlebells':
      case 'kettlebell':
        return isKg ? const [12, 16, 20] : const [25, 35, 45];
      case 'weight_plates':
      case 'bumper_plates':
        return isKg
            ? const [1.25, 2.5, 5, 10, 20]
            : const [2.5, 5, 10, 25, 45];
      case 'barbell':
        return isKg ? const [20] : const [45];
      case 'medicine_ball':
        return isKg ? const [5] : const [10];
      default:
        return const [];
    }
  }

  @override
  void dispose() {
    _customWeightController.dispose();
    super.dispose();
  }

  /// Expand the stack config into discrete weight steps, then store each
  /// with quantity 1 so downstream weight-pickers see the full availability.
  ///
  /// Bounds tightened to prevent pathological inputs: step ≥ 0.5 and
  /// max ≤ 1000 caps total generated entries at 2000.
  void _applyStackConfig() {
    if (_stackIncrement < 0.5) return;
    if (_stackMax < _stackMin) return;
    final cappedMax = _stackMax > 1000 ? 1000.0 : _stackMax;
    final next = <double, int>{};
    int count = 0;
    for (double w = _stackMin; w <= cappedMax + 0.0001; w += _stackIncrement) {
      if (++count > 2000) break; // hard safety cap
      // Round to one decimal to avoid float drift like 25.000000001.
      final rounded = (w * 10).roundToDouble() / 10;
      next[rounded] = 1;
    }
    setState(() => _weightInventory = next);
  }

  /// Mode-aware tap handler.
  ///
  /// - pairs: toggle 0 ↔ 2 (a pair).
  /// - singles: toggle 0 ↔ 1.
  /// - count (plates): cycle 0 → 2 → 4 → 6 → 0 (per side).
  /// - stack: no-op (handled by separate UI).
  void _cycleQuantity(double weight) {
    setState(() {
      final currentQty = _weightInventory[weight] ?? 0;
      switch (_mode) {
        case _InventoryMode.pairs:
          if (currentQty == 0) {
            _weightInventory[weight] = 2;
          } else {
            _weightInventory.remove(weight);
          }
          break;
        case _InventoryMode.singles:
          if (currentQty == 0) {
            _weightInventory[weight] = 1;
          } else {
            _weightInventory.remove(weight);
          }
          break;
        case _InventoryMode.count:
          // 0 → 2 → 4 → 6 → 0 per-side cycle. Long-press hits the keypad
          // for finer control up to the cap (16 per side).
          if (currentQty == 0) {
            _weightInventory[weight] = 2;
          } else if (currentQty < 6) {
            _weightInventory[weight] = currentQty + 2;
          } else {
            _weightInventory.remove(weight);
          }
          break;
        case _InventoryMode.stack:
          break;
      }
    });
  }

  /// Show dialog to directly set quantity
  Future<void> _setQuantity(double weight) async {
    final currentQty = _weightInventory[weight] ?? 0;
    final controller = TextEditingController(text: currentQty > 0 ? currentQty.toString() : '');

    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;

        return AlertDialog(
          backgroundColor: isDark ? AppColors.elevated : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Set Quantity',
            style: TextStyle(color: textPrimary),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_formatWeight(weight)} $_weightUnit',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: textPrimary),
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  labelStyle: TextStyle(color: textPrimary.withValues(alpha: 0.7)),
                  hintText: 'Enter 0 to remove',
                  hintStyle: TextStyle(color: textPrimary.withValues(alpha: 0.5)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: textPrimary.withValues(alpha: 0.7)),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(controller.text) ?? 0;
                Navigator.pop(context, qty);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? AppColors.cyan : AppColorsLight.cyan,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              child: const Text('Set'),
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        if (result == 0) {
          _weightInventory.remove(weight);
        } else {
          _weightInventory[weight] = result;
        }
      });
    }
  }

  void _addCustomWeight() {
    final value = double.tryParse(_customWeightController.text.trim());
    if (value == null || value <= 0) return;
    setState(() {
      // Custom weight defaults to the mode's canonical qty. Adding an
      // already-present weight bumps via the cycle (so plates can stack
      // up across multiple +Add presses).
      final existing = _weightInventory[value] ?? 0;
      _weightInventory[value] = existing == 0 ? _modeDefaultQty : existing + 2;
    });
    _customWeightController.clear();
  }

  void _removeWeight(double weight) {
    setState(() {
      _weightInventory.remove(weight);
    });
  }

  /// Apply a preset by merging it into the current inventory. Existing
  /// custom weights are preserved unless [_Preset.clearAll] is used.
  void _applyPreset(_Preset preset) {
    final isKg = _weightUnit == 'kg';
    Map<double, int> snapshot = Map.from(_weightInventory);

    List<double> additions;
    switch (preset) {
      case _Preset.commercialFull:
        additions = _commonWeights;
        break;
      case _Preset.homeAdjustable:
        additions = _starterSubset(isKg);
        break;
      case _Preset.competitionKettlebell:
        additions = isKg
            ? const [8, 12, 16, 20, 24, 28, 32]
            : const [18, 26, 35, 44, 53, 62, 70];
        break;
      case _Preset.microloading:
        additions = isKg
            ? const [0.25, 0.5, 0.75, 1, 1.25]
            : const [0.5, 1, 1.5, 2.5];
        break;
      case _Preset.clearAll:
        setState(() => _weightInventory.clear());
        _showClearAllUndo(snapshot);
        return;
    }

    setState(() {
      for (final w in additions) {
        _weightInventory[w] = _weightInventory[w] ?? _modeDefaultQty;
      }
    });
  }

  void _showClearAllUndo(Map<double, int> snapshot) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Cleared all weights'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            setState(() => _weightInventory = snapshot);
          },
        ),
      ),
    );
  }

  /// Convert all stored weights to the new unit, snapping each to the
  /// nearest entry in the new unit's standard table (so a 25 lb dumbbell
  /// becomes 11 kg, not 11.34 kg). Duplicates sum.
  void _onUnitChanged(String newUnit) {
    if (newUnit == _weightUnit) return;
    final newTable = newUnit == 'kg' ? _equipmentWeightKg : _equipmentWeightLbs;
    final ref = newTable[_slug] ?? const <double>[];

    final converted = <double, int>{};
    for (final entry in _weightInventory.entries) {
      final rawNew = newUnit == 'kg'
          ? WeightUtils.lbsToKg(entry.key)
          : WeightUtils.kgToLbs(entry.key);
      final snapped = _snapToTable(rawNew, ref);
      converted[snapped] = (converted[snapped] ?? 0) + entry.value;
    }
    setState(() {
      _weightUnit = newUnit;
      _weightInventory = converted;
    });
  }

  double _snapToTable(double w, List<double> table) {
    if (table.isEmpty) {
      // No standard table → keep raw value rounded to 0.5.
      return (w * 2).round() / 2;
    }
    double best = table.first;
    double bestDelta = (w - best).abs();
    for (final t in table) {
      final d = (w - t).abs();
      if (d < bestDelta) {
        best = t;
        bestDelta = d;
      }
    }
    return best;
  }

  void _clearAll() {
    setState(() {
      _weightInventory.clear();
    });
  }

  String _formatWeight(double w) {
    return w == w.roundToDouble() ? w.toInt().toString() : w.toString();
  }

  int get _totalWeights => _weightInventory.values.fold(0, (sum, qty) => sum + qty);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.surface;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Edit Weights',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.equipment.displayName,
                        style: TextStyle(
                          fontSize: 14,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                // Unit toggle
                Container(
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildUnitButton('lbs', isDark),
                      _buildUnitButton('kg', isDark),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quantity / stack instructions — branches on equipment kind.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: accentColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _bannerCopyForMode(),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Selected weights display
          if (_weightInventory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Selected: $_totalWeights items',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _clearAll,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'Clear All',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[400],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _weightInventory.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final weight = _weightInventory.keys.toList()..sort();
                  final w = weight[index];
                  final qty = _weightInventory[w]!;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: accentColor,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$qty',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.black : Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${_formatWeight(w)} $_weightUnit',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        GestureDetector(
                          onTap: () => _removeWeight(w),
                          child: Icon(
                            Icons.close,
                            size: 16,
                            color: accentColor,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],

          const Divider(height: 1),

          if (_isStackMachine) ...[
            _buildStackMachineConfig(
              isDark: isDark,
              accentColor: accentColor,
              textPrimary: textPrimary,
              textMuted: textMuted,
              bgColor: bgColor,
            ),
          ] else ...[
          // Quick add section header — replaces the "Select All Pairs"
          // TextButton with a Preset dropdown that's mode-aware (no
          // "pairs" semantics for kettlebells / barbells / plates).
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  _quickAddHintForMode(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const Spacer(),
                PopupMenuButton<_Preset>(
                  tooltip: 'Apply a preset',
                  onSelected: _applyPreset,
                  itemBuilder: (context) => _presetMenuItems(),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Preset',
                        style: TextStyle(fontSize: 12, color: accentColor),
                      ),
                      Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Common weights — rack-style row.
          //
          // Replaces the previous flat number grid (which the user called
          // "uncreative") with a physical-rack metaphor borrowed from Strong
          // / Hevy / Fitbod equipment screens: each tile is a stylized
          // dumbbell whose plate size scales with the weight, so a 5 lb pair
          // looks visibly smaller than a 100 lb pair. Quantity badge sits on
          // the plate; tap cycles 0→1→2→3→4→0; long-press opens the keypad
          // (existing behavior preserved).
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 10,
                runSpacing: 12,
                children: _commonWeights.map((weight) {
                  final qty = _weightInventory[weight] ?? 0;
                  final isSelected = qty > 0;
                  return _DumbbellRackTile(
                    weight: weight,
                    quantity: qty,
                    isSelected: isSelected,
                    weightUnit: _weightUnit,
                    minWeight: _commonWeights.first,
                    maxWeight: _commonWeights.last,
                    accentColor: accentColor,
                    isDark: isDark,
                    bgColor: bgColor,
                    textSecondary: textSecondary,
                    equipmentName: widget.equipment.name,
                    mode: _mode,
                    onTap: () => _cycleQuantity(weight),
                    onLongPress: _mode == _InventoryMode.singles
                        ? null
                        : () => _setQuantity(weight),
                    formatWeight: _formatWeight,
                  );
                }).toList(),
              ),
            ),
          ),

          // Custom weight input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customWeightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    style: TextStyle(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Custom weight...',
                      hintStyle: TextStyle(color: textMuted, fontSize: 14),
                      filled: true,
                      fillColor: bgColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      suffixText: _weightUnit,
                    ),
                    onSubmitted: (_) => _addCustomWeight(),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: _addCustomWeight,
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          ], // end of !_isStackMachine branch

          // Save button
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).padding.bottom + 16,
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _weightInventory.isEmpty
                          ? 'Skip — no weight constraints'
                          : 'Save ${_saveLabelSuffix()}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_weightInventory.isEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Any weight allowed in workouts',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          color: (isDark ? Colors.black : Colors.white)
                              .withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────── mode-aware copy + preset menu helpers ───────────

  String _bannerCopyForMode() {
    switch (_mode) {
      case _InventoryMode.stack:
        return 'Set this machine\'s weight stack: min, max, and increment between plates.';
      case _InventoryMode.pairs:
        return 'Tap a weight to add a pair; tap again to remove. Long-press to set extras.';
      case _InventoryMode.singles:
        return 'Tap a weight to add or remove it from your set.';
      case _InventoryMode.count:
        return 'Tap to cycle how many you own per side (0→2→4→6). Long-press for custom count.';
    }
  }

  String _quickAddHintForMode() {
    switch (_mode) {
      case _InventoryMode.pairs:
        return 'Tap to add a pair • Long-press for extras';
      case _InventoryMode.singles:
        return 'Tap to add • Tap again to remove';
      case _InventoryMode.count:
        return 'Tap to cycle • Long-press to set';
      case _InventoryMode.stack:
        return '';
    }
  }

  String _saveLabelSuffix() {
    switch (_mode) {
      case _InventoryMode.pairs:
        final pairs = _weightInventory.values.fold(0, (s, q) => s + (q ~/ 2));
        return '$pairs pair${pairs == 1 ? '' : 's'}';
      case _InventoryMode.singles:
        return '${_weightInventory.length} weight${_weightInventory.length == 1 ? '' : 's'}';
      case _InventoryMode.count:
        return '${_weightInventory.length} plate size${_weightInventory.length == 1 ? '' : 's'}';
      case _InventoryMode.stack:
        return '${_weightInventory.length} stack steps';
    }
  }

  List<PopupMenuEntry<_Preset>> _presetMenuItems() {
    final items = <PopupMenuEntry<_Preset>>[
      const PopupMenuItem(
        value: _Preset.commercialFull,
        child: Text('Commercial-gym standard set'),
      ),
      const PopupMenuItem(
        value: _Preset.homeAdjustable,
        child: Text('Home adjustable set'),
      ),
    ];
    // Mode-specific extras.
    if (_slug == 'kettlebells' || _slug == 'kettlebell') {
      items.add(const PopupMenuItem(
        value: _Preset.competitionKettlebell,
        child: Text('Competition set (8–32 kg)'),
      ));
    }
    if (_mode == _InventoryMode.count) {
      items.add(const PopupMenuItem(
        value: _Preset.microloading,
        child: Text('Microloading add-on'),
      ));
    }
    items.add(const PopupMenuDivider());
    items.add(const PopupMenuItem(
      value: _Preset.clearAll,
      child: Text('Clear all', style: TextStyle(color: Colors.redAccent)),
    ));
    return items;
  }

  Widget _buildStackMachineConfig({
    required bool isDark,
    required Color accentColor,
    required Color textPrimary,
    required Color textMuted,
    required Color bgColor,
  }) {
    final sorted = _weightInventory.keys.toList()..sort();
    final preview = sorted.length <= 6
        ? sorted.map(_formatWeight).join(', ')
        : '${sorted.take(3).map(_formatWeight).join(', ')} … ${sorted.skip(sorted.length - 2).map(_formatWeight).join(', ')}';

    return Flexible(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stack range',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textMuted,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _StackNumberField(
                    label: 'Min',
                    value: _stackMin,
                    unit: _weightUnit,
                    isDark: isDark,
                    accentColor: accentColor,
                    onChanged: (v) {
                      setState(() => _stackMin = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StackNumberField(
                    label: 'Max',
                    value: _stackMax,
                    unit: _weightUnit,
                    isDark: isDark,
                    accentColor: accentColor,
                    onChanged: (v) {
                      setState(() => _stackMax = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _StackNumberField(
                    label: 'Step',
                    value: _stackIncrement,
                    unit: _weightUnit,
                    isDark: isDark,
                    accentColor: accentColor,
                    onChanged: (v) {
                      setState(() => _stackIncrement = v);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _applyStackConfig,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Generate stack weights'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: accentColor,
                  side: BorderSide(color: accentColor.withValues(alpha: 0.6)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Preview · ${sorted.length} weight${sorted.length == 1 ? '' : 's'}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.08),
                ),
              ),
              child: Text(
                sorted.isEmpty
                    ? 'No weights yet — pick min/max/step and tap Generate.'
                    : '$preview  $_weightUnit',
                style: TextStyle(
                  fontSize: 13,
                  color: textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnitButton(String unit, bool isDark) {
    final isSelected = _weightUnit == unit;
    final accentColor = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return GestureDetector(
      onTap: () => _onUnitChanged(unit),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? accentColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          unit,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected
                ? (isDark ? Colors.black : Colors.white)
                : (isDark ? Colors.white70 : AppColorsLight.textSecondary),
          ),
        ),
      ),
    );
  }

  void _save() {
    // If the user typed a custom weight but hasn't tapped the + button,
    // commit it before saving so we don't lose their input on close.
    if (_customWeightController.text.trim().isNotEmpty) {
      _addCustomWeight();
    }
    final updated = widget.equipment.copyWith(
      weightInventory: _weightInventory,
      weightUnit: _weightUnit,
    );
    widget.onSave(updated);
    // Pop only this modal sheet — never the route under it. If for any
    // reason this widget's context is no longer the current modal (eg the
    // sheet was dismissed by drag while save was in-flight) we leave the
    // navigator alone instead of risking a pop of the active workout.
    final route = ModalRoute.of(context);
    if (route != null && route.isCurrent && Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }
}


/// Rack-tile renderer for a single weight option.
///
/// Visual: handle bar with two stacked plates whose width and tint scale with
/// the weight relative to the rack range. Light weights = small thin plates,
/// heavy = wide chunky plates with deeper accent. Owned weights show a
/// floating quantity badge that mirrors a real dumbbell rack count tag.
class _DumbbellRackTile extends StatelessWidget {
  final double weight;
  final int quantity;
  final bool isSelected;
  final String weightUnit;
  final double minWeight;
  final double maxWeight;
  final Color accentColor;
  final bool isDark;
  final Color bgColor;
  final Color textSecondary;
  final String equipmentName;
  final _InventoryMode mode;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String Function(double) formatWeight;

  const _DumbbellRackTile({
    required this.weight,
    required this.quantity,
    required this.isSelected,
    required this.weightUnit,
    required this.minWeight,
    required this.maxWeight,
    required this.accentColor,
    required this.isDark,
    required this.bgColor,
    required this.textSecondary,
    required this.equipmentName,
    required this.mode,
    required this.onTap,
    required this.onLongPress,
    required this.formatWeight,
  });

  /// Per-mode badge: pairs show "×N pairs" only if N > 2 (extras),
  /// count shows "+N" per side, singles shows nothing.
  String? _badgeText() {
    switch (mode) {
      case _InventoryMode.pairs:
        final pairs = quantity ~/ 2;
        return pairs >= 2 ? '×$pairs' : null;
      case _InventoryMode.count:
        return quantity > 0 ? '+$quantity' : null;
      case _InventoryMode.singles:
      case _InventoryMode.stack:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Normalize to 0–1 across the rack range, then map to graphic dimensions.
    final span = (maxWeight - minWeight).abs() < 0.01
        ? 1.0
        : (weight - minWeight) / (maxWeight - minWeight);
    final scale = span.clamp(0.0, 1.0);

    // Opacity ramps with weight so a 100 lb dumbbell looks denser than a 5
    // lb one — visual cue that complements the size scaling.
    final fill = isSelected
        ? accentColor
        : (isDark
            ? Colors.white.withValues(alpha: 0.18 + scale * 0.15)
            : Colors.black.withValues(alpha: 0.12 + scale * 0.10));
    final stroke = isDark
        ? Colors.white.withValues(alpha: 0.55)
        : Colors.black.withValues(alpha: 0.55);

    final (Widget graphic, double tileWidth, double graphicHeight) =
        _graphicFor(equipmentName, scale, fill, stroke);

    final selectedLabel = isSelected ? 'selected' : 'not selected';
    final unitLabel = weightUnit == 'kg' ? 'kilograms' : 'pounds';
    final a11y =
        '${formatWeight(weight)} $unitLabel, $selectedLabel, tap to toggle';

    return Semantics(
      label: a11y,
      button: true,
      selected: isSelected,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        // Add invisible padding so the hit-test area is ≥44×44 even when
        // the rendered tile is small (M3 a11y minimum).
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        width: tileWidth,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.12) : bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? accentColor
                : (isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08)),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: graphicHeight + 4,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  graphic,
                  if (_badgeText() != null)
                    Positioned(
                      top: -6,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: accentColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Text(
                          _badgeText()!,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.black : Colors.white,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              formatWeight(weight),
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? accentColor : textSecondary,
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }

  /// Returns (graphic, tileWidth, graphicHeight) for the given equipment.
  /// `scale` is the 0..1 normalized weight position used to size the visual.
  (Widget, double, double) _graphicFor(
    String name,
    double scale,
    Color fill,
    Color stroke,
  ) {
    final n = name.toLowerCase();
    if (n.contains('kettle')) {
      // Kettlebell: round bell with arched handle. Widened range so a 4 kg
      // bell looks visibly smaller than a 48 kg bell.
      final bell = 18.0 + scale * 28.0; // 18 → 46
      return (
        _KettlebellGlyph(size: bell, fill: fill, stroke: stroke),
        bell + 30,
        bell + 10,
      );
    }
    if (n.contains('medicine')) {
      final d = 20.0 + scale * 26.0; // 20 → 46
      return (
        Container(
          width: d,
          height: d,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: Border.all(color: stroke.withValues(alpha: 0.5)),
          ),
        ),
        d + 30,
        d,
      );
    }
    if (n.contains('plate')) {
      // Olympic / bumper plate: solid disc with center hub. Widened range
      // so 2.5 lb looks like the small plate it is and 45 lb dominates.
      final d = 16.0 + scale * 30.0; // 16 → 46
      return (
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: d,
              height: d,
              decoration: BoxDecoration(
                color: fill,
                shape: BoxShape.circle,
                border: Border.all(color: stroke.withValues(alpha: 0.4)),
              ),
            ),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: stroke,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
        d + 30,
        d,
      );
    }
    if (n.contains('barbell') || n.contains('curl_bar') || n.contains('trap_bar')) {
      // Long bar with small end plates — visibly different from a dumbbell.
      final endPlate = 16.0 + scale * 14.0; // 16 → 30
      const barLength = 56.0;
      return (
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 8, height: endPlate, color: fill),
            Container(width: barLength, height: 4, color: stroke),
            Container(width: 8, height: endPlate, color: fill),
          ],
        ),
        barLength + 16 + 24,
        endPlate,
      );
    }
    if (n.contains('cable')) {
      // Cable machine: stack of plates with a pin hole.
      final plateW = 26.0 + scale * 10.0;
      const plateH = 5.0;
      const plateCount = 5;
      const totalH = plateH * plateCount + (plateCount - 1) * 2;
      return (
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(plateCount, (i) {
            return Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 2),
              child: Container(
                width: plateW,
                height: plateH,
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }),
        ),
        plateW + 24,
        totalH,
      );
    }
    // Default: dumbbell silhouette (two plates + handle bar).
    // Widened plate scaling so 5 lb looks visibly tiny vs 100 lb. The old
    // range (14-32) made all tiles look nearly identical.
    final plateWidth = 12.0 + scale * 32.0;   // 12 → 44
    final plateHeight = 20.0 + scale * 22.0;  // 20 → 42
    return (
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: plateWidth,
            height: plateHeight,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          Container(width: 14, height: 4, color: stroke),
          Container(
            width: plateWidth,
            height: plateHeight,
            decoration: BoxDecoration(
              color: fill,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ),
      plateWidth * 2 + 36,
      plateHeight,
    );
  }
}

/// Kettlebell glyph — drawn with CustomPainter so the handle arc looks like
/// an actual kettlebell instead of a styled dumbbell.
class _KettlebellGlyph extends StatelessWidget {
  final double size;
  final Color fill;
  final Color stroke;

  const _KettlebellGlyph({
    required this.size,
    required this.fill,
    required this.stroke,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _KettlebellPainter(fill: fill, stroke: stroke),
    );
  }
}

class _KettlebellPainter extends CustomPainter {
  final Color fill;
  final Color stroke;
  _KettlebellPainter({required this.fill, required this.stroke});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final bodyPaint = Paint()..color = fill;
    final handlePaint = Paint()
      ..color = stroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    // Body: rounded circle sitting in the bottom 70%.
    final bodyRect = Rect.fromCircle(
      center: Offset(w / 2, h * 0.62),
      radius: w * 0.36,
    );
    canvas.drawOval(bodyRect, bodyPaint);
    // Handle: arched top.
    final handleRect = Rect.fromLTWH(w * 0.30, h * 0.05, w * 0.40, h * 0.36);
    canvas.drawArc(handleRect, 3.14, 3.14, false, handlePaint);
    // Handle bridge to body.
    canvas.drawLine(
      Offset(w * 0.30, h * 0.30),
      Offset(w * 0.34, h * 0.42),
      handlePaint,
    );
    canvas.drawLine(
      Offset(w * 0.70, h * 0.30),
      Offset(w * 0.66, h * 0.42),
      handlePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _KettlebellPainter old) =>
      old.fill != fill || old.stroke != stroke;
}

/// Small labeled numeric field used by the stack-machine config.
class _StackNumberField extends StatefulWidget {
  final String label;
  final double value;
  final String unit;
  final bool isDark;
  final Color accentColor;
  final ValueChanged<double> onChanged;

  const _StackNumberField({
    required this.label,
    required this.value,
    required this.unit,
    required this.isDark,
    required this.accentColor,
    required this.onChanged,
  });

  @override
  State<_StackNumberField> createState() => _StackNumberFieldState();
}

class _StackNumberFieldState extends State<_StackNumberField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _format(widget.value));
  }

  @override
  void didUpdateWidget(_StackNumberField old) {
    super.didUpdateWidget(old);
    if ((old.value - widget.value).abs() > 0.0001 &&
        double.tryParse(_controller.text) != widget.value) {
      _controller.text = _format(widget.value);
    }
  }

  String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final bgColor = isDark ? AppColors.elevated : AppColorsLight.surface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: textMuted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: _controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
          ],
          style: TextStyle(
            color: textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: bgColor,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            suffixText: widget.unit,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: widget.accentColor, width: 1.4),
            ),
          ),
          onChanged: (s) {
            final parsed = double.tryParse(s);
            if (parsed != null && parsed >= 0) {
              widget.onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}
