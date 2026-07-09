import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/program_template.dart';
import '../../data/providers/branded_program_provider.dart'
    show activeUserProgramProvider;
import '../../data/providers/equipment_coverage_provider.dart';
import '../../data/providers/program_favorites_provider.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/exercise_image.dart';
import '../../widgets/signature/signature.dart';
import 'exercise_browse.dart';
import 'program_library_screen.dart' show ProgramLibraryStartFlow;
import 'widgets/variant_picker.dart';

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
    : assert(
        card != null || programId != null,
        'ProgramDetailScreen needs a card or a programId',
      );

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

  /// True once the FULL editorial detail (cache OR network) has resolved. Until
  /// then [_card] is the lightweight browse card, which lacks phases / variant
  /// options / joined-count — so the Overview tab shows a phases SKELETON rather
  /// than fabricating "Foundation → Build → Peak" placeholders that then swap
  /// out under the user (the "why did it change?" jank this fixes).
  bool _detailLoaded = false;

  /// Guards the cache-vs-network race: if the network result lands first (rare —
  /// a disk read is normally faster), don't let the stale-cache read clobber it.
  bool _gotFreshDetail = false;

  /// Optimistic favorite override — null means "defer to the server set"
  /// ([favoriteProgramIdsProvider]); non-null is the in-flight toggle target
  /// shown immediately while the add/remove call + invalidation settle.
  bool? _favoriteOverride;
  bool _favoriteBusy = false;

  /// The currently-selected variant id. Null = program default (or single plan).
  String? _selectedVariantId;

  /// Bumped whenever the selected variant changes WITHOUT a full setState, so
  /// only the scoped subtrees that depend on the variant — the stat-tile
  /// selector and the Schedule tab — rebuild. Selecting a variant must NOT
  /// rebuild the whole NestedScrollView (the data is already in memory; the lag
  /// was the full-screen rebuild). See [_selectVariant].
  final ValueNotifier<int> _variantRev = ValueNotifier<int>(0);

  /// True once the user has explicitly picked a variant (via the picker sheet).
  /// While false we keep re-syncing [_selectedVariantId] to the program default
  /// as richer detail loads, so the screen always opens on the recommended
  /// plan (e.g. HYROX → 8 weeks / 4 per week) rather than the first list card.
  bool _userPickedVariant = false;

  /// The selected week index (0-based) in the schedule tab. Resets to 0
  /// whenever the variant changes so the user always lands on week 1.
  int _selectedWeekIndex = 0;

  /// One-shot guard: true once [_selectedWeekIndex] has been seeded from the
  /// enrolled program's current week (or the user has navigated weeks/variants
  /// themselves), so later schedule rebuilds never override their choice.
  bool _seededInitialWeek = false;

  /// Overscroll distance (px) the user has pulled past the top — drives the
  /// stretchy-zoom of the hero. Done MANUALLY because `SliverAppBar.stretch` /
  /// `StretchMode.zoomBackground` do NOT fire inside a [NestedScrollView] (the
  /// inner tab body absorbs the overscroll, so the outer header never
  /// stretches). A [ValueNotifier] so only the hero image's transform rebuilds.
  ///
  /// IMPORTANT: this must only ever drive a paint-time `Transform.scale` on
  /// the hero image — never the `SliverAppBar`'s `expandedHeight`. Mutating
  /// the sliver's actual extent from inside a scroll-notification callback
  /// races `NestedScrollView`'s own outer/inner scroll reconciliation (the
  /// header's reported max extent changes while the coordinator is mid-way
  /// through applying the very overscroll delta that's driving this value),
  /// which previously crashed production with
  /// `'extra >= 0.0': is not true` in nested_scroll_view.dart.
  final ValueNotifier<double> _headerZoom = ValueNotifier<double>(0);

  /// One light haptic per pull once the zoom crosses a threshold (re-armed when
  /// the pull releases). Mirrors the SliverAppBar `onStretchTrigger` feel.
  bool _zoomHapticArmed = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _card = widget.card;
    // Seed the variant from whatever the tapped card already knows. The list
    // card usually has no defaultVariantId, so this is often null until the
    // full detail fetch resolves and _syncDefaultVariant() runs below.
    _selectedVariantId = widget.card?.defaultVariantId;
    _syncDefaultVariant(widget.card);
    _load();
  }

  /// Re-point [_selectedVariantId] at the program's default/recommended variant
  /// from [card]'s `variantOptions`, unless the user has manually picked one.
  /// Prefers the `is_default` option, falling back to [card.defaultVariantId],
  /// then the first option. No-op for single-plan programs.
  void _syncDefaultVariant(ProgramLibraryCard? card) {
    if (_userPickedVariant || card == null) return;
    final variants = card.variantOptions;
    if (variants.length <= 1) return;
    final defaultVariant = variants.firstWhere(
      (v) => v.isDefault,
      orElse: () => variants.firstWhere(
        (v) => v.variantId == card.defaultVariantId,
        orElse: () => variants.first,
      ),
    );
    _selectedVariantId = defaultVariant.variantId;
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
    _variantRev.dispose();
    _headerZoom.dispose();
    super.dispose();
  }

  /// Track overscroll-past-top to drive the manual hero zoom. The inner tab
  /// body's [ScrollPosition] overshoots below `minScrollExtent` when pulled
  /// down at the top (BouncingScrollPhysics), so `minScrollExtent - pixels` is
  /// the pull distance. We only ACT on real overscroll and reset on scroll-end,
  /// so interleaved non-overscrolling notifications can't reset mid-pull.
  bool _onScrollForZoom(ScrollNotification n) {
    if (n.metrics.axis != Axis.vertical) return false;
    if (n is ScrollEndNotification) {
      _headerZoom.value = 0;
      _zoomHapticArmed = true;
      return false;
    }
    final over = n.metrics.minScrollExtent - n.metrics.pixels;
    if (over > 0) {
      _headerZoom.value = over;
      if (over > 64 && _zoomHapticArmed) {
        _zoomHapticArmed = false;
        HapticService.light();
      }
    }
    return false;
  }

  /// Overscroll pull distance (px) at which the hero zoom reaches its max
  /// scale, then springs back on release. The `SliverAppBar`'s `expandedHeight`
  /// itself stays constant (see [_headerZoom] doc) — only the hero image's
  /// paint-time scale responds to this.
  static const double _kMaxHeaderStretch = 140;

  /// Max fractional zoom applied to the hero image at full overscroll pull
  /// (e.g. 0.25 == image scales up to 125%).
  static const double _kMaxHeaderZoomScale = 0.25;

  String get _resolveId => _card?.id ?? widget.programId ?? '';

  void _load() {
    final id = _resolveId;
    if (id.isEmpty) return;
    _gotFreshDetail = false;
    final repo = ref.read(programTemplateRepositoryProvider);

    // Network fetch (also write-through caches to disk). Seed _detail so the
    // deep-link FutureBuilder + Schedule-tab fallback always have a future to
    // await, even before the disk-cache read below returns.
    final fresh = repo.getLibraryDetail(id);
    _detail = fresh;
    fresh
        .then((result) {
          if (!mounted) return;
          _gotFreshDetail = true;
          setState(() {
            _detail = Future.value(result);
            _card = result.card;
            _detailLoaded = true;
            // The full editorial card carries variant_options + default_variant_id.
            // Re-point to the recommended variant now that we know it — unless the
            // user already picked one — so the screen opens on the default (e.g.
            // HYROX → 8 weeks / 4 per week), not the lowest-weeks list-card option.
            _syncDefaultVariant(result.card);
          });
        })
        .catchError((_) {
          // Swallow — the FutureBuilder below surfaces the error state.
        });

    // Cache-first: paint the REAL disk-cached detail (phases / variants /
    // joined) instantly on a repeat open, unless the network already won the
    // race. Kills the placeholder→real swap entirely after the first visit.
    repo
        .cachedLibraryDetail(id)
        .then((cached) {
          if (cached == null || !mounted || _gotFreshDetail) return;
          setState(() {
            _detail = Future.value(cached);
            _card = cached.card;
            _detailLoaded = true;
            _syncDefaultVariant(cached.card);
          });
        })
        .catchError((_) {
          // Cache miss / parse failure is non-fatal — the network path covers it.
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

  /// Called when the user picks a variant from the picker sheet. Marks the
  /// choice as user-driven (so the default-sync stops overriding it), resets the
  /// week index, and triggers a schedule refetch via the provider.
  void _selectVariant(String variantId) {
    if (variantId == _selectedVariantId) {
      _userPickedVariant = true;
      return;
    }
    HapticService.selection();
    // Scoped update: mutate the fields directly and bump [_variantRev] so only
    // the stat selector + Schedule tab rebuild — never the whole tree.
    _selectedVariantId = variantId;
    _userPickedVariant = true;
    // Deliberate week-1 reset — the new variant has a different week
    // structure; block the enrolled-week seed from overriding it.
    _seededInitialWeek = true;
    _selectedWeekIndex = 0;
    _variantRev.value++;
  }

  /// Reset the selection back to the program's default/recommended variant.
  /// Clears the user-picked flag so future detail refreshes can re-sync.
  void _resetVariantToDefault() {
    HapticService.selection();
    _userPickedVariant = false;
    _seededInitialWeek = true;
    _selectedWeekIndex = 0;
    _syncDefaultVariant(_card);
    _variantRev.value++;
  }

  /// Navigate to the Schedule tab and land on the week that contains
  /// [weekStart] (1-based). Used by phase card taps.
  void _jumpToScheduleWeek(int weekStart) {
    HapticService.light();
    _seededInitialWeek = true;
    // weekStart is 1-based; _selectedWeekIndex is 0-based.
    setState(() => _selectedWeekIndex = (weekStart - 1).clamp(0, 999));
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    final card = _card;
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: card == null
          // No card yet (pure deep-link, first frame) — load the header lazily.
          ? FutureBuilder<
              ({ProgramLibraryCard card, ProgramTemplate sampleWeek})
            >(
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
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScrollForZoom,
            child: NestedScrollView(
              // BouncingScrollPhysics on BOTH platforms so the body overscrolls
              // at the top (Android's default ClampingScrollPhysics doesn't) —
              // that overscroll is what `_onScrollForZoom` reads to drive the
              // manual hero zoom.
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                // Only the app bar rebuilds as the overscroll grows its height —
                // not the whole NestedScrollView — so the stretch stays smooth.
                ValueListenableBuilder<double>(
                  valueListenable: _headerZoom,
                  builder: (_, over, __) => _buildSliverAppBar(
                    card,
                    innerBoxIsScrolled,
                    over.clamp(0.0, _kMaxHeaderStretch),
                  ),
                ),
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
                children: [_buildOverviewTab(card), _buildScheduleTab(card)],
              ),
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

  Widget _buildSliverAppBar(
    ProgramLibraryCard card,
    bool innerBoxIsScrolled,
    double stretch,
  ) {
    final theme = categoryTheme(card.programCategory);
    final hasDifficulty =
        card.difficultyLevel != null && card.difficultyLevel!.trim().isNotEmpty;
    final subtitle = (card.tagline?.trim().isNotEmpty == true)
        ? card.tagline!.trim()
        : (card.programCategory ?? '').trim();
    final hasCover = (card.imageUrl ?? '').isNotEmpty;

    return SliverAppBar(
      backgroundColor: AppColors.pureBlack,
      // Deliberately CONSTANT — see [_headerZoom] doc for why this must never
      // vary with the overscroll pull. The stretch is instead applied as a
      // paint-only Transform.scale on the hero background below, which never
      // touches NestedScrollView's scroll-extent bookkeeping.
      expandedHeight: 280,
      pinned: true,
      automaticallyImplyLeading: false,
      // Collapsed bar: back ‹ + program title + favorite heart.
      leading: GestureDetector(
        onTap: _back,
        behavior: HitTestBehavior.opaque,
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: AppColors.textPrimary,
        ),
      ),
      title: AnimatedOpacity(
        // Fade in the collapsed title only when actually collapsed (i.e. when
        // the flexible space is shrunk away). Prevents double-title flicker.
        opacity: innerBoxIsScrolled ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 150),
        child: Text(
          card.displayName,
          style: ZType.sans(
            15,
            color: AppColors.textPrimary,
            weight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      actions: [
        Builder(
          builder: (context) {
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
          },
        ),
      ],
      // Expanded area: the full 280px diagonal-striped hero.
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hero art only — clipped + paint-scaled by the overscroll pull.
            // Scaling (not resizing) keeps the SliverAppBar's real extent
            // constant, so this can never destabilize NestedScrollView.
            ClipRect(
              child: Transform.scale(
                alignment: Alignment.topCenter,
                scale:
                    1 +
                    (stretch / _kMaxHeaderStretch) * _kMaxHeaderZoomScale,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (hasCover) ...[
                      // Cover art; scrim top+bottom keeps the back/heart
                      // controls legible over any photo. BoxFit.cover plus
                      // the wrapping Transform.scale above is what produces
                      // the "zoom in" feel on pull.
                      CachedNetworkImage(
                        imageUrl: card.imageUrl!,
                        fit: BoxFit.cover,
                        fadeInDuration: const Duration(milliseconds: 200),
                        errorWidget: (_, __, ___) => DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: theme.headerGradient,
                          ),
                        ),
                      ),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x73000000),
                              Color(0x1A000000),
                              Color(0xE6000000),
                            ],
                            stops: [0.0, 0.4, 1.0],
                          ),
                        ),
                      ),
                    ] else ...[
                      // Tinted gradient base + diagonal stripes.
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: theme.headerGradient,
                        ),
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
                    ],
                  ],
                ),
              ),
            ),
            // Title block anchored to the bottom of the expanded area — kept
            // OUTSIDE the scale transform so text always stays crisp/fixed.
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

    if (!hasVariants) {
      // Single-plan programs: static tiles — unchanged from before.
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Row(
          children: [
            Expanded(
              child: _StatTile(
                value: card.durationWeeks?.toString() ?? '—',
                label: 'WEEKS',
                accented: true,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatTile(
                value: card.sessionsPerWeek?.toString() ?? '—',
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

    // Multi-variant: WEEKS and PER WEEK render as the shared dropdown selector
    // (bordered "select" box + ▾ chevron) that opens a bottom-sheet picker;
    // MINUTES stays a plain static stat tile. Wrapped in a ValueListenableBuilder
    // on [_variantRev] so picking a variant rebuilds ONLY this selector + the
    // Schedule tab — never the whole NestedScrollView.
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: ValueListenableBuilder<int>(
        valueListenable: _variantRev,
        builder: (context, _, __) {
          return VariantSelectorRow(
            variants: variants,
            selectedVariantId: _selectedVariantId,
            defaultVariantId: card.defaultVariantId,
            trailing: _StatTile(
              value: card.sessionDurationMinutes?.toString() ?? '—',
              label: 'MINUTES',
            ),
            onSelect: (v) => _selectVariant(v.variantId),
            onResetToDefault: _resetVariantToDefault,
          );
        },
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
    final phases = card.phases;
    // While the full editorial detail is still loading we show a SKELETON
    // instead of fabricating generic phases — the lightweight browse card has
    // none, and inventing "Foundation → Build → Peak" only to swap it for the
    // real authored phases is exactly the jank we're removing.
    final showPhaseSkeleton = phases.isEmpty && !_detailLoaded;

    return ListView(
      key: const PageStorageKey<String>('program_detail_overview'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'PHASES',
          style: ZType.lbl(
            13,
            color: AppColors.textPrimary,
            letterSpacing: 1.8,
          ),
        ),
        const SizedBox(height: 12),
        if (showPhaseSkeleton)
          const _PhaseSkeleton()
        else ...[
          for (final phase in phases)
            _PhaseBlock(
              phase: phase,
              onTap: () => _jumpToScheduleWeek(phase.weekStart ?? 1),
            ),
          if (phases.isEmpty)
            Text(
              'This program runs as a single continuous block.',
              style: ZType.sans(
                13,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
              ),
            ),
        ],

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
        _buildEquipmentFitBadge(card),
      ],
    );
  }

  /// Compact fit-check pill vs the active gym profile — sets expectations BEFORE
  /// the Start sheet. Reactive to variant switches (via [_variantRev]) and the
  /// active gym profile (the coverage provider re-runs on profile change).
  /// Branded programs / loading / empty programs render nothing.
  Widget _buildEquipmentFitBadge(ProgramLibraryCard card) {
    if (card.isBranded) return const SizedBox.shrink();
    return ValueListenableBuilder<int>(
      valueListenable: _variantRev,
      builder: (context, _, __) {
        return Consumer(
          builder: (context, ref, __) {
            final cov = ref
                .watch(
                  equipmentCoverageProvider((
                    programId: _resolveId,
                    variantId: _selectedVariantId,
                  )),
                )
                .valueOrNull;
            if (cov == null || cov.totalExercises == 0) {
              return const SizedBox.shrink();
            }

            late final IconData icon;
            late final Color tint;
            late final String text;
            VoidCallback? onTap;
            if (cov.isCovered) {
              icon = Icons.check_circle_rounded;
              tint = AppColors.success;
              text = 'Fits your gym';
            } else if (cov.isUnknown) {
              icon = Icons.fitness_center_rounded;
              tint = AppColors.textMuted;
              text = 'Set your gym equipment to tailor this';
              onTap = () => context.push('/settings/equipment');
            } else {
              icon = Icons.handyman_rounded;
              tint = AppColors.warning;
              final n = cov.swappableCount;
              text =
                  'Needs ${_humanizeEquipmentSlugs(cov.missingEquipment)}'
                  " — we'll swap $n on Start";
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: GestureDetector(
                onTap: onTap,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: tint.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tint.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, size: 15, color: tint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          text,
                          style: ZType.sans(
                            12,
                            color: AppColors.textSecondary,
                            weight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (onTap != null)
                        Text(
                          'Add →',
                          style: ZType.sans(
                            12,
                            color: AppColors.orange,
                            weight: FontWeight.w700,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Pretty equipment-slug list for copy ("barbell" → "Barbell"), capped at 2.
  String _humanizeEquipmentSlugs(List<String> slugs) {
    String cap(String s) => s
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final names = slugs.map(cap).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names.take(2).join(' + ')} +${names.length - 2}';
  }

  // -------------------------------------------------------------------------
  // SCHEDULE tab — multi-week grouped view with media thumbnails + tap-through.
  // -------------------------------------------------------------------------

  Widget _buildScheduleTab(ProgramLibraryCard card) {
    // Rebuild only this subtree (not the whole NestedScrollView) when the user
    // picks a new variant — the stat selector + this tab are the only things
    // that depend on [_selectedVariantId]. The inner [Consumer] gives the
    // provider watch its own correctly-scoped ref so the dependency is tracked
    // (and cleaned up) on each variant switch.
    return ValueListenableBuilder<int>(
      valueListenable: _variantRev,
      builder: (context, _, __) {
        final scheduleKey = (
          programId: _resolveId,
          variantId: _selectedVariantId,
        );
        return Consumer(
          builder: (context, ref, __) {
            final scheduleAsync = ref.watch(
              programScheduleProvider(scheduleKey),
            );
            return scheduleAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.orange),
              ),
              error: (err, _) => _DetailError(
                onRetry: () {
                  ref.invalidate(programScheduleProvider(scheduleKey));
                },
                onBack: null,
              ),
              data: (schedule) {
                if (schedule.weeks.isEmpty) {
                  // Fallback: render the legacy sample week from the detail fetch.
                  return _buildLegacyScheduleFallback();
                }
                return _buildMultiWeekSchedule(schedule);
              },
            );
          },
        );
      },
    );
  }

  /// Renders the schedule grouped by week with a week chip-row selector.
  Widget _buildMultiWeekSchedule(ProgramScheduleResponse schedule) {
    final weeks = schedule.weeks;
    // Enrolled users land on the week they're actually IN, not week 1.
    // Seeded once from the active user program (current_week, falling back
    // to weeks elapsed since started_at); browsing users keep week 1.
    if (!_seededInitialWeek) {
      final active = ref.read(activeUserProgramProvider);
      if (active != null && active.programId == _resolveId) {
        var week = active.currentWeek ?? 0;
        if (week <= 0 && active.startedAt != null) {
          final started = DateTime.tryParse(active.startedAt!);
          if (started != null) {
            week = DateTime.now().difference(started).inDays ~/ 7 + 1;
          }
        }
        if (week > 1) {
          _selectedWeekIndex = (week - 1).clamp(0, weeks.length - 1);
        }
        _seededInitialWeek = true;
      }
    }
    final weekIndex = _selectedWeekIndex.clamp(0, weeks.length - 1);
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
                    _seededInitialWeek = true;
                    setState(() => _selectedWeekIndex = i);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
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
                      style: ZType.lbl(
                        12,
                        color: isSelected
                            ? AppColors.orange
                            : AppColors.textSecondary,
                        letterSpacing: 1.0,
                      ),
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
    return FutureBuilder<
      ({ProgramLibraryCard card, ProgramTemplate sampleWeek})
    >(
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
                style: ZType.sans(
                  14,
                  color: AppColors.textSecondary,
                  weight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        return ListView(
          key: const PageStorageKey<String>('program_detail_schedule'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            for (final day in template.days) _LegacyScheduleDayTile(day: day),
          ],
        );
      },
    );
  }

  /// Open the modern read-only exercise detail for a schedule exercise.
  /// Threads the schedule row's exerciseId so media + stats resolve to the
  /// exact library row; falls back to name-only resolution when absent.
  void _openExerciseDetail(ProgramScheduleExercise ex) {
    // Compose the program's own coaching text (already display-ready sentences)
    // so the exercise-detail Notes card shows protocol context, not just the
    // generic library entry. Order: intensity target, protocol note, form cue.
    final parts = [ex.intensityGuidance, ex.protocolNote, ex.coachCue]
        .where((p) => p != null && p.trim().isNotEmpty)
        .map((p) => p!.trim())
        .toList();
    final contextNote = parts.isEmpty ? null : parts.join(' ');
    openExerciseBrowse(
      context,
      name: ex.name,
      exerciseId: ex.exerciseId,
      libraryId: ex.exerciseId,
      contextNote: contextNote,
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
                    Text(
                      _formatJoined(joined),
                      style: ZType.data(17, color: AppColors.textPrimary),
                    ),
                    Text(
                      'JOINED',
                      style: ZType.lbl(
                        10,
                        color: AppColors.textMuted,
                        letterSpacing: 1.6,
                      ),
                    ),
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
                    style: ZType.lbl(
                      14,
                      color: Colors.white,
                      weight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
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
          Text(
            level.toUpperCase(),
            style: ZType.lbl(
              11,
              color: AppColors.textPrimary,
              letterSpacing: 1.4,
            ),
          ),
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
            style: ZType.disp(
              28,
              color: accented ? AppColors.orange : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: ZType.lbl(
              10,
              color: AppColors.textMuted,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// Overview pieces — phase block + note.
// ===========================================================================

/// Placeholder shown in the Overview tab's PHASES section while the full
/// editorial detail loads. Mirrors [_PhaseBlock]'s geometry so the real phases
/// drop in without a layout jump — and, crucially, shows nothing the user could
/// mistake for content, so there's no "why did it change?" swap.
class _PhaseSkeleton extends StatelessWidget {
  const _PhaseSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
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
                const _SkeletonBar(width: 30, height: 26),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      _SkeletonBar(width: 120, height: 14),
                      SizedBox(height: 7),
                      _SkeletonBar(width: 180, height: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Tiny static (non-animated) skeleton bar — matches the program library's
/// `_ShimmerBox` look so loading states feel consistent across the feature.
class _SkeletonBar extends StatelessWidget {
  final double width;
  final double height;
  const _SkeletonBar({required this.width, required this.height});

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
                    style: ZType.sans(
                      15,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w700,
                    ),
                  ),
                  if (weekLabel != null ||
                      (subtitle != null && subtitle.isNotEmpty)) ...[
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (weekLabel != null) weekLabel,
                        if (subtitle != null && subtitle.isNotEmpty) subtitle,
                      ].join(' · '),
                      style: ZType.sans(
                        12.5,
                        color: AppColors.textSecondary,
                        weight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Chevron is now meaningful — tapping navigates to that phase's
            // first week in the Schedule tab.
            const Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: AppColors.orange,
            ),
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
                Text(
                  label,
                  style: ZType.lbl(
                    10.5,
                    color: AppColors.textMuted,
                    letterSpacing: 1.6,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  body,
                  style: ZType.sans(
                    13.5,
                    color: AppColors.textPrimary,
                    weight: FontWeight.w500,
                    height: 1.35,
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
            style: ZType.lbl(12, color: AppColors.orange, letterSpacing: 1.5),
          ),
        if ((week.focus?.trim().isNotEmpty ?? false)) ...[
          const SizedBox(height: 2),
          Text(
            week.focus!.trim(),
            style: ZType.sans(
              12.5,
              color: AppColors.textSecondary,
              weight: FontWeight.w500,
            ),
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
            const Icon(
              Icons.bedtime_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${day.dayName} · Rest',
              style: ZType.sans(
                13,
                color: AppColors.textSecondary,
                weight: FontWeight.w600,
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
                  style: ZType.lbl(
                    13,
                    color: AppColors.textPrimary,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (day.workoutType != null && day.workoutType!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Text(
                    day.workoutType!.toUpperCase(),
                    style: ZType.lbl(
                      9,
                      color: AppColors.textMuted,
                      letterSpacing: 1.2,
                    ),
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
    // Program-authored subtitle: plain-English interval label, else the
    // authored intensity target. Additive — the volume label stays trailing.
    final subtitle = ex.intervalLabel ?? ex.intensityGuidance;
    final hasSubtitle = subtitle != null && subtitle.trim().isNotEmpty;
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    ex.name,
                    style: ZType.sans(
                      13,
                      color: AppColors.textPrimary,
                      weight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (hasSubtitle) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle.trim(),
                      style: ZType.sans(11, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
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
            const Icon(
              Icons.chevron_right_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
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
            const Icon(
              Icons.bedtime_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              '${day.dayName} · Rest',
              style: ZType.sans(
                13,
                color: AppColors.textSecondary,
                weight: FontWeight.w600,
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
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            day.dayName.toUpperCase(),
            style: ZType.lbl(
              13,
              color: AppColors.textPrimary,
              letterSpacing: 1.2,
            ),
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
                      style: ZType.sans(
                        13,
                        color: AppColors.textPrimary,
                        weight: FontWeight.w500,
                      ),
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
            const Icon(
              Icons.cloud_off_rounded,
              size: 44,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 12),
            Text(
              'We could not load this program.',
              textAlign: TextAlign.center,
              style: ZType.sans(
                14,
                color: AppColors.textSecondary,
                weight: FontWeight.w500,
              ),
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
                child: Text(
                  'Go back',
                  style: ZType.sans(
                    13,
                    color: AppColors.textMuted,
                    weight: FontWeight.w600,
                  ),
                ),
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
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      height: _extent,
      decoration: BoxDecoration(
        color: AppColors.pureBlack,
        border: overlapping || overlapsContent
            ? const Border(bottom: BorderSide(color: AppColors.hairlineStrong))
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
