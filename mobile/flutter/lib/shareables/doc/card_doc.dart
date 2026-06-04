/// # Editable share-card document model
///
/// A share card is a [CardDoc] — a list of [CardElement]s over a
/// [CardBackground], rendered at a fixed design size ([ShareableAspect.size]).
/// Every element is individually selectable, movable, resizable, rotatable,
/// restyleable and hideable; the same document is rendered for the gallery
/// thumbnail, the share-sheet preview, the editor canvas and the captured PNG.
///
/// The ~65 legacy hand-coded templates become *presets* — functions that build
/// a default [CardDoc] from a [Shareable]. Because the editor edits any
/// [CardDoc], every preset is fully customizable for free.
///
/// All serialization is hand-written (the project forbids `build_runner`).
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import '../shareable_data.dart';

// ─────────────────────────── JSON helpers ──────────────────────────────────

int _colorToJson(Color c) => c.toARGB32();
Color _colorFromJson(Object? v, [Color fallback = const Color(0xFFFFFFFF)]) =>
    v is int ? Color(v) : fallback;

Map<String, double> _offsetToJson(Offset o) => {'dx': o.dx, 'dy': o.dy};
Offset _offsetFromJson(Object? v, [Offset fallback = Offset.zero]) {
  if (v is Map) {
    return Offset(
      (v['dx'] as num?)?.toDouble() ?? fallback.dx,
      (v['dy'] as num?)?.toDouble() ?? fallback.dy,
    );
  }
  return fallback;
}

Map<String, double> _sizeToJson(Size s) => {'w': s.width, 'h': s.height};
Size _sizeFromJson(Object? v, [Size fallback = const Size(0.5, 0.2)]) {
  if (v is Map) {
    return Size(
      (v['w'] as num?)?.toDouble() ?? fallback.width,
      (v['h'] as num?)?.toDouble() ?? fallback.height,
    );
  }
  return fallback;
}

/// Decode an enum by `.name`, falling back to [fallback] for unknown values
/// (keeps `fromJson` fail-soft across schema changes).
T _enumFromJson<T extends Enum>(Object? v, List<T> values, T fallback) {
  for (final e in values) {
    if (e.name == v) return e;
  }
  return fallback;
}

// ─────────────────────────── Data bindings ─────────────────────────────────

/// Where an element's value comes from. `literal` means the element carries
/// its own user-edited value; everything else reads live [Shareable] data, so
/// an unedited preset card tracks the underlying log.
enum BindingSource {
  literal,
  title,
  periodLabel,
  mealLabel,
  logText,
  caption,
  userDisplayName,
  heroString,
  nutrition,
  healthScore,
  calories,
  proteinG,
  carbsG,
  fatG,
  foodItemName,
  foodItemAmount,
  foodImageUrl,
  customPhotoPath,
  customPhotoPathSecondary,
  heroImageUrl,
  highlightLabel,
  highlightValue,
  // ── Appended for the redesign (new formats); append-only for JSON safety. ──
  lifetimeVolume,
  currentStreak,
  prCount,
  rank,
  socialHandle,
  recoveryPct,
  exerciseCount,
  avatarUrl,
  weeklyBars,
}

/// A reference from an element to a [Shareable] field (optionally indexed for
/// list sources like `foodItemName[2]`). [literal] is stored on the props.
@immutable
class DataBinding {
  final BindingSource source;
  final int? index;

  const DataBinding(this.source, {this.index});

  /// The common case — the element carries its own value, not bound to data.
  static const DataBinding none = DataBinding(BindingSource.literal);

  bool get isLiteral => source == BindingSource.literal;

  DataBinding copyWith({BindingSource? source, int? index}) =>
      DataBinding(source ?? this.source, index: index ?? this.index);

  Map<String, Object?> toJson() => {
        'source': source.name,
        if (index != null) 'index': index,
      };

  factory DataBinding.fromJson(Object? v) {
    if (v is! Map) return DataBinding.none;
    return DataBinding(
      _enumFromJson(v['source'], BindingSource.values, BindingSource.literal),
      index: (v['index'] as num?)?.toInt(),
    );
  }
}

// ─────────────────────────── Element geometry ──────────────────────────────

/// Geometry of one element in the card's fractional design space.
///
/// [position] is the element CENTER, fractional 0..1 of the canvas.
/// [size] is fractional 0..1 of the canvas (width, height).
/// [rotation] is radians. [anchor] pins the element to a region of the canvas
/// so it survives an aspect-ratio change (used by multi-aspect export).
@immutable
class ElementTransform {
  final Offset position;
  final Size size;
  final double rotation;
  final Alignment anchor;

  const ElementTransform({
    this.position = const Offset(0.5, 0.5),
    this.size = const Size(0.6, 0.15),
    this.rotation = 0.0,
    this.anchor = Alignment.center,
  });

  ElementTransform copyWith({
    Offset? position,
    Size? size,
    double? rotation,
    Alignment? anchor,
  }) =>
      ElementTransform(
        position: position ?? this.position,
        size: size ?? this.size,
        rotation: rotation ?? this.rotation,
        anchor: anchor ?? this.anchor,
      );

  Map<String, Object?> toJson() => {
        'position': _offsetToJson(position),
        'size': _sizeToJson(size),
        'rotation': rotation,
        'anchor': {'x': anchor.x, 'y': anchor.y},
      };

  factory ElementTransform.fromJson(Object? v) {
    if (v is! Map) return const ElementTransform();
    final a = v['anchor'];
    return ElementTransform(
      position: _offsetFromJson(v['position'], const Offset(0.5, 0.5)),
      size: _sizeFromJson(v['size']),
      rotation: (v['rotation'] as num?)?.toDouble() ?? 0.0,
      anchor: a is Map
          ? Alignment((a['x'] as num?)?.toDouble() ?? 0.0,
              (a['y'] as num?)?.toDouble() ?? 0.0)
          : Alignment.center,
    );
  }
}

/// Optional drop-shadow / glow on an element.
@immutable
class ShadowSpec {
  final Color color;
  final double blur;
  final Offset offset;

  const ShadowSpec({
    this.color = const Color(0x66000000),
    this.blur = 12,
    this.offset = const Offset(0, 4),
  });

  ShadowSpec copyWith({Color? color, double? blur, Offset? offset}) =>
      ShadowSpec(
        color: color ?? this.color,
        blur: blur ?? this.blur,
        offset: offset ?? this.offset,
      );

  Map<String, Object?> toJson() => {
        'color': _colorToJson(color),
        'blur': blur,
        'offset': _offsetToJson(offset),
      };

  factory ShadowSpec.fromJson(Object? v) {
    if (v is! Map) return const ShadowSpec();
    return ShadowSpec(
      color: _colorFromJson(v['color'], const Color(0x66000000)),
      blur: (v['blur'] as num?)?.toDouble() ?? 12,
      offset: _offsetFromJson(v['offset'], const Offset(0, 4)),
    );
  }
}

/// Shared visual effects available on every element.
@immutable
class ElementEffects {
  final ShadowSpec? shadow;
  final ShadowSpec? glow;
  final Color? outlineColor;
  final double outlineWidth;

  const ElementEffects({
    this.shadow,
    this.glow,
    this.outlineColor,
    this.outlineWidth = 0,
  });

  static const ElementEffects none = ElementEffects();

