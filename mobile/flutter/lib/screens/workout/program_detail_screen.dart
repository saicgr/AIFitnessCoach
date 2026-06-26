import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/program_template.dart';
import '../../data/providers/program_favorites_provider.dart';
import '../../data/repositories/program_template_repository.dart';
import '../../data/services/haptic_service.dart';
import '../../widgets/signature/signature.dart';
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
/// Full-bleed diagonal-striped header (no image), back ‹ + favorite heart, a
/// difficulty pill, a huge Anton title + subtitle; three big stat tiles
/// (WEEKS / PER WEEK / MINUTES); OVERVIEW (phase blocks + who-for / progression
/// / equipment) and SCHEDULE (the real day-by-day) tabs; a sticky bottom bar
/// with a real JOINED count (hidden when null/0 — no fake numbers) + a big
/// orange START PROGRAM button that hands off to the existing Start flow.
///
/// Opens either from a [card] (tapped in the library — instant header render
/// while the full detail loads) or a bare [programId] (deep-link). Either way
/// it fetches `GET /library/{id}` for the editorial card (phases/joined_count)
/// + the normalized sample week.
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _card = widget.card;
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
        // Keep the override until the invalidated set re-resolves to it, so the
        // heart doesn't flicker; clear it once it matches server truth below.
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
    final future = ref.read(programTemplateRepositoryProvider).getLibraryDetail(id);
    _detail = future;
    // Upgrade the header card to the editorial-complete one once it lands.
    future.then((result) {
      if (!mounted) return;
      setState(() => _card = result.card);
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

  @override
  Widget build(BuildContext context) {
    final card = _card;
    return Scaffold(
      backgroundColor: AppColors.pureBlack,
      body: card == null
          // No card yet (pure deep-link, first frame) — load the header lazily.
          ? FutureBuilder<({ProgramLibraryCard card, ProgramTemplate sampleWeek})>(
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
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(card)),
              SliverToBoxAdapter(child: _buildStatTiles(card)),
              SliverToBoxAdapter(child: _buildTabBar()),
              SliverFillRemaining(
                hasScrollBody: true,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(card),
                    _buildScheduleTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
        _buildBottomBar(card),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Header — full-bleed diagonal-striped panel.
  // -------------------------------------------------------------------------

  Widget _buildHeader(ProgramLibraryCard card) {
    final theme = categoryTheme(card.programCategory);
    final hasDifficulty =
        card.difficultyLevel != null && card.difficultyLevel!.trim().isNotEmpty;
    final subtitle = (card.tagline?.trim().isNotEmpty == true)
        ? card.tagline!.trim()
        : (card.programCategory ?? '').trim();

    return SizedBox(
      height: 280,
      child: Stack(
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
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row — back ‹ + favorite heart.
                  Row(
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: _back,
                      ),
                      const Spacer(),
                      Builder(builder: (context) {
                        final fav = _isFavoritedWatched();
                        return _CircleIconButton(
                          icon: fav
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          tint: fav ? AppColors.orange : null,
                          onTap: _toggleFavorite,
                        );
                      }),
                    ],
                  ),
                  const Spacer(),
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
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Stat tiles — WEEKS / PER WEEK / MINUTES.
  // -------------------------------------------------------------------------

  Widget _buildStatTiles(ProgramLibraryCard card) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              value: card.durationWeeks?.toString() ?? '—',
              label: 'WEEKS',
              // The most relevant stat (length) gets the orange accent.
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
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text('PHASES',
            style: ZType.lbl(13,
                color: AppColors.textPrimary, letterSpacing: 1.8)),
        const SizedBox(height: 12),
        for (final phase in phases) _PhaseBlock(phase: phase),
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
  // SCHEDULE tab — the real day-by-day from the sample week.
  // -------------------------------------------------------------------------

  Widget _buildScheduleTab() {
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Wrap(
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
            const SizedBox(height: 14),
            for (final day in template.days) _ScheduleDayTile(day: day),
          ],
        );
      },
    );
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

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? tint;

  const _CircleIconButton({required this.icon, required this.onTap, this.tint});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Icon(icon, size: 17, color: tint ?? AppColors.textPrimary),
      ),
    );
  }
}

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
    // 45° lines sweeping across the full panel (offset by height so the
    // diagonal covers the whole rect, not just the square).
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
// Stat tile.
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
  const _PhaseBlock({required this.phase});

  @override
  Widget build(BuildContext context) {
    final weekLabel = phase.weekLabel;
    final subtitle = phase.subtitle?.trim();
    return Container(
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
          // Numbered orange index.
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
                if (weekLabel != null || (subtitle != null && subtitle.isNotEmpty)) ...[
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
          const Icon(Icons.chevron_right_rounded,
              size: 20, color: AppColors.textMuted),
        ],
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
// Schedule day tile (mirrors the old preview-sheet day row).
// ===========================================================================

class _ScheduleDayTile extends StatelessWidget {
  final ProgramDay day;
  const _ScheduleDayTile({required this.day});

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
