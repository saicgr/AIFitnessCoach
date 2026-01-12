/// PR Share Card
///
/// Shareable card for Instagram Stories (1080x1920) showcasing PRs.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../data/services/pr_detection_service.dart';

/// PR Share card widget
class PRShareCard extends StatelessWidget {
  final DetectedPR pr;
  final String workoutName;
  final bool showWatermark;
  final bool isDarkTheme;
  final bool showProgressChart;
  final List<Map<String, dynamic>>? progressData;

  const PRShareCard({
    super.key,
    required this.pr,
    required this.workoutName,
    this.showWatermark = true,
    this.isDarkTheme = true,
    this.showProgressChart = true,
    this.progressData,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDarkTheme
        ? const Color(0xFF0A0A0A)
        : const Color(0xFFF5F5F5);
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final subtitleColor = isDarkTheme
        ? Colors.white.withOpacity(0.7)
        : Colors.black.withOpacity(0.6);

    return Container(
      width: 1080,
      height: 1920,
      color: backgroundColor,
      child: Stack(
        children: [
          // Background gradient
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    const Color(0xFFFFD700).withOpacity(0.15),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(60),
            child: Column(
              children: [
                const SizedBox(height: 100),

                // Trophy icon with glow
                _buildTrophyIcon(),

                const SizedBox(height: 60),

                // Title
                Text(
                  'NEW PERSONAL RECORD!',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFFFD700),
                    letterSpacing: 4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 80),

                // PR card
                _buildPRCard(textColor, subtitleColor, backgroundColor),

                if (showProgressChart && progressData != null) ...[
                  const SizedBox(height: 60),
                  _buildProgressChart(textColor, subtitleColor),
                ],

                const Spacer(),

                // Workout info
                Text(
                  'Workout: $workoutName',
                  style: TextStyle(
                    fontSize: 28,
                    color: subtitleColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  DateFormat('MMMM d, yyyy').format(pr.achievedAt),
                  style: TextStyle(
                    fontSize: 24,
                    color: subtitleColor.withOpacity(0.7),
                  ),
                ),

                const SizedBox(height: 60),

                // Watermark
                if (showWatermark) _buildWatermark(subtitleColor),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrophyIcon() {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.5),
            blurRadius: 60,
            spreadRadius: 20,
          ),
        ],
      ),
      child: const Icon(
        Icons.emoji_events,
        color: Colors.white,
        size: 100,
      ),
    );
  }

  Widget _buildPRCard(Color textColor, Color subtitleColor, Color backgroundColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(48),
      decoration: BoxDecoration(
        color: isDarkTheme
            ? Colors.white.withOpacity(0.08)
            : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: const Color(0xFFFFD700).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Exercise name
          Text(
            pr.exerciseName.toUpperCase(),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Main value
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                pr.formattedValue.split(' ').first,
                style: TextStyle(
                  fontSize: 96,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  height: 1,
                ),
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  pr.formattedValue.split(' ').last,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w600,
                    color: subtitleColor,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Reps info
          Text(
            '${pr.reps} reps',
            style: TextStyle(
              fontSize: 32,
              color: subtitleColor,
              fontWeight: FontWeight.w500,
            ),
          ),

          if (pr.previousValue != null) ...[
            const SizedBox(height: 24),

            // Improvement badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                pr.formattedImprovement,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4CAF50),
                ),
              ),
            ),
          ],

          // Estimated 1RM
          if (pr.type == PRType.weight || pr.type == PRType.oneRM) ...[
            const SizedBox(height: 24),
            Text(
              'Est. 1RM: ${_calculate1RM(pr.weight, pr.reps).toStringAsFixed(1)} kg',
              style: TextStyle(
                fontSize: 24,
                color: subtitleColor.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressChart(Color textColor, Color subtitleColor) {
    if (progressData == null || progressData!.isEmpty) {
      return const SizedBox.shrink();
    }

    // Get last 10 data points
    final data = progressData!.take(10).toList().reversed.toList();
    final maxWeight = data.fold<double>(
      0,
      (max, d) => (d['weight_kg'] ?? 0.0).toDouble() > max
          ? (d['weight_kg'] ?? 0.0).toDouble()
          : max,
    );

    return Container(
      height: 200,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: CustomPaint(
        size: const Size(double.infinity, 200),
        painter: ProgressChartPainter(
          data: data,
          maxWeight: maxWeight * 1.1,
          lineColor: const Color(0xFFFFD700),
          isDark: isDarkTheme,
        ),
      ),
    );
  }

  Widget _buildWatermark(Color subtitleColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.cyan.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fitness_center,
            color: AppColors.cyan,
            size: 28,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'FitWiz',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: subtitleColor,
          ),
        ),
      ],
    );
  }

  double _calculate1RM(double weight, int reps) {
    if (reps <= 0) return 0;
    if (reps == 1) return weight;
    return weight * (1 + 0.0333 * reps);
  }
}

/// Simple progress chart painter
class ProgressChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> data;
  final double maxWeight;
  final Color lineColor;
  final bool isDark;

