// Part of the Easy/Simple/Advanced workout-UI tier rework.
//
// Segmented `[ kg | lb ]` pill that reads+writes the same workout-weight-unit
// preference Advanced already consumes (`useKgForWorkoutProvider`). All three
// tiers mount this in their exercise header so a unit flip is instantly
// consistent across the app.
//
// Sizing: 32 pt tall × 56 pt wide (content sized; never stretches).
// Per feedback_accent_colors.md the selected-segment fill uses the runtime
// accent — never a hardcoded brand color.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/theme/accent_color_provider.dart';

class UnitChip extends ConsumerWidget {
  /// When true, renders the pill bigger with bolder text + accent-tinted
  /// background + a soft accent shadow so it reads as a prominent control
  /// next to the Weight label. Defaults to false so the Advanced top bar
  /// (tight horizontal space) keeps its compact 32pt version.
  final bool emphasize;

  const UnitChip({super.key, this.emphasize = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useKg = ref.watch(useKgForWorkoutProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);

    final height = emphasize ? 38.0 : 32.0;
    final width = emphasize ? 86.0 : 56.0;
    final radius = emphasize ? 19.0 : 16.0;
    final segRadius = emphasize ? 17.0 : 14.0;
    final fontSize = emphasize ? 15.0 : 13.0;
    final borderColor = emphasize
        ? accent.withValues(alpha: 0.35)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.14);
    final bgColor = emphasize
        ? accent.withValues(alpha: 0.08)
        : Colors.transparent;

    return Semantics(
      label: 'Weight unit, currently ${useKg ? 'kilograms' : 'pounds'}',
      button: true,
      child: Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: borderColor, width: emphasize ? 1.2 : 1),
          boxShadow: emphasize
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        padding: const EdgeInsets.all(2),
        child: Row(
          children: [
            Expanded(
              child: _UnitSegment(
                label: 'kg',
                selected: useKg,
                accent: accent,
                isDark: isDark,
                fontSize: fontSize,
                radius: segRadius,
                onTap: () => _setUnit(ref, 'kg', useKg),
              ),
            ),
            Expanded(
              child: _UnitSegment(
                label: 'lb',
                selected: !useKg,
                accent: accent,
                isDark: isDark,
                fontSize: fontSize,
                radius: segRadius,
                onTap: () => _setUnit(ref, 'lbs', !useKg),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _setUnit(WidgetRef ref, String unit, bool alreadySelected) async {
    if (alreadySelected) return;
    await HapticService.instance.tap();

    // Optimistically flip the local auth state so `useKgForWorkoutProvider`
    // emits NOW — the active-workout screens listen on it to convert the
    // displayed weight. Without this optimistic update the UI waits on a
    // server round-trip + refreshUser, and when refreshUser fails (auth
    // timeout, offline) the toggle appears broken.
    final notifier = ref.read(authStateProvider.notifier);
    notifier.setWorkoutWeightUnitOptimistic(unit);

    // Persist asynchronously in the background. Swallow errors — settings
    // page is the authoritative path for hard persistence failures.
    unawaited(() async {
      try {
        await notifier.updateUserProfile({'workout_weight_unit': unit});
      } catch (e) {
        debugPrint('⚠️ [UnitChip] Failed to persist unit: $e');
      }
    }());
  }
}

class _UnitSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final double fontSize;
  final double radius;
  final VoidCallback onTap;

  const _UnitSegment({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.fontSize,
    required this.radius,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final fg = selected
        ? (isDark ? Colors.black : Colors.white)
        : (isDark ? Colors.white : Colors.black).withValues(alpha: 0.78);
    final bg = selected ? accent : Colors.transparent;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(radius),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: fg,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
