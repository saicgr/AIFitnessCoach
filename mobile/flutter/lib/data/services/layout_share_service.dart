import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../models/home_layout.dart';
import '../../core/constants/app_colors.dart';
import 'share_service.dart';

/// Service for generating and sharing layout previews
class LayoutShareService {
  /// Generate a preview image for a layout
  /// Uses a GlobalKey to capture a RepaintBoundary widget
  static Future<Uint8List?> captureLayoutPreview(GlobalKey key) async {
    try {
      final RenderRepaintBoundary? boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('❌ [LayoutShare] Could not find render boundary');
        return null;
      }

      // Capture at 3x for high quality
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('❌ [LayoutShare] Could not convert image to bytes');
        return null;
      }

      debugPrint('✅ [LayoutShare] Captured layout preview');
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('❌ [LayoutShare] Error capturing layout: $e');
      return null;
    }
  }

  /// Share layout to Instagram Stories
  static Future<ShareResult> shareToInstagram(Uint8List imageBytes) async {
    return await ShareService.shareToInstagramStories(imageBytes);
  }

  /// Share layout via system share sheet
  static Future<ShareResult> shareGeneric(
    Uint8List imageBytes, {
    String? layoutName,
  }) async {
    return await ShareService.shareGeneric(
      imageBytes,
      caption: layoutName != null
          ? 'Check out my "$layoutName" home screen layout!'
          : 'Check out my custom home screen layout!',
      subject: 'My FitWiz Layout',
    );
  }

  /// Save layout preview to gallery
  static Future<ShareResult> saveToGallery(Uint8List imageBytes) async {
    return await ShareService.saveToGallery(imageBytes);
  }
}

/// Widget for rendering a shareable layout preview
class LayoutPreviewWidget extends StatelessWidget {
  final HomeLayout layout;
  final GlobalKey previewKey;

