import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/allergen.dart';
import '../../../../data/models/menu_item.dart';
import '../../../chat/widgets/fullscreen_image_viewer.dart';
import '../health_breakdown_sheet.dart';
import '../score_explain_sheet.dart';

import '../../../../l10n/generated/app_localizations.dart';
/// Single dish row in the Menu Analysis sheet. Shows:
///  • Checkbox + name + portion weight
///  • Macro row (decimal-precise, rounded only when value IS a clean
///    multiple of 5 — otherwise we show one decimal so the numbers
///    don't feel suspiciously round)
///  • Price (if present) on the right of macros
///  • Health rating pill + inflammation chip
///  • Coach tip (Gemini-generated, optional)
///  • Allergen warning banner (only if user's allergen profile hits)
///  • Portion stepper: ±0.5× buttons that scale macros live
///
/// Tapping the card toggles selection. The portion stepper is a
/// separate tap target so the portion can be adjusted without
/// toggling the checkbox.
class MenuAnalysisItemCard extends StatelessWidget {
  final MenuItem item;
  final bool isSelected;
  final UserAllergenProfile? allergenProfile;
  final ValueChanged<bool?> onToggle;
  final ValueChanged<double> onPortionChanged;

  /// L5 per-dish logging adjustment. When non-null AND the item is
  /// selected, an "Adjust" pill is rendered so the user can correct the
  /// "as served" menu macros (how-much-eaten chips + free-text refine).
  /// Null = hidden (keeps chat-flow / non-logging callers unchanged).
  final VoidCallback? onAdjust;

  /// Short summary of the adjustment already applied to this dish, e.g.
  /// "Applied: Ate ½". Shown as a hint under the Adjust pill.
  final String? adjustmentSummary;

  /// Tapping the thumbnail placeholder asks for an image to be created for
  /// this dish. Null hides the affordance (chat flow, or generation disabled).
  final VoidCallback? onRequestImage;

  /// True while [onRequestImage] is in flight for this dish.
  final bool isGeneratingImage;

  /// Share this single dish — available BEFORE logging, straight off the scan.
  final VoidCallback? onShare;

  /// Pin / edit a personal note on this dish (pre-filled with the menu's own
  /// description). Null hides the bookmark affordance.
  final VoidCallback? onEditNote;

  /// The note already pinned to this dish, if any. Replaces the menu
  /// description in the card so the user sees what will actually be saved.
  final String? pinnedNote;

