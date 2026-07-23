import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/theme_colors.dart';
import '../../../data/models/nutrition.dart';
import '../../../utils/time_formatters.dart';
import '../../../widgets/fullscreen_image_viewer.dart';
import '../../../widgets/glass_sheet.dart';

/// Signature-v2 food-detail sheet — what a tapped logged food/meal opens.
///
/// Mirrors the `signature-v2.html` FOOD DETAIL frame: a floating render hero
/// (food photo if present, else a tasteful emoji + soft shadow), title +
/// editable serving on a dotted underline, a big Anton kcal numeral over
/// semantic P/C/F dots, a micros mini-row, real quality chips (Health /
/// Inflammation / GL), explicit provenance ("LOGGED VIA … · time") with any
/// stored thumbnails, the italic AI-feedback line, and an action grid —
/// Edit / Duplicate / Remove / Add to Saved + one orange "Log again".
///
/// All behaviors delegate to callbacks supplied by [LoggedMealsSection]
/// (`showFoodDetailSheet`) so the existing, audited flows are reused — edit
/// re-derives macros from the new weight (the per-item / whole-meal portion
/// sheets), duplicate / log-again copy the log, remove deletes via the
/// existing handler, and the health / inflammation chips open the shared
/// `ScoreExplainSheet`.
class FoodDetailSheet extends StatelessWidget {
  final FoodLog meal;

  /// Provenance / serving label, e.g. "1 bowl · 420 g" (derived from the meal).
  final String servingLabel;

  /// Tasteful fallback render when the meal has no photo (an emoji).
  final String renderEmoji;

  // ── Behaviors (all wired from the owning LoggedMealsSection) ──
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onAddToSaved;
  final VoidCallback onLogAgain;
  final VoidCallback onShare;

  /// Opens the health-score explanation (ScoreExplainSheet.showHealth).
  final VoidCallback? onExplainHealth;

  /// Opens the inflammation-score explanation (ScoreExplainSheet.show).
  final VoidCallback? onExplainInflammation;

  /// Opens the glycemic-load explanation.
  final VoidCallback? onExplainGl;

  const FoodDetailSheet({
    super.key,
    required this.meal,
    required this.servingLabel,
    required this.renderEmoji,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
    required this.onAddToSaved,
    required this.onLogAgain,
    required this.onShare,
    this.onExplainHealth,
    this.onExplainInflammation,
    this.onExplainGl,
  });

  String get _title {
    final q = meal.userQuery?.trim();
    if (q != null && q.isNotEmpty) return q;
    if (meal.foodItems.isNotEmpty) {
      final names = meal.foodItems
          .map((f) => f.name.trim())
          .where((n) => n.isNotEmpty)
          .toList();
      if (names.isNotEmpty) {
        final head = names.take(2).join(', ');
        final extra = names.length - 2;
        return extra > 0 ? '$head + $extra more' : head;
      }
    }
    final fb = meal.aiFeedback?.trim();
    if (fb != null && fb.isNotEmpty) {
      final end = fb.indexOf(RegExp(r'[.!?]'));
      return end > 0 ? fb.substring(0, end) : fb;
    }
    return 'Food';
  }

  String _provenanceLabel() {
    switch (meal.sourceType) {
      case 'image':
        return 'Logged via photo';
      case 'chat':
        return 'Logged via AI chat';
      case 'barcode':
        return 'Logged via barcode';
      case 'restaurant':
        return 'Logged via restaurant';
      case 'menu':
        return 'Logged via menu scan';
      case 'buffet':
        return 'Logged via buffet scan';
      case 'parse_app_screenshot':
        return 'Logged via app screenshot';
      case 'parse_nutrition_label':
        return 'Logged via nutrition label';
      case 'watch':
        return 'Logged via watch';
      case 'history':
        return 'Logged from history';
      default:
        return 'Logged manually';
    }
  }

