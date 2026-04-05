import 'package:flutter/material.dart';

// =============================================================================
// StatCategory - Rich stat categories for comparison stats bar
// =============================================================================

enum StatCategory {
  duration('Duration', Icons.timer_outlined),
  weight('Weight', Icons.monitor_weight_outlined),
  body('Body', Icons.straighten),
  strength('Strength', Icons.fitness_center);

  final String label;
  final IconData icon;
  const StatCategory(this.label, this.icon);

  static StatCategory? fromString(String value) {
    for (final cat in StatCategory.values) {
      if (cat.name == value) return cat;
    }
    return null;
  }
}

enum DatePosition {
  left('Left', Icons.format_align_left),
  center('Center', Icons.format_align_center),
  right('Right', Icons.format_align_right);

  final String label;
  final IconData icon;
  const DatePosition(this.label, this.icon);
}

enum PhotoShape {
  rectangle('Rectangle', Icons.crop_square),
  squircle('Squircle', Icons.rounded_corner),
  circle('Circle', Icons.circle_outlined);

  final String label;
  final IconData icon;
  const PhotoShape(this.label, this.icon);

  static PhotoShape fromString(String value) {
    for (final s in PhotoShape.values) {
      if (s.name == value) return s;
    }
    return PhotoShape.rectangle;
  }
}
