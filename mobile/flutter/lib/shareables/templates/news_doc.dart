/// Editable-card preset for the **News** template — newspaper editorial on
/// cream paper: masthead, EXCLUSIVE REPORT kicker, serif headline, body
/// paragraph, a by-the-numbers stat strip, and a signed footer.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc newsDoc(Shareable data, ShareableAspect aspect) {
  const cream = Color(0xFFF1ECDF);
  const ink = Color(0xFF111111);
  const redInk = Color(0xFF8B0000);
  return cardDoc(
    aspect: aspect,
    presetId: 'news',
    accent: data.accentColor,
    background: solidBg(cream),
    elements: [
      textEl(
        pos: const Offset(0.5, 0.07),
        size: const Size(0.86, 0.05),
        literal: 'THE ZEALOVA TIMES',
        font: 8,
        fontSize: 34,
        color: ink,
        align: TextAlign.center,
        letterSpacing: 1.4,
      ),
      textEl(
        pos: const Offset(0.16, 0.07),
        size: const Size(0.24, 0.03),
        binding: const DataBinding(BindingSource.periodLabel),
        font: 9,
        fontSize: 18,
        color: ink,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.105),
        size: const Size(0.86, 0.005),
        color: ink,
        thickness: 4,
      ),
      textEl(
        pos: const Offset(0.18, 0.14),
        size: const Size(0.4, 0.03),
        literal: 'EXCLUSIVE REPORT',
        font: 9,
        fontSize: 22,
        color: redInk,
        letterSpacing: 2.6,
      ),
      textEl(
        pos: const Offset(0.5, 0.24),
        size: const Size(0.86, 0.16),
        binding: const DataBinding(BindingSource.title),
        font: 8,
        fontSize: 90,
        color: ink,
        lineHeight: 1.04,
        letterSpacing: -0.5,
        maxLines: 3,
        sizeMode: TextSizeMode.shrinkToFit,
      ),
      textEl(
        pos: const Offset(0.5, 0.5),
        size: const Size(0.86, 0.3),
        binding: const DataBinding(BindingSource.caption),
        font: 9,
        fontSize: 28,
        color: ink,
        lineHeight: 1.5,
        maxLines: 10,
      ),
      dividerEl(
        pos: const Offset(0.5, 0.78),
        size: const Size(0.86, 0.003),
        color: ink,
        thickness: 1.5,
      ),
      chartEl(
        pos: const Offset(0.5, 0.83),
        size: const Size(0.86, 0.08),
        style: MacroVizStyle.numbers,
      ),
      textEl(
        pos: const Offset(0.32, 0.92),
        size: const Size(0.5, 0.03),
        binding: const DataBinding(BindingSource.userDisplayName),
        font: 9,
        fontSize: 24,
        color: ink,
        letterSpacing: 1.4,
        allCaps: true,
      ),
      watermarkEl(pos: const Offset(0.7, 0.92), color: ink),
    ],
  );
}
