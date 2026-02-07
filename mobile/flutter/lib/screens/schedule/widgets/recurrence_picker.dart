import 'package:flutter/material.dart';

/// Picks recurrence rules for schedule items.
/// Generates RRULE strings (e.g. "FREQ=DAILY", "FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR").
class RecurrencePicker extends StatefulWidget {
  final String? initialRule;
  final Function(String?) onChanged;

  const RecurrencePicker({
    super.key,
    this.initialRule,
    required this.onChanged,
  });

  @override
  State<RecurrencePicker> createState() => _RecurrencePickerState();
}

class _RecurrencePickerState extends State<RecurrencePicker> {
  String _selected = 'none'; // 'none', 'daily', 'weekdays', 'custom'
  final Set<int> _customDays = {}; // 0=Mon, 1=Tue, ..., 6=Sun

  static const _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _dayRRuleCodes = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  void initState() {
    super.initState();
    _parseInitialRule();
  }

  void _parseInitialRule() {
    final rule = widget.initialRule;
    if (rule == null || rule.isEmpty) {
      _selected = 'none';
      return;
    }
    if (rule == 'FREQ=DAILY') {
      _selected = 'daily';
    } else if (rule == 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR') {
      _selected = 'weekdays';
    } else if (rule.startsWith('FREQ=WEEKLY;BYDAY=')) {
      _selected = 'custom';
      final byDay = rule.split('BYDAY=').last;
      for (final code in byDay.split(',')) {
        final index = _dayRRuleCodes.indexOf(code.trim());
        if (index >= 0) _customDays.add(index);
      }
    }
  }

  String? _buildRule() {
    switch (_selected) {
      case 'daily':
        return 'FREQ=DAILY';
      case 'weekdays':
        return 'FREQ=WEEKLY;BYDAY=MO,TU,WE,TH,FR';
      case 'custom':
        if (_customDays.isEmpty) return null;
        final sorted = _customDays.toList()..sort();
        final codes = sorted.map((i) => _dayRRuleCodes[i]).join(',');
        return 'FREQ=WEEKLY;BYDAY=$codes';
      default:
        return null;
    }
  }

  void _onSelectionChanged(String value) {
    setState(() {
      _selected = value;
      if (value == 'weekdays') {
        _customDays.clear();
      }
    });
    widget.onChanged(_buildRule());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipBg = isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100;
    final selectedBg = isDark ? Colors.white : Colors.black;
    final selectedFg = isDark ? Colors.black : Colors.white;
    final unselectedFg = isDark ? Colors.white70 : Colors.black87;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 8,
          children: [
            _buildChip('None', 'none', chipBg, selectedBg, selectedFg, unselectedFg),
            _buildChip('Daily', 'daily', chipBg, selectedBg, selectedFg, unselectedFg),
            _buildChip('Weekdays', 'weekdays', chipBg, selectedBg, selectedFg, unselectedFg),
            _buildChip('Custom', 'custom', chipBg, selectedBg, selectedFg, unselectedFg),
          ],
        ),
        if (_selected == 'custom') ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(7, (index) {
              final isActive = _customDays.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isActive) {
                      _customDays.remove(index);
                    } else {
                      _customDays.add(index);
                    }
                  });
                  widget.onChanged(_buildRule());
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isActive ? selectedBg : chipBg,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _dayLabels[index],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isActive ? selectedFg : unselectedFg,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _buildChip(
    String label,
    String value,
    Color chipBg,
    Color selectedBg,
    Color selectedFg,
    Color unselectedFg,
  ) {
    final isActive = _selected == value;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => _onSelectionChanged(value),
      backgroundColor: chipBg,
      selectedColor: selectedBg,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: isActive ? selectedFg : unselectedFg,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }
}
