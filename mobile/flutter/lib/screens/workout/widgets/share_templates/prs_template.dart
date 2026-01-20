import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'app_watermark.dart';

/// PRs Template - Showcases personal records achieved in the workout
/// Gold/trophy theme with achievement highlights
class PrsTemplate extends StatelessWidget {
  final String workoutName;
  final List<Map<String, dynamic>> prsData;
  final List<Map<String, dynamic>>? achievementsData;
  final DateTime completedAt;
  final bool showWatermark;

  const PrsTemplate({
    super.key,
    required this.workoutName,
    required this.prsData,
    this.achievementsData,
    required this.completedAt,
    this.showWatermark = true,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate responsive height based on available space
    final screenHeight = MediaQuery.of(context).size.height;
    final templateHeight = (screenHeight * 0.48).clamp(360.0, 480.0);

    return Container(
      width: 320,
      height: templateHeight,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2D1F00),
            Color(0xFF1A1200),
            Color(0xFF0D0A00),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Gold shimmer effect
            Positioned.fill(
              child: CustomPaint(
                painter: _GoldShimmerPainter(),
              ),
            ),

            // Main content - wrapped in FittedBox to prevent overflow
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.topCenter,
                child: SizedBox(
                  width: 320,
                  height: 440,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Trophy icon
                        _buildTrophyHeader(),

                        const SizedBox(height: 10),

                        // Title
                        const Text(
                          'NEW PERSONAL RECORDS',
                          style: TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 2,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          workoutName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 10),

                        // PRs list - no Expanded wrapper
                        _buildPrsList(),

                        // Achievements row (if any)
                        if (achievementsData != null && achievementsData!.isNotEmpty)
                          _buildAchievementsRow(),

                        if (showWatermark) ...[
                          const SizedBox(height: 10),
                          const AppWatermark(),
                        ] else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrophyHeader() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFDAA520),
            Color(0xFFB8860B),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.4),
            blurRadius: 20,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 36,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPrsList() {
    if (prsData.isEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 48,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'Keep pushing!',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'New PRs are just around the corner',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      );
    }

    // Limit to 2 PRs max to prevent overflow
    final limitedPrs = prsData.take(2).toList();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: limitedPrs.asMap().entries.map((entry) {
        return Padding(
          padding: EdgeInsets.only(bottom: entry.key < limitedPrs.length - 1 ? 8 : 0),
          child: _buildPrCard(entry.value),
        );
      }).toList(),
    );
  }

  Widget _buildPrCard(Map<String, dynamic> pr) {
    final exercise = pr['exercise'] as String? ?? 'Exercise';
    final weight = pr['weight_kg'] as num? ?? pr['value'] as num?;
    final prType = pr['pr_type'] as String? ?? 'weight';
    final unit = prType == 'weight' ? 'kg' : (pr['unit'] as String? ?? '');
    final improvement = pr['improvement'] as num?;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withValues(alpha: 0.15),
            const Color(0xFFFFD700).withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // PR badge
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFB8860B)],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.trending_up_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),

          const SizedBox(width: 16),

          // Exercise info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '${weight?.toStringAsFixed(1) ?? '--'} $unit',
                      style: const TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (improvement != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+${improvement.toStringAsFixed(1)} $unit',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.military_tech_rounded,
            color: Colors.white.withValues(alpha: 0.7),
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            '+${achievementsData!.length} Achievements Unlocked',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

}

/// Custom painter for gold shimmer effect
class _GoldShimmerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.5, -0.5),
        radius: 1.2,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Additional shimmer spots
    final shimmerPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.8, 0.3),
        radius: 0.5,
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), shimmerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
