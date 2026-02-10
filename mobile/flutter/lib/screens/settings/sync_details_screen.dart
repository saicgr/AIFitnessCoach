import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/services/sync_engine.dart';
import '../../data/services/sync_failure_service.dart';

/// Screen showing details about failed sync items (dead letters).
/// Provides actions to retry, export, or re-authenticate.
class SyncDetailsScreen extends ConsumerStatefulWidget {
  const SyncDetailsScreen({super.key});

  @override
  ConsumerState<SyncDetailsScreen> createState() => _SyncDetailsScreenState();
}

class _SyncDetailsScreenState extends ConsumerState<SyncDetailsScreen> {
  List<PendingSyncQueueData> _deadLetterItems = [];
  bool _isLoading = true;
  bool _isRetrying = false;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadDeadLetterItems();
  }

  Future<void> _loadDeadLetterItems() async {
    setState(() => _isLoading = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final items = await db.syncQueueDao.getDeadLetterItems();
      if (mounted) {
        setState(() {
          _deadLetterItems = items;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      debugPrint('❌ [SyncDetails] Failed to load items: $e');
    }
  }

  Future<void> _retryAll() async {
    setState(() => _isRetrying = true);
    try {
      final db = ref.read(appDatabaseProvider);
      final recovered = await db.syncQueueDao.recoverDeadLetterItems();
      debugPrint('🔄 [SyncDetails] Recovered $recovered items for retry');
      // Trigger sync
      ref.read(syncEngineProvider.notifier).syncNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retrying $recovered item${recovered == 1 ? '' : 's'}...'),
            backgroundColor: AppColors.info,
          ),
        );
        await _loadDeadLetterItems();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  Future<void> _exportData() async {
    setState(() => _isExporting = true);
    try {
      final service = ref.read(syncFailureServiceProvider);
      final file = await service.exportDeadLetterItems();
      await service.shareExport(file);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  IconData _iconForEntityType(String entityType) {
    switch (entityType) {
      case 'workout':
      case 'workout_completion':
        return Icons.fitness_center_rounded;
      case 'workout_log':
        return Icons.edit_note_rounded;
      case 'readiness':
        return Icons.monitor_heart_rounded;
      case 'user_profile':
        return Icons.person_rounded;
      default:
        return Icons.sync_problem_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor =
        isDark ? AppColors.pureBlack : AppColorsLight.pureWhite;
    final cardBackground =
        isDark ? AppColors.elevated : AppColorsLight.elevated;
    final textPrimary =
        isDark ? AppColors.textPrimary : AppColorsLight.textPrimary;
    final textSecondary =
        isDark ? AppColors.textSecondary : AppColorsLight.textSecondary;
    final textMuted = isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    final borderColor =
        isDark ? AppColors.cardBorder : AppColorsLight.cardBorder;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text(
          'Sync Details',
          style: TextStyle(color: textPrimary),
        ),
        backgroundColor: backgroundColor,
        iconTheme: IconThemeData(color: textPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _deadLetterItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline_rounded,
                        size: 64,
                        color: AppColors.success,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'All synced!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No failed sync items.',
                        style: TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Summary card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.sync_problem_rounded,
                              color: AppColors.error,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_deadLetterItems.length} item${_deadLetterItems.length == 1 ? '' : 's'} failed to sync',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textPrimary,
                                  ),
                                ),
                                if (_deadLetterItems.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    'Latest: ${_formatDate(_deadLetterItems.first.createdAt)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: textMuted,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Item list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _deadLetterItems.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _deadLetterItems[index];
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.error
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _iconForEntityType(item.entityType),
                                    color: AppColors.error,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_formatEntityType(item.entityType)} - ${item.operationType}',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (item.lastError != null)
                                        Text(
                                          item.lastError!,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.error,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Text(
                                            _formatDate(item.createdAt),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            '${item.retryCount} retries',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Action buttons
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      decoration: BoxDecoration(
                        color: cardBackground,
                        border: Border(
                          top: BorderSide(color: borderColor),
                        ),
                      ),
                      child: SafeArea(
                        top: false,
                        child: Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _isExporting ? null : _exportData,
                                icon: _isExporting
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Icon(Icons.download_rounded,
                                        size: 18),
                                label: const Text('Export'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textSecondary,
                                  side: BorderSide(color: borderColor),
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: FilledButton.icon(
                                onPressed: _isRetrying ? null : _retryAll,
                                icon: _isRetrying
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded,
                                        size: 18),
                                label: const Text('Retry All'),
                                style: FilledButton.styleFrom(
                                  backgroundColor: AppColors.info,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatEntityType(String entityType) {
    return entityType
        .split('_')
        .map((w) => w.isNotEmpty
            ? '${w[0].toUpperCase()}${w.substring(1)}'
            : '')
        .join(' ');
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM d, HH:mm').format(date);
    }
  }
}