  IconData _provenanceIcon() {
    switch (meal.sourceType) {
      case 'image':
        return Icons.photo_camera_outlined;
      case 'chat':
        return Icons.chat_bubble_outline_rounded;
      case 'barcode':
        return Icons.qr_code_scanner_rounded;
      case 'restaurant':
        return Icons.storefront_outlined;
      case 'menu':
        return Icons.menu_book_rounded;
      case 'buffet':
        return Icons.local_dining_outlined;
      case 'parse_app_screenshot':
        return Icons.phone_iphone_rounded;
      case 'parse_nutrition_label':
        return Icons.receipt_long_rounded;
      case 'watch':
        return Icons.watch_outlined;
      case 'history':
        return Icons.history_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ThemeColors.of(context);
    final accent = c.accent;
    final hasPhoto = meal.imageUrl != null && meal.imageUrl!.isNotEmpty;

    return GlassSheet(
      showHandle: true,
      maxHeightFraction: 0.9,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Top bar: meal type + time · share
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 6, 14, 0),
            child: Row(
              children: [
                Text(
                  '${meal.mealType.toUpperCase()} · '
                  '${TimeFormatters.logTime(meal.loggedAt)}',
                  style: ZType.lbl(11, color: c.textMuted, letterSpacing: 2),
                ),
                const Spacer(),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    Navigator.pop(context);
                    onShare();
                  },
                  icon: Icon(Icons.ios_share_rounded, size: 18, color: c.textMuted),
                  tooltip: 'Share',
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── RENDER HERO
                  _RenderHero(
                    meal: meal,
                    renderEmoji: renderEmoji,
                    hasPhoto: hasPhoto,
                  ),
                  const SizedBox(height: 13),
                  // Title (Anton masthead)
                  Text(
                    _title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: ZType.disp(24, color: c.textPrimary),
                  ),
                  const SizedBox(height: 9),
                  // Editable serving on a dotted underline.
                  _ServingTapTarget(
                    label: servingLabel,
                    color: c.textMuted,
                    faint: c.textMuted.withValues(alpha: 0.6),
                    onTap: onEdit,
                  ),
                  const SizedBox(height: 16),
                  // ── BIG CAL + P/C/F semantic dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${meal.totalCalories}',
                        style: ZType.disp(50, color: c.textPrimary),
                      ),
                      const SizedBox(width: 5),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          'KCAL',
                          style: ZType.lbl(13, color: c.textMuted, letterSpacing: 2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MacroDot(
                        value: meal.proteinG,
                        label: 'Protein',
                        color: AppColors.macroProtein,
                        muted: c.textMuted,
                        primary: c.textPrimary,
                      ),
                      const SizedBox(width: 26),
                      _MacroDot(
                        value: meal.carbsG,
                        label: 'Carbs',
                        color: AppColors.macroCarbs,
                        muted: c.textMuted,
                        primary: c.textPrimary,
                      ),
                      const SizedBox(width: 26),
                      _MacroDot(
                        value: meal.fatG,
                        label: 'Fat',
                        color: AppColors.macroFat,
                        muted: c.textMuted,
                        primary: c.textPrimary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // ── MICROS mini-row (only when present)
                  if (_microEntries().isNotEmpty) ...[
                    _MicroRow(entries: _microEntries(), c: c),
                    const SizedBox(height: 14),
                  ],
                  // ── Quality chips (Health · Inflammation · GL)
                  if (_hasAnyScore()) ...[
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (meal.healthScore != null)
                          _ScoreChip(
                            label: 'Health ${meal.healthScore}',
                            dot: _healthColor(meal.healthScore!),
                            border: c.cardBorder,
                            text: c.textMuted,
                            onTap: onExplainHealth,
                          ),
                        if (meal.inflammationScore != null)
                          _ScoreChip(
                            label: 'Inflam ${meal.inflammationScore}/10',
                            dot: _inflammationColor(meal.inflammationScore!),
                            border: c.cardBorder,
                            text: c.textMuted,
                            onTap: onExplainInflammation,
                          ),
                        if (meal.glycemicLoad != null)
                          _ScoreChip(
                            label: 'GL ${meal.glycemicLoad}',
                            dot: null,
                            border: c.cardBorder,
                            text: c.textMuted,
                            onTap: onExplainGl,
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],
                  // ── PROVENANCE badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: c.cardBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(_provenanceIcon(), size: 13, color: c.textMuted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _provenanceLabel().toUpperCase(),
                            style: ZType.lbl(9.5, color: c.textMuted, letterSpacing: 1.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          TimeFormatters.logTime(meal.loggedAt),
                          style: ZType.data(10, color: c.textMuted.withValues(alpha: 0.7)),
                        ),
                      ],
                    ),
                  ),
                  // ── AI feedback (italic, preserved)
                  if (meal.aiFeedback != null && meal.aiFeedback!.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      '"${meal.aiFeedback!}"',
                      textAlign: TextAlign.center,
                      style: ZType.ser(
                        13,
                        color: c.textSecondary,
                        style: FontStyle.italic,
                        height: 1.4,
                      ),
                    ),
                  ],
                  // ── Notes (if any)
                  if (meal.notes != null && meal.notes!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.note_outlined, size: 14, color: c.textMuted),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            meal.notes!,
                            style: ZType.ser(12, color: c.textMuted, style: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),
                  // ── ACTION GRID
                  _ActionGrid(
                    c: c,
                    accent: accent,
                    accentContrast: c.accentContrast,
                    onEdit: () {
                      Navigator.pop(context);
                      onEdit();
                    },
                    onDuplicate: () {
                      Navigator.pop(context);
                      onDuplicate();
                    },
                    onRemove: () {
                      Navigator.pop(context);
                      onRemove();
                    },
                    onAddToSaved: () {
                      Navigator.pop(context);
                      onAddToSaved();
                    },
                    onLogAgain: () {
                      Navigator.pop(context);
                      onLogAgain();
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  bool _hasAnyScore() =>
      meal.healthScore != null ||
      meal.inflammationScore != null ||
      meal.glycemicLoad != null;

  /// Up to three micro entries for the mini-row. Prefers Iron · Sodium · Vit D
  /// (matching the proof), falling back through the next-most-meaningful
  /// micros so the row only renders real, present values.
  List<(String, String)> _microEntries() {
    final out = <(String, String)>[];
    void add(double? v, String unit, String label, {int decimals = 0}) {
      if (out.length >= 3) return;
      if (v == null || v <= 0) return;
      final num = decimals == 0 ? v.round().toString() : v.toStringAsFixed(decimals);
      out.add(('$num$unit', label));
    }

    add(meal.ironMg, 'mg', 'Iron', decimals: 1);
    add(meal.sodiumMg, 'mg', 'Na');
    add(meal.vitaminDIu, 'IU', 'Vit D');
    // Fallbacks if the canonical three weren't present.
    add(meal.fiberG, 'g', 'Fiber', decimals: 1);
    add(meal.calciumMg, 'mg', 'Ca');
    add(meal.potassiumMg, 'mg', 'K');
    return out;
  }

  Color _healthColor(int score) {
    if (score >= 7) return AppColors.success;
    if (score >= 4) return AppColors.orange;
    return AppColors.error;
  }

  Color _inflammationColor(int score) {
    if (score <= 3) return AppColors.success;
    if (score <= 5) return AppColors.info;
    if (score <= 7) return AppColors.orange;
    return AppColors.error;
  }
}

/// Floating render hero — the food photo (network or local) when present, else
/// a large emoji with a soft radial shadow underneath.
class _RenderHero extends StatelessWidget {
  final FoodLog meal;
  final String renderEmoji;
  final bool hasPhoto;

  const _RenderHero({
    required this.meal,
    required this.renderEmoji,
    required this.hasPhoto,
  });

  @override
  Widget build(BuildContext context) {
    if (hasPhoto) {
      final url = meal.imageUrl!;
      final isLocal =
          url.startsWith('file://') || (!url.startsWith('http') && url.startsWith('/'));
      return GestureDetector(
        onTap: isLocal
            ? null
            : () => showFullscreenImage(
                  context,
                  networkUrl: url,
                  heroTag: 'fooddetail_image_${meal.id}',
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Hero(
            tag: 'fooddetail_image_${meal.id}',
            child: isLocal
                ? Image.file(
                    File(url.replaceFirst('file://', '')),
                    height: 168,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _EmojiRender(emoji: renderEmoji),
                  )
                : Image.network(
                    url,
                    height: 168,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _EmojiRender(emoji: renderEmoji),
                  ),
          ),
        ),
      );
    }
    return _EmojiRender(emoji: renderEmoji);
  }
}

class _EmojiRender extends StatelessWidget {
  final String emoji;
  const _EmojiRender({required this.emoji});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft shadow pad beneath the floating render.
          Positioned(
            bottom: 10,
            child: Container(
              width: 78,
              height: 16,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.28),
                    blurRadius: 22,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ),
          Text(emoji, style: const TextStyle(fontSize: 74)),
        ],
      ),
    );
  }
}