  const LayoutPreviewWidget({
    super.key,
    required this.layout,
    required this.previewKey,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      key: previewKey,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.background,
              AppColors.elevated,
            ],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.dashboard_customize,
                    color: AppColors.cyan,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        layout.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${layout.tiles.where((t) => t.isVisible).length} tiles',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Tile preview grid
            _buildTilePreviewGrid(),
            const SizedBox(height: 20),
            // Branding
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center,
                  size: 16,
                  color: AppColors.cyan,
                ),
                const SizedBox(width: 6),
                Text(
                  'FitWiz',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cyan,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTilePreviewGrid() {
    final visibleTiles = layout.tiles.where((t) => t.isVisible).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    if (visibleTiles.isEmpty) {
      return Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.elevated,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No tiles configured',
            style: TextStyle(color: AppColors.textMuted),
          ),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: visibleTiles.take(8).map((tile) {
        final color = _getColorForTile(tile.type);
        final isHalf = tile.size == TileSize.half;

        return Container(
          width: isHalf ? 80 : 168,
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getIconForTile(tile.type),
                size: 14,
                color: color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tile.type.displayName,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  IconData _getIconForTile(TileType type) {
    switch (type) {
      case TileType.nextWorkout:
        return Icons.fitness_center;
      case TileType.fitnessScore:
        return Icons.insights;
      case TileType.moodPicker:
        return Icons.mood;
      case TileType.dailyActivity:
        return Icons.local_fire_department;
      case TileType.quickActions:
        return Icons.grid_view;
      case TileType.weeklyProgress:
        return Icons.bar_chart;
      case TileType.weeklyGoals:
        return Icons.flag;
      case TileType.weekChanges:
        return Icons.swap_horiz;
      case TileType.upcomingFeatures:
        return Icons.upcoming;
      case TileType.upcomingWorkouts:
        return Icons.calendar_today;
      case TileType.streakCounter:
        return Icons.local_fire_department;
      case TileType.personalRecords:
        return Icons.emoji_events;
      case TileType.aiCoachTip:
        return Icons.tips_and_updates;
      case TileType.challengeProgress:
        return Icons.military_tech;
      case TileType.caloriesSummary:
        return Icons.restaurant;
      case TileType.macroRings:
        return Icons.pie_chart;
      case TileType.bodyWeight:
        return Icons.monitor_weight;
      case TileType.progressPhoto:
        return Icons.compare;
      case TileType.socialFeed:
        return Icons.people;
      case TileType.leaderboardRank:
        return Icons.leaderboard;
      case TileType.fasting:
        return Icons.timer;
      case TileType.weeklyCalendar:
        return Icons.calendar_month;
      case TileType.muscleHeatmap:
        return Icons.accessibility_new;
      case TileType.sleepScore:
        return Icons.bedtime;
      case TileType.restDayTip:
        return Icons.spa;
      case TileType.quickStart:
        return Icons.play_circle_filled;
      case TileType.myJourney:
        return Icons.route;
      case TileType.progressCharts:
        return Icons.show_chart;
      case TileType.roiSummary:
        return Icons.trending_up;
      case TileType.weeklyPlan:
        return Icons.calendar_view_week;
      case TileType.weightTrend:
        return Icons.trending_up;
      case TileType.dailyStats:
        return Icons.bar_chart;
      case TileType.achievements:
        return Icons.emoji_events;
      case TileType.heroSection:
        return Icons.star;
      case TileType.quickLogWeight:
        return Icons.scale;
      case TileType.quickLogMeasurements:
        return Icons.straighten;
      case TileType.habits:
        return Icons.check_circle_outline;
    }
  }

  Color _getColorForTile(TileType type) {
    switch (type.category) {
      case TileCategory.workout:
        return AppColors.cyan;
      case TileCategory.progress:
        return AppColors.green;
      case TileCategory.nutrition:
        return AppColors.orange;
      case TileCategory.social:
        return AppColors.purple;
      case TileCategory.wellness:
        return AppColors.yellow;
      case TileCategory.tools:
        return AppColors.cyan;
    }
  }
}

/// Bottom sheet for sharing a layout
class ShareLayoutSheet extends StatefulWidget {
  final HomeLayout layout;

  const ShareLayoutSheet({super.key, required this.layout});

  @override
  State<ShareLayoutSheet> createState() => _ShareLayoutSheetState();
}

class _ShareLayoutSheetState extends State<ShareLayoutSheet> {
  final GlobalKey _previewKey = GlobalKey();
  bool _isSharing = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textMuted.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Share Layout',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: AppColors.textMuted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Preview
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: LayoutPreviewWidget(
              layout: widget.layout,
              previewKey: _previewKey,
            ),
          ),
          const SizedBox(height: 24),
          // Share options
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _ShareOption(
                    icon: Icons.camera_alt,
                    label: 'Instagram',
                    color: const Color(0xFFE1306C),
                    isLoading: _isSharing,
                    onTap: () => _shareToInstagram(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShareOption(
                    icon: Icons.share,
                    label: 'Share',
                    color: AppColors.cyan,
                    isLoading: _isSharing,
                    onTap: () => _shareGeneric(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ShareOption(
                    icon: Icons.save_alt,
                    label: 'Save',
                    color: AppColors.green,
                    isLoading: _isSharing,
                    onTap: () => _saveToGallery(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Future<Uint8List?> _capturePreview() async {
    // Wait for next frame to ensure widget is rendered
    await Future.delayed(const Duration(milliseconds: 100));
    return await LayoutShareService.captureLayoutPreview(_previewKey);
  }

  Future<void> _shareToInstagram() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await _capturePreview();
      if (bytes != null) {
        final result = await LayoutShareService.shareToInstagram(bytes);
        if (mounted) {
          _showShareResult(result);
        }
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareGeneric() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await _capturePreview();
      if (bytes != null) {
        final result = await LayoutShareService.shareGeneric(
          bytes,
          layoutName: widget.layout.name,
        );
        if (mounted) {
          _showShareResult(result);
        }
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _saveToGallery() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);

    try {
      final bytes = await _capturePreview();
      if (bytes != null) {
        final result = await LayoutShareService.saveToGallery(bytes);
        if (mounted) {
          _showShareResult(result);
        }
      }
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  void _showShareResult(ShareResult result) {
    final messenger = ScaffoldMessenger.of(context);

    if (result.success) {
      String message;
      switch (result.destination) {
        case ShareDestination.instagramStories:
          message = 'Opening Instagram...';
        case ShareDestination.systemShare:
          message = 'Shared successfully!';
        case ShareDestination.saveToGallery:
          message = 'Saved to gallery!';
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text(result.error ?? 'Failed to share'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool isLoading;

  const _ShareOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              if (isLoading)
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              else
                Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper function to show the share layout sheet
Future<void> showShareLayoutSheet(
  BuildContext context,
  HomeLayout layout,
) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => ShareLayoutSheet(layout: layout),
  );
}
