import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/context_logging_service.dart';
import '../providers/library_providers.dart';

/// Search bar widget for filtering exercises by name
class ExerciseSearchBar extends ConsumerStatefulWidget {
  const ExerciseSearchBar({super.key});

  @override
  ConsumerState<ExerciseSearchBar> createState() => _ExerciseSearchBarState();
}

class _ExerciseSearchBarState extends ConsumerState<ExerciseSearchBar> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(exerciseSearchProvider.notifier).state = value;

    // Debounce the logging to avoid excessive API calls
    _debounceTimer?.cancel();
    if (value.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        // Log the search for AI preference learning
        ref.read(contextLoggingServiceProvider).logLibrarySearch(
          searchQuery: value,
          searchType: 'exercises',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return TextField(
      onChanged: _onSearchChanged,
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
class ProgramSearchBar extends ConsumerStatefulWidget {
  const ProgramSearchBar({super.key});

  @override
  ConsumerState<ProgramSearchBar> createState() => _ProgramSearchBarState();
}

class _ProgramSearchBarState extends ConsumerState<ProgramSearchBar> {
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(programSearchProvider.notifier).state = value;

    // Debounce the logging to avoid excessive API calls
    _debounceTimer?.cancel();
    if (value.length >= 2) {
      _debounceTimer = Timer(const Duration(milliseconds: 800), () {
        // Log the search for AI preference learning
        ref.read(contextLoggingServiceProvider).logLibrarySearch(
          searchQuery: value,
          searchType: 'programs',
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    return TextField(
      onChanged: _onSearchChanged,
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
