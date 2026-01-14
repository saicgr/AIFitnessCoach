import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Data class for PR information in PDF
class PdfPRData {
  final String exerciseName;
  final String value;
  final String type; // 'weight', 'reps', 'time', 'distance'
  final DateTime? date;

  const PdfPRData({
    required this.exerciseName,
    required this.value,
    required this.type,
    this.date,
  });
}

/// Data class for achievement information in PDF
class PdfAchievementData {
  final String name;
  final String? description;
  final DateTime? earnedDate;

  const PdfAchievementData({
    required this.name,
    this.description,
    this.earnedDate,
  });
}

/// Service for generating PDF stats reports
class PdfExportService {
  // FitWiz brand colors
  static const _primaryColor = PdfColor.fromInt(0xFF00D1C4);
  static const _darkBg = PdfColor.fromInt(0xFF0F1922);
  static const _cardBg = PdfColor.fromInt(0xFF1A2634);
  static const _textPrimary = PdfColor.fromInt(0xFFFFFFFF);
  static const _textMuted = PdfColor.fromInt(0xFF8B9CAF);

  /// Generate a styled stats report PDF
  static Future<Uint8List> generateStatsReport({
    required int totalWorkouts,
    required int currentStreak,
    required int longestStreak,
    required int weeklyCompleted,
    required int weeklyGoal,
    required String dateRange,
    List<PdfPRData>? recentPRs,
    List<PdfAchievementData>? achievements,
    String? userName,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(dateRange, userName),
              pw.SizedBox(height: 24),

              // Summary Stats
              _buildSummarySection(
                totalWorkouts: totalWorkouts,
                currentStreak: currentStreak,
                longestStreak: longestStreak,
              ),
              pw.SizedBox(height: 24),

              // Weekly Progress
              _buildWeeklyProgress(weeklyCompleted, weeklyGoal),
              pw.SizedBox(height: 24),

              // PRs Section (if available)
              if (recentPRs != null && recentPRs.isNotEmpty) ...[
                _buildPRsSection(recentPRs),
                pw.SizedBox(height: 24),
              ],

              // Achievements Section (if available)
              if (achievements != null && achievements.isNotEmpty) ...[
                _buildAchievementsSection(achievements),
                pw.SizedBox(height: 24),
              ],

              pw.Spacer(),

              // Footer
              _buildFooter(),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    debugPrint('[PdfExport] Generated PDF: ${bytes.length} bytes');
    return bytes;
  }

  static pw.Widget _buildHeader(String dateRange, String? userName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'FitWiz Stats Report',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              pw.SizedBox(height: 4),
              if (userName != null)
                pw.Text(
                  userName,
                  style: const pw.TextStyle(
                    fontSize: 14,
                    color: _textMuted,
                  ),
                ),
              pw.Text(
                dateRange,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: _primaryColor,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: _primaryColor,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Text(
              'FW',
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildSummarySection({
    required int totalWorkouts,
    required int currentStreak,
    required int longestStreak,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Summary',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: _buildStatCard(
                label: 'Total Workouts',
                value: totalWorkouts.toString(),
                icon: '💪',
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Current Streak',
                value: '$currentStreak days',
                icon: '🔥',
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: _buildStatCard(
                label: 'Longest Streak',
                value: '$longestStreak days',
                icon: '🏆',
              ),
            ),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildStatCard({
    required String label,
    required String value,
    required String icon,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _cardBg,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: _primaryColor, width: 1),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            icon,
            style: const pw.TextStyle(fontSize: 24),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: _textMuted,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildWeeklyProgress(int completed, int goal) {
    final progress = goal > 0 ? (completed / goal).clamp(0.0, 1.0) : 0.0;
    final percentage = (progress * 100).toInt();

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Weekly Progress',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: _cardBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    '$completed / $goal workouts',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                  pw.Text(
                    '$percentage%',
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              // Progress bar
              pw.Container(
                height: 12,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF2A3A4A),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  children: [
                    pw.Expanded(
                      flex: (progress * 100).toInt(),
                      child: pw.Container(
                        decoration: pw.BoxDecoration(
                          color: _primaryColor,
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                      ),
                    ),
                    if (progress < 1.0)
                      pw.Expanded(
                        flex: ((1 - progress) * 100).toInt(),
                        child: pw.Container(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPRsSection(List<PdfPRData> prs) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Personal Records',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: _cardBg,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Table(
            border: pw.TableBorder.all(color: _textMuted, width: 0.5),
            children: [
              // Header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: _darkBg),
                children: [
                  _buildTableCell('Exercise', isHeader: true),
                  _buildTableCell('Value', isHeader: true),
                  _buildTableCell('Date', isHeader: true),
                ],
              ),
              // Data rows
              ...prs.map((pr) => pw.TableRow(
                    children: [
                      _buildTableCell(pr.exerciseName),
                      _buildTableCell(pr.value),
                      _buildTableCell(
                        pr.date != null
                            ? DateFormat('MMM d, yyyy').format(pr.date!)
                            : '-',
                      ),
                    ],
                  )),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 11 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? _primaryColor : _textPrimary,
        ),
      ),
    );
  }

  static pw.Widget _buildAchievementsSection(List<PdfAchievementData> achievements) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Achievements',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: _textPrimary,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Wrap(
          spacing: 8,
          runSpacing: 8,
          children: achievements.map((achievement) {
            return pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: pw.BoxDecoration(
                color: _cardBg,
                borderRadius: pw.BorderRadius.circular(20),
                border: pw.Border.all(color: _primaryColor, width: 1),
              ),
              child: pw.Text(
                achievement.name,
                style: const pw.TextStyle(
                  fontSize: 11,
                  color: _textPrimary,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  static pw.Widget _buildFooter() {
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy \'at\' h:mm a').format(now);

    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: _textMuted, width: 0.5)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by FitWiz',
            style: const pw.TextStyle(
              fontSize: 10,
              color: _textMuted,
            ),
          ),
          pw.Text(
            dateStr,
            style: const pw.TextStyle(
              fontSize: 10,
              color: _textMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// Generate a simple text summary of stats
  static String generateTextSummary({
    required int totalWorkouts,
    required int currentStreak,
    required int longestStreak,
    required int weeklyCompleted,
    required int weeklyGoal,
    required String dateRange,
    List<PdfPRData>? recentPRs,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('FitWiz Stats Summary');
    buffer.writeln('=' * 30);
    buffer.writeln(dateRange);
    buffer.writeln();

    buffer.writeln('Total Workouts: $totalWorkouts');
    buffer.writeln('Current Streak: $currentStreak days');
    buffer.writeln('Longest Streak: $longestStreak days');
    buffer.writeln('Weekly Progress: $weeklyCompleted / $weeklyGoal');
    buffer.writeln();

    if (recentPRs != null && recentPRs.isNotEmpty) {
      buffer.writeln('Recent PRs:');
      for (final pr in recentPRs.take(5)) {
        final dateStr = pr.date != null
            ? ' (${DateFormat('MMM d').format(pr.date!)})'
            : '';
        buffer.writeln('  - ${pr.exerciseName}: ${pr.value}$dateStr');
      }
      buffer.writeln();
    }

    buffer.writeln('Generated by FitWiz');
    buffer.writeln('https://fitwiz.app');

    return buffer.toString();
  }
}
