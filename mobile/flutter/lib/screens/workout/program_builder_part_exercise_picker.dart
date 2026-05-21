import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../data/models/program_template.dart';
import '../../data/repositories/library_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/lottie_animations.dart';

/// Exercise picker for the program-template builder (plan B.3).
///
/// A draggable bottom sheet that searches the shared exercise library
/// ([LibraryRepository.searchExercises]) with an optional body-part filter.
/// Tapping a result builds a [ProgramExercise] with sensible defaults
/// (3 sets, 10 reps, RIR 2, 75s rest) and returns it to the caller via
/// [Navigator.pop]. The builder screen appends it to the day being edited.
///
/// Kept in its own file so `program_template_builder_screen.dart` stays
/// focused on the three entry tabs + the day editor. Mirrors the working
/// search flow in `custom_workout_builder_screen.dart`.
class ProgramBuilderExercisePicker extends ConsumerStatefulWidget {
  /// Names already on the day — shown with a check so the user does not add
  /// a duplicate by accident (they still can if they tap through).
  final Set<String> existingNames;

  /// The day label, used only for the sheet header ("Add to Upper A").
  final String dayName;

  const ProgramBuilderExercisePicker({
    super.key,
    required this.dayName,
    this.existingNames = const {},
  });

  /// Opens the picker as a modal bottom sheet. Resolves to the chosen
  /// [ProgramExercise], or null when the user dismisses without picking.
  static Future<ProgramExercise?> show(
    BuildContext context, {
    required String dayName,
    Set<String> existingNames = const {},
  }) {
    return showModalBottomSheet<ProgramExercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ProgramBuilderExercisePicker(
        dayName: dayName,
        existingNames: existingNames,
      ),
    );
  }

  @override
  ConsumerState<ProgramBuilderExercisePicker> createState() =>
      _ProgramBuilderExercisePickerState();
}

