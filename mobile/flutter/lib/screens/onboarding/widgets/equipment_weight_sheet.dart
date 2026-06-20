import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/line_icon.dart';
import '../../../models/equipment_item.dart';
import '../../../widgets/glass_sheet.dart';

/// Fitbod-style "what weights do you own" editor for ONE equipment id
/// (dumbbells / kettlebell / barbell). Min / Max / Increment via sliders +
/// tap-to-type custom input (no chip buttons — per the increment-UI rule),
/// with a live preview of the resulting weight set.
///
/// Returns a spec `{min, max, increment, unit}` on Save, or null on cancel.
Future<Map<String, dynamic>?> showEquipmentWeightSheet(
  BuildContext context, {
  required String equipmentId,
  required String label,
  required String lineIcon,
  Map<String, dynamic>? initial,
  bool defaultMetric = false,
}) {
  return showGlassSheet<Map<String, dynamic>>(
    context: context,
    initialChildSize: 0.72,
    minChildSize: 0.5,
    maxChildSize: 0.94,
    builder: (ctx) => GlassSheet(
      showHandle: true,
      child: _EquipmentWeightSheet(
        equipmentId: equipmentId,
        label: label,
        lineIcon: lineIcon,
        initial: initial,
        defaultMetric: defaultMetric,
      ),
    ),
  );
}

// [min, max, increment] sensible starting points per equipment + unit.
const Map<String, List<double>> _lbDefaults = {
  'dumbbells': [5, 50, 5],
  'kettlebell': [10, 50, 5],
  'barbell': [45, 225, 10],
};
const Map<String, List<double>> _kgDefaults = {
  'dumbbells': [2.5, 24, 2.5],
  'kettlebell': [4, 24, 4],
  'barbell': [20, 100, 5],
};

class _EquipmentWeightSheet extends StatefulWidget {
  final String equipmentId;
  final String label;
  final String lineIcon;
  final Map<String, dynamic>? initial;
  final bool defaultMetric;

  const _EquipmentWeightSheet({
    required this.equipmentId,
    required this.label,
    required this.lineIcon,
    required this.initial,
    required this.defaultMetric,
  });

  @override
  State<_EquipmentWeightSheet> createState() => _EquipmentWeightSheetState();
}

class _EquipmentWeightSheetState extends State<_EquipmentWeightSheet> {
  late bool _metric;
  late double _min;
  late double _max;
  late double _inc;

  @override
  void initState() {
    super.initState();
    _metric = (widget.initial?['unit'] == 'kg') ||
        (widget.initial == null && widget.defaultMetric);
    _applyDefaults(fromInitial: true);
  }

  void _applyDefaults({bool fromInitial = false}) {
    final defs = (_metric ? _kgDefaults : _lbDefaults)[widget.equipmentId] ??
        const [5.0, 50.0, 5.0];
    if (fromInitial && widget.initial != null) {
      _min = (widget.initial!['min'] as num?)?.toDouble() ?? defs[0];
      _max = (widget.initial!['max'] as num?)?.toDouble() ?? defs[1];
      _inc = (widget.initial!['increment'] as num?)?.toDouble() ?? defs[2];
    } else {
      _min = defs[0];
      _max = defs[1];
      _inc = defs[2];
    }
  }

  double get _weightBound => _metric ? 140 : 300;
  double get _incMin => _metric ? 0.5 : 1;
  double get _incMax => _metric ? 10 : 25;
  String get _unit => _metric ? 'kg' : 'lb';

  void _toggleUnit(bool metric) {
    if (metric == _metric) return;
    // Convert the current values so the user doesn't lose their setup.
    final f = metric ? 0.45359237 : 2.20462262;
    setState(() {
      _metric = metric;
      double rnd(double v) {
        final step = metric ? 0.5 : 1.0;
        return (v * f / step).round() * step;
      }
      _min = rnd(_min).clamp(0, _weightBound);
      _max = rnd(_max).clamp(0, _weightBound);
      _inc = rnd(_inc).clamp(_incMin, _incMax);
      if (_inc < _incMin) _inc = _incMin;
    });
  }

