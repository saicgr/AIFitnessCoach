import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/program_template.dart';
import '../../../data/providers/program_favorites_provider.dart';
import '../../../data/repositories/program_template_repository.dart';
import '../../../data/services/haptic_service.dart';

/// A designed, image-free category card for the program library (plan B.3.2).
///
/// The `programs` table has no image column and we are NOT generating 259
/// hero images for launch. Instead each card is a permanent, production-grade
/// design: a category-keyed gradient, a large category Material icon bleeding
/// off the corner, the program name, a `celebrity_name` eyebrow for celebrity
/// programs, and a small chip row (difficulty / duration / sessions).
///
/// The same widget renders a saved [ProgramTemplate] (via a [ProgramLibraryCard]
/// DTO derived from the template's `category`) so the library and the saved-
/// template list look consistent.
///
/// Named `ProgramLibraryCardTile` to avoid colliding with the [ProgramLibraryCard]
/// data model — this is the widget, that is the API DTO.
class ProgramLibraryCardTile extends StatelessWidget {
  final ProgramLibraryCard data;
  final VoidCallback onTap;

  /// When true the card lays out at full width (used in single-column lists);
  /// otherwise it sizes to its grid cell.
  final bool fullWidth;

  /// When true, a small favorite heart is overlaid top-right. Enable ONLY for
  /// catalog cards (a real library program with a non-empty id) — favoriting a
  /// template-derived card (custom/AI) is meaningless. The heart itself is the
  /// only Consumer-wrapped region so toggles don't rebuild the whole card.
  final bool showFavorite;

  const ProgramLibraryCardTile({
    super.key,
    required this.data,
    required this.onTap,
    this.fullWidth = false,
    this.showFavorite = false,
  });

  /// Whether the heart should actually render — gated to real catalog programs.
  bool get _favoritable =>
      showFavorite && data.source == 'library' && data.id.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = _ProgramCategoryTheme.forCategory(data.programCategory);
    final isCelebrity = (data.celebrityName ?? '').trim().isNotEmpty;
    // Editorial display name (migration 2283) when present, else the raw name.
    final title = data.displayName;

