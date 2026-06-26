import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/program_template.dart';
import '../../data/providers/program_favorites_provider.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/exercise_image.dart';
import '../../widgets/signature/signature.dart';
import 'exercise_browse.dart';
import 'program_library_screen.dart' show ProgramLibraryStartFlow;

/// Route metadata for the full-screen program detail page (mockup #14).
/// Kept here so callers reference one path constant without a circular import.
class ProgramDetailRoute {
  ProgramDetailRoute._();
  static const String path = '/workout/program-detail';
}

/// Full-screen PROGRAM DETAIL page — the cinematic, signature-v2 replacement
/// for the old bottom-sheet preview (mockup #14).
///
/// The striped header is now a pinned [SliverAppBar] (expandedHeight 280). When
/// fully expanded it shows the gradient / stripes / difficulty pill / Anton
/// title. When the user scrolls, it collapses to a slim app-bar that reserves
/// `MediaQuery.padding.top` + toolbar height, keeping the back button and
/// favorite heart tappable throughout — the tab bar pins BELOW it, never under
/// the Dynamic Island.
///
/// Stat tiles for WEEKS and PER WEEK become selectors when the loaded card
/// exposes `variantOptions.length > 1`, letting the user switch between
/// 4-week / 8-week / 12-week (etc.) variants. Selecting a variant fires a
/// re-fetch of the schedule tab.
///
/// The SCHEDULE tab now shows a week chip-row → selected week's day cards, each
/// exercise row carrying a 40px thumbnail. Tapping an exercise opens the
/// modern read-only exercise detail (browse mode), same as the Exercise Library.
class ProgramDetailScreen extends ConsumerStatefulWidget {
  /// The library card tapped to get here — lets the header paint instantly
  /// while the richer detail (phases / joined_count / sample week) loads.
  final ProgramLibraryCard? card;

  /// Deep-link id when arriving without a card (`?programId=`).
  final String? programId;

  const ProgramDetailScreen({super.key, this.card, this.programId})
      : assert(card != null || programId != null,
            'ProgramDetailScreen needs a card or a programId');

  @override
  ConsumerState<ProgramDetailScreen> createState() =>
      _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  /// The resolved detail (editorial card + sample week). Null until loaded.
  Future<({ProgramLibraryCard card, ProgramTemplate sampleWeek})>? _detail;

  /// The best card we have right now — the tapped card first, upgraded to the
  /// fetched (editorial-complete) card once the detail resolves.
  ProgramLibraryCard? _card;

  /// Optimistic favorite override — null means "defer to the server set"
  /// ([favoriteProgramIdsProvider]); non-null is the in-flight toggle target
  /// shown immediately while the add/remove call + invalidation settle.
  bool? _favoriteOverride;
  bool _favoriteBusy = false;

  /// The currently-selected variant id. Null = program default (or single plan).
  String? _selectedVariantId;

  /// The selected week index (0-based) in the schedule tab. Resets to 0
  /// whenever the variant changes so the user always lands on week 1.
  int _selectedWeekIndex = 0;

