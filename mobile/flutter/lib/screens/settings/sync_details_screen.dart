import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../data/local/database.dart';
import '../../data/local/database_provider.dart';
import '../../data/services/sync_engine.dart';
import '../../data/services/sync_failure_service.dart';
import '../../widgets/pill_app_bar.dart';

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
      case 'food_log':
      case 'meal':
        return Icons.restaurant_outlined;
      case 'hydration_log':
      case 'water_log':
        return Icons.water_drop_outlined;
      default:
        return Icons.sync_problem_rounded;
    }
  }

  /// Produce a human-readable title for a queue row.
  /// Falls back to the entity type when the payload doesn't contain a name —
  /// the entity-specific extraction handles the most common cases users see
  /// in the dead-letter list (food logs by name, workouts by template name).
  String _titleForItem(PendingSyncQueueData item) {
    String? extracted;
    try {
      final raw = item.payload;
      // ignore: avoid_dynamic_calls
      final Map<String, dynamic> data = jsonDecode(raw) is Map
          ? Map<String, dynamic>.from(jsonDecode(raw) as Map)
          : <String, dynamic>{};
      switch (item.entityType) {
        case 'food_log':
        case 'meal':
          // Server payload uses `food_items: [{name, ...}]`. Take first 1-2.
          final items = data['food_items'];
          if (items is List && items.isNotEmpty) {
            final names = items
                .take(2)
                .map((e) => (e is Map ? e['name'] : null)?.toString() ?? '')
                .where((n) => n.isNotEmpty)
                .toList();
            if (names.isNotEmpty) {
              extracted = names.join(', ');
              if (items.length > 2) extracted = '$extracted +${items.length - 2}';
            }
          }
          extracted ??= data['meal_type']?.toString();
          break;
        case 'hydration_log':
        case 'water_log':
          final amt = data['amount_ml'];
          final type = data['drink_type'];
          if (amt != null && type != null) extracted = '$amt ml $type';
          break;
        case 'workout':
        case 'workout_completion':
          extracted = (data['name'] ?? data['template_name'])?.toString();
          break;
      }
    } catch (_) {/* payload not parseable — fall through */ }
    final base = (extracted == null || extracted.isEmpty)
        ? '${_formatEntityType(item.entityType)} • ${item.operationType}'
        : extracted;
    return base;
  }

  /// Color for the error-kind pill. Kept inline so all kinds share one style.
  Color _pillColorFor(SyncErrorKind kind, {required bool isDark}) {
    switch (kind) {
      case SyncErrorKind.auth:
        return AppColors.warning;
      case SyncErrorKind.network:
        return AppColors.info;
      case SyncErrorKind.validation4xx:
        return AppColors.error;
      case SyncErrorKind.server5xx:
        return AppColors.warning;
      case SyncErrorKind.corrupt:
        return AppColors.error;
      case SyncErrorKind.unknown:
        return isDark ? AppColors.textMuted : AppColorsLight.textMuted;
    }
  }

  Future<void> _retryOne(PendingSyncQueueData item) async {
    final service = ref.read(syncFailureServiceProvider);
    final retried = await service.retryItem(item.id);
    if (!mounted) return;
    if (retried) {
      ref.read(syncEngineProvider.notifier).syncNow();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Retrying...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              "This error won't fix itself on retry. Use Edit & re-log or Discard."),
        ),
      );
    }
    await _loadDeadLetterItems();
  }

  Future<void> _discardOne(PendingSyncQueueData item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Discard this change?'),
        content: const Text(
            'This will permanently delete the unsent change from your device. '
            'Existing data on the server is unaffected.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    final service = ref.read(syncFailureServiceProvider);
    await service.discardItem(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Discarded')),
    );
    await _loadDeadLetterItems();
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
      appBar: const PillAppBar(title: 'Sync Details'),
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
                          final kind = SyncErrorKind.classify(item.lastError);
                          final pillColor =
                              _pillColorFor(kind, isDark: isDark);
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardBackground,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error
                                            .withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(8),
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
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  _titleForItem(item),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: textPrimary,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 6),
                                              Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: pillColor
                                                      .withValues(alpha: 0.15),
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  kind.displayLabel,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    color: pillColor,
                                                  ),
                                                ),
                                              ),
                                            ],
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
                                              overflow:
                                                  TextOverflow.ellipsis,
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
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed: () => _discardOne(item),
                                      icon: const Icon(
                                          Icons.delete_outline_rounded,
                                          size: 16),
                                      label: const Text('Discard'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.error,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton.icon(
                                      onPressed: kind.isRetryable
                                          ? () => _retryOne(item)
                                          : null,
                                      icon: const Icon(Icons.refresh_rounded,
                                          size: 16),
                                      label: Text(kind.isRetryable
                                          ? 'Retry'
                                          : 'Edit & re-log'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.info,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
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
