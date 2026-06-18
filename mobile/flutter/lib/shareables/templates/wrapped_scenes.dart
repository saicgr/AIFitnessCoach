/// **F13 — Shareable Wrapped (per-scene)**.
///
/// Turns one Wrapped [Shareable] into an ordered list of vertical 9:16 scene
/// cards — the "swipe through your Wrapped" format — each a deterministic
/// [CardDoc] (zero AI). Workout Wrapped yields intro / headline-number /
/// top-stats / streak / "top X% your age" scenes; food Wrapped yields intro /
/// meals-logged / top-foods / best-macro-day scenes. The export screen renders
/// each scene and saves/shares it as its own 9:16 PNG.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../grade.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

/// One Wrapped scene — a title for the export rail + its [CardDoc].
@immutable
class WrappedScene {
  final String label;
  final CardDoc doc;
  const WrappedScene(this.label, this.doc);
}

/// Builds the full ordered scene list for [data]. Always 9:16 (story).
List<WrappedScene> buildWrappedScenes(Shareable data) {
  final isFood = data.kind == ShareableKind.foodLog ||
      data.kind == ShareableKind.nutrition;
  return isFood ? _foodScenes(data) : _workoutScenes(data);
}

// ─────────────────────────── Shared scene chrome ───────────────────────────