class _ServingTapTarget extends StatelessWidget {
  final String label;
  final Color color;
  final Color faint;
  final VoidCallback onTap;

  const _ServingTapTarget({
    required this.label,
    required this.color,
    required this.faint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: faint,
              width: 1.5,
              style: BorderStyle.solid,
            ),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: color),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.edit_outlined, size: 11, color: faint),
            const SizedBox(width: 3),
            Text(
              'TAP TO EDIT',
              style: ZType.lbl(8.5, color: faint, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroDot extends StatelessWidget {
  /// Nullable: null == UNKNOWN macro → renders "—", never a fabricated 0.
  final double? value;
  final String label;
  final Color color;
  final Color muted;
  final Color primary;

  const _MacroDot({
    required this.value,
    required this.label,
    required this.color,
    required this.muted,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(height: 5),
        Text(macroGramsValue(value), style: ZType.disp(20, color: primary, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(label.toUpperCase(), style: ZType.lbl(9, color: muted, letterSpacing: 2)),
      ],
    );
  }
}

class _MicroRow extends StatelessWidget {
  final List<(String, String)> entries;
  final ThemeColors c;

  const _MicroRow({required this.entries, required this.c});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: c.cardBorder),
          bottom: BorderSide(color: c.cardBorder),
        ),
      ),
      child: Row(
        children: [
          for (final e in entries) ...[
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(e.$1,
                    style: ZType.data(12, color: c.textPrimary)),
                const SizedBox(width: 4),
                Text(e.$2.toUpperCase(),
                    style: ZType.lbl(9, color: c.textMuted, letterSpacing: 1.4)),
              ],
            ),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final Color? dot;
  final Color border;
  final Color text;
  final VoidCallback? onTap;

  const _ScoreChip({
    required this.label,
    required this.dot,
    required this.border,
    required this.text,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
            ],
            Text(label.toUpperCase(),
                style: ZType.lbl(10, color: text, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}

class _ActionGrid extends StatelessWidget {
  final ThemeColors c;
  final Color accent;
  final Color accentContrast;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onRemove;
  final VoidCallback onAddToSaved;
  final VoidCallback onLogAgain;

  const _ActionGrid({
    required this.c,
    required this.accent,
    required this.accentContrast,
    required this.onEdit,
    required this.onDuplicate,
    required this.onRemove,
    required this.onAddToSaved,
    required this.onLogAgain,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _FdBtn(
                icon: Icons.edit_outlined,
                label: 'Edit',
                border: c.cardBorder,
                fg: c.textMuted,
                onTap: onEdit,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FdBtn(
                icon: Icons.copy_all_outlined,
                label: 'Duplicate',
                border: c.cardBorder,
                fg: c.textMuted,
                onTap: onDuplicate,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _FdBtn(
                icon: Icons.delete_outline_rounded,
                label: 'Remove',
                border: AppColors.error.withValues(alpha: 0.3),
                fg: AppColors.error,
                onTap: onRemove,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _FdBtn(
                icon: Icons.bookmark_add_outlined,
                label: 'Add to Saved',
                border: c.cardBorder,
                fg: c.textMuted,
                onTap: onAddToSaved,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Single orange primary action.
        _FdBtn(
          icon: Icons.replay_rounded,
          label: 'Log again',
          border: accent,
          fg: accentContrast,
          fill: accent,
          onTap: onLogAgain,
        ),
      ],
    );
  }
}

class _FdBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color border;
  final Color fg;
  final Color? fill;
  final VoidCallback onTap;

  const _FdBtn({
    required this.icon,
    required this.label,
    required this.border,
    required this.fg,
    required this.onTap,
    this.fill,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: fill ?? Colors.transparent,
      borderRadius: BorderRadius.circular(9),
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: ZType.lbl(11, color: fg, letterSpacing: 1.6,
                      weight: fill != null ? FontWeight.w800 : FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
