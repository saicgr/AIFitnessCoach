/// Editable-card preset for the **Snack Plate** food template — several
/// small circle-masked food crops scattered grazing-plate style on a neutral
/// background, each with a micro-label chip and a cheeky caption on top.
library;

import 'package:flutter/material.dart';

import '../doc/card_doc.dart';
import '../shareable_data.dart';
import 'doc_kit.dart';

CardDoc snackPlateDoc(Shareable data, ShareableAspect aspect) {
  final accent = data.accentColor;
  // Scattered grazing-plate positions: (x, y, diameter).
  const spots = <List<double>>[
    [0.32, 0.36, 0.34],
    [0.66, 0.3, 0.26],
    [0.74, 0.55, 0.3],
    [0.3, 0.62, 0.28],
    [0.52, 0.46, 0.22],
    [0.46, 0.74, 0.24],
    [0.7, 0.78, 0.2],
  ];
  return cardDoc(
    aspect: aspect,
    presetId: 'snackPlate',
    accent: accent,
    background: gradientBg([
      const Color(0xFFEFE9DC),
      const Color(0xFFDDD3BF),
    ]),
    elements: [
      // Cheeky caption across the top.
      textEl(
        pos: const Offset(0.5, 0.1),
        size: const Size(0.88, 0.08),
        literal: 'a little of everything',
        font: 6,
        fontSize: 44,
        color: const Color(0xFF2A2419),
        align: TextAlign.center,
        maxLines: 1,
      ),
      textEl(
        pos: const Offset(0.5, 0.16),
        size: const Size(0.7, 0.04),
        binding: const DataBinding(BindingSource.mealLabel),
        font: 5,
        fontSize: 18,
        color: accent,
        align: TextAlign.center,
        letterSpacing: 4,
        allCaps: true,
      ),
      // 7 circle-masked food crops with micro-label chips.
      for (var i = 0; i < spots.length; i++) ...[
        photoEl(
          pos: Offset(spots[i][0], spots[i][1]),
          size: Size(spots[i][2], spots[i][2]),
          binding: DataBinding(BindingSource.foodImageUrl, index: i),
          mask: PhotoMask.circle,
          frameColor: Colors.white,
          frameWidth: 4,
        ),
        chipsEl(
          pos: Offset(spots[i][0], spots[i][1] + spots[i][2] / 2 + 0.018),
          size: Size(spots[i][2] + 0.06, 0.035),
          binding: DataBinding(BindingSource.foodItemName, index: i),
          layout: ChipLayout.row,
          maxItems: 1,
          chipColor: const Color(0xFF2A2419),
          textColor: const Color(0xFFEFE9DC),
          fontSize: 16,
        ),
      ],
      // Calorie footer.
      textEl(
        pos: const Offset(0.5, 0.92),
        size: const Size(0.8, 0.05),
        binding: const DataBinding(BindingSource.calories),
        font: 7,
        fontSize: 28,
        color: const Color(0xFF2A2419),
        align: TextAlign.center,
      ),
      watermarkEl(pos: const Offset(0.3, 0.97), color: const Color(0xFF2A2419)),
    ],
  );
}
