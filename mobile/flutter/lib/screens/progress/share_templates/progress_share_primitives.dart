import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'progress_share_data.dart';

/// Fixed-size canvas wrapper so every template renders at the same pixel
/// dimensions. Each template is laid out against [kProgressShareCanvas].
class ProgressTemplateCanvas extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final Gradient? gradient;
  final BorderRadius? borderRadius;

  const ProgressTemplateCanvas({
    super.key,
    required this.child,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(20);
    return SizedBox(
      width: kProgressShareCanvas.width,
      height: kProgressShareCanvas.height,
      child: ClipRRect(
        borderRadius: br,
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.black,
            gradient: gradient,
          ),
          child: child,
        ),
      ),
    );
  }
}

class ProgressShareImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  const ProgressShareImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    Widget img = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: 800,
      placeholder: (_, __) => Container(color: Colors.black26),
      errorWidget: (_, __, ___) => Container(
        color: Colors.black26,
        child: const Center(
          child: Icon(Icons.broken_image_outlined, color: Colors.white54),
        ),
      ),
    );
    if (borderRadius != null) img = ClipRRect(borderRadius: borderRadius!, child: img);
    return img;
  }
}

class ProgressShareWatermark extends StatelessWidget {
  final Color color;
  final bool compact;

  const ProgressShareWatermark({
    super.key,
    this.color = Colors.white70,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 14 : 18,
          height: compact ? 14 : 18,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B6B), Color(0xFF9D4EDD)],
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(Icons.bolt_rounded, color: Colors.white, size: compact ? 9 : 12),
        ),
        SizedBox(width: compact ? 4 : 6),
        Text(
          'fitwiz',
          style: TextStyle(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

/// Formats "DD.MM.YY" like the reference Instagram story — user the
/// original screenshot shows that format, not en-US.
String formatCompactDate(DateTime d) =>
    DateFormat('dd.MM.yy').format(d);

String formatPrettyDate(DateTime d) =>
    DateFormat('MMM d, yyyy').format(d);
