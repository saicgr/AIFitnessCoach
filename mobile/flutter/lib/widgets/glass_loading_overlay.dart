import 'dart:ui';

import 'package:flutter/material.dart';

/// Full-screen glassmorphic loading overlay used during long-running blocking
/// async work (workout completion API call, regenerate workout, etc.) so the
/// app never sits silent for 4-5 seconds without an affordance.
///
/// Use [showGlassLoadingOverlay] to present and grab the close handle. Always
/// pop the returned `OverlayEntry` (or call [dismiss]) in a `finally` block to
/// avoid leaving the overlay stuck if the awaited future throws.
class GlassLoadingOverlay extends StatelessWidget {
  final String message;
  final IconData? icon;

  const GlassLoadingOverlay({
    super.key,
    this.message = 'Working on it…',
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Translucent enough to read as glass, opaque enough to stay light
    // in light mode. Previous 0.72 white composited over the 0.25 black
    // scrim to a muddy gray that read as a dark card.
    final fill = isDark
        ? const Color(0xFF1C1C1E).withValues(alpha: 0.86)
        : Colors.white.withValues(alpha: 0.94);
    final border = isDark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.black.withValues(alpha: 0.06);
    final textPrimary = isDark ? Colors.white : Colors.black87;

    return PopScope(
      canPop: false,
      // The OverlayEntry has no MaterialApp ancestor wrapping its subtree, so
      // a bare `Text` here renders with the debug yellow-underline default.
      // `Material(type: transparency)` provides the DefaultTextStyle without
      // adding a visible surface, fixing the underline-on-loader bug.
      child: Material(
        type: MaterialType.transparency,
        child: Container(
        color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.25),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 24),
                constraints: const BoxConstraints(minWidth: 220),
                decoration: BoxDecoration(
                  color: fill,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: border, width: 1),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: isDark ? 0.06 : 0.18),
                      Colors.transparent,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(alpha: isDark ? 0.45 : 0.18),
                      blurRadius: 28,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 28, color: textPrimary),
                      const SizedBox(height: 10),
                    ] else ...[
                      const SizedBox(
                        width: 32,
                        height: 32,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        ),
      ),
    );
  }
}

/// Inserts a [GlassLoadingOverlay] into the active [Overlay]. Returns a
/// dismiss callback the caller MUST run in a `finally` block.
GlassLoadingOverlayHandle showGlassLoadingOverlay(
  BuildContext context, {
  String message = 'Working on it…',
  IconData? icon,
}) {
  final entry = OverlayEntry(
    builder: (_) => GlassLoadingOverlay(message: message, icon: icon),
  );
  Overlay.of(context, rootOverlay: true).insert(entry);
  return GlassLoadingOverlayHandle._(entry);
}

class GlassLoadingOverlayHandle {
  final OverlayEntry _entry;
  bool _dismissed = false;
  GlassLoadingOverlayHandle._(this._entry);

  void dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    _entry.remove();
  }
}
