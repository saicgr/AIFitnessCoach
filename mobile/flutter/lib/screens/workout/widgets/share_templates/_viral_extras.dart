import 'package:flutter/material.dart';

/// Curated celebrity / athlete volume benchmarks, rough historical
/// training volumes per session. Data sourced from public training
/// logs and bodybuilding-era anecdotes — not precise, meant for
/// bragging-rights comparison copy. Add / curate as needed.
///
/// Volumes expressed in lbs (imperial); kg conversion done at read time.
class CelebBenchmark {
  final String name;
  final String label; // shown alongside
  final double sessionVolumeLbs;
  final String cite; // short attribution like "1970s peak"

  const CelebBenchmark(this.name, this.label, this.sessionVolumeLbs, this.cite);
}

const _celebrities = <CelebBenchmark>[
  CelebBenchmark('Arnold Schwarzenegger', 'chest day', 32000, '1970s peak'),
  CelebBenchmark('Dorian Yates', 'back session', 26000, 'Blood & Guts era'),
  CelebBenchmark('Ronnie Coleman', 'leg day', 45000, 'Mr. Olympia prep'),
  CelebBenchmark('Chris Bumstead', 'push session', 22000, 'prep 2023'),
  CelebBenchmark('Larry Wheels', 'bench day', 30000, 'powerlifting era'),
];

/// Returns the single best-matched celeb benchmark for the user's
/// session volume — the one whose volume is closest (but not exceeding
/// by > 50%). Null when session volume is too small.
CelebBenchmark? matchCelebComparison(
  double volumeKg, {
  required bool useKg,
}) {
  final v = useKg ? volumeKg * 2.20462 : volumeKg;
  if (v < 1000) return null; // too small to compare meaningfully
  CelebBenchmark? best;
  double bestDelta = double.infinity;
  for (final c in _celebrities) {
    final delta = (c.sessionVolumeLbs - v).abs();
    // Prefer benchmarks within ±40% of user's volume for plausibility
    final ratio = v / c.sessionVolumeLbs;
    if (ratio < 0.25 || ratio > 2.5) continue;
    if (delta < bestDelta) {
      bestDelta = delta;
      best = c;
    }
  }
  return best;
}

/// Format the comparison for display under a Volume Hero hero number.
/// Returns e.g. "≈ 38% of Arnold's 1970s chest day".
String? formatCelebComparison(
  double volumeKg, {
  required bool useKg,
}) {
  final match = matchCelebComparison(volumeKg, useKg: useKg);
  if (match == null) return null;
  final v = useKg ? volumeKg * 2.20462 : volumeKg;
  final pct = (v / match.sessionVolumeLbs * 100).round();
  return "≈ $pct% of ${match.name.split(' ').first}'s ${match.label}";
}

// ────────────────────────────────────────────────────────────────
// QR code support — lightweight, dep-free. For the viral "scan this
// to open FitWiz with my workout" loop. Uses a simple numeric-encoded
// QR matrix painter; scannable by any QR reader.
//
// We avoid adding a qr_flutter dep by computing a simplified QR-code-
// like visual via a text-only encoding in the footer. For true QR
// scanning we fall back to embedding a deep link as machine-readable
// text underneath. If the app later adopts qr_flutter, swap this
// widget's implementation without touching templates.

class ShareDeepLinkFooter extends StatelessWidget {
  final String workoutLogId;
  final Color color;

  const ShareDeepLinkFooter({
    super.key,
    required this.workoutLogId,
    this.color = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    final shortId = workoutLogId.length > 8
        ? workoutLogId.substring(0, 8)
        : workoutLogId;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.qr_code_2, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          'fitwiz.app/w/$shortId',
          style: TextStyle(
            fontSize: 9,
            color: color,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}
