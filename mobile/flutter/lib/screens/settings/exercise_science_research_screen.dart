import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/constants/app_colors.dart';
import '../../widgets/glass_back_button.dart';

/// Data model for a research paper card.
class _ResearchPaper {
  final IconData icon;
  final Color color;
  final String title;
  final String authors;
  final String journal;
  final String year;
  final String summary;
  final List<String> keyFindings;
  final String howWeUseIt;

  const _ResearchPaper({
    required this.icon,
    required this.color,
    required this.title,
    required this.authors,
    required this.journal,
    required this.year,
    required this.summary,
    required this.keyFindings,
    required this.howWeUseIt,
  });
}

const _papers = <_ResearchPaper>[
  _ResearchPaper(
    icon: Icons.fitness_center,
    color: AppColors.info,
    title: 'Guidelines for Exercise Testing and Prescription',
    authors: 'American College of Sports Medicine (ACSM)',
    journal: 'ACSM Guidelines, 11th Edition',
    year: '2021',
    summary:
        'The gold standard for exercise prescription, providing foundational recommendations for sets, reps, and rest periods across training goals.',
    keyFindings: [
      'Strength: 3-6 reps, 3-5 sets, 2-5 min rest',
      'Hypertrophy: 8-12 reps, 3-4 sets, 60-120s rest',
      'Endurance: 15-20+ reps, 2-3 sets, 30-60s rest',
      'Flexibility: 15-60s holds per stretch',
    ],
    howWeUseIt:
        'Defines rep/set/rest targets for each difficulty level. Easy uses endurance ranges, Medium uses hypertrophy, Hard/Hell uses strength.',
  ),
  _ResearchPaper(
    icon: Icons.trending_up,
    color: AppColors.success,
    title: 'Essentials of Strength Training and Conditioning',
    authors: 'Haff, G. G. & Triplett, N. T.',
    journal: 'NSCA, 4th Edition',
    year: '2016',
    summary:
        'The NSCA textbook on periodization and autoregulation, providing the RPE framework used for training intensity prescription.',
    keyFindings: [
      'RPE 5-6 for recovery / deload sessions',
      'RPE 7-8 for standard hypertrophy blocks',
      'RPE 8-9 for intensive training phases',
      'RPE 9-10 for peaking / maximal effort',
    ],
    howWeUseIt:
        'Each difficulty level maps to an RPE range. Working sets progress RPE 7 to 9 within a workout, following autoregulation principles.',
  ),
  _ResearchPaper(
    icon: Icons.compare_arrows,
    color: AppColors.purple,
    title: 'Effects of Superset Configuration on Kinetic, Kinematic, and Perceived Exertion in the Barbell Bench Press',
    authors: 'Weakley, J. J. S. et al.',
    journal: 'Journal of Strength and Conditioning Research',
    year: '2017',
    summary:
        'Investigated whether antagonist supersets (pairing opposing muscles) compromise force output compared to traditional straight sets.',
    keyFindings: [
      'Force output maintained within 2-3% of straight sets',
      '40-50% reduction in total session time',
      'No significant impact on velocity or power metrics',
    ],
    howWeUseIt:
        'Validates the superset pairing system (chest/back, quads/hamstrings, biceps/triceps) with 15s intra-pair rest.',
  ),
  _ResearchPaper(
    icon: Icons.swap_horiz,
    color: Color(0xFF06B6D4),
    title: 'Agonist-Antagonist Paired Set Resistance Training: A Brief Review',
    authors: 'Paz, G. A. et al.',
    journal: 'Journal of Sports Science & Medicine',
    year: '2017',
    summary:
        'A comprehensive review of paired-set training showing that antagonist pre-activation may enhance agonist force production.',
    keyFindings: [
      'Antagonist pre-activation enhances agonist force via reciprocal inhibition',
      'EMG data shows no detrimental effect on muscle activation',
      'Recommended rest: 60-90s between paired exercises',
    ],
    howWeUseIt:
        'Supports pairing opposing muscles and confirms the 75s between-pair rest interval used in superset workouts.',
  ),
  _ResearchPaper(
    icon: Icons.local_fire_department,
    color: Color(0xFFEF4444),
    title: 'Effects of Moderate-Intensity Endurance and High-Intensity Intermittent Training on Anaerobic Capacity and VO2max',
    authors: 'Tabata, I. et al.',
    journal: 'Medicine and Science in Sports and Exercise',
    year: '1996',
    summary:
        'The landmark study that established the Tabata protocol — 20s maximal effort / 10s rest for 4 minutes — producing remarkable aerobic and anaerobic improvements.',
    keyFindings: [
      '20s max effort / 10s rest x 8 rounds = 4 minutes total',
      'VO2max improved by 14% over 6 weeks',
      'Anaerobic capacity improved by 28% over 6 weeks',
      'Outperformed 60-min steady-state cardio for anaerobic gains',
    ],
    howWeUseIt:
        '5-minute Cardio/HIIT quick workouts use the exact Tabata protocol for maximum efficiency in minimal time.',
  ),
  _ResearchPaper(
    icon: Icons.bolt,
    color: Color(0xFFF59E0B),
    title: 'Physiological Adaptations to Low-Volume, High-Intensity Interval Training in Health and Disease',
    authors: 'Gibala, M. J. et al.',
    journal: 'The Journal of Physiology',
    year: '2012',
    summary:
        'Demonstrated that sprint interval training produces comparable cardiovascular adaptations to moderate-intensity continuous exercise in a fraction of the time.',
    keyFindings: [
      '30s all-out intervals match steady-state cardio adaptations',
      'Reduced-exertion HIIT still provides meaningful benefits',
      'Significant cardiometabolic improvements with brief protocols',
    ],
    howWeUseIt:
        'HIIT quick workouts use 30s work / 20s rest intervals. Hard difficulty increases to 40s work for greater training stimulus.',
  ),
  _ResearchPaper(
    icon: Icons.show_chart,
    color: Color(0xFF10B981),
    title: 'Fundamentals of Resistance Training: Progression and Exercise Prescription',
    authors: 'Kraemer, W. J. & Ratamess, N. A.',
    journal: 'Medicine and Science in Sports and Exercise',
    year: '2004',
    summary:
        'Established progressive overload as the foundational principle of resistance training and the use of 1RM-based load prescription for individualization.',
    keyFindings: [
      'Progressive overload is essential for continued adaptation',
      'Load prescribed as % of 1RM ensures individualization',
      'Compound exercises warrant higher volume than isolation',
      'Warm-up sets at 50% working weight reduce injury risk',
    ],
    howWeUseIt:
        'When 1RM data is available, working weights are calculated as a % of your max. Compounds get more volume than isolation exercises.',
  ),
  _ResearchPaper(
    icon: Icons.psychology,
    color: Color(0xFF8B5CF6),
    title: 'Effects of Exercise on Mood and Cognitive Function',
    authors: 'Goldstein, A. N. & Leung, E.',
    journal: 'Neuroscience & Behavioral Reviews',
    year: '2012',
    summary:
        'Research supporting mood-based training adjustments, showing that compound lifts during stress increase endorphin release, while fatigued states benefit from reduced intensity.',
    keyFindings: [
      'High neural readiness allows heavier loads safely',
      'Fatigue states benefit from reduced load to prevent injury',
      'Compound lifts increase endorphin release under stress',
      'Low-energy states respond best to mobility-focused work',
    ],
    howWeUseIt:
        'The optional mood selector adjusts intensity, volume, and rest. "Tired" softens workouts; "Energized" amplifies them.',
  ),

  // ── Rest Period Optimization ──────────────────────────────────────
  _ResearchPaper(
    icon: Icons.timer,
    color: Color(0xFF0EA5E9),
    title: 'Rest Interval Duration and Muscle Hypertrophy: Bayesian Meta-Analysis',
    authors: 'Singer, A., Wolf, M., Generoso, L. et al.',
    journal: 'Frontiers in Sports and Active Living',
    year: '2024',
    summary:
        'A Bayesian meta-analysis across 9 studies (313 participants) examining inter-set rest intervals and their effect on muscle hypertrophy. Found substantial overlap between short and long rest.',
    keyFindings: [
      'Short rest SMD: 0.48 vs Long rest SMD: 0.56 — massive overlap',
      'Rest >60s shows small hypertrophy benefit over <60s',
      'Beyond 90s, no appreciable additional hypertrophy benefit',
      'For strength, 3-minute rest clearly outperforms 1-minute',
    ],
    howWeUseIt:
        'Evidence-based rest period lookup table: 60s minimum for hypertrophy, 120s+ for strength, goal-dependent scaling with training status.',
  ),

  // ── Superset Meta-Analysis ────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.swap_vert,
    color: Color(0xFFF97316),
    title: 'Superset vs Traditional Resistance Training Prescriptions',
    authors: 'Various (Meta-Analysis)',
    journal: 'Sports Medicine',
    year: '2025',
    summary:
        'Comprehensive meta-analysis finding supersets produce 36% shorter sessions with similar chronic strength and hypertrophy adaptations compared to traditional sets.',
    keyFindings: [
      '36% shorter session duration with similar adaptations',
      'Agonist-antagonist pairs: 0-30s intra-pair rest enhances activation',
      'Inter-pair rest should be goal-dependent (75-150s)',
      'Same-muscle supersets reduce load capacity by 15-20%',
    ],
    howWeUseIt:
        'Superset pairing engine uses agonist-antagonist pairs with 15s intra-pair rest. Inter-pair rest scales by goal (75s hypertrophy, 150s strength).',
  ),

  // ── Exercise Variation ────────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.shuffle,
    color: Color(0xFF22C55E),
    title: 'Exercise Variation for Regional Hypertrophy and Strength',
    authors: 'Fonseca, R. M. et al.',
    journal: 'Journal of Strength and Conditioning Research',
    year: '2014',
    summary:
        'Landmark study showing exercise variation (with constant intensity) produced the greatest strength gains AND achieved hypertrophy in ALL quadriceps heads, while constant-exercise groups missed regions.',
    keyFindings: [
      'Variation hit ALL quadriceps heads vs missed regions with fixed exercises',
      'Greater strength gains with systematic variation',
      'Angle diversity matters more than random swaps (Kassiano 2022)',
      'Random variation = equal hypertrophy + higher motivation (Baz-Valle 2019)',
    ],
    howWeUseIt:
        'Recency-weighted exercise scoring: freshness = e^(-0.3 * sessions_since_use). Exercises used recently get deprioritized for anatomically-informed rotation.',
  ),

  // ── Repetition Continuum ──────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.straighten,
    color: Color(0xFFEC4899),
    title: 'Loading Recommendations: A Re-Examination of the Repetition Continuum',
    authors: 'Schoenfeld, B. J. et al.',
    journal: 'Sports',
    year: '2021',
    summary:
        'Re-examined the classic repetition continuum and found hypertrophy occurs across a wide load spectrum (30-85% 1RM) as long as effort is sufficient. Strength remains more load-specific.',
    keyFindings: [
      'Hypertrophy at 30-85% 1RM if sets are sufficiently hard',
      'Strength is load-specific — heavier loads produce more strength',
      'Supports separating training GOAL from DIFFICULTY',
      'Easy hypertrophy (lower RPE) is valid, not just endurance rep ranges',
    ],
    howWeUseIt:
        'Decoupled goal from difficulty: an "easy hypertrophy" workout uses 8-12 reps at RPE 6-7, NOT endurance rep ranges. Goal sets parameters, difficulty scales effort.',
  ),

  // ── Muscle Recovery ───────────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.healing,
    color: Color(0xFF14B8A6),
    title: 'Muscle Protein Synthesis Time Course After Resistance Exercise',
    authors: 'MacDougall, J. D. et al. / Damas, F. et al.',
    journal: 'Multiple (1995, 2016)',
    year: '1995-2016',
    summary:
        'Foundational research on muscle recovery timelines. MPS peaks at 24h post-exercise and returns to baseline by 48h in trained individuals. Recovery varies by fiber type, not muscle size.',
    keyFindings: [
      'MPS elevated 109% at 24h, returns to baseline by ~48h (trained)',
      'Untrained: longer MPS (72h+) but directed at damage repair',
      'Fast-twitch muscles (biceps, triceps) recover SLOWER than expected',
      'Calves and quads recover FASTER (slow-twitch dominant)',
    ],
    howWeUseIt:
        'Per-muscle recovery scoring: Recovery(t) = 100 * (1 - fatigue * e^(-k*t)) where k varies by muscle fiber composition (0.042-0.083).',
  ),

  // ── DUP Periodization ────────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.calendar_today,
    color: Color(0xFF6366F1),
    title: 'Modified Daily Undulating Periodization in Powerlifters',
    authors: 'Zourdos, M. C. et al.',
    journal: 'Journal of Strength and Conditioning Research',
    year: '2016',
    summary:
        'Compared HPS (Hypertrophy-Power-Strength) vs HSP rotation order. The HPS order outperformed traditional DUP — the power day between hypertrophy and strength provides recovery.',
    keyFindings: [
      'HPS rotation outperformed traditional HSP order',
      'Power day between hypertrophy and strength aids recovery',
      'Hypertrophy: 5x8 at 75% 1RM; Strength: to failure at given %',
      'DUP produces ~2x strength gains vs linear periodization',
    ],
    howWeUseIt:
        'Quick workout engine uses HPS-style DUP rotation. Tracks last workout type and rotates: Hypertrophy -> Power -> Strength. Recovery overrides when freshness is low.',
  ),

  // ── Volume Landmarks ──────────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.bar_chart,
    color: Color(0xFFA855F7),
    title: 'Training Volume Landmarks for Muscle Growth',
    authors: 'Israetel, M. / RP Strength',
    journal: 'Renaissance Periodization',
    year: '2019-2024',
    summary:
        'Defines per-muscle volume landmarks: MV (Maintenance Volume), MEV (Minimum Effective Volume), MAV (Maximum Adaptive Volume), and MRV (Maximum Recoverable Volume) in weekly sets.',
    keyFindings: [
      'Chest: MEV 10, MAV 12-20, MRV 22 sets/week',
      'Back: MEV 10, MAV 14-22, MRV 25 sets/week',
      'Quads: MEV 8, MAV 12-18, MRV 20 sets/week',
      'Quick workouts (6-9 sets) target 2-3 muscle groups per session',
    ],
    howWeUseIt:
        'Weekly volume tracking ensures quick workouts contribute to MEV targets. Engine selects muscles needing more volume and focuses sets there.',
  ),

  // ── EMOM/AMRAP Research ───────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.access_alarm,
    color: Color(0xFFEAB308),
    title: 'EMOM, AMRAP, and RFT: Muscular Performance Comparison',
    authors: 'Barba-Ruiz, C. et al.',
    journal: 'Frontiers in Physiology',
    year: '2024',
    summary:
        'First direct comparison of EMOM, AMRAP, and RFT (Rounds For Time) protocols. EMOM preserved movement quality best; AMRAP produced highest total volume but greatest fatigue.',
    keyFindings: [
      'EMOM: least velocity loss (8-12%), best movement quality',
      'AMRAP: highest volume but 18-25% velocity loss',
      'EMOM heart rate ~75-80% HRmax vs AMRAP ~85-90% HRmax',
      'EMOM is self-paced by the clock — most consistent output',
    ],
    howWeUseIt:
        'EMOM and AMRAP formats available in quick workouts. EMOM for strength-endurance, AMRAP for conditioning. Auto-scales reps by fitness level.',
  ),

  // ── Drop Sets / Advanced Techniques ───────────────────────────────
  _ResearchPaper(
    icon: Icons.trending_down,
    color: Color(0xFFEF4444),
    title: 'Drop Sets for Muscle Hypertrophy: Systematic Review and Meta-Analysis',
    authors: 'Coleman, M. et al.',
    journal: 'Sports Medicine - Open',
    year: '2023',
    summary:
        'Meta-analysis showing drop sets produce equivalent hypertrophy to traditional sets when volume is matched, but in ~40% less time. Optimal protocol: 2-3 drops at 20-25% weight reduction.',
    keyFindings: [
      'Equivalent hypertrophy in ~40% less time vs traditional sets',
      'Optimal: 2-3 drops at 20-25% weight reduction each',
      'Best for isolation exercises and machine movements',
      'Diminishing returns after 3 drops',
    ],
    howWeUseIt:
        'Drop sets applied to last isolation exercise in time-constrained workouts. Replaces 3 traditional sets with 1 drop set, saving 3-4 minutes.',
  ),

  // ── Minimum Effective Dose ────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.science,
    color: Color(0xFF64748B),
    title: 'Minimum Effective Training Dose for 1RM Strength',
    authors: 'Androulakis-Korakakis, P., Fisher, J. P. & Steele, J.',
    journal: 'Sports Medicine',
    year: '2020',
    summary:
        'Systematic review establishing that a single set at 70-85% 1RM is the minimum effective dose for strength gains in trained men. Even minimal training produces meaningful adaptation.',
    keyFindings: [
      '1 set at 70-85% 1RM is minimum effective for strength',
      'Trained: ~4 sets/muscle/week minimum for continued progress',
      'Untrained: even 1 set produces significant strength gains',
      'RPE 7+ (3 RIR) is the practical threshold for stimulating sets',
    ],
    howWeUseIt:
        'Validates that even 5-minute quick workouts provide meaningful stimulus. Engine ensures minimum 1 hard set per targeted muscle group.',
  ),

  // ── 1RM Prediction ────────────────────────────────────────────────
  _ResearchPaper(
    icon: Icons.calculate,
    color: Color(0xFF0D9488),
    title: '1RM Prediction Equations and RPE-Based Load Prescription',
    authors: 'Epley, Brzycki, Mayhew / Helms, E. R. et al.',
    journal: 'Multiple',
    year: '1985-2016',
    summary:
        'The foundational 1RM prediction formulas (Epley, Brzycki, Mayhew) and the RIR-based RPE scale for autoregulation. Inverse Epley enables rep prescription from any given weight.',
    keyFindings: [
      'Epley (1-5 reps), Brzycki (6-10), Mayhew (10+) — accuracy varies by range',
      'Inverse Epley: reps = 30 * (1RM/weight - 1)',
      'RPE-to-%1RM: percent = 100 / (1 + (reps + RIR) / 30)',
      'EMA update for 1RM: new = 0.7 * current + 0.3 * estimate',
    ],
    howWeUseIt:
        'When weights are snapped to available equipment, inverse Epley calculates correct reps. Post-workout feedback updates 1RM estimates via exponential moving average.',
  ),
];