  /// Which selector pill row is currently expanded: 'weeks', 'sessions', or
  /// null (both collapsed). Toggled by tapping a selector tile.
  String? _expandedSelector;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _card = widget.card;
    // Seed the variant from whatever the tapped card already knows. Upgraded
    // once the detail fetch resolves with the full editorial card.
    _selectedVariantId = widget.card?.defaultVariantId;
    _load();
  }

  /// Whether the program is favorited, preferring the optimistic override, then
  /// the WATCHED server set, then false. Call only from build (it `watch`es).
  bool _isFavoritedWatched() {
    if (_favoriteOverride != null) return _favoriteOverride!;
    final ids = ref.watch(favoriteProgramIdsProvider).valueOrNull;
    return ids != null && ids.contains(_resolveId);
  }

  /// Same logic with `read` (no rebuild subscription) for the tap handler.
  bool _isFavoritedRead() {
    if (_favoriteOverride != null) return _favoriteOverride!;
    final ids = ref.read(favoriteProgramIdsProvider).valueOrNull;
    return ids != null && ids.contains(_resolveId);
  }

  /// Optimistic heart toggle → add/removeFavorite → invalidate both providers.
  /// On failure the override is cleared so the UI snaps back to server truth.
  Future<void> _toggleFavorite() async {
    final id = _resolveId;
    if (id.isEmpty || _favoriteBusy) return;
    HapticService.selection();
    final next = !_isFavoritedRead();
    setState(() {
      _favoriteOverride = next;
      _favoriteBusy = true;
    });
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (next) {
        await repo.addFavorite(id);
      } else {
        await repo.removeFavorite(id);
      }
      if (!mounted) return;
      refreshProgramFavoritesW(ref);
      setState(() {
        _favoriteBusy = false;
      });
      // Reconcile: once the fresh set lands, drop the override.
      final fresh = await ref.read(favoriteProgramIdsProvider.future);
      if (!mounted) return;
      if (fresh.contains(id) == next) {
        setState(() => _favoriteOverride = null);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _favoriteOverride = null; // snap back to server truth.
        _favoriteBusy = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update favorites. Try again.')),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _resolveId => _card?.id ?? widget.programId ?? '';

  void _load() {
    final id = _resolveId;
    if (id.isEmpty) return;
    final future =
        ref.read(programTemplateRepositoryProvider).getLibraryDetail(id);
    _detail = future;
    // Upgrade the header card to the editorial-complete one once it lands.
    future.then((result) {
      if (!mounted) return;
      setState(() {
        _card = result.card;
        // Seed variant from the full card if the tapped card didn't have it.
        _selectedVariantId ??= result.card.defaultVariantId;
      });
    }).catchError((_) {
      // Swallow — the FutureBuilder below surfaces the error state.
    });
  }

  void _retry() {
    setState(_load);
  }

  void _startFlow() {
    final card = _card;
    if (card == null) return;
    HapticService.light();
    ProgramLibraryStartFlow.open(context, card);
  }

  /// Called when the user picks a different variant from the selector tiles.
  /// Resets the week index, collapses the pill row, and triggers a schedule
  /// refetch via the provider.
  void _selectVariant(String variantId) {
    if (variantId == _selectedVariantId) {
      // Tapping the already-selected pill just closes the row.
      setState(() => _expandedSelector = null);
      return;
    }
    HapticService.selection();
    setState(() {
      _selectedVariantId = variantId;
      _selectedWeekIndex = 0;
      _expandedSelector = null;
    });
  }

  /// Navigate to the Schedule tab and land on the week that contains
  /// [weekStart] (1-based). Used by phase card taps.
  void _jumpToScheduleWeek(int weekStart) {
    HapticService.light();
    // weekStart is 1-based; _selectedWeekIndex is 0-based.
    setState(() => _selectedWeekIndex = (weekStart - 1).clamp(0, 999));
    _tabController.animateTo(1);
  }

  /// Resolves the best variant for [weeks] × [sessions] on a sparse matrix.
  ///
  /// Priority:
  ///   1. Exact match (weeks == w && sessionsPerWeek == s).
  ///   2. Nearest available sessionsPerWeek for [weeks] (min abs diff; tiebreak
  ///      lower).
  ///   3. Default variant (isDefault == true).
  ///   4. First variant in the list.
  ///
  /// Never returns null as long as [variants] is non-empty.
  ProgramVariantOption _resolveVariant(
    List<ProgramVariantOption> variants,
    int weeks,
    int sessions,
  ) {
    // 1. Exact match.
    for (final v in variants) {
      if (v.weeks == weeks && v.sessionsPerWeek == sessions) return v;
    }

    // 2. Nearest sessions for the requested weeks.
    final sameWeek = variants.where((v) => v.weeks == weeks).toList();
    if (sameWeek.isNotEmpty) {
      sameWeek.sort((a, b) {
        final da = (a.sessionsPerWeek - sessions).abs();
        final db = (b.sessionsPerWeek - sessions).abs();
        if (da != db) return da.compareTo(db);
        // Tiebreak: prefer the lower sessions count.
        return a.sessionsPerWeek.compareTo(b.sessionsPerWeek);
      });
      return sameWeek.first;
    }

    // 3. Default variant.
    for (final v in variants) {
      if (v.isDefault) return v;
    }

    // 4. First variant.
    return variants.first;
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: card == null
          // No card yet (pure deep-link, first frame) — load the header lazily.
          ? FutureBuilder<
                ({ProgramLibraryCard card, ProgramTemplate sampleWeek})>(
              future: _detail,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return SafeArea(
                    child: _DetailError(onRetry: _retry, onBack: _back),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.orange),
                  );
                }
                return _buildBody(snapshot.data!.card);
              },
            )
          : _buildBody(card),
    );
  }

  void _back() {
    HapticService.light();
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Widget _buildBody(ProgramLibraryCard card) {
    return Column(
      children: [
        Expanded(
          // NestedScrollView so the OVERVIEW/SCHEDULE tab bar PINS to the top.
          // The SliverAppBar handles the 280-tall header with pinned: true so
          // it collapses to a slim bar (status-bar-height + kToolbarHeight) as
          // the user scrolls. The tab bar in a SliverPersistentHeader pins
          // BELOW the collapsed app-bar — never under the Dynamic Island.
          child: NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(card, innerBoxIsScrolled),
              SliverToBoxAdapter(child: _buildStatTiles(card)),
              SliverPersistentHeader(
                pinned: true,
                delegate: _DetailTabBarDelegate(
                  tabBar: _buildTabBar(),
                  overlapping: innerBoxIsScrolled,
                ),
              ),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(card),
                _buildScheduleTab(card),
              ],
            ),
          ),
        ),
        _buildBottomBar(card),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Header — pinned SliverAppBar with the diagonal-striped hero.
  // When expanded → full gradient + stripes + difficulty pill + Anton title.
  // When collapsed → slim bar with back ‹ + program name + favorite heart.
  // -------------------------------------------------------------------------

  Widget _buildSliverAppBar(ProgramLibraryCard card, bool innerBoxIsScrolled) {
    final theme = categoryTheme(card.programCategory);
    final hasDifficulty =
        card.difficultyLevel != null && card.difficultyLevel!.trim().isNotEmpty;
    final subtitle = (card.tagline?.trim().isNotEmpty == true)
        ? card.tagline!.trim()
        : (card.programCategory ?? '').trim();

    return SliverAppBar(
      backgroundColor: AppColors.pureBlack,
      expandedHeight: 280,
      pinned: true,
      automaticallyImplyLeading: false,
      // Collapsed bar: back ‹ + program title + favorite heart.
      leading: GestureDetector(
        onTap: _back,
        behavior: HitTestBehavior.opaque,
        child: const Icon(Icons.arrow_back_ios_new_rounded,
            size: 18, color: AppColors.textPrimary),
      ),
      title: AnimatedOpacity(
        // Fade in the collapsed title only when actually collapsed (i.e. when
        // the flexible space is shrunk away). Prevents double-title flicker.
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(
          card.displayName,
          style: ZType.sans(15,
              color: AppColors.textPrimary, weight: FontWeight.w700),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        Builder(builder: (context) {
          final fav = _isFavoritedWatched();
          return GestureDetector(
            onTap: _toggleFavorite,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 22,
                color: fav ? AppColors.orange : AppColors.textPrimary,
              ),
            ),
          );
        }),
      ],
      // Expanded area: the full 280px diagonal-striped hero.
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Tinted gradient base + diagonal stripes.
            DecoratedBox(
              decoration: BoxDecoration(gradient: theme.headerGradient),
            ),
            CustomPaint(
              painter: _DiagonalStripePainter(
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
            // Bottom scrim so the title reads against the panel.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                  stops: [0.45, 1.0],
                ),
              ),
            ),
            // Title block anchored to the bottom of the expanded area.
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasDifficulty) ...[
                    _DifficultyPill(level: card.difficultyLevel!),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    card.displayName.toUpperCase(),
                    style: ZType.disp(40, color: AppColors.textPrimary),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.ser(15, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stat tiles — WEEKS / PER WEEK / MINUTES.
  // WEEKS and PER WEEK become variant selectors when variantOptions.length > 1.
  // -------------------------------------------------------------------------

  Widget _buildStatTiles(ProgramLibraryCard card) {
    final variants = card.variantOptions;
    final hasVariants = variants.length > 1;

    // Resolve the currently-selected variant's data (fallback to card defaults).
    ProgramVariantOption? selectedVariant;
    if (hasVariants) {
      for (final v in variants) {
        if (v.variantId == _selectedVariantId) {
          selectedVariant = v;
          break;
        }
      }
      selectedVariant ??= variants.firstWhere(
        (v) => v.isDefault,
        orElse: () => variants.first,
      );
    }

    final displayWeeks = selectedVariant?.weeks ?? card.durationWeeks;
    final displaySessions =
        selectedVariant?.sessionsPerWeek ?? card.sessionsPerWeek;

    if (!hasVariants) {
      // Single-plan programs: static tiles — unchanged from before.
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                value: displayWeeks?.toString() ?? '—',
                label: 'WEEKS',
                accented: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: displaySessions?.toString() ?? '—',
                label: 'PER WEEK',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: card.sessionDurationMinutes?.toString() ?? '—',
                label: 'MINUTES',
              ),
            ),
          ],
        ),
      );
    }

    // Multi-variant: tiles look identical to the static ones (big number +
    // label) but include a subtle ⌄ chevron. Tapping a tile toggles an
    // animated pill row that slides in below the tile row — no layout pop.
    final distinctWeeks = variants.map((v) => v.weeks).toSet().toList()
      ..sort();

    // Sessions available for the currently-selected week only — sparse guard.
    final currentWeeks = selectedVariant?.weeks ?? variants.first.weeks;
    final sessionsForCurrentWeek = variants
        .where((v) => v.weeks == currentWeeks)
        .map((v) => v.sessionsPerWeek)
        .toSet()
        .toList()
      ..sort();

    final distinctIntensities =
        variants.map((v) => v.intensity).toSet().toList();

    final weeksLabel   = selectedVariant?.weeks.toString() ??
        displayWeeks?.toString() ?? '—';
    final sessionsLabel = selectedVariant?.sessionsPerWeek.toString() ??
        displaySessions?.toString() ?? '—';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Tile row — always looks like static tiles ──────────────────────
          Row(
            children: [
              // WEEKS — tappable tile that toggles the weeks pill row.
              Expanded(
                child: _SelectableTile(
                  value: weeksLabel,
                  label: 'WEEKS',
                  accented: true,
                  expanded: _expandedSelector == 'weeks',
                  onTap: () => setState(() {
                    _expandedSelector =
                        _expandedSelector == 'weeks' ? null : 'weeks';
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // PER WEEK — tappable tile that toggles the sessions pill row.
              Expanded(
                child: _SelectableTile(
                  value: sessionsLabel,
                  label: 'PER WEEK',
                  accented: false,
                  expanded: _expandedSelector == 'sessions',
                  onTap: () => setState(() {
                    _expandedSelector =
                        _expandedSelector == 'sessions' ? null : 'sessions';
                  }),
                ),
              ),
              const SizedBox(width: 10),
              // MINUTES — always static.
              Expanded(
                child: _StatTile(
                  value: card.sessionDurationMinutes?.toString() ?? '—',
                  label: 'MINUTES',
                ),
              ),
            ],
          ),

          // ── Animated pill row — slides in below tiles ──────────────────────
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expandedSelector == 'weeks'
                ? _PillRow(
                    key: const ValueKey('weeks-pills'),
                    values: distinctWeeks.map((w) => w.toString()).toList(),
                    selectedValue: weeksLabel,
                    onSelect: (val) {
                      final w = int.tryParse(val);
                      if (w == null) return;
                      final currentSessions =
                          selectedVariant?.sessionsPerWeek ??
                              variants.first.sessionsPerWeek;
                      _selectVariant(
                          _resolveVariant(variants, w, currentSessions)
                              .variantId);
                    },
                  )
                : _expandedSelector == 'sessions'
                    ? _PillRow(
                        key: const ValueKey('sessions-pills'),
                        values: sessionsForCurrentWeek
                            .map((s) => s.toString())
                            .toList(),
                        selectedValue: sessionsLabel,
                        onSelect: (val) {
                          final s = int.tryParse(val);
                          if (s == null) return;
                          _selectVariant(
                              _resolveVariant(variants, currentWeeks, s)
                                  .variantId);
                        },
                      )
                    : const SizedBox.shrink(),
          ),

          // Intensity chip row — only when there are distinct intensities.
          if (distinctIntensities.length > 1) ...[
            const SizedBox(height: 10),
            _IntensityChipRow(
              intensities: distinctIntensities,
              selectedIntensity: selectedVariant?.intensity ?? '',
              onSelect: (intensity) {
                final candidate = variants.firstWhere(
                  (v) =>
                      v.intensity == intensity &&
                      v.weeks ==
                          (selectedVariant?.weeks ?? variants.first.weeks),
                  orElse: () =>
                      variants.firstWhere((v) => v.intensity == intensity,
                          orElse: () => variants.first),
                );
                _selectVariant(candidate.variantId);
              },
            ),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Tabs.
  // -------------------------------------------------------------------------

  Widget _buildTabBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.orange,
        unselectedLabelColor: AppColors.textMuted,
        indicatorColor: AppColors.orange,
        indicatorWeight: 2.5,
        indicatorSize: TabBarIndicatorSize.label,
        labelPadding: const EdgeInsets.only(right: 24),
        labelStyle: ZType.lbl(14, letterSpacing: 1.8),
        unselectedLabelStyle: ZType.lbl(14, letterSpacing: 1.8),
        tabs: const [
          Tab(text: 'OVERVIEW'),
          Tab(text: 'SCHEDULE'),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // OVERVIEW tab — phase blocks + who-for / progression / equipment.
  // -------------------------------------------------------------------------

  Widget _buildOverviewTab(ProgramLibraryCard card) {
    final phases = card.phases.isNotEmpty
        ? card.phases
        : _fallbackPhases(card.durationWeeks);

    return ListView(
      key: const PageStorageKey<String>('program_detail_overview'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('PHASES',
            style: ZType.lbl(13,
                color: AppColors.textPrimary, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        for (final phase in phases)
          _PhaseBlock(
            phase: phase,
            onTap: () => _jumpToScheduleWeek(phase.weekStart ?? 1),
          ),
        if (phases.isEmpty)
          Text(
            'This program runs as a single continuous block.',
            style: ZType.sans(13,
                color: AppColors.textSecondary, weight: FontWeight.w500),
          ),

        if ((card.whoFor ?? '').trim().isNotEmpty)
          _OverviewNote(
            icon: Icons.check_circle_outline_rounded,
            tint: const Color(0xFF2ECC71),
            label: 'WHO IT IS FOR',
            body: card.whoFor!.trim(),
          ),
        if ((card.whoNotFor ?? '').trim().isNotEmpty)
          _OverviewNote(
            icon: Icons.do_not_disturb_on_outlined,
            tint: const Color(0xFFEF4444),
            label: 'WHO IT IS NOT FOR',
            body: card.whoNotFor!.trim(),
          ),
        if ((card.progressionNote ?? '').trim().isNotEmpty)
          _OverviewNote(
            icon: Icons.trending_up_rounded,
            tint: const Color(0xFF38BDF8),
            label: 'HOW IT PROGRESSES',
            body: card.progressionNote!.trim(),
          ),
        if ((card.equipmentSummary ?? '').trim().isNotEmpty)
          _OverviewNote(
            icon: Icons.fitness_center_rounded,
            tint: AppColors.orange,
            label: 'EQUIPMENT',
            body: card.equipmentSummary!.trim(),
          ),
      ],
    );
  }

  /// Derive a sensible phase split from [durationWeeks] when the program has no
  /// authored phases — never invents content, just a plain Foundation → Build →
  /// Peak structure proportional to length. Returns empty for very short plans.
  List<ProgramPhase> _fallbackPhases(int? durationWeeks) {
    final w = durationWeeks ?? 0;
    if (w < 3) return const [];
    if (w <= 5) {
      final mid = (w / 2).ceil();
      return [
        ProgramPhase(
            index: 1, title: 'Foundation', weekStart: 1, weekEnd: mid),
        ProgramPhase(index: 2, title: 'Build', weekStart: mid + 1, weekEnd: w),
      ];
    }
    final third = (w / 3).floor();
    return [
      ProgramPhase(
          index: 1, title: 'Foundation', weekStart: 1, weekEnd: third),
      ProgramPhase(
          index: 2, title: 'Build', weekStart: third + 1, weekEnd: third * 2),
      ProgramPhase(
          index: 3, title: 'Peak', weekStart: third * 2 + 1, weekEnd: w),
    ];
  }

  // -------------------------------------------------------------------------
  // SCHEDULE tab — multi-week grouped view with media thumbnails + tap-through.
  // -------------------------------------------------------------------------

  Widget _buildScheduleTab(ProgramLibraryCard card) {
    final scheduleKey = (
      programId: _resolveId,
      variantId: _selectedVariantId,
    );
    final scheduleAsync = ref.watch(programScheduleProvider(scheduleKey));

    return scheduleAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.orange),
      ),
      error: (err, _) => _DetailError(onRetry: () {
        ref.invalidate(programScheduleProvider(scheduleKey));
      }, onBack: null),
      data: (schedule) {
        if (schedule.weeks.isEmpty) {
          // Fallback: render the legacy sample week from the detail fetch.
          return _buildLegacyScheduleFallback();
        }
        return _buildMultiWeekSchedule(schedule);
      },
    );
  }

  /// Renders the schedule grouped by week with a week chip-row selector.
  Widget _buildMultiWeekSchedule(ProgramScheduleResponse schedule) {
    final weeks = schedule.weeks;
    final weekIndex =
        _selectedWeekIndex.clamp(0, weeks.length - 1);
    final selectedWeek = weeks[weekIndex];

    return ListView(
      key: const PageStorageKey<String>('program_detail_schedule'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        // Week selector chip row: Wk 1, Wk 2, ...
        if (weeks.length > 1) ...[
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: weeks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final isSelected = i == weekIndex;
                return GestureDetector(
                  onTap: () {
                    if (i == weekIndex) return;
                    HapticService.light();
                    setState(() => _selectedWeekIndex = i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.orange.withValues(alpha: 0.18)
                          : AppColors.surface2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.orange
                            : AppColors.cardBorder,
                      ),
                    ),
                    child: Text(
                      'Wk ${weeks[i].weekNumber}',
                      style: ZType.lbl(12,
                          color: isSelected
                              ? AppColors.orange
                              : AppColors.textSecondary,
                          letterSpacing: 1.0),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
        ],

        // Phase / focus header for the selected week.
        if ((selectedWeek.phase?.trim().isNotEmpty ?? false) ||
            (selectedWeek.focus?.trim().isNotEmpty ?? false)) ...[
          _WeekPhaseHeader(week: selectedWeek),
          const SizedBox(height: 12),
        ],

        // Day cards for the selected week.
        for (final day in selectedWeek.days)
          _ScheduleDayCard(day: day, onExerciseTap: _openExerciseDetail),
      ],
    );
  }

  /// Fallback to the legacy sample-week when the new schedule endpoint returns
  /// nothing (e.g., the backend is mid-deploy). Shows the old day tiles.
  Widget _buildLegacyScheduleFallback() {
    return FutureBuilder<({ProgramLibraryCard card, ProgramTemplate sampleWeek})>(
      future: _detail,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return _DetailError(onRetry: _retry, onBack: null);
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          );
        }
        final template = snapshot.data!.sampleWeek;
        if (template.days.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Text(
                'A day-by-day schedule is not available for this program.',
                textAlign: TextAlign.center,
                style: ZType.sans(14,
                    color: AppColors.textSecondary, weight: FontWeight.w500),
              ),
            ),
          );
        }
        return ListView(
          key: const PageStorageKey<String>('program_detail_schedule'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (final day in template.days)
              _LegacyScheduleDayTile(day: day),
          ],
        );
      },
    );
  }

  /// Open the modern read-only exercise detail for a schedule exercise.
  /// Threads the schedule row's exerciseId so media + stats resolve to the
  /// exact library row; falls back to name-only resolution when absent.
  void _openExerciseDetail(ProgramScheduleExercise ex) {
    openExerciseBrowse(
      context,
      name: ex.name,
      exerciseId: ex.exerciseId,
      libraryId: ex.exerciseId,
    );
  }

  // -------------------------------------------------------------------------
  // Sticky bottom bar — JOINED <count> (real, hidden when 0/null) + START.
  // -------------------------------------------------------------------------

  Widget _buildBottomBar(ProgramLibraryCard card) {
    final joined = card.joinedCount;
    final showJoined = joined != null && joined > 0;
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF09090B),
        border: Border(top: BorderSide(color: AppColors.hairlineStrong)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              if (showJoined) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatJoined(joined),
                        style: ZType.data(17, color: AppColors.textPrimary)),
                    Text('JOINED',
                        style: ZType.lbl(10,
                            color: AppColors.textMuted, letterSpacing: 1.6)),
                  ],
                ),
                const SizedBox(width: 16),
              ],
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _startFlow,
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
            ],
          ),
        ),
      ),
    );
  }

  /// "1,240" style grouping for the joined count.
  String _formatJoined(int n) {
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ===========================================================================
// Header pieces.
// ===========================================================================

class _DifficultyPill extends StatelessWidget {
  final String level;
  const _DifficultyPill({required this.level});

  @override
  Widget build(BuildContext context) {
    final color = programDifficultyColor(level);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(level.toUpperCase(),
              style: ZType.lbl(11, color: AppColors.textPrimary,
                  letterSpacing: 1.4)),
        ],
      ),
    );
  }
}

