/// Single source of truth for the peer-reviewed / authoritative citations
/// surfaced across onboarding and the paywall.
///
/// WHY THIS EXISTS (honesty policy — see CLAUDE.md + memory):
/// Zealova ships NO fabricated stats. Every authority claim shown to a user
/// must be backed by a REAL, verifiable source the user can tap and read.
/// Centralising the citations here guarantees the science screen, the trust
/// bullets, the weight-projection footnote and the paywall "N× faster"
/// module all cite the SAME wording and the SAME (working) URL — so there is
/// exactly one place to keep them correct and current.
///
/// These references back the *methodology* ("our plans use progressive
/// overload", "consistent tracking helps"), never an outcome promise about
/// Zealova specifically. That distinction is what keeps them defensible
/// under FTC substantiation rules and Apple 3.1.2.
///
/// Pure Dart (no Flutter import) so it can be unit-tested and consumed by
/// the deterministic goal-speed calculator as well as the widgets.
library;

/// One verifiable reference: a plain-language claim, the human-readable
/// source label, and a tappable URL to the primary source.
class ScienceCitation {
  /// Plain-language, methodology-level claim. NOT an outcome promise.
  final String claim;

  /// Short human-readable source label shown inline (e.g. the journal +
  /// year). Keep it tight — it renders as tappable link text.
  final String source;

  /// Canonical URL to the primary source (PubMed / NHS / position stand).
  final String url;

  /// Stable key for analytics + lookups. Never shown to the user.
  final String id;

  const ScienceCitation({
    required this.id,
    required this.claim,
    required this.source,
    required this.url,
  });
}

/// The vetted registry. Add only references you have actually verified.
class ScienceCitations {
  ScienceCitations._();

  /// Self-monitoring (consistent tracking) ~doubles the odds of hitting a
  /// clinically meaningful (≥5%) weight goal. This is the cited BASIS for the
  /// derived "N× faster with your plan" multiplier — the multiplier is the
  /// user's own plan-vs-solo projection; this is why a consistent plan beats
  /// going solo at all.
  static const ScienceCitation selfMonitoring = ScienceCitation(
    id: 'self_monitoring_2021',
    claim:
        'People who track consistently are about twice as likely to reach a '
        'meaningful weight goal.',
    source: 'Obesity Reviews, 2021',
    url: 'https://pubmed.ncbi.nlm.nih.gov/34192411/',
  );

  /// Progressive overload — the backbone of how every Zealova plan adds load
  /// week to week. ACSM position stand.
  static const ScienceCitation progressiveOverload = ScienceCitation(
    id: 'acsm_progression_2009',
    claim:
        'Gradually increasing training load (progressive overload) is the '
        'evidence-based driver of strength and muscle gains.',
    source: 'ACSM Position Stand, Med Sci Sports Exerc 2009',
    url: 'https://pubmed.ncbi.nlm.nih.gov/19204579/',
  );

  /// Safe, sustainable rate of weight change. This is the source cited next
  /// to the projection's safe-rate cap.
  static const ScienceCitation safeRate = ScienceCitation(
    id: 'nhs_safe_rate',
    claim:
        'A safe, sustainable rate of weight loss is about 0.5–1 kg (1–2 lb) '
        'per week.',
    source: 'NHS Weight Loss Guidance',
    url:
        'https://www.nhs.uk/live-well/healthy-weight/managing-your-weight/start-the-nhs-weight-loss-plan/',
  );

  /// Protein intake & timing for muscle protein synthesis — backs the
  /// nutrition/macro side of the plan. ISSN position stand.
  static const ScienceCitation protein = ScienceCitation(
    id: 'issn_protein_2017',
    claim:
        'Adequate, well-timed protein intake supports muscle growth and '
        'recovery.',
    source: 'ISSN Position Stand, J Int Soc Sports Nutr 2017',
    url: 'https://pubmed.ncbi.nlm.nih.gov/28642676/',
  );

  /// Ordered list for the science-grounding screen.
  static const List<ScienceCitation> all = [
    progressiveOverload,
    protein,
    selfMonitoring,
    safeRate,
  ];
}