    return LayoutBuilder(
      builder: (context, constraints) {
        // 3-up grid cells are ~110-118px wide on an iPhone SE; the prior
        // single-column / 2-up layout was ~150-280px. Scale type + padding so
        // the card stays legible and never overflows the narrower cell.
        final narrow = constraints.maxWidth < 140;
        final pad = narrow ? 10.0 : 12.0;
        final titleSize = narrow ? 13.5 : 17.0;
        final eyebrowSize = narrow ? 9.0 : 10.5;
        final showDescription =
            !narrow && (data.description ?? '').trim().isNotEmpty;
        return _buildCard(
          theme: theme,
          isCelebrity: isCelebrity,
          title: title,
          pad: pad,
          titleSize: titleSize,
          eyebrowSize: eyebrowSize,
          showDescription: showDescription,
          narrow: narrow,
        );
      },
    );
  }

  Widget _buildCard({
    required _ProgramCategoryTheme theme,
    required bool isCelebrity,
    required String title,
    required double pad,
    required double titleSize,
    required double eyebrowSize,
    required bool showDescription,
    required bool narrow,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [theme.start, theme.end],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.end.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                // Oversized category glyph bleeding off the bottom-right —
                // gives the card visual weight without an image asset.
                Positioned(
                  right: -18,
                  bottom: -22,
                  child: Icon(
                    theme.icon,
                    size: narrow ? 96 : 128,
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                Padding(
                  // Padding + type scale come from LayoutBuilder so the card
                  // fits the 3-up grid cell (~110px) without overflow.
                  padding: EdgeInsets.all(pad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Eyebrow row — category badge, plus celebrity name
                      // when present.
                      Row(
                        children: [
                          _GlyphBadge(icon: theme.icon, compact: narrow),
                          SizedBox(width: narrow ? 6 : 8),
                          Expanded(
                            child: Text(
                              isCelebrity
                                  ? data.celebrityName!.trim().toUpperCase()
                                  : (data.programCategory ?? 'PROGRAM')
                                      .toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: eyebrowSize,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          // Reserve room so the eyebrow text never slides under
                          // the top-right favorite heart overlay.
                          if (_favoritable) const SizedBox(width: 26),
                        ],
                      ),
                      SizedBox(height: narrow ? 6 : 8),
                      // Program name — the hero text (editorial name).
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                          color: Colors.white,
                        ),
                      ),
                      if (showDescription) ...[
                        const SizedBox(height: 4),
                        // 1 line only — the height budget can't fit eyebrow +
                        // 2-line title + 2-line description + chips.
                        Text(
                          data.description!.trim(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
                      SizedBox(height: narrow ? 6 : 8),
                      // Stat chips. Wrap so they never overflow horizontally
                      // on a narrow grid cell; vertical overflow is prevented
                      // by trimming the rest of the card above. On the narrow
                      // 3-up cell we drop the difficulty chip (kept in the
                      // preview) so duration + sessions stay on one line.
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (!narrow &&
                              (data.difficultyLevel ?? '').isNotEmpty)
                            _StatChip(
                              icon: Icons.bolt_rounded,
                              label: _titleCase(data.difficultyLevel!),
                            ),
                          if (data.durationWeeks != null &&
                              data.durationWeeks! > 0)
                            _StatChip(
                              icon: Icons.event_rounded,
                              label: '${data.durationWeeks} wk',
                            ),
                          if (data.sessionsPerWeek != null &&
                              data.sessionsPerWeek! > 0)
                            _StatChip(
                              icon: Icons.repeat_rounded,
                              label: '${data.sessionsPerWeek}/wk',
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Favorite heart — only the heart is Consumer-wrapped so a
                // toggle never rebuilds the whole card. Gated to catalog cards.
                if (_favoritable)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: _CardFavoriteHeart(programId: data.id),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _titleCase(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }
}

/// The per-card favorite heart. Consumer-scoped so a toggle rebuilds only the
/// heart, not the whole card. Optimistic: flips immediately, calls the repo,
/// then invalidates both favorites providers so the source of truth re-syncs.
class _CardFavoriteHeart extends ConsumerStatefulWidget {
  final String programId;
  const _CardFavoriteHeart({required this.programId});

  @override
  ConsumerState<_CardFavoriteHeart> createState() =>
      _CardFavoriteHeartState();
}

class _CardFavoriteHeartState extends ConsumerState<_CardFavoriteHeart> {
  /// Optimistic override — null defers to the server set.
  bool? _override;
  bool _busy = false;

  bool _favored(Set<String>? ids) {
    if (_override != null) return _override!;
    return ids != null && ids.contains(widget.programId);
  }

  Future<void> _toggle() async {
    if (_busy) return;
    HapticService.selection();
    final ids = ref.read(favoriteProgramIdsProvider).valueOrNull;
    final next = !_favored(ids);
    setState(() {
      _override = next;
      _busy = true;
    });
    final repo = ref.read(programTemplateRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (next) {
        await repo.addFavorite(widget.programId);
      } else {
        await repo.removeFavorite(widget.programId);
      }
      if (!mounted) return;
      refreshProgramFavoritesW(ref);
      final fresh = await ref.read(favoriteProgramIdsProvider.future);
      if (!mounted) return;
      setState(() {
        _busy = false;
        if (fresh.contains(widget.programId) == next) _override = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _override = null;
        _busy = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not update favorites. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ids = ref.watch(favoriteProgramIdsProvider).valueOrNull;
    final fav = _favored(ids);
    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.28),
          shape: BoxShape.circle,
        ),
        child: Icon(
          fav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 16,
          color: fav ? AppColors.orange : Colors.white,
        ),
      ),
    );
  }
}

/// Small frosted glyph badge that sits in the eyebrow row.
class _GlyphBadge extends StatelessWidget {
  final IconData icon;
  final bool compact;
  const _GlyphBadge({required this.icon, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final size = compact ? 22.0 : 28.0;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(compact ? 6 : 8),
      ),
      child: Icon(icon, size: compact ? 13 : 16, color: Colors.white),
    );
  }
}

/// Frosted pill for one program stat.
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Deterministic gradient + icon per program category. A fixed map so the
/// same category always renders identically across the library grid and the
/// saved-template list.
class _ProgramCategoryTheme {
  final Color start;
  final Color end;
  final IconData icon;

  const _ProgramCategoryTheme(this.start, this.end, this.icon);

  static _ProgramCategoryTheme forCategory(String? category) {
    final key = (category ?? '').toLowerCase().trim();
    if (key.contains('celebrity')) {
      return const _ProgramCategoryTheme(
          Color(0xFFEC4899), Color(0xFF8B5CF6), Icons.movie_rounded);
    }
    if (key.contains('sport')) {
      return const _ProgramCategoryTheme(
          Color(0xFF06B6D4), Color(0xFF2563EB), Icons.sports_basketball_rounded);
    }
    if (key.contains('goal')) {
      return const _ProgramCategoryTheme(
          Color(0xFFF97316), Color(0xFFE11D48), Icons.flag_rounded);
    }
    if (key.contains('special')) {
      return const _ProgramCategoryTheme(
          Color(0xFF8B5CF6), Color(0xFF4338CA), Icons.auto_awesome_rounded);
    }
    if (key.contains('yoga')) {
      return const _ProgramCategoryTheme(
          Color(0xFF22C55E), Color(0xFF0D9488), Icons.self_improvement_rounded);
    }
    if (key.contains('stretch')) {
      return const _ProgramCategoryTheme(
          Color(0xFF14B8A6), Color(0xFF0891B2), Icons.accessibility_new_rounded);
    }
    if (key.contains('pain')) {
      return const _ProgramCategoryTheme(
          Color(0xFF38BDF8), Color(0xFF1D4ED8), Icons.healing_rounded);
    }
    if (key.contains('women') || key.contains('men') || key.contains('health')) {
      return const _ProgramCategoryTheme(
          Color(0xFFF472B6), Color(0xFF9333EA), Icons.favorite_rounded);
    }
    if (key.contains('cardio')) {
      return const _ProgramCategoryTheme(
          Color(0xFFEF4444), Color(0xFFB91C1C), Icons.directions_run_rounded);
    }
    if (key.contains('strength')) {
      return const _ProgramCategoryTheme(
          Color(0xFFF59E0B), Color(0xFFB45309), Icons.fitness_center_rounded);
    }
    // Authored / parsed / duplicated / unknown — neutral accent gradient.
    return const _ProgramCategoryTheme(
        Color(0xFF6366F1), Color(0xFF312E81), Icons.list_alt_rounded);
  }

  /// Convenience for callers that only have a saved [ProgramTemplate] — wraps
  /// its `category` so `program_library_card` can render it too.
  static ProgramLibraryCard cardFromTemplate(ProgramTemplate t) {
    return ProgramLibraryCard(
      id: t.id ?? '',
      programName: t.name,
      programCategory: t.category ?? _sourceLabel(t.source),
      description: t.description,
      difficultyLevel: null,
      durationWeeks: null,
      sessionsPerWeek: t.trainingDayCount,
    );
  }

  static String _sourceLabel(String source) {
    switch (source) {
      case 'library':
        return 'Imported';
      case 'parsed':
        return 'Pasted';
      case 'duplicated':
        return 'Copy';
      default:
        return 'Custom';
    }
  }
}

/// Public helper so other screens (template list) can derive a card DTO from
/// a saved template without re-implementing the mapping.
ProgramLibraryCard programCardFromTemplate(ProgramTemplate t) =>
    _ProgramCategoryTheme.cardFromTemplate(t);

/// A compact skeleton placeholder shown while the library loads.
class ProgramLibraryCardSkeleton extends StatelessWidget {
  const ProgramLibraryCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final base = isDark ? AppColors.elevated : AppColorsLight.elevated;
    return Container(
      decoration: BoxDecoration(
        color: base,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const SizedBox.expand(),
    );
  }
}
