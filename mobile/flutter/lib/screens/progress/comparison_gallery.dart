import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/progress_photos.dart';
import '../../data/repositories/progress_photos_repository.dart';
import 'comparison_view.dart';

/// Full-screen gallery of saved before/after comparisons
class ComparisonGalleryScreen extends ConsumerStatefulWidget {
  final String userId;

  const ComparisonGalleryScreen({super.key, required this.userId});

  @override
  ConsumerState<ComparisonGalleryScreen> createState() =>
      _ComparisonGalleryScreenState();
}

class _ComparisonGalleryScreenState
    extends ConsumerState<ComparisonGalleryScreen> {
  bool _sortNewestFirst = true;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(progressPhotosNotifierProvider(widget.userId));
    final colorScheme = Theme.of(context).colorScheme;

    final comparisons = _sortNewestFirst
        ? state.comparisons.toList()
        : state.comparisons.reversed.toList();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Saved Comparisons'),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: Icon(
              _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
            ),
            tooltip: _sortNewestFirst ? 'Showing newest first' : 'Showing oldest first',
            onPressed: () {
              setState(() => _sortNewestFirst = !_sortNewestFirst);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref
            .read(progressPhotosNotifierProvider(widget.userId).notifier)
            .loadAll(),
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator())
            : comparisons.isEmpty
                ? _buildEmptyState(colorScheme)
                : _buildGrid(comparisons, colorScheme),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return ListView(
      // ListView so pull-to-refresh still works on empty state
      children: [
        SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.compare_outlined,
                    size: 80,
                    color: colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Comparisons Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a before & after comparison from the Photos tab to see your progress over time.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGrid(
      List<PhotoComparison> comparisons, ColorScheme colorScheme) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.78,
      ),
      itemCount: comparisons.length,
      itemBuilder: (context, index) {
        return _buildComparisonCard(comparisons[index], colorScheme);
      },
    );
  }

  Widget _buildComparisonCard(
      PhotoComparison comparison, ColorScheme colorScheme) {
    final beforeDate = DateFormat('MMM yyyy').format(comparison.beforePhoto.takenAt);
    final afterDate = DateFormat('MMM yyyy').format(comparison.afterPhoto.takenAt);
    final dateRange = '$beforeDate - $afterDate';

    // Layout icon mapping
    IconData layoutIcon;
    switch (comparison.layout) {
      case 'slider':
        layoutIcon = Icons.compare;
        break;
      case 'stacked':
        layoutIcon = Icons.view_agenda;
        break;
      default:
        layoutIcon = Icons.view_column;
    }

    return GestureDetector(
      onTap: () => _showDetailSheet(comparison),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Side-by-side thumbnail preview
            Expanded(
              child: Stack(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: comparison.beforePhoto.thumbnailUrl ??
                              comparison.beforePhoto.photoUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.errorContainer,
                            child: Icon(Icons.broken_image,
                                color: colorScheme.error, size: 20),
                          ),
                        ),
                      ),
                      Container(width: 1.5, color: colorScheme.outline),
                      Expanded(
                        child: CachedNetworkImage(
                          imageUrl: comparison.afterPhoto.thumbnailUrl ??
                              comparison.afterPhoto.photoUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: colorScheme.errorContainer,
                            child: Icon(Icons.broken_image,
                                color: colorScheme.error, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Layout icon in top-right corner
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        layoutIcon,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info section
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date range
                  Text(
                    dateRange,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  // Weight change badge + duration
                  Row(
                    children: [
                      if (comparison.formattedWeightChange != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: (comparison.weightChangeKg ?? 0) < 0
                                ? AppColors.green.withOpacity(0.15)
                                : AppColors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            comparison.formattedWeightChange!,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (comparison.weightChangeKg ?? 0) < 0
                                  ? AppColors.green
                                  : AppColors.orange,
                            ),
                          ),
                        ),
                      if (comparison.formattedWeightChange != null &&
                          comparison.formattedDuration != null)
                        const SizedBox(width: 6),
                      if (comparison.formattedDuration != null)
                        Expanded(
                          child: Text(
                            comparison.formattedDuration!,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // Detail bottom sheet
  // ──────────────────────────────────────────────────────────

  void _showDetailSheet(PhotoComparison comparison) {
    final colorScheme = Theme.of(context).colorScheme;
    final beforeDate =
        DateFormat('MMM d, yyyy').format(comparison.beforePhoto.takenAt);
    final afterDate =
        DateFormat('MMM d, yyyy').format(comparison.afterPhoto.takenAt);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Mini side-by-side preview
                SizedBox(
                  height: 140,
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl:
                                comparison.beforePhoto.thumbnailUrl ??
                                    comparison.beforePhoto.photoUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: CachedNetworkImage(
                            imageUrl:
                                comparison.afterPhoto.thumbnailUrl ??
                                    comparison.afterPhoto.photoUrl,
                            fit: BoxFit.cover,
                            memCacheWidth: 200,
                            memCacheHeight: 200,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Date info
                Text(
                  '$beforeDate  ->  $afterDate',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (comparison.progressDescription.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    comparison.progressDescription,
                    style: TextStyle(
                      fontSize: 13,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                // Action buttons
                _buildActionTile(
                  icon: Icons.edit_outlined,
                  label: 'Re-edit',
                  subtitle: 'Open in comparison editor',
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ComparisonView(
                          userId: widget.userId,
                          existingComparison: comparison,
                        ),
                      ),
                    );
                  },
                ),
                _buildActionTile(
                  icon: Icons.share_outlined,
                  label: 'Share',
                  subtitle: 'Export and share this comparison',
                  colorScheme: colorScheme,
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareComparison(comparison);
                  },
                ),
                _buildActionTile(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  subtitle: 'Remove this comparison',
                  colorScheme: colorScheme,
                  isDestructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    _confirmDelete(comparison);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final foreground =
        isDestructive ? colorScheme.error : colorScheme.onSurface;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: foreground),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDestructive
              ? colorScheme.error.withOpacity(0.7)
              : colorScheme.onSurfaceVariant,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onTap: onTap,
    );
  }

  // ──────────────────────────────────────────────────────────
  // Share (export via native share sheet)
  // ──────────────────────────────────────────────────────────

  Future<void> _shareComparison(PhotoComparison comparison) async {
    if (comparison.exportedImageUrl != null) {
      // If we already have an exported image, share it directly via URL
      // For now, show a snackbar indicating we are working on it.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preparing comparison for sharing...')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Open the comparison in editor first to export and share.'),
            action: SnackBarAction(
              label: 'Open',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ComparisonView(
                      userId: widget.userId,
                      existingComparison: comparison,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }

  // ──────────────────────────────────────────────────────────
  // Delete with confirmation
  // ──────────────────────────────────────────────────────────

  void _confirmDelete(PhotoComparison comparison) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: const Text('Delete Comparison?'),
        content: const Text(
          'This will permanently remove the comparison. The original photos will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref
                  .read(progressPhotosNotifierProvider(widget.userId).notifier)
                  .deleteComparison(comparison.id);

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(success
                        ? 'Comparison deleted'
                        : 'Failed to delete comparison'),
                    backgroundColor:
                        success ? colorScheme.primary : colorScheme.error,
                  ),
                );
              }
            },
            child: Text(
              'Delete',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }
}