  const MenuAnalysisItemCard({
    super.key,
    required this.item,
    required this.isSelected,
    required this.allergenProfile,
    required this.onToggle,
    required this.onPortionChanged,
    this.onAdjust,
    this.adjustmentSummary,
    this.onRequestImage,
    this.isGeneratingImage = false,
    this.onShare,
    this.onEditNote,
    this.pinnedNote,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary = isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    // Match allergens against the dish's REAL printed description when we
    // have one — "Iceberg Wedge Salad" says nothing about blue cheese, its
    // description does. Falls back to the coach tip only when the menu
    // printed no description.
    final allergenHits = allergenProfile == null
        ? const <String>[]
        : allergenProfile!
            .matchesForDish(
              dishName: item.name,
              detectedAllergens: item.detectedAllergens,
              dishDescription: item.description ?? item.coachTip,
            )
            .toList();

    return InkWell(
      onTap: () => onToggle(!isSelected),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.orange : AppColorsLight.orange)
                  .withValues(alpha: isDark ? 0.08 : 0.10)
              : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.grey.shade50),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.orange : AppColorsLight.orange)
                    .withValues(alpha: 0.4)
                : (isDark ? AppColors.cardBorder : Colors.grey.shade200),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isSelected,
                  onChanged: onToggle,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                ),
                _DishThumbnail(
                  item: item,
                  isGenerating: isGeneratingImage,
                  onRequestImage: onRequestImage,
                  isDark: isDark,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (onEditNote != null)
                            _IconAction(
                              icon: pinnedNote != null && pinnedNote!.isNotEmpty
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              tooltip: pinnedNote != null && pinnedNote!.isNotEmpty
                                  ? 'Edit your note'
                                  : 'Save a note with this dish',
                              active: pinnedNote != null && pinnedNote!.isNotEmpty,
                              onTap: onEditNote!,
                              isDark: isDark,
                            ),
                          if (onShare != null)
                            _IconAction(
                              icon: Icons.ios_share_rounded,
                              tooltip: 'Share this dish',
                              onTap: onShare!,
                              isDark: isDark,
                            ),
                          if (item.rating != null)
                            _RatingPill(
                              rating: item.rating!,
                              onTap: () => ScoreExplainSheet.show(
                                context,
                                kind: ScoreKind.rating,
                                value: item.rating,
                                reason: item.ratingReason ?? item.coachTip,
                              ),
                            ),
                        ],
                      ),
                      // The menu's own words for this dish — the thing that
                      // makes a logged "Bacon & Eggs" still mean something in
                      // three months. A pinned note replaces it (that's the
                      // text that will actually be saved).
                      if ((pinnedNote != null && pinnedNote!.isNotEmpty) ||
                          item.description != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: _DishDescription(
                            text: (pinnedNote != null && pinnedNote!.isNotEmpty)
                                ? pinnedNote!
                                : item.description!,
                            isNote: pinnedNote != null && pinnedNote!.isNotEmpty,
                            color: textSecondary,
                            accent: isDark ? AppColors.orange : AppColorsLight.orange,
                          ),
                        ),
                      if (item.includedChoices != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.add_circle_outline,
                                  size: 12,
                                  color: isDark
                                      ? AppColors.orange
                                      : AppColorsLight.orange),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  item.includedChoices!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? AppColors.orange
                                        : AppColorsLight.orange,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (item.weightG != null || item.amount != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            _subtitlePortion(item),
                            style: TextStyle(fontSize: 11, color: textMuted),
                          ),
                        ),
                      // Horizontally-scrollable Health Strip — one labeled
                      // pill per signal (inflammation / blood sugar / FODMAP /
                      // added sugar / ultra-processed). Tap a pill → scoped
                      // explain sheet; tap the trailing "Full breakdown" pill
                      // → HealthBreakdownSheet with every signal at once.
                      // Collapses to "✨ All scores green" when nothing is
                      // worth flagging so clean dishes read clean.
                      if (_HealthStrip.hasAnySignal(item)) ...[
                        const SizedBox(height: 6),
                        _HealthStrip(item: item),
                      ],
                      const SizedBox(height: 6),
                      _MacroLine(item: item, color: textSecondary),
                      if (item.coachTip != null && item.coachTip!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.auto_awesome, size: 12, color: AppColors.orange),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.coachTip!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (allergenHits.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _AllergenWarning(matches: allergenHits),
                      ],
                      const SizedBox(height: 6),
                      _PortionStepper(
                        item: item,
                        onChanged: onPortionChanged,
                      ),
                      // L5 — per-dish "as eaten" adjustment. Only when the
                      // dish is selected for logging and the caller wired
                      // up onAdjust (the log-meal / nutrition flows do; the
                      // chat flow leaves it null).
                      if (onAdjust != null && isSelected) ...[
                        const SizedBox(height: 6),
                        _AdjustPill(
                          summary: adjustmentSummary,
                          onTap: onAdjust!,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Portion descriptor only — no inflammation copy (that moved to its own
  /// tappable chip on the ScoreChipRow below).
  static String _subtitlePortion(MenuItem item) {
    final parts = <String>[];
    if (item.weightG != null) {
      parts.add('${item.scaledWeightG!.round()} g');
    }
    if (item.amount != null && item.amount!.isNotEmpty) {
      parts.add(item.amount!);
    }
    return parts.join(' · ');
  }

}

/// 44×44 dish thumbnail at the head of the row.
///
/// Three states, and the empty one matters most: when no image resolved we
/// show the dish's initials, NOT a stock photo of something else. Tapping the
/// placeholder is what spends money (one generation), so it's always an
/// explicit user action — never a side effect of scrolling.
class _DishThumbnail extends StatelessWidget {
  final MenuItem item;
  final bool isGenerating;
  final VoidCallback? onRequestImage;
  final bool isDark;

  const _DishThumbnail({
    required this.item,
    required this.isGenerating,
    required this.onRequestImage,
    required this.isDark,
  });

  static const double _size = 44;

  @override
  Widget build(BuildContext context) {
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    final url = item.dishImageUrl;

    Widget shell(Widget child, {VoidCallback? onTap}) {
      final box = Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.cardBorder : Colors.grey.shade300,
            width: 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      );
      if (onTap == null) return box;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: box,
      );
    }

    if (url != null && url.isNotEmpty) {
      return shell(
        Image.network(
          url,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          // A dead image URL falls back to initials rather than Flutter's
          // broken-image glyph.
          errorBuilder: (_, __, ___) => _initials(muted),
          loadingBuilder: (_, child, progress) =>
              progress == null ? child : _initials(muted),
        ),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FullscreenImageViewer(
              imageUrl: url,
              heroTag: 'dish-${item.id}',
              title: item.name,
            ),
          ),
        ),
      );
    }

    if (isGenerating) {
      return shell(
        Center(
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          ),
        ),
      );
    }

    return shell(
      Stack(
        fit: StackFit.expand,
        children: [
          _initials(muted),
          if (onRequestImage != null)
            Positioned(
              right: 2,
              bottom: 2,
              child: Icon(Icons.auto_awesome, size: 11, color: accent),
            ),
        ],
      ),
      onTap: onRequestImage,
    );
  }

  Widget _initials(Color muted) {
    final words = item.name.trim().split(RegExp(r'\s+'));
    final letters = words
        .where((w) => w.isNotEmpty && RegExp(r'[A-Za-z]').hasMatch(w[0]))
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();
    return Center(
      child: Text(
        letters.isEmpty ? '·' : letters,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: muted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// The menu's printed description (or the user's pinned note), collapsed to
/// two lines and expandable in place — a Disney-style menu description runs
/// long and truncating it permanently would defeat the point of capturing it.
class _DishDescription extends StatefulWidget {
  final String text;
  final bool isNote;
  final Color color;
  final Color accent;

  const _DishDescription({
    required this.text,
    required this.isNote,
    required this.color,
    required this.accent,
  });

  @override
  State<_DishDescription> createState() => _DishDescriptionState();
}

class _DishDescriptionState extends State<_DishDescription> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: 11.5,
      height: 1.3,
      color: widget.color,
    );
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.isNote) ...[
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.bookmark_rounded, size: 11, color: widget.accent),
            ),
            const SizedBox(width: 4),
          ],
          Expanded(
            child: Text(
              widget.text,
              style: style,
              maxLines: _expanded ? null : 2,
              overflow: _expanded ? null : TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small square icon button used for the per-dish note + share affordances.
class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isDark;
  final bool active;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    required this.isDark,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    final muted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Icon(icon, size: 16, color: active ? accent : muted),
        ),
      ),
    );
  }
}

