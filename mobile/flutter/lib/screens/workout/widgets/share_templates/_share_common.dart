import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/weight_utils.dart';
import '../../../../data/models/exercise.dart';
import '../../../../shareables/widgets/fitwiz_watermark.dart';

/// Shared primitives + helpers for the share-template gallery.
///
/// Every template in `share_templates/` composes from this file so we
/// can keep each template lean (~40-80 lines). The primitives intentionally
/// match the dark OLED aesthetic the app ships; individual templates
/// override backgrounds, accents, and typography as needed.

// ───────────────── Data models ─────────────────

/// Slim view-model for an exercise summary, passed from the workout-
/// complete screen into share templates. Decouples the heavier Workout
/// model from the template constructors.
class ShareExerciseSummary {
  final String name;
  final int sets;
  final int reps;
  final double? topWeightKg;

  const ShareExerciseSummary({
    required this.name,
    required this.sets,
    required this.reps,
    this.topWeightKg,
  });
}

/// Per-muscle set count. Derived from a workout's exercises via
/// [extractMuscles]. Keyed by muscle name (chest, back, biceps, etc).
typedef MuscleSetMap = Map<String, int>;

// ───────────────── Muscle extraction ─────────────────

/// Canonical muscle group keys we recognize. Matches the 15 webp assets
/// under `assets/images/muscles/` (chest, back, shoulders, arms, legs,
/// core, glutes, biceps, triceps, quadriceps, hamstrings, calves,
/// lower_back, hips, forearms).
const List<String> _knownMuscles = [
  'chest', 'back', 'shoulders', 'biceps', 'triceps', 'forearms',
  'core', 'glutes', 'quadriceps', 'hamstrings', 'calves',
  'lower_back', 'hips', 'legs', 'arms',
];

/// Lowercase, snake-case a free-form muscle string.
String _normalizeMuscleName(String raw) {
  final s = raw.toLowerCase().trim();
  // Common aliases
  if (s.contains('pectoral')) return 'chest';
  if (s.contains('lat')) return 'back';
  if (s.contains('trap')) return 'back';
  if (s.contains('rhomboid')) return 'back';
  if (s.contains('delt')) return 'shoulders';
  if (s.contains('bicep')) return 'biceps';
  if (s.contains('tricep')) return 'triceps';
  if (s.contains('forearm')) return 'forearms';
  if (s.contains('ab') || s.contains('oblique')) return 'core';
  if (s.contains('glute')) return 'glutes';
  if (s.contains('quad')) return 'quadriceps';
  if (s.contains('hamstring')) return 'hamstrings';
  if (s.contains('calf') || s.contains('calves') || s.contains('gastroc')) return 'calves';
  if (s.contains('lower back') || s.contains('lower_back') || s.contains('erector')) return 'lower_back';
  if (s.contains('hip')) return 'hips';
  return s.replaceAll(' ', '_');
}

/// Count total working sets per muscle group across a list of exercises.
/// Used by Anatomy Hero + Newspaper + Trading Card.
///
/// An exercise targeting multiple muscles contributes its set count to
/// each. Exercises with a missing or unrecognized muscle name are
/// skipped silently (no "unknown" bucket — would pollute the anatomy).
MuscleSetMap extractMuscles(List<WorkoutExercise> exercises) {
  final counts = <String, int>{};
  for (final ex in exercises) {
    // `sets` is nullable on WorkoutExercise — treat missing/zero as 1
    // working set so the muscle still shows up as trained rather than
    // silently dropped from the anatomy overlay.
    final sets = (ex.sets ?? 0) > 0 ? ex.sets! : 1;
    final primary = ex.primaryMuscle ?? ex.muscleGroup;
    if (primary != null && primary.isNotEmpty) {
      final key = _normalizeMuscleName(primary);
      if (_knownMuscles.contains(key)) {
        counts[key] = (counts[key] ?? 0) + sets;
      }
    }
  }
  return counts;
}

