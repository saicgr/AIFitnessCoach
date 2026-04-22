// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Helper bottom sheet used by `focal_stepper.dart` for precise numeric entry
// (tap the number → keyboard). Split out to keep focal_stepper.dart ≤ 250 lines.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/accent_color_provider.dart';

/// Shows a modal keyboard sheet for precise editing of the focal-stepper
/// value. Resolves to the clamped new value, or `null` when the user
/// dismisses the sheet without saving.
Future<double?> showFocalStepperNumericSheet({
  required BuildContext context,
  required double initial,
  required String unit,
  required bool integerOnly,
  required double min,
  required double max,
  required String label,
}) {
  return showModalBottomSheet<double>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _NumericEditSheet(
      initial: initial,
      unit: unit,
      integerOnly: integerOnly,
      min: min,
      max: max,
      label: label,
    ),
  );
}

class _NumericEditSheet extends StatefulWidget {
  final double initial;
  final String unit;
  final bool integerOnly;
  final double min;
  final double max;
  final String label;

  const _NumericEditSheet({
    required this.initial,
    required this.unit,
    required this.integerOnly,
    required this.min,
    required this.max,
    required this.label,
  });

  @override
  State<_NumericEditSheet> createState() => _NumericEditSheetState();
}

class _NumericEditSheetState extends State<_NumericEditSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final initial = widget.integerOnly
        ? widget.initial.round().toString()
        : _trimTrailing(widget.initial.toStringAsFixed(2));
    _controller = TextEditingController(text: initial);
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Trim trailing zeros so "30.00" renders as "30" when the sheet opens.
  String _trimTrailing(String s) {
    if (!s.contains('.')) return s;
    var trimmed = s;
    while (trimmed.endsWith('0')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    if (trimmed.endsWith('.')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  void _submit() {
    final parsed = double.tryParse(_controller.text.trim());
    if (parsed == null) {
      Navigator.of(context).pop();
      return;
    }
    final clamped = parsed.clamp(widget.min, widget.max).toDouble();
    Navigator.of(context).pop(clamped);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final onSurface = isDark ? Colors.white : Colors.black;
    final viewInsets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: onSurface.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              autofocus: true,
              keyboardType: TextInputType.numberWithOptions(
                decimal: !widget.integerOnly,
                signed: false,
              ),
              inputFormatters: widget.integerOnly
                  ? <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly]
                  : <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
              onSubmitted: (_) => _submit(),
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                suffixText: widget.unit,
                border: const OutlineInputBorder(),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: accent,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: _submit,
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
