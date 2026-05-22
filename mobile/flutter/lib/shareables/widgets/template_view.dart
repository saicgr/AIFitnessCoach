/// Renders a [ShareableTemplateSpec] the right way during the migration to
/// the editable-card engine: a migrated spec (non-null `docBuilder`) renders
/// via [CardDocRenderer]; an un-migrated spec falls back to its legacy
/// `builder`. The catalog therefore works fully while half-migrated.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../doc/card_doc_renderer.dart';
import '../shareable_catalog.dart';
import '../shareable_data.dart';

class TemplateView extends StatelessWidget {
  final ShareableTemplateSpec spec;
  final Shareable data;
  final ShareableAspect aspect;
  final bool showWatermark;
  final double textScale;

  /// When set, this already-edited document is rendered instead of the
  /// preset — the share sheet passes the user's customized card here.
  final CardDoc? overrideDoc;

  /// When false, the food photo is stripped from the card (the share
  /// sheet's photo on/off toggle).
  final bool showPhoto;

  const TemplateView({
    super.key,
    required this.spec,
    required this.data,
    required this.aspect,
    this.showWatermark = true,
    this.textScale = 1.0,
    this.overrideDoc,
    this.showPhoto = true,
  });

  @override
  Widget build(BuildContext context) {
    var doc = overrideDoc ?? spec.docBuilder?.call(data, aspect);
    if (doc != null) {
      if (!showPhoto) doc = doc.withoutPhoto();
      return CardDocRenderer(
        doc: doc,
        data: data,
        showWatermark: showWatermark,
        textScale: textScale,
      );
    }
    // Legacy un-migrated template (or an empty box if neither path exists).
    final legacy = spec.builder;
    return legacy != null
        ? legacy(data, showWatermark)
        : const SizedBox.shrink();
  }
}
