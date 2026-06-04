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
  ChartKind kind = ChartKind.macro,
  DataBinding valueBinding = DataBinding.none,
  double maxValue = 100,
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
        kind: kind,
        valueBinding: valueBinding,
        maxValue: maxValue,
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

// ───────────── Social / AI / collectible element helpers ───────────────────

/// A chat / DM / comment bubble — iMessage / WhatsApp / AI-chat styling.
CardElement chatBubbleEl({
  required Offset pos,
  required Size size,
  String text = 'Crushed leg day today 💪',
  DataBinding textBinding = DataBinding.none,
  String sender = '',
  DataBinding senderBinding = DataBinding.none,
  ChatSide side = ChatSide.right,
  Color tint = const Color(0xFF2563EB),
  Color textColor = const Color(0xFFFFFFFF),
  double fontSize = 28,
  int font = 0,
  double cornerRadius = 22,
  bool showTail = true,
}) =>
    _el(
      CardElementType.chatBubble,
      pos,
      size,
      ChatBubbleProps(
        text: text,
        textBinding: textBinding,
        sender: sender,
        senderBinding: senderBinding,
        side: side,
        tint: tint,
        textColor: textColor,
        fontSize: fontSize,
        fontIndex: font,
        cornerRadius: cornerRadius,
        showTail: showTail,
      ),
    );

/// A social-header row — circular avatar + handle + sub-line.
CardElement avatarRowEl({
  required Offset pos,
  required Size size,
  DataBinding avatarBinding = const DataBinding(BindingSource.avatarUrl),
  String fallbackGlyph = '🏋️',
  String handle = '@yourhandle',
  DataBinding handleBinding = const DataBinding(BindingSource.socialHandle),
  String sub = 'just now',
  DataBinding subBinding = DataBinding.none,
  Color textColor = const Color(0xFFFFFFFF),
  Color subColor = const Color(0x99FFFFFF),
  double fontSize = 30,
  int font = 0,
  bool verified = false,
}) =>
    _el(
      CardElementType.avatarRow,
      pos,
      size,
      AvatarRowProps(
        avatar: CardPhotoRef(binding: avatarBinding),
        fallbackGlyph: fallbackGlyph,
        handle: handle,
        handleBinding: handleBinding,
        sub: sub,
        subBinding: subBinding,
        textColor: textColor,
        subColor: subColor,
        fontSize: fontSize,
        fontIndex: font,
        verified: verified,
      ),
    );

/// A now-playing / podcast scrubber — progress track + two time labels.
CardElement scrubberEl({
  required Offset pos,
  required Size size,
  double progress = 0.42,
  String leftLabel = '1:23',
  String rightLabel = '3:05',
  Color trackColor = const Color(0x33FFFFFF),
  Color fillColor = const Color(0xFFFFFFFF),
  Color knobColor = const Color(0xFFFFFFFF),
  Color textColor = const Color(0xCCFFFFFF),
  double trackHeight = 6,
  double fontSize = 20,
  bool showKnob = true,
}) =>
    _el(
      CardElementType.scrubber,
      pos,
      size,
      ScrubberProps(
        progress: progress,
        leftLabel: leftLabel,
        rightLabel: rightLabel,
        trackColor: trackColor,
        fillColor: fillColor,
        knobColor: knobColor,
        textColor: textColor,
        trackHeight: trackHeight,
        fontSize: fontSize,
        showKnob: showKnob,
      ),
    );

/// A single radial progress ring with a big center value + small label.
CardElement ringStatEl({
  required Offset pos,
  required Size size,
  double progress = 0.72,
  DataBinding valueBinding = DataBinding.none,
  double maxValue = 100,
  String centerValue = '72%',
  DataBinding centerBinding = DataBinding.none,
  String label = 'GOAL',
  Color ringColor = const Color(0xFFF97316),
  Color trackColor = const Color(0x22FFFFFF),
  Color textColor = const Color(0xFFFFFFFF),
  double strokeFraction = 0.12,
  double centerFontSize = 64,
  double labelFontSize = 18,
  int font = 0,
}) =>
    _el(
      CardElementType.ringStat,
      pos,
      size,
      RingStatProps(
        progress: progress,
        valueBinding: valueBinding,
        maxValue: maxValue,
        centerValue: centerValue,
        centerBinding: centerBinding,
        label: label,
        ringColor: ringColor,
        trackColor: trackColor,
        textColor: textColor,
        strokeFraction: strokeFraction,
        centerFontSize: centerFontSize,
        labelFontSize: labelFontSize,
        fontIndex: font,
      ),
    );

