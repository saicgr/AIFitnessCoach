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
            Text(
              'Rates how inflammatory a food is based on processing level, fat profile, sugar content, fiber, and antioxidant properties.',
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('1-3', 'Anti-inflammatory', Colors.green),
            _buildInfoRow('4-5', 'Neutral', Colors.teal),
            _buildInfoRow('6-7', 'Mildly inflammatory', Colors.orange),
            _buildInfoRow('8-10', 'Inflammatory', Colors.red),
            const SizedBox(height: 16),
            Text(
              'Lower is better for reducing body inflammation and gut health.',
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
