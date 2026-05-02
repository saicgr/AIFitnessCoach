import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../shareable_catalog.dart';
import '../shareable_data.dart';

/// 3-tier selector that drives the unified share sheet:
///
///   [1:1]  [4:5]  [9:16]              ← Tier 1: Aspect
///   [thumb][thumb][thumb] …            ← Tier 2: TAPPABLE THUMBNAIL STRIP
///                                          (replaces old subcategory pills —
///                                          ports the demo's gallery UX so
///                                          users see every template's real
///                                          preview at thumb scale)
///   [Classic] [Rich] [Edit] [Play]    ← Tier 3: Category
///
/// Recently-used templates carry an orange `RECENT` badge in the top-right
/// of their thumbnail. The list of recent IDs flows in via [recentTemplateIds]
/// from the parent sheet state.
///
/// Disabled templates (not available for current data) render greyed
/// with a lock overlay and a snackbar on tap.
class NestedPillSelector extends StatelessWidget {
  final Shareable data;
  final ShareableAspect aspect;
  final ShareableCategory category;
  final ShareableTemplate template;
  final bool ownsCosmetic;
  final List<String> recentTemplateIds;
  final bool showWatermark;
  final ValueChanged<ShareableAspect> onAspectChanged;
  final ValueChanged<ShareableCategory> onCategoryChanged;
  final ValueChanged<ShareableTemplate> onTemplateChanged;

