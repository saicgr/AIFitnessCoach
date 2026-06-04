/// The single render path for an editable share card. A [CardDoc] is rendered
/// at its fixed design size ([ShareableAspect.size]); callers wrap this in a
/// `FittedBox` to scale it for a thumbnail, the share-sheet preview, the editor
/// canvas, or a capture `RepaintBoundary`.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../shareable_data.dart';
import '../widgets/app_watermark.dart';
import '../widgets/food_image.dart';
import '../widgets/macro_viz.dart';
import 'card_doc.dart';
import 'card_doc_bindings.dart';

/// Renders a [CardDoc] + live [Shareable] data into a card at design size.
class CardDocRenderer extends StatelessWidget {
  final CardDoc doc;

  /// Live data source for bound elements.
  final Shareable data;

  /// Global watermark toggle (from share settings).
  final bool showWatermark;

  /// Global text-scale multiplier (from share settings).
  final double textScale;

  const CardDocRenderer({
    super.key,
    required this.doc,
    required this.data,
    this.showWatermark = true,
    this.textScale = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final size = doc.aspect.size;
    return SizedBox(
      width: size.width,
      height: size.height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(child: _Background(doc.background, data)),
          for (final element in doc.elements)
            if (!element.hidden)
              _ElementHost(
                element: element,
                canvas: size,
                doc: doc,
                data: data,
                showWatermark: showWatermark,
                textScale: textScale,
              ),
        ],
      ),
    );
  }
}

// ─────────────────────────── Background ────────────────────────────────────

class _Background extends StatelessWidget {
  final CardBackground bg;
  final Shareable data;
  const _Background(this.bg, this.data);

  @override
  Widget build(BuildContext context) {
    switch (bg.kind) {
      case CardBackgroundKind.none:
        return const SizedBox.shrink();
      case CardBackgroundKind.solid:
        return ColoredBox(
            color: bg.colors.isNotEmpty ? bg.colors.first : Colors.black);
      case CardBackgroundKind.linearGradient:
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: bg.begin,
              end: bg.end,
              colors: bg.colors.length >= 2
                  ? bg.colors
                  : [...bg.colors, ...bg.colors],
              stops: bg.stops,
            ),
          ),
        );
      case CardBackgroundKind.photo:
      case CardBackgroundKind.blurredPhoto:
        final url =
            bg.photo != null ? resolvePhotoUrl(bg.photo!, data) : null;
        final img = FoodImage(url: url, fit: bg.photoFit);
        if (bg.kind == CardBackgroundKind.blurredPhoto) {
          return ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: img,
          );
        }
        return img;
    }
  }
}

// ─────────────────────────── Element host ─────────────────────────────────

/// Positions, rotates, fades and renders one [CardElement] on the canvas.
class _ElementHost extends StatelessWidget {
  final CardElement element;
  final Size canvas;
  final CardDoc doc;
  final Shareable data;
  final bool showWatermark;
  final double textScale;

  const _ElementHost({
    required this.element,
    required this.canvas,
    required this.doc,
    required this.data,
    required this.showWatermark,
    required this.textScale,
  });

  @override
  Widget build(BuildContext context) {
    final t = element.transform;
    final w = t.size.width * canvas.width;
    final h = t.size.height * canvas.height;
    final cx = t.position.dx * canvas.width;
    final cy = t.position.dy * canvas.height;

    Widget body = _ElementBody(
      element: element,
      doc: doc,
      data: data,
      showWatermark: showWatermark,
      textScale: textScale,
      box: Size(w, h),
    );

    final effects = element.effects;
    if (!effects.isEmpty) {
      final shadows = <BoxShadow>[
        if (effects.shadow != null)
          BoxShadow(
            color: effects.shadow!.color,
            blurRadius: effects.shadow!.blur,
            offset: effects.shadow!.offset,
          ),
        if (effects.glow != null)
          BoxShadow(
            color: effects.glow!.color,
            blurRadius: effects.glow!.blur,
          ),
      ];
      if (shadows.isNotEmpty) {
        body = DecoratedBox(
          decoration: BoxDecoration(boxShadow: shadows),
          child: body,
        );
      }
    }

    return Positioned(
      left: cx - w / 2,
      top: cy - h / 2,
      width: w,
      height: h,
      child: Opacity(
        opacity: element.opacity.clamp(0.0, 1.0),
        child: Transform.rotate(
          angle: t.rotation,
          child: RepaintBoundary(child: body),
        ),
      ),
    );
  }
}