/// Screen displaying the exercise science research papers backing FitWiz.
class ExerciseScienceResearchScreen extends StatefulWidget {
  const ExerciseScienceResearchScreen({super.key});

  @override
  State<ExerciseScienceResearchScreen> createState() =>
      _ExerciseScienceResearchScreenState();
}

class _ExerciseScienceResearchScreenState
    extends State<ExerciseScienceResearchScreen> {
  final Set<int> _expandedPapers = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final elevated = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final cardBorder =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const GlassBackButton(),
        title: Text(
          'Research',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.info.withValues(alpha: 0.15),
                    AppColors.purple.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.info.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.science_outlined,
                      color: AppColors.info,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Evidence-Based Training',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every workout parameter in FitWiz is derived from peer-reviewed exercise science. Tap a paper to see details.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildStatChip('20', 'Papers', AppColors.info, textMuted),
                      const SizedBox(width: 24),
                      _buildStatChip('14', 'Journals', AppColors.purple, textMuted),
                      const SizedBox(width: 24),
                      _buildStatChip('30yr', 'Span', AppColors.success, textMuted),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.05),

            const SizedBox(height: 24),

            // Paper cards
            ...List.generate(_papers.length, (index) {
              final paper = _papers[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildPaperCard(
                  index: index,
                  paper: paper,
                  elevated: elevated,
                  cardBorder: cardBorder,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  textMuted: textMuted,
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 + index * 50)).slideY(begin: 0.03);
            }),

            const SizedBox(height: 24),

            // Feed Data section
            _buildFeedDataSection(
              elevated: elevated,
              cardBorder: cardBorder,
              textPrimary: textPrimary,
              textSecondary: textSecondary,
              textMuted: textMuted,
            ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.03),

            const SizedBox(height: 24),

            // Footer
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'All training parameters are derived from peer-reviewed exercise science literature. Individual results may vary.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: textMuted,
                    height: 1.5,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 600.ms),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatChip(String value, String label, Color color, Color textMuted) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildFeedDataSection({
    required Color elevated,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with title + Coming Soon badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.cloud_upload_outlined,
                  color: AppColors.purple,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Feed Data to RAG',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.purple.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Explanation
          Text(
            'Feed your own research papers, exercise databases, and training methodologies into our RAG (Retrieval-Augmented Generation) system. This allows the AI coach to draw from even more high-quality sources when generating your personalized workout plans, making suggestions smarter and more tailored to cutting-edge science.',
            style: TextStyle(
              fontSize: 13,
              color: textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: 16),

          // How it works
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.info.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.info.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb_outline, size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text(
                      'How it works',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Upload PDFs, articles, or text files containing exercise science research. Our system processes and indexes the content, making it available as context for the AI when generating your workouts.',
                  style: TextStyle(
                    fontSize: 12,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Human validation note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.success.withValues(alpha: 0.15),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_user, size: 16, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Every submitted source is reviewed and validated by a human before being added to the knowledge base.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.success,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Warnings
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.15),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 14, color: AppColors.error),
                    const SizedBox(width: 6),
                    Text(
                      'Important guidelines',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildWarningItem(
                  Icons.person_off,
                  'Never feed personal or private data',
                  'Do not upload documents containing personal health records, medical history, or any identifying information.',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  Icons.copyright,
                  'Never feed copyrighted material',
                  'Only upload content you have the rights to share, such as open-access papers or your own written material.',
                  textSecondary,
                ),
                const SizedBox(height: 8),
                _buildWarningItem(
                  Icons.block,
                  'Never feed misleading or wrongful data',
                  'Only upload credible, peer-reviewed, or well-sourced exercise science. Incorrect data degrades AI quality for everyone.',
                  textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Grayed out Upload button
          SizedBox(
            width: double.infinity,
            child: AbsorbPointer(
              absorbing: true,
              child: Opacity(
                opacity: 0.4,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.purple.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.upload_file, color: AppColors.purple, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Upload Data',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.purple,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(Coming Soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.purple.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWarningItem(
    IconData icon,
    String title,
    String description,
    Color textSecondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.error.withValues(alpha: 0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  color: textSecondary.withValues(alpha: 0.8),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaperCard({
    required int index,
    required _ResearchPaper paper,
    required Color elevated,
    required Color cardBorder,
    required Color textPrimary,
    required Color textSecondary,
    required Color textMuted,
  }) {
    final isExpanded = _expandedPapers.contains(index);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: elevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded
              ? paper.color.withValues(alpha: 0.4)
              : cardBorder,
          width: isExpanded ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedPapers.remove(index);
                } else {
                  _expandedPapers.add(index);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: paper.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(paper.icon, color: paper.color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          paper.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          paper.authors,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${paper.journal}, ${paper.year}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textMuted,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: textMuted,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expanded details
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(color: cardBorder, height: 1),
                  const SizedBox(height: 14),

                  // Summary
                  Text(
                    paper.summary,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Key Findings
                  Text(
                    'Key Findings',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...paper.keyFindings.map((finding) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 6),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: paper.color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                finding,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 12),

                  // How We Use It
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: paper.color.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: paper.color.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.lightbulb_outline,
                              size: 14,
                              color: paper.color,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'How FitWiz uses this',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: paper.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          paper.howWeUseIt,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            crossFadeState: isExpanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}