/// L5 — compact "Adjust" affordance shown on a selected menu dish. Tapping
/// it opens the per-dish adjustment sheet (how-much-eaten chips + free-text
/// refine). When an adjustment is already applied, the chip turns accent-
/// colored and shows a one-line summary beneath it ("Applied: Ate ½").
class _AdjustPill extends StatelessWidget {
  final String? summary;
  final VoidCallback onTap;

  const _AdjustPill({required this.summary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? AppColors.orange : AppColorsLight.orange;
    final textMuted =
        isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final adjusted = summary != null && summary!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: accent.withValues(alpha: adjusted ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(adjusted ? Icons.check_circle : Icons.tune_rounded,
                      size: 13, color: accent),
                  const SizedBox(width: 5),
                  Text(
                    adjusted ? AppLocalizations.of(context).menuAnalysisItemAdjusted : AppLocalizations.of(context).menuAnalysisItemAdjustWhatYouAte,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (adjusted)
          Padding(
            padding: const EdgeInsets.only(top: 3, left: 2),
            child: Text(
              summary!,
              style: TextStyle(
                fontSize: 10,
                color: textMuted,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

/// Horizontally-scrollable row of labeled health-signal pills.
///
/// One pill per signal (inflammation / blood sugar / FODMAP / added sugar /
/// ultra-processed). Each pill shows emoji + short label + value and is
/// colored green / amber / red by severity. Tap a pill → [ScoreExplainSheet]
/// scoped to that signal; tap the trailing "Full breakdown" pill →
/// [HealthBreakdownSheet] with every signal in one sheet.
///
/// Design decisions (see feedback_multiscore_display.md):
///   • LABELED, not dots. Users must know what each pill means without
///     tapping. Unlabeled dots were rejected.
///   • Horizontal scroll, not Wrap. Card height stays constant regardless
///     of how many signals a dish has.
///   • "All clean" collapse. If every rendered pill would be green we
///     render a single "✨ All scores green" badge instead — reduces noise
///     on healthy dishes and draws attention to problem dishes.
///   • ultra-processed pill ONLY when true (no point bragging about
///     not being processed).
///   • Inflammation tap passes structured `triggers` (not `ratingReason`)
///     so the Score Explain sheet shows ingredient drivers — the core
///     correctness fix.
class _HealthStrip extends StatelessWidget {
  final MenuItem item;
  const _HealthStrip({required this.item});

  /// True if we have ANY signal worth rendering. Cheap gate used by the
  /// parent card to skip the strip entirely when Gemini dropped everything.
  static bool hasAnySignal(MenuItem i) =>
      i.inflammationScore != null ||
      i.glycemicLoad != null ||
      i.fodmapRating != null ||
      i.addedSugarG != null ||
      i.isUltraProcessed == true;

  @override
  Widget build(BuildContext context) {
    final pills = _buildPills(context);
    if (pills.isEmpty) return const SizedBox.shrink();

    // Collapse to a single "All clean" badge when every visible pill is
    // green. Avoids drowning the card in 4+ green pills for healthy dishes.
    final allGreen = pills.every((p) => p.severity == _PillSeverity.good);
    if (allGreen && pills.length >= 3) {
      return _AllCleanBadge(onTap: () => _openBreakdown(context));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          for (final p in pills) ...[
            p.widget,
            const SizedBox(width: 6),
          ],
          // Trailing "Full breakdown →" opens the all-signals sheet. Kept
          // at the end so horizontal scroll reveals it naturally.
          _BreakdownPill(onTap: () => _openBreakdown(context)),
        ],
      ),
    );
  }

  void _openBreakdown(BuildContext context) {
    HealthBreakdownSheet.show(context, item: item);
  }

  List<_PillSpec> _buildPills(BuildContext context) {
    final specs = <_PillSpec>[];

    // Inflammation — always informative. Tap passes structured triggers.
    if (item.inflammationScore != null) {
      final s = item.inflammationScore!;
      final sev = s >= 7
          ? _PillSeverity.bad
          : s >= 4
              ? _PillSeverity.mid
              : _PillSeverity.good;
      specs.add(_PillSpec(
        severity: sev,
        widget: _HealthPill(
          emoji: '🔥',
          label: AppLocalizations.of(context).menuFilterInflammation,
          value: '$s/10',
          severity: sev,
          onTap: () => ScoreExplainSheet.show(
            context,
            kind: ScoreKind.inflammation,
            value: s,
            triggers: item.inflammationTriggers,
          ),
        ),
      ));
    }

    // Blood sugar (glycemic load).
    if (item.glycemicLoad != null) {
      final gl = item.glycemicLoad!;
      final sev = gl >= 20
          ? _PillSeverity.bad
          : gl >= 10
              ? _PillSeverity.mid
              : _PillSeverity.good;
      specs.add(_PillSpec(
        severity: sev,
        widget: _HealthPill(
          emoji: '🩸',
          label: AppLocalizations.of(context).menuFilterBloodSugar,
          value: '$gl',
          severity: sev,
          onTap: () => ScoreExplainSheet.show(
            context,
            kind: ScoreKind.glycemicLoad,
            value: gl,
          ),
        ),
      ));
    }

    // FODMAP.
    if (item.fodmapRating != null) {
      final r = item.fodmapRating!;
      final sev = r == 'high'
          ? _PillSeverity.bad
          : r == 'medium'
              ? _PillSeverity.mid
              : _PillSeverity.good;
      specs.add(_PillSpec(
        severity: sev,
        widget: _HealthPill(
          emoji: '🧡',
          label: AppLocalizations.of(context).menuAnalysisItemFodmap,
          value: _titleCase(r),
          severity: sev,
          onTap: () => ScoreExplainSheet.show(
            context,
            kind: ScoreKind.fodmap,
            value: r,
            reason: item.fodmapReason,
          ),
        ),
      ));
    }

    // Added sugar (grams per serving). WHO daily limit = 25 g.
    if (item.addedSugarG != null) {
      final g = item.addedSugarG!;
      final sev = g >= 15
          ? _PillSeverity.bad
          : g >= 5
              ? _PillSeverity.mid
              : _PillSeverity.good;
      specs.add(_PillSpec(
        severity: sev,
        widget: _HealthPill(
          emoji: '🍬',
          label: AppLocalizations.of(context).menuAnalysisItemAddedSugar,
          value: _fmtSugar(g),
          severity: sev,
          onTap: () => ScoreExplainSheet.show(
            context,
            kind: ScoreKind.addedSugar,
            value: g,
          ),
        ),
      ));
    }

    // Ultra-processed — only when true. No pill for "not processed".
    if (item.isUltraProcessed == true) {
      specs.add(_PillSpec(
        severity: _PillSeverity.bad,
        widget: _HealthPill(
          emoji: '🏭',
          label: AppLocalizations.of(context).scoreExplainUltraProcessed,
          value: AppLocalizations.of(context).commonYes,
          severity: _PillSeverity.bad,
          onTap: () => ScoreExplainSheet.show(
            context,
            kind: ScoreKind.ultraProcessed,
            value: true,
          ),
        ),
      ));
    }

    return specs;
  }

  static String _titleCase(String s) =>
      s.isEmpty ? s : (s[0].toUpperCase() + s.substring(1));

  static String _fmtSugar(double g) {
    if ((g - g.roundToDouble()).abs() < 0.05) return '${g.round()} g';
    return '${g.toStringAsFixed(1)} g';
  }
}

enum _PillSeverity { good, mid, bad }

class _PillSpec {
  final _PillSeverity severity;
  final Widget widget;
  _PillSpec({required this.severity, required this.widget});
}

/// Individual labeled pill: `[emoji] [label] [value]` on a severity-colored
/// background. Kept visually distinct from filter chips (rounder, brighter
/// border) so users read it as "health signal" not "filter".
class _HealthPill extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final _PillSeverity severity;
  final VoidCallback onTap;
  const _HealthPill({
    required this.emoji,
    required this.label,
    required this.value,
    required this.severity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = _severityColor(severity);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: c.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: c.withValues(alpha: 0.45), width: 0.8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(emoji, style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: c,
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: c.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: c,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Color _severityColor(_PillSeverity s) {
    switch (s) {
      case _PillSeverity.good: return AppColors.success;
      case _PillSeverity.mid: return AppColors.orange;
      case _PillSeverity.bad: return AppColors.error;
    }
  }
}

class _BreakdownPill extends StatelessWidget {
  final VoidCallback onTap;
  const _BreakdownPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // White-alpha is invisible on a light background — flip to black-alpha
    // in light mode so the pill fill/border actually read.
    final tintBase = isDark ? Colors.white : Colors.black;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tintBase.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: tintBase.withValues(alpha: 0.18),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppLocalizations.of(context).menuAnalysisItemFullBreakdown,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: textSecondary,
                ),
              ),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right, size: 14, color: textMuted),
            ],
          ),
        ),
      ),
    );
  }
}

