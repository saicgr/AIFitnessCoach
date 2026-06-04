/// A labeled group of contextual cards whose header **only appears when at
/// least one child actually renders content** (issue 7).
///
/// The child cards each self-collapse to `SizedBox.shrink()` when their gate
/// fails, so a group can be entirely empty on any given day. Rather than
/// duplicate every card's gating logic, this wrapper measures the rendered
/// height of the card column after layout and shows/hides the header
/// accordingly — no orphan section header floating over nothing.
///
/// Extracted from the old private `_HomeCardSection` in
/// `extended_home_cards_stack.dart` so the Home feed AND the Workouts tab
/// ("Around your workout") share one implementation.
///
/// Optionally [collapsible]: the header becomes a tap target with a chevron
/// and the card stack collapses/expands beneath it. When [initiallyCollapsed]
/// the stack starts closed (just header + optional [collapsedSubtitle]) so a
/// dense post-workout group doesn't dominate the screen until the user opens
/// it. The body is always laid out (so content-presence measurement still
/// works) but clipped to zero height while collapsed.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/theme_colors.dart';

class SelfHidingCardSection extends StatefulWidget {
  final String title;
  final List<Widget> children;

  /// When true, the header is tappable and toggles the card stack open/closed.
  final bool collapsible;

  /// When true (and [collapsible]), the stack starts collapsed.
  final bool initiallyCollapsed;

  /// One-line hint shown under the title while collapsed (e.g. what's inside).
  final String? collapsedSubtitle;

  const SelfHidingCardSection({
    super.key,
    required this.title,
    required this.children,
    this.collapsible = false,
    this.initiallyCollapsed = false,
    this.collapsedSubtitle,
  });

  @override
  State<SelfHidingCardSection> createState() => _SelfHidingCardSectionState();
}

class _SelfHidingCardSectionState extends State<SelfHidingCardSection> {
  final GlobalKey _bodyKey = GlobalKey();
  bool _hasContent = false;
  // Guards the post-frame measurement so it runs ONCE per build, not on every
  // frame. The old code re-armed addPostFrameCallback on every build, turning
  // each section into a per-frame layout probe (findRenderObject) — a major
  // source of scroll jank with ~11 sections live.
  bool _measureScheduled = false;

  late bool _collapsed = widget.collapsible && widget.initiallyCollapsed;

  void _measure() {
    _measureScheduled = false;
    if (!mounted) return;
    final ctx = _bodyKey.currentContext;
    if (ctx == null) return;
    final ro = ctx.findRenderObject();
    final h = (ro is RenderBox && ro.hasSize) ? ro.size.height : 0.0;
    final has = h > 1.0;
    if (has != _hasContent) setState(() => _hasContent = has);
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  Widget build(BuildContext context) {
    // Measure once per build (de-duped via _measureScheduled) instead of
    // re-arming a post-frame layout probe on every frame. The child cards
    // self-collapse via their own providers; when one flips it rebuilds the
    // affected card subtree, the parent SliverList relayouts, and this build
    // runs again — re-arming exactly one measurement. setState only fires on an
    // actual content flip, so there's no rebuild loop.
    _scheduleMeasure();
    final c = ThemeColors.of(context);

    // The card column is ALWAYS built so the content-presence measurement keeps
    // working even while collapsed; `Align(heightFactor: 0)` lays the children
    // out at their natural size (so `_bodyKey` has a real height to measure) but
    // reports zero height to the parent, and `ClipRect` hides the overflow.
    final body = ClipRect(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _collapsed ? 0.0 : 1.0,
          child: Column(
            key: _bodyKey,
            mainAxisSize: MainAxisSize.min,
            children: widget.children,
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: _hasContent
              ? _buildHeader(c)
              : const SizedBox.shrink(),
        ),
        body,
      ],
    );
  }

  Widget _buildHeader(ThemeColors c) {
    final titleText = Text(
      widget.title.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.8,
        color: c.textMuted,
      ),
    );

    if (!widget.collapsible) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 16, 6),
        child: titleText,
      );
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _collapsed = !_collapsed),
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 12, _collapsed ? 10 : 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    titleText,
                    if (_collapsed && widget.collapsedSubtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        widget.collapsedSubtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: c.textMuted.withValues(alpha: 0.85),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedRotation(
                duration: const Duration(milliseconds: 200),
                turns: _collapsed ? 0.0 : 0.5,
                child: Icon(Icons.expand_more, size: 22, color: c.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
