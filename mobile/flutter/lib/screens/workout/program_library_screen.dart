import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../widgets/glass_sheet.dart';
import '../../widgets/signature/signature.dart';
import '../../data/models/program_template.dart';
import '../../data/models/user_program_assignment.dart';
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
  /// Optional deep-link target — when set, the screen opens straight to that
  /// program's rich PREVIEW detail sheet on first build (used by the coach's
  /// "View program" chat card via `/workout/program-library?programId=<id>`).
  final String? initialProgramId;

  const ProgramLibraryScreen({super.key, this.initialProgramId});

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

  /// Guards the one-shot deep-link auto-open so it fires only once.
  bool _deepLinkOpened = false;

  @override
  void initState() {
    super.initState();
    // Deep-link: open straight to a program's PREVIEW detail sheet.
    final id = widget.initialProgramId?.trim();
    if (id != null && id.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _deepLinkOpened) return;
        _deepLinkOpened = true;
        _openPreviewById(id);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _heroController.dispose();
    super.dispose();
  }

  /// Resolve a program id to a card and open its PREVIEW sheet. The structured
  /// detail (name/description/category/duration) is fetched from the preview
  /// route; editorial card fields aren't in that payload, so the sheet renders
  /// from the resolved name/description. On failure, a transient toast — the
  /// browse surface stays usable (never a dead-end).
  Future<void> _openPreviewById(String id) async {
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final template = await repo.previewLibraryProgram(id);
      if (!mounted) return;
      final card = ProgramLibraryCard(
        id: id,
        programName: template.name,
        description: template.description,
        programCategory: template.category,
        durationWeeks: template.durationWeeks,
        // The id may be branded — preserve the source so the sheet picks the
        // right Start path.
        source: id.startsWith('branded:') ? 'branded' : 'library',
      );
      _openPreview(card);
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not open that program. Browse the library '
                'to find it.')),
      );
    }
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
    // When a filter/search is active the screen is showing a drilled-in result
    // surface; the back affordance (header ‹ AND the system back gesture)
    // should return to discovery by clearing filters rather than popping the
    // whole route and ejecting the user back to the workout tab.
    return PopScope(
      canPop: !_hasActiveFilter,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _hasActiveFilter) {
          HapticService.light();
          _clearFilters();
        }
      },
      child: Scaffold(
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
      ),
    );
  }

  /// Filter-aware back: when a filter/search is active, back returns to the
  /// discovery surface (clears filters); otherwise it pops the route.
  void _handleBack() {
    HapticService.light();
    if (_hasActiveFilter) {
      _clearFilters();
    } else if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  /// Back ‹ + Anton masthead over a hairline rule. The masthead reads
  /// "PROGRAMS" in discovery and "RESULTS" when filtered, so the drilled-in
  /// state is legible and back ‹ obviously steps back to the browse surface.
  Widget _buildHeader(BuildContext context) {
    final filtered = _hasActiveFilter;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(bottom: BorderSide(color: AppColors.hairlineStrong)),
      ),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _handleBack,
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
          Expanded(
            child: Text(
              filtered
                  ? 'RESULTS'
                  : AppLocalizations.of(context).programLibraryProgramLibrary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: ZType.disp(30, color: AppColors.textPrimary),
            ),
          ),
          // Add + AI creation entry points (point #8).
          _HeaderActionButton(
            icon: Icons.add_rounded,
            tooltip: 'Build from scratch',
            onTap: _openBuildFromScratch,
          ),
          const SizedBox(width: 8),
          _HeaderActionButton(
            icon: Icons.auto_awesome_rounded,
            tooltip: 'Create with AI',
            accent: true,
            onTap: _openAiCreateSheet,
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
                  title: p.displayName,
                  description: p.tagline?.trim().isNotEmpty == true
                      ? p.tagline
                      : p.description,
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
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  mainAxisExtent: 104,
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
    // 3-up grid (point #1). The card already uses mainAxisSize.min + a single-
    // line description, so it renders cleanly in the narrower cell. The taller
    // mainAxisExtent leaves room for the eyebrow + 2-line title + 1-line
    // description + a (now wrapping) chip row on an iPhone SE width.
    return const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 3,
      mainAxisExtent: 188,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
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
  // Preview sheet + Start flow + creation entry points.
  // -------------------------------------------------------------------------

  /// PREVIEW (card tap / hero ghost) → rich READ-ONLY detail sheet with a
  /// persistent "Start program" button at the bottom.
  void _openPreview(ProgramLibraryCard card) {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      // GlassSheet draws the single drag handle; the inner sheet draws none
      // (avoids the double-handle bug). Same pattern as the filter sheet.
      builder: (_) => GlassSheet(
        child: _ProgramPreviewSheet(
          card: card,
          onStart: () => _openStartFlow(card),
          onCustomize: () => _openCustomizeBuilder(card),
        ),
      ),
    );
  }

  /// START PROGRAM (hero primary) → go straight to the Start flow sheet
  /// (start date + weekdays + slot + replace/alongside + AI tailor).
  void _startProgram(ProgramLibraryCard card) => _openStartFlow(card);

  /// The unified Start flow — pick start date / training weekdays / slot, then
  /// `POST /assign`. Replaces the old "auto-import into the builder" path for
  /// the primary CTA (the builder is now the explicit "Customize" route).
  void _openStartFlow(ProgramLibraryCard card) {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => GlassSheet(
        child: _StartProgramFlowSheet(card: card),
      ),
    );
  }

  /// "Customize" from the preview → import the program into an editable
  /// template and open the builder (the prior "Import & customize" behavior).
  Future<void> _openCustomizeBuilder(ProgramLibraryCard card) async {
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final navigator = Navigator.of(context);
    try {
      final template = await repo.importFromProgram(card.id);
      if (!mounted) return;
      // Close the preview sheet, then open the builder pre-filled.
      navigator.pop();
      router.push(ProgramBuilderRoute.path, extra: template);
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context).programLibraryCouldNotImportThis)),
      );
    }
  }

  /// Add (＋) → builder "build from scratch".
  void _openBuildFromScratch() {
    HapticService.light();
    context.push(ProgramBuilderRoute.path);
  }

  /// AI (✨) → the three-entry creation sheet (prompt / photo·PDF / coach).
  void _openAiCreateSheet() {
    HapticService.light();
    showGlassSheet<void>(
      context: context,
      builder: (_) => const GlassSheet(child: _AiCreateSheet()),
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
                  name: p.displayName,
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
              // No inner drag handle — the GlassSheet wrapper already draws one
              // (was double-stacked). Keep the GlassSheet handle as the single
              // grabber for visual consistency with every other app sheet.
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
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
// Preview sheet — rich READ-ONLY program detail (point #3 PREVIEW).
//
// Editorial name + tagline, who-for / who-not-for, equipment, a plain-English
// progression note, and a "Sample week" expandable (the day-by-day from the
// preview payload). A persistent "Start program" button sits at the bottom and
// hands off to the Start flow; a quieter "Customize in builder" link imports
// the program into an editable template. No data is mutated here.
// ===========================================================================

class _ProgramPreviewSheet extends ConsumerStatefulWidget {
  final ProgramLibraryCard card;

  /// Opens the Start flow (start date + weekdays + slot). Wired by the screen.
  final VoidCallback onStart;

  /// Imports the program into an editable template and opens the builder.
  final VoidCallback onCustomize;

  const _ProgramPreviewSheet({
    required this.card,
    required this.onStart,
    required this.onCustomize,
  });

  @override
  ConsumerState<_ProgramPreviewSheet> createState() =>
      _ProgramPreviewSheetState();
}

class _ProgramPreviewSheetState extends ConsumerState<_ProgramPreviewSheet> {
  Future<ProgramTemplate>? _preview;
  bool _sampleWeekOpen = false;

  /// True when this is a branded card the backend told us has no normalizable
  /// day structure — we skip the structured-preview fetch entirely.
  bool get _previewUnavailable =>
      widget.card.isBranded && !widget.card.previewAvailable;

  @override
  void initState() {
    super.initState();
    if (!_previewUnavailable) {
      _preview = ref
          .read(programTemplateRepositoryProvider)
          .previewLibraryProgram(widget.card.id);
    }
  }

  void _retryPreview() {
    setState(() {
      _preview = ref
          .read(programTemplateRepositoryProvider)
          .previewLibraryProgram(widget.card.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    // Eyebrow — category / celebrity.
                    Text(
                      ((card.celebrityName ?? '').trim().isNotEmpty
                              ? card.celebrityName!
                              : (card.programCategory ?? 'PROGRAM'))
                          .toUpperCase(),
                      style: ZType.lbl(11,
                          color: AppColors.orange, letterSpacing: 2.0),
                    ),
                    const SizedBox(height: 6),
                    // Editorial display name.
                    Text(
                      card.displayName.toUpperCase(),
                      style: ZType.disp(26, color: AppColors.textPrimary),
                    ),
                    // Tagline (editorial) → description fallback.
                    if ((card.tagline ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        card.tagline!.trim(),
                        style:
                            ZType.ser(14, color: AppColors.textSecondary),
                      ),
                    ] else if ((card.description ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        card.description!.trim(),
                        style:
                            ZType.ser(13, color: AppColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 16),
                    _cardStatsRow(card),

                    // Who-for / who-not-for.
                    if ((card.whoFor ?? '').trim().isNotEmpty)
                      _PreviewNote(
                        icon: Icons.check_circle_outline_rounded,
                        tint: const Color(0xFF2ECC71),
                        label: 'WHO IT IS FOR',
                        body: card.whoFor!.trim(),
                      ),
                    if ((card.whoNotFor ?? '').trim().isNotEmpty)
                      _PreviewNote(
                        icon: Icons.do_not_disturb_on_outlined,
                        tint: const Color(0xFFEF4444),
                        label: 'WHO IT IS NOT FOR',
                        body: card.whoNotFor!.trim(),
                      ),
                    if ((card.equipmentSummary ?? '').trim().isNotEmpty)
                      _PreviewNote(
                        icon: Icons.fitness_center_rounded,
                        tint: AppColors.orange,
                        label: 'EQUIPMENT',
                        body: card.equipmentSummary!.trim(),
                      ),
                    if ((card.progressionNote ?? '').trim().isNotEmpty)
                      _PreviewNote(
                        icon: Icons.trending_up_rounded,
                        tint: const Color(0xFF38BDF8),
                        label: 'HOW IT PROGRESSES',
                        body: card.progressionNote!.trim(),
                      ),

                    const SizedBox(height: 8),
                    _buildSampleWeek(),
                  ],
                ),
              ),
              _buildBottomBar(),
            ],
          ),
        );
      },
    );
  }

  /// A few mini-stats from the card-level data (no fetch required).
  Widget _cardStatsRow(ProgramLibraryCard card) {
    final stats = <Widget>[];
    if (card.difficultyLevel != null &&
        card.difficultyLevel!.trim().isNotEmpty) {
      stats.add(_miniStat(
          Icons.bolt_rounded, card.difficultyLevel!.trim()));
    }
    if (card.durationWeeks != null && card.durationWeeks! > 0) {
      stats.add(_miniStat(Icons.event_rounded, '${card.durationWeeks} weeks'));
    }
    if (card.sessionsPerWeek != null && card.sessionsPerWeek! > 0) {
      stats.add(_miniStat(
          Icons.repeat_rounded, '${card.sessionsPerWeek}×/week'));
    }
    if (card.sessionDurationMinutes != null &&
        card.sessionDurationMinutes! > 0) {
      stats.add(_miniStat(
          Icons.timer_outlined, '${card.sessionDurationMinutes} min'));
    }
    if (stats.isEmpty) return const SizedBox.shrink();
    return Wrap(spacing: 10, runSpacing: 8, children: stats);
  }

  Widget _miniStat(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label, style: ZType.data(11, color: AppColors.textMuted)),
      ],
    );
  }

  /// "Sample week" expandable — the day-by-day from the structured preview.
  Widget _buildSampleWeek() {
    if (_previewUnavailable) {
      return Container(
        margin: const EdgeInsets.only(top: 8),
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
                'A day-by-day preview is not available for this program — you '
                'can still start it.',
                style: ZType.sans(13,
                    color: AppColors.textSecondary, weight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: () {
            HapticService.selection();
            setState(() => _sampleWeekOpen = !_sampleWeekOpen);
          },
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Text(
                  'SAMPLE WEEK',
                  style: ZType.lbl(13,
                      color: AppColors.textPrimary, letterSpacing: 1.8),
                ),
                const Spacer(),
                Icon(
                  _sampleWeekOpen
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (_sampleWeekOpen)
          FutureBuilder<ProgramTemplate>(
            future: _preview,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  ),
                );
              }
              if (snapshot.hasError) {
                return _ErrorState(
                  message: 'Could not load the sample week.',
                  onRetry: _retryPreview,
                );
              }
              final template = snapshot.data!;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        _miniStat(Icons.event_rounded,
                            '${template.weekLength}-day cycle'),
                        _miniStat(Icons.fitness_center_rounded,
                            '${template.trainingDayCount} training days'),
                        _miniStat(Icons.list_alt_rounded,
                            '${template.totalExercises} exercises'),
                      ],
                    ),
                  ),
                  for (final day in template.days) _DayPreviewTile(day: day),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onStart();
                },
                icon: const Icon(Icons.play_arrow_rounded, size: 20),
                label: Text(
                  'START PROGRAM',
                  style: ZType.lbl(14,
                      color: Colors.white,
                      weight: FontWeight.w800,
                      letterSpacing: 2.0),
                ),
              ),
            ),
            // Customize is only meaningful for importable (non-branded-only)
            // programs — the builder needs a normalizable structure.
            if (!_previewUnavailable) ...[
              const SizedBox(height: 6),
              TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onCustomize();
                },
                icon: const Icon(Icons.tune_rounded,
                    size: 16, color: AppColors.textSecondary),
                label: Text(
                  'Customize in builder',
                  style: ZType.sans(13,
                      color: AppColors.textSecondary, weight: FontWeight.w600),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A labeled note block (who-for / equipment / progression) in the preview.
class _PreviewNote extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String body;

  const _PreviewNote({
    required this.icon,
    required this.tint,
    required this.label,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 16, color: tint),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: ZType.lbl(10.5,
                      color: AppColors.textMuted, letterSpacing: 1.6),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: ZType.sans(13.5,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w500,
                      height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
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

// ===========================================================================
// Header action button — the Add (＋) and AI (✨) circular glyph buttons.
// ===========================================================================

class _HeaderActionButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  /// When true the button gets the orange accent fill (used for the AI button).
  final bool accent;

  const _HeaderActionButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.accent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent
                ? AppColors.orange.withValues(alpha: 0.16)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: accent ? AppColors.orange : AppColors.cardBorder,
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: accent ? AppColors.orange : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ===========================================================================
// Start flow sheet — start date + training weekdays + slot (Primary/Add-on),
// Replace vs Run-alongside (Primary), and an optional AI-tailor toggle, then
// POST /assign. On success: pop + success toast (point #3 START PROGRAM).
// ===========================================================================

/// Weekday labels, index 0=Mon..6=Sun (matches the assigned_days contract).
const List<String> _kWeekdayLabels = [
  'MON',
  'TUE',
  'WED',
  'THU',
  'FRI',
  'SAT',
  'SUN',
];

class _StartProgramFlowSheet extends ConsumerStatefulWidget {
  final ProgramLibraryCard card;

  const _StartProgramFlowSheet({required this.card});

  @override
  ConsumerState<_StartProgramFlowSheet> createState() =>
      _StartProgramFlowSheetState();
}

class _StartProgramFlowSheetState
    extends ConsumerState<_StartProgramFlowSheet> {
  late DateTime _startDate;
  final Set<int> _days = <int>{};
  ProgramSlot _slot = ProgramSlot.primary;

  /// Primary only: replace the current primary vs run alongside it. Defaults to
  /// run-alongside (false) per the spec.
  bool _replace = false;

  // AI-tailor toggle + its sub-options (only meaningful when on).
  bool _aiTailor = false;
  bool _adaptToLevel = true;
  bool _swapForInjuries = true;
  bool _fitEquipment = true;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    // Seed sensible default training days from the program's sessions/week.
    final n = widget.card.sessionsPerWeek;
    if (n != null && n > 0) {
      // Spread n sessions across the week (e.g. 3 → Mon/Wed/Fri).
      final picks = _spreadDays(n.clamp(1, 7));
      _days.addAll(picks);
    } else {
      _days.addAll(const [0, 2, 4]); // Mon/Wed/Fri default.
    }
  }

  /// Spread [n] sessions roughly evenly across a 7-day week (0=Mon..6=Sun).
  List<int> _spreadDays(int n) {
    if (n >= 7) return List.generate(7, (i) => i);
    final out = <int>{};
    for (var i = 0; i < n; i++) {
      out.add((i * 7 / n).floor().clamp(0, 6));
    }
    // If rounding collapsed two picks, backfill from the front.
    var d = 0;
    while (out.length < n && d < 7) {
      out.add(d);
      d++;
    }
    return out.toList()..sort();
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickStartDate() async {
    HapticService.light();
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.orange,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (_days.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one training day.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final card = widget.card;
    try {
      final result = await repo.assignProgram(
        programId: card.isBranded ? card.bareBrandedId : card.id,
        assignedDays: _days.toList()..sort(),
        slot: _slot,
        startDate: _isoDate(_startDate),
        replace: _slot == ProgramSlot.primary && _replace,
        durationWeeks: card.durationWeeks,
        adaptToLevel: _aiTailor && _adaptToLevel,
        swapForInjuries: _aiTailor && _swapForInjuries,
        fitEquipment: _aiTailor && _fitEquipment,
      );
      if (!mounted) return;
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            result.workoutsCreated > 0
                ? '${card.displayName} started — ${result.workoutsCreated} '
                    'workouts scheduled'
                : '${card.displayName} started',
          ),
        ),
      );
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not start this program. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.82,
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
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: [
                    Text(
                      'START PROGRAM',
                      style: ZType.disp(26, color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.card.displayName,
                      style: ZType.ser(14, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 20),

                    // Start date.
                    _StartFlowLabel('START DATE'),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickStartDate,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: AppColors.surface2,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.event_rounded,
                                size: 18, color: AppColors.orange),
                            const SizedBox(width: 10),
                            Text(
                              _fmtDate(_startDate),
                              style: ZType.sans(14,
                                  color: AppColors.textPrimary,
                                  weight: FontWeight.w600),
                            ),
                            const Spacer(),
                            const Icon(Icons.edit_calendar_rounded,
                                size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Training weekdays.
                    _StartFlowLabel('TRAINING DAYS'),
                    const SizedBox(height: 8),
                    _buildWeekdayPicker(),
                    const SizedBox(height: 20),

                    // Slot — Primary vs Add-on.
                    _StartFlowLabel('SLOT'),
                    const SizedBox(height: 8),
                    _buildSlotPicker(),
                    const SizedBox(height: 8),
                    Text(
                      _slot == ProgramSlot.primary
                          ? 'Primary drives your home workout.'
                          : 'Add-on stacks on top, e.g. a 7-min core finisher.',
                      style: ZType.sans(12.5,
                          color: AppColors.textMuted, weight: FontWeight.w500),
                    ),

                    // Replace vs Run-alongside (Primary only).
                    if (_slot == ProgramSlot.primary) ...[
                      const SizedBox(height: 16),
                      _buildReplaceToggle(),
                    ],

                    const SizedBox(height: 20),

                    // AI tailor.
                    _buildAiTailor(),
                  ],
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
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_rounded, size: 20),
                      label: Text(
                        _submitting ? 'STARTING…' : 'CONFIRM & START',
                        style: ZType.lbl(14,
                            color: Colors.white,
                            weight: FontWeight.w800,
                            letterSpacing: 2.0),
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

  Widget _buildWeekdayPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 7; i++)
          GestureDetector(
            onTap: () {
              HapticService.selection();
              setState(() {
                if (_days.contains(i)) {
                  _days.remove(i);
                } else {
                  _days.add(i);
                }
              });
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              width: 40,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _days.contains(i)
                    ? AppColors.orange
                    : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _days.contains(i)
                      ? AppColors.orange
                      : AppColors.cardBorder,
                ),
              ),
              child: Text(
                _kWeekdayLabels[i],
                style: ZType.lbl(10.5,
                    color: _days.contains(i)
                        ? Colors.white
                        : AppColors.textSecondary,
                    letterSpacing: 0.5),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSlotPicker() {
    return Row(
      children: [
        Expanded(
          child: _SlotChip(
            label: 'PRIMARY',
            icon: Icons.home_rounded,
            selected: _slot == ProgramSlot.primary,
            onTap: () {
              HapticService.selection();
              setState(() => _slot = ProgramSlot.primary);
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SlotChip(
            label: 'ADD-ON',
            icon: Icons.add_circle_outline_rounded,
            selected: _slot == ProgramSlot.addon,
            onTap: () {
              HapticService.selection();
              setState(() => _slot = ProgramSlot.addon);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildReplaceToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SwitchListTile.adaptive(
        contentPadding: EdgeInsets.zero,
        dense: true,
        value: _replace,
        activeThumbColor: AppColors.orange,
        onChanged: (v) => setState(() => _replace = v),
        title: Text(
          'Replace current program',
          style: ZType.sans(13.5,
              color: AppColors.textPrimary, weight: FontWeight.w600),
        ),
        subtitle: Text(
          _replace
              ? 'Your current primary program is replaced.'
              : 'Runs alongside your current program.',
          style: ZType.sans(11.5,
              color: AppColors.textMuted, weight: FontWeight.w500),
        ),
      ),
    );
  }

  Widget _buildAiTailor() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _aiTailor ? AppColors.orange : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            value: _aiTailor,
            activeThumbColor: AppColors.orange,
            onChanged: (v) => setState(() => _aiTailor = v),
            secondary: const Icon(Icons.auto_awesome_rounded,
                size: 18, color: AppColors.orange),
            title: Text(
              'Let AI tailor it to me',
              style: ZType.sans(13.5,
                  color: AppColors.textPrimary, weight: FontWeight.w700),
            ),
            subtitle: Text(
              'Adapt sets/reps to your level, swap for injuries, fit your gear.',
              style: ZType.sans(11.5,
                  color: AppColors.textMuted, weight: FontWeight.w500),
            ),
          ),
          if (_aiTailor) ...[
            const Divider(height: 16, color: AppColors.cardBorder),
            _aiSubToggle(
              'Adapt sets/reps to my level',
              _adaptToLevel,
              (v) => setState(() => _adaptToLevel = v),
            ),
            _aiSubToggle(
              'Swap exercises for my injuries',
              _swapForInjuries,
              (v) => setState(() => _swapForInjuries = v),
            ),
            _aiSubToggle(
              'Fit my available equipment',
              _fitEquipment,
              (v) => setState(() => _fitEquipment = v),
            ),
          ],
        ],
      ),
    );
  }

  Widget _aiSubToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: ZType.sans(12.5,
                color: AppColors.textSecondary, weight: FontWeight.w500),
          ),
        ),
        Checkbox(
          value: value,
          activeColor: AppColors.orange,
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (v) => onChanged(v ?? false),
        ),
      ],
    );
  }
}

class _StartFlowLabel extends StatelessWidget {
  final String text;
  const _StartFlowLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: ZType.lbl(11, color: AppColors.textMuted, letterSpacing: 2.0),
    );
  }
}

