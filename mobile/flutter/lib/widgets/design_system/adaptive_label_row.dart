import 'package:flutter/material.dart';

/// A [Row] whose text label ellipsizes when it has to and keeps its natural
/// width when it doesn't.
///
/// Chips and pills live in two kinds of parent:
///
///  * a [Wrap], a card, or any bounded box — here an over-long label must
///    ellipsize or it paints a RenderFlex overflow stripe (and, in release,
///    silently clips);
///  * a horizontally-scrolling list — here the row is handed *unbounded* width,
///    and a flex child throws outright ("RenderFlex children have non-zero flex
///    but incoming width constraints are unbounded").
///
/// So neither a plain [Flexible] nor a plain [Text] is correct on its own. The
/// [LayoutBuilder] has to sit OUTSIDE the row to tell the two cases apart: a
/// [Row] hands every non-flex child unbounded main-axis constraints regardless
/// of its own, so a LayoutBuilder placed inside the row would always report
/// "unbounded" and never help.
///
/// ```dart
/// AdaptiveLabelRow(
///   leading: [Icon(Icons.timer, size: 12), const SizedBox(width: 6)],
///   label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
/// )
/// ```
class AdaptiveLabelRow extends StatelessWidget {
  /// Fixed-width widgets rendered before the label (icon, dot, spacing).
  final List<Widget> leading;

  /// The shrinkable label. Give it `maxLines` + `overflow` — this widget
  /// decides whether it *can* shrink, not how it looks when it does.
  final Widget label;

  /// Fixed-width widgets rendered after the label (trailing count, chevron).
  final List<Widget> trailing;

  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  const AdaptiveLabelRow({
    super.key,
    this.leading = const <Widget>[],
    required this.label,
    this.trailing = const <Widget>[],
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: mainAxisAlignment,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            ...leading,
            if (constraints.hasBoundedWidth) Flexible(child: label) else label,
            ...trailing,
          ],
        );
      },
    );
  }
}