  ProgressChartPainter({
    required this.data,
    required this.maxWeight,
    required this.lineColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || maxWeight <= 0) return;

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final weight = (data[i]['weight_kg'] ?? 0.0).toDouble();
      final x = (i / (data.length - 1)) * size.width;
      final y = size.height - (weight / maxWeight) * size.height;
      points.add(Offset(x, y));

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    // Draw line
    canvas.drawPath(path, paint);

    // Draw dots
    for (final point in points) {
      canvas.drawCircle(point, 8, dotPaint);
    }

    // Highlight last point (current PR)
    if (points.isNotEmpty) {
      final lastPaint = Paint()
        ..color = lineColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.last, 14, lastPaint);

      final innerPaint = Paint()
        ..color = isDark ? Colors.black : Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points.last, 8, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ProgressChartPainter oldDelegate) {
    return data != oldDelegate.data || maxWeight != oldDelegate.maxWeight;
  }
}

/// Helper to capture widget as image for sharing
class ShareCardCapture {
  static Future<Uint8List?> captureWidget({
    required GlobalKey key,
    double pixelRatio = 1.0,
  }) async {
    try {
      final boundary = key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing widget: $e');
      return null;
    }
  }
}

/// PR Share Sheet for customization and sharing
class PRShareSheet extends StatefulWidget {
  final DetectedPR pr;
  final String workoutName;
  final List<Map<String, dynamic>>? progressData;

  const PRShareSheet({
    super.key,
    required this.pr,
    required this.workoutName,
    this.progressData,
  });

  @override
  State<PRShareSheet> createState() => _PRShareSheetState();
}

class _PRShareSheetState extends State<PRShareSheet> {
  bool _showWatermark = true;
  bool _isDarkTheme = true;
  bool _showProgressChart = true;
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.2)
                  : Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Text(
                  'Share Your PR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),

          // Preview (scaled down)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: RepaintBoundary(
                    key: _cardKey,
                    child: PRShareCard(
                      pr: widget.pr,
                      workoutName: widget.workoutName,
                      showWatermark: _showWatermark,
                      isDarkTheme: _isDarkTheme,
                      showProgressChart: _showProgressChart,
                      progressData: widget.progressData,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Options
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildOption(
                  'Show watermark',
                  _showWatermark,
                  (v) => setState(() => _showWatermark = v),
                  isDark,
                ),
                _buildOption(
                  'Dark theme',
                  _isDarkTheme,
                  (v) => setState(() => _isDarkTheme = v),
                  isDark,
                ),
                if (widget.progressData != null)
                  _buildOption(
                    'Show progress chart',
                    _showProgressChart,
                    (v) => setState(() => _showProgressChart = v),
                    isDark,
                  ),
              ],
            ),
          ),

          // Share buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _copyText,
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Text'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share),
                    label: const Text('Share Image'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.cyan,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(
    String label,
    bool value,
    ValueChanged<bool> onChanged,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const Spacer(),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.cyan,
          ),
        ],
      ),
    );
  }

  void _copyText() {
    final text = '''
NEW PERSONAL RECORD! 🏆

${widget.pr.exerciseName}
${widget.pr.formattedValue} x ${widget.pr.reps} reps
${widget.pr.previousValue != null ? widget.pr.formattedImprovement : 'First time!'}

Workout: ${widget.workoutName}
${DateFormat('MMMM d, yyyy').format(widget.pr.achievedAt)}

#FitWiz #PersonalRecord #Fitness #Gym
''';

    // TODO: Copy to clipboard
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
    Navigator.pop(context);
  }

  Future<void> _shareImage() async {
    // TODO: Implement image sharing
    // 1. Capture widget as image using ShareCardCapture
    // 2. Save to temp file
    // 3. Share using share_plus package

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing PR card...')),
    );
    Navigator.pop(context);
  }
}
