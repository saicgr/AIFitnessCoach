import 'package:flutter/material.dart';

import '../shareable_data.dart';

/// The kind of a movable element on the food-photo editor canvas. The photo
/// itself is the fixed background — not a layer.
enum EditorLayerKind {
  macroViz,
  text,
  emoji,
  gif,
  scoreBadge,
  dateStamp,
  watermark,
}

/// One draggable / resizable / rotatable element on the editor canvas.
/// [position] is normalized 0..1 of the canvas with a CENTER anchor, so the
/// layout is resolution-independent (the editor canvas and the capture
/// canvas are different pixel sizes but the same aspect).
@immutable
class EditorLayer {
  final String id;
  final EditorLayerKind kind;
  final Offset position;
  final double scale;
  final double rotation; // radians

  // ─── payload (only the relevant fields are used per kind) ───
  final String text; // text content / emoji glyph
  final int fontIndex; // index into [kEditorFonts]
  final Color color;
  final MacroVizStyle macroStyle;
  final String gifUrl; // GIPHY GIF url for a `gif` layer

  const EditorLayer({
    required this.id,
    required this.kind,
    this.position = const Offset(0.5, 0.5),
    this.scale = 1.0,
    this.rotation = 0.0,
    this.text = '',
    this.fontIndex = 0,
    this.color = Colors.white,
    this.macroStyle = MacroVizStyle.coin,
    this.gifUrl = '',
  });

  EditorLayer copyWith({
    Offset? position,
    double? scale,
    double? rotation,
    String? text,
    int? fontIndex,
    Color? color,
    MacroVizStyle? macroStyle,
    String? gifUrl,
  }) {
    return EditorLayer(
      id: id,
      kind: kind,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      text: text ?? this.text,
      fontIndex: fontIndex ?? this.fontIndex,
      color: color ?? this.color,
      macroStyle: macroStyle ?? this.macroStyle,
      gifUrl: gifUrl ?? this.gifUrl,
    );
  }
}

/// A named text treatment for the editor's font picker — dependency-free
/// (weight / spacing / style / generic family variations), so it works
/// without bundling extra fonts.
class EditorFont {
  final String label;
  final TextStyle style;
  const EditorFont(this.label, this.style);
}

const List<EditorFont> kEditorFonts = [
  EditorFont('Classic', TextStyle(fontWeight: FontWeight.w700)),
  EditorFont('Heavy',
      TextStyle(fontWeight: FontWeight.w900, letterSpacing: -1.0)),
  EditorFont('Light',
      TextStyle(fontWeight: FontWeight.w300, letterSpacing: 0.5)),
  EditorFont('Serif',
      TextStyle(fontFamily: 'serif', fontWeight: FontWeight.w600)),
  EditorFont('Mono',
      TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w600)),
  EditorFont('Wide',
      TextStyle(fontWeight: FontWeight.w700, letterSpacing: 6.0)),
  EditorFont('Italic',
      TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600)),
  EditorFont('Pop',
      TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.0)),
];

/// Curated food / fitness emoji set for the sticker picker.
const List<String> kEditorEmojis = [
  '🔥', '💪', '🥗', '🍳', '🥑', '🍗', '🥦', '🍚', '🍝', '🍕',
  '💯', '✨', '😋', '🙌', '⚡', '🥄', '🍽️', '🧈', '🥛', '🍌',
  '☕', '🫐', '🍓', '🥚', '🧀', '🥜', '🍠', '🌮', '🍜', '🥨',
  '👏', '⭐', '🎯', '🏆', '😮‍💨', '🤤', '👀', '❤️', '🫶', '🥇',
];
