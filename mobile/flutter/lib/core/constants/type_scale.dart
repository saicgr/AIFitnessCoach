/// Type-scale tokens — the app's 6-step font ramp.
///
/// Approved in the 2026-06 UI review (docs/planning/redesign-2026-06/
/// ui-review-mockup.html, Change 4). New/retrofitted chrome must pick a step
/// instead of inventing a size; nothing in the app should render below
/// [kTypeCaption] (11px). Weights are defaults — callers may override weight
/// without leaving the ramp.
///
/// | step     | size | default weight | use                                |
/// |----------|------|----------------|------------------------------------|
/// | display  | 28   | w800           | hero metrics (kcal left, score)    |
/// | headline | 20   | w800           | card hero values, big counts       |
/// | title    | 16   | w700           | card/section titles                |
/// | body     | 14   | w500           | body copy, list rows               |
/// | label    | 12   | w600           | buttons, chips, meta lines         |
/// | caption  | 11   | w600           | nav labels, timestamps, overlines  |
library;

import 'package:flutter/painting.dart';

const double kTypeDisplaySize = 28;
const double kTypeHeadlineSize = 20;
const double kTypeTitleSize = 16;
const double kTypeBodySize = 14;
const double kTypeLabelSize = 12;
const double kTypeCaptionSize = 11;

const TextStyle kTypeDisplay =
    TextStyle(fontSize: kTypeDisplaySize, fontWeight: FontWeight.w800);
const TextStyle kTypeHeadline =
    TextStyle(fontSize: kTypeHeadlineSize, fontWeight: FontWeight.w800);
const TextStyle kTypeTitle =
    TextStyle(fontSize: kTypeTitleSize, fontWeight: FontWeight.w700);
const TextStyle kTypeBody =
    TextStyle(fontSize: kTypeBodySize, fontWeight: FontWeight.w500);
const TextStyle kTypeLabel =
    TextStyle(fontSize: kTypeLabelSize, fontWeight: FontWeight.w600);
const TextStyle kTypeCaption =
    TextStyle(fontSize: kTypeCaptionSize, fontWeight: FontWeight.w600);
