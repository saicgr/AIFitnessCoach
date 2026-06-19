import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/config/science_citations.dart';

/// Opens a citation's source URL in the external browser. Shared by every
/// citation surface so the "verify-me" behaviour is identical everywhere.
Future<void> openCitation(ScienceCitation citation) async {
  final uri = Uri.parse(citation.url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// A tappable, underlined "source → " link rendering a [ScienceCitation]'s
/// source label. "Verify-me beats trust-me": every authority claim we show
/// can be tapped through to the primary source.
///
/// Gives a tactile press state + light haptic before opening (premium feel
/// requirement). [accent] colours the label + arrow; defaults to the ambient
/// text style colour when null.
class CitationLink extends StatefulWidget {
  final ScienceCitation citation;
  final Color? accent;
  final double fontSize;

  /// Optional leading label, e.g. "Source: ". When null only the source
  /// label + arrow render.
  final String? leading;

  const CitationLink({
    super.key,
    required this.citation,
    this.accent,
    this.fontSize = 12,
    this.leading,
  });

  @override
  State<CitationLink> createState() => _CitationLinkState();
}

class _CitationLinkState extends State<CitationLink> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.accent ??
        DefaultTextStyle.of(context).style.color ??
        Theme.of(context).colorScheme.primary;

    return Semantics(
      link: true,
      label: '${widget.citation.source}. Opens the source in your browser.',
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.lightImpact();
          openCitation(widget.citation);
        },
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: AnimatedOpacity(
            opacity: _pressed ? 0.7 : 1.0,
            duration: const Duration(milliseconds: 120),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: widget.fontSize,
                  height: 1.35,
                ),
                children: [
                  if (widget.leading != null)
                    TextSpan(
                      text: widget.leading,
                      style: TextStyle(
                        color: color.withValues(alpha: 0.75),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  TextSpan(
                    text: widget.citation.source,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: color.withValues(alpha: 0.5),
                    ),
                  ),
                  TextSpan(
                    text: '  ↗',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
