import 'package:flutter/material.dart';
import '../../../data/models/progress_photos.dart';

/// Immutable view-model passed into every viral template so each one is
/// pure-render and cheap to capture via RepaintBoundary.
class ProgressShareData {
  final ProgressPhoto before;
  final ProgressPhoto after;
  final DateTime beforeDate;
  final DateTime afterDate;
  final double? beforeWeightKg;
  final double? afterWeightKg;
  final String? username;
  final int currentStreak;
  final int totalWorkouts;
  final int? waistCmDelta;
  final bool useKg;

  const ProgressShareData({
    required this.before,
    required this.after,
    required this.beforeDate,
    required this.afterDate,
    this.beforeWeightKg,
    this.afterWeightKg,
    this.username,
    this.currentStreak = 0,
    this.totalWorkouts = 0,
    this.waistCmDelta,
    this.useKg = true,
  });

  int get daysBetween => afterDate.difference(beforeDate).inDays.abs();

  double? get weightDeltaKg =>
      (beforeWeightKg != null && afterWeightKg != null)
          ? afterWeightKg! - beforeWeightKg!
          : null;

  String get durationText {
    final d = daysBetween;
    if (d == 0) return 'Same day';
    if (d < 14) return '$d days';
    if (d < 60) {
      final w = (d / 7).round();
      return '$w weeks';
    }
    if (d < 365) {
      final m = (d / 30).round();
      return '$m months';
    }
    final y = (d / 365).floor();
    final mo = ((d % 365) / 30).round();
    return mo == 0 ? '${y}y' : '${y}y ${mo}m';
  }

  String get weightDeltaText {
    final d = weightDeltaKg;
    if (d == null) return '';
    final v = useKg ? d : d * 2.20462;
    final unit = useKg ? 'kg' : 'lb';
    final sign = v >= 0 ? '+' : '−';
    return '$sign${v.abs().toStringAsFixed(1)} $unit';
  }

  /// Positive delta is weight lost (we assume users share transformations
  /// where lower is the goal; copy flips sign to feel celebratory).
  String get weightLostText {
    final d = weightDeltaKg;
    if (d == null) return '';
    final lost = -d;
    final v = useKg ? lost : lost * 2.20462;
    final unit = useKg ? 'kg' : 'lb';
    if (v <= 0) return '${v.abs().toStringAsFixed(1)} $unit gained';
    return '${v.toStringAsFixed(1)} $unit down';
  }
}

/// Shared enum + registry so the gallery can iterate templates without
/// hard-coding the grid.
enum ProgressTemplateKind {
  igStoryCta,
  wrapped,
  receipt,
  tradingCard,
  newspaper,
  polaroidDiary,
  magazineCover,
  retro80s,
  neonTabloid,
  swissEditorial,
  achievementUnlocked,
  calendarGrid,
  progressBar,
  tapeMeasure,
  transformationTuesday,
  timelineRuler,
}

extension ProgressTemplateKindExt on ProgressTemplateKind {
  String get label {
    switch (this) {
      case ProgressTemplateKind.igStoryCta: return 'IG Story';
      case ProgressTemplateKind.wrapped: return 'Wrapped';
      case ProgressTemplateKind.receipt: return 'Receipt';
      case ProgressTemplateKind.tradingCard: return 'Trading Card';
      case ProgressTemplateKind.newspaper: return 'Newspaper';
      case ProgressTemplateKind.polaroidDiary: return 'Polaroid';
      case ProgressTemplateKind.magazineCover: return 'Magazine';
      case ProgressTemplateKind.retro80s: return 'Retro 80s';
      case ProgressTemplateKind.neonTabloid: return 'Neon';
      case ProgressTemplateKind.swissEditorial: return 'Swiss';
      case ProgressTemplateKind.achievementUnlocked: return 'Achievement';
      case ProgressTemplateKind.calendarGrid: return 'Calendar';
      case ProgressTemplateKind.progressBar: return 'Progress Bar';
      case ProgressTemplateKind.tapeMeasure: return 'Tape';
      case ProgressTemplateKind.transformationTuesday: return 'Transformation';
      case ProgressTemplateKind.timelineRuler: return 'Timeline';
    }
  }
}

/// Instagram Story canvas size used for every template so capture is
/// deterministic across devices (matches ImageCaptureUtils.instagramStoriesSize).
const Size kProgressShareCanvas = Size(360, 640);