  bool get isEmpty =>
      shadow == null && glow == null && (outlineColor == null || outlineWidth <= 0);

  ElementEffects copyWith({
    ShadowSpec? shadow,
    ShadowSpec? glow,
    Color? outlineColor,
    double? outlineWidth,
    bool clearShadow = false,
    bool clearGlow = false,
    bool clearOutline = false,
  }) =>
      ElementEffects(
        shadow: clearShadow ? null : (shadow ?? this.shadow),
        glow: clearGlow ? null : (glow ?? this.glow),
        outlineColor: clearOutline ? null : (outlineColor ?? this.outlineColor),
        outlineWidth: outlineWidth ?? this.outlineWidth,
      );

  Map<String, Object?> toJson() => {
        if (shadow != null) 'shadow': shadow!.toJson(),
        if (glow != null) 'glow': glow!.toJson(),
        if (outlineColor != null) 'outlineColor': _colorToJson(outlineColor!),
        'outlineWidth': outlineWidth,
      };

  factory ElementEffects.fromJson(Object? v) {
    if (v is! Map) return ElementEffects.none;
    return ElementEffects(
      shadow: v['shadow'] != null ? ShadowSpec.fromJson(v['shadow']) : null,
      glow: v['glow'] != null ? ShadowSpec.fromJson(v['glow']) : null,
      outlineColor:
          v['outlineColor'] != null ? _colorFromJson(v['outlineColor']) : null,
      outlineWidth: (v['outlineWidth'] as num?)?.toDouble() ?? 0,
    );
  }
}

// ─────────────────────────── Background ────────────────────────────────────

enum CardBackgroundKind { solid, linearGradient, photo, blurredPhoto, none }

/// A photo source — either bound to a [Shareable] field or a static path the
/// user picked inside the editor.
@immutable
class CardPhotoRef {
  final DataBinding binding;
  final String? staticPath;

  const CardPhotoRef({this.binding = DataBinding.none, this.staticPath});

  CardPhotoRef copyWith({
    DataBinding? binding,
    String? staticPath,
    bool clearStatic = false,
  }) =>
      CardPhotoRef(
        binding: binding ?? this.binding,
        staticPath: clearStatic ? null : (staticPath ?? this.staticPath),
      );

  Map<String, Object?> toJson() => {
        'binding': binding.toJson(),
        if (staticPath != null) 'staticPath': staticPath,
      };

  factory CardPhotoRef.fromJson(Object? v) {
    if (v is! Map) return const CardPhotoRef();
    return CardPhotoRef(
      binding: DataBinding.fromJson(v['binding']),
      staticPath: v['staticPath'] as String?,
    );
  }
}

/// The card background — non-selectable, always behind every element.
@immutable
class CardBackground {
  final CardBackgroundKind kind;
  final List<Color> colors;
  final List<double>? stops;
  final Alignment begin;
  final Alignment end;
  final CardPhotoRef? photo;
  final BoxFit photoFit;

  const CardBackground({
    this.kind = CardBackgroundKind.solid,
    this.colors = const [Color(0xFF15171C)],
    this.stops,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.photo,
    this.photoFit = BoxFit.cover,
  });

  static const CardBackground dark =
      CardBackground(colors: [Color(0xFF15171C)]);

