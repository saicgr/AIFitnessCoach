import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';

/// Day picker component for selecting workout days
/// Shows M T W T F S S buttons with multi-select capability
class DayPicker extends StatefulWidget {
  final int daysPerWeek;
  final ValueChanged<List<int>> onSelect;
  final List<int> initialSelected;

  const DayPicker({
    super.key,
    required this.daysPerWeek,
    required this.onSelect,
    this.initialSelected = const [],
  });

  @override
  State<DayPicker> createState() => _DayPickerState();
}

class _DayPickerState extends State<DayPicker> {
  late Set<int> _selectedDays;

  static const _days = [
    (label: 'M', full: 'Monday', value: 0),
    (label: 'T', full: 'Tuesday', value: 1),
    (label: 'W', full: 'Wednesday', value: 2),
    (label: 'T', full: 'Thursday', value: 3),
    (label: 'F', full: 'Friday', value: 4),
    (label: 'S', full: 'Saturday', value: 5),
    (label: 'S', full: 'Sunday', value: 6),
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = Set.from(widget.initialSelected);
  }

  void _toggleDay(int dayValue) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedDays.contains(dayValue)) {
        _selectedDays.remove(dayValue);
      } else if (_selectedDays.length < widget.daysPerWeek) {
        _selectedDays.add(dayValue);
      }
    });
  }

  void _handleConfirm() {
    if (_selectedDays.length == widget.daysPerWeek) {
      HapticFeedback.mediumImpact();
      widget.onSelect(_selectedDays.toList()..sort());
    }
  }

  bool get _canConfirm => _selectedDays.length == widget.daysPerWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // Responsive margin: smaller on narrow screens
    final screenWidth = MediaQuery.of(context).size.width;
    final leftMargin = screenWidth < 380 ? 16.0 : 52.0;

    return Container(
      margin: EdgeInsets.only(left: leftMargin, top: 8, right: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.glassSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select ${widget.daysPerWeek} days (${_selectedDays.length}/${widget.daysPerWeek} selected)',
            style: TextStyle(
              fontSize: 12,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),

          // Day grid - use Wrap for responsive layout on narrow screens
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _days.map((day) {
              final isSelected = _selectedDays.contains(day.value);
              final isDisabled =
                  !isSelected && _selectedDays.length >= widget.daysPerWeek;

              return GestureDetector(
                onTap: isDisabled ? null : () => _toggleDay(day.value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: isSelected ? colors.cyanGradient : null,
                    color: isSelected
                        ? null
                        : isDisabled
                            ? colors.glassSurface.withOpacity(0.3)
                            : colors.glassSurface,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDisabled
                                ? colors.cardBorder.withOpacity(0.3)
                                : colors.cardBorder,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: colors.cyan.withOpacity(0.5),
                              blurRadius: 16,
                              spreadRadius: 0,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      day.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : isDisabled
                                ? colors.textMuted.withOpacity(0.5)
                                : colors.textPrimary,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Confirm button
          GestureDetector(
            onTap: _canConfirm ? _handleConfirm : null,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                gradient: _canConfirm ? colors.cyanGradient : null,
                color: _canConfirm ? null : colors.glassSurface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: _canConfirm
                    ? [
                        BoxShadow(
                          color: colors.cyan.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Center(
                child: Text(
                  _canConfirm
                      ? 'Confirm Days'
                      : 'Select ${widget.daysPerWeek - _selectedDays.length} more day${widget.daysPerWeek - _selectedDays.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _canConfirm ? Colors.white : colors.textMuted,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
