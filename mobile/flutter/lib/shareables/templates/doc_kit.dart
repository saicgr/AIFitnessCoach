/// A small DSL for authoring [CardDoc] presets concisely. A preset
/// doc-builder is a function `CardDoc Function(Shareable, ShareableAspect)`;
/// with these helpers it stays ~15-30 lines. Used by both the conversions of
/// the ~65 legacy templates and every new preset.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';

// ─────────────────────────── Document ──────────────────────────────────────

/// Assembles a [CardDoc] from a background + element list.
CardDoc cardDoc({
  required ShareableAspect aspect,
  required List<CardElement> elements,
  CardBackground background = CardBackground.dark,
  String? presetId,
  Color accent = const Color(0xFFF97316),
}) =>
    CardDoc(
      aspect: aspect,
      elements: elements,
      background: background,
      presetId: presetId,
      accentColor: accent,
    );

// ─────────────────────────── Backgrounds ──────────────────────────────────

CardBackground solidBg(Color color) =>
    CardBackground(kind: CardBackgroundKind.solid, colors: [color]);

CardBackground gradientBg(
  List<Color> colors, {
  Alignment begin = Alignment.topLeft,
  Alignment end = Alignment.bottomRight,
  List<double>? stops,
}) =>
    CardBackground(
      kind: CardBackgroundKind.linearGradient,
      colors: colors,
      begin: begin,
      end: end,
      stops: stops,
    );

/// A photo background bound to the share's first food photo.
CardBackground photoBg({
  DataBinding binding = const DataBinding(BindingSource.foodImageUrl, index: 0),
  BoxFit fit = BoxFit.cover,
  bool blurred = false,
}) =>
    CardBackground(
      kind: blurred ? CardBackgroundKind.blurredPhoto : CardBackgroundKind.photo,
      photo: CardPhotoRef(binding: binding),
      photoFit: fit,
    );

// ─────────────────────────── Element helper ───────────────────────────────

CardElement _el(
  CardElementType type,
  Offset pos,
  Size size,
  ElementProps props, {
  double rotation = 0,
  double opacity = 1,
  bool locked = false,
  ElementEffects effects = ElementEffects.none,
}) =>
    CardElement(
      id: CardDoc.newId(),
      type: type,
      transform:
          ElementTransform(position: pos, size: size, rotation: rotation),
      opacity: opacity,
      locked: locked,
      effects: effects,
      props: props,
    );

// ─────────────────────────── Elements ─────────────────────────────────────

/// A text element. Pass [binding] to bind it to live data, or [literal] for
/// static text.
CardElement textEl({
  required Offset pos,
  required Size size,
  String literal = '',
  DataBinding binding = DataBinding.none,
  int font = 0,
  double fontSize = 48,
  Color color = const Color(0xFFFFFFFF),
  TextAlign align = TextAlign.left,
  double letterSpacing = 0,
  double lineHeight = 1.1,
  bool allCaps = false,
  int? maxLines,
  TextSizeMode sizeMode = TextSizeMode.hugContent,
  ShadowSpec? shadow,
}) =>
    _el(
      CardElementType.text,
      pos,
      size,
      TextProps(
        literal: literal,
        binding: binding,
        fontIndex: font,
        fontSize: fontSize,
        color: color,
        align: align,
        letterSpacing: letterSpacing,
        lineHeight: lineHeight,
        allCaps: allCaps,
        maxLines: maxLines,
        sizeMode: sizeMode,
      ),
      effects: shadow != null ? ElementEffects(shadow: shadow) : ElementEffects.none,
    );

/// A macro chart element.
CardElement chartEl({
  required Offset pos,
  required Size size,
  MacroVizStyle style = MacroVizStyle.appleRings,
  bool glass = false,
  bool showFiber = false,
  bool showHealthScore = false,
  double vizScale = 1.0,
}) =>
    _el(
      CardElementType.chart,
      pos,
      size,
      ChartProps(
        macroStyle: style,
        glass: glass,
        showFiber: showFiber,
        showHealthScore: showHealthScore,
        vizScale: vizScale,
      ),
    );

/// A movable photo element bound to a food photo by default.
CardElement photoEl({
  required Offset pos,
  required Size size,
  DataBinding binding = const DataBinding(BindingSource.foodImageUrl, index: 0),
  BoxFit fit = BoxFit.cover,
  PhotoMask mask = PhotoMask.rounded,
  double cornerRadius = 24,
  Color? frameColor,
  double frameWidth = 0,
}) =>
    _el(
      CardElementType.photo,
      pos,
      size,
      PhotoProps(
        source: CardPhotoRef(binding: binding),
        fit: fit,
        mask: mask,
        cornerRadius: cornerRadius,
        frameColor: frameColor,
        frameWidth: frameWidth,
      ),
    );

