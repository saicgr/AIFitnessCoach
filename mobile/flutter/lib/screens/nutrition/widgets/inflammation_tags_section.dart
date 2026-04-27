import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class InflammationTagsSection extends StatelessWidget {
  final int? inflammationScore;
  final bool? isUltraProcessed;
  final bool isDark;

  const InflammationTagsSection({
    super.key,
    this.inflammationScore,
    this.isUltraProcessed,
    required this.isDark,
  });

  bool get _hasAnyTag =>
      inflammationScore != null || isUltraProcessed == true;

  @override
  Widget build(BuildContext context) {
    if (!_hasAnyTag) return const SizedBox.shrink();

    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Column(
      children: [
        if (inflammationScore != null) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _inflammationColor(inflammationScore!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _inflammationColor(inflammationScore!).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _inflammationColor(inflammationScore!).withValues(alpha: 0.2),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${inflammationScore!}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _inflammationColor(inflammationScore!),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Inflammation Score',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () => _showInflammationInfo(context),
                            child: Icon(Icons.info_outline, size: 16, color: textMuted),
                          ),
                        ],
                      ),
                      Text(
                        _inflammationLabel(inflammationScore!),
                        style: TextStyle(
                          fontSize: 11,
                          color: _inflammationColor(inflammationScore!),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: inflammationScore! / 10.0,
                      backgroundColor: cardBorder.withValues(alpha: 0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _inflammationColor(inflammationScore!),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (isUltraProcessed == true) ...[
          if (inflammationScore != null) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Contains ultra-processed items',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _showUltraProcessedInfo(context),
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.red.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Color _inflammationColor(int score) {
    if (score <= 3) return Colors.green;
    if (score <= 5) return Colors.teal;
    if (score <= 7) return Colors.orange;
    return Colors.red;
  }

  String _inflammationLabel(int score) {
    if (score <= 2) return 'Anti-inflammatory';
    if (score <= 4) return 'Mildly anti-inflammatory';
    if (score == 5) return 'Neutral';
    if (score <= 7) return 'Mildly inflammatory';
    if (score <= 9) return 'Inflammatory';
    return 'Highly inflammatory';
  }

  void _showInflammationInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final score = inflammationScore ?? 5;
    final color = _inflammationColor(score);
    final drivers = _driversFor(score);
    final mechanism = _mechanismFor(score);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_fire_department, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Inflammation Score',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Why THIS score — opens with the user-facing rating, then the
            // chemistry/biology drivers behind it. This is the part the
            // user explicitly asked for ("what chemical or what?").
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color.withValues(alpha: 0.2),
                        ),
                        child: Text(
                          '$score',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Why this scored ${_inflammationLabel(score).toLowerCase()}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ...drivers.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                d,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 6),
                  Text(
                    mechanism,
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.white54 : Colors.black54,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),
            Text(
              'How the score is built',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'NOVA processing level, omega-6:omega-3 fat ratio, refined-sugar load, fiber & polyphenol density, glycemic load, and seed-oil content. Calibrated to peer-reviewed Dietary Inflammatory Index (DII) buckets.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 14),
            _buildInfoRow('1-3', 'Anti-inflammatory', Colors.green),
            _buildInfoRow('4-5', 'Neutral', Colors.teal),
            _buildInfoRow('6-7', 'Mildly inflammatory', Colors.orange),
            _buildInfoRow('8-10', 'Inflammatory', Colors.red),
            const SizedBox(height: 12),
            Text(
              'Lower scores reduce systemic inflammation, gut irritation, and post-meal energy crashes.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// Plain-English drivers for the score bucket. These are the chemistry/
  /// biology levers the score is sensitive to — surfaced so users can see
  /// WHY a meal landed where it did, not just where it landed.
  List<String> _driversFor(int score) {
    if (score <= 3) {
      return const [
        'Rich in omega-3 fats (EPA/DHA) and polyphenols — both directly downregulate NF-κB and COX-2 pathways.',
        'High fiber load feeds short-chain-fatty-acid production in the gut, which lowers systemic inflammation.',
        'No ultra-processed additives, refined sugar, or industrial seed oils.',
      ];
    }
    if (score <= 5) {
      return const [
        'Macronutrients are balanced; little refined sugar and modest seed-oil content.',
        'Some processed components or saturated fat present, but offset by fiber/protein.',
        'Glycemic load is moderate — minor blood-sugar swing, no large insulin spike.',
      ];
    }
    if (score <= 7) {
      return const [
        'Notable refined-carb or added-sugar content — drives a glucose/insulin spike that promotes inflammatory cytokines.',
        'Seed-oil or fried-prep contribution skews omega-6 high (linoleic acid → arachidonic acid pathway).',
        'Low fiber-to-carb ratio reduces the gut\'s short-chain-fatty-acid buffer.',
      ];
    }
    return const [
      'Ultra-processed (NOVA-4) markers: emulsifiers, hydrogenated oils, artificial sweeteners, or HFCS.',
      'High in advanced glycation end-products (AGEs) from deep-frying / browning — drives oxidative stress.',
      'High glycemic load + omega-6 dominance → strong post-meal inflammatory cascade (TNF-α, IL-6).',
    ];
  }

  String _mechanismFor(int score) {
    if (score <= 3) return 'Net effect: anti-inflammatory — supports recovery, gut barrier, and insulin sensitivity.';
    if (score <= 5) return 'Net effect: neutral — won\'t drive inflammation up or down on its own.';
    if (score <= 7) return 'Net effect: mildly pro-inflammatory — fine occasionally, problematic if eaten daily.';
    return 'Net effect: strongly pro-inflammatory — repeated intake is linked to fatigue, joint stiffness, and metabolic stress.';
  }

  Widget _buildInfoRow(String range, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 40,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              range,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 14, color: color)),
        ],
      ),
    );
  }

  void _showUltraProcessedInfo(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Ultra-Processed Foods',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Ultra-processed foods (NOVA Group 4) contain industrial additives like emulsifiers, hydrogenated oils, artificial sweeteners, and protein isolates — substances not found in home cooking.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Research links regular consumption to increased inflammation, obesity, heart disease, and digestive issues.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Examples: soft drinks, instant noodles, packaged snacks, chicken nuggets, most breakfast cereals.',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
