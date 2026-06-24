import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/signature/signature.dart';
import '../../data/models/program_template.dart';
import '../../data/providers/branded_program_provider.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import 'program_template_builder_screen.dart';
import 'widgets/program_library_card.dart';

import '../../l10n/generated/app_localizations.dart';

/// Route metadata for the program library — kept here so the builder and the
/// router reference one path constant without a circular import.
class ProgramLibraryRoute {
  ProgramLibraryRoute._();
  static const String path = '/workout/program-library';
}

/// Browse the curated 259-program library — signature-v2 redesign.
///
/// Near-black surface, Anton "PROGRAMS" masthead, an orange-accented language.
/// The screen is a single scroll that, when no filter/search is active, reads
/// like a discovery surface: a Recommended-for-you hero carousel, intent rails
/// (Quick / Beginner-friendly / a goal rail), category quick-chips, and a
/// "Browse by category" grid. The moment a filter, search, or category chip is
/// active it collapses to the filtered browse list (the real result surface).
///
/// Tapping any program opens the structured preview sheet; "Import & customize"
/// clones the program into an editable saved template and opens the builder —
/// that flow is preserved exactly from the prior implementation.
class ProgramLibraryScreen extends ConsumerStatefulWidget {
  const ProgramLibraryScreen({super.key});

  @override
  ConsumerState<ProgramLibraryScreen> createState() =>
      _ProgramLibraryScreenState();
}

/// The library categories surfaced as filter chips. `null` = All.
const List<String?> _kCategories = [
  null,
  'Goal-Based',
  'Sport',
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
  'Elite',
];

/// Sessions/week quick-pick values (null = Any).
const List<int?> _kSessions = [null, 2, 3, 4, 5, 6];

/// Duration buckets for the filter sheet — label + (min,max) weeks (null=open).
const List<({String label, int? min, int? max})> _kDurationBuckets = [
  (label: 'Any', min: null, max: null),
  (label: '≤4 WK', min: null, max: 4),
  (label: '5–8 WK', min: 5, max: 8),
  (label: '9–12 WK', min: 9, max: 12),
  (label: '12+ WK', min: 13, max: null),
];

/// Goal chips for the filter sheet — label drives the `goals` query field.
const List<String> _kGoals = [
  'Build Muscle',
  'Lose Fat',
  'Get Strong',
  'Endurance',
  'Mobility',
];

/// A rail short enough to fit ~30-minute sessions. The library exposes
/// `session_duration_minutes` only through the card model (not a server filter),
/// so the QUICK rail filters Beginner programs and we cap the rendered posters
/// to those ≤30 min, falling back to the shortest available if the server has
/// no minute data — labeled honestly as "QUICK · ≤30 MIN".
const int _kQuickMaxMinutes = 30;

class _ProgramLibraryScreenState extends ConsumerState<ProgramLibraryScreen> {
  String? _category;
  String? _difficulty;
  int? _sessionsPerWeek;
  final Set<String> _goals = <String>{};
  int? _durationMin;
  int? _durationMax;
  String _search = '';
  final TextEditingController _searchController = TextEditingController();

  /// A PageView of the recommended/featured hero cards.
  final PageController _heroController = PageController(viewportFraction: 0.88);
  int _heroPage = 0;