/// An Apple-rings trio — three concentric radial rings.
CardElement ringTrioEl({
  required Offset pos,
  required Size size,
  double outer = 0.82,
  double middle = 0.7,
  double inner = 0.6,
  Color outerColor = const Color(0xFFFA114F),
  Color middleColor = const Color(0xFF92E82A),
  Color innerColor = const Color(0xFF1AD6FD),
  double strokeFraction = 0.09,
  double trackOpacity = 0.2,
}) =>
    _el(
      CardElementType.ringTrio,
      pos,
      size,
      RingTrioProps(
        outer: outer,
        middle: middle,
        inner: inner,
        outerColor: outerColor,
        middleColor: middleColor,
        innerColor: innerColor,
        strokeFraction: strokeFraction,
        trackOpacity: trackOpacity,
      ),
    );

/// A 2×N grid of label/value tiles. Each tile is `[value, label]`.
CardElement statGridEl({
  required Offset pos,
  required Size size,
  List<List<String>> tiles = const [
    ['12', 'WORKOUTS'],
    ['48.2k', 'VOLUME LB'],
    ['7', 'PRs'],
    ['14', 'DAY STREAK'],
  ],
  int columns = 2,
  Color tileColor = const Color(0x14FFFFFF),
  Color valueColor = const Color(0xFFFFFFFF),
  Color labelColor = const Color(0x99FFFFFF),
  double valueFontSize = 44,
  double labelFontSize = 16,
  int valueFont = 0,
  double cornerRadius = 16,
  double spacing = 10,
}) =>
    _el(
      CardElementType.statGrid,
      pos,
      size,
      StatGridProps(
        tiles: tiles,
        columns: columns,
        tileColor: tileColor,
        valueColor: valueColor,
        labelColor: labelColor,
        valueFontSize: valueFontSize,
        labelFontSize: labelFontSize,
        valueFontIndex: valueFont,
        cornerRadius: cornerRadius,
        spacing: spacing,
      ),
    );

/// A calendar / contribution-style heatmap grid. Empty [cells] → demo data.
CardElement gridHeatmapEl({
  required Offset pos,
  required Size size,
  List<double> cells = const [],
  int columns = 13,
  Color cellColor = const Color(0xFF22C55E),
  Color emptyColor = const Color(0x1FFFFFFF),
  double cellRadius = 3,
  double gapFraction = 0.18,
}) =>
    _el(
      CardElementType.gridHeatmap,
      pos,
      size,
      GridHeatmapProps(
        cells: cells,
        columns: columns,
        cellColor: cellColor,
        emptyColor: emptyColor,
        cellRadius: cellRadius,
        gapFraction: gapFraction,
      ),
    );

/// A 5-star rating row (reviews). [rating] is 0..[count], supports halves.
CardElement ratingStarsEl({
  required Offset pos,
  required Size size,
  double rating = 4.5,
  int count = 5,
  Color filledColor = const Color(0xFFFFD23F),
  Color emptyColor = const Color(0x33FFFFFF),
  double spacingFraction = 0.18,
}) =>
    _el(
      CardElementType.ratingStars,
      pos,
      size,
      RatingStarsProps(
        rating: rating,
        count: count,
        filledColor: filledColor,
        emptyColor: emptyColor,
        spacingFraction: spacingFraction,
      ),
    );

/// A decorative barcode (deterministic stripes) + optional caption.
CardElement barcodeEl({
  required Offset pos,
  required Size size,
  String data = 'ZEALOVA-2026',
  String caption = 'ZEALOVA · 2026',
  DataBinding captionBinding = DataBinding.none,
  Color barColor = const Color(0xFF111111),
  Color background = const Color(0xFFFFFFFF),
  Color captionColor = const Color(0xFF111111),
  double captionFontSize = 18,
  bool showCaption = true,
}) =>
    _el(
      CardElementType.barcode,
      pos,
      size,
      BarcodeProps(
        data: data,
        caption: caption,
        captionBinding: captionBinding,
        barColor: barColor,
        background: background,
        captionColor: captionColor,
        captionFontSize: captionFontSize,
        showCaption: showCaption,
      ),
    );

/// A ticket / boarding-pass perforation — dashed tear line + punched notches.
CardElement perforationEl({
  required Offset pos,
  required Size size,
  PerforationEdge edge = PerforationEdge.horizontalCenter,
  Color color = const Color(0x66FFFFFF),
  double dashLength = 12,
  double gapLength = 9,
  double thickness = 2,
  double notchRadius = 16,
  Color notchColor = const Color(0xFF15171C),
  bool showNotches = true,
}) =>
    _el(
      CardElementType.perforation,
      pos,
      size,
      PerforationProps(
        edge: edge,
        color: color,
        dashLength: dashLength,
        gapLength: gapLength,
        thickness: thickness,
        notchRadius: notchRadius,
        notchColor: notchColor,
        showNotches: showNotches,
      ),
    );
