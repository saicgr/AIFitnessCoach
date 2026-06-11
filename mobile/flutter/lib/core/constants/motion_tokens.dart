/// Motion tokens — the app's three sanctioned animation timings.
///
/// Approved in the 2026-06 UI review (docs/planning/redesign-2026-06/
/// ui-review-mockup.html, Change 4). Chrome animation timing must come from
/// these tokens; data-driven tweens (count-up numbers, progress arcs) keep
/// their own longer durations because they communicate magnitude, not state.
///
///  * [kMotionFast]       — state ticks, toggles, press feedback.
///  * [kMotionStandard]   — crossfades, container tints, tab switches.
///                          Replaces the bespoke 220/260/300ms sprawl.
///  * [kMotionExpressive] — celebrations, nav spin-pop, word bounce.
///
/// Always gate expressive motion on `MediaQuery.disableAnimations`.
library;

import 'package:flutter/animation.dart';

const Duration kMotionFast = Duration(milliseconds: 150);
const Duration kMotionStandard = Duration(milliseconds: 250);
const Duration kMotionExpressive = Duration(milliseconds: 450);

/// Default ease for fast + standard motion.
const Curve kMotionCurve = Curves.easeOutCubic;

/// Ease-out used by fast feedback (press scale, opacity ticks).
const Curve kMotionCurveFast = Curves.easeOut;
