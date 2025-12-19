import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/repositories/onboarding_repository.dart';

/// Quick reply buttons for conversational onboarding
/// Supports single-select and multi-select modes
class QuickReplyButtons extends StatefulWidget {
  final List<QuickReply> replies;
  final ValueChanged<dynamic> onSelect;
  final bool multiSelect;
  final VoidCallback? onOtherSelected;

  const QuickReplyButtons({
    super.key,
    required this.replies,
    required this.onSelect,
    this.multiSelect = false,
    this.onOtherSelected,
  });

  @override
  State<QuickReplyButtons> createState() => _QuickReplyButtonsState();
}

class _QuickReplyButtonsState extends State<QuickReplyButtons> {
  final Set<dynamic> _selected = {};

  // Quantity tracking for equipment that supports counts
  int _dumbbellCount = 2;
  int _kettlebellCount = 1;

  void _handleTap(QuickReply reply) {
    HapticFeedback.lightImpact();

    // Handle "Other" option
    if (reply.value == '__other__') {
      widget.onOtherSelected?.call();
      return;
    }

    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(reply.value)) {
          _selected.remove(reply.value);
        } else {
          _selected.add(reply.value);
        }
      });
    } else {
      // Single-select: immediately trigger send with both label and value
      // The label is shown in chat, the value is sent to backend
      widget.onSelect({
        'label': reply.label,
        'value': reply.value,
        'isSingleSelect': true,
      });
    }
  }

  void _handleConfirm() {
    if (_selected.isNotEmpty) {
      // Build result with quantities for equipment
      final result = <String, dynamic>{
        'selected': _selected.toList(),
      };

      // Include quantities if relevant equipment is selected
      if (_selected.contains('Dumbbells')) {
        result['dumbbell_count'] = _dumbbellCount;
      }
      if (_selected.contains('Kettlebell')) {
        result['kettlebell_count'] = _kettlebellCount;
      }

      widget.onSelect(result);
    }
  }

  bool _isEquipmentWithQuantity(String? value) {
    return value == 'Dumbbells' || value == 'Kettlebell';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 52, top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...widget.replies.map((reply) {
            final isSelected = _selected.contains(reply.value);
            final showQuantity = widget.multiSelect &&
                isSelected &&
                _isEquipmentWithQuantity(reply.value?.toString());

            return GestureDetector(
              onTap: () => _handleTap(reply),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: showQuantity ? 8 : 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.cyan.withOpacity(0.3)
                      : colors.glassSurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? colors.cyan : colors.cyan.withOpacity(0.5),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.cyan.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (reply.icon != null) ...[
                      Text(
                        reply.icon!,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      reply.label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? colors.cyan : colors.textSecondary,
                      ),
                    ),
                    // Quantity selector for Dumbbells/Kettlebell
                    if (showQuantity) ...[
                      const SizedBox(width: 8),
                      _QuantitySelector(
                        value: reply.value == 'Dumbbells' ? _dumbbellCount : _kettlebellCount,
                        onChanged: (newValue) {
                          HapticFeedback.selectionClick();
                          setState(() {
                            if (reply.value == 'Dumbbells') {
                              _dumbbellCount = newValue;
                            } else {
                              _kettlebellCount = newValue;
                            }
                          });
                        },
                        colors: colors,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),

          // Multi-select confirm button
          if (widget.multiSelect && _selected.isNotEmpty)
            GestureDetector(
              onTap: _handleConfirm,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: colors.cyanGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cyan.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Text(
                  'Continue (${_selected.length} selected)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Compact quantity selector with +/- buttons
class _QuantitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final ThemeColors colors;

  const _QuantitySelector({
    required this.value,
    required this.onChanged,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: colors.background.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Minus button
          GestureDetector(
            onTap: value > 1 ? () => onChanged(value - 1) : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value > 1 ? colors.cyan.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.remove,
                size: 14,
                color: value > 1 ? colors.cyan : colors.textMuted,
              ),
            ),
          ),
          // Value
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colors.cyan,
              ),
            ),
          ),
          // Plus button
          GestureDetector(
            onTap: value < 2 ? () => onChanged(value + 1) : null,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: value < 2 ? colors.cyan.withOpacity(0.3) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: value < 2 ? colors.cyan : colors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
