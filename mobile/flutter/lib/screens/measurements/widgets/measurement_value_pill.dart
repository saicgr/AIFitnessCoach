import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/measurements_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../measurement_unit_conversion.dart';

/// A compact pill that both shows a measurement value and becomes its own
/// inline editor on tap. Writes to the DB immediately on ✓ — no intermediate
/// bottom sheet. Long-press navigates to the full detail screen.
///
/// Designed for the Body view (value pills overlaid on the anatomical
/// figure) but equally usable wherever "show + tap-to-edit" is wanted.
class MeasurementValuePill extends ConsumerStatefulWidget {
  /// Which metric this pill is bound to.
  final MeasurementType type;

  /// Latest recorded entry (null when the user has never logged this metric).
  final MeasurementEntry? latest;

  /// Delta between the latest entry and the previous one, in metric units
  /// (kg or cm; `null` for body-fat). Drives the trend-arrow color + direction.
  /// When null or below the "noise" threshold we hide the arrow entirely.
  final double? change;

  /// Whether the user is in metric mode. Drives both the unit toggle default
  /// and the display formatting.
  final bool isMetric;

  /// Optional short name to display instead of [type.displayName] — useful
  /// when the pill sits in a cramped anatomical region and full display
  /// names (e.g. "Biceps (L)") don't fit.
  final String? shortName;

  /// Optional icon override (defaults to [Icons.straighten]).
  final IconData? icon;

  /// When `true` the pill renders in "anatomical" mode: no label text, just
  /// `[icon] value [trend] [›]`. Used when the pill is overlaid on its body
  /// part in [MeasurementBodyView] — position on the silhouette already
  /// communicates which metric it is. Defaults to `false` (full label).
  final bool compact;

  const MeasurementValuePill({
    super.key,
    required this.type,
    required this.latest,
    required this.isMetric,
    this.change,
    this.shortName,
    this.icon,
    this.compact = false,
  });

  @override
  ConsumerState<MeasurementValuePill> createState() => _MeasurementValuePillState();
}