/// Diagonal hatch lines over the header panel — image-free texture.
class _DiagonalStripePainter extends CustomPainter {
  final Color color;
  const _DiagonalStripePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2;
    const gap = 18.0;
    for (double x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DiagonalStripePainter oldDelegate) =>
      oldDelegate.color != color;
}

// ===========================================================================
// Selectable stat tile — looks like _StatTile but shows a small ⌄/⌃ chevron
// in the bottom-right corner when the program has >1 option for this
// dimension. Tapping toggles the pill row that slides in below.
// ===========================================================================

class _SelectableTile extends StatelessWidget {
  final String value;
  final String label;
  final bool accented;
  final bool expanded;
  final VoidCallback onTap;

  const _SelectableTile({
    required this.value,
    required this.label,
    required this.accented,
    required this.expanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: accented
              ? AppColors.orange.withValues(alpha: 0.14)
              : AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: accented
                ? AppColors.orange
                : (expanded ? AppColors.orange : AppColors.cardBorder),
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: ZType.disp(28,
                        color: accented
                            ? AppColors.orange
                            : AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: ZType.lbl(10,
                        color: AppColors.textMuted, letterSpacing: 1.4),
                  ),
                ],
              ),
            ),
            // Subtle affordance chevron anchored to bottom-right.
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: accented
                    ? AppColors.orange.withValues(alpha: 0.7)
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Pill row — horizontal scrollable strip of option chips that animates in
// below the tile row when a _SelectableTile is tapped.
// ===========================================================================