class _AllCleanBadge extends StatelessWidget {
  final VoidCallback onTap;
  const _AllCleanBadge({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.success.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✨', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 5),
              Text(
                AppLocalizations.of(context).menuAnalysisItemAllScoresGreen,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 14, color: AppColors.success.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final MenuItem item;
  final Color color;
  const _MacroLine({required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    // A bill line whose dish name couldn't be identified has no nutrition.
    // Saying so is the only honest option — rendering "0 cal" would read as
    // a real (and very wrong) estimate.
    if (item.nutritionUnknown) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.help_outline_rounded, size: 13, color: color),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              "Couldn't estimate nutrition — tap Adjust to describe it",
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: color,
              ),
            ),
          ),
          if (item.price != null) ...[
            const SizedBox(width: 8),
            Text(
              _formatPrice(item.price!, item.currency),
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: color,
              ),
            ),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 2,
      children: [
        _macro(item.scaledCalories, 'cal', AppColors.coral),
        _macro(item.scaledProteinG, 'g P', AppColors.macroProtein),
        _macro(item.scaledCarbsG, 'g C', AppColors.macroCarbs),
        _macro(item.scaledFatG, 'g F', AppColors.macroFat),
        if (item.price != null)
          Text(
            _formatPrice(item.price!, item.currency),
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
      ],
    );
  }