/// Dispatches an element to its type-specific renderer.
class _ElementBody extends StatelessWidget {
  final CardElement element;
  final CardDoc doc;
  final Shareable data;
  final bool showWatermark;
  final double textScale;
  final Size box;

  const _ElementBody({
    required this.element,
    required this.doc,
    required this.data,
    required this.showWatermark,
    required this.textScale,
    required this.box,
  });

  Color get _accent => doc.accentColor;

  @override
  Widget build(BuildContext context) {
    final p = element.props;
    if (p is TextProps) return _text(p);
    if (p is PhotoProps) return _photo(p);
    if (p is ChartProps) return _chart(p);
    if (p is ScrimProps) return _scrim(p);
    if (p is ShapeProps) return _shape(p);
    if (p is DividerProps) return _divider(p);
    if (p is BadgeProps) return _badge(p);
    if (p is ChipGroupProps) return _chipGroup(p);
    if (p is IconProps) return _icon(p);
    if (p is ImageProps) return _image(p);
    if (p is WatermarkProps) return _watermark(p);
    if (p is DateStampProps) return _dateStamp(p);
    if (p is RepeaterProps) return _repeater(p);
    if (p is TableProps) return _table(p);
    if (p is FrameProps) return _frame(p);
    if (p is QrProps) return _qr(p);
    if (p is TextureProps) return _texture(p);
    return const SizedBox.shrink();
  }

  // ─── text ───
  Widget _text(TextProps p) {
    var value = resolveText(p.binding, data, literalFallback: p.literal);
    if (p.prefix != null) value = '${p.prefix}$value';
    if (p.suffix != null) value = '$value${p.suffix}';
    if (p.allCaps) value = value.toUpperCase();
    final base = cardFontByIndex(p.fontIndex).style;
    final style = base.copyWith(
      color: p.color,
      fontSize: p.fontSize * textScale,
      letterSpacing: p.letterSpacing,
      height: p.lineHeight,
    );
    final text = Text(
      value,
      textAlign: p.align,
      maxLines: p.maxLines,
      overflow: p.maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      style: style,
    );
    if (p.sizeMode == TextSizeMode.shrinkToFit) {
      return FittedBox(fit: BoxFit.scaleDown, child: text);
    }
    return Align(
      alignment: _alignFor(p.align),
      child: text,
    );
  }

  Alignment _alignFor(TextAlign a) {
    switch (a) {
      case TextAlign.center:
        return Alignment.center;
      case TextAlign.right:
      case TextAlign.end:
        return Alignment.centerRight;
      default:
        return Alignment.centerLeft;
    }
  }

  // ─── photo ───
  Widget _photo(PhotoProps p) {
    final url = resolvePhotoUrl(p.source, data);
    Widget img = FoodImage(url: url, fit: p.fit);
    switch (p.mask) {
      case PhotoMask.circle:
        img = ClipOval(child: img);
      case PhotoMask.rect:
        break;
      case PhotoMask.rounded:
      case PhotoMask.film:
      case PhotoMask.stamp:
        img = ClipRRect(
          borderRadius: BorderRadius.circular(p.cornerRadius),
          child: img,
        );
    }
    if (p.frameColor != null && p.frameWidth > 0) {
      img = Container(
        decoration: BoxDecoration(
          border: Border.all(color: p.frameColor!, width: p.frameWidth),
          borderRadius: p.mask == PhotoMask.circle
              ? null
              : BorderRadius.circular(p.cornerRadius),
          shape: p.mask == PhotoMask.circle
              ? BoxShape.circle
              : BoxShape.rectangle,
        ),
        child: img,
      );
    }
    return SizedBox.expand(child: img);
  }

