import 'package:flutter/material.dart';

/// A dependency-free renderer for the small markdown subset the app's
/// AI summaries emit. We deliberately avoid `flutter_markdown` (no new pub
/// dependency, smaller surface area) and parse the exact constructs the
/// backend is prompted to produce:
///
///   - `## Header` / `### Header`  → bold, larger line
///   - `- bullet` / `* bullet`     → bullet row with a hanging indent
///   - `**bold**` inline spans     → bold runs inside any line
///   - blank lines                 → vertical spacing
///
/// Anything else renders as a normal paragraph. Inline `**bold**` is honored
/// inside headers, bullets, and paragraphs alike. Theme-aware text color.
///
/// This is intentionally line-oriented (parse per line) + a [RichText] per
/// line for the inline bold runs — robust enough for grounded coach copy
/// without pulling in a full CommonMark parser.
class SimpleMarkdownText extends StatelessWidget {
  /// The raw markdown string to render.
  final String data;

  /// Base font size for paragraph/bullet text. Headers scale up from this.
  final double baseFontSize;

  /// Base text color. Defaults to the theme's body color.
  final Color? color;

  /// Muted color for bullet glyphs / secondary accents. Defaults to a
  /// theme-appropriate translucent shade of [color].
  final Color? accentColor;

  const SimpleMarkdownText(
    this.data, {
    super.key,
    this.baseFontSize = 14,
    this.color,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor =
        color ??
        (isDark ? Colors.white.withValues(alpha: 0.92) : Colors.black87);
    final mutedColor =
        accentColor ??
        (isDark ? Colors.white.withValues(alpha: 0.55) : Colors.black54);

    final lines = data.replaceAll('\r\n', '\n').split('\n');
    final widgets = <Widget>[];

    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final trimmed = raw.trim();

      // Blank line → spacing (but never two stacked gaps).
      if (trimmed.isEmpty) {
        if (widgets.isNotEmpty && widgets.last is! SizedBox) {
          widgets.add(const SizedBox(height: 10));
        }
        continue;
      }

      // Headers: ## / ### (also tolerate a single # just in case).
      final headerMatch = RegExp(r'^(#{1,3})\s+(.*)$').firstMatch(trimmed);
      if (headerMatch != null) {
        final level = headerMatch.group(1)!.length;
        final text = headerMatch.group(2)!.trim();
        final headerSize = level <= 1
            ? baseFontSize + 5
            : (level == 2 ? baseFontSize + 3 : baseFontSize + 1);
        if (widgets.isNotEmpty) widgets.add(const SizedBox(height: 12));
        widgets.add(
          _line(
            text,
            baseStyle: TextStyle(
              fontSize: headerSize,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: baseColor,
              letterSpacing: -0.2,
            ),
          ),
        );
        widgets.add(const SizedBox(height: 6));
        continue;
      }

      // Bullets: - or * (with optional leading whitespace).
      final bulletMatch = RegExp(r'^[-*]\s+(.*)$').firstMatch(trimmed);
      if (bulletMatch != null) {
        final text = bulletMatch.group(1)!.trim();
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 9, left: 2),
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: mutedColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Expanded(
                  child: _line(
                    text,
                    baseStyle: TextStyle(
                      fontSize: baseFontSize,
                      height: 1.4,
                      color: baseColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal paragraph line.
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: _line(
            trimmed,
            baseStyle: TextStyle(
              fontSize: baseFontSize,
              height: 1.45,
              color: baseColor,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgets,
    );
  }

  /// Render a single logical line, honoring inline `**bold**` runs.
  Widget _line(String text, {required TextStyle baseStyle}) {
    return RichText(
      text: TextSpan(style: baseStyle, children: _inlineSpans(text, baseStyle)),
    );
  }

  /// Split a line into alternating normal / **bold** spans. Unmatched `**`
  /// (odd count) is treated as literal text so we never drop characters.
  List<TextSpan> _inlineSpans(String text, TextStyle baseStyle) {
    final spans = <TextSpan>[];
    final pattern = RegExp(r'\*\*(.+?)\*\*');
    var lastEnd = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, m.start)));
      }
      spans.add(
        TextSpan(
          text: m.group(1),
          style: baseStyle.copyWith(fontWeight: FontWeight.w800),
        ),
      );
      lastEnd = m.end;
    }
    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }
    return spans;
  }
}