  /// Preserve decimal precision when the value isn't a clean multiple of 5
  /// so Gemini's numbers don't read as suspiciously round.
  static Widget _macro(double value, String unit, Color c) {
    final isClean = (value - value.round()).abs() < 0.05 && value.round() % 5 == 0;
    final text = isClean
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: text,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w800, color: c,
            ),
          ),
          TextSpan(
            text: ' $unit',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600,
              color: c.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatPrice(double price, String? currency) {
    final symbol = switch (currency) {
      'USD' || null => '\$',
      'EUR' => '€',
      'GBP' => '£',
      'INR' => '₹',
      'JPY' => '¥',
      _ => (currency.length <= 3 ? '$currency ' : '\$'),
    };
    return '$symbol${price.toStringAsFixed(2)}';
  }
}

class _RatingPill extends StatelessWidget {
  final String rating;
  final VoidCallback? onTap;
  const _RatingPill({required this.rating, this.onTap});
  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (rating) {
      case 'green':
        color = AppColors.success;
        label = 'Good';
        break;
      case 'yellow':
        color = AppColors.orange;
        label = 'Moderate';
        break;
      case 'red':
        color = AppColors.error;
        // "Skip" matches the AI recommendation copy ("Skip; contains...")
        // already rendered in the card body. "Limit" was ambiguous — could
        // be read as "eat a small amount" when the intent here is "avoid".
        label = 'Skip';
        break;
      default:
        return const SizedBox.shrink();
    }
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700, color: color,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 3),
            Icon(Icons.info_outline, size: 10, color: color.withValues(alpha: 0.7)),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: pill,
      ),
    );
  }
}

