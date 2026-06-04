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
  // ── Appended for the social / AI / collectible redesign (append-only). ──
  chatBubble,
  avatarRow,
  scrubber,
  ringStat,
  ringTrio,
  statGrid,
  gridHeatmap,
  ratingStars,
  barcode,
  perforation,
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
      case CardElementType.chatBubble:
        return ChatBubbleProps.fromJson(m);
      case CardElementType.avatarRow:
        return AvatarRowProps.fromJson(m);
      case CardElementType.scrubber:
        return ScrubberProps.fromJson(m);
      case CardElementType.ringStat:
        return RingStatProps.fromJson(m);
      case CardElementType.ringTrio:
        return RingTrioProps.fromJson(m);
      case CardElementType.statGrid:
        return StatGridProps.fromJson(m);
      case CardElementType.gridHeatmap:
        return GridHeatmapProps.fromJson(m);
      case CardElementType.ratingStars:
        return RatingStarsProps.fromJson(m);
      case CardElementType.barcode:
        return BarcodeProps.fromJson(m);
      case CardElementType.perforation:
        return PerforationProps.fromJson(m);
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
      case CardElementType.chatBubble:
        return const ChatBubbleProps();
      case CardElementType.avatarRow:
        return const AvatarRowProps();
      case CardElementType.scrubber:
        return const ScrubberProps();
      case CardElementType.ringStat:
        return const RingStatProps();
      case CardElementType.ringTrio:
        return const RingTrioProps();
      case CardElementType.statGrid:
        return const StatGridProps();
      case CardElementType.gridHeatmap:
        return const GridHeatmapProps();
      case CardElementType.ratingStars:
        return const RatingStarsProps();
      case CardElementType.barcode:
        return const BarcodeProps();
      case CardElementType.perforation:
        return const PerforationProps();
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

/// Non-macro chart kinds. `macro` keeps the original MacroViz behaviour; the
/// rest render via a generic series painter (see card_doc_renderer).
enum ChartKind { macro, bars, line, radar, ring, appleRings, heatmap }

/// A chart element. `macro` styles delegate to `MacroViz`; the generic kinds
/// (bars/line/radar/ring/appleRings/heatmap) render from live workout/stats data.
@immutable
class ChartProps extends ElementProps {
  final MacroVizStyle macroStyle;
  final bool glass;
  final bool showFiber;
  final bool showHealthScore;
  final double vizScale;
  final ChartKind kind;
  /// For `ring`: fill fraction = resolveNumber(valueBinding) / maxValue.
  final DataBinding valueBinding;
  final double maxValue;

  const ChartProps({
    this.macroStyle = MacroVizStyle.appleRings,
    this.glass = false,
    this.showFiber = false,
    this.showHealthScore = false,
    this.vizScale = 1.0,
    this.kind = ChartKind.macro,
    this.valueBinding = DataBinding.none,
    this.maxValue = 100,
  });

  @override
  CardElementType get type => CardElementType.chart;

  ChartProps copyWith({
    MacroVizStyle? macroStyle,
    bool? glass,
    bool? showFiber,
    bool? showHealthScore,
    double? vizScale,
    ChartKind? kind,
    DataBinding? valueBinding,
    double? maxValue,
  }) =>
      ChartProps(
        macroStyle: macroStyle ?? this.macroStyle,
        glass: glass ?? this.glass,
        showFiber: showFiber ?? this.showFiber,
        showHealthScore: showHealthScore ?? this.showHealthScore,
        vizScale: vizScale ?? this.vizScale,
        kind: kind ?? this.kind,
        valueBinding: valueBinding ?? this.valueBinding,
        maxValue: maxValue ?? this.maxValue,
      );

  @override
  Map<String, Object?> toJson() => {
        'macroStyle': macroStyle.name,
        'glass': glass,
        'showFiber': showFiber,
        'showHealthScore': showHealthScore,
        'vizScale': vizScale,
        'kind': kind.name,
        'valueBinding': valueBinding.toJson(),
        'maxValue': maxValue,
      };