class _ProgramBuilderExercisePickerState
    extends ConsumerState<ProgramBuilderExercisePicker> {
  final _searchController = TextEditingController();

  // The body-part filter chips. "All" maps to a null filter.
  static const _categories = <String>[
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
    'Cardio',
  ];

  String _query = '';
  String? _selectedCategory;

  bool _isSearching = false;
  bool _hasSearched = false;
  String? _error;
  List<LibraryExerciseItem> _results = const [];

  /// Monotonic token so a slow earlier request cannot overwrite a newer one.
  int _searchSeq = 0;

  @override
  void initState() {
    super.initState();
    // Show something immediately rather than an empty sheet.
    _runSearch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final seq = ++_searchSeq;
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final repo = ref.read(libraryRepositoryProvider);
      final bodyPart =
          (_selectedCategory != null && _selectedCategory != 'All')
              ? _selectedCategory!.toLowerCase()
              : null;
      final results = await repo.searchExercises(
        query: _query.isNotEmpty ? _query : null,
        bodyPart: bodyPart,
        limit: 60,
      );
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _results = results;
        _isSearching = false;
        _hasSearched = true;
      });
    } catch (e) {
      if (!mounted || seq != _searchSeq) return;
      setState(() {
        _isSearching = false;
        _hasSearched = true;
        _error =
            'Could not load exercises. Check your connection and try again.';
      });
    }
  }

  /// Build a [ProgramExercise] from a library row with builder defaults and
  /// hand it back to the caller.
  void _pick(LibraryExerciseItem item) {
    HapticService.selection();
    final exercise = ProgramExercise(
      name: item.name,
      exerciseId: item.id.isNotEmpty ? item.id : null,
      sets: 3,
      reps: '10',
      repsSpec: const RepsSpec(kind: RepsKind.fixed, min: 10, max: 10),
      targetRir: 2,
      restSeconds: 75,
      // A library-resolved pick is, by definition, resolved.
      unresolved: false,
      resolutionSource: 'exact',
    );
    Navigator.of(context).pop(exercise);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = AccentColorScope.of(context).getColor(isDark);
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            children: [
              // Grab handle.
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: textSecondary.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add to ${widget.dayName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: textSecondary),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Search field.
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  style: TextStyle(fontSize: 14, color: textPrimary),
                  textInputAction: TextInputAction.search,
                  onChanged: (v) {
                    _query = v;
                    _runSearch();
                  },
                  onSubmitted: (_) => _runSearch(),
                  decoration: InputDecoration(
                    hintText: 'Search exercises...',
                    hintStyle:
                        TextStyle(fontSize: 14, color: textSecondary),
                    prefixIcon:
                        Icon(Icons.search_rounded, color: textSecondary),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(Icons.clear_rounded,
                                size: 18, color: textSecondary),
                            onPressed: () {
                              _searchController.clear();
                              _query = '';
                              _runSearch();
                            },
                          ),
                    filled: true,
                    fillColor: fieldBg,
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              // Category filter chips.
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final category = _categories[i];
                    final isSelected = _selectedCategory == category ||
                        (category == 'All' && _selectedCategory == null);
                    return _CategoryChip(
                      label: category,
                      selected: isSelected,
                      accent: accent,
                      isDark: isDark,
                      onTap: () {
                        setState(() {
                          _selectedCategory =
                              (category == 'All') ? null : category;
                        });
                        _runSearch();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 6),
              Divider(
                height: 1,
                color: textSecondary.withValues(alpha: 0.12),
              ),

              // Results.
              Expanded(
                child: _buildResults(
                  scrollController,
                  isDark,
                  accent,
                  textPrimary,
                  textSecondary,
                  fieldBg,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResults(
    ScrollController scrollController,
    bool isDark,
    Color accent,
    Color textPrimary,
    Color textSecondary,
    Color fieldBg,
  ) {
    if (_isSearching && _results.isEmpty) {
      return const Center(child: LottieLoading(size: 54));
    }
    if (_error != null) {
      return _StateMessage(
        icon: Icons.wifi_off_rounded,
        message: _error!,
        color: textSecondary,
        action: TextButton(
          onPressed: _runSearch,
          child: Text('Retry', style: TextStyle(color: accent)),
        ),
      );
    }
    if (_hasSearched && _results.isEmpty) {
      return _StateMessage(
        icon: Icons.search_off_rounded,
        message: _query.isEmpty && _selectedCategory == null
            ? 'No exercises available right now.'
            : 'No exercises match your search.',
        color: textSecondary,
      );
    }
    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 16),
      itemCount: _results.length,
      itemBuilder: (context, i) {
        final item = _results[i];
        final alreadyAdded = widget.existingNames.contains(item.name);
        return _ResultTile(
          item: item,
          alreadyAdded: alreadyAdded,
          isDark: isDark,
          accent: accent,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
          fieldBg: fieldBg,
          onTap: () => _pick(item),
        );
      },
    );
  }
}

// ===========================================================================
// Category chip.
// ===========================================================================

class _CategoryChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = selected
        ? (accent.computeLuminance() > 0.55 ? Colors.black : Colors.white)
        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);
    return Material(
      color: selected ? accent : base,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Result tile.
// ===========================================================================

class _ResultTile extends StatelessWidget {
  final LibraryExerciseItem item;
  final bool alreadyAdded;
  final bool isDark;
  final Color accent;
  final Color textPrimary;
  final Color textSecondary;
  final Color fieldBg;
  final VoidCallback onTap;

  const _ResultTile({
    required this.item,
    required this.alreadyAdded,
    required this.isDark,
    required this.accent,
    required this.textPrimary,
    required this.textSecondary,
    required this.fieldBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = item.gifUrl ?? item.imageUrl;
    final subtitle = item.targetMuscle ??
        item.bodyPart ??
        item.equipment ??
        'Exercise';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      child: Material(
        color: fieldBg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          // Tapping an added exercise still adds it again — programs can
          // legitimately repeat a movement — but the check signals it.
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                _Thumb(url: imageUrl, fieldBg: fieldBg),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (alreadyAdded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Icon(Icons.check_circle_rounded,
                        size: 22, color: accent),
                  )
                else
                  Icon(Icons.add_circle_outline_rounded,
                      size: 24, color: accent),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact illustration thumbnail with a fitness-center fallback glyph.
class _Thumb extends StatelessWidget {
  final String? url;
  final Color fieldBg;

  const _Thumb({required this.url, required this.fieldBg});

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: fieldBg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.fitness_center_rounded,
          size: 20, color: AppColors.textSecondary),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: url!,
        width: 46,
        height: 46,
        fit: BoxFit.cover,
        placeholder: (_, __) => placeholder,
        errorWidget: (_, __, ___) => placeholder,
      ),
    );
  }
}

// ===========================================================================
// Empty / error state.
// ===========================================================================

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final Widget? action;

  const _StateMessage({
    required this.icon,
    required this.message,
    required this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: color.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.4, color: color),
            ),
            if (action != null) ...[
              const SizedBox(height: 8),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
