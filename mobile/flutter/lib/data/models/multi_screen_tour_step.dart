import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

/// Represents a single step in the multi-screen interactive tour
class MultiScreenTourStep {
  /// Unique identifier for this step
  final String id;

  /// The route this step belongs to (e.g., '/home', '/workouts')
  final String screenRoute;

  /// Identifier to match with GlobalKey registration
  final String targetKeyId;

  /// Title shown in the tooltip
  final String title;

  /// Description shown in the tooltip
  final String description;

  /// Icon displayed in the tooltip
  final IconData icon;

  /// Color theme for this step
  final Color color;

  /// Route to navigate to when user taps (null for final step)
  final String? navigateToOnTap;

  /// Alignment of tooltip content relative to target
  final ContentAlign contentAlign;

  /// Shape of the highlight around the target
  final ShapeLightFocus shape;

  const MultiScreenTourStep({
    required this.id,
    required this.screenRoute,
    required this.targetKeyId,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.navigateToOnTap,
    this.contentAlign = ContentAlign.bottom,
    this.shape = ShapeLightFocus.RRect,
  });

  /// Whether this is the final step in the tour
  bool get isFinalStep => navigateToOnTap == null;
}