class _AllergenWarning extends StatelessWidget {
  final List<String> matches;
  const _AllergenWarning({required this.matches});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.4), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_rounded, size: 14, color: AppColors.error),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Contains ${matches.join(' · ')}',
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Portion control with two linked affordances:
///   • Discrete multiplier stepper (−/1×/+) — quick half/full/double taps.
///   • Tap-to-edit weight in grams — morphs the "180 g" chip into a TextField
///     so the user can type exactly what they're eating. Saves on ✓.
///
/// Per feedback_inline_editing.md: prefer tap-to-edit over modal sheets when
/// the value is already visible on screen. When the dish has no baseline
/// `weightG`, the grams editor hides and we fall back to multiplier-only.
class _PortionStepper extends StatefulWidget {
  final MenuItem item;
  final ValueChanged<double> onChanged;
  const _PortionStepper({required this.item, required this.onChanged});

  static const _steps = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  State<_PortionStepper> createState() => _PortionStepperState();
}

class _PortionStepperState extends State<_PortionStepper> {
  bool _editing = false;
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startEdit() {
    final current = widget.item.scaledWeightG?.round();
    _controller.text = current == null ? '' : current.toString();
    _controller.selection = TextSelection(baseOffset: 0, extentOffset: _controller.text.length);
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
  }

