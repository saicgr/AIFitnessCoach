import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Branded replacement for Flutter's default error box (red in debug, grey in
/// release). Installed globally via `ErrorWidget.builder` in `main.dart`.
///
/// Because Flutter substitutes the `ErrorWidget` IN PLACE of any widget whose
/// `build()` throws, a screen-level build error renders this card inside the
/// route's slot — the route is contained and the app never shows a raw error
/// box or a stark-white screen. That makes the global override the de-facto
/// route-level boundary for BUILD-phase errors.
///
/// LIMIT (by design, documented honestly): a render/layout-phase assertion such
/// as "BoxConstraints forces an infinite height" is thrown deep inside
/// `RenderObject.layout()` and is NOT routed through `ErrorWidget.builder` — no
/// Dart try/catch or boundary widget can intercept it. That class is prevented
/// at the source by the self-bounding layout contract (e.g. `MetricGrid`'s
/// `IntrinsicHeight`) and gated by
/// `test/screens/workout/workout_result_unbounded_layout_test.dart`.
class BrandedErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const BrandedErrorWidget({super.key, required this.details});

  static const _bg = Color(0xFF0E0E11);
  static const _amber = Color(0xFFF59E0B); // accent-allowlist: error state color, semantic
  static const _muted = Color(0xFF9CA3AF);

  @override
  Widget build(BuildContext context) {
    // No BuildContext theme is guaranteed here (errors can surface very early),
    // so colours are raw. LTR is forced so the card lays out even when no
    // Directionality ancestor survived the failure.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, c) {
          // In a tiny slot (a small inline widget failed) render a minimal mark
          // so the boundary itself never overflows. Unbounded (infinite) extents
          // are treated as "roomy".
          final tight = (c.maxHeight.isFinite && c.maxHeight < 170) ||
              (c.maxWidth.isFinite && c.maxWidth < 220);
          if (tight) {
            return Container(
              color: _bg,
              alignment: Alignment.center,
              padding: const EdgeInsets.all(8),
              child: const Icon(Icons.error_outline_rounded,
                  color: _amber, size: 20),
            );
          }
          // Scrollable, and deliberately so: this Column is a fixed stack of
          // text in a slot whose height it does not control, so at a large
          // accessibility text scale it overflowed its own card (46px at 1.3x,
          // caught by test/ui_gates/no_overflow_gate_test.dart). An error
          // boundary that itself overflows is the worst possible failure — it
          // is what users see precisely when something has already gone wrong.
          // Scrolling means it cannot overflow at ANY text scale or slot size,
          // rather than fitting at the scales someone happened to check.
          return Container(
            color: _bg,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Color(0x1AF59E0B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline_rounded,
                      color: _amber, size: 30),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Something went wrong here',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This part of the screen failed to load. Go back and reopen '
                  'it — your data is safe.',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: _muted, fontSize: 13, height: 1.4),
                ),
                // The copy says "Go back" — so give them something to go back
                // WITH. A screenshot audit of 862 screens found this was the
                // only route type in the app rendering zero controls, while
                // instructing the user to navigate away. Guarded on
                // `canPop()`: this widget also replaces small inline widgets
                // mid-screen and can surface before any Navigator exists, and
                // a dead button would be worse than none.
                if (Navigator.maybeOf(context)?.canPop() ?? false) ...[
                  const SizedBox(height: 20),
                  TextButton.icon(
                    onPressed: () => Navigator.maybeOf(context)?.maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: 18, color: _amber),
                    label: const Text('Go back',
                        style: TextStyle(
                            color: _amber,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      // Meets the 44pt minimum touch target — a "Talk more"
                      // control elsewhere in this app was ~70x15pt and taps
                      // silently missed it.
                      minimumSize: const Size(88, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                    ),
                  ),
                ],
                  if (kDebugMode) ...[
                    const SizedBox(height: 14),
                    Text(
                      details.exceptionAsString(),
                      textAlign: TextAlign.center,
                      maxLines: 6,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Color(0xFFEF4444), // accent-allowlist: error state color, semantic
                          fontSize: 11,
                          fontFamily: 'monospace'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
