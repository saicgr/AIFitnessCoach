import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/accent_color_provider.dart';
import '../../widgets/glass_sheet.dart';
import '../../data/models/program_template.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import 'program_template_builder_screen.dart';
import 'widgets/program_library_card.dart';

/// Route metadata for the program library — kept here so the builder and the
/// router reference one path constant without a circular import.
class ProgramLibraryRoute {
  ProgramLibraryRoute._();
  static const String path = '/workout/program-library';
}

/// Browse the curated 259-program library (`GET /program-templates/library`).
///
/// Category + difficulty filter chips, a search field, a responsive grid of
/// designed [ProgramLibraryCard]s. Tapping a card opens a structured preview
/// sheet; "Import & customize" clones the program into an editable saved
/// template and opens the builder.
class ProgramLibraryScreen extends ConsumerStatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  ConsumerState<ProgramLibraryScreen> createState() =>
      _ProgramLibraryScreenState();
}

/// The eight library categories surfaced as filter chips. `null` = All.
const List<String?> _kCategories = [
  null,
  'Celebrity',
  'Sport',
  'Goal-Based',
  'Specialized',
  'Yoga',
  'Health',
  'Stretching',
  'Pain Management',
];

const List<String?> _kDifficulties = [
  null,
  'Beginner',
  'Intermediate',
  'Advanced',
];

class _ProgramLibraryScreenState extends ConsumerState<ProgramLibraryScreen> {
  String? _category;
  String? _difficulty;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  Future<ProgramLibraryResult>? _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// (Re)issue the library query for the current filter state.
  void _reload() {
    final repo = ref.read(programTemplateRepositoryProvider);
    setState(() {
      _future = repo.browseLibrary(
        category: _category,
        difficulty: _difficulty,
        search: _search.isEmpty ? null : _search,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.background : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'Program Library',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: Column(
        children: [
          _buildSearchField(isDark, textPrimary, accent),
          _buildCategoryChips(isDark, accent),
          _buildDifficultyChips(isDark, accent),
          const SizedBox(height: 4),
          Expanded(child: _buildGrid(isDark, textPrimary, accent)),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Filters.
  // -------------------------------------------------------------------------

  Widget _buildSearchField(bool isDark, Color textPrimary, Color accent) {
    final fieldBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textPrimary, fontSize: 14),
        textInputAction: TextInputAction.search,
        onSubmitted: (v) {
          _search = v.trim();
          _reload();
        },
        decoration: InputDecoration(
          hintText: 'Search programs',
          hintStyle: TextStyle(color: muted, fontSize: 14),
          prefixIcon: Icon(Icons.search_rounded, color: muted, size: 20),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: Icon(Icons.close_rounded, color: muted, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _search = '';
                    _reload();
                  },
                ),
          filled: true,
          fillColor: fieldBg,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(bool isDark, Color accent) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _kCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final cat = _kCategories[i];
          final selected = _category == cat;
          return _FilterChip(
            label: cat ?? 'All',
            selected: selected,
            accent: accent,
            isDark: isDark,
            onTap: () {
              HapticService.selection();
              _category = selected ? null : cat;
              _reload();
            },
          );
        },
      ),
    );
  }

  Widget _buildDifficultyChips(bool isDark, Color accent) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            'Level',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: muted,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Wrap(
              spacing: 6,
              children: [
                for (final d in _kDifficulties)
                  _FilterChip(
                    label: d ?? 'Any',
                    compact: true,
                    selected: _difficulty == d,
                    accent: accent,
                    isDark: isDark,
                    onTap: () {
                      HapticService.selection();
                      _difficulty = _difficulty == d ? null : d;
                      _reload();
                    },
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Grid — loading / error / empty / data states.
  // -------------------------------------------------------------------------

  Widget _buildGrid(bool isDark, Color textPrimary, Color accent) {
    return FutureBuilder<ProgramLibraryResult>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonGrid();
        }
        if (snapshot.hasError) {
          return _ErrorState(
            message: 'We could not load the program library.',
            onRetry: _reload,
            isDark: isDark,
          );
        }
        final result = snapshot.data;
        if (result == null || result.programs.isEmpty) {
          return _EmptyState(
            isDark: isDark,
            hasFilters: _category != null ||
                _difficulty != null ||
                _search.isNotEmpty,
            onClear: () {
              _category = null;
              _difficulty = null;
              _search = '';
              _searchController.clear();
              _reload();
            },
          );
        }
        return _buildCardGrid(result.programs);
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      gridDelegate: _gridDelegate(),
      itemCount: 6,
      itemBuilder: (_, __) => const ProgramLibraryCardSkeleton(),
    );
  }

  Widget _buildCardGrid(List<ProgramLibraryCard> programs) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      gridDelegate: _gridDelegate(),
      itemCount: programs.length,
      itemBuilder: (context, i) {
        final p = programs[i];
        return ProgramLibraryCardTile(
          data: p,
          onTap: () => _openPreview(p),
        );
      },
    );
  }

  /// Responsive grid — one column on iPhone SE, two on wider phones / iPad.
  SliverGridDelegate _gridDelegate() {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 280,
      mainAxisExtent: 196,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
  }

  // -------------------------------------------------------------------------
  // Preview sheet.
  // -------------------------------------------------------------------------

  void _openPreview(ProgramLibraryCard card) {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(child: _ProgramPreviewSheet(card: card)),
    );
  }
}