  void _saveEdit() {
    final grams = double.tryParse(_controller.text.trim());
    if (grams != null && grams > 0) {
      final mult = widget.item.multiplierForWeight(grams);
      if (mult != null) widget.onChanged(mult);
    }
    setState(() => _editing = false);
  }

  void _cancelEdit() {
    setState(() => _editing = false);
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final hasWeight = item.weightG != null && item.weightG! > 0;
    final steps = _PortionStepper._steps;
    final idx = steps.indexWhere((s) => (s - item.portionMultiplier).abs() < 0.01);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          AppLocalizations.of(context).menuAnalysisItemPortion,
          style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textMuted : AppColorsLight.textMuted,
          ),
        ),
        const SizedBox(width: 6),
        _roundBtn(Icons.remove, () {
          if (idx > 0) widget.onChanged(steps[idx - 1]);
        }),
        Container(
          constraints: const BoxConstraints(minWidth: 40),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            _formatMultiplier(item.portionMultiplier),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
        _roundBtn(Icons.add, () {
          if (idx >= 0 && idx < steps.length - 1) widget.onChanged(steps[idx + 1]);
        }),
        if (hasWeight) ...[
          const SizedBox(width: 10),
          Container(width: 1, height: 14, color: (isDark ? AppColors.cardBorder : Colors.grey.shade300)),
          const SizedBox(width: 10),
          if (_editing)
            _weightEditor(isDark)
          else
            _weightChip(isDark, item.scaledWeightG!.round()),
        ],
      ],
    );
  }

  Widget _weightChip(bool isDark, int grams) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _startEdit,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.orange.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: AppColors.orange.withValues(alpha: 0.35), width: 0.7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$grams g',
                style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange,
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.edit_outlined, size: 11, color: AppColors.orange.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _weightEditor(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.orange, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              onSubmitted: (_) => _saveEdit(),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange),
              decoration: const InputDecoration(
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 2),
                border: InputBorder.none,
                suffixText: 'g',
                suffixStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange),
              ),
            ),
          ),
          InkWell(
            onTap: _cancelEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.close, size: 14, color: AppColors.orange),
            ),
          ),
          InkWell(
            onTap: _saveEdit,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 2),
              child: Icon(Icons.check, size: 14, color: AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatMultiplier(double m) {
    if (m == 0.5) return '½×';
    if (m == 0.75) return '¾×';
    if (m == 1.0) return '1×';
    if (m == 1.25) return '1¼×';
    if (m == 1.5) return '1½×';
    if (m == 2.0) return '2×';
    return '${m.toStringAsFixed(2)}×';
  }

  Widget _roundBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.orange.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 14, color: AppColors.orange),
      ),
    );
  }
}