  CardBackground copyWith({
    CardBackgroundKind? kind,
    List<Color>? colors,
    List<double>? stops,
    Alignment? begin,
    Alignment? end,
    CardPhotoRef? photo,
    BoxFit? photoFit,
    bool clearStops = false,
    bool clearPhoto = false,
  }) =>
      CardBackground(
        kind: kind ?? this.kind,
        colors: colors ?? this.colors,
        stops: clearStops ? null : (stops ?? this.stops),
        begin: begin ?? this.begin,
        end: end ?? this.end,
        photo: clearPhoto ? null : (photo ?? this.photo),
        photoFit: photoFit ?? this.photoFit,
      );

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'colors': colors.map(_colorToJson).toList(),
        if (stops != null) 'stops': stops,
        'begin': {'x': begin.x, 'y': begin.y},
        'end': {'x': end.x, 'y': end.y},
        if (photo != null) 'photo': photo!.toJson(),
        'photoFit': photoFit.name,
      };

  factory CardBackground.fromJson(Object? v) {
    if (v is! Map) return CardBackground.dark;
    final begin = v['begin'];
    final end = v['end'];
    return CardBackground(
      kind: _enumFromJson(
          v['kind'], CardBackgroundKind.values, CardBackgroundKind.solid),
      colors: (v['colors'] as List?)
              ?.map((c) => _colorFromJson(c))
              .toList(growable: false) ??
          const [Color(0xFF15171C)],
      stops: (v['stops'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList(growable: false),
      begin: begin is Map
          ? Alignment((begin['x'] as num?)?.toDouble() ?? 0,
              (begin['y'] as num?)?.toDouble() ?? -1)
          : Alignment.topCenter,
      end: end is Map
          ? Alignment((end['x'] as num?)?.toDouble() ?? 0,
              (end['y'] as num?)?.toDouble() ?? 1)
          : Alignment.bottomCenter,
      photo: v['photo'] != null ? CardPhotoRef.fromJson(v['photo']) : null,
      photoFit: _enumFromJson(v['photoFit'], BoxFit.values, BoxFit.cover),
    );
  }
}

// ─────────────────────────── Element types ─────────────────────────────────

/// Every kind of element a card can contain. New element types are appended
/// (never reordered) so persisted documents keep decoding.
enum CardElementType {
  text,
  photo,
  chart,
  scrim,
  shape,
  divider,
  badge,
  chipGroup,
  icon,
  image,
  watermark,
  dateStamp,
  repeater,
  table,
  frame,
  qr,
  texture,
}

/// Base class for every element's type-specific payload. Each concrete
/// subclass owns its own `toJson` / `copyWith`; [ElementProps.fromJson]
/// dispatches on [CardElementType].
@immutable
abstract class ElementProps {
  const ElementProps();

  CardElementType get type;
  Map<String, Object?> toJson();

  static ElementProps fromJson(CardElementType type, Object? v) {
    final m = v is Map ? v : const <String, Object?>{};
    switch (type) {
      case CardElementType.text:
        return TextProps.fromJson(m);
      case CardElementType.photo:
        return PhotoProps.fromJson(m);
      case CardElementType.chart:
        return ChartProps.fromJson(m);
      case CardElementType.scrim:
        return ScrimProps.fromJson(m);
      case CardElementType.shape:
        return ShapeProps.fromJson(m);
      case CardElementType.divider:
        return DividerProps.fromJson(m);
      case CardElementType.badge:
        return BadgeProps.fromJson(m);
      case CardElementType.chipGroup:
        return ChipGroupProps.fromJson(m);
      case CardElementType.icon:
        return IconProps.fromJson(m);
      case CardElementType.image:
        return ImageProps.fromJson(m);
      case CardElementType.watermark:
        return WatermarkProps.fromJson(m);
      case CardElementType.dateStamp:
        return DateStampProps.fromJson(m);
      case CardElementType.repeater:
        return RepeaterProps.fromJson(m);
      case CardElementType.table:
        return TableProps.fromJson(m);
      case CardElementType.frame:
        return FrameProps.fromJson(m);
      case CardElementType.qr:
        return QrProps.fromJson(m);
      case CardElementType.texture:
        return TextureProps.fromJson(m);
    }
  }

  /// A sensible default props payload for a freshly-added element.
  static ElementProps defaultFor(CardElementType type) {
    switch (type) {
      case CardElementType.text:
        return const TextProps(literal: 'Text');
      case CardElementType.photo:
        return const PhotoProps();
      case CardElementType.chart:
        return const ChartProps();
      case CardElementType.scrim:
        return const ScrimProps();
      case CardElementType.shape:
        return const ShapeProps();
      case CardElementType.divider:
        return const DividerProps();
      case CardElementType.badge:
        return const BadgeProps();
      case CardElementType.chipGroup:
        return const ChipGroupProps();
      case CardElementType.icon:
        return const IconProps();
      case CardElementType.image:
        return const ImageProps();
      case CardElementType.watermark:
        return const WatermarkProps();
      case CardElementType.dateStamp:
        return const DateStampProps();
      case CardElementType.repeater:
        return const RepeaterProps();
      case CardElementType.table:
        return const TableProps();
      case CardElementType.frame:
        return const FrameProps();
      case CardElementType.qr:
        return const QrProps();
      case CardElementType.texture:
        return const TextureProps();
    }
  }
}

/// How a text box sizes itself.
enum TextSizeMode { fixed, hugContent, shrinkToFit }

/// A text element — title, eyebrow, quote, masthead, footer, big-number.
@immutable
class TextProps extends ElementProps {
  final String literal;
  final DataBinding binding;
  final int fontIndex;
  final double fontSize; // design-space px
  final Color color;
  final TextAlign align;
  final double letterSpacing;
  final double lineHeight;
  final bool allCaps;
  final int? maxLines;
  final TextSizeMode sizeMode;
  final String? prefix;
  final String? suffix;

  const TextProps({
    this.literal = '',
    this.binding = DataBinding.none,
    this.fontIndex = 0,
    this.fontSize = 48,
    this.color = const Color(0xFFFFFFFF),
    this.align = TextAlign.left,
    this.letterSpacing = 0,
    this.lineHeight = 1.1,
    this.allCaps = false,
    this.maxLines,
    this.sizeMode = TextSizeMode.hugContent,
    this.prefix,
    this.suffix,
  });

  @override
  CardElementType get type => CardElementType.text;

  TextProps copyWith({
    String? literal,
    DataBinding? binding,
    int? fontIndex,
    double? fontSize,
    Color? color,
    TextAlign? align,
    double? letterSpacing,
    double? lineHeight,
    bool? allCaps,
    int? maxLines,
    TextSizeMode? sizeMode,
    String? prefix,
    String? suffix,
  }) =>
      TextProps(
        literal: literal ?? this.literal,
        binding: binding ?? this.binding,
        fontIndex: fontIndex ?? this.fontIndex,
        fontSize: fontSize ?? this.fontSize,
        color: color ?? this.color,
        align: align ?? this.align,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        lineHeight: lineHeight ?? this.lineHeight,
        allCaps: allCaps ?? this.allCaps,
        maxLines: maxLines ?? this.maxLines,
        sizeMode: sizeMode ?? this.sizeMode,
        prefix: prefix ?? this.prefix,
        suffix: suffix ?? this.suffix,
      );

  @override
  Map<String, Object?> toJson() => {
        'literal': literal,
        'binding': binding.toJson(),
        'fontIndex': fontIndex,
        'fontSize': fontSize,
        'color': _colorToJson(color),
        'align': align.name,
        'letterSpacing': letterSpacing,
        'lineHeight': lineHeight,
        'allCaps': allCaps,
        if (maxLines != null) 'maxLines': maxLines,
        'sizeMode': sizeMode.name,
        if (prefix != null) 'prefix': prefix,
        if (suffix != null) 'suffix': suffix,
      };

  factory TextProps.fromJson(Map v) => TextProps(
        literal: v['literal'] as String? ?? '',
        binding: DataBinding.fromJson(v['binding']),
        fontIndex: (v['fontIndex'] as num?)?.toInt() ?? 0,
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 48,
        color: _colorFromJson(v['color']),
        align: _enumFromJson(v['align'], TextAlign.values, TextAlign.left),
        letterSpacing: (v['letterSpacing'] as num?)?.toDouble() ?? 0,
        lineHeight: (v['lineHeight'] as num?)?.toDouble() ?? 1.1,
        allCaps: v['allCaps'] as bool? ?? false,
        maxLines: (v['maxLines'] as num?)?.toInt(),
        sizeMode: _enumFromJson(
            v['sizeMode'], TextSizeMode.values, TextSizeMode.hugContent),
        prefix: v['prefix'] as String?,
        suffix: v['suffix'] as String?,
      );
}

/// Photo mask shapes.
enum PhotoMask { rect, rounded, circle, film, stamp }

/// A movable food/user photo element.
@immutable
class PhotoProps extends ElementProps {
  final CardPhotoRef source;
  final BoxFit fit;
  final PhotoMask mask;
  final double cornerRadius;
  final Color? frameColor;
  final double frameWidth;

  const PhotoProps({
    this.source = const CardPhotoRef(),
    this.fit = BoxFit.cover,
    this.mask = PhotoMask.rounded,
    this.cornerRadius = 24,
    this.frameColor,
    this.frameWidth = 0,
  });

  @override
  CardElementType get type => CardElementType.photo;

  PhotoProps copyWith({
    CardPhotoRef? source,
    BoxFit? fit,
    PhotoMask? mask,
    double? cornerRadius,
    Color? frameColor,
    double? frameWidth,
    bool clearFrame = false,
  }) =>
      PhotoProps(
        source: source ?? this.source,
        fit: fit ?? this.fit,
        mask: mask ?? this.mask,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        frameColor: clearFrame ? null : (frameColor ?? this.frameColor),
        frameWidth: frameWidth ?? this.frameWidth,
      );

  @override
  Map<String, Object?> toJson() => {
        'source': source.toJson(),
        'fit': fit.name,
        'mask': mask.name,
        'cornerRadius': cornerRadius,
        if (frameColor != null) 'frameColor': _colorToJson(frameColor!),
        'frameWidth': frameWidth,
      };

  factory PhotoProps.fromJson(Map v) => PhotoProps(
        source: CardPhotoRef.fromJson(v['source']),
        fit: _enumFromJson(v['fit'], BoxFit.values, BoxFit.cover),
        mask: _enumFromJson(v['mask'], PhotoMask.values, PhotoMask.rounded),
        cornerRadius: (v['cornerRadius'] as num?)?.toDouble() ?? 24,
        frameColor:
            v['frameColor'] != null ? _colorFromJson(v['frameColor']) : null,
        frameWidth: (v['frameWidth'] as num?)?.toDouble() ?? 0,
      );
}

/// A chart element. The macro styles delegate to `MacroViz`; the generic
/// styles (progress/gauge/bar/dotGrid) render from explicit value/segments.
@immutable
class ChartProps extends ElementProps {
  final MacroVizStyle macroStyle;
  final bool glass;
  final bool showFiber;
  final bool showHealthScore;
  final double vizScale;

  const ChartProps({
    this.macroStyle = MacroVizStyle.appleRings,
    this.glass = false,
    this.showFiber = false,
    this.showHealthScore = false,
    this.vizScale = 1.0,
  });

  @override
  CardElementType get type => CardElementType.chart;

  ChartProps copyWith({
    MacroVizStyle? macroStyle,
    bool? glass,
    bool? showFiber,
    bool? showHealthScore,
    double? vizScale,
  }) =>
      ChartProps(
        macroStyle: macroStyle ?? this.macroStyle,
        glass: glass ?? this.glass,
        showFiber: showFiber ?? this.showFiber,
        showHealthScore: showHealthScore ?? this.showHealthScore,
        vizScale: vizScale ?? this.vizScale,
      );

  @override
  Map<String, Object?> toJson() => {
        'macroStyle': macroStyle.name,
        'glass': glass,
        'showFiber': showFiber,
        'showHealthScore': showHealthScore,
        'vizScale': vizScale,
      };

  factory ChartProps.fromJson(Map v) => ChartProps(
        macroStyle: _enumFromJson(
            v['macroStyle'], MacroVizStyle.values, MacroVizStyle.appleRings),
        glass: v['glass'] as bool? ?? false,
        showFiber: v['showFiber'] as bool? ?? false,
        showHealthScore: v['showHealthScore'] as bool? ?? false,
        vizScale: (v['vizScale'] as num?)?.toDouble() ?? 1.0,
      );
}

/// A multi-stop gradient overlay (legibility scrim).
@immutable
class ScrimProps extends ElementProps {
  final List<Color> colors;
  final List<double>? stops;
  final Alignment begin;
  final Alignment end;

  const ScrimProps({
    this.colors = const [Color(0x00000000), Color(0xCC000000)],
    this.stops,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
  });

  @override
  CardElementType get type => CardElementType.scrim;

  ScrimProps copyWith({
    List<Color>? colors,
    List<double>? stops,
    Alignment? begin,
    Alignment? end,
    bool clearStops = false,
  }) =>
      ScrimProps(
        colors: colors ?? this.colors,
        stops: clearStops ? null : (stops ?? this.stops),
        begin: begin ?? this.begin,
        end: end ?? this.end,
      );

  @override
  Map<String, Object?> toJson() => {
        'colors': colors.map(_colorToJson).toList(),
        if (stops != null) 'stops': stops,
        'begin': {'x': begin.x, 'y': begin.y},
        'end': {'x': end.x, 'y': end.y},
      };

  factory ScrimProps.fromJson(Map v) {
    final begin = v['begin'];
    final end = v['end'];
    return ScrimProps(
      colors: (v['colors'] as List?)
              ?.map((c) => _colorFromJson(c, const Color(0x00000000)))
              .toList(growable: false) ??
          const [Color(0x00000000), Color(0xCC000000)],
      stops: (v['stops'] as List?)
          ?.map((s) => (s as num).toDouble())
          .toList(growable: false),
      begin: begin is Map
          ? Alignment((begin['x'] as num?)?.toDouble() ?? 0,
              (begin['y'] as num?)?.toDouble() ?? -1)
          : Alignment.topCenter,
      end: end is Map
          ? Alignment((end['x'] as num?)?.toDouble() ?? 0,
              (end['y'] as num?)?.toDouble() ?? 1)
          : Alignment.bottomCenter,
    );
  }
}

enum ShapeKind { rect, rounded, circle, pill, line }

/// A filled / stroked shape — kicker bars, dividers, pill backgrounds, plates.
@immutable
class ShapeProps extends ElementProps {
  final ShapeKind shape;
  final Color fillColor;
  final List<Color>? fillGradient;
  final bool radialGradient;
  final Color? strokeColor;
  final double strokeWidth;
  final double cornerRadius;

  const ShapeProps({
    this.shape = ShapeKind.rounded,
    this.fillColor = const Color(0xFFFFFFFF),
    this.fillGradient,
    this.radialGradient = false,
    this.strokeColor,
    this.strokeWidth = 0,
    this.cornerRadius = 16,
  });

  @override
  CardElementType get type => CardElementType.shape;

  ShapeProps copyWith({
    ShapeKind? shape,
    Color? fillColor,
    List<Color>? fillGradient,
    bool? radialGradient,
    Color? strokeColor,
    double? strokeWidth,
    double? cornerRadius,
    bool clearGradient = false,
    bool clearStroke = false,
  }) =>
      ShapeProps(
        shape: shape ?? this.shape,
        fillColor: fillColor ?? this.fillColor,
        fillGradient: clearGradient ? null : (fillGradient ?? this.fillGradient),
        radialGradient: radialGradient ?? this.radialGradient,
        strokeColor: clearStroke ? null : (strokeColor ?? this.strokeColor),
        strokeWidth: strokeWidth ?? this.strokeWidth,
        cornerRadius: cornerRadius ?? this.cornerRadius,
      );

  @override
  Map<String, Object?> toJson() => {
        'shape': shape.name,
        'fillColor': _colorToJson(fillColor),
        if (fillGradient != null)
          'fillGradient': fillGradient!.map(_colorToJson).toList(),
        'radialGradient': radialGradient,
        if (strokeColor != null) 'strokeColor': _colorToJson(strokeColor!),
        'strokeWidth': strokeWidth,
        'cornerRadius': cornerRadius,
      };

  factory ShapeProps.fromJson(Map v) => ShapeProps(
        shape: _enumFromJson(v['shape'], ShapeKind.values, ShapeKind.rounded),
        fillColor: _colorFromJson(v['fillColor']),
        fillGradient: (v['fillGradient'] as List?)
            ?.map((c) => _colorFromJson(c))
            .toList(growable: false),
        radialGradient: v['radialGradient'] as bool? ?? false,
        strokeColor:
            v['strokeColor'] != null ? _colorFromJson(v['strokeColor']) : null,
        strokeWidth: (v['strokeWidth'] as num?)?.toDouble() ?? 0,
        cornerRadius: (v['cornerRadius'] as num?)?.toDouble() ?? 16,
      );
}

enum DividerStyle { solid, dashed, dotted, perforated }

/// A first-class rule line — receipts, boarding passes, coupons.
@immutable
class DividerProps extends ElementProps {
  final DividerStyle style;
  final Color color;
  final double thickness;

  const DividerProps({
    this.style = DividerStyle.solid,
    this.color = const Color(0x33FFFFFF),
    this.thickness = 2,
  });

  @override
  CardElementType get type => CardElementType.divider;

  DividerProps copyWith({
    DividerStyle? style,
    Color? color,
    double? thickness,
  }) =>
      DividerProps(
        style: style ?? this.style,
        color: color ?? this.color,
        thickness: thickness ?? this.thickness,
      );

  @override
  Map<String, Object?> toJson() => {
        'style': style.name,
        'color': _colorToJson(color),
        'thickness': thickness,
      };

  factory DividerProps.fromJson(Map v) => DividerProps(
        style:
            _enumFromJson(v['style'], DividerStyle.values, DividerStyle.solid),
        color: _colorFromJson(v['color'], const Color(0x33FFFFFF)),
        thickness: (v['thickness'] as num?)?.toDouble() ?? 2,
      );
}

enum BadgeShape { circle, shield, seal }

/// A circular score badge — value + label inside a disc.
@immutable
class BadgeProps extends ElementProps {
  final BadgeShape shape;
  final List<Color> fillGradient;
  final Color borderColor;
  final double borderWidth;
  final DataBinding valueBinding;
  final String valueLiteral;
  final String label;
  final Color textColor;

  const BadgeProps({
    this.shape = BadgeShape.circle,
    this.fillGradient = const [Color(0xFFF59E0B), Color(0xFFB45309)],
    this.borderColor = const Color(0xFFFFFFFF),
    this.borderWidth = 2.4,
    this.valueBinding = const DataBinding(BindingSource.healthScore),
    this.valueLiteral = '5',
    this.label = 'HEALTH',
    this.textColor = const Color(0xFFFFFFFF),
  });

  @override
  CardElementType get type => CardElementType.badge;

  BadgeProps copyWith({
    BadgeShape? shape,
    List<Color>? fillGradient,
    Color? borderColor,
    double? borderWidth,
    DataBinding? valueBinding,
    String? valueLiteral,
    String? label,
    Color? textColor,
  }) =>
      BadgeProps(
        shape: shape ?? this.shape,
        fillGradient: fillGradient ?? this.fillGradient,
        borderColor: borderColor ?? this.borderColor,
        borderWidth: borderWidth ?? this.borderWidth,
        valueBinding: valueBinding ?? this.valueBinding,
        valueLiteral: valueLiteral ?? this.valueLiteral,
        label: label ?? this.label,
        textColor: textColor ?? this.textColor,
      );

  @override
  Map<String, Object?> toJson() => {
        'shape': shape.name,
        'fillGradient': fillGradient.map(_colorToJson).toList(),
        'borderColor': _colorToJson(borderColor),
        'borderWidth': borderWidth,
        'valueBinding': valueBinding.toJson(),
        'valueLiteral': valueLiteral,
        'label': label,
        'textColor': _colorToJson(textColor),
      };

  factory BadgeProps.fromJson(Map v) => BadgeProps(
        shape: _enumFromJson(v['shape'], BadgeShape.values, BadgeShape.circle),
        fillGradient: (v['fillGradient'] as List?)
                ?.map((c) => _colorFromJson(c))
                .toList(growable: false) ??
            const [Color(0xFFF59E0B), Color(0xFFB45309)],
        borderColor: _colorFromJson(v['borderColor']),
        borderWidth: (v['borderWidth'] as num?)?.toDouble() ?? 2.4,
        valueBinding: DataBinding.fromJson(v['valueBinding']),
        valueLiteral: v['valueLiteral'] as String? ?? '5',
        label: v['label'] as String? ?? 'HEALTH',
        textColor: _colorFromJson(v['textColor']),
      );
}

enum ChipLayout { wrap, row, column }

/// A collection of small chips — food-name chips, cover-line rails, legends.
@immutable
class ChipGroupProps extends ElementProps {
  final DataBinding itemsBinding;
  final List<String> literalItems;
  final ChipLayout layout;
  final int maxItems;
  final double spacing;
  final Color chipColor;
  final Color textColor;
  final double chipRadius;
  final double fontSize;

  const ChipGroupProps({
    this.itemsBinding = const DataBinding(BindingSource.foodItemName),
    this.literalItems = const [],
    this.layout = ChipLayout.wrap,
    this.maxItems = 6,
    this.spacing = 8,
    this.chipColor = const Color(0x1FFFFFFF),
    this.textColor = const Color(0xFFFFFFFF),
    this.chipRadius = 999,
    this.fontSize = 22,
  });

  @override
  CardElementType get type => CardElementType.chipGroup;

  ChipGroupProps copyWith({
    DataBinding? itemsBinding,
    List<String>? literalItems,
    ChipLayout? layout,
    int? maxItems,
    double? spacing,
    Color? chipColor,
    Color? textColor,
    double? chipRadius,
    double? fontSize,
  }) =>
      ChipGroupProps(
        itemsBinding: itemsBinding ?? this.itemsBinding,
        literalItems: literalItems ?? this.literalItems,
        layout: layout ?? this.layout,
        maxItems: maxItems ?? this.maxItems,
        spacing: spacing ?? this.spacing,
        chipColor: chipColor ?? this.chipColor,
        textColor: textColor ?? this.textColor,
        chipRadius: chipRadius ?? this.chipRadius,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  Map<String, Object?> toJson() => {
        'itemsBinding': itemsBinding.toJson(),
        'literalItems': literalItems,
        'layout': layout.name,
        'maxItems': maxItems,
        'spacing': spacing,
        'chipColor': _colorToJson(chipColor),
        'textColor': _colorToJson(textColor),
        'chipRadius': chipRadius,
        'fontSize': fontSize,
      };

  factory ChipGroupProps.fromJson(Map v) => ChipGroupProps(
        itemsBinding: DataBinding.fromJson(v['itemsBinding']),
        literalItems: (v['literalItems'] as List?)
                ?.map((e) => e.toString())
                .toList(growable: false) ??
            const [],
        layout:
            _enumFromJson(v['layout'], ChipLayout.values, ChipLayout.wrap),
        maxItems: (v['maxItems'] as num?)?.toInt() ?? 6,
        spacing: (v['spacing'] as num?)?.toDouble() ?? 8,
        chipColor: _colorFromJson(v['chipColor'], const Color(0x1FFFFFFF)),
        textColor: _colorFromJson(v['textColor']),
        chipRadius: (v['chipRadius'] as num?)?.toDouble() ?? 999,
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 22,
      );
}

/// A Material icon or emoji glyph.
@immutable
class IconProps extends ElementProps {
  final String emoji;
  final int? iconCodepoint;
  final String? iconFontFamily;
  final Color color;

  const IconProps({
    this.emoji = '✨',
    this.iconCodepoint,
    this.iconFontFamily,
    this.color = const Color(0xFFFFFFFF),
  });

  @override
  CardElementType get type => CardElementType.icon;

  bool get isEmoji => iconCodepoint == null;

  IconProps copyWith({
    String? emoji,
    int? iconCodepoint,
    String? iconFontFamily,
    Color? color,
  }) =>
      IconProps(
        emoji: emoji ?? this.emoji,
        iconCodepoint: iconCodepoint ?? this.iconCodepoint,
        iconFontFamily: iconFontFamily ?? this.iconFontFamily,
        color: color ?? this.color,
      );

  @override
  Map<String, Object?> toJson() => {
        'emoji': emoji,
        if (iconCodepoint != null) 'iconCodepoint': iconCodepoint,
        if (iconFontFamily != null) 'iconFontFamily': iconFontFamily,
        'color': _colorToJson(color),
      };

  factory IconProps.fromJson(Map v) => IconProps(
        emoji: v['emoji'] as String? ?? '✨',
        iconCodepoint: (v['iconCodepoint'] as num?)?.toInt(),
        iconFontFamily: v['iconFontFamily'] as String?,
        color: _colorFromJson(v['color']),
      );
}

/// A non-photo decorative image / GIF sticker (network or asset URL).
@immutable
class ImageProps extends ElementProps {
  final String url;
  final BoxFit fit;

  const ImageProps({this.url = '', this.fit = BoxFit.contain});

  @override
  CardElementType get type => CardElementType.image;

  ImageProps copyWith({String? url, BoxFit? fit}) =>
      ImageProps(url: url ?? this.url, fit: fit ?? this.fit);

  @override
  Map<String, Object?> toJson() => {'url': url, 'fit': fit.name};

  factory ImageProps.fromJson(Map v) => ImageProps(
        url: v['url'] as String? ?? '',
        fit: _enumFromJson(v['fit'], BoxFit.values, BoxFit.contain),
      );
}

/// The app-branding watermark element (wraps `AppWatermark`).
@immutable
class WatermarkProps extends ElementProps {
  final Color textColor;
  final double iconSize;
  final double fontSize;

  const WatermarkProps({
    this.textColor = const Color(0xFFFFFFFF),
    this.iconSize = 26,
    this.fontSize = 15,
  });

  @override
  CardElementType get type => CardElementType.watermark;

  WatermarkProps copyWith({
    Color? textColor,
    double? iconSize,
    double? fontSize,
  }) =>
      WatermarkProps(
        textColor: textColor ?? this.textColor,
        iconSize: iconSize ?? this.iconSize,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  Map<String, Object?> toJson() => {
        'textColor': _colorToJson(textColor),
        'iconSize': iconSize,
        'fontSize': fontSize,
      };

  factory WatermarkProps.fromJson(Map v) => WatermarkProps(
        textColor: _colorFromJson(v['textColor']),
        iconSize: (v['iconSize'] as num?)?.toDouble() ?? 26,
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 15,
      );
}

/// A date / period-label stamp.
@immutable
class DateStampProps extends ElementProps {
  final DataBinding binding;
  final String literal;
  final Color color;
  final double fontSize;
  final bool pill;

  const DateStampProps({
    this.binding = const DataBinding(BindingSource.periodLabel),
    this.literal = '',
    this.color = const Color(0xFFFFFFFF),
    this.fontSize = 24,
    this.pill = false,
  });

  @override
  CardElementType get type => CardElementType.dateStamp;

  DateStampProps copyWith({
    DataBinding? binding,
    String? literal,
    Color? color,
    double? fontSize,
    bool? pill,
  }) =>
      DateStampProps(
        binding: binding ?? this.binding,
        literal: literal ?? this.literal,
        color: color ?? this.color,
        fontSize: fontSize ?? this.fontSize,
        pill: pill ?? this.pill,
      );

  @override
  Map<String, Object?> toJson() => {
        'binding': binding.toJson(),
        'literal': literal,
        'color': _colorToJson(color),
        'fontSize': fontSize,
        'pill': pill,
      };

  factory DateStampProps.fromJson(Map v) => DateStampProps(
        binding: DataBinding.fromJson(v['binding']),
        literal: v['literal'] as String? ?? '',
        color: _colorFromJson(v['color']),
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 24,
        pill: v['pill'] as bool? ?? false,
      );
}

/// A data-bound list — renders one styled row per item of a [Shareable]
/// array (receipt line items, recipe ingredients, tier rows, checklists).
@immutable
class RepeaterProps extends ElementProps {
  final DataBinding itemsBinding;
  final int maxItems;
  final double rowHeight;
  final double rowSpacing;
  final int fontIndex;
  final double fontSize;
  final Color textColor;
  final bool showAmount;
  final bool showCalories;
  /// When true, the repeater renders `data.exercises` (name + top set, with an
  /// optional thumbnail) instead of food items — the Hevy-style workout list.
  final bool exerciseMode;
  final bool showImage;

  const RepeaterProps({
    this.itemsBinding = const DataBinding(BindingSource.foodItemName),
    this.maxItems = 8,
    this.rowHeight = 56,
    this.rowSpacing = 6,
    this.fontIndex = 0,
    this.fontSize = 26,
    this.textColor = const Color(0xFFFFFFFF),
    this.showAmount = true,
    this.showCalories = true,
    this.exerciseMode = false,
    this.showImage = false,
  });

  @override
  CardElementType get type => CardElementType.repeater;

  RepeaterProps copyWith({
    DataBinding? itemsBinding,
    int? maxItems,
    double? rowHeight,
    double? rowSpacing,
    int? fontIndex,
    double? fontSize,
    Color? textColor,
    bool? showAmount,
    bool? showCalories,
    bool? exerciseMode,
    bool? showImage,
  }) =>
      RepeaterProps(
        itemsBinding: itemsBinding ?? this.itemsBinding,
        maxItems: maxItems ?? this.maxItems,
        rowHeight: rowHeight ?? this.rowHeight,
        rowSpacing: rowSpacing ?? this.rowSpacing,
        fontIndex: fontIndex ?? this.fontIndex,
        fontSize: fontSize ?? this.fontSize,
        textColor: textColor ?? this.textColor,
        showAmount: showAmount ?? this.showAmount,
        showCalories: showCalories ?? this.showCalories,
        exerciseMode: exerciseMode ?? this.exerciseMode,
        showImage: showImage ?? this.showImage,
      );

  @override
  Map<String, Object?> toJson() => {
        'itemsBinding': itemsBinding.toJson(),
        'maxItems': maxItems,
        'rowHeight': rowHeight,
        'rowSpacing': rowSpacing,
        'fontIndex': fontIndex,
        'fontSize': fontSize,
        'textColor': _colorToJson(textColor),
        'showAmount': showAmount,
        'showCalories': showCalories,
        'exerciseMode': exerciseMode,
        'showImage': showImage,
      };

  factory RepeaterProps.fromJson(Map v) => RepeaterProps(
        itemsBinding: DataBinding.fromJson(v['itemsBinding']),
        maxItems: (v['maxItems'] as num?)?.toInt() ?? 8,
        rowHeight: (v['rowHeight'] as num?)?.toDouble() ?? 56,
        rowSpacing: (v['rowSpacing'] as num?)?.toDouble() ?? 6,
        fontIndex: (v['fontIndex'] as num?)?.toInt() ?? 0,
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 26,
        textColor: _colorFromJson(v['textColor']),
        showAmount: v['showAmount'] as bool? ?? true,
        showCalories: v['showCalories'] as bool? ?? true,
        exerciseMode: v['exerciseMode'] as bool? ?? false,
        showImage: v['showImage'] as bool? ?? false,
      );
}

/// A small key/value table — nutrition-facts label, ID-badge fields.
@immutable
class TableProps extends ElementProps {
  /// Each entry is `[label, value]`.
  final List<List<String>> rows;
  final Color textColor;
  final Color ruleColor;
  final double fontSize;

  const TableProps({
    this.rows = const [],
    this.textColor = const Color(0xFFFFFFFF),
    this.ruleColor = const Color(0x33FFFFFF),
    this.fontSize = 24,
  });

  @override
  CardElementType get type => CardElementType.table;

  TableProps copyWith({
    List<List<String>>? rows,
    Color? textColor,
    Color? ruleColor,
    double? fontSize,
  }) =>
      TableProps(
        rows: rows ?? this.rows,
        textColor: textColor ?? this.textColor,
        ruleColor: ruleColor ?? this.ruleColor,
        fontSize: fontSize ?? this.fontSize,
      );

  @override
  Map<String, Object?> toJson() => {
        'rows': rows,
        'textColor': _colorToJson(textColor),
        'ruleColor': _colorToJson(ruleColor),
        'fontSize': fontSize,
      };

  factory TableProps.fromJson(Map v) => TableProps(
        rows: (v['rows'] as List?)
                ?.map((r) => (r as List).map((e) => e.toString()).toList())
                .toList(growable: false) ??
            const [],
        textColor: _colorFromJson(v['textColor']),
        ruleColor: _colorFromJson(v['ruleColor'], const Color(0x33FFFFFF)),
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 24,
      );
}

enum FrameStyle { none, polaroid, rounded, ornament, holo }

/// An ornamental border / frame decoration.
@immutable
class FrameProps extends ElementProps {
  final FrameStyle style;
  final Color color;
  final double width;
  final double cornerRadius;

  const FrameProps({
    this.style = FrameStyle.rounded,
    this.color = const Color(0xFFFFFFFF),
    this.width = 6,
    this.cornerRadius = 20,
  });

  @override
  CardElementType get type => CardElementType.frame;

  FrameProps copyWith({
    FrameStyle? style,
    Color? color,
    double? width,
    double? cornerRadius,
  }) =>
      FrameProps(
        style: style ?? this.style,
        color: color ?? this.color,
        width: width ?? this.width,
        cornerRadius: cornerRadius ?? this.cornerRadius,
      );

  @override
  Map<String, Object?> toJson() => {
        'style': style.name,
        'color': _colorToJson(color),
        'width': width,
        'cornerRadius': cornerRadius,
      };

  factory FrameProps.fromJson(Map v) => FrameProps(
        style:
            _enumFromJson(v['style'], FrameStyle.values, FrameStyle.rounded),
        color: _colorFromJson(v['color']),
        width: (v['width'] as num?)?.toDouble() ?? 6,
        cornerRadius: (v['cornerRadius'] as num?)?.toDouble() ?? 20,
      );
}

/// A QR code element — encodes [data] (defaults to the share deep link).
@immutable
class QrProps extends ElementProps {
  final String data;
  final Color foreground;
  final Color background;

  const QrProps({
    this.data = '',
    this.foreground = const Color(0xFF000000),
    this.background = const Color(0xFFFFFFFF),
  });

  @override
  CardElementType get type => CardElementType.qr;

  QrProps copyWith({String? data, Color? foreground, Color? background}) =>
      QrProps(
        data: data ?? this.data,
        foreground: foreground ?? this.foreground,
        background: background ?? this.background,
      );

  @override
  Map<String, Object?> toJson() => {
        'data': data,
        'foreground': _colorToJson(foreground),
        'background': _colorToJson(background),
      };

  factory QrProps.fromJson(Map v) => QrProps(
        data: v['data'] as String? ?? '',
        foreground: _colorFromJson(v['foreground'], const Color(0xFF000000)),
        background: _colorFromJson(v['background']),
      );
}

enum TextureKind { grain, halftone, paper }

/// A blendable texture overlay (grain / halftone / paper).
@immutable
class TextureProps extends ElementProps {
  final TextureKind kind;
  final double intensity;
  final Color tint;

  const TextureProps({
    this.kind = TextureKind.grain,
    this.intensity = 0.12,
    this.tint = const Color(0xFF000000),
  });

  @override
  CardElementType get type => CardElementType.texture;

  TextureProps copyWith({
    TextureKind? kind,
    double? intensity,
    Color? tint,
  }) =>
      TextureProps(
        kind: kind ?? this.kind,
        intensity: intensity ?? this.intensity,
        tint: tint ?? this.tint,
      );

  @override
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'intensity': intensity,
        'tint': _colorToJson(tint),
      };

  factory TextureProps.fromJson(Map v) => TextureProps(
        kind: _enumFromJson(v['kind'], TextureKind.values, TextureKind.grain),
        intensity: (v['intensity'] as num?)?.toDouble() ?? 0.12,
        tint: _colorFromJson(v['tint'], const Color(0xFF000000)),
      );
}

// ─────────────────────────── Card element ──────────────────────────────────

/// One element on the card — geometry + flags + type-specific [props].
@immutable
class CardElement {
  final String id;
  final CardElementType type;
  final ElementTransform transform;
  final bool hidden;
  final bool locked;
  final double opacity;
  final BlendMode blendMode;
  final ElementEffects effects;
  final ElementProps props;

  const CardElement({
    required this.id,
    required this.type,
    required this.props,
    this.transform = const ElementTransform(),
    this.hidden = false,
    this.locked = false,
    this.opacity = 1.0,
    this.blendMode = BlendMode.srcOver,
    this.effects = ElementEffects.none,
  });

  CardElement copyWith({
    ElementTransform? transform,
    bool? hidden,
    bool? locked,
    double? opacity,
    BlendMode? blendMode,
    ElementEffects? effects,
    ElementProps? props,
  }) =>
      CardElement(
        id: id,
        type: type,
        transform: transform ?? this.transform,
        hidden: hidden ?? this.hidden,
        locked: locked ?? this.locked,
        opacity: opacity ?? this.opacity,
        blendMode: blendMode ?? this.blendMode,
        effects: effects ?? this.effects,
        props: props ?? this.props,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'type': type.name,
        'transform': transform.toJson(),
        'hidden': hidden,
        'locked': locked,
        'opacity': opacity,
        'blendMode': blendMode.name,
        'effects': effects.toJson(),
        'props': props.toJson(),
      };

  factory CardElement.fromJson(Map v) {
    final type =
        _enumFromJson(v['type'], CardElementType.values, CardElementType.text);
    return CardElement(
      id: v['id'] as String? ?? CardDoc.newId(),
      type: type,
      transform: ElementTransform.fromJson(v['transform']),
      hidden: v['hidden'] as bool? ?? false,
      locked: v['locked'] as bool? ?? false,
      opacity: (v['opacity'] as num?)?.toDouble() ?? 1.0,
      blendMode:
          _enumFromJson(v['blendMode'], BlendMode.values, BlendMode.srcOver),
      effects: ElementEffects.fromJson(v['effects']),
      props: ElementProps.fromJson(type, v['props']),
    );
  }
}

// ─────────────────────────── Card document ─────────────────────────────────

/// A complete editable share card.
@immutable
class CardDoc {
  /// Bump on a breaking model change; `fromJson` stays fail-soft regardless.
  static const String schemaVersion = '1';

  final ShareableAspect aspect;
  final CardBackground background;

  /// Paint order — index 0 is the bottom-most element.
  final List<CardElement> elements;

  /// The `ShareableTemplate.name` this document was derived from.
  final String? presetId;
  final Color accentColor;

  const CardDoc({
    required this.aspect,
    required this.elements,
    this.background = CardBackground.dark,
    this.presetId,
    this.accentColor = const Color(0xFFF97316),
  });

  CardDoc copyWith({
    ShareableAspect? aspect,
    CardBackground? background,
    List<CardElement>? elements,
    String? presetId,
    Color? accentColor,
  }) =>
      CardDoc(
        aspect: aspect ?? this.aspect,
        background: background ?? this.background,
        elements: elements ?? this.elements,
        presetId: presetId ?? this.presetId,
        accentColor: accentColor ?? this.accentColor,
      );

  /// Element with [id], or null.
  CardElement? elementById(String id) {
    for (final e in elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  /// Returns a copy with [id]'s element replaced by `fn(element)`.
  CardDoc withElement(String id, CardElement Function(CardElement) fn) {
    final next = [
      for (final e in elements) e.id == id ? fn(e) : e,
    ];
    return copyWith(elements: next);
  }

  CardDoc addElement(CardElement element) =>
      copyWith(elements: [...elements, element]);

  CardDoc removeElement(String id) =>
      copyWith(elements: elements.where((e) => e.id != id).toList());

  /// Moves [id] to [newIndex] in paint order (z-order).
  CardDoc reorder(String id, int newIndex) {
    final list = [...elements];
    final from = list.indexWhere((e) => e.id == id);
    if (from < 0) return this;
    final el = list.removeAt(from);
    list.insert(newIndex.clamp(0, list.length), el);
    return copyWith(elements: list);
  }

  /// Returns a copy with all photo content removed — every photo element
  /// hidden, and a photo background swapped for an accent gradient. Backs
  /// the share sheet's one-tap photo on/off toggle.
  CardDoc withoutPhoto() {
    final bgIsPhoto = background.kind == CardBackgroundKind.photo ||
        background.kind == CardBackgroundKind.blurredPhoto;
    return copyWith(
      background: bgIsPhoto
          ? CardBackground(
              kind: CardBackgroundKind.linearGradient,
              colors: [
                Color.lerp(accentColor, const Color(0xFF0D1117), 0.78)!,
                const Color(0xFF0D1117),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : background,
      elements: [
        for (final e in elements)
          e.props is PhotoProps ? e.copyWith(hidden: true) : e,
      ],
    );
  }

  /// Re-fits the document to [newAspect] for multi-aspect export
  /// ("magic resize"). All three aspects share a 1080-px design WIDTH, so
  /// element x-positions and widths carry over unchanged; only y-positions
  /// and heights are rescaled by the height ratio — every element keeps its
  /// on-screen pixel layout, the canvas just gets taller or shorter.
  CardDoc resizedTo(ShareableAspect newAspect) {
    if (newAspect == aspect) return this;
    final ratio = aspect.size.height / newAspect.size.height;
    return copyWith(
      aspect: newAspect,
      elements: [
        for (final e in elements)
          e.copyWith(
            transform: e.transform.copyWith(
              position: Offset(
                e.transform.position.dx,
                (e.transform.position.dy * ratio).clamp(0.0, 1.0),
              ),
              size: Size(
                e.transform.size.width,
                e.transform.size.height * ratio,
              ),
            ),
          ),
      ],
    );
  }

  Map<String, Object?> toJson() => {
        'schemaVersion': schemaVersion,
        'aspect': aspect.name,
        'background': background.toJson(),
        'elements': elements.map((e) => e.toJson()).toList(),
        if (presetId != null) 'presetId': presetId,
        'accentColor': _colorToJson(accentColor),
      };

  factory CardDoc.fromJson(Map<String, Object?> v) {
    final rawElements = v['elements'];
    final elements = <CardElement>[];
    if (rawElements is List) {
      for (final raw in rawElements) {
        if (raw is Map) {
          // Fail-soft: a single bad element is skipped, not fatal.
          try {
            elements.add(CardElement.fromJson(raw));
          } catch (_) {
            /* skip unreadable element */
          }
        }
      }
    }
    return CardDoc(
      aspect:
          _enumFromJson(v['aspect'], ShareableAspect.values, ShareableAspect.story),
      background: CardBackground.fromJson(v['background']),
      elements: elements,
      presetId: v['presetId'] as String?,
      accentColor: _colorFromJson(v['accentColor'], const Color(0xFFF97316)),
    );
  }

  /// Encodes to a JSON string for persistence.
  String encode() => jsonEncode(toJson());

  /// Decodes from a JSON string; returns null on any failure (fail-soft —
  /// the caller rebuilds the preset document instead).
  static CardDoc? decode(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, Object?>) return CardDoc.fromJson(decoded);
    } catch (e) {
      debugPrint('[CardDoc] decode failed: $e');
    }
    return null;
  }

  /// Monotonic element-ID generator. Seeds past any numeric ids already in a
  /// document so editor-added elements never collide with preset ids.
  static int _idCounter = 0;
  static String newId() => 'el_${_idCounter++}';

  /// Ensures [newId] will not collide with any id already in [doc].
  static void seedIdCounter(CardDoc doc) {
    for (final e in doc.elements) {
      final n = int.tryParse(e.id.replaceFirst('el_', ''));
      if (n != null && n >= _idCounter) _idCounter = n + 1;
    }
  }
}

// ─────────────────────────── Fonts ─────────────────────────────────────────

/// A named text treatment for the editor's font picker. Dependency-free
/// (weight / spacing / style / generic-family variations) plus display faces
/// for masthead / editorial presets.
@immutable
class CardFont {
  final String label;
  final TextStyle style;
  const CardFont(this.label, this.style);
}

/// Font presets available to text elements (indexed by `TextProps.fontIndex`).
/// Order is stable — appended-only — so persisted documents keep their font.
const List<CardFont> kCardFonts = [
  CardFont('Classic', TextStyle(fontWeight: FontWeight.w700)),
  CardFont('Heavy',
      TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
  CardFont('Light',
      TextStyle(fontWeight: FontWeight.w300, letterSpacing: 0.5)),
  // Index 3 ('Serif') now resolves to the real editorial serif (Fraunces),
  // index 4 ('Mono') to Space Mono — upgrading every template that used the
  // platform-generic 'serif'/'monospace' fallbacks.
  CardFont('Serif',
      TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w600)),
  CardFont('Mono',
      TextStyle(fontFamily: 'Space Mono', fontWeight: FontWeight.w400)),
  CardFont('Wide',
      TextStyle(fontWeight: FontWeight.w700, letterSpacing: 6.0)),
  CardFont('Italic',
      TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
  CardFont('Pop',
      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
  // Display / editorial faces — now real bundled fonts (were 'serif').
  CardFont('Masthead',
      TextStyle(fontFamily: 'Anton', letterSpacing: 0, height: 0.9)),
  CardFont('Editorial',
      TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w700)),
  CardFont('Condensed',
      TextStyle(fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800,
          letterSpacing: -0.2)),
  // ── Appended (stable indices 11+) — explicit redesign display faces. ──
  CardFont('Anton', TextStyle(fontFamily: 'Anton', height: 0.9)), // 11
  CardFont('Barlow', // 12
      TextStyle(fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w800,
          letterSpacing: 0.4)),
  CardFont('Barlow Mid', // 13
      TextStyle(fontFamily: 'Barlow Condensed', fontWeight: FontWeight.w600,
          letterSpacing: 0.8)),
  CardFont('Fraunces', // 14
      TextStyle(fontFamily: 'Fraunces', fontWeight: FontWeight.w900)),
  CardFont('Archivo', // 15
      TextStyle(fontFamily: 'Archivo', fontWeight: FontWeight.w800,
          letterSpacing: -0.3)),
  CardFont('Space Mono', TextStyle(fontFamily: 'Space Mono')), // 16
];

/// Stable font-index constants for the redesign doc-builders.
class CardFontIx {
  static const display = 11; // Anton
  static const cond = 12; // Barlow Condensed ExtraBold
  static const condMid = 13; // Barlow Condensed SemiBold
  static const serif = 14; // Fraunces
  static const grotesk = 15; // Archivo
  static const mono = 16; // Space Mono
}

/// Resolves a [CardFont] by index, clamped (a stale index never crashes).
CardFont cardFontByIndex(int index) =>
    kCardFonts[index.clamp(0, kCardFonts.length - 1)];
