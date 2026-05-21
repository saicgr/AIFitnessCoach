/// Plain-English training-concept explainers.
///
/// Pure data — no Flutter imports — so it can be unit-tested and reused by
/// any surface that needs to demystify gym jargon. The active-workout set
/// rows tap into [TrainingExplainers.rir] / [.failure] for the RIR pill
/// bottom sheet (Phase A.2).
///
/// Copy intentionally avoids jargon-on-jargon: each paragraph reads as if a
/// coach were explaining the term to someone hearing it for the first time.
library;

/// One explainer entry: a short title plus a single plain-English paragraph.
class TrainingExplainer {
  /// Short heading shown at the top of the bottom sheet.
  final String title;

  /// One paragraph (no line breaks) describing the concept in plain English.
  final String body;

  /// Optional one-line takeaway shown as an emphasised footer.
  final String? takeaway;

  const TrainingExplainer({
    required this.title,
    required this.body,
    this.takeaway,
  });
}

/// Static catalogue of training-concept explainers.
class TrainingExplainers {
  TrainingExplainers._();

  /// "Reps in reserve" — the general concept behind the RIR pills.
  static const TrainingExplainer rir = TrainingExplainer(
    title: 'Reps in reserve (RIR)',
    body:
        'RIR is how many more reps you could have done before your form broke '
        'down or the bar stopped moving. A target of "2 RIR" means you should '
        'stop the set with about two clean reps still in the tank. Leaving a '
        'rep or two unused keeps your technique sharp and lets you recover '
        'enough to hit every set hard, instead of emptying yourself on set one. '
        'Most working sets are written this way on purpose.',
    takeaway: 'Stop when you have roughly that many good reps left, not at total exhaustion.',
  );

  /// "Push to failure" — what an AMRAP / 0-RIR / failure set is asking for.
  static const TrainingExplainer failure = TrainingExplainer(
    title: 'Push to failure',
    body:
        'This set asks you to keep going until you genuinely cannot complete '
        'another rep with good form. It is the same idea as AMRAP, which means '
        '"as many reps as possible". Going to failure is a deliberate, '
        'occasional tool: it tells the app exactly where your limit is today, '
        'which sharpens future weight suggestions. Use clean reps, stop the '
        'moment your form slips, and never chase failure on every set or every '
        'session.',
    takeaway: 'Go all the way, but the rep before your form breaks is the last good rep.',
  );

  /// "1 RIR (near max)" — the in-between case.
  static const TrainingExplainer nearMax = TrainingExplainer(
    title: '1 RIR — near max',
    body:
        'This set should end with just one clean rep left in the tank. It is '
        'close to failure without crossing into it, so you still get a strong '
        'training stimulus while keeping a small safety margin. Push hard, but '
        'rack the weight while you are confident you could have squeezed out '
        'one more.',
    takeaway: 'Hard effort, but leave exactly one good rep unused.',
  );

  /// Resolve the right explainer for a set, given its RIR/AMRAP context.
  ///
  /// Mirrors the label map in `set_row_visuals.dart`:
  ///   isAmrap OR set_type=='failure' OR targetRir==0 → [failure]
  ///   targetRir == 1                                 → [nearMax]
  ///   targetRir >= 2 (or anything else)              → [rir]
  static TrainingExplainer forSet({
    required bool isAmrap,
    required bool isFailureType,
    int? targetRir,
  }) {
    if (isAmrap || isFailureType || targetRir == 0) return failure;
    if (targetRir == 1) return nearMax;
    return rir;
  }
}
