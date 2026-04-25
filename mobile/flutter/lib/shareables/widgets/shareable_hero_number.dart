import 'package:flutter/material.dart';

import '../shareable_data.dart';

/// Renders the hero number + pluralized unit. Always source the value
/// through this widget so we get pluralization everywhere — never let
/// templates interpolate `${value} ${unit}` themselves.
class ShareableHeroNumber extends StatelessWidget {
  final Shareable data;
  final double size;
  final double unitSize;
  final Color color;
  final Color? unitColor;
  final bool stacked;
  final FontWeight weight;

  const ShareableHeroNumber({
    super.key,
    required this.data,
    this.size = 96,
    this.unitSize = 18,
    this.color = Colors.white,
    this.unitColor,
    this.stacked = false,
    this.weight = FontWeight.w900,
  });

  @override
  Widget build(BuildContext context) {
    final hero = shareableHeroString(data);
    final unit = shareableHeroUnit(data);

    final number = Text(
      hero,
      style: TextStyle(
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: 1,
        letterSpacing: -size * 0.025,
      ),
    );

    if (unit.isEmpty) return number;

    final unitWidget = Padding(
      padding: EdgeInsets.only(left: stacked ? 0 : 8, top: stacked ? 4 : 0),
      child: Text(
        unit,
        style: TextStyle(
          color: unitColor ?? data.accentColor,
          fontSize: unitSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.6,
        ),
      ),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [number, unitWidget],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [number, unitWidget],
    );
  }
}
