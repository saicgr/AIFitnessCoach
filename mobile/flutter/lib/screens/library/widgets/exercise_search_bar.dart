import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/library_providers.dart';

/// Search bar widget for filtering exercises by name
class ExerciseSearchBar extends ConsumerWidget {
  const ExerciseSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return TextField(
      onChanged: (value) =>
          ref.read(exerciseSearchProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: 'Search exercises...',
        prefixIcon: Icon(Icons.search, color: textMuted),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: AppColorsLight.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: AppColorsLight.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

/// Search bar widget for filtering programs by name
class ProgramSearchBar extends ConsumerWidget {
  const ProgramSearchBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return TextField(
      onChanged: (value) =>
          ref.read(programSearchProvider.notifier).state = value,
      decoration: InputDecoration(
        hintText: 'Search programs...',
        prefixIcon: Icon(Icons.search, color: textMuted),
        filled: true,
        fillColor: elevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: AppColorsLight.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: isDark
              ? BorderSide.none
              : BorderSide(color: AppColorsLight.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}