  @override
  void dispose() {
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Filter state.
  // -------------------------------------------------------------------------

  /// The active browse filter (drives the result surface + Retry refresh).
  ProgramLibraryFilter get _filter => (
        category: _category,
        difficulty: _difficulty,
        sessionsPerWeek: _sessionsPerWeek,
        search: _search.isEmpty ? null : _search,
        goals: _goals.isEmpty ? null : _goals.toList(growable: false),
        durationMin: _durationMin,
        durationMax: _durationMax,
      );

  /// Whether the user has narrowed the library at all — when true the screen
  /// shows the filtered browse result surface instead of the discovery rails.
  bool get _hasActiveFilter =>
      _category != null ||
      _difficulty != null ||
      _sessionsPerWeek != null ||
      _goals.isNotEmpty ||
      _durationMin != null ||
      _durationMax != null ||
      _search.isNotEmpty;

  /// How many discrete filter facets are active (drives the Filter pill badge).
  int get _activeFilterCount {
    var n = 0;
    if (_category != null) n++;
    if (_difficulty != null) n++;
    if (_sessionsPerWeek != null) n++;
    if (_durationMin != null || _durationMax != null) n++;
    n += _goals.length;
    return n;
  }

  void _applyFilters() => setState(() {});

  void _clearFilters() {
    setState(() {
      _category = null;
      _difficulty = null;
      _sessionsPerWeek = null;
      _goals.clear();
      _durationMin = null;
      _durationMax = null;
      _search = '';
      _searchController.clear();
    });
  }

  /// Force a silent refresh of the current browse combo (used by Retry).
  void _refresh() {
    ref.invalidate(programLibraryBrowseProvider(_filter));
    setState(() {});
  }

  // -------------------------------------------------------------------------
  // Build.
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(context),
            Expanded(
              child: _hasActiveFilter
                  ? _buildFilteredSurface()
                  : _buildDiscovery(),
            ),
          ],
        ),
      ),
    );
  }

  /// Back ‹ + Anton "PROGRAMS" over a hairline rule.
  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(bottom: BorderSide(color: AppColors.hairlineStrong)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 18, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {
              HapticService.light();
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.only(right: 8, top: 2, bottom: 2),
              child: Text(
                '‹',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 32,
                  height: 1.0,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ),
          Text(
            AppLocalizations.of(context).programLibraryProgramLibrary,
            style: ZType.disp(30, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Discovery surface — hero carousel + search + chips + rails + categories.
  // -------------------------------------------------------------------------

  Widget _buildDiscovery() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 28),
      children: [
        const SizedBox(height: 14),
        _buildHeroCarousel(),
        const SizedBox(height: 12),
        _buildSearchAndFilterRow(),
        const SizedBox(height: 10),
        _buildCategoryQuickChips(),
        const SizedBox(height: 18),
        _buildQuickRail(),
        _buildBeginnerRail(),
        _buildGoalRail(),
        const SizedBox(height: 4),
        _buildBrowseByCategory(),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Hero carousel — Recommended for you (falls back to Featured if empty).
  // -------------------------------------------------------------------------

  Widget _buildHeroCarousel() {
    final recommended = ref.watch(programRecommendedProvider);

    return recommended.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: _heroSkeleton,
      // A failed recommendation fetch isn't fatal to the whole screen — fall
      // back to featured so the masthead still has a hero. If both fail, the
      // hero quietly collapses (the rails + categories below still render).
      error: (_, __) => _buildFeaturedHeroFallback(),
      data: (result) {
        if (result.programs.isEmpty) {
          return _buildFeaturedHeroFallback();
        }
        return _buildHeroPager(result.programs, 'Recommended for you');
      },
    );
  }

  Widget _buildFeaturedHeroFallback() {
    final featured = ref.watch(programFeaturedProvider);
    return featured.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: _heroSkeleton,
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        if (result.programs.isEmpty) return const SizedBox.shrink();
        return _buildHeroPager(result.programs, 'Program of the week');
      },
    );
  }

  Widget _buildHeroPager(List<ProgramLibraryCard> programs, String kicker) {
    // Cap the carousel so it stays a curated "of the week" lane, not a feed.
    final cards = programs.take(6).toList(growable: false);
    final page = _heroPage.clamp(0, cards.length - 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
          child: ZSectionKicker(label: kicker),
        ),
        SizedBox(
          height: 232,
          child: PageView.builder(
            controller: _heroController,
            itemCount: cards.length,
            onPageChanged: (i) => setState(() => _heroPage = i),
            itemBuilder: (context, i) {
              final p = cards[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 18 : 6,
                  right: i == cards.length - 1 ? 18 : 6,
                ),
                child: ZHeroCard(
                  title: p.programName,
                  description: p.description,
                  category: p.programCategory,
                  difficultyLevel: p.difficultyLevel,
                  meta: _heroMeta(p),
                  primaryLabel: 'START PROGRAM',
                  onPrimary: () => _startProgram(p),
                  ghostLabel: 'PREVIEW',
                  onGhost: () => _openPreview(p),
                  onTap: () => _openPreview(p),
                ),
              );
            },
          ),
        ),
        if (cards.length > 1) ...[
          const SizedBox(height: 10),
          ZCarouselDots(
            count: cards.length,
            index: page,
            onPrev: () => _heroController.previousPage(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            ),
            onNext: () => _heroController.nextPage(
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ],
    );
  }

  Widget _heroSkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _ShimmerBox(width: 160, height: 13),
          const SizedBox(height: 12),
          Container(
            height: 232,
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.cardBorder),
            ),
          ),
        ],
      ),
    );
  }

  /// `LEVEL · wk WK · n×/WK · min MIN` — Space Mono meta (rendered by the card).
  String _heroMeta(ProgramLibraryCard p) {
    final parts = <String>[];
    final lvl = p.difficultyLevel?.trim();
    if (lvl != null && lvl.isNotEmpty) parts.add(lvl.toUpperCase());
    if (p.durationWeeks != null) parts.add('${p.durationWeeks} WK');
    if (p.sessionsPerWeek != null) parts.add('${p.sessionsPerWeek}×/WK');
    if (p.sessionDurationMinutes != null) {
      parts.add('${p.sessionDurationMinutes} MIN');
    }
    return parts.join(' · ');
  }

  // -------------------------------------------------------------------------
  // Search pill + Filter button.
  // -------------------------------------------------------------------------

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Expanded(child: _buildSearchPill()),
          const SizedBox(width: 10),
          _buildFilterButton(),
        ],
      ),
    );
  }

  Widget _buildSearchPill() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.cardBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.search_rounded,
              color: AppColors.textMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              style: ZType.sans(13.5,
                  color: AppColors.textPrimary, weight: FontWeight.w500),
              cursorColor: AppColors.orange,
              textInputAction: TextInputAction.search,
              onSubmitted: (v) {
                _search = v.trim();
                _applyFilters();
              },
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: InputBorder.none,
                hintText:
                    AppLocalizations.of(context).programLibrarySearchPrograms,
                hintStyle: ZType.sans(13.5,
                    color: AppColors.textMuted, weight: FontWeight.w500),
              ),
            ),
          ),
          if (_search.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                _search = '';
                _applyFilters();
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.close_rounded,
                    color: AppColors.textMuted, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterButton() {
    final count = _activeFilterCount;
    return GestureDetector(
      onTap: _openFilterSheet,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: count > 0 ? AppColors.orange : AppColors.cardBorder,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded,
                size: 15,
                color: count > 0 ? AppColors.orange : AppColors.textPrimary),
            const SizedBox(width: 7),
            Text(
              'FILTER',
              style: ZType.lbl(11,
                  color:
                      count > 0 ? AppColors.orange : AppColors.textPrimary,
                  letterSpacing: 1.5),
            ),
            if (count > 0) ...[
              const SizedBox(width: 7),
              Container(
                constraints:
                    const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$count',
                  style: ZType.data(10, color: Colors.white),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Category quick-chips (label + count) from the counts provider.
  // -------------------------------------------------------------------------

  Widget _buildCategoryQuickChips() {
    final counts = ref.watch(programCategoryCountsProvider);
    return counts.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const SizedBox(height: 34),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 18),
            itemCount: cats.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              if (i == 0) {
                return ZChip(
                  label: AppLocalizations.of(context).syncedWorkoutsHistoryAll,
                  selected: _category == null,
                  onTap: () {
                    HapticService.selection();
                    setState(() => _category = null);
                  },
                );
              }
              final cat = cats[i - 1];
              return ZChip(
                label: '${cat.category}  ${cat.count}',
                selected: _category == cat.category,
                onTap: () {
                  HapticService.selection();
                  setState(() => _category =
                      _category == cat.category ? null : cat.category);
                },
              );
            },
          ),
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Rails — each backed by a distinct browse filter.
  // -------------------------------------------------------------------------

  /// QUICK · ≤30 MIN — Beginner programs, capped to short sessions client-side.
  Widget _buildQuickRail() {
    const filter = (
      category: null,
      difficulty: 'Beginner',
      sessionsPerWeek: null,
      search: null,
      goals: null,
      durationMin: null,
      durationMax: null,
    );
    return _Rail(
      title: 'QUICK · ≤30 MIN',
      filter: filter,
      onSeeAll: () {
        setState(() {
          _difficulty = 'Beginner';
        });
      },
      transform: (programs) {
        final short = programs
            .where((p) =>
                p.sessionDurationMinutes != null &&
                p.sessionDurationMinutes! <= _kQuickMaxMinutes)
            .toList(growable: false);
        return short.isNotEmpty ? short : programs;
      },
      onTapCard: _openPreview,
    );
  }

  Widget _buildBeginnerRail() {
    const filter = (
      category: null,
      difficulty: 'Beginner',
      sessionsPerWeek: null,
      search: null,
      goals: null,
      durationMin: null,
      durationMax: null,
    );
    return _Rail(
      title: 'BEGINNER-FRIENDLY',
      filter: filter,
      onSeeAll: () => setState(() => _difficulty = 'Beginner'),
      onTapCard: _openPreview,
    );
  }

  Widget _buildGoalRail() {
    const goal = 'Build Muscle';
    const filter = (
      category: null,
      difficulty: null,
      sessionsPerWeek: null,
      search: null,
      goals: ['Build Muscle'],
      durationMin: null,
      durationMax: null,
    );
    return _Rail(
      title: 'GOAL · BUILD MUSCLE',
      filter: filter,
      onSeeAll: () => setState(() => _goals
        ..clear()
        ..add(goal)),
      onTapCard: _openPreview,
    );
  }

  // -------------------------------------------------------------------------
  // Browse by category — 2-col grid of category tiles (label + count).
  // -------------------------------------------------------------------------

  Widget _buildBrowseByCategory() {
    final counts = ref.watch(programCategoryCountsProvider);
    return counts.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (cats) {
        if (cats.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 11),
              child: ZHairlineRow(
                title: Text(
                  'BROWSE BY CATEGORY',
                  style: ZType.lbl(13,
                      color: AppColors.textPrimary, letterSpacing: 1.8),
                ),
                showDivider: false,
                verticalPadding: 0,
                trailing: const SizedBox.shrink(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  mainAxisExtent: 100,
                ),
                itemCount: cats.length,
                itemBuilder: (context, i) {
                  final cat = cats[i];
                  return _CategoryHubTile(
                    category: cat.category,
                    count: cat.count,
                    onTap: () {
                      HapticService.selection();
                      setState(() => _category = cat.category);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  // -------------------------------------------------------------------------
  // Filtered surface — the real result list when a filter/search is active.
  // -------------------------------------------------------------------------

  Widget _buildFilteredSurface() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              Expanded(child: _buildSearchPill()),
              const SizedBox(width: 10),
              _buildFilterButton(),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _buildActiveFilterStrip(),
        Expanded(child: _buildBrowseGrid()),
      ],
    );
  }

  /// A row showing active facets + a one-tap "CLEAR" affordance.
  Widget _buildActiveFilterStrip() {
    final chips = <Widget>[];
    if (_category != null) chips.add(_activeChip(_category!));
    if (_difficulty != null) {
      chips.add(_activeChip(_difficulty!,
          dot: programDifficultyColor(_difficulty)));
    }
    if (_sessionsPerWeek != null) {
      chips.add(_activeChip('$_sessionsPerWeek×/WK'));
    }
    if (_durationMin != null || _durationMax != null) {
      chips.add(_activeChip(_durationLabel()));
    }
    for (final g in _goals) {
      chips.add(_activeChip(g));
    }
    if (_search.isNotEmpty) chips.add(_activeChip('"$_search"'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final c in chips) ...[
                    c,
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
          ),
          GestureDetector(
            onTap: _clearFilters,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(left: 4),
              child: Text(
                AppLocalizations.of(context).programsClearFilters,
                style: ZType.lbl(11,
                    color: AppColors.textMuted, letterSpacing: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeChip(String label, {Color? dot}) {
    return ZChip(label: label, selected: true, leadingDot: dot);
  }

  String _durationLabel() {
    final min = _durationMin;
    final max = _durationMax;
    if (min == null && max != null) return '≤$max WK';
    if (min != null && max == null) return '$min+ WK';
    if (min != null && max != null) return '$min–$max WK';
    return 'ANY WK';
  }

  Widget _buildBrowseGrid() {
    final async = ref.watch(programLibraryBrowseProvider(_filter));
    return async.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: _buildSkeletonGrid,
      error: (e, _) => _ErrorState(
        message: 'We could not load the program library.',
        onRetry: _refresh,
      ),
      data: (result) {
        if (result.programs.isEmpty) {
          return _EmptyState(
            hasFilters: true,
            onClear: _clearFilters,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
          gridDelegate: _gridDelegate(),
          itemCount: result.programs.length,
          itemBuilder: (context, i) {
            final p = result.programs[i];
            return ProgramLibraryCardTile(
              data: p,
              onTap: () => _openPreview(p),
            );
          },
        );
      },
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
      gridDelegate: _gridDelegate(),
      itemCount: 6,
      itemBuilder: (_, __) => const ProgramLibraryCardSkeleton(),
    );
  }

  SliverGridDelegate _gridDelegate() {
    return const SliverGridDelegateWithMaxCrossAxisExtent(
      maxCrossAxisExtent: 280,
      mainAxisExtent: 196,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
  }

  // -------------------------------------------------------------------------
  // Filter bottom sheet.
  // -------------------------------------------------------------------------

  void _openFilterSheet() {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        child: _ProgramFilterSheet(
          category: _category,
          difficulty: _difficulty,
          sessionsPerWeek: _sessionsPerWeek,
          goals: _goals,
          durationMin: _durationMin,
          durationMax: _durationMax,
          onApply: ({
            required String? category,
            required String? difficulty,
            required int? sessionsPerWeek,
            required Set<String> goals,
            required int? durationMin,
            required int? durationMax,
          }) {
            setState(() {
              _category = category;
              _difficulty = difficulty;
              _sessionsPerWeek = sessionsPerWeek;
              _goals
                ..clear()
                ..addAll(goals);
              _durationMin = durationMin;
              _durationMax = durationMax;
            });
          },
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Preview sheet + start flow — PRESERVED from the prior implementation.
  // -------------------------------------------------------------------------

  void _openPreview(ProgramLibraryCard card) {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(child: _ProgramPreviewSheet(card: card)),
    );
  }

  /// Hero "START PROGRAM" → open the same preview sheet auto-starting the
  /// import (so the import → schedule path is identical to "Import & customize"
  /// in the preview sheet). The sheet kicks off the import on open.
  void _startProgram(ProgramLibraryCard card) {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) =>
          GlassSheet(child: _ProgramPreviewSheet(card: card, autoImport: true)),
    );
  }
}

// ===========================================================================
// Rail — a horizontal ListView of ZPosterCards backed by one browse filter.
// ===========================================================================

class _Rail extends ConsumerWidget {
  final String title;
  final ProgramLibraryFilter filter;
  final VoidCallback? onSeeAll;
  final void Function(ProgramLibraryCard) onTapCard;

  /// Optional client-side transform on the fetched programs (e.g. cap to short
  /// sessions for the QUICK rail). Receives the server list, returns the list
  /// to render. Never substitutes mock data — only filters/reorders real rows.
  final List<ProgramLibraryCard> Function(List<ProgramLibraryCard>)? transform;

  const _Rail({
    required this.title,
    required this.filter,
    required this.onTapCard,
    this.onSeeAll,
    this.transform,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(programLibraryBrowseProvider(filter));
    return async.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => _scaffold(const _RailSkeleton()),
      // A single rail failing shouldn't blank the whole discovery screen —
      // it quietly collapses (the other rails + categories still render).
      error: (_, __) => const SizedBox.shrink(),
      data: (result) {
        var programs = result.programs;
        if (transform != null) programs = transform!(programs);
        if (programs.isEmpty) return const SizedBox.shrink();
        return _scaffold(
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              itemCount: programs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 11),
              itemBuilder: (context, i) {
                final p = programs[i];
                return ZPosterCard(
                  name: p.programName,
                  category: p.programCategory,
                  difficultyLevel: p.difficultyLevel,
                  stat: _posterStat(p),
                  onTap: () => onTapCard(p),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _scaffold(Widget body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
            child: ZSectionKicker(label: title, onSeeAll: onSeeAll),
          ),
          body,
        ],
      ),
    );
  }

  String _posterStat(ProgramLibraryCard p) {
    final parts = <String>[];
    if (p.durationWeeks != null) parts.add('${p.durationWeeks} WK');
    if (p.sessionsPerWeek != null) parts.add('${p.sessionsPerWeek}×/WK');
    return parts.join(' · ');
  }
}

class _RailSkeleton extends StatelessWidget {
  const _RailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 11),
        itemBuilder: (_, __) => Container(
          width: 118,
          height: 154,
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder),
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Category hub tile — used in the "Browse by category" grid.
// ===========================================================================

class _CategoryHubTile extends StatelessWidget {
  final String category;
  final int count;
  final VoidCallback onTap;

  const _CategoryHubTile({
    required this.category,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = categoryTheme(category);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        padding: const EdgeInsets.all(13),
        child: Stack(
          children: [
            // Big faint glyph bottom-right.
            Positioned(
              right: -10,
              bottom: -12,
              child: Icon(
                theme.icon,
                size: 58,
                color: AppColors.textMuted.withValues(alpha: 0.14),
              ),
            ),
            // Count, top-right.
            Positioned(
              top: 0,
              right: 0,
              child: Text(
                '$count',
                style: ZType.data(11, color: AppColors.textSecondary),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  alignment: Alignment.center,
                  child: Icon(theme.icon, size: 17, color: AppColors.orange),
                ),
                Text(
                  category.toUpperCase(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(12.5,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w800,
                      letterSpacing: 0.6),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Shimmer box — tiny skeleton helper.
// ===========================================================================

class _ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  const _ShimmerBox({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
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

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: ZType.sans(14,
                  color: AppColors.textSecondary, weight: FontWeight.w500),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.orange,
                side: const BorderSide(color: AppColors.orange),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(AppLocalizations.of(context).buttonRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  final VoidCallback onClear;

  const _EmptyState({required this.hasFilters, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 44, color: AppColors.textSecondary),
            const SizedBox(height: 12),
            Text(
              hasFilters
                  ? AppLocalizations.of(context)
                      .programLibraryNoProgramsMatchThese
                  : 'No programs available right now.',
              textAlign: TextAlign.center,
              style: ZType.sans(14,
                  color: AppColors.textSecondary, weight: FontWeight.w500),
            ),
            if (hasFilters) ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.orange,
                  side: const BorderSide(color: AppColors.orange),
                ),
                child: Text(
                    AppLocalizations.of(context).programsClearFilters),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Programs filter bottom sheet — Category / Level / Sessions / Duration / Goal.
// ===========================================================================

typedef _ApplyFilter = void Function({
  required String? category,
  required String? difficulty,
  required int? sessionsPerWeek,
  required Set<String> goals,
  required int? durationMin,
  required int? durationMax,
});

class _ProgramFilterSheet extends StatefulWidget {
  final String? category;
  final String? difficulty;
  final int? sessionsPerWeek;
  final Set<String> goals;
  final int? durationMin;
  final int? durationMax;
  final _ApplyFilter onApply;

  const _ProgramFilterSheet({
    required this.category,
    required this.difficulty,
    required this.sessionsPerWeek,
    required this.goals,
    required this.durationMin,
    required this.durationMax,
    required this.onApply,
  });

  @override
  State<_ProgramFilterSheet> createState() => _ProgramFilterSheetState();
}

class _ProgramFilterSheetState extends State<_ProgramFilterSheet> {
  late String? _category = widget.category;
  late String? _difficulty = widget.difficulty;
  late int? _sessionsPerWeek = widget.sessionsPerWeek;
  late final Set<String> _goals = {...widget.goals};
  late int? _durationMin = widget.durationMin;
  late int? _durationMax = widget.durationMax;

  bool _durationSelected(({String label, int? min, int? max}) b) =>
      _durationMin == b.min && _durationMax == b.max;

  void _reset() {
    setState(() {
      _category = null;
      _difficulty = null;
      _sessionsPerWeek = null;
      _goals.clear();
      _durationMin = null;
      _durationMax = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('FILTER',
                        style: ZType.disp(28, color: AppColors.textPrimary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: _reset,
                      behavior: HitTestBehavior.opaque,
                      child: Text(
                        'RESET',
                        style: ZType.lbl(11,
                            color: AppColors.textMuted, letterSpacing: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  children: [
                    _section(
                      'CATEGORY',
                      [
                        for (final c in _kCategories)
                          ZChip(
                            label: c ??
                                AppLocalizations.of(context)
                                    .syncedWorkoutsHistoryAll,
                            selected: _category == c,
                            onTap: () {
                              HapticService.selection();
                              setState(() =>
                                  _category = _category == c ? null : c);
                            },
                          ),
                      ],
                    ),
                    _section(
                      AppLocalizations.of(context).programSummaryLevel,
                      [
                        for (final d in _kDifficulties)
                          ZChip(
                            label: d ??
                                AppLocalizations.of(context).programLibraryAny,
                            selected: _difficulty == d,
                            leadingDot: d == null
                                ? null
                                : programDifficultyColor(d),
                            onTap: () {
                              HapticService.selection();
                              setState(() =>
                                  _difficulty = _difficulty == d ? null : d);
                            },
                          ),
                      ],
                    ),
                    _section(
                      'SESSIONS / WEEK',
                      [
                        for (final s in _kSessions)
                          ZChip(
                            label: s == null
                                ? AppLocalizations.of(context)
                                    .programLibraryAny
                                : '$s',
                            selected: _sessionsPerWeek == s,
                            onTap: () {
                              HapticService.selection();
                              setState(() => _sessionsPerWeek =
                                  _sessionsPerWeek == s ? null : s);
                            },
                          ),
                      ],
                    ),
                    _section(
                      'DURATION',
                      [
                        for (final b in _kDurationBuckets)
                          ZChip(
                            label: b.min == null && b.max == null
                                ? AppLocalizations.of(context)
                                    .programLibraryAny
                                : b.label,
                            selected: _durationSelected(b),
                            onTap: () {
                              HapticService.selection();
                              setState(() {
                                _durationMin = b.min;
                                _durationMax = b.max;
                              });
                            },
                          ),
                      ],
                    ),
                    _section(
                      'GOAL',
                      [
                        for (final g in _kGoals)
                          ZChip(
                            label: g,
                            selected: _goals.contains(g),
                            onTap: () {
                              HapticService.selection();
                              setState(() {
                                if (_goals.contains(g)) {
                                  _goals.remove(g);
                                } else {
                                  _goals.add(g);
                                }
                              });
                            },
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        widget.onApply(
                          category: _category,
                          difficulty: _difficulty,
                          sessionsPerWeek: _sessionsPerWeek,
                          goals: _goals,
                          durationMin: _durationMin,
                          durationMax: _durationMax,
                        );
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'APPLY',
                        style: ZType.lbl(14,
                            color: Colors.white,
                            weight: FontWeight.w800,
                            letterSpacing: 2.5),
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

  Widget _section(String key, List<Widget> chips) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 11),
            child: Text(
              key.toUpperCase(),
              style: ZType.lbl(11,
                  color: AppColors.textMuted, letterSpacing: 2.2),
            ),
          ),
          Wrap(spacing: 8, runSpacing: 8, children: chips),
        ],
      ),
    );
  }
}

// ===========================================================================
// Preview sheet — full structured preview + "Import & customize".
// PRESERVED behavior: previewLibraryProgram → importFromProgram → builder.
// ===========================================================================

class _ProgramPreviewSheet extends ConsumerStatefulWidget {
  final ProgramLibraryCard card;

  /// When true, kick off the import as soon as the sheet opens (used by the
  /// hero "START PROGRAM" button). The import → builder path is identical to
  /// tapping "Import & customize".
  final bool autoImport;

  const _ProgramPreviewSheet({required this.card, this.autoImport = false});

  @override
  ConsumerState<_ProgramPreviewSheet> createState() =>
      _ProgramPreviewSheetState();
}

class _ProgramPreviewSheetState extends ConsumerState<_ProgramPreviewSheet> {
  Future<ProgramTemplate>? _preview;
  bool _importing = false;
  bool _autoImportFired = false;

  /// True when this is a branded card the backend told us has no normalizable
  /// day structure — we skip the structured-preview fetch entirely and render
  /// the card-level info + a "preview not available" note instead.
  bool get _previewUnavailable =>
      widget.card.isBranded && !widget.card.previewAvailable;

  @override
  void initState() {
    super.initState();
    // Both `library` and `branded` (when previewable) resolve through the same
    // `GET /library/{id}` preview route. Only skip the fetch when the backend
    // already told us no normalized preview exists for this branded program.
    if (!_previewUnavailable) {
      _preview = ref
          .read(programTemplateRepositoryProvider)
          .previewLibraryProgram(widget.card.id);
    }
    if (widget.autoImport) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _autoImportFired) return;
        _autoImportFired = true;
        _import();
      });
    }
  }

  /// START / Import.
  ///
  /// - `library`: clone → editable template → builder (unchanged).
  /// - `branded`: try the same import → builder; if the backend 422s with
  ///   `branded_import_unsupported` (no normalizable structure), fall back to
  ///   the BRANDED ASSIGN flow (assign the bare uuid as the user's current
  ///   program), then confirm + pop.
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
      // A branded program with no normalizable structure can't go through the
      // template builder — fall back to the branded ASSIGN flow.
      if (widget.card.isBranded && e.code == 'branded_import_unsupported') {
        await _assignBranded();
        return;
      }
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).programLibraryCouldNotImportThis)),
      );
    }
  }

  /// Branded ASSIGN fallback — set this branded program as the user's current
  /// program (mirrors the existing branded assign UX: confirm via snackbar +
  /// pop the sheet). Uses the bare uuid (without the `branded:` prefix).
  Future<void> _assignBranded() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final userId = ref.read(authStateProvider).user?.id;
    if (userId == null) {
      if (!mounted) return;
      setState(() => _importing = false);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).programLibraryCouldNotImportThis)),
      );
      return;
    }
    final ok = await ref.read(currentProgramProvider.notifier).assignProgram(
          programId: widget.card.bareBrandedId,
          userId: userId,
        );
    if (!mounted) return;
    if (ok) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text('${widget.card.programName} started')),
      );
    } else {
      setState(() => _importing = false);
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).programLibraryCouldNotImportThis)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: _previewUnavailable
                    ? _buildCardLevelInfo()
                    : FutureBuilder<ProgramTemplate>(
                  future: _preview,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.orange),
                      );
                    }
                    if (snapshot.hasError) {
                      return _ErrorState(
                        message: 'Could not load this program preview.',
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
                          template.name.toUpperCase(),
                          style: ZType.disp(24, color: AppColors.textPrimary),
                        ),
                        if ((template.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            template.description!.trim(),
                            style: ZType.ser(13,
                                color: AppColors.textSecondary),
                          ),
                        ],
                        const SizedBox(height: 16),
                        _previewStatsRow(template),
                        const SizedBox(height: 16),
                        for (final day in template.days) _DayPreviewTile(day: day),
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
                        backgroundColor: AppColors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _importing ? null : _import,
                      icon: _importing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              _previewUnavailable
                                  ? Icons.play_arrow_rounded
                                  : Icons.tune_rounded,
                              size: 18),
                      label: Text(
                        _importing
                            ? AppLocalizations.of(context)
                                .programLibraryImporting
                            : (_previewUnavailable
                                ? 'START PROGRAM'
                                : AppLocalizations.of(context)
                                    .programLibraryImportCustomize),
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

  Widget _previewStatsRow(ProgramTemplate template) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _miniStat(
            Icons.event_rounded, '${template.weekLength}-day cycle'),
        _miniStat(Icons.fitness_center_rounded,
            '${template.trainingDayCount} training days'),
        _miniStat(
            Icons.list_alt_rounded, '${template.totalExercises} exercises'),
      ],
    );
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: ZType.data(11, color: AppColors.textMuted)),
      ],
    );
  }

  /// Branded card with no normalizable day breakdown — render the card-level
  /// info we already have plus an honest "preview not available" note. The
  /// user can still START it (it assigns through the branded flow).
  Widget _buildCardLevelInfo() {
    final card = widget.card;
    final stats = <Widget>[];
    if (card.durationWeeks != null) {
      stats.add(_miniStat(Icons.event_rounded, '${card.durationWeeks} weeks'));
    }
    if (card.sessionsPerWeek != null) {
      stats.add(_miniStat(
          Icons.fitness_center_rounded, '${card.sessionsPerWeek}×/week'));
    }
    if (card.difficultyLevel != null &&
        card.difficultyLevel!.trim().isNotEmpty) {
      stats.add(_miniStat(
          Icons.signal_cellular_alt_rounded, card.difficultyLevel!));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Text(
          card.programName.toUpperCase(),
          style: ZType.disp(24, color: AppColors.textPrimary),
        ),
        if ((card.description ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            card.description!.trim(),
            style: ZType.ser(13, color: AppColors.textSecondary),
          ),
        ],
        if (stats.isNotEmpty) ...[
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: stats),
        ],
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Preview not available — you can still start it.',
                  style: ZType.sans(13,
                      color: AppColors.textSecondary,
                      weight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One day row inside the preview sheet.
class _DayPreviewTile extends StatelessWidget {
  final ProgramDay day;

  const _DayPreviewTile({required this.day});

  @override
  Widget build(BuildContext context) {
    if (day.effectivelyRest) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.bedtime_outlined,
                size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              AppLocalizations.of(context)
                  .programLibraryScreenRest(day.dayName),
              style: ZType.sans(13,
                  color: AppColors.textSecondary, weight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName.toUpperCase(),
            style: ZType.lbl(13,
                color: AppColors.textPrimary, letterSpacing: 1.2),
          ),
          const SizedBox(height: 8),
          for (final ex in day.exercises)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      ex.name,
                      style: ZType.sans(13,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    AppLocalizations.of(context)
                        .programLibraryScreenValue(ex.sets, ex.repsLabel()),
                    style: ZType.data(11, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
