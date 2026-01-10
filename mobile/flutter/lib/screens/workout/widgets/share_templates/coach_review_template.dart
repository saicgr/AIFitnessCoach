import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/coach_persona.dart';
import 'app_watermark.dart';

/// Coach Review Template - Shows the AI coach's review/opinion of the workout
/// Features the selected coach persona with their feedback
class CoachReviewTemplate extends StatelessWidget {
  final String workoutName;
  final int durationSeconds;
  final int? calories;
  final double? totalVolumeKg;
  final int exercisesCount;
  final int? totalSets;
  final int? totalReps;
  final CoachPersona? coach;
  final String? coachReview;
  final double? performanceRating; // 0.0 - 1.0
  final DateTime completedAt;
  final bool showWatermark;

  const CoachReviewTemplate({
    super.key,
    required this.workoutName,
    required this.durationSeconds,
    this.calories,
    this.totalVolumeKg,
    required this.exercisesCount,
    this.totalSets,
    this.totalReps,
    this.coach,
    this.coachReview,
    this.performanceRating,
    required this.completedAt,
    this.showWatermark = true,
  });

  String get _formattedDuration {
    final hours = durationSeconds ~/ 3600;
    final minutes = (durationSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// Generate a coach review based on the workout stats and coach personality
  String get _generatedReview {
    if (coachReview != null && coachReview!.isNotEmpty) {
      return coachReview!;
    }

    final coachId = coach?.id ?? 'coach_mike';
    final rating = performanceRating ?? 0.8;

    switch (coachId) {
      case 'coach_mike':
        if (rating >= 0.9) {
          return "INCREDIBLE workout, champ! 💪 You absolutely crushed it today! This is the kind of effort that builds champions!";
        } else if (rating >= 0.7) {
          return "Great work today! 💪 You showed up and gave it your all. Keep this momentum going, champ!";
        }
        return "Good effort today! Remember, every rep counts. Let's come back stronger next time! 💪";

      case 'dr_sarah':
        if (rating >= 0.9) {
          return "Excellent performance metrics. Your workout volume and intensity were optimal for progressive overload. Well executed.";
        } else if (rating >= 0.7) {
          return "Solid workout with good adherence to the program. The data shows consistent effort and proper form execution.";
        }
        return "Adequate session. Consider increasing time under tension next session for optimal hypertrophy stimulus.";

      case 'sergeant_max':
        if (rating >= 0.9) {
          return "NOW THAT'S WHAT I'M TALKING ABOUT! 💥 You earned every drop of sweat today, soldier! OUTSTANDING!";
        } else if (rating >= 0.7) {
          return "Solid effort, recruit! You pushed through when it got tough. That's what separates warriors from quitters!";
        }
        return "Acceptable work, but I know you've got more in the tank! NO EXCUSES next time! 💥";

      case 'zen_maya':
        if (rating >= 0.9) {
          return "Beautiful session 🧘 Your body and mind moved in perfect harmony today. You honored your practice beautifully.";
        } else if (rating >= 0.7) {
          return "A mindful practice today 🧘 You listened to your body and moved with intention. Growth happens in these moments.";
        }
        return "Every journey has its ebbs and flows 🧘 Today was a step forward on your path. Embrace it.";

      case 'hype_danny':
        if (rating >= 0.9) {
          return "YOOO THIS WORKOUT WAS ABSOLUTELY INSANE!! 🔥🔥 You're literally built different no cap!! SHEEEESH!!";
        } else if (rating >= 0.7) {
          return "Ayooo that was fire fr fr! 🔥 You really showed up today and ate that workout UP! W's only!!";
        }
        return "Not bad not bad! 🔥 Every session makes you better fam! Let's run it back even harder next time!!";

      default:
        if (rating >= 0.9) {
          return "Outstanding workout! You gave 100% effort and it shows. Keep up the amazing work! 💪";
        } else if (rating >= 0.7) {
          return "Great session today! Consistency like this is what builds results. Well done! 💪";
        }
        return "Good effort! Every workout counts toward your goals. Keep showing up! 💪";
    }
  }

  Color get _coachColor => coach?.primaryColor ?? AppColors.cyan;
  Color get _coachAccent => coach?.accentColor ?? AppColors.purple;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final templateHeight = (screenHeight * 0.48).clamp(360.0, 480.0);

    return Container(
      width: 320,
      height: templateHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _coachColor.withValues(alpha: 0.2),
            const Color(0xFF1A1A1A),
            const Color(0xFF0D0D0D),
          ],
          stops: const [0.0, 0.4, 1.0],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _CoachPatternPainter(color: _coachColor),
            ),
          ),

          // Main content
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Coach header
                _buildCoachHeader(),

                const SizedBox(height: 14),

                // Workout info
                Text(
                  workoutName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Quick stats
                _buildQuickStats(),

                const SizedBox(height: 12),

                // Coach review
                Expanded(
                  child: _buildReviewSection(),
                ),

                if (showWatermark) ...[
                  const SizedBox(height: 10),
                  const AppWatermark(),
                ] else
                  const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoachHeader() {
    final coachName = coach?.name ?? 'AI Coach';
    final coachEmoji = coach?.emoji ?? '🤖';

    return Row(
      children: [
        // Coach avatar
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_coachColor, _coachAccent],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _coachColor.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              coachEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                coachName,
                style: TextStyle(
                  color: _coachColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'WORKOUT REVIEW',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),

        // Rating badge
        if (performanceRating != null) _buildRatingBadge(),
      ],
    );
  }

  Widget _buildRatingBadge() {
    final rating = performanceRating ?? 0.8;
    final stars = (rating * 5).round();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _coachColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _coachColor.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          return Icon(
            index < stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: 14,
            color: index < stars ? _coachColor : Colors.white.withValues(alpha: 0.3),
          );
        }),
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(Icons.timer_outlined, _formattedDuration),
          _buildDivider(),
          _buildStatItem(Icons.fitness_center, '$exercisesCount ex'),
          if (totalVolumeKg != null) ...[
            _buildDivider(),
            _buildStatItem(Icons.scale_outlined, '${totalVolumeKg!.toStringAsFixed(0)}kg'),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: _coachColor),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 16,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildReviewSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: _coachColor.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.format_quote_rounded,
                size: 18,
                color: _coachColor.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 6),
              Text(
                "Coach's Review",
                style: TextStyle(
                  color: _coachColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              _generatedReview,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter for coach-themed background pattern
class _CoachPatternPainter extends CustomPainter {
  final Color color;

  _CoachPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    // Gradient circle top-left
    final paint1 = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.7, -0.5),
        radius: 0.8,
        colors: [
          color.withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawCircle(
      Offset(size.width * 0.15, size.height * 0.2),
      size.width * 0.5,
      paint1,
    );

    // Subtle dots pattern
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.fill;

    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