  // ─── chart (macro viz) ───
  Widget _chart(ChartProps p) {
    // MacroViz is a `crossAxisAlignment: stretch` Column — it MUST lay out
    // under bounded constraints. A bare `FittedBox` would hand it unbounded
    // width (→ "BoxConstraints forces an infinite width" crash). So give it
    // a generous DEFINITE box matching the element slot's aspect ratio, then
    // let the FittedBox scale that whole thing down into the slot.
    final w = box.width > 0 ? box.width : 1.0;
    final h = box.height > 0 ? box.height : 1.0;
    const natural = 1000.0;
    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: natural,
        height: natural * (h / w),
        child: ClipRect(
          child: MacroViz(
            nutrition: resolveNutrition(data),
            style: p.macroStyle,
            accentColor: _accent,
            glass: p.glass,
            showFiber: p.showFiber,
            scale: p.vizScale,
            healthScore: p.showHealthScore ? data.healthScore : null,
          ),
        ),
      ),
    );
  }

  // ─── scrim ───
  Widget _scrim(ScrimProps p) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: p.begin,
          end: p.end,
          colors: p.colors.length >= 2
              ? p.colors
              : [...p.colors, ...p.colors],
          stops: p.stops,
        ),
      ),
    );
  }

  // ─── shape ───
  Widget _shape(ShapeProps p) {
    final gradient = p.fillGradient != null && p.fillGradient!.length >= 2
        ? (p.radialGradient
            ? RadialGradient(colors: p.fillGradient!)
            : LinearGradient(colors: p.fillGradient!))
        : null;
    BoxShape boxShape = BoxShape.rectangle;
    BorderRadius? radius;
    switch (p.shape) {
      case ShapeKind.circle:
        boxShape = BoxShape.circle;
      case ShapeKind.pill:
        radius = BorderRadius.circular(9999);
      case ShapeKind.rounded:
        radius = BorderRadius.circular(p.cornerRadius);
      case ShapeKind.rect:
      case ShapeKind.line:
        break;
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        color: gradient == null ? p.fillColor : null,
        gradient: gradient,
        shape: boxShape,
        borderRadius: boxShape == BoxShape.circle ? null : radius,
        border: (p.strokeColor != null && p.strokeWidth > 0)
            ? Border.all(color: p.strokeColor!, width: p.strokeWidth)
            : null,
      ),
    );
  }

  // ─── divider ───
  Widget _divider(DividerProps p) {
    if (p.style == DividerStyle.solid) {
      return Align(
        alignment: Alignment.center,
        child: Container(height: p.thickness, color: p.color),
      );
    }
    return CustomPaint(
      painter: _DashedLinePainter(
        color: p.color,
        thickness: p.thickness,
        style: p.style,
      ),
      child: const SizedBox.expand(),
    );
  }

  // ─── badge ───
  Widget _badge(BadgeProps p) {
    final value = resolveText(p.valueBinding, data,
        literalFallback: p.valueLiteral);
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: p.fillGradient.length >= 2
              ? p.fillGradient
              : [...p.fillGradient, ...p.fillGradient],
        ),
        border: Border.all(color: p.borderColor, width: p.borderWidth),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: p.textColor,
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              if (p.label.isNotEmpty)
                Text(
                  p.label,
                  style: TextStyle(
                    color: p.textColor.withValues(alpha: 0.85),
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── chip group ───
  Widget _chipGroup(ChipGroupProps p) {
    final items = p.itemsBinding.isLiteral
        ? p.literalItems
        : resolveItemList(p.itemsBinding, data, max: p.maxItems);
    final shown = items.take(p.maxItems).toList();
    final chips = [
      for (final label in shown)
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: p.fontSize * 0.6, vertical: p.fontSize * 0.32),
          decoration: BoxDecoration(
            color: p.chipColor,
            borderRadius: BorderRadius.circular(p.chipRadius),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: p.textColor,
              fontSize: p.fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
    ];
    switch (p.layout) {
      case ChipLayout.wrap:
        return Wrap(spacing: p.spacing, runSpacing: p.spacing, children: chips);
      case ChipLayout.row:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) SizedBox(width: p.spacing),
              chips[i],
            ],
          ],
        );
      case ChipLayout.column:
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < chips.length; i++) ...[
              if (i > 0) SizedBox(height: p.spacing),
              chips[i],
            ],
          ],
        );
    }
  }

  // ─── icon ───
  Widget _icon(IconProps p) {
    if (p.isEmoji) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(p.emoji, style: const TextStyle(fontSize: 96)),
      );
    }
    return FittedBox(
      fit: BoxFit.contain,
      child: Icon(
        IconData(p.iconCodepoint!, fontFamily: p.iconFontFamily ?? 'MaterialIcons'),
        color: p.color,
        size: 96,
      ),
    );
  }

  // ─── image ───
  Widget _image(ImageProps p) {
    if (p.url.isEmpty) return const SizedBox.shrink();
    return Image.network(
      p.url,
      fit: p.fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  // ─── watermark ───
  Widget _watermark(WatermarkProps p) {
    return Align(
      alignment: Alignment.centerLeft,
      child: AppWatermark(
        enabled: showWatermark,
        textColor: p.textColor,
        iconSize: p.iconSize,
        fontSize: p.fontSize,
      ),
    );
  }

  // ─── date stamp ───
  Widget _dateStamp(DateStampProps p) {
    final value = resolveText(p.binding, data, literalFallback: p.literal);
    if (value.trim().isEmpty) return const SizedBox.shrink();
    final text = Text(
      value,
      style: TextStyle(
        color: p.color,
        fontSize: p.fontSize,
        fontWeight: FontWeight.w600,
      ),
    );
    if (!p.pill) return Align(alignment: Alignment.centerLeft, child: text);
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: text,
      ),
    );
  }

  // ─── repeater (data-bound list) ───
  Widget _repeater(RepeaterProps p) {
    if (p.exerciseMode) return _exerciseRepeater(p);
    final items = resolveFoodItems(data, max: p.maxItems);
    final base = cardFontByIndex(p.fontIndex).style;
    final style = base.copyWith(color: p.textColor, fontSize: p.fontSize);
    final subStyle = style.copyWith(
        fontSize: p.fontSize * 0.78,
        color: p.textColor.withValues(alpha: 0.6));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) SizedBox(height: p.rowSpacing),
          Row(
            children: [
              Expanded(
                child: Text(items[i].name, maxLines: 1,
                    overflow: TextOverflow.ellipsis, style: style),
              ),
              if (p.showAmount && (items[i].amount?.isNotEmpty ?? false)) ...[
                const SizedBox(width: 8),
                Text(items[i].amount!, style: subStyle),
              ],
              if (p.showCalories) ...[
                const SizedBox(width: 12),
                Text('${items[i].calories}', style: style),
              ],
            ],
          ),
        ],
      ],
    );
  }

  // ─── exercise list (Hevy-style: thumbnail + name + top set) ───
  Widget _exerciseRepeater(RepeaterProps p) {
    final list = (data.exercises ?? const <ShareableExercise>[])
        .take(p.maxItems)
        .toList();
    final base = cardFontByIndex(p.fontIndex).style;
    final nameStyle = base.copyWith(
        color: p.textColor, fontSize: p.fontSize, fontWeight: FontWeight.w700);
    final subStyle = base.copyWith(
        color: p.textColor.withValues(alpha: 0.55),
        fontSize: p.fontSize * 0.6,
        fontWeight: FontWeight.w500);
    final thumb = p.fontSize * 1.55;
    String topSet(ShareableExercise e) {
      if (e.sets.isEmpty) return '';
      var top = e.sets.first;
      for (final s in e.sets) {
        if ((s.weight ?? 0) > (top.weight ?? 0)) top = s;
      }
      final n = e.sets.length;
      final sets = '$n ${n == 1 ? 'set' : 'sets'}';
      if (top.isBodyweight || top.weight == null) {
        return '$sets · BW × ${top.reps}';
      }
      return '$sets · ${top.weight!.round()} ${top.unit} × ${top.reps}';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < list.length; i++) ...[
          if (i > 0) SizedBox(height: p.rowSpacing),
          Row(
            children: [
              if (p.showImage) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(thumb * 0.26),
                  child: SizedBox(
                    width: thumb,
                    height: thumb,
                    child: ColoredBox(
                      color: p.textColor.withValues(alpha: 0.08),
                      child: list[i].imageUrl == null
                          ? const SizedBox.shrink()
                          : FoodImage(url: list[i].imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),
                SizedBox(width: p.fontSize * 0.45),
              ],
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(list[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: nameStyle),
                        ),
                        if (list[i].isPr) ...[
                          const SizedBox(width: 5),
                          Text('PR',
                              style: subStyle.copyWith(
                                  color: doc.accentColor,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ],
                    ),
                    if (topSet(list[i]).isNotEmpty)
                      Text(topSet(list[i]),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: subStyle),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ─── table ───
  Widget _table(TableProps p) {
    final style = TextStyle(color: p.textColor, fontSize: p.fontSize);
    final boldStyle = style.copyWith(fontWeight: FontWeight.w800);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in p.rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: p.ruleColor)),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(row.isNotEmpty ? row[0] : '', style: style)),
                    Text(row.length > 1 ? row[1] : '', style: boldStyle),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─── frame ───
  Widget _frame(FrameProps p) {
    if (p.style == FrameStyle.none) return const SizedBox.shrink();
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: p.color, width: p.width),
        borderRadius: p.style == FrameStyle.polaroid
            ? null
            : BorderRadius.circular(p.cornerRadius),
      ),
    );
  }

  // ─── qr ───
  Widget _qr(QrProps p) {
    // Lightweight placeholder block — a real QR painter is wired in Phase 7.
    return DecoratedBox(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(Icons.qr_code_2_rounded,
            color: p.foreground, size: box.shortestSide * 0.8),
      ),
    );
  }

  // ─── texture ───
  Widget _texture(TextureProps p) {
    return CustomPaint(
      painter: _TexturePainter(p.kind, p.intensity, p.tint),
      child: const SizedBox.expand(),
    );
  }
}