CardBackground _bg(Color accent) => gradientBg(
      [
        accent,
        Color.lerp(accent, Colors.black, 0.5)!,
        const Color(0xFF05050A),
      ],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

CardElement _eyebrow(String text, Color color) => textEl(
      pos: const Offset(0.5, 0.12),
      size: const Size(0.84, 0.04),
      literal: text,
      font: CardFontIx.cond,
      fontSize: 28,
      color: color,
      align: TextAlign.center,
      letterSpacing: 4,
    );

CardElement _bigNumber(DataBinding binding, {String? literal}) => textEl(
      pos: const Offset(0.5, 0.46),
      size: const Size(0.92, 0.22),
      literal: literal ?? '',
      binding: binding,
      font: CardFontIx.display,
      fontSize: 240,
      align: TextAlign.center,
      maxLines: 1,
      sizeMode: TextSizeMode.shrinkToFit,
    );

// ─────────────────────────── Workout scenes ────────────────────────────────

List<WrappedScene> _workoutScenes(Shareable data) {
  const story = ShareableAspect.story;
  final scenes = <WrappedScene>[];

  // 1 — Intro masthead.
  scenes.add(WrappedScene(
    'Intro',
    cardDoc(
      aspect: story,
      presetId: 'wrappedSceneIntro',
      accent: data.accentColor,
      background: _bg(data.accentColor),
      elements: [
        _eyebrow('YOUR', data.accentColor),
        textEl(
          pos: const Offset(0.5, 0.4),
          size: const Size(0.92, 0.2),
          literal: 'WRAPPED',
          font: CardFontIx.display,
          fontSize: 180,
          align: TextAlign.center,
          sizeMode: TextSizeMode.shrinkToFit,
        ),
        textEl(
          pos: const Offset(0.5, 0.56),
          size: const Size(0.84, 0.05),
          binding: const DataBinding(BindingSource.periodLabel),
          font: CardFontIx.cond,
          fontSize: 34,
          align: TextAlign.center,
          letterSpacing: 3,
          allCaps: true,
        ),
        watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
      ],
    ),
  ));

  // 2 — Headline number.
  scenes.add(WrappedScene(
    'Headline',
    cardDoc(
      aspect: story,
      presetId: 'wrappedSceneHeadline',
      accent: data.accentColor,
      background: _bg(data.accentColor),
      elements: [
        _eyebrow(data.heroUnitSingular.isEmpty
            ? 'YOUR NUMBER'
            : data.heroUnitSingular.toUpperCase(), Colors.white),
        _bigNumber(const DataBinding(BindingSource.heroString)),
        textEl(
          pos: const Offset(0.5, 0.62),
          size: const Size(0.86, 0.05),
          binding: const DataBinding(BindingSource.title),
          font: CardFontIx.condMid,
          fontSize: 44,
          align: TextAlign.center,
          maxLines: 2,
        ),
        watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
      ],
    ),
  ));

  // 3 — Top stats grid.
  scenes.add(WrappedScene(
    'Top stats',
    cardDoc(
      aspect: story,
      presetId: 'wrappedSceneStats',
      accent: data.accentColor,
      background: _bg(data.accentColor),
      elements: [
        _eyebrow('THE NUMBERS', data.accentColor),
        statGridEl(
          pos: const Offset(0.5, 0.5),
          size: const Size(0.86, 0.46),
          columns: 2,
          tiles: [
            for (var i = 0; i < 4 && i < data.highlights.length; i++)
              [data.highlights[i].value, data.highlights[i].label],
          ],
          valueFontSize: 56,
          labelFontSize: 18,
          valueFont: CardFontIx.cond,
        ),
        watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
      ],
    ),
  ));

  // 4 — Streak (only when there's a streak to show).
  if ((data.currentStreak ?? 0) > 0) {
    scenes.add(WrappedScene(
      'Streak',
      cardDoc(
        aspect: story,
        presetId: 'wrappedSceneStreak',
        accent: data.accentColor,
        background: _bg(data.accentColor),
        elements: [
          _eyebrow('YOUR STREAK', Colors.white),
          iconEl(
            pos: const Offset(0.5, 0.3),
            size: const Size(0.3, 0.16),
            emoji: '🔥',
            color: Colors.white,
          ),
          _bigNumber(const DataBinding(BindingSource.currentStreak)),
          textEl(
            pos: const Offset(0.5, 0.62),
            size: const Size(0.84, 0.05),
            literal: 'DAYS IN A ROW',
            font: CardFontIx.cond,
            fontSize: 38,
            align: TextAlign.center,
            letterSpacing: 3,
          ),
          watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
        ],
      ),
    ));
  }

  // 5 — "Top X% your age" (only when a rank/percentile travelled on the share).
  final pct = _percentile(data);
  if (pct != null) {
    scenes.add(WrappedScene(
      'Top %',
      cardDoc(
        aspect: story,
        presetId: 'wrappedScenePercentile',
        accent: data.accentColor,
        background: _bg(data.accentColor),
        elements: [
          _eyebrow('YOU RANK', Colors.white),
          textEl(
            pos: const Offset(0.5, 0.42),
            size: const Size(0.92, 0.2),
            literal: 'TOP $pct%',
            font: CardFontIx.display,
            fontSize: 200,
            align: TextAlign.center,
            sizeMode: TextSizeMode.shrinkToFit,
          ),
          textEl(
            pos: const Offset(0.5, 0.58),
            size: const Size(0.86, 0.05),
            literal: 'OF ATHLETES YOUR AGE',
            font: CardFontIx.cond,
            fontSize: 36,
            align: TextAlign.center,
            letterSpacing: 2,
          ),
          watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
        ],
      ),
    ));
  }

  return scenes;
}

// ─────────────────────────── Food scenes ───────────────────────────────────

List<WrappedScene> _foodScenes(Shareable data) {
  const story = ShareableAspect.story;
  final scenes = <WrappedScene>[];

  // 1 — Intro.
  scenes.add(WrappedScene(
    'Intro',
    cardDoc(
      aspect: story,
      presetId: 'wrappedFoodIntro',
      accent: data.accentColor,
      background: _bg(data.accentColor),
      elements: [
        _eyebrow('YOUR NUTRITION', data.accentColor),
        textEl(
          pos: const Offset(0.5, 0.4),
          size: const Size(0.92, 0.2),
          literal: 'WRAPPED',
          font: CardFontIx.display,
          fontSize: 180,
          align: TextAlign.center,
          sizeMode: TextSizeMode.shrinkToFit,
        ),
        textEl(
          pos: const Offset(0.5, 0.56),
          size: const Size(0.84, 0.05),
          binding: const DataBinding(BindingSource.periodLabel),
          font: CardFontIx.cond,
          fontSize: 34,
          align: TextAlign.center,
          letterSpacing: 3,
          allCaps: true,
        ),
        watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
      ],
    ),
  ));

  // 2 — Meals logged / calories headline.
  scenes.add(WrappedScene(
    'Calories',
    cardDoc(
      aspect: story,
      presetId: 'wrappedFoodCalories',
      accent: data.accentColor,
      background: _bg(data.accentColor),
      elements: [
        _eyebrow('CALORIES LOGGED', Colors.white),
        _bigNumber(const DataBinding(BindingSource.calories)),
        chartEl(
          pos: const Offset(0.5, 0.7),
          size: const Size(0.86, 0.1),
          style: MacroVizStyle.pills,
        ),
        watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
      ],
    ),
  ));

  // 3 — Top foods (chip rail from food items).
  if ((data.foodItems?.isNotEmpty ?? false)) {
    scenes.add(WrappedScene(
      'Top foods',
      cardDoc(
        aspect: story,
        presetId: 'wrappedFoodTop',
        accent: data.accentColor,
        background: _bg(data.accentColor),
        elements: [
          _eyebrow('YOUR TOP FOODS', data.accentColor),
          chipsEl(
            pos: const Offset(0.5, 0.5),
            size: const Size(0.86, 0.4),
            layout: ChipLayout.wrap,
            maxItems: 8,
            chipColor: const Color(0x1FFFFFFF),
            fontSize: 30,
          ),
          watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
        ],
      ),
    ));
  }

  // 4 — Best macro day (meal grade letter from health score).
  if (data.healthScore != null) {
    final grade = letterGrade(data.healthScore!);
    scenes.add(WrappedScene(
      'Best day',
      cardDoc(
        aspect: story,
        presetId: 'wrappedFoodBestDay',
        accent: data.accentColor,
        background: _bg(data.accentColor),
        elements: [
          _eyebrow('BEST MACRO DAY', Colors.white),
          textEl(
            pos: const Offset(0.5, 0.46),
            size: const Size(0.7, 0.3),
            literal: grade.letter,
            font: CardFontIx.display,
            fontSize: 320,
            color: grade.color,
            align: TextAlign.center,
            maxLines: 1,
            sizeMode: TextSizeMode.shrinkToFit,
          ),
          textEl(
            pos: const Offset(0.5, 0.66),
            size: const Size(0.84, 0.05),
            literal: grade.label.toUpperCase(),
            font: CardFontIx.cond,
            fontSize: 40,
            align: TextAlign.center,
            letterSpacing: 4,
          ),
          watermarkEl(pos: const Offset(0.5, 0.92), color: Colors.white),
        ],
      ),
    ));
  }

  return scenes;
}

// ─────────────────────────── Helpers ───────────────────────────────────────

/// The "top X%" value when a percentile travelled on the share (from the
/// Discover snapshot via a sub-metric labelled PERCENTILE, or `rank`).
String? _percentile(Shareable data) {
  for (final m in data.subMetrics) {
    if (m.label == 'PERCENTILE' && m.value.trim().isNotEmpty) {
      return m.value.replaceAll('%', '').trim();
    }
  }
  return null;
}
