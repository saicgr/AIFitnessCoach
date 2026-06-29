/// "+ Add column" picker — choose a metric to track for an exercise, or define
/// a custom one. Used in both Advanced and Easy active-workout modes and the
/// custom-exercise builder. Persists per user + per exercise.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_colors.dart';
import '../../../core/utils/exercise_tracking_metric.dart';
import '../../../data/providers/exercise_metrics_provider.dart';
import '../../../data/services/haptic_service.dart';
import '../../../widgets/glass_sheet.dart';

class MetricPickerSheet extends ConsumerStatefulWidget {
  const MetricPickerSheet({
    super.key,
    required this.currentKeys,
    this.title = 'Add a metric to this exercise',
  });

  /// Keys already present on the exercise (hidden from the add list).
  final List<String> currentKeys;
  final String title;

  /// Shows the picker; resolves to the chosen metric KEY (already added to the
  /// user's custom registry if it was custom), or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required List<String> currentKeys,
    String title = 'Add a metric to this exercise',
  }) {
    return showGlassSheet<String>(
      context: context,
      builder: (_) => GlassSheet(
        child: MetricPickerSheet(currentKeys: currentKeys, title: title),
      ),
    );
  }

  @override
  ConsumerState<MetricPickerSheet> createState() => _MetricPickerSheetState();
}

class _MetricPickerSheetState extends ConsumerState<MetricPickerSheet> {
  bool _customMode = false;
  final _labelCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _labelCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  String _slug(String label) => label
      .toLowerCase()
      .trim()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');

  Future<void> _createCustom() async {
    final label = _labelCtrl.text.trim();
    if (label.isEmpty || _saving) return;
    final unit = _unitCtrl.text.trim();
    final key = _slug(label);
    if (key.isEmpty) return;
    setState(() => _saving = true);
    try {
      await ref.read(exerciseMetricsServiceProvider).createCustomMetric(
            key: key,
            label: label,
            unit: unit.isEmpty ? null : unit,
            canonicalUnit: unit.isEmpty ? 'count' : unit,
          );
      if (mounted) Navigator.of(context).pop(key);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    final custom = ref.watch(customMetricDefsProvider).valueOrNull ?? const {};
    // Available = built-ins + customs, minus what's already on the exercise.
    final all = <String, MetricDef>{...kMetricCatalog, ...custom};
    final addable = all.entries
        .where((e) => !widget.currentKeys.contains(e.key))
        .map((e) => e.value)
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary)),
          const SizedBox(height: 8),
          if (!_customMode) ...[
            ...addable.map((def) => _MetricRow(
                  def: def,
                  onTap: () {
                    HapticService.selection();
                    Navigator.of(context).pop(def.key);
                  },
                )),
            const Divider(height: 18),
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => setState(() => _customMode = true),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                child: Row(children: [
                  const Icon(Icons.add, size: 18, color: Color(0xFF7FD6A0)),
                  const SizedBox(width: 10),
                  Text('Define custom metric…',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7FD6A0))),
                ]),
              ),
            ),
          ] else ...[
            const SizedBox(height: 4),
            TextField(
              controller: _labelCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                  labelText: 'Metric name', hintText: 'e.g. Box Height'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _unitCtrl,
              decoration: const InputDecoration(
                  labelText: 'Unit (optional)', hintText: 'e.g. cm'),
            ),
            const SizedBox(height: 16),
            Row(children: [
              TextButton(
                onPressed: () => setState(() => _customMode = false),
                child: const Text('Back'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _saving ? null : _createCustom,
                child: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create & add'),
              ),
            ]),
          ],
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.def, required this.onTap});
  final MetricDef def;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = ThemeColors.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
        child: Row(children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: colors.elevated,
                borderRadius: BorderRadius.circular(7)),
            child: Text(def.shortLabel.characters.first,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: colors.textSecondary)),
          ),
          const SizedBox(width: 12),
          Text(def.label,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary)),
          const Spacer(),
          if (def.canonicalUnit.isNotEmpty && def.canonicalUnit != 'count')
            Text(def.canonicalUnit,
                style: TextStyle(
                    fontSize: 11,
                    color: colors.textMuted,
                    fontFamily: 'monospace')),
        ]),
      ),
    );
  }
}
