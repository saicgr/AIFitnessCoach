import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/accent_color_provider.dart';
import '../../../data/services/haptic_service.dart';

/// A compact, overflow-safe selector for sore / painful body regions.
///
/// Renders a [Wrap] of toggleable chips (one per region). Selected chips are
/// highlighted with the resolved accent color. The widget speaks human display
/// labels to the user ("Lower back", "Knees") but reports the underlying
/// snake_case keys via [onChanged] — those keys feed the studio's
/// `soreAreas` param straight through to the backend.
class BodyMapSelector extends ConsumerWidget {
  /// Currently selected region keys (snake_case, e.g. `lower_back`).
  final List<String> selected;

  /// Called with the full updated list of selected snake_case keys.
  final ValueChanged<List<String>> onChanged;

  const BodyMapSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// Ordered region catalog: snake_case key -> human display label.
  /// Order is roughly head-to-toe so the chip grid reads anatomically.
  static const List<MapEntry<String, String>> _regions = [
    MapEntry('neck', 'Neck'),
    MapEntry('shoulders', 'Shoulders'),
    MapEntry('chest', 'Chest'),
    MapEntry('upper_back', 'Upper back'),
    MapEntry('lower_back', 'Lower back'),
    MapEntry('biceps', 'Biceps'),
    MapEntry('triceps', 'Triceps'),
    MapEntry('forearms', 'Forearms'),
    MapEntry('wrists', 'Wrists'),
    MapEntry('elbows', 'Elbows'),
    MapEntry('core', 'Core'),
    MapEntry('glutes', 'Glutes'),
    MapEntry('quads', 'Quads'),
    MapEntry('hamstrings', 'Hamstrings'),
    MapEntry('calves', 'Calves'),
    MapEntry('knees', 'Knees'),
    MapEntry('hips', 'Hips'),
    MapEntry('ankles', 'Ankles'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = ref.watch(accentColorProvider).getColor(isDark);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _regions.map((entry) {
        final key = entry.key;
        final label = entry.value;
        final isSelected = selected.contains(key);
        return _RegionChip(
          label: label,
          selected: isSelected,
          accent: accent,
          isDark: isDark,
          onTap: () {
            HapticService.selection();
            final next = List<String>.from(selected);
            if (isSelected) {
              next.remove(key);
            } else {
              next.add(key);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}

class _RegionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _RegionChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final baseText = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final unselectedBg = (isDark ? AppColors.surface : AppColorsLight.surface)
        .withValues(alpha: isDark ? 0.6 : 1.0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.18) : unselectedBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected
                  ? accent
                  : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.12),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                Icon(Icons.check_circle, size: 15, color: accent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? accent : baseText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
