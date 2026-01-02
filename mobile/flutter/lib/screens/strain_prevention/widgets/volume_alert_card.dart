import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../data/models/strain_prevention.dart';

/// Alert card for volume increase warnings with acknowledge button
class VolumeAlertCard extends StatelessWidget {
  final VolumeAlert alert;
  final VoidCallback? onAcknowledge;
  final VoidCallback? onTap;

  const VolumeAlertCard({
    super.key,
    required this.alert,
    this.onAcknowledge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final alertColor = _getAlertColor(alert.alertType);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              alertColor.withValues(alpha: 0.15),
              alertColor.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: alertColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: alertColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.trending_up,
                          color: alertColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              alert.muscleGroupDisplay,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(alert.createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Increase percentage badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: alertColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          alert.formattedIncrease,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Message
                  Text(
                    alert.message,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Volume comparison
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildVolumeColumn(
                            'Previous',
                            '${alert.previousVolumeKg.toStringAsFixed(0)} kg',
                            colorScheme.onSurfaceVariant,
                            colorScheme,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: colorScheme.outline.withValues(alpha: 0.2),
                        ),
                        Expanded(
                          child: _buildVolumeColumn(
                            'Current',
                            '${alert.currentVolumeKg.toStringAsFixed(0)} kg',
                            alertColor,
                            colorScheme,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Recommendation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 18,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            alert.recommendation,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Acknowledge button
            if (!alert.isAcknowledged && onAcknowledge != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.surface.withValues(alpha: 0.5),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: FilledButton.icon(
                  onPressed: onAcknowledge,
                  icon: const Icon(Icons.check, size: 18),
                  label: const Text('Acknowledge'),
                  style: FilledButton.styleFrom(
                    backgroundColor: alertColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildVolumeColumn(
    String label,
    String value,
    Color valueColor,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Color _getAlertColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'critical':
        return const Color(0xFF7C3AED); // Purple
      case 'danger':
        return const Color(0xFFEF4444); // Red
      case 'warning':
        return const Color(0xFFF59E0B); // Amber
      default:
        return const Color(0xFFF59E0B); // Amber default
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }
    return DateFormat('MMM d, yyyy').format(date);
  }
}

/// Compact version of the alert card for use in banners
class VolumeAlertBanner extends StatelessWidget {
  final List<VolumeAlert> alerts;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const VolumeAlertBanner({
    super.key,
    required this.alerts,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (alerts.isEmpty) return const SizedBox.shrink();

    final alertColor = alerts.length > 1
        ? const Color(0xFFEF4444)
        : _getAlertColor(alerts.first.alertType);

    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              alertColor,
              alertColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: alertColor.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.warning_amber,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alerts.length == 1
                        ? 'Volume Alert'
                        : '${alerts.length} Volume Alerts',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    alerts.length == 1
                        ? '${alerts.first.muscleGroupDisplay}: ${alerts.first.formattedIncrease} increase'
                        : 'Tap to review and acknowledge',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.2, end: 0);
  }

  Color _getAlertColor(String alertType) {
    switch (alertType.toLowerCase()) {
      case 'critical':
        return const Color(0xFF7C3AED);
      case 'danger':
        return const Color(0xFFEF4444);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}