class _SlotChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _SlotChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 13),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.orange.withValues(alpha: 0.16)
                          : AppColors.surface2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.orange : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: selected ? AppColors.orange : AppColors.textSecondary),
            const SizedBox(width: 7),
            Text(
              label,
              style: ZType.lbl(12,
                  color: selected ? AppColors.orange : AppColors.textSecondary,
                  letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// AI create sheet — three entries: Generate from a prompt, Import from
// photo/PDF, Ask the Coach (point #8 AI button).
// ===========================================================================

class _AiCreateSheet extends ConsumerStatefulWidget {
  const _AiCreateSheet();

  @override
  ConsumerState<_AiCreateSheet> createState() => _AiCreateSheetState();
}

class _AiCreateSheetState extends ConsumerState<_AiCreateSheet> {
  final TextEditingController _promptController = TextEditingController();
  bool _busy = false;

  /// What we're doing while busy — drives the optimistic skeleton copy.
  String _busyLabel = '';

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  /// Generate from a free-text multi-week prompt → parse → open the draft in
  /// the builder. Optimistic skeleton (per feedback_instant_feel_ai_generation)
  /// — the sheet shows a "drafting your program" skeleton, never a blank
  /// spinner.
  Future<void> _generateFromPrompt() async {
    final text = _promptController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the program you want first.')),
      );
      return;
    }
    setState(() {
      _busy = true;
      _busyLabel = 'Drafting your program…';
    });
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    try {
      final draft = await repo.parseDescription(text);
      if (!mounted) return;
      navigator.pop();
      router.push(ProgramBuilderRoute.path, extra: draft);
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.isNotAProgram
              ? 'That did not read as a program. Try describing a day-by-day '
                  'split, sets and reps.'
              : e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not reach the AI. Check your connection.')),
      );
    }
  }

  /// Import from photo/PDF → import-photo → open the draft in the builder.
  Future<void> _importFromPhoto() async {
    final source = await _pickPhotoOrFile();
    if (source == null || !mounted) return;
    setState(() {
      _busy = true;
      _busyLabel = 'Reading your program…';
    });
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final router = GoRouter.of(context);
    try {
      final draft = await repo.importFromPhoto(
        imageBase64: source.base64,
        mimeType: source.mimeType,
      );
      if (!mounted) return;
      navigator.pop();
      router.push(ProgramBuilderRoute.path, extra: draft);
    } on ProgramParseException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.isNotAProgram
              ? 'That image did not look like a workout program.'
              : e.message),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      messenger.showSnackBar(
        const SnackBar(
            content: Text('Could not read that file. Please try again.')),
      );
    }
  }

  /// Source-pick sheet → returns the chosen file's base64 + mime, or null.
  Future<_PickedSource?> _pickPhotoOrFile() async {
    return showGlassSheet<_PickedSource?>(
      context: context,
      builder: (sheetContext) {
        // Capture the navigator up front so the async tile handlers don't use
        // a BuildContext across an await (image/file pickers are async).
        final navigator = Navigator.of(sheetContext);
        return GlassSheet(
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('IMPORT FROM',
                        style: ZType.lbl(12,
                            color: AppColors.textMuted, letterSpacing: 2.0)),
                  ),
                ),
                _SourceTile(
                  icon: Icons.photo_camera_rounded,
                  label: 'Take a photo',
                  onTap: () async {
                    final r = await _readImage(ImageSource.camera);
                    navigator.pop(r);
                  },
                ),
                _SourceTile(
                  icon: Icons.photo_library_rounded,
                  label: 'Choose from gallery',
                  onTap: () async {
                    final r = await _readImage(ImageSource.gallery);
                    navigator.pop(r);
                  },
                ),
                _SourceTile(
                  icon: Icons.picture_as_pdf_rounded,
                  label: 'Pick a PDF or image file',
                  onTap: () async {
                    final r = await _readFile();
                    navigator.pop(r);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_PickedSource?> _readImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final shot = await picker.pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 88,
      );
      if (shot == null) return null;
      final bytes = await shot.readAsBytes();
      return _PickedSource(
        base64: base64Encode(bytes),
        mimeType: _mimeFromPath(shot.path, fallback: 'image/jpeg'),
      );
    } catch (_) {
      return null;
    }
  }

  Future<_PickedSource?> _readFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'heic', 'webp'],
        withData: true,
      );
      final file = result?.files.firstOrNull;
      if (file == null) return null;
      final bytes = file.bytes ??
          (file.path != null ? await File(file.path!).readAsBytes() : null);
      if (bytes == null) return null;
      return _PickedSource(
        base64: base64Encode(bytes),
        mimeType: _mimeFromPath(file.name, fallback: 'application/pdf'),
      );
    } catch (_) {
      return null;
    }
  }

  String _mimeFromPath(String path, {required String fallback}) {
    final p = path.toLowerCase();
    if (p.endsWith('.png')) return 'image/png';
    if (p.endsWith('.jpg') || p.endsWith('.jpeg')) return 'image/jpeg';
    if (p.endsWith('.heic')) return 'image/heic';
    if (p.endsWith('.webp')) return 'image/webp';
    if (p.endsWith('.pdf')) return 'application/pdf';
    return fallback;
  }

  /// Ask the Coach — deep-link to chat with a program-building seed message.
  void _askTheCoach() {
    final router = GoRouter.of(context);
    Navigator.of(context).pop();
    router.push('/chat', extra: {
      'initialMessage':
          'Help me build a multi-week workout program. Ask me about my goal, '
          'experience, available days, and equipment, then draft a plan.',
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
          ),
          child: _busy
              ? _buildBusySkeleton()
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome_rounded,
                            size: 22, color: AppColors.orange),
                        const SizedBox(width: 8),
                        Text('CREATE WITH AI',
                            style:
                                ZType.disp(24, color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 1) Generate from a prompt.
                    Text('GENERATE FROM A PROMPT',
                        style: ZType.lbl(12,
                            color: AppColors.textMuted, letterSpacing: 1.8)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _promptController,
                      maxLines: 4,
                      minLines: 3,
                      style: ZType.sans(13.5,
                          color: AppColors.textPrimary,
                          weight: FontWeight.w500,
                          height: 1.4),
                      cursorColor: AppColors.orange,
                      decoration: InputDecoration(
                        hintText:
                            'e.g. An 8-week upper/lower split, 4 days a week, '
                            'dumbbells only, focused on building my back.',
                        hintStyle: ZType.sans(12.5,
                            color: AppColors.textMuted,
                            weight: FontWeight.w500,
                            height: 1.4),
                        filled: true,
                        fillColor: AppColors.surface2,
                        contentPadding: const EdgeInsets.all(14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.cardBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.orange),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: _generateFromPrompt,
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text('GENERATE',
                            style: ZType.lbl(13,
                                color: Colors.white,
                                weight: FontWeight.w800,
                                letterSpacing: 1.8)),
                      ),
                    ),

                    const SizedBox(height: 22),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    const SizedBox(height: 18),

                    // 2) Import from photo/PDF.
                    _AiEntryRow(
                      icon: Icons.document_scanner_rounded,
                      title: 'Import from photo or PDF',
                      subtitle:
                          'Snap or upload a written program — we read it into '
                          'an editable plan.',
                      onTap: _importFromPhoto,
                    ),
                    const SizedBox(height: 12),

                    // 3) Ask the Coach.
                    _AiEntryRow(
                      icon: Icons.chat_bubble_outline_rounded,
                      title: 'Ask the Coach',
                      subtitle:
                          'Build a program in a conversation with your AI '
                          'coach.',
                      onTap: _askTheCoach,
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Optimistic skeleton while parsing/importing — never a blank spinner.
  Widget _buildBusySkeleton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.orange),
              ),
              const SizedBox(width: 10),
              Text(_busyLabel,
                  style: ZType.sans(14,
                      color: AppColors.textPrimary, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < 4; i++) ...[
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.cardBorder),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// A picked file reduced to the import-photo contract: base64 + mime type.
class _PickedSource {
  final String base64;
  final String mimeType;
  const _PickedSource({required this.base64, required this.mimeType});
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  const _SourceTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.orange, size: 22),
      title: Text(label,
          style: ZType.sans(14.5,
              color: AppColors.textPrimary, weight: FontWeight.w600)),
      onTap: () => onTap(),
    );
  }
}

class _AiEntryRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AiEntryRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.orange, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: ZType.sans(14.5,
                            color: AppColors.textPrimary,
                            weight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: ZType.sans(12.5,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w500,
                            height: 1.35)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