class _PillRow extends StatelessWidget {
  final List<String> values;
  final String selectedValue;
  final ValueChanged<String> onSelect;

  const _PillRow({
    super.key,
    required this.values,
    required this.selectedValue,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: values.map((v) {
            final isSelected = v == selectedValue;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onSelect(v),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.orange
                        : AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.orange
                          : AppColors.cardBorder,
                    ),
                  ),
                  child: Text(
                    v,
                    style: ZType.sans(14,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        weight: FontWeight.w700),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Intensity chip row — shown beneath the WEEKS/PER-WEEK/MINUTES row when
/// there are multiple distinct intensities (e.g. Light / Medium / Hard).
class _IntensityChipRow extends StatelessWidget {
  final List<String> intensities;
  final String selectedIntensity;
  final ValueChanged<String> onSelect;

  const _IntensityChipRow({
    required this.intensities,
    required this.selectedIntensity,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('INTENSITY',
            style: ZType.lbl(10,
                color: AppColors.textMuted, letterSpacing: 1.4)),
        const SizedBox(width: 10),
        Wrap(
          spacing: 8,
          children: intensities.map((intensity) {
            final isSelected = intensity == selectedIntensity;
            return GestureDetector(
              onTap: () => onSelect(intensity),
              behavior: HitTestBehavior.opaque,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.orange.withValues(alpha: 0.18)
                      : AppColors.surface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.orange
                        : AppColors.cardBorder,
                  ),
                ),
                child: Text(
                  intensity,
                  style: ZType.sans(12,
                      color: isSelected
                          ? AppColors.orange
                          : AppColors.textSecondary,
                      weight: FontWeight.w600),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// ===========================================================================
// Stat tile (static — no variant selector).
// ===========================================================================

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final bool accented;

  const _StatTile({
    required this.value,
    required this.label,
    this.accented = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: accented
            ? AppColors.orange.withValues(alpha: 0.14)
            : AppColors.surface2,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: accented ? AppColors.orange : AppColors.cardBorder,
        ),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: ZType.disp(28,
                color: accented ? AppColors.orange : AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ZType.lbl(10, color: AppColors.textMuted, letterSpacing: 1.4),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Overview pieces — phase block + note.
// ===========================================================================

class _PhaseBlock extends StatelessWidget {
  final ProgramPhase phase;

  /// Tapping the card navigates to the schedule tab at [phase.weekStart].
  final VoidCallback onTap;

  const _PhaseBlock({required this.phase, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final weekLabel = phase.weekLabel;
    final subtitle = phase.subtitle?.trim();
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              phase.index.toString().padLeft(2, '0'),
              style: ZType.disp(26, color: AppColors.orange),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    phase.title,
                    style: ZType.sans(15,
                        color: AppColors.textPrimary, weight: FontWeight.w700),
                  ),
                  if (weekLabel != null ||
                      (subtitle != null && subtitle.isNotEmpty)) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (weekLabel != null) weekLabel,
                        if (subtitle != null && subtitle.isNotEmpty) subtitle,
                      ].join(' · '),
                      style: ZType.sans(12.5,
                          color: AppColors.textSecondary,
                          weight: FontWeight.w500),
                    ),
                  ],
                ],
              ),
            ),
            // Chevron is now meaningful — tapping navigates to that phase's
            // first week in the Schedule tab.
            const Icon(Icons.chevron_right_rounded,
                size: 20, color: AppColors.orange),
          ],
        ),
      ),
    );
  }
}

class _OverviewNote extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String label;
  final String body;

  const _OverviewNote({
    required this.icon,
    required this.tint,
    required this.label,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
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
                Text(label,
                    style: ZType.lbl(10.5,
                        color: AppColors.textMuted, letterSpacing: 1.6)),
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

// ===========================================================================
// Schedule — week phase header + day cards with media thumbnails.
// ===========================================================================

/// Optional week-level header showing the phase name and focus line.
class _WeekPhaseHeader extends StatelessWidget {
  final ProgramScheduleWeek week;
  const _WeekPhaseHeader({required this.week});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if ((week.phase?.trim().isNotEmpty ?? false))
          Text(
            week.phase!.trim().toUpperCase(),
            style: ZType.lbl(12,
                color: AppColors.orange, letterSpacing: 1.5),
          ),
        if ((week.focus?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 2),
          Text(
            week.focus!.trim(),
            style: ZType.sans(12.5,
                color: AppColors.textSecondary, weight: FontWeight.w500),
          ),
        ],
      ],
    );
  }
}

/// One training day card in the schedule tab — shows the day name and a list
/// of exercise rows with 40px thumbnails. Tapping an exercise row opens the
/// modern read-only exercise detail (browse mode).
class _ScheduleDayCard extends StatelessWidget {
  final ProgramScheduleDay day;
  final void Function(ProgramScheduleExercise) onExerciseTap;

