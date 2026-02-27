import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/providers/consistency_provider.dart';
import '../../../data/providers/scores_provider.dart';
import '../../../data/repositories/workout_repository.dart';
import '../../../data/services/haptic_service.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../../widgets/glass_sheet.dart';
import '../../settings/dialogs/export_dialog.dart';

/// Bottom sheet for exporting stats in various formats
class ExportStatsSheet extends ConsumerStatefulWidget {
  const ExportStatsSheet({super.key});

  static Future<void> show(BuildContext context, WidgetRef ref) {
    return showGlassSheet(
      context: context,
      useRootNavigator: true,
      builder: (context) => const ExportStatsSheet(),
    );
  }

  @override
  ConsumerState<ExportStatsSheet> createState() => _ExportStatsSheetState();
}

class _ExportStatsSheetState extends ConsumerState<ExportStatsSheet> {
  bool _isExporting = false;

  String get _dateRangeLabel {
    final customRange = ref.read(customStatsDateRangeProvider);
    if (customRange != null) {
      final formatter = DateFormat('MMM d, yyyy');
      return '${formatter.format(customRange.start)} - ${formatter.format(customRange.end)}';
    }

    final timeRange = ref.read(heatmapTimeRangeProvider);
    final now = DateTime.now();
    final start = now.subtract(Duration(days: timeRange.weeks * 7));
    final formatter = DateFormat('MMM d, yyyy');
    return '${formatter.format(start)} - ${formatter.format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;

    return GlassSheet(
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.file_download_outlined,
                    color: isDark ? AppColors.cyan : AppColorsLight.cyan,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Export Stats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Export options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // CSV/ZIP Export
                  _ExportOptionCard(
                    icon: Icons.folder_zip_outlined,
                    iconColor: Colors.orange,
                    title: 'CSV / ZIP',
                    description: 'Full data export with all workouts, PRs, and measurements',
                    onTap: _isExporting ? null : () => _exportCsvZip(context),
                  ),
                  const SizedBox(height: 12),

                  // PDF Report
                  _ExportOptionCard(
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: Colors.red,
                    title: 'PDF Report',
                    description: 'Styled report with stats summary and progress',
                    onTap: _isExporting ? null : _exportPdf,
                  ),
                  const SizedBox(height: 12),

                  // Text Summary
                  _ExportOptionCard(
                    icon: Icons.text_snippet_outlined,
                    iconColor: Colors.blue,
                    title: 'Text Summary',
                    description: 'Quick shareable text summary of your stats',
                    onTap: _isExporting ? null : _exportText,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _exportCsvZip(BuildContext context) {
    HapticService.light();
    Navigator.pop(context);
    // Open the existing export dialog
    showExportDialog(context, ref);
  }

  Future<void> _exportPdf() async {
    HapticService.light();
    setState(() => _isExporting = true);

    try {
      // Get stats data
      final consistencyState = ref.read(consistencyProvider);
      final workoutsNotifier = ref.read(workoutsProvider.notifier);
      final weeklyProgress = workoutsNotifier.weeklyProgress;

      // Map real PR data from scores provider
      final prStats = ref.read(prStatsProvider);
      final realPRs = prStats?.recentPrs.map((pr) => PdfPRData(
        exerciseName: pr.exerciseDisplayName,
        value: '${pr.weightKg.toStringAsFixed(1)} kg x ${pr.reps}',
        type: 'weight',
        date: DateTime.tryParse(pr.achievedAt),
      )).toList();

      // Generate PDF
      final pdfBytes = await PdfExportService.generateStatsReport(
        totalWorkouts: consistencyState.insights?.monthWorkoutsCompleted ??
            workoutsNotifier.completedCount,
        currentStreak: consistencyState.currentStreak,
        longestStreak: consistencyState.longestStreak,
        weeklyCompleted: weeklyProgress.$1,
        weeklyGoal: weeklyProgress.$2,
        dateRange: _dateRangeLabel,
        recentPRs: realPRs ?? [],
        achievements: [],
      );

      // Save to temp file
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().toIso8601String().split('T')[0];
      final filePath = '${tempDir.path}/FitWiz_Stats_$timestamp.pdf';
      final file = File(filePath);
      await file.writeAsBytes(pdfBytes);

      // Share the file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'FitWiz Stats Report',
        text: 'My fitness stats from FitWiz',
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('PDF report exported!');
      }
    } catch (e) {
      debugPrint('[ExportStats] PDF export error: $e');
      if (mounted) {
        _showError('Failed to export PDF: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportText() async {
    HapticService.light();
    setState(() => _isExporting = true);

    try {
      // Get stats data
      final consistencyState = ref.read(consistencyProvider);
      final workoutsNotifier = ref.read(workoutsProvider.notifier);
      final weeklyProgress = workoutsNotifier.weeklyProgress;

      // Map real PR data from scores provider
      final prStats = ref.read(prStatsProvider);
      final realPRs = prStats?.recentPrs.map((pr) => PdfPRData(
        exerciseName: pr.exerciseDisplayName,
        value: '${pr.weightKg.toStringAsFixed(1)} kg x ${pr.reps}',
        type: 'weight',
        date: DateTime.tryParse(pr.achievedAt),
      )).toList();

      // Generate text summary
      final textSummary = PdfExportService.generateTextSummary(
        totalWorkouts: consistencyState.insights?.monthWorkoutsCompleted ??
            workoutsNotifier.completedCount,
        currentStreak: consistencyState.currentStreak,
        longestStreak: consistencyState.longestStreak,
        weeklyCompleted: weeklyProgress.$1,
        weeklyGoal: weeklyProgress.$2,
        dateRange: _dateRangeLabel,
        recentPRs: realPRs ?? [],
      );

      // Share the text
      await Share.share(
        textSummary,
        subject: 'My FitWiz Stats',
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccess('Text summary shared!');
      }
    } catch (e) {
      debugPrint('[ExportStats] Text export error: $e');
      if (mounted) {
        _showError('Failed to share text: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Card widget for each export option
class _ExportOptionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _ExportOptionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBg = isDark
        ? AppColors.pureBlack.withOpacity(0.3)
        : AppColorsLight.background;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cardBorder),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
