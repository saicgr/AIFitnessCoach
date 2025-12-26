import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

/// PRs Template - Showcases personal records achieved in the workout
/// Gold/trophy theme with achievement highlights
class PrsTemplate extends StatelessWidget {
  final String workoutName;
  final List<Map<String, dynamic>> prsData;
  final List<Map<String, dynamic>>? achievementsData;
  final DateTime completedAt;

  const PrsTemplate({
    super.key,
    required this.workoutName,
    required this.prsData,
    this.achievementsData,
    required this.completedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      height: 640,
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
      child: Stack(
        children: [
          // Gold shimmer effect
          Positioned.fill(
            child: CustomPaint(
              painter: _GoldShimmerPainter(),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                // Trophy icon
                _buildTrophyHeader(),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'NEW PERSONAL RECORDS',
                  style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  workoutName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 32),

                // PRs list
                Expanded(
                  child: _buildPrsList(),
                ),

                // Achievements row (if any)
                if (achievementsData != null && achievementsData!.isNotEmpty)
                  _buildAchievementsRow(),

                const SizedBox(height: 16),

                // Watermark
                _buildWatermark(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyHeader() {
    return Container(
      width: 80,
      height: 80,
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
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events_rounded,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildPrsList() {
    if (prsData.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.star_outline_rounded,
              size: 64,
              color: Colors.white.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keep pushing!',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'New PRs are just around the corner',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: prsData.length > 4 ? 4 : prsData.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final pr = prsData[index];
        return _buildPrCard(pr);
      },
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

  Widget _buildWatermark() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFDAA520)],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.fitness_center,
                  size: 12,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'AI Fitness Coach',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
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
