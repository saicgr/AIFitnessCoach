import 'package:flutter/material.dart';

import '../../core/constants/chrome_constants.dart';
import 'chat_screen.dart';

/// DEAD as of the 2026-08 nav redesign — nothing constructs this any more.
///
/// Coach gave up the centre bottom-nav slot to Health, so there is no Coach
/// branch for this to root. Coach access is the full-screen `/chat` route plus
/// the global ✦ pill (`widgets/coach_floating_button.dart`), and `/coach` is
/// now a redirect to `/chat`.
///
/// Kept only so the `ChatScreen(embedded: true)` + nav-clearance recipe below
/// is not lost; DO NOT re-mount it as a tab root without re-adding a branch —
/// a second `/coach`-shaped embedded chat would drift from the real `/chat`
/// push path, which is exactly the split this redesign removed.
///
/// ── original doc ──────────────────────────────────────────────────────────
/// Branch root for the Coach bottom-nav tab (2026-06 redesign — Change 1:
/// the AI coach is the product's differentiator, so it gets the center tab;
/// the scroll-collapsing Home FAB is retired).
///
/// Hosts the existing [ChatScreen] in embedded mode. The floating main nav
/// overlays the bottom of every tab, so we widen `MediaQuery.padding.bottom`
/// by the nav clearance — ChatScreen's own SafeArea then naturally lifts the
/// composer above the nav pill. When the keyboard is up the nav hides (see
/// MainShell) and `viewInsets` drives the lift instead, so no extra padding.
///
/// Pushed `/chat` deep links (coach card prefill, ?workout_id, etc.) are
/// untouched — they still open the full-screen overlay chat.
class CoachTabScreen extends StatelessWidget {
  const CoachTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final keyboardOpen = mq.viewInsets.bottom > 0;
    final bottomBump = keyboardOpen ? 0.0 : kMainNavClearance;
    return MediaQuery(
      data: mq.copyWith(
        padding: mq.padding.copyWith(bottom: mq.padding.bottom + bottomBump),
        viewPadding: mq.viewPadding
            .copyWith(bottom: mq.viewPadding.bottom + bottomBump),
      ),
      child: const ChatScreen(embedded: true),
    );
  }
}