  List<double> get _preview =>
      EquipmentItem.expandRange(_min, _max, _inc);

  String _fmt(double v) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1);
    return '$s $_unit';
  }

  void _save() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).pop(<String, dynamic>{
      'min': _min,
      'max': _max,
      'increment': _inc,
      'unit': _unit,
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final preview = _preview;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header.
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: LineIcon(widget.lineIcon,
                      size: 22, color: AppColors.orange),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Available ${widget.label.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    Text(
                      'Which weights do you have?',
                      style: TextStyle(fontSize: 13, color: textSecondary),
                    ),
                  ],
                ),
              ),
              _unitToggle(isDark, textPrimary, textSecondary),
            ],
          ),
          const SizedBox(height: 20),
          _control('Lightest', _min, 0, _max, textPrimary, textSecondary,
              (v) => setState(() => _min = v.clamp(0, _max))),
          const SizedBox(height: 16),
          _control('Heaviest', _max, _min, _weightBound, textPrimary,
              textSecondary, (v) => setState(() => _max = v.clamp(_min, _weightBound))),
          const SizedBox(height: 16),
          _control('Jump between weights', _inc, _incMin, _incMax, textPrimary,
              textSecondary, (v) => setState(() => _inc = v),
              isIncrement: true),
          const SizedBox(height: 20),
          // Live preview.
          Text(
            '${preview.length} weights',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 96),
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final w in preview)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppColors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        _fmt(w),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.orange,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Save.
          GestureDetector(
            onTap: _save,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.orange, Color(0xFFEA580C)],
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Center(
                child: Text(
                  'Save',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _unitToggle(bool isDark, Color textPrimary, Color textSecondary) {
    Widget seg(String u, bool metric) {
      final active = _metric == metric;
      return GestureDetector(
        onTap: () => _toggleUnit(metric),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? AppColors.orange.withValues(alpha: 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            u,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? AppColors.orange : textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('lb', false),
        seg('kg', true),
      ]),
    );
  }

  Widget _control(
    String label,
    double value,
    double min,
    double max,
    Color textPrimary,
    Color textSecondary,
    ValueChanged<double> onChanged, {
    bool isIncrement = false,
  }) {
    final divisions = isIncrement
        ? ((max - min) / (_metric ? 0.5 : 1)).round().clamp(1, 100)
        : (max - min).round().clamp(1, 600);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary)),
            // Value pill — tap to type a custom value.
            GestureDetector(
              onTap: () => _editValue(label, value, min, max, onChanged),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_fmt(value),
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: AppColors.orange)),
                    const SizedBox(width: 5),
                    const Icon(Icons.edit_rounded,
                        size: 13, color: AppColors.orange),
                  ],
                ),
              ),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.orange,
            inactiveTrackColor: AppColors.orange.withValues(alpha: 0.18),
            thumbColor: AppColors.orange,
            overlayColor: AppColors.orange.withValues(alpha: 0.16),
            trackHeight: 4,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max <= min ? min + 1 : max,
            divisions: divisions,
            onChanged: (v) {
              HapticFeedback.selectionClick();
              onChanged(v);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _editValue(String label, double current, double min, double max,
      ValueChanged<double> onChanged) async {
    final ctrl = TextEditingController(text: _fmt(current).split(' ').first);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final v = await showDialog<double>(
      context: context,
      builder: (dctx) => AlertDialog(
        backgroundColor: isDark ? AppColors.surface : Colors.white,
        title: Text('$label ($_unit)'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: const InputDecoration(hintText: 'Enter a number'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () =>
                Navigator.pop(dctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Set'),
          ),
        ],
      ),
    );
    if (v != null && v.isFinite) {
      onChanged(v.clamp(min, max));
    }
  }
}
