import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../data/models/home_layout.dart';
import '../../../../data/repositories/measurements_repository.dart';
import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/services/haptic_service.dart';
import '../../../progress/log_measurement_sheet.dart';

/// Quick Log Measurements Tile - Shows key body measurements
/// Displays waist, chest, hips with last update and quick update button
class QuickLogMeasurementsCard extends ConsumerWidget {
  final TileSize size;
  final bool isDark;

  const QuickLogMeasurementsCard({
    super.key,
    this.size = TileSize.half,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final elevatedColor = isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textColor = isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final cardBorder = isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    final measurementsState = ref.watch(measurementsProvider);
    final summary = measurementsState.summary;
    final isLoading = measurementsState.isLoading;

    // Get key measurements
    final waist = summary?.latestByType[MeasurementType.waist];
    final chest = summary?.latestByType[MeasurementType.chest];
    final hips = summary?.latestByType[MeasurementType.hips];

    // Calculate last update time
    String lastUpdatedText = 'Not logged yet';
    DateTime? lastUpdate;

    for (final m in [waist, chest, hips]) {
      if (m != null && (lastUpdate == null || m.recordedAt.isAfter(lastUpdate))) {
        lastUpdate = m.recordedAt;
      }
    }

    if (lastUpdate != null) {
      final daysAgo = DateTime.now().difference(lastUpdate).inDays;
      if (daysAgo == 0) {
        lastUpdatedText = 'Updated today';
      } else if (daysAgo == 1) {
        lastUpdatedText = 'Updated yesterday';
      } else {
        lastUpdatedText = 'Updated $daysAgo days ago';
      }
    }

    // Build the appropriate layout based on size
    if (size == TileSize.compact) {
      return _buildCompactLayout(
        context,
        ref,
        elevatedColor: elevatedColor,
        textColor: textColor,
        textMuted: textMuted,
        cardBorder: cardBorder,
        hasMeasurements: waist != null || chest != null || hips != null,
      );
    }

    return InkWell(
      onTap: () => _openMeasurementsSheet(context, ref),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: size == TileSize.full
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 4)
            : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: isLoading
            ? _buildLoadingState(textMuted)
            : (waist == null && chest == null && hips == null)
                ? _buildEmptyState(textMuted, context, ref)
                : _buildContentState(
                    context,
                    ref,
                    textColor: textColor,
                    textMuted: textMuted,
                    waist: waist,
                    chest: chest,
                    hips: hips,
                    lastUpdatedText: lastUpdatedText,
                  ),
      ),
    );
  }

  Widget _buildCompactLayout(
    BuildContext context,
    WidgetRef ref, {
    required Color elevatedColor,
    required Color textColor,
    required Color textMuted,
    required Color cardBorder,
    required bool hasMeasurements,
  }) {
    return InkWell(
      onTap: () => _openMeasurementsSheet(context, ref),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: elevatedColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.straighten,
              color: AppColors.purple,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              hasMeasurements ? 'Measurements' : 'Log',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color textMuted) {
    return Row(
      children: [
        SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'Loading measurements...',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(Color textMuted, BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.straighten, color: AppColors.purple, size: 20),
            const SizedBox(width: 8),
            Text(
              'Body Measurements',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Track your body changes over time',
          style: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: () => _openMeasurementsSheet(context, ref),
          icon: Icon(Icons.add, size: 18),
          label: Text('Log Measurements'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.purple,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
        ),
      ],
    );
  }

  Widget _buildContentState(
    BuildContext context,
    WidgetRef ref, {
    required Color textColor,
    required Color textMuted,
    required MeasurementEntry? waist,
    required MeasurementEntry? chest,
    required MeasurementEntry? hips,
    required String lastUpdatedText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        Row(
          children: [
            Icon(Icons.straighten, color: AppColors.purple, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Measurements',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textMuted,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: textMuted,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Measurements row
        Row(
          children: [
            if (waist != null)
              Expanded(
                child: _MeasurementItem(
                  label: 'Waist',
                  value: '${waist.getValueInUnit(false).toStringAsFixed(1)}"',
                  color: AppColors.purple,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
              ),
            if (waist != null && (chest != null || hips != null))
              Container(
                width: 1,
                height: 36,
                color: textMuted.withValues(alpha: 0.2),
              ),
            if (chest != null)
              Expanded(
                child: _MeasurementItem(
                  label: 'Chest',
                  value: '${chest.getValueInUnit(false).toStringAsFixed(1)}"',
                  color: AppColors.cyan,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
              ),
            if (chest != null && hips != null)
              Container(
                width: 1,
                height: 36,
                color: textMuted.withValues(alpha: 0.2),
              ),
            if (hips != null)
              Expanded(
                child: _MeasurementItem(
                  label: 'Hips',
                  value: '${hips.getValueInUnit(false).toStringAsFixed(1)}"',
                  color: AppColors.orange,
                  textColor: textColor,
                  textMuted: textMuted,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Last updated + Update button
        Row(
          children: [
            Icon(Icons.access_time, size: 14, color: textMuted),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                lastUpdatedText,
                style: TextStyle(
                  fontSize: 12,
                  color: textMuted,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openMeasurementsSheet(context, ref),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Update',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.purple,
                  ),
                ),
              ),
            ),
          ],
        ),

        // Full size: show changes
        if (size == TileSize.full) ...[
          const SizedBox(height: 12),
          _buildChangesRow(textMuted, waist, chest, hips),
        ],
      ],
    );
  }

  Widget _buildChangesRow(
    Color textMuted,
    MeasurementEntry? waist,
    MeasurementEntry? chest,
    MeasurementEntry? hips,
  ) {
    // For full size, show trend info
    return Row(
      children: [
        Icon(Icons.show_chart, size: 14, color: textMuted),
        const SizedBox(width: 6),
        Text(
          'Tap to view full history and trends',
          style: TextStyle(
            fontSize: 12,
            color: textMuted,
          ),
        ),
      ],
    );
  }

  void _openMeasurementsSheet(BuildContext context, WidgetRef ref) async {
    HapticService.light();

    final authState = ref.read(authStateProvider);
    final userId = authState.user?.id;

    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please sign in to log measurements')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LogMeasurementSheet(userId: userId),
    );

    // Refresh measurements after logging
    ref.read(measurementsProvider.notifier).loadAllMeasurements(userId);
  }
}

/// Individual measurement display item
class _MeasurementItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color textColor;
  final Color textMuted;

  const _MeasurementItem({
    required this.label,
    required this.value,
    required this.color,
    required this.textColor,
    required this.textMuted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textColor,
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
}