  const _ScheduleDayCard({required this.day, required this.onExerciseTap});

  @override
  Widget build(BuildContext context) {
    if (day.isRest) {
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
              '${day.dayName} · Rest',
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
          // Day name header + optional workout type badge.
          Row(
            children: [
              Expanded(
                child: Text(
                  day.dayName.toUpperCase(),
                  style: ZType.lbl(13,
                      color: AppColors.textPrimary, letterSpacing: 1.2),
                ),
              ),
              if (day.workoutType != null && day.workoutType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    day.workoutType!.toUpperCase(),
                    style: ZType.lbl(9,
                        color: AppColors.textMuted, letterSpacing: 1.2),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          for (final ex in day.exercises)
            _ScheduleExerciseRow(ex: ex, onTap: () => onExerciseTap(ex)),
        ],
      ),
    );
  }
}

/// One exercise row inside a day card — 40px thumbnail on the left, name and
/// volume label on the right. Tapping opens the exercise detail sheet.
class _ScheduleExerciseRow extends StatelessWidget {
  final ProgramScheduleExercise ex;
  final VoidCallback onTap;

  const _ScheduleExerciseRow({required this.ex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final volume = ex.volumeLabel;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 40×40 thumbnail — uses the pre-resolved imageUrl when present,
            // else resolves by exerciseId (preferred) or name via the widget.
            ExerciseImage(
              exerciseName: ex.name,
              imageUrl: ex.imageUrl,
              exerciseId: ex.exerciseId,
              width: 40,
              height: 40,
              borderRadius: 8,
              backgroundColor: AppColors.surface,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ex.name,
                style: ZType.sans(13,
                    color: AppColors.textPrimary, weight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (volume.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                volume,
                style: ZType.data(11, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Legacy schedule day tile — fallback when new schedule endpoint returns empty.
// Mirrors the old _ScheduleDayTile but without the class name collision.
// ===========================================================================

class _LegacyScheduleDayTile extends StatelessWidget {
  final ProgramDay day;
  const _LegacyScheduleDayTile({required this.day});

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
              '${day.dayName} · Rest',
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
                  ExerciseImage(
                    exerciseName: ex.name,
                    exerciseId: ex.exerciseId,
                    width: 40,
                    height: 40,
                    borderRadius: 8,
                    backgroundColor: AppColors.surface,
                  ),
                  const SizedBox(width: 10),
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
                    '${ex.sets} × ${ex.repsLabel()}',
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
// Error state.
// ===========================================================================

class _DetailError extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback? onBack;

  const _DetailError({required this.onRetry, this.onBack});

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
              'We could not load this program.',
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
              label: const Text('Retry'),
            ),
            if (onBack != null) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: onBack,
                child: Text('Go back',
                    style: ZType.sans(13,
                        color: AppColors.textMuted, weight: FontWeight.w600)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ===========================================================================
// Pinned tab-bar delegate — keeps OVERVIEW / SCHEDULE stuck to the top while
// each tab's content scrolls beneath it (NestedScrollView header sliver).
// ===========================================================================

class _DetailTabBarDelegate extends SliverPersistentHeaderDelegate {
  final Widget tabBar;

  /// True once inner tab content has scrolled under the bar — adds a divider.
  final bool overlapping;

  _DetailTabBarDelegate({required this.tabBar, required this.overlapping});

  // TabBar (~46) + the bar's top padding (8) + a hairline. A constant extent
  // keeps the pin smooth.
  static const double _extent = 56;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      height: _extent,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        border: overlapping || overlapsContent
            ? const Border(
                bottom: BorderSide(color: AppColors.hairlineStrong))
            : null,
      ),
      alignment: Alignment.centerLeft,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_DetailTabBarDelegate oldDelegate) =>
      oldDelegate.overlapping != overlapping || oldDelegate.tabBar != tabBar;
}