// ===========================================================================
// Filter chip.
// ===========================================================================

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool compact;
  final Color accent;
  final bool isDark;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.isDark,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final base = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = selected
        ? (accent.computeLuminance() > 0.55 ? Colors.black : Colors.white)
        : (isDark ? AppColors.textSecondary : AppColorsLight.textSecondary);
    return Material(
      color: selected ? accent : base,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 12 : 14,
            vertical: compact ? 6 : 9,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11.5 : 12.5,
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
// Error + empty states.
// ===========================================================================

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  const _ErrorState({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 44, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({
    required this.isDark,
    required this.hasFilters,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 44, color: textSecondary),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? 'No programs match these filters.'
                  : 'No programs available right now.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 14),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onClear,
                child: const Text('Clear filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Preview sheet — full structured preview + "Import & customize".
// ===========================================================================

class _ProgramPreviewSheet extends ConsumerStatefulWidget {
  final ProgramLibraryCard card;
  const _ProgramPreviewSheet({required this.card});

  @override
  ConsumerState<_ProgramPreviewSheet> createState() =>
      _ProgramPreviewSheetState();
}

class _ProgramPreviewSheetState extends ConsumerState<_ProgramPreviewSheet> {
  Future<ProgramTemplate>? _preview;
  bool _importing = false;

  @override
  void initState() {
    super.initState();
    _preview = ref
        .read(programTemplateRepositoryProvider)
        .previewLibraryProgram(widget.card.id);
  }

  Future<void> _import() async {
    if (_importing) return;
    setState(() => _importing = true);
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    try {
      final template = await repo.importFromProgram(widget.card.id);
      if (!mounted) return;
      navigator.pop();
      // Open the builder pre-filled with the imported (now editable) copy.
      router.push(ProgramBuilderRoute.path, extra: template);
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not import this program. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? AppColors.surface : AppColorsLight.background;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final accent = AccentColorScope.of(context).getColor(isDark);

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: sheetBg,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: FutureBuilder<ProgramTemplate>(
                  future: _preview,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: 'Could not load this program preview.',
                        isDark: isDark,
                        onRetry: () => setState(() {
                          _preview = ref
                              .read(programTemplateRepositoryProvider)
                              .previewLibraryProgram(widget.card.id);
                        }),
                      );
                    }
                    final template = snapshot.data!;
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      children: [
                        Text(
                          template.name,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: textPrimary,
                          ),
                        ),
                        if ((widget.card.celebrityName ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'With ${widget.card.celebrityName!.trim()}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: accent,
                            ),
                          ),
                        ],
                        if ((template.description ?? '')
                            .trim()
                            .isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            template.description!.trim(),
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: textSecondary,
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _previewStatsRow(template, isDark),
                        const SizedBox(height: 16),
                        for (final day in template.days)
                          _DayPreviewTile(day: day, isDark: isDark),
                      ],
                    );
                  },
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.tune_rounded, size: 18),
                      label: Text(
                        _importing ? 'Importing...' : 'Import & customize',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _previewStatsRow(ProgramTemplate template, bool isDark) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _miniStat(Icons.event_rounded,
            '${template.weekLength}-day cycle', muted),
        _miniStat(Icons.fitness_center_rounded,
            '${template.trainingDayCount} training days', muted),
        _miniStat(Icons.list_alt_rounded,
            '${template.totalExercises} exercises', muted),
      ],
    );
  }

  Widget _miniStat(IconData icon, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ],
    );
  }
}

/// One collapsible-looking day row inside the preview sheet.
class _DayPreviewTile extends StatelessWidget {
  final ProgramDay day;
  final bool isDark;

  const _DayPreviewTile({required this.day, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;

    if (day.effectivelyRest) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.bedtime_outlined, size: 16, color: textSecondary),
            const SizedBox(width: 8),
            Text(
              '${day.dayName} · Rest',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          for (final ex in day.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: TextStyle(color: textSecondary, fontSize: 13)),
                  Expanded(
                    child: Text(
                      ex.name,
                      style: TextStyle(fontSize: 13, color: textPrimary),
                    ),
                  ),
                  Text(
                    '${ex.sets} × ${ex.repsLabel()}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
