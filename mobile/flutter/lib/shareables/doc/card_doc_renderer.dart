/// The single render path for an editable share card. A [CardDoc] is rendered
/// at its fixed design size ([ShareableAspect.size]); callers wrap this in a
/// `FittedBox` to scale it for a thumbnail, the share-sheet preview, the editor
/// canvas, or a capture `RepaintBoundary`.
library;

import 'dart:math' as math;
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
    if (p is ChatBubbleProps) return _chatBubble(p);
    if (p is AvatarRowProps) return _avatarRow(p);
    if (p is ScrubberProps) return _scrubber(p);
    if (p is RingStatProps) return _ringStat(p);
    if (p is RingTrioProps) return _ringTrio(p);
    if (p is StatGridProps) return _statGrid(p);
    if (p is GridHeatmapProps) return _gridHeatmap(p);
    if (p is RatingStarsProps) return _ratingStars(p);
    if (p is BarcodeProps) return _barcode(p);
    if (p is PerforationProps) return _perforation(p);
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
    if (p.kind != ChartKind.macro) return _seriesChart(p);
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

  // ─── series chart (bars/line/radar/ring/appleRings/heatmap) ───
  Widget _seriesChart(ChartProps p) {
    final raw = data.subMetrics
        .map((m) =>
            double.tryParse(m.value.replaceAll(RegExp(r'[^0-9.\-]'), '')) ?? 0)
        .where((v) => v >= 0)
        .toList();
    final series =
        raw.isNotEmpty ? raw : const [0.4, 0.7, 0.5, 0.95, 0.6, 0.35, 0.8];
    final mw = data.musclesWorked ?? const <String, int>{};
    List<double> radar;
    if (mw.isNotEmpty) {
      final maxM = mw.values.fold<int>(1, (a, b) => b > a ? b : a);
      radar = (mw.values.toList()..sort((a, b) => b.compareTo(a)))
          .take(6)
          .map((v) => v / maxM)
          .toList();
      if (radar.length < 3) radar = const [0.85, 0.6, 0.9, 0.5, 0.7];
    } else {
      radar = const [0.85, 0.6, 0.9, 0.5, 0.7];
    }
    final maxV = p.maxValue == 0 ? 1.0 : p.maxValue;
    final ring = (((resolveNumber(p.valueBinding, data) ?? (maxV * 0.7)) / maxV))
        .clamp(0.0, 1.0)
        .toDouble();
    return CustomPaint(
      size: Size.infinite,
      painter: _SeriesPainter(
        kind: p.kind,
        accent: _accent,
        series: series,
        radar: radar,
        ring: ring,
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

  // ─── chat bubble (iMessage / WhatsApp / AI-chat / comment / DM) ───
  Widget _chatBubble(ChatBubbleProps p) {
    final sender =
        resolveText(p.senderBinding, data, literalFallback: p.sender);
    final text = resolveText(p.textBinding, data, literalFallback: p.text);
    final base = cardFontByIndex(p.fontIndex).style;
    final isRight = p.side == ChatSide.right;
    final bubble = Container(
      padding: EdgeInsets.symmetric(
          horizontal: p.fontSize * 0.7, vertical: p.fontSize * 0.5),
      decoration: BoxDecoration(
        color: p.tint,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(p.cornerRadius),
          topRight: Radius.circular(p.cornerRadius),
          bottomLeft: Radius.circular(
              p.showTail && !isRight ? p.cornerRadius * 0.18 : p.cornerRadius),
          bottomRight: Radius.circular(
              p.showTail && isRight ? p.cornerRadius * 0.18 : p.cornerRadius),
        ),
      ),
      child: Text(
        text,
        style: base.copyWith(
          color: p.textColor,
          fontSize: p.fontSize,
          height: 1.18,
        ),
      ),
    );
    return Align(
      alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (sender.trim().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(
                  bottom: p.fontSize * 0.22,
                  left: p.fontSize * 0.3,
                  right: p.fontSize * 0.3),
              child: Text(
                sender,
                style: base.copyWith(
                  color: p.textColor.withValues(alpha: 0.7),
                  fontSize: p.fontSize * 0.62,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          Flexible(child: bubble),
        ],
      ),
    );
  }

  // ─── avatar row (social header) ───
  Widget _avatarRow(AvatarRowProps p) {
    final handle = resolveText(p.handleBinding, data, literalFallback: p.handle);
    final sub = resolveText(p.subBinding, data, literalFallback: p.sub);
    final avatarUrl = resolvePhotoUrl(p.avatar, data);
    final base = cardFontByIndex(p.fontIndex).style;
    final dim = box.height.clamp(1.0, double.infinity);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipOval(
          child: SizedBox(
            width: dim,
            height: dim,
            child: ColoredBox(
              color: p.textColor.withValues(alpha: 0.12),
              child: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? FoodImage(url: avatarUrl, fit: BoxFit.cover)
                  : Center(
                      child: Text(p.fallbackGlyph,
                          style: TextStyle(fontSize: dim * 0.5)),
                    ),
            ),
          ),
        ),
        SizedBox(width: dim * 0.28),
        Flexible(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: base.copyWith(
                        color: p.textColor,
                        fontSize: p.fontSize,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (p.verified) ...[
                    SizedBox(width: p.fontSize * 0.2),
                    Icon(Icons.verified_rounded,
                        color: const Color(0xFF1DA1F2),
                        size: p.fontSize * 0.85),
                  ],
                ],
              ),
              if (sub.trim().isNotEmpty)
                Text(
                  sub,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: base.copyWith(
                    color: p.subColor,
                    fontSize: p.fontSize * 0.66,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── scrubber (now-playing / podcast) ───
  Widget _scrubber(ScrubberProps p) {
    final labelStyle = TextStyle(
      color: p.textColor,
      fontSize: p.fontSize,
      fontWeight: FontWeight.w600,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: math.max(p.trackHeight, p.showKnob ? p.trackHeight * 2.6 : p.trackHeight),
          child: CustomPaint(
            size: Size.infinite,
            painter: _ScrubberPainter(
              progress: p.progress.clamp(0.0, 1.0),
              trackColor: p.trackColor,
              fillColor: p.fillColor,
              knobColor: p.knobColor,
              trackHeight: p.trackHeight,
              showKnob: p.showKnob,
            ),
          ),
        ),
        SizedBox(height: p.fontSize * 0.4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(p.leftLabel, style: labelStyle),
            Text(p.rightLabel, style: labelStyle),
          ],
        ),
      ],
    );
  }

  // ─── ring stat (single radial + center value) ───
  Widget _ringStat(RingStatProps p) {
    final maxV = p.maxValue == 0 ? 1.0 : p.maxValue;
    final bound = resolveNumber(p.valueBinding, data);
    final frac = (p.valueBinding.isLiteral || bound == null
            ? p.progress
            : bound / maxV)
        .clamp(0.0, 1.0)
        .toDouble();
    final center =
        resolveText(p.centerBinding, data, literalFallback: p.centerValue);
    final base = cardFontByIndex(p.fontIndex).style;
    return Stack(
      alignment: Alignment.center,
      children: [
        CustomPaint(
          size: Size.infinite,
          painter: _RingStatPainter(
            progress: frac,
            ringColor: p.ringColor,
            trackColor: p.trackColor,
            strokeFraction: p.strokeFraction,
          ),
        ),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                center,
                style: base.copyWith(
                  color: p.textColor,
                  fontSize: p.centerFontSize,
                  fontWeight: FontWeight.w900,
                  height: 0.95,
                ),
              ),
              if (p.label.trim().isNotEmpty)
                Text(
                  p.label,
                  style: base.copyWith(
                    color: p.textColor.withValues(alpha: 0.75),
                    fontSize: p.labelFontSize,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── ring trio (Apple rings) ───
  Widget _ringTrio(RingTrioProps p) {
    return CustomPaint(
      size: Size.infinite,
      painter: _RingTrioPainter(
        fracs: [
          p.outer.clamp(0.0, 1.0),
          p.middle.clamp(0.0, 1.0),
          p.inner.clamp(0.0, 1.0),
        ],
        colors: [p.outerColor, p.middleColor, p.innerColor],
        strokeFraction: p.strokeFraction,
        trackOpacity: p.trackOpacity,
      ),
    );
  }

  // ─── stat grid (2×N label/value tiles) ───
  Widget _statGrid(StatGridProps p) {
    final cols = p.columns < 1 ? 1 : p.columns;
    final base = cardFontByIndex(p.valueFontIndex).style;
    Widget tile(List<String> t) => Container(
          padding: EdgeInsets.all(p.spacing * 1.1),
          decoration: BoxDecoration(
            color: p.tileColor,
            borderRadius: BorderRadius.circular(p.cornerRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  t.isNotEmpty ? t[0] : '',
                  style: base.copyWith(
                    color: p.valueColor,
                    fontSize: p.valueFontSize,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ),
              SizedBox(height: p.spacing * 0.35),
              Text(
                t.length > 1 ? t[1] : '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: base.copyWith(
                  color: p.labelColor,
                  fontSize: p.labelFontSize,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );
    final rows = <Widget>[];
    for (var i = 0; i < p.tiles.length; i += cols) {
      final rowTiles = <Widget>[];
      for (var c = 0; c < cols; c++) {
        final idx = i + c;
        if (c > 0) rowTiles.add(SizedBox(width: p.spacing));
        rowTiles.add(Expanded(
          child: idx < p.tiles.length
              ? tile(p.tiles[idx])
              : const SizedBox.shrink(),
        ));
      }
      if (rows.isNotEmpty) rows.add(SizedBox(height: p.spacing));
      // IntrinsicHeight is REQUIRED: the outer Column lays each row out with an
      // unbounded main-axis (height) constraint to measure it, and a Row with
      // `crossAxisAlignment.stretch` under unbounded height throws
      // "BoxConstraints forces an infinite height" (it tries to stretch its
      // tiles to an infinite cross-axis). IntrinsicHeight pins the row to its
      // tallest tile's natural height so stretch has a finite extent to fill.
      rows.add(IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: rowTiles,
        ),
      ));
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: rows,
    );
  }

  // ─── grid heatmap (calendar / contribution grid) ───
  Widget _gridHeatmap(GridHeatmapProps p) {
    final cells = p.cells.isNotEmpty
        ? p.cells
        : List<double>.generate(
            p.columns * 7, (i) => ((i * 53 + 17) % 11) / 10.0);
    return CustomPaint(
      size: Size.infinite,
      painter: _GridHeatmapPainter(
        cells: cells,
        columns: p.columns < 1 ? 1 : p.columns,
        cellColor: p.cellColor,
        emptyColor: p.emptyColor,
        cellRadius: p.cellRadius,
        gapFraction: p.gapFraction,
      ),
    );
  }

  // ─── rating stars (reviews) ───
  Widget _ratingStars(RatingStarsProps p) {
    return CustomPaint(
      size: Size.infinite,
      painter: _StarsPainter(
        rating: p.rating,
        count: p.count < 1 ? 1 : p.count,
        filledColor: p.filledColor,
        emptyColor: p.emptyColor,
        spacingFraction: p.spacingFraction,
      ),
    );
  }

  // ─── barcode (ticket / boarding-pass / receipt / stamp) ───
  Widget _barcode(BarcodeProps p) {
    final caption =
        resolveText(p.captionBinding, data, literalFallback: p.caption);
    return DecoratedBox(
      decoration: BoxDecoration(color: p.background),
      child: Padding(
        padding: EdgeInsets.all(box.shortestSide * 0.06),
        child: Column(
          children: [
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _BarcodePainter(data: p.data, barColor: p.barColor),
              ),
            ),
            if (p.showCaption && caption.trim().isNotEmpty) ...[
              SizedBox(height: box.shortestSide * 0.04),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  caption,
                  style: TextStyle(
                    color: p.captionColor,
                    fontSize: p.captionFontSize,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                    fontFamily: 'Space Mono',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── perforation (ticket / boarding-pass tear line) ───
  Widget _perforation(PerforationProps p) {
    return CustomPaint(
      size: Size.infinite,
      painter: _PerforationPainter(
        edge: p.edge,
        color: p.color,
        dashLength: p.dashLength,
        gapLength: p.gapLength,
        thickness: p.thickness,
        notchRadius: p.notchRadius,
        notchColor: p.notchColor,
        showNotches: p.showNotches,
      ),
    );
  }
}

// ─────────────────────────── Painters ─────────────────────────────────────

class _SeriesPainter extends CustomPainter {
  final ChartKind kind;
  final Color accent;
  final List<double> series;
  final List<double> radar;
  final double ring;
  const _SeriesPainter({
    required this.kind,
    required this.accent,
    required this.series,
    required this.radar,
    required this.ring,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.shortestSide * 0.09;
    switch (kind) {
      case ChartKind.macro:
        break;
      case ChartKind.bars:
        final n = series.length;
        final maxV = series.fold<double>(0.0001, (a, b) => b > a ? b : a);
        final gap = size.width * 0.03;
        final bw = (size.width - gap * (n - 1)) / n;
        for (var i = 0; i < n; i++) {
          final f = series[i] / maxV;
          final h = f * size.height;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              Rect.fromLTWH(i * (bw + gap), size.height - h, bw, h),
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
            Paint()..color = accent.withValues(alpha: 0.45 + 0.55 * f),
          );
        }
      case ChartKind.line:
        final n = series.length;
        final maxV = series.fold<double>(0.0001, (a, b) => b > a ? b : a);
        final path = Path();
        for (var i = 0; i < n; i++) {
          final x = n == 1 ? size.width / 2 : i / (n - 1) * size.width;
          final y = size.height -
              (series[i] / maxV) * size.height * 0.9 -
              size.height * 0.05;
          i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
        }
        canvas.drawPath(
          path,
          Paint()
            ..color = accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = math.max(2.0, size.shortestSide * 0.03)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      case ChartKind.ring:
        final c = size.center(Offset.zero);
        final r = size.shortestSide / 2 - sw;
        canvas.drawCircle(
            c,
            r,
            Paint()
              ..color = const Color(0x22FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw);
        canvas.drawArc(
            Rect.fromCircle(center: c, radius: r),
            -math.pi / 2,
            2 * math.pi * ring,
            false,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw
              ..strokeCap = StrokeCap.round);
      case ChartKind.appleRings:
        final c = size.center(Offset.zero);
        const colors = [Color(0xFFFA114F), Color(0xFF92E82A), Color(0xFF1AD6FD)];
        const fracs = [0.82, 0.7, 0.6];
        for (var i = 0; i < 3; i++) {
          final r = size.shortestSide / 2 - sw - i * (sw * 1.25);
          if (r <= 0) continue;
          canvas.drawCircle(
              c,
              r,
              Paint()
                ..color = colors[i].withValues(alpha: 0.2)
                ..style = PaintingStyle.stroke
                ..strokeWidth = sw);
          canvas.drawArc(
              Rect.fromCircle(center: c, radius: r),
              -math.pi / 2,
              2 * math.pi * fracs[i],
              false,
              Paint()
                ..color = colors[i]
                ..style = PaintingStyle.stroke
                ..strokeWidth = sw
                ..strokeCap = StrokeCap.round);
        }
      case ChartKind.radar:
        final c = size.center(Offset.zero);
        final radius = size.shortestSide / 2 * 0.9;
        final n = radar.length;
        Offset pt(int i, double f) {
          final a = -math.pi / 2 + 2 * math.pi * i / n;
          return c + Offset(math.cos(a), math.sin(a)) * radius * f;
        }
        final grid = Path();
        for (var i = 0; i < n; i++) {
          final pp = pt(i, 1);
          i == 0 ? grid.moveTo(pp.dx, pp.dy) : grid.lineTo(pp.dx, pp.dy);
        }
        grid.close();
        canvas.drawPath(
            grid,
            Paint()
              ..color = const Color(0x22FFFFFF)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5);
        final poly = Path();
        for (var i = 0; i < n; i++) {
          final pp = pt(i, radar[i].clamp(0.1, 1.0));
          i == 0 ? poly.moveTo(pp.dx, pp.dy) : poly.lineTo(pp.dx, pp.dy);
        }
        poly.close();
        canvas.drawPath(poly, Paint()..color = accent.withValues(alpha: 0.28));
        canvas.drawPath(
            poly,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = math.max(2.0, size.shortestSide * 0.022)
              ..strokeJoin = StrokeJoin.round);
      case ChartKind.heatmap:
        const cols = 10;
        final rows = (series.length / cols).ceil().clamp(3, 7);
        final cell = math.min(size.width / cols, size.height / rows);
        final gap = cell * 0.16;
        for (var r = 0; r < rows; r++) {
          for (var col = 0; col < cols; col++) {
            final idx = r * cols + col;
            final v = idx < series.length
                ? series[idx].clamp(0.0, 1.0)
                : ((idx * 37) % 10) / 10;
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(col * cell + gap / 2, r * cell + gap / 2,
                    cell - gap, cell - gap),
                const Radius.circular(2),
              ),
              Paint()..color = accent.withValues(alpha: 0.15 + 0.85 * v),
            );
          }
        }
    }
  }

  @override
  bool shouldRepaint(_SeriesPainter old) =>
      old.kind != kind ||
      old.accent != accent ||
      old.ring != ring ||
      old.series != series ||
      old.radar != radar;
}

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

class _ScrubberPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color fillColor;
  final Color knobColor;
  final double trackHeight;
  final bool showKnob;
  const _ScrubberPainter({
    required this.progress,
    required this.trackColor,
    required this.fillColor,
    required this.knobColor,
    required this.trackHeight,
    required this.showKnob,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cy = size.height / 2;
    final r = trackHeight / 2;
    final track = RRect.fromRectAndRadius(
        Rect.fromLTWH(0, cy - r, size.width, trackHeight), Radius.circular(r));
    canvas.drawRRect(track, Paint()..color = trackColor);
    final fillW = (size.width * progress).clamp(0.0, size.width);
    if (fillW > 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, cy - r, fillW, trackHeight), Radius.circular(r)),
        Paint()..color = fillColor,
      );
    }
    if (showKnob) {
      canvas.drawCircle(
          Offset(fillW.clamp(0.0, size.width), cy),
          math.max(trackHeight * 1.3, 6),
          Paint()..color = knobColor);
    }
  }

  @override
  bool shouldRepaint(_ScrubberPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.fillColor != fillColor ||
      old.knobColor != knobColor ||
      old.trackHeight != trackHeight ||
      old.showKnob != showKnob;
}

class _RingStatPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeFraction;
  const _RingStatPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final sw = size.shortestSide * strokeFraction.clamp(0.02, 0.4);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - sw / 2;
    if (r <= 0) return;
    canvas.drawCircle(
        c,
        r,
        Paint()
          ..color = trackColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw);
    canvas.drawArc(
        Rect.fromCircle(center: c, radius: r),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        Paint()
          ..color = ringColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(_RingStatPainter old) =>
      old.progress != progress ||
      old.ringColor != ringColor ||
      old.trackColor != trackColor ||
      old.strokeFraction != strokeFraction;
}

class _RingTrioPainter extends CustomPainter {
  final List<double> fracs;
  final List<Color> colors;
  final double strokeFraction;
  final double trackOpacity;
  const _RingTrioPainter({
    required this.fracs,
    required this.colors,
    required this.strokeFraction,
    required this.trackOpacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final sw = size.shortestSide * strokeFraction.clamp(0.02, 0.2);
    for (var i = 0; i < 3; i++) {
      final r = size.shortestSide / 2 - sw / 2 - i * (sw * 1.4);
      if (r <= 0) continue;
      canvas.drawCircle(
          c,
          r,
          Paint()
            ..color = colors[i].withValues(alpha: trackOpacity.clamp(0.0, 1.0))
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw);
      canvas.drawArc(
          Rect.fromCircle(center: c, radius: r),
          -math.pi / 2,
          2 * math.pi * fracs[i],
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = sw
            ..strokeCap = StrokeCap.round);
    }
  }

  @override
  bool shouldRepaint(_RingTrioPainter old) =>
      old.fracs != fracs ||
      old.colors != colors ||
      old.strokeFraction != strokeFraction ||
      old.trackOpacity != trackOpacity;
}

class _GridHeatmapPainter extends CustomPainter {
  final List<double> cells;
  final int columns;
  final Color cellColor;
  final Color emptyColor;
  final double cellRadius;
  final double gapFraction;
  const _GridHeatmapPainter({
    required this.cells,
    required this.columns,
    required this.cellColor,
    required this.emptyColor,
    required this.cellRadius,
    required this.gapFraction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rows = (cells.length / columns).ceil().clamp(1, 999);
    final cell = math.min(size.width / columns, size.height / rows);
    final gap = cell * gapFraction.clamp(0.0, 0.5);
    final inner = cell - gap;
    if (inner <= 0) return;
    // Center the grid within the slot.
    final gridW = columns * cell;
    final gridH = rows * cell;
    final ox = (size.width - gridW) / 2;
    final oy = (size.height - gridH) / 2;
    for (var i = 0; i < columns * rows; i++) {
      final col = i % columns;
      final row = i ~/ columns;
      final v = i < cells.length ? cells[i].clamp(0.0, 1.0) : 0.0;
      final color = v <= 0.001
          ? emptyColor
          : Color.lerp(emptyColor, cellColor, 0.25 + 0.75 * v)!;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(ox + col * cell + gap / 2, oy + row * cell + gap / 2,
              inner, inner),
          Radius.circular(cellRadius),
        ),
        Paint()..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_GridHeatmapPainter old) =>
      old.cells != cells ||
      old.columns != columns ||
      old.cellColor != cellColor ||
      old.emptyColor != emptyColor ||
      old.cellRadius != cellRadius ||
      old.gapFraction != gapFraction;
}

class _StarsPainter extends CustomPainter {
  final double rating;
  final int count;
  final Color filledColor;
  final Color emptyColor;
  final double spacingFraction;
  const _StarsPainter({
    required this.rating,
    required this.count,
    required this.filledColor,
    required this.emptyColor,
    required this.spacingFraction,
  });

  Path _starPath(Offset c, double r) {
    final path = Path();
    const points = 5;
    final inner = r * 0.42;
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? r : inner;
      final a = -math.pi / 2 + i * math.pi / points;
      final pt = c + Offset(math.cos(a), math.sin(a)) * radius;
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final gap = size.width * spacingFraction.clamp(0.0, 0.5) / count;
    final slot = (size.width - gap * (count - 1)) / count;
    final r = math.min(slot, size.height) / 2;
    for (var i = 0; i < count; i++) {
      final cx = i * (slot + gap) + slot / 2;
      final c = Offset(cx, size.height / 2);
      final fill = (rating - i).clamp(0.0, 1.0);
      final star = _starPath(c, r);
      canvas.drawPath(star, Paint()..color = emptyColor);
      if (fill > 0) {
        if (fill >= 1) {
          canvas.drawPath(star, Paint()..color = filledColor);
        } else {
          canvas.save();
          canvas.clipRect(
              Rect.fromLTWH(cx - r, c.dy - r, 2 * r * fill, 2 * r));
          canvas.drawPath(star, Paint()..color = filledColor);
          canvas.restore();
        }
      }
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) =>
      old.rating != rating ||
      old.count != count ||
      old.filledColor != filledColor ||
      old.emptyColor != emptyColor ||
      old.spacingFraction != spacingFraction;
}

class _BarcodePainter extends CustomPainter {
  final String data;
  final Color barColor;
  const _BarcodePainter({required this.data, required this.barColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = barColor;
    // Deterministic stripe widths seeded from [data] — looks like a real
    // Code-128 barcode without needing an encoder.
    final seed = data.isEmpty ? 'ZEALOVA'.codeUnits : data.codeUnits;
    var x = 0.0;
    var i = 0;
    var bar = true;
    while (x < size.width) {
      final unit = size.width / 64;
      final w = unit * (1 + (seed[i % seed.length] % 4));
      if (bar) {
        canvas.drawRect(
            Rect.fromLTWH(x, 0, math.min(w, size.width - x), size.height),
            paint);
      }
      x += w;
      bar = !bar;
      i++;
    }
  }

  @override
  bool shouldRepaint(_BarcodePainter old) =>
      old.data != data || old.barColor != barColor;
}

class _PerforationPainter extends CustomPainter {
  final PerforationEdge edge;
  final Color color;
  final double dashLength;
  final double gapLength;
  final double thickness;
  final double notchRadius;
  final Color notchColor;
  final bool showNotches;
  const _PerforationPainter({
    required this.edge,
    required this.color,
    required this.dashLength,
    required this.gapLength,
    required this.thickness,
    required this.notchRadius,
    required this.notchColor,
    required this.showNotches,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bool vertical =
        edge == PerforationEdge.left || edge == PerforationEdge.right;
    // Resolve the line endpoints for the chosen edge.
    late Offset a;
    late Offset b;
    switch (edge) {
      case PerforationEdge.top:
        a = const Offset(0, 0);
        b = Offset(size.width, 0);
      case PerforationEdge.bottom:
        a = Offset(0, size.height);
        b = Offset(size.width, size.height);
      case PerforationEdge.left:
        a = const Offset(0, 0);
        b = Offset(0, size.height);
      case PerforationEdge.right:
        a = Offset(size.width, 0);
        b = Offset(size.width, size.height);
      case PerforationEdge.horizontalCenter:
        a = Offset(0, size.height / 2);
        b = Offset(size.width, size.height / 2);
    }
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round;
    final notchPaint = Paint()..color = notchColor;
    final total = vertical ? size.height : size.width;
    final step = dashLength + gapLength;
    final start = showNotches ? notchRadius : 0.0;
    final endPad = showNotches ? notchRadius : 0.0;
    var pos = start;
    while (pos < total - endPad) {
      final end = math.min(pos + dashLength, total - endPad);
      if (vertical) {
        canvas.drawLine(Offset(a.dx, pos), Offset(a.dx, end), paint);
      } else {
        canvas.drawLine(Offset(pos, a.dy), Offset(end, a.dy), paint);
      }
      pos += step;
    }
    if (showNotches) {
      // Punched circles cut at each end of the tear line.
      canvas.drawCircle(a, notchRadius, notchPaint);
      canvas.drawCircle(b, notchRadius, notchPaint);
    }
  }

  @override
  bool shouldRepaint(_PerforationPainter old) =>
      old.edge != edge ||
      old.color != color ||
      old.dashLength != dashLength ||
      old.gapLength != gapLength ||
      old.thickness != thickness ||
      old.notchRadius != notchRadius ||
      old.notchColor != notchColor ||
      old.showNotches != showNotches;
}