  factory ChartProps.fromJson(Map v) => ChartProps(
        macroStyle: _enumFromJson(
            v['macroStyle'], MacroVizStyle.values, MacroVizStyle.appleRings),
        glass: v['glass'] as bool? ?? false,
        showFiber: v['showFiber'] as bool? ?? false,
        showHealthScore: v['showHealthScore'] as bool? ?? false,
        vizScale: (v['vizScale'] as num?)?.toDouble() ?? 1.0,
        kind: _enumFromJson(v['kind'], ChartKind.values, ChartKind.macro),
        valueBinding: v['valueBinding'] != null
            ? DataBinding.fromJson(v['valueBinding'])
            : DataBinding.none,
        maxValue: (v['maxValue'] as num?)?.toDouble() ?? 100,
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

// ─────────────── Social / AI / collectible element props ───────────────────

/// Which side a chat bubble sits on (sender vs receiver).
enum ChatSide { left, right }

/// A single chat / DM / comment bubble — iMessage / WhatsApp / AI-chat /
/// social-comment styling. [sender] is an optional name line above the
/// [text]; [side] decides bubble alignment + tail; [tint] is the bubble fill.
@immutable
class ChatBubbleProps extends ElementProps {
  final String sender;
  final DataBinding senderBinding;
  final String text;
  final DataBinding textBinding;
  final ChatSide side;
  final Color tint;
  final Color textColor;
  final double fontSize;
  final int fontIndex;
  final double cornerRadius;
  final bool showTail;

  const ChatBubbleProps({
    this.sender = '',
    this.senderBinding = DataBinding.none,
    this.text = 'Crushed leg day today 💪',
    this.textBinding = DataBinding.none,
    this.side = ChatSide.right,
    this.tint = const Color(0xFF2563EB),
    this.textColor = const Color(0xFFFFFFFF),
    this.fontSize = 28,
    this.fontIndex = 0,
    this.cornerRadius = 22,
    this.showTail = true,
  });

  @override
  CardElementType get type => CardElementType.chatBubble;

  ChatBubbleProps copyWith({
    String? sender,
    DataBinding? senderBinding,
    String? text,
    DataBinding? textBinding,
    ChatSide? side,
    Color? tint,
    Color? textColor,
    double? fontSize,
    int? fontIndex,
    double? cornerRadius,
    bool? showTail,
  }) =>
      ChatBubbleProps(
        sender: sender ?? this.sender,
        senderBinding: senderBinding ?? this.senderBinding,
        text: text ?? this.text,
        textBinding: textBinding ?? this.textBinding,
        side: side ?? this.side,
        tint: tint ?? this.tint,
        textColor: textColor ?? this.textColor,
        fontSize: fontSize ?? this.fontSize,
        fontIndex: fontIndex ?? this.fontIndex,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        showTail: showTail ?? this.showTail,
      );

  @override
  Map<String, Object?> toJson() => {
        'sender': sender,
        'senderBinding': senderBinding.toJson(),
        'text': text,
        'textBinding': textBinding.toJson(),
        'side': side.name,
        'tint': _colorToJson(tint),
        'textColor': _colorToJson(textColor),
        'fontSize': fontSize,
        'fontIndex': fontIndex,
        'cornerRadius': cornerRadius,
        'showTail': showTail,
      };

  factory ChatBubbleProps.fromJson(Map v) => ChatBubbleProps(
        sender: v['sender'] as String? ?? '',
        senderBinding: DataBinding.fromJson(v['senderBinding']),
        text: v['text'] as String? ?? 'Crushed leg day today 💪',
        textBinding: DataBinding.fromJson(v['textBinding']),
        side: _enumFromJson(v['side'], ChatSide.values, ChatSide.right),
        tint: _colorFromJson(v['tint'], const Color(0xFF2563EB)),
        textColor: _colorFromJson(v['textColor']),
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 28,
        fontIndex: (v['fontIndex'] as num?)?.toInt() ?? 0,
        cornerRadius: (v['cornerRadius'] as num?)?.toDouble() ?? 22,
        showTail: v['showTail'] as bool? ?? true,
      );
}

/// A social-header row — circular avatar + handle + sub-line (followers,
/// timestamp, location). Avatar is photo-bound by default, with an emoji /
/// initial fallback when there's no image.
@immutable
class AvatarRowProps extends ElementProps {
  final CardPhotoRef avatar;
  final String fallbackGlyph;
  final String handle;
  final DataBinding handleBinding;
  final String sub;
  final DataBinding subBinding;
  final Color textColor;
  final Color subColor;
  final double fontSize;
  final int fontIndex;
  final bool verified;

  const AvatarRowProps({
    this.avatar = const CardPhotoRef(
        binding: DataBinding(BindingSource.avatarUrl)),
    this.fallbackGlyph = '🏋️',
    this.handle = '@yourhandle',
    this.handleBinding = const DataBinding(BindingSource.socialHandle),
    this.sub = 'just now',
    this.subBinding = DataBinding.none,
    this.textColor = const Color(0xFFFFFFFF),
    this.subColor = const Color(0x99FFFFFF),
    this.fontSize = 30,
    this.fontIndex = 0,
    this.verified = false,
  });

  @override
  CardElementType get type => CardElementType.avatarRow;

  AvatarRowProps copyWith({
    CardPhotoRef? avatar,
    String? fallbackGlyph,
    String? handle,
    DataBinding? handleBinding,
    String? sub,
    DataBinding? subBinding,
    Color? textColor,
    Color? subColor,
    double? fontSize,
    int? fontIndex,
    bool? verified,
  }) =>
      AvatarRowProps(
        avatar: avatar ?? this.avatar,
        fallbackGlyph: fallbackGlyph ?? this.fallbackGlyph,
        handle: handle ?? this.handle,
        handleBinding: handleBinding ?? this.handleBinding,
        sub: sub ?? this.sub,
        subBinding: subBinding ?? this.subBinding,
        textColor: textColor ?? this.textColor,
        subColor: subColor ?? this.subColor,
        fontSize: fontSize ?? this.fontSize,
        fontIndex: fontIndex ?? this.fontIndex,
        verified: verified ?? this.verified,
      );

  @override
  Map<String, Object?> toJson() => {
        'avatar': avatar.toJson(),
        'fallbackGlyph': fallbackGlyph,
        'handle': handle,
        'handleBinding': handleBinding.toJson(),
        'sub': sub,
        'subBinding': subBinding.toJson(),
        'textColor': _colorToJson(textColor),
        'subColor': _colorToJson(subColor),
        'fontSize': fontSize,
        'fontIndex': fontIndex,
        'verified': verified,
      };

  factory AvatarRowProps.fromJson(Map v) => AvatarRowProps(
        avatar: CardPhotoRef.fromJson(v['avatar']),
        fallbackGlyph: v['fallbackGlyph'] as String? ?? '🏋️',
        handle: v['handle'] as String? ?? '@yourhandle',
        handleBinding: DataBinding.fromJson(v['handleBinding']),
        sub: v['sub'] as String? ?? 'just now',
        subBinding: DataBinding.fromJson(v['subBinding']),
        textColor: _colorFromJson(v['textColor']),
        subColor: _colorFromJson(v['subColor'], const Color(0x99FFFFFF)),
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 30,
        fontIndex: (v['fontIndex'] as num?)?.toInt() ?? 0,
        verified: v['verified'] as bool? ?? false,
      );
}

/// A now-playing / podcast scrubber — a progress track with a knob and two
/// time labels (elapsed left, total right). [progress] is 0..1.
@immutable
class ScrubberProps extends ElementProps {
  final double progress;
  final String leftLabel;
  final String rightLabel;
  final Color trackColor;
  final Color fillColor;
  final Color knobColor;
  final Color textColor;
  final double trackHeight;
  final double fontSize;
  final bool showKnob;

  const ScrubberProps({
    this.progress = 0.42,
    this.leftLabel = '1:23',
    this.rightLabel = '3:05',
    this.trackColor = const Color(0x33FFFFFF),
    this.fillColor = const Color(0xFFFFFFFF),
    this.knobColor = const Color(0xFFFFFFFF),
    this.textColor = const Color(0xCCFFFFFF),
    this.trackHeight = 6,
    this.fontSize = 20,
    this.showKnob = true,
  });

  @override
  CardElementType get type => CardElementType.scrubber;

  ScrubberProps copyWith({
    double? progress,
    String? leftLabel,
    String? rightLabel,
    Color? trackColor,
    Color? fillColor,
    Color? knobColor,
    Color? textColor,
    double? trackHeight,
    double? fontSize,
    bool? showKnob,
  }) =>
      ScrubberProps(
        progress: progress ?? this.progress,
        leftLabel: leftLabel ?? this.leftLabel,
        rightLabel: rightLabel ?? this.rightLabel,
        trackColor: trackColor ?? this.trackColor,
        fillColor: fillColor ?? this.fillColor,
        knobColor: knobColor ?? this.knobColor,
        textColor: textColor ?? this.textColor,
        trackHeight: trackHeight ?? this.trackHeight,
        fontSize: fontSize ?? this.fontSize,
        showKnob: showKnob ?? this.showKnob,
      );

  @override
  Map<String, Object?> toJson() => {
        'progress': progress,
        'leftLabel': leftLabel,
        'rightLabel': rightLabel,
        'trackColor': _colorToJson(trackColor),
        'fillColor': _colorToJson(fillColor),
        'knobColor': _colorToJson(knobColor),
        'textColor': _colorToJson(textColor),
        'trackHeight': trackHeight,
        'fontSize': fontSize,
        'showKnob': showKnob,
      };

  factory ScrubberProps.fromJson(Map v) => ScrubberProps(
        progress: (v['progress'] as num?)?.toDouble() ?? 0.42,
        leftLabel: v['leftLabel'] as String? ?? '1:23',
        rightLabel: v['rightLabel'] as String? ?? '3:05',
        trackColor: _colorFromJson(v['trackColor'], const Color(0x33FFFFFF)),
        fillColor: _colorFromJson(v['fillColor']),
        knobColor: _colorFromJson(v['knobColor']),
        textColor: _colorFromJson(v['textColor'], const Color(0xCCFFFFFF)),
        trackHeight: (v['trackHeight'] as num?)?.toDouble() ?? 6,
        fontSize: (v['fontSize'] as num?)?.toDouble() ?? 20,
        showKnob: v['showKnob'] as bool? ?? true,
      );
}

/// A single radial progress ring with a big center value + small label —
/// goal-progress / score / completion. Fill fraction is [progress] (0..1) when
/// unbound, or `resolveNumber(valueBinding) / maxValue` when bound.
@immutable
class RingStatProps extends ElementProps {
  final double progress;
  final DataBinding valueBinding;
  final double maxValue;
  final String centerValue;
  final DataBinding centerBinding;
  final String label;
  final Color ringColor;
  final Color trackColor;
  final Color textColor;
  final double strokeFraction;
  final double centerFontSize;
  final double labelFontSize;
  final int fontIndex;

  const RingStatProps({
    this.progress = 0.72,
    this.valueBinding = DataBinding.none,
    this.maxValue = 100,
    this.centerValue = '72%',
    this.centerBinding = DataBinding.none,
    this.label = 'GOAL',
    this.ringColor = const Color(0xFFF97316),
    this.trackColor = const Color(0x22FFFFFF),
    this.textColor = const Color(0xFFFFFFFF),
    this.strokeFraction = 0.12,
    this.centerFontSize = 64,
    this.labelFontSize = 18,
    this.fontIndex = 0,
  });

  @override
  CardElementType get type => CardElementType.ringStat;

  RingStatProps copyWith({
    double? progress,
    DataBinding? valueBinding,
    double? maxValue,
    String? centerValue,
    DataBinding? centerBinding,
    String? label,
    Color? ringColor,
    Color? trackColor,
    Color? textColor,
    double? strokeFraction,
    double? centerFontSize,
    double? labelFontSize,
    int? fontIndex,
  }) =>
      RingStatProps(
        progress: progress ?? this.progress,
        valueBinding: valueBinding ?? this.valueBinding,
        maxValue: maxValue ?? this.maxValue,
        centerValue: centerValue ?? this.centerValue,
        centerBinding: centerBinding ?? this.centerBinding,
        label: label ?? this.label,
        ringColor: ringColor ?? this.ringColor,
        trackColor: trackColor ?? this.trackColor,
        textColor: textColor ?? this.textColor,
        strokeFraction: strokeFraction ?? this.strokeFraction,
        centerFontSize: centerFontSize ?? this.centerFontSize,
        labelFontSize: labelFontSize ?? this.labelFontSize,
        fontIndex: fontIndex ?? this.fontIndex,
      );

  @override
  Map<String, Object?> toJson() => {
        'progress': progress,
        'valueBinding': valueBinding.toJson(),
        'maxValue': maxValue,
        'centerValue': centerValue,
        'centerBinding': centerBinding.toJson(),
        'label': label,
        'ringColor': _colorToJson(ringColor),
        'trackColor': _colorToJson(trackColor),
        'textColor': _colorToJson(textColor),
        'strokeFraction': strokeFraction,
        'centerFontSize': centerFontSize,
        'labelFontSize': labelFontSize,
        'fontIndex': fontIndex,
      };

  factory RingStatProps.fromJson(Map v) => RingStatProps(
        progress: (v['progress'] as num?)?.toDouble() ?? 0.72,
        valueBinding: DataBinding.fromJson(v['valueBinding']),
        maxValue: (v['maxValue'] as num?)?.toDouble() ?? 100,
        centerValue: v['centerValue'] as String? ?? '72%',
        centerBinding: DataBinding.fromJson(v['centerBinding']),
        label: v['label'] as String? ?? 'GOAL',
        ringColor: _colorFromJson(v['ringColor'], const Color(0xFFF97316)),
        trackColor: _colorFromJson(v['trackColor'], const Color(0x22FFFFFF)),
        textColor: _colorFromJson(v['textColor']),
        strokeFraction: (v['strokeFraction'] as num?)?.toDouble() ?? 0.12,
        centerFontSize: (v['centerFontSize'] as num?)?.toDouble() ?? 64,
        labelFontSize: (v['labelFontSize'] as num?)?.toDouble() ?? 18,
        fontIndex: (v['fontIndex'] as num?)?.toInt() ?? 0,
      );
}

/// An Apple-rings trio — three concentric radial rings (move / exercise /
/// stand). Each fraction is 0..1; colors are individually editable.
@immutable
class RingTrioProps extends ElementProps {
  final double outer;
  final double middle;
  final double inner;
  final Color outerColor;
  final Color middleColor;
  final Color innerColor;
  final double strokeFraction;
  final double trackOpacity;

  const RingTrioProps({
    this.outer = 0.82,
    this.middle = 0.7,
    this.inner = 0.6,
    this.outerColor = const Color(0xFFFA114F),
    this.middleColor = const Color(0xFF92E82A),
    this.innerColor = const Color(0xFF1AD6FD),
    this.strokeFraction = 0.09,
    this.trackOpacity = 0.2,
  });

  @override
  CardElementType get type => CardElementType.ringTrio;

  RingTrioProps copyWith({
    double? outer,
    double? middle,
    double? inner,
    Color? outerColor,
    Color? middleColor,
    Color? innerColor,
    double? strokeFraction,
    double? trackOpacity,
  }) =>
      RingTrioProps(
        outer: outer ?? this.outer,
        middle: middle ?? this.middle,
        inner: inner ?? this.inner,
        outerColor: outerColor ?? this.outerColor,
        middleColor: middleColor ?? this.middleColor,
        innerColor: innerColor ?? this.innerColor,
        strokeFraction: strokeFraction ?? this.strokeFraction,
        trackOpacity: trackOpacity ?? this.trackOpacity,
      );

  @override
  Map<String, Object?> toJson() => {
        'outer': outer,
        'middle': middle,
        'inner': inner,
        'outerColor': _colorToJson(outerColor),
        'middleColor': _colorToJson(middleColor),
        'innerColor': _colorToJson(innerColor),
        'strokeFraction': strokeFraction,
        'trackOpacity': trackOpacity,
      };

  factory RingTrioProps.fromJson(Map v) => RingTrioProps(
        outer: (v['outer'] as num?)?.toDouble() ?? 0.82,
        middle: (v['middle'] as num?)?.toDouble() ?? 0.7,
        inner: (v['inner'] as num?)?.toDouble() ?? 0.6,
        outerColor: _colorFromJson(v['outerColor'], const Color(0xFFFA114F)),
        middleColor: _colorFromJson(v['middleColor'], const Color(0xFF92E82A)),
        innerColor: _colorFromJson(v['innerColor'], const Color(0xFF1AD6FD)),
        strokeFraction: (v['strokeFraction'] as num?)?.toDouble() ?? 0.09,
        trackOpacity: (v['trackOpacity'] as num?)?.toDouble() ?? 0.2,
      );
}

/// A 2×N grid of label/value tiles — stat-brag / box-score / sportscard back.
/// Each tile is `[value, label]`; both strings are individually editable.
@immutable
class StatGridProps extends ElementProps {
  /// Each entry is `[value, label]`.
  final List<List<String>> tiles;
  final int columns;
  final Color tileColor;
  final Color valueColor;
  final Color labelColor;
  final double valueFontSize;
  final double labelFontSize;
  final int valueFontIndex;
  final double cornerRadius;
  final double spacing;

  const StatGridProps({
    this.tiles = const [
      ['12', 'WORKOUTS'],
      ['48.2k', 'VOLUME LB'],
      ['7', 'PRs'],
      ['14', 'DAY STREAK'],
    ],
    this.columns = 2,
    this.tileColor = const Color(0x14FFFFFF),
    this.valueColor = const Color(0xFFFFFFFF),
    this.labelColor = const Color(0x99FFFFFF),
    this.valueFontSize = 44,
    this.labelFontSize = 16,
    this.valueFontIndex = 0,
    this.cornerRadius = 16,
    this.spacing = 10,
  });

  @override
  CardElementType get type => CardElementType.statGrid;

  StatGridProps copyWith({
    List<List<String>>? tiles,
    int? columns,
    Color? tileColor,
    Color? valueColor,
    Color? labelColor,
    double? valueFontSize,
    double? labelFontSize,
    int? valueFontIndex,
    double? cornerRadius,
    double? spacing,
  }) =>
      StatGridProps(
        tiles: tiles ?? this.tiles,
        columns: columns ?? this.columns,
        tileColor: tileColor ?? this.tileColor,
        valueColor: valueColor ?? this.valueColor,
        labelColor: labelColor ?? this.labelColor,
        valueFontSize: valueFontSize ?? this.valueFontSize,
        labelFontSize: labelFontSize ?? this.labelFontSize,
        valueFontIndex: valueFontIndex ?? this.valueFontIndex,
        cornerRadius: cornerRadius ?? this.cornerRadius,
        spacing: spacing ?? this.spacing,
      );

  @override
  Map<String, Object?> toJson() => {
        'tiles': tiles,
        'columns': columns,
        'tileColor': _colorToJson(tileColor),
        'valueColor': _colorToJson(valueColor),
        'labelColor': _colorToJson(labelColor),
        'valueFontSize': valueFontSize,
        'labelFontSize': labelFontSize,
        'valueFontIndex': valueFontIndex,
        'cornerRadius': cornerRadius,
        'spacing': spacing,
      };

  factory StatGridProps.fromJson(Map v) => StatGridProps(
        tiles: (v['tiles'] as List?)
                ?.map((t) => (t as List).map((e) => e.toString()).toList())
                .toList(growable: false) ??
            const [
              ['12', 'WORKOUTS'],
              ['48.2k', 'VOLUME LB'],
              ['7', 'PRs'],
              ['14', 'DAY STREAK'],
            ],
        columns: (v['columns'] as num?)?.toInt() ?? 2,
        tileColor: _colorFromJson(v['tileColor'], const Color(0x14FFFFFF)),
        valueColor: _colorFromJson(v['valueColor']),
        labelColor: _colorFromJson(v['labelColor'], const Color(0x99FFFFFF)),
        valueFontSize: (v['valueFontSize'] as num?)?.toDouble() ?? 44,
        labelFontSize: (v['labelFontSize'] as num?)?.toDouble() ?? 16,
        valueFontIndex: (v['valueFontIndex'] as num?)?.toInt() ?? 0,
        cornerRadius: (v['cornerRadius'] as num?)?.toDouble() ?? 16,
        spacing: (v['spacing'] as num?)?.toDouble() ?? 10,
      );
}

/// A calendar / contribution-style heatmap grid (GitHub-style activity). Cells
/// are intensities 0..1; an empty [cells] list renders fail-soft demo data.
@immutable
class GridHeatmapProps extends ElementProps {
  final List<double> cells;
  final int columns;
  final Color cellColor;
  final Color emptyColor;
  final double cellRadius;
  final double gapFraction;

  const GridHeatmapProps({
    this.cells = const [],
    this.columns = 13,
    this.cellColor = const Color(0xFF22C55E),
    this.emptyColor = const Color(0x1FFFFFFF),
    this.cellRadius = 3,
    this.gapFraction = 0.18,
  });

  @override
  CardElementType get type => CardElementType.gridHeatmap;

  GridHeatmapProps copyWith({
    List<double>? cells,
    int? columns,
    Color? cellColor,
    Color? emptyColor,
    double? cellRadius,
    double? gapFraction,
  }) =>
      GridHeatmapProps(
        cells: cells ?? this.cells,
        columns: columns ?? this.columns,
        cellColor: cellColor ?? this.cellColor,
        emptyColor: emptyColor ?? this.emptyColor,
        cellRadius: cellRadius ?? this.cellRadius,
        gapFraction: gapFraction ?? this.gapFraction,
      );

  @override
  Map<String, Object?> toJson() => {
        'cells': cells,
        'columns': columns,
        'cellColor': _colorToJson(cellColor),
        'emptyColor': _colorToJson(emptyColor),
        'cellRadius': cellRadius,
        'gapFraction': gapFraction,
      };

  factory GridHeatmapProps.fromJson(Map v) => GridHeatmapProps(
        cells: (v['cells'] as List?)
                ?.map((c) => (c as num).toDouble())
                .toList(growable: false) ??
            const [],
        columns: (v['columns'] as num?)?.toInt() ?? 13,
        cellColor: _colorFromJson(v['cellColor'], const Color(0xFF22C55E)),
        emptyColor: _colorFromJson(v['emptyColor'], const Color(0x1FFFFFFF)),
        cellRadius: (v['cellRadius'] as num?)?.toDouble() ?? 3,
        gapFraction: (v['gapFraction'] as num?)?.toDouble() ?? 0.18,
      );
}

/// A 5-star rating row (reviews). [rating] is 0..[count], supports halves.
@immutable
class RatingStarsProps extends ElementProps {
  final double rating;
  final int count;
  final Color filledColor;
  final Color emptyColor;
  final double spacingFraction;

  const RatingStarsProps({
    this.rating = 4.5,
    this.count = 5,
    this.filledColor = const Color(0xFFFFD23F),
    this.emptyColor = const Color(0x33FFFFFF),
    this.spacingFraction = 0.18,
  });

  @override
  CardElementType get type => CardElementType.ratingStars;

  RatingStarsProps copyWith({
    double? rating,
    int? count,
    Color? filledColor,
    Color? emptyColor,
    double? spacingFraction,
  }) =>
      RatingStarsProps(
        rating: rating ?? this.rating,
        count: count ?? this.count,
        filledColor: filledColor ?? this.filledColor,
        emptyColor: emptyColor ?? this.emptyColor,
        spacingFraction: spacingFraction ?? this.spacingFraction,
      );

  @override
  Map<String, Object?> toJson() => {
        'rating': rating,
        'count': count,
        'filledColor': _colorToJson(filledColor),
        'emptyColor': _colorToJson(emptyColor),
        'spacingFraction': spacingFraction,
      };

  factory RatingStarsProps.fromJson(Map v) => RatingStarsProps(
        rating: (v['rating'] as num?)?.toDouble() ?? 4.5,
        count: (v['count'] as num?)?.toInt() ?? 5,
        filledColor: _colorFromJson(v['filledColor'], const Color(0xFFFFD23F)),
        emptyColor: _colorFromJson(v['emptyColor'], const Color(0x33FFFFFF)),
        spacingFraction: (v['spacingFraction'] as num?)?.toDouble() ?? 0.18,
      );
}

/// A decorative barcode (deterministic stripe pattern from [data]) with an
/// optional caption — ticket / boarding-pass / receipt / stamp.
@immutable
class BarcodeProps extends ElementProps {
  final String data;
  final String caption;
  final DataBinding captionBinding;
  final Color barColor;
  final Color background;
  final Color captionColor;
  final double captionFontSize;
  final bool showCaption;

  const BarcodeProps({
    this.data = 'ZEALOVA-2026',
    this.caption = 'ZEALOVA · 2026',
    this.captionBinding = DataBinding.none,
    this.barColor = const Color(0xFF111111),
    this.background = const Color(0xFFFFFFFF),
    this.captionColor = const Color(0xFF111111),
    this.captionFontSize = 18,
    this.showCaption = true,
  });

  @override
  CardElementType get type => CardElementType.barcode;

  BarcodeProps copyWith({
    String? data,
    String? caption,
    DataBinding? captionBinding,
    Color? barColor,
    Color? background,
    Color? captionColor,
    double? captionFontSize,
    bool? showCaption,
  }) =>
      BarcodeProps(
        data: data ?? this.data,
        caption: caption ?? this.caption,
        captionBinding: captionBinding ?? this.captionBinding,
        barColor: barColor ?? this.barColor,
        background: background ?? this.background,
        captionColor: captionColor ?? this.captionColor,
        captionFontSize: captionFontSize ?? this.captionFontSize,
        showCaption: showCaption ?? this.showCaption,
      );

  @override
  Map<String, Object?> toJson() => {
        'data': data,
        'caption': caption,
        'captionBinding': captionBinding.toJson(),
        'barColor': _colorToJson(barColor),
        'background': _colorToJson(background),
        'captionColor': _colorToJson(captionColor),
        'captionFontSize': captionFontSize,
        'showCaption': showCaption,
      };

  factory BarcodeProps.fromJson(Map v) => BarcodeProps(
        data: v['data'] as String? ?? 'ZEALOVA-2026',
        caption: v['caption'] as String? ?? 'ZEALOVA · 2026',
        captionBinding: DataBinding.fromJson(v['captionBinding']),
        barColor: _colorFromJson(v['barColor'], const Color(0xFF111111)),
        background: _colorFromJson(v['background']),
        captionColor: _colorFromJson(v['captionColor'], const Color(0xFF111111)),
        captionFontSize: (v['captionFontSize'] as num?)?.toDouble() ?? 18,
        showCaption: v['showCaption'] as bool? ?? true,
      );
}

/// Which edge(s) a perforation runs along.
enum PerforationEdge { top, bottom, left, right, horizontalCenter }

/// A ticket / boarding-pass perforation — a dashed tear line with optional
/// punched-out notch circles at each end of the line.
@immutable
class PerforationProps extends ElementProps {
  final PerforationEdge edge;
  final Color color;
  final double dashLength;
  final double gapLength;
  final double thickness;
  final double notchRadius;
  final Color notchColor;
  final bool showNotches;

  const PerforationProps({
    this.edge = PerforationEdge.horizontalCenter,
    this.color = const Color(0x66FFFFFF),
    this.dashLength = 12,
    this.gapLength = 9,
    this.thickness = 2,
    this.notchRadius = 16,
    this.notchColor = const Color(0xFF15171C),
    this.showNotches = true,
  });

  @override
  CardElementType get type => CardElementType.perforation;

  PerforationProps copyWith({
    PerforationEdge? edge,
    Color? color,
    double? dashLength,
    double? gapLength,
    double? thickness,
    double? notchRadius,
    Color? notchColor,
    bool? showNotches,
  }) =>
      PerforationProps(
        edge: edge ?? this.edge,
        color: color ?? this.color,
        dashLength: dashLength ?? this.dashLength,
        gapLength: gapLength ?? this.gapLength,
        thickness: thickness ?? this.thickness,
        notchRadius: notchRadius ?? this.notchRadius,
        notchColor: notchColor ?? this.notchColor,
        showNotches: showNotches ?? this.showNotches,
      );

  @override
  Map<String, Object?> toJson() => {
        'edge': edge.name,
        'color': _colorToJson(color),
        'dashLength': dashLength,
        'gapLength': gapLength,
        'thickness': thickness,
        'notchRadius': notchRadius,
        'notchColor': _colorToJson(notchColor),
        'showNotches': showNotches,
      };

  factory PerforationProps.fromJson(Map v) => PerforationProps(
        edge: _enumFromJson(
            v['edge'], PerforationEdge.values, PerforationEdge.horizontalCenter),
        color: _colorFromJson(v['color'], const Color(0x66FFFFFF)),
        dashLength: (v['dashLength'] as num?)?.toDouble() ?? 12,
        gapLength: (v['gapLength'] as num?)?.toDouble() ?? 9,
        thickness: (v['thickness'] as num?)?.toDouble() ?? 2,
        notchRadius: (v['notchRadius'] as num?)?.toDouble() ?? 16,
        notchColor: _colorFromJson(v['notchColor'], const Color(0xFF15171C)),
        showNotches: v['showNotches'] as bool? ?? true,
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