/// A multi-stop legibility scrim.
CardElement scrimEl({
  required Offset pos,
  required Size size,
  required List<Color> colors,
  List<double>? stops,
  Alignment begin = Alignment.topCenter,
  Alignment end = Alignment.bottomCenter,
}) =>
    _el(
      CardElementType.scrim,
      pos,
      size,
      ScrimProps(colors: colors, stops: stops, begin: begin, end: end),
    );

/// A filled / stroked shape.
CardElement shapeEl({
  required Offset pos,
  required Size size,
  ShapeKind shape = ShapeKind.rounded,
  Color fill = const Color(0xFFFFFFFF),
  List<Color>? gradient,
  bool radial = false,
  Color? stroke,
  double strokeWidth = 0,
  double cornerRadius = 16,
}) =>
    _el(
      CardElementType.shape,
      pos,
      size,
      ShapeProps(
        shape: shape,
        fillColor: fill,
        fillGradient: gradient,
        radialGradient: radial,
        strokeColor: stroke,
        strokeWidth: strokeWidth,
        cornerRadius: cornerRadius,
      ),
    );

/// A chip group — food-name chips by default.
CardElement chipsEl({
  required Offset pos,
  required Size size,
  DataBinding binding = const DataBinding(BindingSource.foodItemName),
  List<String> literalItems = const [],
  ChipLayout layout = ChipLayout.wrap,
  int maxItems = 6,
  double spacing = 8,
  Color chipColor = const Color(0x1FFFFFFF),
  Color textColor = const Color(0xFFFFFFFF),
  double fontSize = 22,
}) =>
    _el(
      CardElementType.chipGroup,
      pos,
      size,
      ChipGroupProps(
        itemsBinding: binding,
        literalItems: literalItems,
        layout: layout,
        maxItems: maxItems,
        spacing: spacing,
        chipColor: chipColor,
        textColor: textColor,
        fontSize: fontSize,
      ),
    );

/// A circular score badge.
CardElement badgeEl({
  required Offset pos,
  required Size size,
  List<Color> gradient = const [Color(0xFFF59E0B), Color(0xFFB45309)],
  String label = 'HEALTH',
  DataBinding valueBinding = const DataBinding(BindingSource.healthScore),
  String valueLiteral = '5',
}) =>
    _el(
      CardElementType.badge,
      pos,
      size,
      BadgeProps(
        fillGradient: gradient,
        label: label,
        valueBinding: valueBinding,
        valueLiteral: valueLiteral,
      ),
    );

/// A rule line.
CardElement dividerEl({
  required Offset pos,
  required Size size,
  DividerStyle style = DividerStyle.solid,
  Color color = const Color(0x33FFFFFF),
  double thickness = 2,
}) =>
    _el(
      CardElementType.divider,
      pos,
      size,
      DividerProps(style: style, color: color, thickness: thickness),
    );

/// A data-bound food-item list.
CardElement repeaterEl({
  required Offset pos,
  required Size size,
  int maxItems = 8,
  double fontSize = 26,
  Color textColor = const Color(0xFFFFFFFF),
  bool showAmount = true,
  bool showCalories = true,
  bool exerciseMode = false,
  bool showImage = false,
  double rowSpacing = 6,
}) =>
    _el(
      CardElementType.repeater,
      pos,
      size,
      RepeaterProps(
        maxItems: maxItems,
        fontSize: fontSize,
        textColor: textColor,
        showAmount: showAmount,
        showCalories: showCalories,
        exerciseMode: exerciseMode,
        showImage: showImage,
        rowSpacing: rowSpacing,
      ),
    );

/// The app watermark.
CardElement watermarkEl({
  Offset pos = const Offset(0.32, 0.95),
  Size size = const Size(0.5, 0.05),
  Color color = const Color(0xFFFFFFFF),
  double iconSize = 26,
  double fontSize = 15,
}) =>
    _el(
      CardElementType.watermark,
      pos,
      size,
      WatermarkProps(textColor: color, iconSize: iconSize, fontSize: fontSize),
    );

/// A date / period stamp.
CardElement dateEl({
  required Offset pos,
  required Size size,
  DataBinding binding = const DataBinding(BindingSource.periodLabel),
  String literal = '',
  Color color = const Color(0xFFFFFFFF),
  double fontSize = 24,
  bool pill = false,
}) =>
    _el(
      CardElementType.dateStamp,
      pos,
      size,
      DateStampProps(
        binding: binding,
        literal: literal,
        color: color,
        fontSize: fontSize,
        pill: pill,
      ),
    );

/// An emoji / icon sticker.
CardElement iconEl({
  required Offset pos,
  required Size size,
  String emoji = '✨',
  Color color = const Color(0xFFFFFFFF),
}) =>
    _el(CardElementType.icon, pos, size, IconProps(emoji: emoji, color: color));
