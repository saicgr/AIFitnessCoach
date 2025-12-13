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
      // Single-select: immediately trigger send
      widget.onSelect(reply.value);
    }
  }

  void _handleConfirm() {
    if (_selected.isNotEmpty) {
      widget.onSelect(_selected.toList());
    }
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
            return GestureDetector(
              onTap: () => _handleTap(reply),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
