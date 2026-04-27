import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/services/context_logging_service.dart';
import '../models/filter_option.dart';
import '../providers/library_providers.dart';

/// Search bar widget for filtering exercises by name OR equipment.
///
/// GymBeat-parity: typing an equipment keyword (e.g. "treadmill", "barbell")
/// surfaces an "Filter by equipment: …" suggestion chip just below the field.
/// Tapping it applies the equipment filter and clears the free-text search so
/// the chip-driven filter is the source of truth.
class ExerciseSearchBar extends ConsumerStatefulWidget {
  const ExerciseSearchBar({super.key});

  @override
  ConsumerState<ExerciseSearchBar> createState() => _ExerciseSearchBarState();
}

class _ExerciseSearchBarState extends ConsumerState<ExerciseSearchBar> {
  Timer? _debounceTimer;
  final _controller = TextEditingController();

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
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

  /// Returns the equipment option matching `query` (case-insensitive,
  /// substring or token-overlap), or null if no equipment name matches.
  /// "treadmill" → Treadmill. "bar bell" → Barbell. "db" → Dumbbells.
  FilterOption? _matchEquipment(String query, List<FilterOption> equipment) {
    final q = query.trim().toLowerCase();
    if (q.length < 2) return null;
    // Exact + prefix matches first
    for (final eq in equipment) {
      if (eq.name.toLowerCase() == q) return eq;
    }
    for (final eq in equipment) {
      if (eq.name.toLowerCase().startsWith(q)) return eq;
    }
    // Substring match
    for (final eq in equipment) {
      if (eq.name.toLowerCase().contains(q)) return eq;
    }
    // Common alias map for the impatient typer
    const aliases = {
      'db': 'Dumbbells',
      'bb': 'Barbell',
      'kb': 'Kettlebell',
      'machine': 'Machine',
      'cable': 'Cable',
      'tm': 'Treadmill',
      'bike': 'Stationary Bike',
    };
    final hit = aliases[q];
    if (hit != null) {
      for (final eq in equipment) {
        if (eq.name.toLowerCase() == hit.toLowerCase()) return eq;
      }
    }
    return null;
  }

  void _applyEquipment(FilterOption eq) {
    final current = ref.read(selectedEquipmentsProvider);
    ref.read(selectedEquipmentsProvider.notifier).state = {...current, eq.name};
    // Clear the search query so the equipment chip is the active filter,
    // matching GymBeat's "type-to-filter" interaction.
    _controller.clear();
    ref.read(exerciseSearchProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cyan = isDark ? AppColors.cyan : AppColorsLight.cyan;

    final query = ref.watch(exerciseSearchProvider);
    final filterOpts = ref.watch(filterOptionsProvider).valueOrNull;
    final equipmentMatch = filterOpts == null
        ? null
        : _matchEquipment(query, filterOpts.equipment);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _controller,
          onChanged: _onSearchChanged,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) {
            // Submit-key shortcut: if the typed text matches an equipment,
            // pin it as a chip filter instead of leaving it as a free-text query.
            if (equipmentMatch != null) _applyEquipment(equipmentMatch);
          },
          decoration: InputDecoration(
            hintText: 'Search exercises or equipment...',
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
        ),
        if (equipmentMatch != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              children: [
                Icon(Icons.fitness_center_rounded, size: 14, color: cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _applyEquipment(equipmentMatch),
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 12, color: textMuted),
                        children: [
                          const TextSpan(text: 'Filter by equipment: '),
                          TextSpan(
                            text: equipmentMatch.name,
                            style: TextStyle(
                              color: cyan,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                          TextSpan(text: ' (${equipmentMatch.count})'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
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