// ───────────────── Comparison copy generator ─────────────────

/// Returns an italic-ready punchline for a volume value, matching
/// Hevy's "cool comparisons" pattern. Apply to the user's display-unit
/// value so the copy matches what they're reading.
String comparisonCopyForVolume(double displayVolume, {required bool useKg}) {
  // Thresholds are in the unit being displayed.
  if (useKg) {
    if (displayVolume >= 18000) return 'more than a house';
    if (displayVolume >= 9000) return 'a truck, lifted';
    if (displayVolume >= 4500) return '2 grand pianos';
    if (displayVolume >= 2250) return 'a grizzly bear';
    if (displayVolume >= 900) return 'an adult horse';
    if (displayVolume >= 450) return 'a fridge';
    if (displayVolume >= 225) return 'an adult lion';
    if (displayVolume >= 90) return 'a large dog';
    return 'every rep counts';
  } else {
    if (displayVolume >= 40000) return 'more than a house';
    if (displayVolume >= 20000) return 'a truck, lifted';
    if (displayVolume >= 10000) return '2 grand pianos';
    if (displayVolume >= 5000) return 'a grizzly bear';
    if (displayVolume >= 2000) return 'an adult horse';
    if (displayVolume >= 1000) return 'a fridge';
    if (displayVolume >= 500) return 'an adult lion';
    if (displayVolume >= 200) return 'a large dog';
    return 'every rep counts';
  }
}

// ───────────────── Rarity bucketer (Trading Card) ─────────────────

/// Volume → rarity tier. Used by the Trading Card template for its
/// border + glow styling.
enum ShareRarity { bronze, silver, gold, platinum, diamond }

ShareRarity rarityForVolume(double displayVolume, {required bool useKg}) {
  if (useKg) {
    if (displayVolume >= 9000) return ShareRarity.diamond;
    if (displayVolume >= 4500) return ShareRarity.platinum;
    if (displayVolume >= 2250) return ShareRarity.gold;
    if (displayVolume >= 900) return ShareRarity.silver;
    return ShareRarity.bronze;
  } else {
    if (displayVolume >= 20000) return ShareRarity.diamond;
    if (displayVolume >= 10000) return ShareRarity.platinum;
    if (displayVolume >= 5000) return ShareRarity.gold;
    if (displayVolume >= 2000) return ShareRarity.silver;
    return ShareRarity.bronze;
  }
}

Color rarityColor(ShareRarity r) {
  switch (r) {
    case ShareRarity.diamond: return const Color(0xFF7FF9FF);
    case ShareRarity.platinum: return const Color(0xFFE5E4E2);
    case ShareRarity.gold: return const Color(0xFFFFD700);
    case ShareRarity.silver: return const Color(0xFFC0C0C0);
    case ShareRarity.bronze: return const Color(0xFFCD7F32);
  }
}

String rarityLabel(ShareRarity r) => r.name.toUpperCase();

// ───────────────── Formatting ─────────────────