class _MeasurementValuePillState extends ConsumerState<MeasurementValuePill> {
  bool _editing = false;
  bool _saving = false;
  late bool _editIsMetric;
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _editIsMetric = widget.isMetric;
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEditing() {
    HapticService.light();
    // Seed the field with the latest value in the user's selected unit so
    // they only type if they want to change it.
    if (widget.latest != null) {
      final displayed = widget.latest!.getValueInUnit(widget.isMetric);
      _controller.text = _stripTrailingZero(displayed.toStringAsFixed(1));
    } else {
      _controller.text = '';
    }
    _editIsMetric = widget.isMetric;
    setState(() => _editing = true);
    // Select all so the numeric keyboard replaces the value cleanly.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  void _cancel() {
    if (_saving) return;
    setState(() => _editing = false);
    _controller.clear();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _save() async {
    if (_saving) return;
    final raw = _controller.text.trim();
    final parsed = double.tryParse(raw);
    if (parsed == null || parsed <= 0) {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter a valid ${_unitLabel()} value'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final auth = ref.read(authStateProvider);
    final user = auth.user;
    if (user == null) return;

    setState(() => _saving = true);
    final converted = convertToMetric(parsed, widget.type, !_editIsMetric);
    final success = await ref.read(measurementsProvider.notifier).recordMeasurement(
          userId: user.id,
          type: widget.type,
          value: converted.value,
          unit: converted.unit,
        );

    if (!mounted) return;
    setState(() {
      _saving = false;
      if (success) _editing = false;
    });

    if (success) {
      HapticService.success();
    } else {
      HapticService.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save — try again'),
          backgroundColor: AppColors.error,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  String _unitLabel() {
    if (widget.type == MeasurementType.bodyFat) return '%';
    if (widget.type == MeasurementType.weight) {
      return _editIsMetric ? 'kg' : 'lb';
    }
    return _editIsMetric ? 'cm' : 'in';
  }

  bool get _supportsUnitToggle => widget.type != MeasurementType.bodyFat;

  String _stripTrailingZero(String s) {
    // "96.0" → "96"; "96.5" → "96.5".
    if (s.contains('.') && s.endsWith('0')) {
      final t = s.substring(0, s.length - 1);
      return t.endsWith('.') ? t.substring(0, t.length - 1) : t;
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final colors = ref.colors(context);
    final accent = colors.accent;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final hasData = widget.latest != null;
    final borderColor = hasData ? accent.withValues(alpha: 0.5) : cardBorder;

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      alignment: Alignment.centerLeft,
      curve: Curves.easeOut,
      child: _editing
          ? _buildEditor(accent, elevated, textPrimary)
          : _buildDisplay(accent, elevated, textMuted, borderColor, hasData),
    );
  }

  /// Determines whether a positive change is "good" for this metric. Weight
  /// and body-fat losses are the goal; muscle / torso circumferences are
  /// aimed at increase (unless the user is cutting waist/hips, handled as
  /// neutral — we still go with increase = good for lack of better signal).
  bool get _positiveIsGood {
    switch (widget.type) {
      case MeasurementType.weight:
      case MeasurementType.bodyFat:
      case MeasurementType.waist:
      case MeasurementType.hips:
        return false; // decrease trends toward goals for most users
      default:
        return true; // growth = progress
    }
  }

  Widget _buildDisplay(Color accent, Color elevated, Color textMuted,
      Color borderColor, bool hasData) {
    final label = widget.shortName ?? widget.type.displayName;
    final showLabel = !widget.compact;

    // Trend arrow: rendered only when we have a change AND it's above the
    // noise floor. Color follows the user's goal alignment for this metric.
    Widget? trendArrow;
    final change = widget.change;
    if (hasData && change != null && change.abs() >= 0.1) {
      final isUp = change > 0;
      final aligned = isUp == _positiveIsGood;
      final color = aligned ? AppColors.success : AppColors.error;
      trendArrow = Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Icon(
          isUp ? Icons.north_rounded : Icons.south_rounded,
          size: 10,
          color: color,
        ),
      );
    }

    // Compact value string — drop the unit in the pill itself (the global
    // Metric/Imperial toggle in the header already tells the user which unit
    // scale is active). Saves ~18 px of horizontal space so pills fit the
    // flanking columns around the body figure.
    final compactValue = hasData
        ? _stripTrailingZero(widget.latest!.getValueInUnit(widget.isMetric).toStringAsFixed(1))
        : '—';

    // Split taps: the value area opens the inline editor; the chevron
    // navigates to the full detail screen (chart + history). This matches
    // the user's mental model — "tap the number to change it, tap the
    // chevron to dig deeper".
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 2, 2, 2),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Left part — icon + label + value + trend — taps open editor.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _startEditing,
            onLongPress: () {
              HapticService.light();
              context.push('/measurements/${widget.type.name}');
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon ?? Icons.straighten,
                  size: 11,
                  color: hasData ? accent : textMuted,
                ),
                if (showLabel) ...[
                  const SizedBox(width: 3),
                  // FittedBox.scaleDown keeps label on one line at base
                  // font size on normal phones, shrinks on narrower ones.
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      softWrap: false,
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: textMuted,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    compactValue,
                    maxLines: 1,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: hasData ? accent : textMuted,
                    ),
                  ),
                ),
                if (trendArrow != null) trendArrow,
                const SizedBox(width: 3),
              ],
            ),
          ),

          // Chevron circle — own tap zone, navigates to the detail screen.
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticService.light();
              context.push('/measurements/${widget.type.name}');
            },
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (hasData ? accent : textMuted).withValues(alpha: 0.15),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 11,
                color: hasData ? accent : textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditor(Color accent, Color elevated, Color textPrimary) {
    // NOTE: editor is rendered inside ~150 dp grid cells; keep the layout
    // lean so it never overflows. The surrounding body/tile context already
    // communicates which metric is being edited, so the label is omitted in
    // edit mode to save horizontal space.

    return TapRegion(
      // Tap-outside-to-cancel: covers the "clicked anywhere off the pill".
      onTapOutside: (_) => _cancel(),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 3, 3, 3),
        decoration: BoxDecoration(
          color: elevated,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: accent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon ?? Icons.straighten, size: 12, color: accent),
            const SizedBox(width: 4),
            SizedBox(
              width: 42,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                enabled: !_saving,
                autofocus: true,
                textAlign: TextAlign.center,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 4),
                  border: InputBorder.none,
                  hintText: '0',
                ),
                onSubmitted: (_) => _save(),
              ),
            ),
            const SizedBox(width: 3),
            if (_supportsUnitToggle)
              GestureDetector(
                onTap: _saving
                    ? null
                    : () {
                        // Flip the toggle AND convert the in-field value so the
                        // number keeps its semantic meaning across units.
                        final current = double.tryParse(_controller.text.trim());
                        setState(() {
                          _editIsMetric = !_editIsMetric;
                          if (current != null && current > 0) {
                            double next;
                            if (widget.type == MeasurementType.weight) {
                              next = _editIsMetric
                                  ? current / 2.20462
                                  : current * 2.20462;
                            } else {
                              next = _editIsMetric ? current * 2.54 : current / 2.54;
                            }
                            _controller.text =
                                _stripTrailingZero(next.toStringAsFixed(1));
                          }
                        });
                      },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _unitLabel(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Text(
                  _unitLabel(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
              ),
            const SizedBox(width: 3),
            _IconButton(
              icon: _saving ? Icons.hourglass_empty : Icons.check,
              color: accent,
              onTap: _saving ? null : _save,
            ),
            _IconButton(
              icon: Icons.close,
              color: textPrimary,
              onTap: _saving ? null : _cancel,
            ),
          ],
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _IconButton({required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Icon(icon, size: 16, color: onTap == null ? color.withValues(alpha: 0.4) : color),
      ),
    );
  }
}