  const NestedPillSelector({
    super.key,
    required this.data,
    required this.aspect,
    required this.category,
    required this.template,
    required this.onAspectChanged,
    required this.onCategoryChanged,
    required this.onTemplateChanged,
    this.ownsCosmetic = false,
    this.recentTemplateIds = const [],
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    final available = ShareableCatalog.availableFor(
      data,
      ownsCosmetic: ownsCosmetic,
    );
    final categories = ShareableCatalog.categoriesFor(
      data,
      ownsCosmetic: ownsCosmetic,
    );
    final inCategory = ShareableCatalog.all()
        .where((s) => s.category == category)
        .toList();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          _aspectRow(context),
          const SizedBox(height: 8),
          _subcategoryRow(context, inCategory, available),
          const SizedBox(height: 8),
          _categoryRow(context, categories),
        ],
      ),
    );
  }

  Widget _aspectRow(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: ShareableAspect.values.map((a) {
          final selected = a == aspect;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _Pill(
              label: a.label,
              selected: selected,
              accent: data.accentColor,
              onTap: () {
                HapticFeedback.selectionClick();
                onAspectChanged(a);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Tier 2 — horizontal thumbnail strip. Each tile renders the real
  /// template at design size, scaled down via `FittedBox(BoxFit.cover)`.
  /// Selected tile carries an orange border, recently-used tiles carry
  /// a small `RECENT` badge, and unavailable templates are greyed with
  /// a lock overlay (preserving the prior availability-gate semantics).
  Widget _subcategoryRow(
    BuildContext context,
    List<ShareableTemplateSpec> inCategory,
    List<ShareableTemplateSpec> available,
  ) {
    final accent = data.accentColor;
    return SizedBox(
      height: 88,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: inCategory.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final spec = inCategory[i];
          final isAvailable =
              available.any((s) => s.template == spec.template);
          final isSelected = spec.template == template;
          final isRecent = recentTemplateIds.contains(spec.template.name) &&
              !isSelected;
          final tileSize = aspect.size;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (!isAvailable) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Not enough data yet — log more to unlock',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              onTemplateChanged(spec.template);
            },
            child: SizedBox(
              width: 64,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? accent
                            : Colors.white.withValues(alpha: 0.15),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            clipBehavior: Clip.hardEdge,
                            child: SizedBox(
                              width: tileSize.width,
                              height: tileSize.height,
                              child: spec.builder(data, false),
                            ),
                          ),
                        ),
                        if (!isAvailable)
                          Positioned.fill(
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.55),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.lock_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        if (isRecent)
                          Positioned(
                            top: 3,
                            right: 3,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: accent,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: const Text(
                                'RECENT',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    spec.name,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? accent
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryRow(
    BuildContext context,
    List<ShareableCategory> categories,
  ) {
    // Designed to fit on a single row without horizontal scrolling: the
    // text pills (Cards / Editorial / Playful / Graph) are compact, and
    // the Spark + Studio pills are icon-only circles (~36dp each). Wrap
    // is the safety net for narrow phones — pills flow to a second row
    // instead of clipping if anything overflows.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: categories.map((c) {
          final selected = c == category;
          return _Pill(
            label: c.iconOnly ? '' : c.label,
            selected: selected,
            compact: true,
            accent: data.accentColor,
            leadingIcon: c.icon,
            iconOnly: c.iconOnly,
            onTap: () {
              HapticFeedback.selectionClick();
              onCategoryChanged(c);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool selected;
  final bool disabled;
  final bool compact;
  final bool iconOnly;
  final Widget? trailing;
  final IconData? leadingIcon;
  final VoidCallback onTap;
  final Color? accent;

  const _Pill({
    required this.label,
    required this.onTap,
    this.selected = false,
    this.disabled = false,
    this.compact = false,
    this.iconOnly = false,
    this.trailing,
    this.leadingIcon,
    this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Selected pill uses the share asset's accent color so each pill
    // row visually echoes the template's identity (orange workout vs
    // purple PR vs green streak, etc.) instead of being uniform white.
    // If accent is null OR effectively white/black (low chroma), fall
    // back to a vivid brand color so the selection is never invisible
    // on the matching surface.
    Color resolveActive(Color? a) {
      if (a == null) return const Color(0xFF06B6D4); // AppColors.cyan
      // HSL chroma proxy: avg distance from grayscale axis. White (1,1,1)
      // and black (0,0,0) score 0; saturated colors score higher.
      final r = a.r, g = a.g, b = a.b;
      final maxC = [r, g, b].reduce((x, y) => x > y ? x : y);
      final minC = [r, g, b].reduce((x, y) => x < y ? x : y);
      final chroma = maxC - minC;
      if (chroma < 0.08) return const Color(0xFF06B6D4);
      return a;
    }
    final activeBg = resolveActive(accent);
    final activeFg = ThemeData.estimateBrightnessForColor(activeBg) ==
            Brightness.dark
        ? Colors.white
        : Colors.black;
    final restBg =
        isDark ? Colors.white.withValues(alpha: 0.10) : Colors.black.withValues(alpha: 0.06);
    final restFg = isDark
        ? Colors.white.withValues(alpha: 0.85)
        : Colors.black.withValues(alpha: 0.75);
    final disabledFg =
        (isDark ? Colors.white : Colors.black).withValues(alpha: 0.35);

    return Opacity(
      opacity: disabled ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: iconOnly
              ? const EdgeInsets.all(7)
              : EdgeInsets.symmetric(
                  horizontal: compact ? 10 : 14,
                  vertical: compact ? 6 : 8,
                ),
          decoration: BoxDecoration(
            color: selected ? activeBg : restBg,
            borderRadius: BorderRadius.circular(iconOnly ? 999 : 20),
            shape: BoxShape.rectangle,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: activeBg.withValues(alpha: 0.45),
                      blurRadius: 12,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: iconOnly
              ? Icon(
                  leadingIcon,
                  size: 18,
                  color: selected
                      ? activeFg
                      : (disabled ? disabledFg : restFg),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        size: 14,
                        color: selected
                            ? activeFg
                            : (disabled ? disabledFg : restFg),
                      ),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        color: selected
                            ? activeFg
                            : (disabled ? disabledFg : restFg),
                        fontSize: compact ? 12 : 13,
                        fontWeight:
                            selected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0.2,
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 4),
                      IconTheme(
                        data: IconThemeData(
                          color: disabled ? disabledFg : restFg,
                          size: 12,
                        ),
                        child: trailing!,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}
