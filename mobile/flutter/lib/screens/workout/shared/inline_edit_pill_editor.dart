// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Expanded editor half of `InlineEditPill`. Split out so inline_edit_pill.dart
// stays under the 250-line project cap.

import 'package:flutter/material.dart';

class InlineEditPillExpanded extends StatelessWidget {
  final double weight;
  final int reps;
  final String unit;
  final Color accent;
  final bool isDark;
  final ValueChanged<int> onBumpWeight;
  final ValueChanged<int> onBumpReps;
  final VoidCallback onSave;

  const InlineEditPillExpanded({
    super.key,
    required this.weight,
    required this.reps,
    required this.unit,
    required this.accent,
    required this.isDark,
    required this.onBumpWeight,
    required this.onBumpReps,
    required this.onSave,
  });

  String get _weightText {
    if (weight == weight.roundToDouble()) return weight.toStringAsFixed(0);
    return weight.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final onSurface = isDark ? Colors.white : Colors.black;

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: isDark ? 0.10 : 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          _MiniButton(
            icon: Icons.remove_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => onBumpWeight(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$_weightText $unit',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _MiniButton(
            icon: Icons.add_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => onBumpWeight(1),
          ),
          Container(
            height: 32,
            width: 1,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            color: onSurface.withValues(alpha: 0.08),
          ),
          _MiniButton(
            icon: Icons.remove_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => onBumpReps(-1),
          ),
          Expanded(
            child: Center(
              child: Text(
                '$reps',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _MiniButton(
            icon: Icons.add_rounded,
            accent: accent,
            isDark: isDark,
            onTap: () => onBumpReps(1),
          ),
          const SizedBox(width: 4),
          _SaveButton(accent: accent, isDark: isDark, onTap: onSave),
        ],
      ),
    );
  }
}

class _MiniButton extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _MiniButton({
    required this.icon,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: isDark ? 0.20 : 0.14),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 18, color: accent),
      ),
    );
  }
}

class _SaveButton extends StatelessWidget {
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _SaveButton({
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Save set',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.check_rounded,
            size: 22,
            color: isDark ? Colors.black : Colors.white,
          ),
        ),
      ),
    );
  }
}