/// Pretty-format a duration like "17:32" or "1:17:32".
String formatShareDuration(int seconds) {
  if (seconds < 0) seconds = 0;
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Long-form "17m 32s" / "1h 17m" — use for mixed-unit stat strips.
String formatShareDurationLong(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final m = seconds ~/ 60;
  final s = seconds % 60;
  if (m < 60) return s == 0 ? '${m}m' : '${m}m ${s}s';
  final h = m ~/ 60;
  final mm = m % 60;
  return mm == 0 ? '${h}h' : '${h}h ${mm}m';
}

/// Format a kg value for display in the user's preferred unit, with
/// comma separators for thousands. Unit is attached inline (e.g.
/// "6,670 lb"). Uses the same conversion factor as [WeightUtils].
String formatShareWeight(double? weightKg, {required bool useKg}) {
  if (weightKg == null) return '--';
  final v = useKg ? weightKg : WeightUtils.kgToLbs(weightKg);
  final rounded = v.round();
  final formatted = rounded.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
  return '$formatted ${useKg ? 'kg' : 'lb'}';
}

/// Short "6.7k lb" version for space-constrained stat tiles.
String formatShareWeightCompact(double? weightKg, {required bool useKg}) {
  if (weightKg == null) return '--';
  final v = useKg ? weightKg : WeightUtils.kgToLbs(weightKg);
  if (v >= 10000) return '${(v / 1000).toStringAsFixed(1)}k ${useKg ? 'kg' : 'lb'}';
  return '${v.round()} ${useKg ? 'kg' : 'lb'}';
}

// ───────────────── UI primitives ─────────────────

/// Giant number used as the hero element on posters (Volume Hero, PR
/// Poster). Composes into a FittedBox so it auto-scales when the value
/// is longer than expected.
class ShareHeroNumber extends StatelessWidget {
  final String value;
  final String? unit;
  final double size;
  final Color color;
  final FontWeight weight;
  final double letterSpacing;

  const ShareHeroNumber({
    super.key,
    required this.value,
    this.unit,
    this.size = 140,
    this.color = Colors.white,
    this.weight = FontWeight.w900,
    this.letterSpacing = -2.5,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: value,
              style: TextStyle(
                fontSize: size,
                fontWeight: weight,
                color: color,
                height: 1,
                letterSpacing: letterSpacing,
              ),
            ),
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                  letterSpacing: 2,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// All-caps tracked-out label — ubiquitous across templates for titles,
/// category chips, and footer strips.
class ShareTrackedCaps extends StatelessWidget {
  final String text;
  final double size;
  final Color color;
  final double letterSpacing;
  final FontWeight weight;

  const ShareTrackedCaps(
    this.text, {
    super.key,
    this.size = 11,
    this.color = Colors.white,
    this.letterSpacing = 3,
    this.weight = FontWeight.w700,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
      ),
    );
  }
}

/// Small labeled stat (icon + value + label). Stacks vertically.
class ShareStatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final double size;

  const ShareStatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.color = Colors.white,
    this.size = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16 * size),
        SizedBox(height: 4 * size),
        Text(
          value,
          style: TextStyle(
            fontSize: 16 * size,
            fontWeight: FontWeight.w800,
            color: color,
            height: 1,
          ),
        ),
        SizedBox(height: 2 * size),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9 * size,
            fontWeight: FontWeight.w600,
            color: color.withValues(alpha: 0.6),
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }
}

/// Horizontal footer strip of dot-separated stat parts. Used by most
/// templates as the bottom sig line.
class ShareFooterStrip extends StatelessWidget {
  final List<String> parts;
  final Color color;
  final double fontSize;

  const ShareFooterStrip({
    super.key,
    required this.parts,
    this.color = Colors.white70,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      parts.join('  ·  ').toUpperCase(),
      style: TextStyle(
        fontSize: fontSize,
        color: color,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
}

/// Legacy attribution badge — delegates to the unified [FitWizWatermark]
/// so every existing template now renders the real app icon + capitalized
/// "FitWiz" wordmark with no per-site changes.
class ShareWatermarkBadge extends StatelessWidget {
  final bool enabled;
  final Color color;

  const ShareWatermarkBadge({
    super.key,
    this.enabled = true,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) return const SizedBox.shrink();
    return FitWizWatermark(
      textColor: color,
      iconSize: 18,
      fontSize: 12,
    );
  }
}

/// Lock overlay for templates that require data the user doesn't have
/// yet (PR Poster needs a PR, Polaroid needs a photo). Shown inside the
/// gallery tile; the template itself still renders behind it.
class ShareLockOverlay extends StatelessWidget {
  final String message;

  const ShareLockOverlay({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Container(
          color: Colors.black.withValues(alpha: 0.72),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded,
                color: Colors.white.withValues(alpha: 0.9),
                size: 28,
              ),
              const SizedBox(height: 8),
              Text(
                message.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