// ─────────────────────────── Painters ─────────────────────────────────────

class _DashedLinePainter extends CustomPainter {
  final Color color;
  final double thickness;
  final DividerStyle style;
  const _DashedLinePainter({
    required this.color,
    required this.thickness,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    final dash = style == DividerStyle.dotted ? thickness : 14.0;
    final gap = style == DividerStyle.dotted ? thickness * 1.8 : 9.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y),
          paint);
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter old) =>
      old.color != color || old.thickness != thickness || old.style != style;
}

class _TexturePainter extends CustomPainter {
  final TextureKind kind;
  final double intensity;
  final Color tint;
  const _TexturePainter(this.kind, this.intensity, this.tint);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = tint.withValues(alpha: intensity.clamp(0, 1));
    if (kind == TextureKind.halftone) {
      const step = 26.0;
      for (var y = step / 2; y < size.height; y += step) {
        for (var x = step / 2; x < size.width; x += step) {
          canvas.drawCircle(Offset(x, y), step * 0.18, paint);
        }
      }
    } else {
      // grain / paper — a sparse speckle.
      const step = 13.0;
      var toggle = false;
      for (var y = 0.0; y < size.height; y += step) {
        for (var x = (toggle ? step / 2 : 0.0); x < size.width; x += step) {
          canvas.drawCircle(Offset(x, y), 1.1, paint);
        }
        toggle = !toggle;
      }
    }
  }

  @override
  bool shouldRepaint(_TexturePainter old) =>
      old.kind != kind || old.intensity != intensity || old.tint != tint;
}
