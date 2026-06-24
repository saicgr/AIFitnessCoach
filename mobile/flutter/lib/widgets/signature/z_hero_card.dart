import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'signature_theme.dart';
import 'z_poster_card.dart';

/// A large featured-program card sized for a `PageView` carousel. A category-
/// tinted gradient header (with optional difficulty ribbon + category icon)
/// sits above an Anton title, a description line, a Space-Mono meta row, and a
/// primary/ghost button pair.
///
/// ```dart
/// ZHeroCard(
///   title: 'PUSH PULL LEGS',
///   description: 'A 6-week hypertrophy block built around progressive overload.',
///   category: 'Goal-Based',
///   difficultyLevel: 'Intermediate',
///   meta: '6 WEEKS · 5 DAYS/WK · GYM',
///   primaryLabel: 'START PROGRAM',
///   onPrimary: () {},
///   ghostLabel: 'PREVIEW',
///   onGhost: () {},
/// )
/// ```
class ZHeroCard extends StatelessWidget {
  /// Big Anton title (rendered uppercase-friendly; pass already-cased text).
  final String title;

  /// One-line (clamped to 2) description under the title.
  final String? description;

  /// Category — drives the header gradient + icon via [categoryTheme].
  final String? category;

  /// Program difficulty ("Beginner".."Elite"); drives the ribbon. Omitted when
  /// null/empty.
  final String? difficultyLevel;

  /// A Space-Mono meta row (e.g. "6 WEEKS · 5 DAYS/WK"). Omitted when null.
  final String? meta;

  /// Primary (solid orange) button label. Omitted when null.
  final String? primaryLabel;

  /// Primary button tap handler.
  final VoidCallback? onPrimary;

  /// Ghost (outlined) button label. Omitted when null.
  final String? ghostLabel;

  /// Ghost button tap handler.
  final VoidCallback? onGhost;

  /// Tap on the card body itself (outside the buttons).
  final VoidCallback? onTap;

  /// Card height. Defaults to 230.
  final double height;

  const ZHeroCard({
    super.key,
    required this.title,
    this.description,
    this.category,
    this.difficultyLevel,
    this.meta,
    this.primaryLabel,
    this.onPrimary,
    this.ghostLabel,
    this.onGhost,
    this.onTap,
    this.height = 230,
  });

  @override
  Widget build(BuildContext context) {
    final theme = categoryTheme(category);
    final hasDifficulty =
        difficultyLevel != null && difficultyLevel!.trim().isNotEmpty;

    final card = Container(
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tinted gradient header.
          Container(
            height: height * 0.30,
            decoration: BoxDecoration(gradient: theme.headerGradient),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                if (hasDifficulty) ZDifficultyRibbon(level: difficultyLevel!),
                const Spacer(),
                Icon(
                  theme.icon,
                  size: 24,
                  color: AppColors.textPrimary.withValues(alpha: 0.85),
                ),
              ],
            ),
          ),
          // Body.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.disp(24, color: AppColors.textPrimary),
                  ),
                  if (description != null && description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.ser(13, color: AppColors.textSecondary),
                    ),
                  ],
                  const Spacer(),
                  if (meta != null && meta!.trim().isNotEmpty) ...[
                    Text(
                      meta!.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: ZType.data(10.5, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (primaryLabel != null || ghostLabel != null)
                    Row(
                      children: [
                        if (primaryLabel != null)
                          Expanded(
                            child: _PrimaryButton(
                              label: primaryLabel!,
                              onTap: onPrimary,
                            ),
                          ),
                        if (primaryLabel != null && ghostLabel != null)
                          const SizedBox(width: 10),
                        if (ghostLabel != null)
                          Expanded(
                            child: _GhostButton(
                              label: ghostLabel!,
                              onTap: onGhost,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _PrimaryButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.orange,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: ZType.lbl(13, color: Colors.white, letterSpacing: 1.4),
        ),
      ),
    );
  }
}

class _GhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _GhostButton({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 42,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Text(
          label.toUpperCase(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              ZType.lbl(13, color: AppColors.textSecondary, letterSpacing: 1.4),
        ),
      ),
    );
  }
}

/// A "‹ • • • ›" carousel position indicator for a [PageView] driving
/// [ZHeroCard]s. The arrows are tappable (no-op when at an edge / handler
/// null); the active dot is the app accent.
///
/// ```dart
/// ZCarouselDots(
///   count: programs.length,
///   index: page,
///   onPrev: () => controller.previousPage(...),
///   onNext: () => controller.nextPage(...),
/// )
/// ```
class ZCarouselDots extends StatelessWidget {
  /// Total number of pages.
  final int count;

  /// The active page index.
  final int index;

  /// Tap on the left chevron.
  final VoidCallback? onPrev;

  /// Tap on the right chevron.
  final VoidCallback? onNext;

  const ZCarouselDots({
    super.key,
    required this.count,
    required this.index,
    this.onPrev,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    if (count <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _Arrow(glyph: '‹', enabled: index > 0, onTap: onPrev),
        const SizedBox(width: 10),
        ...List.generate(count, (i) {
          final active = i == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: active ? 18 : 6,
            height: 6,
            decoration: BoxDecoration(
              color: active ? AppColors.orange : AppColors.hairlineStrong,
              borderRadius: BorderRadius.circular(3),
            ),
          );
        }),
        const SizedBox(width: 10),
        _Arrow(glyph: '›', enabled: index < count - 1, onTap: onNext),
      ],
    );
  }
}

class _Arrow extends StatelessWidget {
  final String glyph;
  final bool enabled;
  final VoidCallback? onTap;
  const _Arrow({required this.glyph, required this.enabled, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      behavior: HitTestBehavior.opaque,
      child: Text(
        glyph,
        style: TextStyle(
          color: enabled ? AppColors.textSecondary : AppColors.hairlineStrong,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.0,
        ),
      ),
    );
  }
}
